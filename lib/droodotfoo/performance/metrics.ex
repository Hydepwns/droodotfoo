defmodule Droodotfoo.Performance.Metrics do
  @moduledoc """
  Performance metrics tracking and aggregation.

  This module tracks performance metrics over time, including API response times,
  cache hit rates, rendering durations, and custom application metrics. It provides
  statistical analysis (min, max, avg, percentiles) and ASCII visualization.

  ## Features

  - Track timing metrics (API calls, renders, computations)
  - Counter metrics (events, errors, cache hits/misses)
  - Gauge metrics (concurrent users, queue depths)
  - Statistical aggregation (min, max, mean, median, p95, p99)
  - Time-series data with configurable retention
  - ASCII chart generation for terminal display

  ## Usage

      # Track API call duration
      Metrics.timing(:spotify_api, :get_track, 145)  # 145ms
      Metrics.timing(:github_api, :fetch_repo, 320)

      # Increment counters
      Metrics.increment(:cache_hits)
      Metrics.increment(:api_errors, 1, tags: [service: :spotify])

      # Set gauge values
      Metrics.gauge(:active_connections, 42)

      # Get statistics
      Metrics.stats(:spotify_api)
      # => %{count: 100, min: 45, max: 890, mean: 156, p95: 342, p99: 678}

      # Generate ASCII chart
      Metrics.chart(:spotify_api, :get_track)
  """

  use GenServer
  require Logger

  @type metric_type :: :timing | :counter | :gauge
  @type metric_name :: atom()
  @type metric_value :: number()
  @type tags :: keyword()

  @type stats :: %{
          count: non_neg_integer(),
          min: number(),
          max: number(),
          mean: float(),
          median: float(),
          p95: float(),
          p99: float()
        }

  @default_retention 3600
  # 1 hour in seconds
  @table_name :droodotfoo_metrics

  ## Public API

  @doc """
  Starts the metrics GenServer.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Records a timing metric (duration in milliseconds).

  ## Examples

      Metrics.timing(:spotify_api, :get_track, 145)
      Metrics.timing(:github_api, :fetch_stars, 89, tags: [repo: "droodotfoo"])
  """
  @spec timing(metric_name(), atom(), metric_value(), keyword()) :: :ok
  def timing(namespace, operation, duration_ms, opts \\ []) do
    tags = Keyword.get(opts, :tags, [])
    record_metric(:timing, {namespace, operation}, duration_ms, tags)
  end

  @doc """
  Measures and records the duration of a function execution.

  Returns the function result and records timing as a side effect.

  ## Examples

      result = Metrics.measure(:spotify_api, :get_track, fn ->
        Spotify.API.get_track("track_id")
      end)
  """
  @spec measure(metric_name(), atom(), (-> any()), keyword()) :: any()
  def measure(namespace, operation, fun, opts \\ []) when is_function(fun, 0) do
    start = System.monotonic_time(:millisecond)
    result = fun.()
    duration = System.monotonic_time(:millisecond) - start

    timing(namespace, operation, duration, opts)
    result
  end

  @doc """
  Increments a counter metric.

  ## Examples

      Metrics.increment(:cache_hits)
      Metrics.increment(:api_errors, 5)
      Metrics.increment(:user_actions, 1, tags: [action: :click])
  """
  @spec increment(metric_name(), non_neg_integer(), keyword()) :: :ok
  def increment(name, value \\ 1, opts \\ []) do
    tags = Keyword.get(opts, :tags, [])
    record_metric(:counter, name, value, tags)
  end

  @doc """
  Sets a gauge metric to a specific value.

  Gauges represent point-in-time values like queue depth or active connections.

  ## Examples

      Metrics.gauge(:active_users, 42)
      Metrics.gauge(:queue_depth, 156)
  """
  @spec gauge(metric_name(), metric_value(), keyword()) :: :ok
  def gauge(name, value, opts \\ []) do
    tags = Keyword.get(opts, :tags, [])
    record_metric(:gauge, name, value, tags)
  end

  @doc """
  Returns statistical summary for a timing metric.

  ## Examples

      Metrics.stats(:spotify_api, :get_track)
      # => %{count: 100, min: 45, max: 890, mean: 156, median: 142, p95: 342, p99: 678}
  """
  @spec stats(metric_name(), atom() | nil) :: stats() | nil
  def stats(namespace, operation \\ nil) do
    key = if operation, do: {namespace, operation}, else: namespace
    values = get_metric_values(:timing, key)

    if Enum.empty?(values) do
      nil
    else
      calculate_stats(values)
    end
  end

  @doc """
  Returns the current value of a counter metric.

  ## Examples

      Metrics.counter_value(:cache_hits)
      # => 1234
  """
  @spec counter_value(metric_name()) :: non_neg_integer()
  def counter_value(name) do
    values = get_metric_values(:counter, name)
    Enum.sum(values)
  end

  @doc """
  Returns the latest value of a gauge metric.

  ## Examples

      Metrics.gauge_value(:active_users)
      # => 42
  """
  @spec gauge_value(metric_name()) :: metric_value() | nil
  def gauge_value(name) do
    values = get_metric_values(:gauge, name)
    List.last(values)
  end

  @doc """
  Returns all metrics of a specific type.

  ## Examples

      Metrics.all_metrics(:timing)
      # => [:spotify_api, :github_api, :web3_api]
  """
  @spec all_metrics(metric_type()) :: [metric_name()]
  def all_metrics(type) do
    match_spec = [{{{type, :"$1", :_}, :_}, [], [:"$1"]}]

    :ets.select(@table_name, match_spec)
    |> Enum.uniq()
  end

  @doc """
  Generates an ASCII chart for timing metrics.

  ## Examples

      IO.puts(Metrics.chart(:spotify_api, :get_track))
  """
  @spec chart(metric_name(), atom(), keyword()) :: String.t()
  def chart(namespace, operation, opts \\ []) do
    key = {namespace, operation}
    values = get_metric_values(:timing, key)

    if Enum.empty?(values) do
      "No data available for #{namespace}.#{operation}"
    else
      width = Keyword.get(opts, :width, 60)
      height = Keyword.get(opts, :height, 10)
      generate_ascii_chart(values, width, height)
    end
  end

  @doc """
  Clears all metrics or metrics of a specific type.

  ## Examples

      Metrics.clear(:all)
      Metrics.clear(:timing)
      Metrics.clear(:counter)
  """
  @spec clear(metric_type() | :all) :: :ok
  def clear(:all) do
    :ets.delete_all_objects(@table_name)
    :ok
  end

  def clear(type) do
    match_spec = [{{{type, :_, :_}, :_}, [], [true]}]
    :ets.select_delete(@table_name, match_spec)
    :ok
  end

  ## GenServer Callbacks

  @impl true
  def init(opts) do
    :ets.new(@table_name, [
      :bag,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    retention = Keyword.get(opts, :retention, @default_retention)
    schedule_cleanup(retention)

    {:ok, %{retention: retention}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    prune_old_metrics(state.retention)
    schedule_cleanup(state.retention)
    {:noreply, state}
  end

  ## Private Functions

  defp record_metric(type, name, value, tags) do
    timestamp = System.system_time(:second)
    key = {type, name, timestamp}
    entry = {value, tags}

    :ets.insert(@table_name, {key, entry})
    :ok
  end

  defp get_metric_values(type, name) do
    match_spec = [{{{type, name, :_}, {:"$1", :_}}, [], [:"$1"]}]

    :ets.select(@table_name, match_spec)
  end

  defp calculate_stats(values) when is_list(values) do
    sorted = Enum.sort(values)
    count = length(sorted)

    %{
      count: count,
      min: Enum.min(sorted),
      max: Enum.max(sorted),
      mean: mean(sorted),
      median: percentile(sorted, 50),
      p95: percentile(sorted, 95),
      p99: percentile(sorted, 99)
    }
  end

  defp mean([]), do: 0.0

  defp mean(values) do
    Float.round(Enum.sum(values) / length(values), 2)
  end

  defp percentile([], _), do: 0.0
  defp percentile([value], _), do: value * 1.0

  defp percentile(sorted_values, percentile) do
    count = length(sorted_values)
    index = ceil(count * percentile / 100) - 1
    index = max(0, min(index, count - 1))

    Enum.at(sorted_values, index) * 1.0
  end

  defp schedule_cleanup(interval_seconds) do
    Process.send_after(self(), :cleanup, interval_seconds * 1000)
  end

  defp prune_old_metrics(retention_seconds) do
    cutoff_time = System.system_time(:second) - retention_seconds
    match_spec = [{{{:_, :_, :"$1"}, :_}, [{:<, :"$1", cutoff_time}], [true]}]

    :ets.select_delete(@table_name, match_spec)
  end

  defp generate_ascii_chart(values, width, height) do
    sorted = Enum.sort(values)
    stats = calculate_stats(values)

    # Create histogram buckets
    buckets = create_histogram_buckets(sorted, width)
    max_count = Enum.max(buckets)

    # Scale to fit height
    scaled =
      Enum.map(buckets, fn count ->
        round(count / max_count * height)
      end)

    # Generate chart rows
    rows =
      for row <- (height - 1)..0 do
        bars =
          Enum.map_join(scaled, "", fn bar_height ->
            if bar_height > row, do: "█", else: " "
          end)

        "│ #{bars} │"
      end

    header = "┌─" <> String.duplicate("─", width) <> "─┐"
    footer = "└─" <> String.duplicate("─", width) <> "─┘"

    stats_line =
      "  Min: #{stats.min}ms | Mean: #{stats.mean}ms | P95: #{stats.p95}ms | Max: #{stats.max}ms"

    [header | rows]
    |> Enum.concat([footer, stats_line])
    |> Enum.join("\n")
  end

  defp create_histogram_buckets(values, bucket_count) do
    min = Enum.min(values)
    max = Enum.max(values)
    range = max - min

    bucket_size = if range > 0, do: range / bucket_count, else: 1

    # Initialize buckets
    buckets = List.duplicate(0, bucket_count)

    # Fill buckets
    Enum.reduce(values, buckets, fn value, acc ->
      bucket_index = min(trunc((value - min) / bucket_size), bucket_count - 1)
      List.update_at(acc, bucket_index, &(&1 + 1))
    end)
  end
end
