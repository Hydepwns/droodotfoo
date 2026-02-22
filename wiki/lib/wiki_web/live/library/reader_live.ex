defmodule WikiWeb.Library.ReaderLive do
  use WikiWeb, :live_view

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    {:ok, assign(socket, slug: slug, page_title: slug)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto px-4 py-8">
        <h1 class="text-2xl font-mono font-bold mb-6">{@slug}</h1>
        <p class="text-zinc-500 font-mono">Document reader coming soon.</p>
      </div>
    </Layouts.app>
    """
  end
end
