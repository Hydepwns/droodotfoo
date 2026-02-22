defmodule WikiWeb.Library.UploadLive do
  use WikiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Upload Document")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-2xl mx-auto px-4 py-8">
        <h1 class="text-2xl font-mono font-bold mb-6">Upload Document</h1>
        <p class="text-zinc-500 font-mono">Upload form coming soon.</p>
      </div>
    </Layouts.app>
    """
  end
end
