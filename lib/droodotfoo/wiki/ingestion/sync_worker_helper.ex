defmodule Droodotfoo.Wiki.Ingestion.SyncWorkerHelper do
  @moduledoc """
  Common utilities for wiki sync workers.

  Consolidates duplicate patterns across OSRS, nLab, Wikipedia, and
  VintageMachinery sync workers:

  - Result handling with SyncRun completion
  - Stats transformation to SyncRun format
  - Consistent logging patterns
  """

  require Logger

  alias Droodotfoo.Wiki.Ingestion.SyncRun

  @doc """
  Runs a recent changes sync with standard boilerplate.

  Handles:
  1. Starting a SyncRun
  2. Getting last_completed_at timestamp
  3. Logging the sync start
  4. Calling the sync function
  5. Handling the result

  ## Examples

      # In a sync worker:
      def sync_recent_changes do
        SyncWorkerHelper.sync_recent_changes(:osrs, &OSRSPipeline.sync_recent_changes/1, "OSRS sync")
      end

      # With transform disabled:
      SyncWorkerHelper.sync_recent_changes(:wikipedia, &WikipediaPipeline.sync_recent_changes/1, "Wikipedia sync", transform: false)

  """
  @spec sync_recent_changes(atom(), (DateTime.t() | nil -> {:ok, map()} | {:error, term()}), String.t(), keyword()) ::
          :ok | {:error, term()}
  def sync_recent_changes(source, sync_fn, label, opts \\ []) do
    run = SyncRun.start!(source, "recent_changes")
    since = SyncRun.last_completed_at(source)

    Logger.info("#{label}: recent changes since #{inspect(since)}")

    sync_fn.(since)
    |> handle_result(run, label, opts)
  end

  @doc """
  Handles pipeline result, completes the SyncRun, logs, and returns appropriate value.

  ## Options

  - `transform: true` (default) - Transform stats to SyncRun format via `to_sync_stats/1`
  - `transform: false` - Pass stats through unchanged

  ## Examples

      run = SyncRun.start!(:osrs, "recent_changes")
      result = OSRSPipeline.sync_recent_changes(since)
      handle_result(result, run, "OSRS sync")

      # Without transformation
      handle_result(result, run, "Wikipedia sync", transform: false)

  """
  @spec handle_result({:ok, map()} | {:error, term()}, SyncRun.t(), String.t(), keyword()) ::
          :ok | {:error, term()}
  def handle_result(result, run, label, opts \\ [])

  def handle_result({:ok, stats}, run, label, opts) do
    sync_stats = if Keyword.get(opts, :transform, true), do: to_sync_stats(stats), else: stats
    SyncRun.complete!(run, {:ok, sync_stats})
    log_stats(label, stats)
    :ok
  end

  def handle_result({:error, reason} = error, run, label, _opts) do
    SyncRun.complete!(run, error)
    Logger.error("#{label} failed: #{inspect(reason)}")
    error
  end

  @doc """
  Transforms pipeline stats to SyncRun format.

  Pipeline stats have :created/:updated/:unchanged/:errors keys.
  SyncRun expects :pages_processed/:pages_created/:pages_updated/:pages_unchanged.
  """
  @spec to_sync_stats(map()) :: map()
  def to_sync_stats(stats) do
    %{
      pages_processed: stats.created + stats.updated + stats.unchanged + stats.errors,
      pages_created: stats.created,
      pages_updated: stats.updated,
      pages_unchanged: stats.unchanged
    }
  end

  @doc """
  Logs sync completion with consistent format.
  """
  @spec log_stats(String.t(), map()) :: :ok
  def log_stats(label, stats) do
    Logger.info(
      "#{label} complete: #{stats.created} created, #{stats.updated} updated, " <>
        "#{stats.unchanged} unchanged, #{stats.errors} errors"
    )
  end
end
