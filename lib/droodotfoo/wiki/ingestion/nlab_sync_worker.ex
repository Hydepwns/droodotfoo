defmodule Droodotfoo.Wiki.Ingestion.NLabSyncWorker do
  @moduledoc """
  Oban worker for syncing nLab wiki content.

  Runs daily at 4am (configured in runtime.exs) to fetch
  recent changes from the nLab git repository.

  ## Manual Invocation

      # Sync recent changes (last 7 days)
      %{} |> Droodotfoo.Wiki.Ingestion.NLabSyncWorker.new() |> Oban.insert()

      # Full sync (all pages)
      %{full_sync: true} |> Droodotfoo.Wiki.Ingestion.NLabSyncWorker.new() |> Oban.insert()

      # Sync changes since specific date
      %{since: "2025-01-01T00:00:00Z"} |> Droodotfoo.Wiki.Ingestion.NLabSyncWorker.new() |> Oban.insert()

  """

  use Oban.Worker,
    queue: :ingestion,
    max_attempts: 2,
    unique: [period: 3600, states: [:available, :scheduled, :executing]]

  require Logger

  alias Droodotfoo.Wiki.Ingestion.{NLabPipeline, SyncRun, SyncWorkerHelper}

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    cond do
      Map.get(args, "full_sync") ->
        full_sync()

      since = Map.get(args, "since") ->
        sync_since(parse_datetime(since))

      true ->
        sync_recent_changes()
    end
  end

  defp sync_recent_changes do
    SyncWorkerHelper.sync_recent_changes(:nlab, &NLabPipeline.sync_recent_changes/1, "nLab sync")
  end

  defp sync_since(since) do
    run = SyncRun.start!(:nlab, "since:#{DateTime.to_iso8601(since)}")

    Logger.info("nLab sync: changes since #{since}")

    NLabPipeline.sync_recent_changes(since)
    |> SyncWorkerHelper.handle_result(run, "nLab sync")
  end

  defp full_sync do
    run = SyncRun.start!(:nlab, "full_sync")

    Logger.info("nLab full sync starting")

    NLabPipeline.sync_all()
    |> SyncWorkerHelper.handle_result(run, "nLab full sync")
  end

  defp parse_datetime(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp parse_datetime(_), do: nil
end
