defmodule Droodotfoo.Terminal.Commands.Performance do
  @moduledoc """
  Performance monitoring and optimization command implementations.

  Provides commands for:
  - perf memory: Display memory usage statistics
  - perf cache: Display cache statistics
  - perf metrics: Display performance metrics
  - perf optimize: Run automatic optimizations
  - perf analyze: Analyze system performance
  - perf monitor: Display real-time performance monitor
  """

  use Droodotfoo.Terminal.CommandBase

  alias Droodotfoo.Performance.{Cache, Metrics, Monitor, Optimizer}

  @impl true
  def execute("perf", [], state) do
    # Show help when no subcommand provided
    help = """
    Performance Monitoring Commands:

      perf memory     - Display memory usage statistics
      perf cache      - Display cache statistics and efficiency
      perf metrics    - Display performance metrics
      perf optimize   - Run automatic optimizations
      perf analyze    - Analyze system performance
      perf monitor    - Display comprehensive performance monitor

    Use 'perf <subcommand>' for detailed information.
    """

    {:ok, help, state}
  end

  def execute("perf", ["memory"], state) do
    output = perf_memory()
    {:ok, output, state}
  end

  def execute("perf", ["cache"], state) do
    output = perf_cache()
    {:ok, output, state}
  end

  def execute("perf", ["metrics"], state) do
    output = perf_metrics()
    {:ok, output, state}
  end

  def execute("perf", ["optimize"], state) do
    output = perf_optimize()
    {:ok, output, state}
  end

  def execute("perf", ["analyze"], state) do
    output = perf_analyze()
    {:ok, output, state}
  end

  def execute("perf", ["monitor"], state) do
    output = perf_monitor()
    {:ok, output, state}
  end

  def execute("perf", [subcommand | _], state) do
    {:error, "Unknown perf subcommand: #{subcommand}\nUse 'perf' for help.", state}
  end

  def execute("performance", args, state) do
    # Alias to perf
    execute("perf", args, state)
  end

  def execute(command, _args, state) do
    {:error, "Unknown performance command: #{command}", state}
  end

  ## Subcommand Implementations

  @doc """
  Display memory usage statistics.
  """
  def perf_memory do
    snapshot = Monitor.memory_snapshot()
    total_mb = snapshot.total / 1_048_576

    """
    ┌─ MEMORY USAGE ─────────────────────────────────────────────────────┐
    │                                                                     │
    │  Total:       #{String.pad_trailing(Monitor.format_memory(snapshot.total), 12)} (100%)            │
    │  Processes:   #{String.pad_trailing(Monitor.format_memory(snapshot.processes), 12)} (#{Monitor.memory_percentage(snapshot.processes, snapshot.total)}%)           │
    │  Atoms:       #{String.pad_trailing(Monitor.format_memory(snapshot.atom), 12)} (#{Monitor.memory_percentage(snapshot.atom, snapshot.total)}%)           │
    │  Binary:      #{String.pad_trailing(Monitor.format_memory(snapshot.binary), 12)} (#{Monitor.memory_percentage(snapshot.binary, snapshot.total)}%)           │
    │  Code:        #{String.pad_trailing(Monitor.format_memory(snapshot.code), 12)} (#{Monitor.memory_percentage(snapshot.code, snapshot.total)}%)           │
    │  ETS Tables:  #{String.pad_trailing(Monitor.format_memory(snapshot.ets), 12)} (#{Monitor.memory_percentage(snapshot.ets, snapshot.total)}%)           │
    │                                                                     │
    │  USAGE:       #{format_memory_bar(total_mb, 512.0)}                    │
    │               #{Float.round(total_mb / 512.0 * 100, 1)}% of estimated available memory    │
    │                                                                     │
    └─────────────────────────────────────────────────────────────────────┘
    """
  end

  @doc """
  Display cache statistics and efficiency.
  """
  def perf_cache do
    all_stats = Cache.stats(:all)
    total_requests = all_stats.hits + all_stats.misses

    hit_rate =
      if total_requests > 0 do
        Float.round(all_stats.hits / total_requests * 100, 1)
      else
        0.0
      end

    # Get namespace-specific stats
    namespaces = [:spotify, :github, :web3, :ipfs, :portal]

    namespace_lines =
      Enum.map(namespaces, fn ns ->
        stats = Cache.stats(ns)
        requests = stats.hits + stats.misses

        if requests > 0 do
          ns_hit_rate = Float.round(stats.hits / requests * 100, 1)

          ns_name = String.pad_trailing("#{ns}", 10)
          hits = String.pad_leading("#{stats.hits}", 6)
          misses = String.pad_leading("#{stats.misses}", 6)
          rate = String.pad_leading("#{ns_hit_rate}%", 7)

          "│  #{ns_name} #{hits} #{misses}   #{rate}                  │"
        else
          nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    namespace_section =
      if Enum.empty?(namespace_lines) do
        "│  (no cache activity)                                           │"
      else
        Enum.join(namespace_lines, "\n")
      end

    """
    ┌─ CACHE STATISTICS ─────────────────────────────────────────────────┐
    │                                                                     │
    │  OVERALL                                                           │
    │  Total Requests:  #{String.pad_leading("#{total_requests}", 10)}                              │
    │  Cache Hits:      #{String.pad_leading("#{all_stats.hits}", 10)} (#{hit_rate}%)                    │
    │  Cache Misses:    #{String.pad_leading("#{all_stats.misses}", 10)}                              │
    │  Cache Size:      #{String.pad_leading("#{all_stats.size}", 10)} entries                       │
    │  Memory Used:     #{String.pad_leading(Monitor.format_memory(all_stats.memory_bytes), 10)}                              │
    │                                                                     │
    │  BY NAMESPACE                                                      │
    │  Namespace     Hits  Misses  Hit Rate                             │
    #{namespace_section}
    │                                                                     │
    │  EFFICIENCY:  #{format_efficiency_bar(hit_rate)}                          │
    │               Target: >80% hit rate                                │
    │                                                                     │
    └─────────────────────────────────────────────────────────────────────┘
    """
  end

  @doc """
  Display performance metrics.
  """
  def perf_metrics do
    timing_metrics = Metrics.all_metrics(:timing)

    metrics_lines =
      if Enum.empty?(timing_metrics) do
        ["│  (no timing metrics recorded)                                  │"]
      else
        timing_metrics
        |> Enum.take(10)
        |> Enum.map(fn metric ->
          case Metrics.stats(metric) do
            nil ->
              nil

            stats ->
              name = String.pad_trailing("#{metric}", 18)
              count = String.pad_leading("#{stats.count}", 5)
              mean = String.pad_leading("#{trunc(stats.mean)}", 5)
              p95 = String.pad_leading("#{trunc(stats.p95)}", 5)

              "│  #{name} #{count}  #{mean}ms  #{p95}ms              │"
          end
        end)
        |> Enum.reject(&is_nil/1)
      end

    metrics_section = Enum.join(metrics_lines, "\n")

    """
    ┌─ PERFORMANCE METRICS ──────────────────────────────────────────────┐
    │                                                                     │
    │  TIMING METRICS (Top 10)                                           │
    │  Metric             Count   Mean    P95                           │
    #{metrics_section}
    │                                                                     │
    │  Use 'perf analyze' for detailed bottleneck analysis              │
    │                                                                     │
    └─────────────────────────────────────────────────────────────────────┘
    """
  end

  @doc """
  Run automatic optimizations.
  """
  def perf_optimize do
    optimizations = Optimizer.optimize()

    results =
      if Enum.empty?(optimizations) do
        "No optimizations needed - system is running well!"
      else
        opt_names = Enum.map_join(optimizations, ", ", &":#{&1}")
        "Applied optimizations: #{opt_names}"
      end

    """
    ┌─ PERFORMANCE OPTIMIZER ────────────────────────────────────────────┐
    │                                                                     │
    │  Running automatic optimizations...                                │
    │                                                                     │
    │  #{String.pad_trailing(results, 63)} │
    │                                                                     │
    │  Use 'perf analyze' to see detailed recommendations               │
    │                                                                     │
    └─────────────────────────────────────────────────────────────────────┘
    """
  end

  @doc """
  Analyze system performance.
  """
  def perf_analyze do
    Optimizer.format_report()
  end

  @doc """
  Display comprehensive performance monitor.
  """
  def perf_monitor do
    Monitor.format_report()
  end

  ## Helper Functions

  defp format_memory_bar(used_mb, total_mb) do
    percentage = used_mb / total_mb
    bar_width = 40
    filled = trunc(percentage * bar_width)
    empty = bar_width - filled

    bar = String.duplicate("█", filled) <> String.duplicate("░", empty)
    "[#{bar}]"
  end

  defp format_efficiency_bar(hit_rate) do
    bar_width = 40
    filled = trunc(hit_rate / 100 * bar_width)
    empty = bar_width - filled

    bar = String.duplicate("█", filled) <> String.duplicate("░", empty)

    status =
      cond do
        hit_rate >= 80 -> "GOOD"
        hit_rate >= 60 -> "FAIR"
        true -> "POOR"
      end

    "[#{bar}] #{status}"
  end
end
