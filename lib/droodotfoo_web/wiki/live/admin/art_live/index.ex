defmodule DroodotfooWeb.Wiki.Admin.ArtLive.Index do
  @moduledoc """
  Admin index for WikiArt curation.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Wiki.Layouts
  alias Droodotfoo.Wiki.WikiArt

  import Phoenix.Component

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "WikiArt Curation")
     |> assign(current_path: "/admin/art")
     |> assign(search: "")
     |> assign(artworks: WikiArt.list_artworks(limit: 50))}
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => query}}, socket) do
    artworks =
      case query do
        "" -> WikiArt.list_artworks(limit: 50)
        q -> WikiArt.search(q, limit: 50)
      end

    {:noreply, assign(socket, search: query, artworks: artworks)}
  end

  def handle_event("delete", %{"slug" => slug}, socket) do
    case WikiArt.get_artwork(slug) do
      nil ->
        {:noreply, put_flash(socket, :error, "Artwork not found")}

      artwork ->
        case WikiArt.remove_artwork(artwork) do
          {:ok, _} ->
            artworks = WikiArt.list_artworks(limit: 50)

            {:noreply,
             socket |> put_flash(:info, "Artwork removed") |> assign(artworks: artworks)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to remove artwork")}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <div class="max-w-6xl mx-auto px-4 py-8">
        <header class="flex items-center justify-between mb-8">
          <h1 class="text-2xl font-mono font-bold">WikiArt Curation</h1>
          <.link navigate="/admin/art/add" class="btn-primary">
            + Add Artwork
          </.link>
        </header>

        <form phx-change="search" class="mb-6">
          <input
            type="text"
            name="search[q]"
            value={@search}
            placeholder="Search artworks..."
            phx-debounce="300"
            class="w-full"
          />
        </form>

        <div :if={@artworks == []} class="text-center py-12 text-zinc-500 font-mono">
          No artworks curated yet.
        </div>

        <div :if={@artworks != []} class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <.artwork_card :for={artwork <- @artworks} artwork={artwork} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp artwork_card(assigns) do
    ~H"""
    <div class="border border-zinc-800 rounded-lg overflow-hidden">
      <div :if={@artwork.metadata["image_url"]} class="aspect-square bg-zinc-900">
        <img
          src={@artwork.metadata["image_url"]}
          alt={@artwork.title}
          class="w-full h-full object-cover"
          loading="lazy"
        />
      </div>

      <div class="p-4">
        <h2 class="font-mono font-bold truncate">{@artwork.title}</h2>
        <p class="text-sm text-zinc-400 font-mono">{@artwork.metadata["artist"]}</p>
        <p :if={@artwork.metadata["year"]} class="text-xs text-zinc-500 font-mono">
          {@artwork.metadata["year"]}
        </p>

        <div class="mt-4 flex gap-2">
          <.link navigate={"/art/#{@artwork.slug}"} class="text-sm text-blue-400 hover:underline">
            View
          </.link>
          <.link
            navigate={"/admin/art/#{@artwork.slug}/edit"}
            class="text-sm text-zinc-400 hover:underline"
          >
            Edit
          </.link>
          <button
            phx-click="delete"
            phx-value-slug={@artwork.slug}
            data-confirm="Remove this artwork?"
            class="text-sm text-red-400 hover:underline"
          >
            Delete
          </button>
        </div>
      </div>
    </div>
    """
  end
end
