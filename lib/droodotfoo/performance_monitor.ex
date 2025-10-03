defmodule Droodotfoo.PerformanceMonitor do
  @moduledoc """
  Performance monitoring system for the droodotfoo application.
  Tracks render times, memory usage, and system metrics.
  """

  use GenServer
  require Logger

  # Keep last 100 measurements
  @metrics_window 100
  # Report every minute
  @report_interval 60_000

  defstruct [
    :render_times,
    :memory_usage,
    :process_count,
    :message_queue_lengths,
    :reductions,
    :start_time,
    :request_count,
    :error_count,
    :report_timer,
    :metrics_timer
  ]

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_render_time(duration_ms) do
    GenServer.cast(__MODULE__, {:record_render, duration_ms})
  end

  def record_error do
    GenServer.cast(__MODULE__, :record_error)
  end

  def record_request do
    GenServer.cast(__MODULE__, :record_request)
  end

  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  def get_summary do
    GenServer.call(__MODULE__, :get_summary)
  end

  def reset_metrics do
    GenServer.call(__MODULE__, :reset_metrics)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Schedule periodic reporting
    report_timer = Process.send_after(self(), :report_metrics, @report_interval)

    # Schedule periodic system metrics collection
    metrics_timer = Process.send_after(self(), :collect_system_metrics, 5000)

    state = %__MODULE__{
      render_times: [],
      memory_usage: [],
      process_count: [],
      message_queue_lengths: [],
      reductions: [],
      start_time: System.monotonic_time(:second),
      request_count: 0,
      error_count: 0,
      report_timer: report_timer,
      metrics_timer: metrics_timer
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:record_render, duration_ms}, state) do
    render_times = [duration_ms | state.render_times] |> Enum.take(@metrics_window)
    {:noreply, %{state | render_times: render_times}}
  end

  @impl true
  def handle_cast(:record_error, state) do
    {:noreply, %{state | error_count: state.error_count + 1}}
  end

  @impl true
  def handle_cast(:record_request, state) do
    {:noreply, %{state | request_count: state.request_count + 1}}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    metrics = %{
      render_times: state.render_times,
      memory_usage: state.memory_usage,
      process_count: state.process_count,
      message_queue_lengths: state.message_queue_lengths,
      request_count: state.request_count,
      error_count: state.error_count,
      uptime: System.monotonic_time(:second) - state.start_time
    }

    {:reply, metrics, state}
  end

  @impl true
  def handle_call(:get_summary, _from, state) do
    summary = calculate_summary(state)
    {:reply, summary, state}
  end

  @impl true
  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  def handle_call(:reset_metrics, _from, state) do
    new_state = %__MODULE__{
      render_times: [],
      memory_usage: [],
      process_count: [],
      message_queue_lengths: [],
      reductions: [],
      start_time: System.monotonic_time(:second),
      request_count: 0,
      error_count: 0,
      report_timer: state.report_timer,
      metrics_timer: state.metrics_timer
    }
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info(:collect_system_metrics, state) do
    # Collect system metrics
    # Convert to MB
    memory = :erlang.memory(:total) / 1_048_576
    proc_count = :erlang.system_info(:process_count)

    # Get message queue lengths for key processes
    queue_lengths = get_message_queue_lengths()

    # Get reductions (CPU usage indicator)
    reductions = get_total_reductions()

    # Update state with new metrics
    new_state = %{
      state
      | memory_usage: [memory | state.memory_usage] |> Enum.take(@metrics_window),
        process_count: [proc_count | state.process_count] |> Enum.take(@metrics_window),
        message_queue_lengths:
          [queue_lengths | state.message_queue_lengths] |> Enum.take(@metrics_window),
        reductions: [reductions | state.reductions] |> Enum.take(@metrics_window)
    }

    # Schedule next collection
    Process.send_after(self(), :collect_system_metrics, 5000)

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:report_metrics, state) do
    summary = calculate_summary(state)

    Logger.info("""
    Performance Report:
    ===================
    Uptime: #{summary.uptime_hours} hours
    Requests: #{summary.total_requests} (#{summary.requests_per_minute} req/min)
    Errors: #{summary.total_errors} (#{summary.error_rate}%)

    Render Times:
      Avg: #{summary.avg_render_time}ms
      Min: #{summary.min_render_time}ms
      Max: #{summary.max_render_time}ms
      P95: #{summary.p95_render_time}ms

    System Metrics:
      Memory: #{summary.current_memory}MB (avg: #{summary.avg_memory}MB)
      Processes: #{summary.current_processes} (avg: #{summary.avg_processes})
      Message Queue: #{summary.max_queue_length} max
    """)

    # Schedule next report
    Process.send_after(self(), :report_metrics, @report_interval)

    {:noreply, state}
  end

  # Private functions

  defp calculate_summary(state) do
    uptime_seconds = System.monotonic_time(:second) - state.start_time

    %{
      uptime_hours: Float.round(uptime_seconds / 3600, 2),
      total_requests: state.request_count,
      requests_per_minute: calculate_rate(state.request_count, uptime_seconds),
      total_errors: state.error_count,
      error_rate: calculate_error_rate(state.error_count, state.request_count),
      avg_render_time: calculate_avg(state.render_times),
      min_render_time: calculate_min(state.render_times),
      max_render_time: calculate_max(state.render_times),
      p95_render_time: calculate_percentile(state.render_times, 95),
      current_memory: List.first(state.memory_usage, 0.0) |> safe_round(2),
      avg_memory: calculate_avg(state.memory_usage) |> safe_round(2),
      current_processes: List.first(state.process_count, 0),
      avg_processes: calculate_avg(state.process_count) |> round(),
      max_queue_length: calculate_max_queue_length(state.message_queue_lengths)
    }
  end

  defp calculate_rate(count, seconds) when seconds > 0 do
    Float.round(count * 60 / seconds, 2)
  end

  # If uptime is less than 1 second, assume 1 second for rate calculation
  defp calculate_rate(count, _) when count > 0, do: Float.round(count * 60.0, 2)
  defp calculate_rate(_, _), do: 0.0

  defp calculate_error_rate(0, _), do: 0.0
  defp calculate_error_rate(_, 0), do: 0.0

  defp calculate_error_rate(errors, requests) do
    Float.round(errors * 100 / requests, 2)
  end

  defp safe_round(value, precision) when is_float(value) do
    Float.round(value, precision)
  end

  defp safe_round(value, _precision) when is_integer(value) do
    value * 1.0
  end

  defp safe_round(value, _precision), do: value

  defp calculate_avg([]), do: 0.0

  defp calculate_avg(list) do
    Enum.sum(list) / length(list)
  end

  defp calculate_min([]), do: 0
  defp calculate_min(list), do: Enum.min(list)

  defp calculate_max([]), do: 0
  defp calculate_max(list), do: Enum.max(list)

  defp calculate_percentile([], _), do: 0

  defp calculate_percentile(list, percentile) do
    sorted = Enum.sort(list)
    index = round(length(sorted) * percentile / 100)
    Enum.at(sorted, index - 1, 0)
  end

  defp calculate_max_queue_length([]), do: 0

  defp calculate_max_queue_length(queue_lists) do
    queue_lists
    |> Enum.map(&Map.get(&1, :max, 0))
    |> calculate_max()
  end

  defp get_message_queue_lengths do
    processes = Process.list()

    lengths =
      processes
      |> Enum.map(fn pid ->
        case Process.info(pid, :message_queue_len) do
          {:message_queue_len, len} -> len
          _ -> 0
        end
      end)
      |> Enum.filter(&(&1 > 0))

    %{
      total: length(lengths),
      max: calculate_max(lengths),
      avg: calculate_avg(lengths) |> Float.round(2)
    }
  end

  defp get_total_reductions do
    Process.list()
    |> Enum.reduce(0, fn pid, acc ->
      case Process.info(pid, :reductions) do
        {:reductions, red} -> acc + red
        _ -> acc
      end
    end)
  end

  @impl true
  def terminate(_reason, state) when is_struct(state) do
    # Cancel timers to prevent resource leaks
    if state.report_timer, do: Process.cancel_timer(state.report_timer)
    if state.metrics_timer, do: Process.cancel_timer(state.metrics_timer)
    :ok
  end

  def terminate(_reason, _state) do
    :ok
  end
end
