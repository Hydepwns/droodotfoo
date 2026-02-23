defmodule WikiWeb.ArticleLive do
  @moduledoc """
  Single LiveView for all wiki sources.

  The source is derived from the URL path via handle_params.
  Content is loaded asynchronously after mount.
  Shows related articles from other sources in a sidebar.
  """

  use WikiWeb, :live_view

  alias Wiki.Content
  alias Wiki.CrossLinks

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, article: nil, html: "", loading: true, error: nil, related: [])}
  end

  @impl true
  def handle_params(params, uri, socket) do
    {source, slug} = source_and_slug_from_uri(uri, params)

    socket =
      socket
      |> assign(source: source, slug: slug, loading: true, error: nil, related: [])
      |> assign(page_title: format_title(slug))

    if connected?(socket) do
      send(self(), {:load_article, source, slug})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:load_article, source, slug}, socket) do
    case Content.get_article(source, slug) do
      {:ok, article, html} ->
        related = CrossLinks.get_related(article, limit: 5)

        {:noreply,
         socket
         |> assign(article: article, html: html, loading: false, related: related)
         |> assign(page_title: article.title)}

      {:error, :not_found} ->
        {:noreply, assign(socket, loading: false, error: :not_found)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-6xl mx-auto px-4 py-8">
        <div class="flex gap-8">
          <article role="article" aria-label={@slug} class="flex-1 min-w-0">
            <.source_badge source={@source} />

            <h1 class="text-2xl font-mono font-bold mt-4 mb-6">
              {if @article, do: @article.title, else: format_title(@slug)}
            </h1>

            <.loading :if={@loading} />

            <.not_found :if={@error == :not_found} source={@source} slug={@slug} />

            <div
              :if={@article && !@loading}
              id="article-content"
              class="article-body font-mono prose prose-invert max-w-none"
            >
              {raw(@html)}
            </div>

            <.article_meta :if={@article} article={@article} />
          </article>

          <.related_sidebar :if={@related != []} related={@related} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp related_sidebar(assigns) do
    ~H"""
    <aside class="w-64 flex-shrink-0 hidden lg:block">
      <div class="sticky top-8 border border-zinc-800 rounded-lg p-4">
        <h2 class="text-sm font-mono font-bold text-zinc-400 mb-3">Related Articles</h2>
        <ul class="space-y-3">
          <li :for={rel <- @related} class="text-sm">
            <.link
              navigate={article_path(rel.source, rel.slug)}
              class="block hover:bg-zinc-800/50 rounded p-2 -mx-2 transition-colors"
            >
              <div class="flex items-center gap-2 mb-1">
                <.mini_source_badge source={rel.source} />
                <span class="font-mono text-white truncate">{rel.title}</span>
              </div>
              <div class="flex items-center gap-2 text-xs text-zinc-500 font-mono">
                <span>{format_relationship(rel.relationship)}</span>
                <span class="text-zinc-600">|</span>
                <span>{format_confidence(rel.confidence)}</span>
              </div>
            </.link>
          </li>
        </ul>
      </div>
    </aside>
    """
  end

  defp mini_source_badge(assigns) do
    colors = %{
      osrs: "bg-amber-900 text-amber-300",
      nlab: "bg-blue-900 text-blue-300",
      wikipedia: "bg-zinc-700 text-zinc-300",
      vintage_machinery: "bg-orange-900 text-orange-300",
      wikiart: "bg-purple-900 text-purple-300"
    }

    labels = %{
      osrs: "OSRS",
      nlab: "nLab",
      wikipedia: "Wiki",
      vintage_machinery: "VM",
      wikiart: "Art"
    }

    assigns =
      assigns
      |> assign(:color, Map.get(colors, assigns.source, "bg-zinc-800 text-zinc-400"))
      |> assign(:label, Map.get(labels, assigns.source, "?"))

    ~H"""
    <span class={"flex-shrink-0 px-1.5 py-0.5 rounded text-xs font-mono #{@color}"}>
      {@label}
    </span>
    """
  end

  defp source_badge(assigns) do
    labels = %{
      osrs: "OSRS Wiki",
      nlab: "nLab",
      wikipedia: "Wikipedia",
      vintage_machinery: "Vintage Machinery",
      wikiart: "WikiArt"
    }

    colors = %{
      osrs: "bg-amber-800 text-amber-100",
      nlab: "bg-blue-800 text-blue-100",
      wikipedia: "bg-zinc-700 text-zinc-100",
      vintage_machinery: "bg-orange-800 text-orange-100",
      wikiart: "bg-purple-800 text-purple-100"
    }

    assigns =
      assigns
      |> assign(:label, Map.get(labels, assigns.source, to_string(assigns.source)))
      |> assign(:color, Map.get(colors, assigns.source, "bg-zinc-800 text-zinc-300"))

    ~H"""
    <span class={"inline-flex items-center rounded-md px-2 py-1 text-xs font-mono #{@color}"}>
      {@label}
    </span>
    """
  end

  defp loading(assigns) do
    ~H"""
    <div class="text-zinc-500 font-mono animate-pulse">
      Loading article...
    </div>
    """
  end

  defp not_found(assigns) do
    upstream_url = upstream_url(assigns.source, assigns.slug)
    assigns = assign(assigns, :upstream_url, upstream_url)

    ~H"""
    <div class="text-zinc-500 font-mono space-y-4">
      <p>Article not found in local cache.</p>
      <p :if={@upstream_url}>
        <a
          href={@upstream_url}
          target="_blank"
          rel="noopener noreferrer"
          class="text-blue-400 hover:underline"
        >
          View on source wiki ->
        </a>
      </p>
    </div>
    """
  end

  defp article_meta(assigns) do
    ~H"""
    <footer class="mt-8 pt-4 border-t border-zinc-700 text-sm text-zinc-500 font-mono">
      <div class="flex flex-wrap gap-4">
        <span :if={@article.license}>License: {@article.license}</span>
        <span :if={@article.synced_at}>
          Last synced: {Calendar.strftime(@article.synced_at, "%Y-%m-%d %H:%M UTC")}
        </span>
        <a
          :if={@article.upstream_url}
          href={@article.upstream_url}
          target="_blank"
          rel="noopener noreferrer"
          class="text-blue-400 hover:underline"
        >
          View original
        </a>
      </div>
    </footer>
    """
  end

  @path_to_source %{
    "/osrs/" => :osrs,
    "/nlab/" => :nlab,
    "/wikipedia/" => :wikipedia,
    "/machines/" => :vintage_machinery,
    "/art/" => :wikiart
  }

  defp source_and_slug_from_uri(uri, params) do
    path = URI.parse(uri).path
    slug = params["slug"] || "unknown"

    source =
      @path_to_source
      |> Enum.find_value(:osrs, fn {prefix, source} ->
        if String.starts_with?(path, prefix), do: source
      end)

    {source, slug}
  end

  defp format_title(slug) do
    slug
    |> String.replace(~r/[-_]/, " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp article_path(:osrs, slug), do: ~p"/osrs/#{slug}"
  defp article_path(:nlab, slug), do: ~p"/nlab/#{slug}"
  defp article_path(:wikipedia, slug), do: ~p"/wikipedia/#{slug}"
  defp article_path(:vintage_machinery, slug), do: ~p"/machines/#{slug}"
  defp article_path(:wikiart, slug), do: ~p"/art/#{slug}"
  defp article_path(_source, slug), do: "/#{slug}"

  defp format_relationship(:same_topic), do: "Same topic"
  defp format_relationship(:related), do: "Related"
  defp format_relationship(:see_also), do: "See also"
  defp format_relationship(r), do: to_string(r)

  defp format_confidence(nil), do: ""
  defp format_confidence(c) when c >= 0.8, do: "High"
  defp format_confidence(c) when c >= 0.5, do: "Medium"
  defp format_confidence(_), do: "Low"

  defp upstream_url(:osrs, slug), do: "https://oldschool.runescape.wiki/w/#{URI.encode(slug)}"
  defp upstream_url(:nlab, slug), do: "https://ncatlab.org/nlab/show/#{URI.encode(slug)}"
  defp upstream_url(:wikipedia, slug), do: "https://en.wikipedia.org/wiki/#{URI.encode(slug)}"

  defp upstream_url(:vintage_machinery, slug),
    do: "https://vintagemachinery.org/#{String.replace(slug, "__", "/")}"

  defp upstream_url(:wikiart, slug),
    do: "https://www.wikiart.org/en/#{String.replace(slug, "__", "/")}"

  defp upstream_url(_, _), do: nil
end
