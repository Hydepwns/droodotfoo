defmodule Wiki.Ingestion.OSRSSyncWorker do
  @moduledoc """
  Oban worker for syncing OSRS Wiki content.

  Runs on a cron schedule (every 15 minutes by default) to fetch
  recent changes and update local articles.

  Can also be triggered manually for full category syncs.

  ## Manual Invocation

      # Sync recent changes
      %{} |> Wiki.Ingestion.OSRSSyncWorker.new() |> Oban.insert()

      # Sync a specific category
      %{category: "Items"} |> Wiki.Ingestion.OSRSSyncWorker.new() |> Oban.insert()

      # Full initial sync (all main categories)
      %{full_sync: true} |> Wiki.Ingestion.OSRSSyncWorker.new() |> Oban.insert()

  """

  use Oban.Worker,
    queue: :ingestion,
    max_attempts: 3,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  require Logger

  alias Wiki.Ingestion.{OSRSPipeline, SyncRun}

  @main_categories ~w(Items Monsters NPCs Quests Locations)

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    cond do
      Map.get(args, "full_sync") ->
        full_sync()

      category = Map.get(args, "category") ->
        sync_category(category)

      true ->
        sync_recent_changes()
    end
  end

  defp sync_recent_changes do
    run = SyncRun.start!(:osrs, "recent_changes")
    since = SyncRun.last_completed_at(:osrs)

    Logger.info("OSRS sync: recent changes since #{inspect(since)}")

    result = OSRSPipeline.sync_recent_changes(since)

    case result do
      {:ok, stats} ->
        SyncRun.complete!(run, {:ok, to_sync_stats(stats)})
        Logger.info("OSRS sync completed: #{inspect(stats)}")
        :ok

      {:error, reason} ->
        SyncRun.complete!(run, {:error, reason})
        Logger.error("OSRS sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp sync_category(category) do
    run = SyncRun.start!(:osrs, "category:#{category}")

    Logger.info("OSRS sync: category #{category}")

    result = OSRSPipeline.sync_category(category)

    case result do
      {:ok, stats} ->
        SyncRun.complete!(run, {:ok, to_sync_stats(stats)})
        Logger.info("OSRS sync #{category} completed: #{inspect(stats)}")
        :ok

      {:error, reason} ->
        SyncRun.complete!(run, {:error, reason})
        Logger.error("OSRS sync #{category} failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp full_sync do
    run = SyncRun.start!(:osrs, "full_sync")

    Logger.info("OSRS full sync starting: #{inspect(@main_categories)}")

    results =
      Enum.map(@main_categories, fn category ->
        case OSRSPipeline.sync_category(category, limit: 10_000) do
          {:ok, stats} ->
            Logger.info("Category #{category}: #{inspect(stats)}")
            stats

          {:error, reason} ->
            Logger.error("Category #{category} failed: #{inspect(reason)}")
            %{created: 0, updated: 0, unchanged: 0, errors: 1}
        end
      end)

    combined =
      Enum.reduce(results, %{created: 0, updated: 0, unchanged: 0, errors: 0}, fn stats, acc ->
        %{
          created: acc.created + stats.created,
          updated: acc.updated + stats.updated,
          unchanged: acc.unchanged + stats.unchanged,
          errors: acc.errors + stats.errors
        }
      end)

    if combined.errors > 0 do
      SyncRun.complete!(run, {:error, "#{combined.errors} category sync failures"})
      {:error, "partial failure"}
    else
      SyncRun.complete!(run, {:ok, to_sync_stats(combined)})
      Logger.info("OSRS full sync completed: #{inspect(combined)}")
      :ok
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
end
