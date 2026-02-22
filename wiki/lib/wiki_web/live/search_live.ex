defmodule WikiWeb.SearchLive do
  @moduledoc """
  Cross-source search page.
  """

  use WikiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "", results: [], page_title: "Search")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto px-4 py-8">
        <h1 class="text-2xl font-mono font-bold mb-6">Search</h1>

        <form phx-submit="search" class="mb-8">
          <input
            type="text"
            name="q"
            value={@query}
            placeholder="Search articles..."
            class="w-full px-4 py-2 bg-zinc-900 border border-zinc-700 rounded font-mono text-white"
            autofocus
          />
        </form>

        <div :if={@results == []} class="text-zinc-500 font-mono">
          Enter a search term to find articles across all sources.
        </div>

        <ul :if={@results != []} class="space-y-4">
          <li :for={result <- @results} class="border-b border-zinc-800 pb-4">
            <.link navigate={result.url} class="text-blue-400 hover:underline font-mono">
              {result.title}
            </.link>
            <p class="text-zinc-500 text-sm font-mono mt-1">{result.snippet}</p>
          </li>
        </ul>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    # TODO: Implement Wiki.Search.search/1
    {:noreply, assign(socket, query: query, results: [])}
  end
end
