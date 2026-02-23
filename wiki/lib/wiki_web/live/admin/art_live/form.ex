defmodule WikiWeb.Admin.ArtLive.Form do
  @moduledoc """
  Form for adding/editing WikiArt artworks.
  """

  use WikiWeb, :live_view

  alias Wiki.WikiArt

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Add Artwork")
     |> assign(artwork: nil)
     |> assign(form: to_form(default_form()))}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _uri, socket) do
    case WikiArt.get_artwork(slug) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Artwork not found")
         |> push_navigate(to: ~p"/admin/art")}

      artwork ->
        form_data = %{
          "slug" => artwork.slug,
          "title" => artwork.title,
          "artist" => artwork.metadata["artist"],
          "year" => artwork.metadata["year"],
          "style" => artwork.metadata["style"],
          "genre" => artwork.metadata["genre"],
          "description" => artwork.extracted_text,
          "image_url" => artwork.metadata["image_url"],
          "wikiart_url" => artwork.upstream_url
        }

        {:noreply,
         socket
         |> assign(page_title: "Edit Artwork")
         |> assign(artwork: artwork)
         |> assign(form: to_form(form_data))}
    end
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event("validate", %{"artwork" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params))}
  end

  def handle_event("save", %{"artwork" => params}, socket) do
    artwork_data = %{
      slug: params["slug"] || slugify(params["title"]),
      title: params["title"],
      artist: params["artist"],
      year: parse_year(params["year"]),
      style: params["style"],
      genre: params["genre"],
      description: params["description"],
      image_url: params["image_url"],
      wikiart_url: params["wikiart_url"]
    }

    result =
      case socket.assigns.artwork do
        nil -> WikiArt.add_artwork(artwork_data)
        existing -> WikiArt.update_artwork(existing, artwork_data)
      end

    case result do
      {:ok, article} ->
        {:noreply,
         socket
         |> put_flash(:info, "Artwork saved")
         |> push_navigate(to: ~p"/art/#{article.slug}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to save: #{inspect(reason)}")}
    end
  end

  def handle_event("import_url", %{"url" => url}, socket) do
    case parse_wikiart_url(url) do
      {:ok, slug, artist} ->
        form_data =
          socket.assigns.form.source
          |> Map.merge(%{
            "slug" => slug,
            "artist" => artist,
            "wikiart_url" => url
          })

        {:noreply, assign(socket, form: to_form(form_data))}

      :error ->
        {:noreply, put_flash(socket, :error, "Invalid WikiArt URL")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-2xl mx-auto px-4 py-8">
        <h1 class="text-2xl font-mono font-bold mb-6">
          {if @artwork, do: "Edit Artwork", else: "Add Artwork"}
        </h1>

        <div class="mb-6 p-4 border border-zinc-800 rounded-lg">
          <p class="text-sm text-zinc-400 font-mono mb-2">Import from WikiArt URL:</p>
          <form phx-submit="import_url" class="flex gap-2">
            <input
              type="url"
              name="url"
              placeholder="https://www.wikiart.org/en/artist/artwork"
              class="input flex-1"
            />
            <button type="submit" class="btn-secondary">Import</button>
          </form>
        </div>

        <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-6">
          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:title]} label="Title" required />
            <.input field={@form[:artist]} label="Artist" required />
          </div>

          <div class="grid grid-cols-3 gap-4">
            <.input field={@form[:year]} label="Year" type="number" />
            <.input field={@form[:style]} label="Style" placeholder="e.g., Impressionism" />
            <.input field={@form[:genre]} label="Genre" placeholder="e.g., landscape" />
          </div>

          <.input field={@form[:description]} type="textarea" label="Description" rows="3" />

          <.input field={@form[:image_url]} label="Image URL" type="url" />

          <.input field={@form[:wikiart_url]} label="WikiArt URL" type="url" />

          <.input
            :if={!@artwork}
            field={@form[:slug]}
            label="Slug"
            placeholder="auto-generated from title"
          />

          <div class="flex justify-end gap-4 pt-4">
            <.link navigate={~p"/admin/art"} class="btn-secondary">Cancel</.link>
            <button type="submit" class="btn-primary">Save Artwork</button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  defp default_form do
    %{
      "slug" => "",
      "title" => "",
      "artist" => "",
      "year" => "",
      "style" => "",
      "genre" => "",
      "description" => "",
      "image_url" => "",
      "wikiart_url" => ""
    }
  end

  defp slugify(nil), do: nil
  defp slugify(""), do: nil

  defp slugify(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end

  defp parse_year(nil), do: nil
  defp parse_year(""), do: nil

  defp parse_year(year) when is_binary(year) do
    case Integer.parse(year) do
      {y, _} -> y
      :error -> nil
    end
  end

  defp parse_year(year) when is_integer(year), do: year

  defp parse_wikiart_url(url) do
    case URI.parse(url) do
      %{host: host, path: path} when host in ["wikiart.org", "www.wikiart.org"] ->
        parts =
          path
          |> String.trim_leading("/en/")
          |> String.split("/")

        case parts do
          [artist, artwork] ->
            slug = "#{artist}__#{artwork}"
            {:ok, slug, humanize(artist)}

          [artist] ->
            {:ok, artist, humanize(artist)}

          _ ->
            :error
        end

      _ ->
        :error
    end
  end

  defp humanize(slug) do
    slug
    |> String.replace(~r/[-_]/, " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
