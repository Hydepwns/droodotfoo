defmodule WikiWeb.ArticleLive do
  @moduledoc """
  Single LiveView for all wiki sources.

  The source is derived from the URL path via handle_params.
  """

  use WikiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, article: nil, html: "", cross_refs: [])}
  end

  @impl true
  def handle_params(params, uri, socket) do
    {source, slug} = source_and_slug_from_uri(uri, params)

    # TODO: Implement Wiki.Content.get_article/2
    socket =
      socket
      |> assign(source: source, slug: slug)
      |> assign(page_title: slug)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <article role="article" aria-label={@slug} class="max-w-4xl mx-auto px-4 py-8">
        <.source_badge source={@source} />

        <h1 class="text-2xl font-mono font-bold mt-4 mb-6">{@slug}</h1>

        <div :if={@article == nil} class="text-zinc-500 font-mono">
          Article not found. This page will be populated after ingestion.
        </div>

        <div :if={@article} id="article-content" class="article-body font-mono prose prose-invert max-w-none">
          {raw(@html)}
        </div>
      </article>
    </Layouts.app>
    """
  end

  defp source_badge(assigns) do
    labels = %{
      osrs: "OSRS Wiki",
      nlab: "nLab",
      wikipedia: "Wikipedia"
    }

    assigns = assign(assigns, :label, Map.get(labels, assigns.source, to_string(assigns.source)))

    ~H"""
    <span class="inline-flex items-center rounded-md bg-zinc-800 px-2 py-1 text-xs font-mono text-zinc-300">
      {@label}
    </span>
    """
  end

  defp source_and_slug_from_uri(uri, params) do
    path = URI.parse(uri).path
    slug = params["slug"] || "Unknown"

    cond do
      String.starts_with?(path, "/osrs/") -> {:osrs, slug}
      String.starts_with?(path, "/nlab/") -> {:nlab, slug}
      String.starts_with?(path, "/wikipedia/") -> {:wikipedia, slug}
      true -> {:osrs, slug}
    end
  end
end
