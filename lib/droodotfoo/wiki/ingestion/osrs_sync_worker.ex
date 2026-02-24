defmodule Droodotfoo.Wiki.Ingestion.OSRSSyncWorker do
  @moduledoc """
  Oban worker for syncing OSRS Wiki content.

  Runs on a cron schedule (every 15 minutes by default) to fetch
  recent changes and update local articles.

  Can also be triggered manually for full category syncs.

  ## Manual Invocation

      # Sync recent changes
      %{} |> Droodotfoo.Wiki.Ingestion.OSRSSyncWorker.new() |> Oban.insert()

      # Sync a specific category
      %{category: "Items"} |> Droodotfoo.Wiki.Ingestion.OSRSSyncWorker.new() |> Oban.insert()

      # Full initial sync (all main categories)
      %{full_sync: true} |> Droodotfoo.Wiki.Ingestion.OSRSSyncWorker.new() |> Oban.insert()

  """

  use Oban.Worker,
    queue: :ingestion,
    max_attempts: 3,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  require Logger

  alias Droodotfoo.Wiki.Ingestion.{OSRSPipeline, SyncRun, SyncWorkerHelper}

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
    SyncWorkerHelper.sync_recent_changes(:osrs, &OSRSPipeline.sync_recent_changes/1, "OSRS sync")
  end

  defp sync_category(category) do
    run = SyncRun.start!(:osrs, "category:#{category}")

    Logger.info("OSRS sync: category #{category}")

    OSRSPipeline.sync_category(category)
    |> SyncWorkerHelper.handle_result(run, "OSRS sync #{category}")
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
      SyncRun.complete!(run, {:ok, SyncWorkerHelper.to_sync_stats(combined)})
      SyncWorkerHelper.log_stats("OSRS full sync", combined)
      :ok
    end
  end
end
