defmodule WikiWeb.Admin.SyncLive do
  @moduledoc """
  Admin sync dashboard (Tailnet-only).
  """

  use WikiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, sync_runs: [], page_title: "Sync Status")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto px-4 py-8">
        <h1 class="text-2xl font-mono font-bold mb-6">Sync Status</h1>

        <div class="space-y-4">
          <div :for={_run <- @sync_runs} class="border border-zinc-800 rounded p-4">
            <!-- Sync run details -->
          </div>
        </div>

        <div :if={@sync_runs == []} class="text-zinc-500 font-mono">
          No sync runs recorded yet.
        </div>
      </div>
    </Layouts.app>
    """
  end
end
