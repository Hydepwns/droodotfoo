defmodule DroodotfooWeb.Wiki.SourceIndexLive do
  @moduledoc """
  Index page for browsing articles within a specific wiki source.
  Shows article count, sort options, and paginated article listing.
  """

  use Phoenix.LiveView, layout: false

  alias Droodotfoo.Wiki.Content
  alias DroodotfooWeb.Wiki.{Helpers, Layouts}

  @per_page 25
  @letters ~w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)

  # Source routing - maps URL paths to source atoms
  @path_to_source %{
    "/osrs" => :osrs,
    "/nlab" => :nlab,
    "/wikipedia" => :wikipedia,
    "/machines" => :vintage_machinery,
    "/art" => :wikiart
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    with {:ok, source} <- source_from_uri(uri),
         filters <- parse_filters(params),
         {articles, total} <- fetch_articles(source, filters) do
      breadcrumbs = [
        {"Home", "/"},
        {Helpers.source_label_full(source), Helpers.source_index_path(source)}
      ]

      {:noreply,
       assign(socket,
         source: source,
         filters: filters,
         articles: articles,
         total_count: total,
         total_pages: ceil_div(total, @per_page),
         letters: @letters,
         page_title: Helpers.source_label_full(source),
         current_path: Helpers.source_index_path(source),
         breadcrumbs: breadcrumbs
       )}
    else
      :error -> {:noreply, push_navigate(socket, to: "/")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <Layouts.breadcrumbs items={@breadcrumbs} />

      <section class="section-spaced">
        <h2 class="section-header-bordered">
          {Helpers.source_label_full(@source)}
        </h2>

        <p class="text-muted-alt">
          {@total_count} articles <span class="px-1">|</span>
          <a href={Helpers.upstream_base_url(@source)} target="_blank" rel="noopener">
            Source ->
          </a>
        </p>
      </section>

      <section class="section-spaced">
        <nav class="flex gap-2 mb-2">
          <span class="text-muted-alt">Sort:</span>
          <.nav_link
            :for={{sort, label} <- [{"recent", "Recent"}, {"alpha", "A-Z"}]}
            to={build_url(@source, %{@filters | sort: sort, page: 1})}
            active={@filters.sort == sort}
            label={label}
          />
        </nav>

        <nav :if={@filters.sort == "alpha"} class="flex flex-wrap gap-1 mb-2">
          <.nav_link
            :for={letter <- @letters}
            to={build_url(@source, %{@filters | letter: letter, page: 1})}
            active={@filters.letter == letter}
            label={letter}
            class="text-sm px-1"
          />
          <.nav_link
            to={build_url(@source, %{@filters | letter: nil, page: 1})}
            active={is_nil(@filters.letter)}
            label="All"
            class="text-sm px-1"
          />
        </nav>
      </section>

      <section class="section-spaced">
        <p :if={@articles == []} class="text-muted-alt">
          No articles found.
        </p>

        <article :for={article <- @articles} class="post-item">
          <h3 class="mb-0-5">
            <.link navigate={Helpers.article_path(article)} class="link-reset">
              {article.title}
            </.link>
          </h3>
          <p class="text-muted-alt text-sm">
            Updated {format_date(article.synced_at)}
          </p>
        </article>
      </section>

      <.pagination
        :if={@total_pages > 1}
        source={@source}
        filters={@filters}
        total_pages={@total_pages}
      />
    </Layouts.app>
    """
  end

  # Components

  attr :to, :string, required: true
  attr :active, :boolean, required: true
  attr :label, :string, required: true
  attr :class, :string, default: nil

  defp nav_link(assigns) do
    ~H"""
    <.link navigate={@to} class={[@class, @active && "font-bold", !@active && "text-muted-alt"]}>
      {@label}
    </.link>
    """
  end

  attr :source, :atom, required: true
  attr :filters, :map, required: true
  attr :total_pages, :integer, required: true

  defp pagination(assigns) do
    ~H"""
    <section class="section-spaced">
      <nav class="flex gap-2 items-center">
        <.link
          :if={@filters.page > 1}
          navigate={build_url(@source, %{@filters | page: @filters.page - 1})}
          class="btn"
        >
          Prev
        </.link>
        <span class="text-muted-alt">
          Page {@filters.page} of {@total_pages}
        </span>
        <.link
          :if={@filters.page < @total_pages}
          navigate={build_url(@source, %{@filters | page: @filters.page + 1})}
          class="btn"
        >
          Next
        </.link>
      </nav>
    </section>
    """
  end

  # Data fetching

  defp fetch_articles(source, %{page: page, sort: sort, letter: letter}) do
    opts = [
      limit: @per_page,
      offset: (page - 1) * @per_page,
      order_by: sort_to_order(sort),
      letter: letter
    ]

    articles = Content.list_articles(source, opts)
    total = Content.count_articles(source, letter: letter)

    {articles, total}
  end

  defp sort_to_order("alpha"), do: :title
  defp sort_to_order(_), do: :updated_at

  # Parsing

  defp source_from_uri(uri) do
    path = URI.parse(uri).path
    base_path = path |> String.split("/") |> Enum.take(2) |> Enum.join("/")

    case Map.fetch(@path_to_source, base_path) do
      {:ok, source} -> {:ok, source}
      :error -> :error
    end
  end

  defp parse_filters(params) do
    %{
      page: parse_page(params["page"]),
      sort: parse_sort(params["sort"]),
      letter: params["letter"]
    }
  end

  defp parse_page(nil), do: 1

  defp parse_page(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, _} when n > 0 -> n
      _ -> 1
    end
  end

  defp parse_sort("alpha"), do: "alpha"
  defp parse_sort(_), do: "recent"

  # URL building

  defp build_url(source, filters) do
    base = Helpers.source_index_path(source)
    params = filters_to_params(filters)

    case params do
      [] -> base
      _ -> base <> "?" <> URI.encode_query(params)
    end
  end

  defp filters_to_params(%{sort: sort, letter: letter, page: page}) do
    []
    |> maybe_add_param(:sort, sort, "recent")
    |> maybe_add_param(:letter, letter, nil)
    |> maybe_add_param(:page, page, 1)
  end

  defp maybe_add_param(params, _key, value, default) when value == default, do: params
  defp maybe_add_param(params, _key, nil, _default), do: params
  defp maybe_add_param(params, key, value, _default), do: [{key, value} | params]

  # Formatting

  defp format_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d")
  defp format_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d")
  defp format_date(_), do: "unknown"

  defp ceil_div(_, 0), do: 1
  defp ceil_div(num, denom), do: max(1, ceil(num / denom))
end
