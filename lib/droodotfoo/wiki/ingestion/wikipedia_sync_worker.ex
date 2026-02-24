defmodule Droodotfoo.Wiki.Ingestion.WikipediaSyncWorker do
  @moduledoc """
  Oban worker for Wikipedia sync.

  Wikipedia ingestion is curated rather than automated - we don't
  mirror the entire site. This worker:

  1. Refreshes existing Wikipedia articles weekly
  2. Can be triggered manually to import specific pages

  ## Manual Invocation

      # Refresh all existing articles
      Droodotfoo.Wiki.Ingestion.WikipediaSyncWorker.new(%{"strategy" => "refresh"})
      |> Oban.insert()

      # Import a specific page
      Droodotfoo.Wiki.Ingestion.WikipediaSyncWorker.new(%{"slug" => "Riemann_hypothesis"})
      |> Oban.insert()

      # Import pages matching a search
      Droodotfoo.Wiki.Ingestion.WikipediaSyncWorker.new(%{"search" => "category theory", "limit" => 10})
      |> Oban.insert()

  """

  use Oban.Worker, queue: :ingestion, max_attempts: 2

  require Logger

  alias Droodotfoo.Wiki.Ingestion.{SyncRun, SyncWorkerHelper, WikipediaPipeline}

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    cond do
      slug = args["slug"] ->
        import_single(slug)

      query = args["search"] ->
        import_search(query, args)

      args["strategy"] == "refresh" ->
        refresh_all(args)

      true ->
        refresh_all(args)
    end
  end

  defp import_single(slug) do
    case WikipediaPipeline.process_page(slug) do
      {:created, article} ->
        Logger.info("Imported Wikipedia article: #{article.title}")
        :ok

      {:updated, article} ->
        Logger.info("Updated Wikipedia article: #{article.title}")
        :ok

      {:unchanged, _} ->
        Logger.debug("Wikipedia article unchanged: #{slug}")
        :ok

      {:error, reason} ->
        Logger.error("Failed to import Wikipedia article #{slug}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp import_search(query, args) do
    limit = args["limit"] || 10
    run = SyncRun.start!(:wikipedia, "search:#{query}")

    WikipediaPipeline.import_search(query, limit: limit)
    |> SyncWorkerHelper.handle_result(run, "Wikipedia search import", transform: false)
  end

  defp refresh_all(args) do
    limit = args["limit"] || 1000
    run = SyncRun.start!(:wikipedia, "refresh")

    WikipediaPipeline.refresh_all(limit: limit)
    |> SyncWorkerHelper.handle_result(run, "Wikipedia refresh", transform: false)
  end
end
