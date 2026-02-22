defmodule WikiWeb.Parts.ShowLive do
  use WikiWeb, :live_view

  @impl true
  def mount(%{"number" => number}, _session, socket) do
    {:ok, assign(socket, part_number: number, page_title: "Part #{number}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto px-4 py-8">
        <h1 class="text-2xl font-mono font-bold mb-6">Part {@part_number}</h1>
        <p class="text-zinc-500 font-mono">Part details coming soon.</p>
      </div>
    </Layouts.app>
    """
  end
end
