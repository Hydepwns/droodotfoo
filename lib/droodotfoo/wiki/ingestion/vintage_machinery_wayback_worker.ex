defmodule Droodotfoo.Wiki.Ingestion.VintageMachineryWaybackWorker do
  @moduledoc """
  Oban worker for VintageMachinery sync via Wayback Machine.

  Use this when the live site is unavailable (403 errors).

  ## Manual Invocation

      # Full sync from Wayback Machine
      %{} |> Droodotfoo.Wiki.Ingestion.VintageMachineryWaybackWorker.new() |> Oban.insert()

      # Limit pages (for testing)
      %{"limit" => 100} |> Droodotfoo.Wiki.Ingestion.VintageMachineryWaybackWorker.new() |> Oban.insert()

      # Sync specific prefix
      %{"prefix" => "pubs/"} |> Droodotfoo.Wiki.Ingestion.VintageMachineryWaybackWorker.new() |> Oban.insert()

  """

  use Oban.Worker,
    queue: :ingestion,
    max_attempts: 2,
    unique: [period: 3600, states: [:available, :scheduled, :executing]]

  require Logger

  alias Droodotfoo.Wiki.Ingestion.{SyncRun, VintageMachineryWaybackPipeline}

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    limit = Map.get(args, "limit", 50_000)
    prefix = Map.get(args, "prefix")

    run = SyncRun.start!(:vintage_machinery, "wayback#{if prefix, do: ":#{prefix}", else: ""}")

    Logger.info(
      "Starting VintageMachinery Wayback sync#{if prefix, do: " (prefix: #{prefix})", else: ""}"
    )

    result =
      if prefix do
        VintageMachineryWaybackPipeline.sync_prefix(prefix, limit: limit)
      else
        VintageMachineryWaybackPipeline.sync_all(
          limit: limit,
          progress: fn count, total ->
            Logger.info("VintageMachinery Wayback progress: #{count}/#{total}")
            SyncRun.update_progress!(run, %{pages_processed: count})
          end
        )
      end

    case result do
      {:ok, stats} ->
        SyncRun.complete!(run, {:ok, to_sync_stats(stats)})
        log_stats(stats)
        :ok

      {:error, reason} ->
        SyncRun.complete!(run, {:error, inspect(reason)})
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

  defp log_stats(stats) do
    total = stats.created + stats.updated + stats.unchanged + stats.errors

    Logger.info("""
    VintageMachinery Wayback sync complete:
      Total: #{total}
      Created: #{stats.created}
      Updated: #{stats.updated}
      Unchanged: #{stats.unchanged}
      Errors: #{stats.errors}
    """)
  end
end
