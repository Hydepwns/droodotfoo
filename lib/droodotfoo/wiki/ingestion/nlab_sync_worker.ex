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

  alias Droodotfoo.Wiki.Ingestion.{NLabPipeline, SyncRun}

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
    run = SyncRun.start!(:nlab, "recent_changes")
    since = SyncRun.last_completed_at(:nlab)

    Logger.info("nLab sync: recent changes since #{inspect(since)}")

    result = NLabPipeline.sync_recent_changes(since)

    case result do
      {:ok, stats} ->
        SyncRun.complete!(run, {:ok, to_sync_stats(stats)})
        Logger.info("nLab sync completed: #{inspect(stats)}")
        :ok

      {:error, reason} ->
        SyncRun.complete!(run, {:error, reason})
        Logger.error("nLab sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp sync_since(since) do
    run = SyncRun.start!(:nlab, "since:#{DateTime.to_iso8601(since)}")

    Logger.info("nLab sync: changes since #{since}")

    result = NLabPipeline.sync_recent_changes(since)

    case result do
      {:ok, stats} ->
        SyncRun.complete!(run, {:ok, to_sync_stats(stats)})
        Logger.info("nLab sync completed: #{inspect(stats)}")
        :ok

      {:error, reason} ->
        SyncRun.complete!(run, {:error, reason})
        Logger.error("nLab sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp full_sync do
    run = SyncRun.start!(:nlab, "full_sync")

    Logger.info("nLab full sync starting")

    result = NLabPipeline.sync_all()

    case result do
      {:ok, stats} ->
        SyncRun.complete!(run, {:ok, to_sync_stats(stats)})
        Logger.info("nLab full sync completed: #{inspect(stats)}")
        :ok

      {:error, reason} ->
        SyncRun.complete!(run, {:error, reason})
        Logger.error("nLab full sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp to_sync_stats(stats) do
    %{
      pages_processed: stats.created + stats.updated + stats.unchanged + stats.errors,
      pages_created: stats.created,
      pages_updated: stats.updated,
      pages_unchanged: stats.unchanged
    }
  end

  defp parse_datetime(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp parse_datetime(_), do: nil
end
