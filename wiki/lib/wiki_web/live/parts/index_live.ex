defmodule WikiWeb.Parts.IndexLive do
  @moduledoc """
  Auto parts catalog index.
  """

  use WikiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, parts: [], page_title: "Parts Catalog")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto px-4 py-8">
        <div class="flex justify-between items-center mb-6">
          <h1 class="text-2xl font-mono font-bold">Parts Catalog</h1>
          <.link navigate="/parts/add" class="text-blue-400 hover:underline font-mono">
            + Add Part
          </.link>
        </div>

        <div :if={@parts == []} class="text-zinc-500 font-mono">
          No parts catalogued yet.
        </div>
      </div>
    </Layouts.app>
    """
  end
end
