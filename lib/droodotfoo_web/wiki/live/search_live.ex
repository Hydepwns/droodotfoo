defmodule DroodotfooWeb.Wiki.SearchLive do
  @moduledoc """
  Cross-source search page with keyword, semantic, and hybrid search modes.
  Terminal aesthetic matching droo.foo.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Wiki.{Helpers, Layouts}
  alias Droodotfoo.Wiki.Search
  alias Droodotfoo.Wiki.Search.RateLimiter

  @rate_limit_seconds 30

  @impl true
  def mount(_params, _session, socket) do
    # Defer source_counts loading to avoid blocking mount
    if connected?(socket), do: send(self(), :load_source_counts)

    {:ok,
     assign(socket,
       query: "",
       results: [],
       suggestions: [],
       source_filter: nil,
       source_counts: %{},
       total_count: 0,
       search_mode: :hybrid,
       rate_limited: false,
       rate_limit_seconds: 0,
       rate_limit_timer: nil,
       page_title: "SEARCH",
       current_path: "/search",
       breadcrumbs: [{"Home", "/"}, {"Search", "/search"}]
     )}
  end

  @impl true
  def handle_info(:load_source_counts, socket) do
    {:noreply, assign(socket, source_counts: Search.source_counts())}
  end

  @impl true
  def handle_info(:countdown_tick, socket) do
    remaining = socket.assigns.rate_limit_seconds - 1

    if remaining <= 0 do
      {:noreply,
       assign(socket,
         rate_limited: false,
         rate_limit_seconds: 0,
         rate_limit_timer: nil
       )}
    else
      timer = Process.send_after(self(), :countdown_tick, 1000)

      {:noreply,
       assign(socket,
         rate_limit_seconds: remaining,
         rate_limit_timer: timer
       )}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    query = params["q"] || ""
    source = Helpers.parse_source(params["source"])
    mode = parse_mode(params["mode"])

    socket =
      socket
      |> assign(query: query, source_filter: source, search_mode: mode)
      |> do_search()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <Layouts.breadcrumbs items={@breadcrumbs} />

      <section class="section-spaced">
        <h2 class="section-header-bordered">
          SEARCH
        </h2>

        <form phx-submit="search" phx-change="search">
          <div class="flex gap-2 mb-2">
            <input
              type="text"
              name="q"
              value={@query}
              placeholder="Search articles... (press / to focus)"
              class="flex-1"
              autofocus
              phx-debounce="300"
              list="search-suggestions"
              autocomplete="off"
            />
            <datalist id="search-suggestions">
              <option :for={suggestion <- @suggestions} value={suggestion.title}>
                {Helpers.source_label(suggestion.source)}
              </option>
            </datalist>
            <select name="source">
              <option value="">All sources</option>
              <option
                :for={{source, count} <- @source_counts}
                value={source}
                selected={@source_filter == source}
              >
                {Helpers.source_label(source)} ({count})
              </option>
            </select>
          </div>

          <div class="flex gap-1">
            <.mode_button mode={:hybrid} current={@search_mode} label="HYBRID" />
            <.mode_button mode={:keyword} current={@search_mode} label="KEYWORD" />
            <.mode_button mode={:semantic} current={@search_mode} label="SEMANTIC" />
          </div>
        </form>
      </section>

      <section :if={@rate_limited} class="rate-limit-notice">
        <span class="text-muted">
          [!] Rate limit - retry in {@rate_limit_seconds}s
        </span>
        <div class="rate-limit-bar">
          <div
            class="rate-limit-progress"
            style={"width: #{(1.0 - @rate_limit_seconds / 30.0) * 100.0}%"}
          >
          </div>
        </div>
      </section>

      <section :if={@query == "" && !@rate_limited} class="section-spaced">
        <p class="text-muted-alt">
          Enter a search term to find articles across all sources.
        </p>
      </section>

      <section :if={@query != "" && @results == [] && !@rate_limited} class="section-spaced">
        <p class="text-muted-alt">
          No results found for "{@query}".
        </p>
      </section>

      <section :if={@results != []} class="section-spaced">
        <h2 class="section-header-bordered">
          RESULTS
        </h2>
        <p class="text-muted-alt mb-2">
          Found {@total_count} results for "{@query}"
        </p>

        <article :for={result <- @results} class="post-item">
          <h3 class="mb-0-5">
            <.link navigate={Helpers.article_path(result)} class="link-reset">
              {result.title}
            </.link>
            <.source_badge source={result.source} />
          </h3>
          <p class="text-muted-alt">
            {Phoenix.HTML.raw(result.snippet)}
          </p>
        </article>
      </section>
    </Layouts.app>
    """
  end

  defp mode_button(assigns) do
    active = assigns.mode == assigns.current
    assigns = assign(assigns, :active, active)

    ~H"""
    <button
      type="button"
      phx-click="set_mode"
      phx-value-mode={@mode}
      class={["btn text-sm", @active && "bg-accent"]}
    >
      {@label}
    </button>
    """
  end

  defp source_badge(assigns) do
    assigns =
      assigns
      |> assign(:class, Helpers.source_badge_class(assigns.source))
      |> assign(:label, Helpers.source_label(assigns.source))

    ~H"""
    <span class={@class}>
      {@label}
    </span>
    """
  end

  @impl true
  def handle_event("search", %{"q" => query} = params, socket) do
    source = Helpers.parse_source(params["source"])

    # Fetch suggestions for autocomplete (only when typing, not on submit)
    suggestions = fetch_suggestions(query, source)

    socket =
      socket
      |> assign(query: query, source_filter: source, suggestions: suggestions)
      |> do_search()
      |> push_patch_if_changed(query, source, socket.assigns.search_mode)

    {:noreply, socket}
  end

  @impl true
  def handle_event("set_mode", %{"mode" => mode}, socket) do
    mode = parse_mode(mode)

    socket =
      socket
      |> assign(search_mode: mode)
      |> do_search()
      |> push_patch_if_changed(socket.assigns.query, socket.assigns.source_filter, mode)

    {:noreply, socket}
  end

  defp do_search(%{assigns: %{query: ""}} = socket) do
    assign(socket, results: [], total_count: 0, rate_limited: false)
  end

  defp do_search(%{assigns: %{query: query, source_filter: source, search_mode: mode}} = socket) do
    ip = get_client_ip(socket)

    case RateLimiter.check_rate_limit(ip) do
      {:ok, :allowed} ->
        RateLimiter.record_request(ip)
        opts = [mode: mode]
        opts = if source, do: Keyword.put(opts, :source, source), else: opts
        results = Search.search(query, opts)
        total = Search.count(query, opts)

        assign(socket, results: results, total_count: total, rate_limited: false)

      {:error, _message} ->
        start_rate_limit_countdown(socket)
    end
  end

  defp start_rate_limit_countdown(socket) do
    # Cancel existing timer if any
    if socket.assigns.rate_limit_timer do
      Process.cancel_timer(socket.assigns.rate_limit_timer)
    end

    timer = Process.send_after(self(), :countdown_tick, 1000)

    assign(socket,
      results: [],
      total_count: 0,
      rate_limited: true,
      rate_limit_seconds: @rate_limit_seconds,
      rate_limit_timer: timer
    )
  end

  defp get_client_ip(socket) do
    case socket.assigns[:peer_data] do
      %{address: ip} when is_tuple(ip) -> ip |> Tuple.to_list() |> Enum.join(".")
      _ -> get_connect_info_ip(socket)
    end
  end

  defp get_connect_info_ip(socket) do
    case Phoenix.LiveView.get_connect_info(socket, :peer_data) do
      %{address: ip} when is_tuple(ip) -> ip |> Tuple.to_list() |> Enum.join(".")
      _ -> "unknown"
    end
  end

  defp push_patch_if_changed(socket, query, source, mode) do
    params =
      %{}
      |> then(fn p -> if query != "", do: Map.put(p, "q", query), else: p end)
      |> then(fn p -> if source, do: Map.put(p, "source", source), else: p end)
      |> then(fn p -> if mode != :hybrid, do: Map.put(p, "mode", mode), else: p end)

    push_patch(socket, to: "/search?#{URI.encode_query(params)}")
  end

  defp parse_mode("keyword"), do: :keyword
  defp parse_mode("semantic"), do: :semantic
  defp parse_mode("hybrid"), do: :hybrid
  defp parse_mode(_), do: :hybrid

  defp fetch_suggestions(query, source) when byte_size(query) >= 2 do
    opts = if source, do: [source: source, limit: 8], else: [limit: 8]
    Search.suggest(query, opts)
  end

  defp fetch_suggestions(_query, _source), do: []
end
