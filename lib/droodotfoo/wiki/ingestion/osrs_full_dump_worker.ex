defmodule Droodotfoo.Wiki.Ingestion.OSRSFullDumpWorker do
  @moduledoc """
  Oban worker for full OSRS Wiki dump.

  Downloads ALL pages from the OSRS Wiki (~40,000 articles).
  Processes in batches, tracks progress, and can resume from interruption.

  ## Manual Invocation

      # Start full dump
      %{} |> Droodotfoo.Wiki.Ingestion.OSRSFullDumpWorker.new() |> Oban.insert()

      # Resume from a specific page (alphabetically)
      %{resume_from: "Dragon"} |> Droodotfoo.Wiki.Ingestion.OSRSFullDumpWorker.new() |> Oban.insert()

      # Limit pages (for testing)
      %{limit: 1000} |> Droodotfoo.Wiki.Ingestion.OSRSFullDumpWorker.new() |> Oban.insert()

  ## Progress Tracking

  Progress is stored in sync_runs table. If the job is interrupted,
  check the last processed page and resume from there.

  """

  use Oban.Worker,
    queue: :ingestion,
    max_attempts: 1,
    unique: [period: :infinity, states: [:available, :scheduled, :executing]]

  require Logger

  alias Droodotfoo.Wiki.Ingestion.{MediaWikiClient, OSRSPipeline, SyncRun}

  @batch_size 50
  @progress_interval 100

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    resume_from = Map.get(args, "resume_from")
    limit = Map.get(args, "limit")

    run = SyncRun.start!(:osrs, "full_dump")

    Logger.info(
      "OSRS full dump starting#{if resume_from, do: " (resuming from #{resume_from})", else: ""}"
    )

    result = run_full_dump(resume_from, limit, run)

    case result do
      {:ok, stats} ->
        SyncRun.complete!(run, {:ok, stats})
        log_final_stats(stats)
        :ok

      {:error, reason} ->
        SyncRun.complete!(run, {:error, inspect(reason)})
        {:error, reason}
    end
  end

  defp run_full_dump(resume_from, limit, run) do
    opts = if resume_from, do: [from: resume_from], else: []

    case MediaWikiClient.all_pages(opts) do
      {:ok, stream} ->
        stream
        |> maybe_limit(limit)
        |> Stream.chunk_every(@batch_size)
        |> Stream.with_index(1)
        |> Enum.reduce_while({:ok, initial_stats()}, fn {batch, batch_num}, {:ok, acc} ->
          case process_batch(batch, batch_num, acc, run) do
            {:ok, new_acc} -> {:cont, {:ok, new_acc}}
            {:error, _} = error -> {:halt, error}
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_limit(stream, nil), do: stream
  defp maybe_limit(stream, limit), do: Stream.take(stream, limit)

  defp process_batch(titles, batch_num, acc, run) do
    results = OSRSPipeline.process_pages(titles)
    batch_stats = aggregate_batch(results)
    new_acc = merge_stats(acc, batch_stats)

    # Log progress periodically
    total_processed = new_acc.created + new_acc.updated + new_acc.unchanged + new_acc.errors

    if rem(total_processed, @progress_interval) < @batch_size do
      log_progress(batch_num, new_acc, List.last(titles))
      update_run_progress(run, new_acc, List.last(titles))
    end

    {:ok, new_acc}
  rescue
    e ->
      Logger.error("Batch #{batch_num} failed: #{inspect(e)}")
      {:error, {:batch_failed, batch_num, e}}
  end

  defp initial_stats do
    %{created: 0, updated: 0, unchanged: 0, errors: 0, last_title: nil}
  end

  defp aggregate_batch(results) do
    Enum.reduce(results, initial_stats(), fn {title, result}, acc ->
      case result do
        {:created, _} -> %{acc | created: acc.created + 1, last_title: title}
        {:updated, _} -> %{acc | updated: acc.updated + 1, last_title: title}
        {:unchanged, _} -> %{acc | unchanged: acc.unchanged + 1, last_title: title}
        {:error, _} -> %{acc | errors: acc.errors + 1, last_title: title}
      end
    end)
  end

  defp merge_stats(acc, batch) do
    %{
      created: acc.created + batch.created,
      updated: acc.updated + batch.updated,
      unchanged: acc.unchanged + batch.unchanged,
      errors: acc.errors + batch.errors,
      last_title: batch.last_title || acc.last_title
    }
  end

  defp log_progress(batch_num, stats, last_title) do
    total = stats.created + stats.updated + stats.unchanged + stats.errors

    Logger.info(
      "OSRS dump progress: batch #{batch_num}, #{total} pages " <>
        "(#{stats.created} new, #{stats.updated} updated, #{stats.unchanged} unchanged, #{stats.errors} errors) " <>
        "- last: #{last_title}"
    )
  end

  defp update_run_progress(run, stats, last_title) do
    SyncRun.update_progress!(run, %{
      pages_processed: stats.created + stats.updated + stats.unchanged + stats.errors,
      pages_created: stats.created,
      pages_updated: stats.updated,
      pages_unchanged: stats.unchanged,
      errors: [%{last_title: last_title}]
    })
  end

  defp log_final_stats(stats) do
    total = stats.created + stats.updated + stats.unchanged + stats.errors

    Logger.info("""
    OSRS full dump complete:
      Total pages: #{total}
      Created: #{stats.created}
      Updated: #{stats.updated}
      Unchanged: #{stats.unchanged}
      Errors: #{stats.errors}
    """)
  end
end
