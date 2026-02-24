defmodule DroodotfooWeb.Wiki.Parts.IndexLive do
  @moduledoc """
  Parts catalog index with search and filtering.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Wiki.Layouts
  alias Droodotfoo.Wiki.Parts
  alias Droodotfoo.Wiki.Parts.Part

  import Phoenix.Component

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Parts Catalog")
     |> assign(current_path: "/parts")
     |> assign(search: "")
     |> assign(category: nil)
     |> assign(parts: [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    search = Map.get(params, "q", "")
    category = Map.get(params, "category")

    parts = load_parts(search, category)

    {:noreply,
     socket
     |> assign(search: search)
     |> assign(category: category)
     |> assign(parts: parts)}
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => query}}, socket) do
    params = build_params(query, socket.assigns.category)
    {:noreply, push_patch(socket, to: "/parts?#{URI.encode_query(params)}")}
  end

  def handle_event("filter", %{"category" => category}, socket) do
    category = if category == "", do: nil, else: category
    params = build_params(socket.assigns.search, category)
    {:noreply, push_patch(socket, to: "/parts?#{URI.encode_query(params)}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <div class="max-w-6xl mx-auto px-4 py-8">
        <header class="flex items-center justify-between mb-8">
          <h1 class="text-2xl font-mono font-bold">Parts Catalog</h1>
          <.link navigate="/parts/add" class="btn-primary">
            + Add Part
          </.link>
        </header>

        <div class="flex gap-4 mb-6">
          <form phx-submit="search" phx-change="search" class="flex-1">
            <input
              type="text"
              name="search[q]"
              value={@search}
              placeholder="Search parts..."
              phx-debounce="300"
              class="w-full"
            />
          </form>

          <form phx-change="filter">
            <select name="category" class="input">
              <option value="">All Categories</option>
              <%= for cat <- Part.categories() do %>
                <option value={cat} selected={to_string(cat) == @category}>
                  {format_category(cat)}
                </option>
              <% end %>
            </select>
          </form>
        </div>

        <div :if={@parts == []} class="text-center py-12 text-zinc-500 font-mono">
          No parts found.
          <.link navigate="/parts/add" class="text-blue-400 hover:underline">
            Add one?
          </.link>
        </div>

        <div :if={@parts != []} class="space-y-4">
          <.part_card :for={part <- @parts} part={part} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp part_card(assigns) do
    ~H"""
    <.link
      navigate={"/parts/#{@part.part_number}"}
      class="block border border-zinc-800 rounded-lg p-4 hover:bg-zinc-800/50 transition-colors"
    >
      <div class="flex items-start justify-between">
        <div>
          <h2 class="font-mono font-bold text-lg">{@part.name}</h2>
          <p class="text-sm text-zinc-400 font-mono">{@part.part_number}</p>
        </div>
        <span class="px-2 py-1 bg-zinc-800 rounded text-xs font-mono text-zinc-300">
          {format_category(@part.category)}
        </span>
      </div>

      <p :if={@part.description} class="mt-2 text-sm text-zinc-400 line-clamp-2">
        {@part.description}
      </p>

      <div class="mt-3 flex items-center gap-4 text-xs text-zinc-500 font-mono">
        <span :if={@part.manufacturer}>{@part.manufacturer}</span>
        <span :if={@part.price_cents}>{Part.format_price(@part)}</span>
      </div>
    </.link>
    """
  end

  defp load_parts("", nil), do: Parts.list_parts(%{"limit" => 50})

  defp load_parts(search, nil) when search != "" do
    Parts.search_parts(search, limit: 50)
  end

  defp load_parts("", category) do
    Parts.list_parts(%{"category" => category, "limit" => 50})
  end

  defp load_parts(search, category) do
    Parts.search_parts(search, limit: 50)
    |> Enum.filter(&(to_string(&1.category) == category))
  end

  defp build_params(search, category) do
    []
    |> then(fn p -> if search != "", do: [{"q", search} | p], else: p end)
    |> then(fn p -> if category, do: [{"category", category} | p], else: p end)
  end

  defp format_category(cat) do
    cat
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
