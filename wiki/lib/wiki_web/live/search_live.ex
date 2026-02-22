defmodule WikiWeb.SearchLive do
  @moduledoc """
  Cross-source search page with full-text search.
  """

  use WikiWeb, :live_view

  alias Wiki.Search

  @impl true
  def mount(_params, _session, socket) do
    source_counts = Search.source_counts()

    {:ok,
     assign(socket,
       query: "",
       results: [],
       source_filter: nil,
       source_counts: source_counts,
       total_count: 0,
       page_title: "Search"
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    query = params["q"] || ""
    source = parse_source(params["source"])

    socket =
      socket
      |> assign(query: query, source_filter: source)
      |> do_search()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto px-4 py-8">
        <h1 class="text-2xl font-mono font-bold mb-6">Search</h1>

        <form phx-submit="search" phx-change="search" class="mb-6">
          <div class="flex gap-4">
            <input
              type="text"
              name="q"
              value={@query}
              placeholder="Search articles..."
              class="flex-1 px-4 py-2 bg-zinc-900 border border-zinc-700 rounded font-mono text-white focus:border-blue-500 focus:outline-none"
              autofocus
              phx-debounce="300"
            />
            <select
              name="source"
              class="px-4 py-2 bg-zinc-900 border border-zinc-700 rounded font-mono text-white"
            >
              <option value="">All sources</option>
              <option
                :for={{source, count} <- @source_counts}
                value={source}
                selected={@source_filter == source}
              >
                {source_label(source)} ({count})
              </option>
            </select>
          </div>
        </form>

        <.no_results :if={@query != "" && @results == []} query={@query} />

        <.empty_state :if={@query == ""} />

        <.results_list :if={@results != []} results={@results} total={@total_count} query={@query} />
      </div>
    </Layouts.app>
    """
  end

  defp empty_state(assigns) do
    ~H"""
    <div class="text-zinc-500 font-mono">
      Enter a search term to find articles across all sources.
    </div>
    """
  end

  defp no_results(assigns) do
    ~H"""
    <div class="text-zinc-500 font-mono">
      No results found for "<span class="text-white">{@query}</span>".
    </div>
    """
  end

  defp results_list(assigns) do
    ~H"""
    <div>
      <p class="text-zinc-500 text-sm font-mono mb-4">
        Found {@total} results for "<span class="text-white">{@query}</span>"
      </p>

      <ul class="space-y-4">
        <li :for={result <- @results} class="border-b border-zinc-800 pb-4">
          <div class="flex items-center gap-2 mb-1">
            <.source_badge source={result.source} />
            <.link navigate={article_path(result)} class="text-blue-400 hover:underline font-mono">
              {result.title}
            </.link>
          </div>
          <p class="text-zinc-400 text-sm font-mono mt-1 leading-relaxed">
            {raw(result.snippet)}
          </p>
        </li>
      </ul>
    </div>
    """
  end

  defp source_badge(assigns) do
    color =
      case assigns.source do
        :osrs -> "bg-amber-900 text-amber-200"
        :nlab -> "bg-blue-900 text-blue-200"
        :wikipedia -> "bg-zinc-700 text-zinc-200"
        _ -> "bg-zinc-800 text-zinc-300"
      end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={"text-xs px-1.5 py-0.5 rounded font-mono #{@color}"}>
      {source_label(@source)}
    </span>
    """
  end

  @impl true
  def handle_event("search", %{"q" => query} = params, socket) do
    source = parse_source(params["source"])

    socket =
      socket
      |> assign(query: query, source_filter: source)
      |> do_search()
      |> push_patch_if_changed(query, source)

    {:noreply, socket}
  end

  defp do_search(%{assigns: %{query: ""}} = socket) do
    assign(socket, results: [], total_count: 0)
  end

  defp do_search(%{assigns: %{query: query, source_filter: source}} = socket) do
    opts = if source, do: [source: source], else: []
    results = Search.search(query, opts)
    total = Search.count(query, opts)

    assign(socket, results: results, total_count: total)
  end

  defp push_patch_if_changed(socket, query, source) do
    params =
      %{}
      |> then(fn p -> if query != "", do: Map.put(p, "q", query), else: p end)
      |> then(fn p -> if source, do: Map.put(p, "source", source), else: p end)

    push_patch(socket, to: ~p"/search?#{params}")
  end

  defp parse_source(""), do: nil
  defp parse_source(nil), do: nil

  defp parse_source(source) when is_binary(source) do
    case source do
      "osrs" -> :osrs
      "nlab" -> :nlab
      "wikipedia" -> :wikipedia
      "vintage_machinery" -> :vintage_machinery
      "wikiart" -> :wikiart
      _ -> nil
    end
  end

  defp source_label(:osrs), do: "OSRS"
  defp source_label(:nlab), do: "nLab"
  defp source_label(:wikipedia), do: "Wikipedia"
  defp source_label(:vintage_machinery), do: "Vintage"
  defp source_label(:wikiart), do: "Art"
  defp source_label(source), do: to_string(source)

  defp article_path(%{source: :osrs, slug: slug}), do: ~p"/osrs/#{slug}"
  defp article_path(%{source: :nlab, slug: slug}), do: ~p"/nlab/#{slug}"
  defp article_path(%{source: :wikipedia, slug: slug}), do: ~p"/wikipedia/#{slug}"
  defp article_path(%{source: source, slug: slug}), do: "/#{source}/#{slug}"
end
