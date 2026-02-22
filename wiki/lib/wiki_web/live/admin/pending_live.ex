defmodule WikiWeb.Admin.PendingLive do
  @moduledoc """
  Admin pending review dashboard (Tailnet-only).
  """

  use WikiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, articles: [], page_title: "Pending Review")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto px-4 py-8">
        <h1 class="text-2xl font-mono font-bold mb-6">Pending Review</h1>

        <div :if={@articles == []} class="text-zinc-500 font-mono">
          No articles pending review.
        </div>
      </div>
    </Layouts.app>
    """
  end
end
