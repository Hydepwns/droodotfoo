defmodule DroodotfooWeb.Wiki.Admin.SyncLive do
  @moduledoc """
  Admin sync dashboard for monitoring ingestion status.

  Tailnet-only access. Shows:
  - Source status cards with last sync time
  - Recent sync runs with stats
  - Manual sync triggers
  - Live updates via PubSub
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Wiki.Layouts
  alias Droodotfoo.Wiki.Ingestion.SyncRun
  alias Droodotfoo.Wiki.Content

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Droodotfoo.PubSub, "ingestion:*")
      send(self(), :refresh)
    end

    {:ok,
     assign(socket,
       source_statuses: [],
       recent_runs: [],
       article_counts: %{},
       page_title: "Sync Dashboard",
       current_path: "/admin/sync"
     )}
  end

  @impl true
  def handle_info(:refresh, socket) do
    socket =
      socket
      |> assign(source_statuses: SyncRun.source_statuses())
      |> assign(recent_runs: SyncRun.list_recent(20))
      |> assign(article_counts: Content.count_by_source())

    {:noreply, socket}
  end

  def handle_info({:sync_started, source}, socket) do
    socket =
      socket
      |> assign(source_statuses: SyncRun.source_statuses())
      |> put_flash(:info, "Sync started for #{source}")

    {:noreply, socket}
  end

  def handle_info({:sync_complete, _stats}, socket) do
    send(self(), :refresh)
    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def handle_event("trigger_sync", %{"source" => source}, socket) do
    source_atom = String.to_existing_atom(source)

    case source_atom do
      :osrs ->
        %{} |> Droodotfoo.Wiki.Ingestion.OSRSSyncWorker.new() |> Oban.insert()
        {:noreply, put_flash(socket, :info, "OSRS sync queued")}

      :nlab ->
        %{} |> Droodotfoo.Wiki.Ingestion.NLabSyncWorker.new() |> Oban.insert()
        {:noreply, put_flash(socket, :info, "nLab sync queued")}

      _ ->
        {:noreply, put_flash(socket, :error, "Sync not implemented for #{source}")}
    end
  end

  def handle_event("trigger_full_sync", %{"source" => source}, socket) do
    source_atom = String.to_existing_atom(source)

    case source_atom do
      :osrs ->
        %{full_sync: true} |> Droodotfoo.Wiki.Ingestion.OSRSSyncWorker.new() |> Oban.insert()
        {:noreply, put_flash(socket, :info, "OSRS full sync queued")}

      :nlab ->
        %{full_sync: true} |> Droodotfoo.Wiki.Ingestion.NLabSyncWorker.new() |> Oban.insert()
        {:noreply, put_flash(socket, :info, "nLab full sync queued")}

      _ ->
        {:noreply, put_flash(socket, :error, "Full sync not implemented for #{source}")}
    end
  end

  def handle_event("refresh", _params, socket) do
    send(self(), :refresh)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <div class="max-w-6xl mx-auto px-4 py-8">
        <div class="flex items-center justify-between mb-8">
          <h1 class="text-2xl font-mono font-bold">Sync Dashboard</h1>
          <button
            phx-click="refresh"
            class="px-3 py-1 bg-zinc-800 hover:bg-zinc-700 rounded font-mono text-sm"
          >
            Refresh
          </button>
        </div>

        <section class="mb-10">
          <h2 class="text-lg font-mono font-bold mb-4 text-zinc-400">Sources</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <.source_card
              :for={status <- @source_statuses}
              status={status}
              article_count={Map.get(@article_counts, status.source, 0)}
            />
          </div>
        </section>

        <section>
          <h2 class="text-lg font-mono font-bold mb-4 text-zinc-400">Recent Sync Runs</h2>
          <.runs_table runs={@recent_runs} />
        </section>
      </div>
    </Layouts.app>
    """
  end

  defp source_card(assigns) do
    ~H"""
    <div class={"border rounded-lg p-4 #{status_border_color(@status)}"}>
      <div class="flex items-center justify-between mb-3">
        <h3 class="font-mono font-bold text-lg">{source_label(@status.source)}</h3>
        <.status_badge running={@status.running} last_run={@status.last_run} />
      </div>

      <dl class="space-y-1 text-sm font-mono text-zinc-400 mb-4">
        <div class="flex justify-between">
          <dt>Articles:</dt>
          <dd class="text-white">{@article_count}</dd>
        </div>
        <div class="flex justify-between">
          <dt>Last sync:</dt>
          <dd class="text-white">{format_time(@status.last_success)}</dd>
        </div>
        <div :if={@status.last_run} class="flex justify-between">
          <dt>Last run:</dt>
          <dd class={run_status_color(@status.last_run.status)}>
            {format_status(@status.last_run.status)}
          </dd>
        </div>
      </dl>

      <div class="flex gap-2">
        <button
          phx-click="trigger_sync"
          phx-value-source={@status.source}
          disabled={@status.running}
          class="flex-1 px-3 py-1.5 bg-blue-600 hover:bg-blue-500 disabled:bg-zinc-700 disabled:cursor-not-allowed rounded font-mono text-sm"
        >
          {if @status.running, do: "Running...", else: "Sync"}
        </button>
        <button
          phx-click="trigger_full_sync"
          phx-value-source={@status.source}
          disabled={@status.running}
          class="px-3 py-1.5 bg-zinc-700 hover:bg-zinc-600 disabled:bg-zinc-800 disabled:cursor-not-allowed rounded font-mono text-sm"
          title="Full sync (all pages)"
        >
          Full
        </button>
      </div>
    </div>
    """
  end

  defp status_badge(assigns) do
    ~H"""
    <span :if={@running} class="px-2 py-0.5 bg-yellow-600 text-yellow-100 rounded text-xs font-mono">
      RUNNING
    </span>
    <span
      :if={!@running && @last_run && @last_run.status == :completed}
      class="px-2 py-0.5 bg-green-800 text-green-200 rounded text-xs font-mono"
    >
      OK
    </span>
    <span
      :if={!@running && @last_run && @last_run.status == :failed}
      class="px-2 py-0.5 bg-red-800 text-red-200 rounded text-xs font-mono"
    >
      FAILED
    </span>
    <span
      :if={!@running && !@last_run}
      class="px-2 py-0.5 bg-zinc-700 text-zinc-300 rounded text-xs font-mono"
    >
      NEVER
    </span>
    """
  end

  defp runs_table(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="w-full font-mono text-sm">
        <thead class="text-left text-zinc-500 border-b border-zinc-800">
          <tr>
            <th class="py-2 pr-4">Source</th>
            <th class="py-2 pr-4">Strategy</th>
            <th class="py-2 pr-4">Status</th>
            <th class="py-2 pr-4">Processed</th>
            <th class="py-2 pr-4">Created</th>
            <th class="py-2 pr-4">Updated</th>
            <th class="py-2 pr-4">Started</th>
            <th class="py-2">Duration</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={run <- @runs} class="border-b border-zinc-800/50 hover:bg-zinc-800/30">
            <td class="py-2 pr-4">{source_label(run.source)}</td>
            <td class="py-2 pr-4 text-zinc-400">{run.strategy || "-"}</td>
            <td class="py-2 pr-4">
              <span class={run_status_color(run.status)}>{format_status(run.status)}</span>
            </td>
            <td class="py-2 pr-4">{run.pages_processed}</td>
            <td class="py-2 pr-4 text-green-400">+{run.pages_created}</td>
            <td class="py-2 pr-4 text-blue-400">~{run.pages_updated}</td>
            <td class="py-2 pr-4 text-zinc-400">{format_time(run.started_at)}</td>
            <td class="py-2 text-zinc-400">{format_duration(run.started_at, run.completed_at)}</td>
          </tr>
        </tbody>
      </table>

      <div :if={@runs == []} class="py-8 text-center text-zinc-500 font-mono">
        No sync runs recorded yet.
      </div>
    </div>
    """
  end

  # Helpers

  defp source_label(:osrs), do: "OSRS Wiki"
  defp source_label(:nlab), do: "nLab"
  defp source_label(:wikipedia), do: "Wikipedia"
  defp source_label(:vintage_machinery), do: "Vintage Machinery"
  defp source_label(:wikiart), do: "WikiArt"
  defp source_label(source), do: to_string(source)

  defp status_border_color(%{running: true}), do: "border-yellow-600"
  defp status_border_color(%{last_run: %{status: :failed}}), do: "border-red-800"
  defp status_border_color(%{last_run: %{status: :completed}}), do: "border-zinc-700"
  defp status_border_color(_), do: "border-zinc-800"

  defp run_status_color(:running), do: "text-yellow-400"
  defp run_status_color(:completed), do: "text-green-400"
  defp run_status_color(:failed), do: "text-red-400"
  defp run_status_color(_), do: "text-zinc-400"

  defp format_status(:running), do: "running"
  defp format_status(:completed), do: "completed"
  defp format_status(:failed), do: "failed"
  defp format_status(nil), do: "-"
  defp format_status(status), do: to_string(status)

  defp format_time(nil), do: "never"

  defp format_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> Calendar.strftime(datetime, "%Y-%m-%d")
    end
  end

  defp format_duration(nil, _), do: "-"
  defp format_duration(_, nil), do: "running..."

  defp format_duration(started, completed) do
    seconds = DateTime.diff(completed, started, :second)

    cond do
      seconds < 60 -> "#{seconds}s"
      seconds < 3600 -> "#{div(seconds, 60)}m #{rem(seconds, 60)}s"
      true -> "#{div(seconds, 3600)}h #{div(rem(seconds, 3600), 60)}m"
    end
  end
end
