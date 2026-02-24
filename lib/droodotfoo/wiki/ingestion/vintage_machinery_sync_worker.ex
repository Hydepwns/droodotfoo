defmodule Droodotfoo.Wiki.Ingestion.VintageMachinerySyncWorker do
  @moduledoc """
  Oban worker for VintageMachinery.org sync.

  Runs weekly by default (site updates infrequently).

  ## Manual Invocation

      # Incremental sync (default)
      Droodotfoo.Wiki.Ingestion.VintageMachinerySyncWorker.new(%{})
      |> Oban.insert()

      # Full sync
      Droodotfoo.Wiki.Ingestion.VintageMachinerySyncWorker.new(%{"strategy" => "full"})
      |> Oban.insert()

      # Limit pages processed
      Droodotfoo.Wiki.Ingestion.VintageMachinerySyncWorker.new(%{"limit" => 100})
      |> Oban.insert()

  """

  use Oban.Worker,
    queue: :ingestion,
    max_attempts: 2

  require Logger

  alias Droodotfoo.Wiki.Ingestion.{SyncRun, SyncWorkerHelper, VintageMachineryPipeline}

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    strategy = Map.get(args, "strategy", "incremental")
    limit = Map.get(args, "limit", 50_000)

    run = SyncRun.start!(:vintage_machinery, strategy)

    case strategy do
      "full" ->
        Logger.info("Starting full VintageMachinery sync")
        VintageMachineryPipeline.sync_all(limit: limit)

      _ ->
        since = SyncRun.last_completed_at(:vintage_machinery)
        Logger.info("Starting incremental VintageMachinery sync since #{inspect(since)}")
        VintageMachineryPipeline.sync_recent_changes(since)
    end
    |> SyncWorkerHelper.handle_result(run, "VintageMachinery sync", transform: false)
  end
end
