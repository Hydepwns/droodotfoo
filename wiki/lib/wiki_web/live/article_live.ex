defmodule WikiWeb.ArticleLive do
  @moduledoc """
  Single LiveView for all wiki sources.

  The source is derived from the URL path via handle_params.
  Content is loaded asynchronously after mount.
  """

  use WikiWeb, :live_view

  alias Wiki.Content

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, article: nil, html: "", loading: true, error: nil)}
  end

  @impl true
  def handle_params(params, uri, socket) do
    {source, slug} = source_and_slug_from_uri(uri, params)

    socket =
      socket
      |> assign(source: source, slug: slug, loading: true, error: nil)
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
        {:noreply,
         socket
         |> assign(article: article, html: html, loading: false)
         |> assign(page_title: article.title)}

      {:error, :not_found} ->
        {:noreply, assign(socket, loading: false, error: :not_found)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <article role="article" aria-label={@slug} class="max-w-4xl mx-auto px-4 py-8">
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
    </Layouts.app>
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

  defp source_and_slug_from_uri(uri, params) do
    path = URI.parse(uri).path
    slug = params["slug"] || "unknown"

    cond do
      String.starts_with?(path, "/osrs/") -> {:osrs, slug}
      String.starts_with?(path, "/nlab/") -> {:nlab, slug}
      String.starts_with?(path, "/wikipedia/") -> {:wikipedia, slug}
      String.starts_with?(path, "/vintage/") -> {:vintage_machinery, slug}
      String.starts_with?(path, "/art/") -> {:wikiart, slug}
      true -> {:osrs, slug}
    end
  end

  defp format_title(slug) do
    slug
    |> String.replace(~r/[-_]/, " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp upstream_url(:osrs, slug), do: "https://oldschool.runescape.wiki/w/#{URI.encode(slug)}"
  defp upstream_url(:nlab, slug), do: "https://ncatlab.org/nlab/show/#{URI.encode(slug)}"
  defp upstream_url(:wikipedia, slug), do: "https://en.wikipedia.org/wiki/#{URI.encode(slug)}"
  defp upstream_url(_, _), do: nil
end
