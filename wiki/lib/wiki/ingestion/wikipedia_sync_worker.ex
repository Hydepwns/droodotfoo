defmodule Wiki.Ingestion.WikipediaSyncWorker do
  @moduledoc """
  Oban worker for Wikipedia sync.

  Wikipedia ingestion is curated rather than automated - we don't
  mirror the entire site. This worker:

  1. Refreshes existing Wikipedia articles weekly
  2. Can be triggered manually to import specific pages

  ## Manual Invocation

      # Refresh all existing articles
      Wiki.Ingestion.WikipediaSyncWorker.new(%{"strategy" => "refresh"})
      |> Oban.insert()

      # Import a specific page
      Wiki.Ingestion.WikipediaSyncWorker.new(%{"slug" => "Riemann_hypothesis"})
      |> Oban.insert()

      # Import pages matching a search
      Wiki.Ingestion.WikipediaSyncWorker.new(%{"search" => "category theory", "limit" => 10})
      |> Oban.insert()

  """

  use Oban.Worker, queue: :ingestion, max_attempts: 2

  require Logger

  alias Wiki.Ingestion.{SyncRun, WikipediaPipeline}

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

    case WikipediaPipeline.import_search(query, limit: limit) do
      {:ok, stats} ->
        SyncRun.complete!(run, {:ok, stats})
        log_stats("search import", stats)
        :ok

      {:error, reason} = error ->
        SyncRun.complete!(run, error)
        Logger.error("Wikipedia search import failed: #{inspect(reason)}")
        error
    end
  end

  defp refresh_all(args) do
    limit = args["limit"] || 1000
    run = SyncRun.start!(:wikipedia, "refresh")

    case WikipediaPipeline.refresh_all(limit: limit) do
      {:ok, stats} ->
        SyncRun.complete!(run, {:ok, stats})
        log_stats("refresh", stats)
        :ok

      {:error, reason} = error ->
        SyncRun.complete!(run, error)
        Logger.error("Wikipedia refresh failed: #{inspect(reason)}")
        error
    end
  end

  defp log_stats(operation, stats) do
    Logger.info(
      "Wikipedia #{operation} complete: " <>
        "#{stats.created} created, #{stats.updated} updated, " <>
        "#{stats.unchanged} unchanged, #{stats.errors} errors"
    )
  end
end
