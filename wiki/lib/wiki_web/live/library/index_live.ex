defmodule WikiWeb.Library.IndexLive do
  @moduledoc """
  Personal document library index (Tailnet-only).
  """

  use WikiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, documents: [], page_title: "Library")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto px-4 py-8">
        <div class="flex justify-between items-center mb-6">
          <h1 class="text-2xl font-mono font-bold">Document Library</h1>
          <.link navigate="/upload" class="text-blue-400 hover:underline font-mono">
            + Upload
          </.link>
        </div>

        <div :if={@documents == []} class="text-zinc-500 font-mono">
          No documents uploaded yet.
        </div>
      </div>
    </Layouts.app>
    """
  end
end
