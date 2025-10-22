defmodule Droodotfoo.Performance.Optimizer do
  @moduledoc """
  Performance optimization utilities and recommendations.

  This module provides tools for analyzing application performance and suggesting
  optimizations. It can detect common performance issues, recommend configuration
  changes, and apply automatic optimizations.

  ## Features

  - Performance analysis and bottleneck detection
  - Cache efficiency analysis
  - Memory optimization recommendations
  - Process pool sizing recommendations
  - API call batching and deduplication
  - Automatic optimization application

  ## Usage

      # Analyze current performance
      Optimizer.analyze()
      # => %{
      #   cache_hit_rate: 0.85,
      #   memory_pressure: :low,
      #   recommendations: [...]
      # }

      # Get optimization recommendations
      Optimizer.recommendations()
      # => [
      #   %{type: :cache, priority: :high, description: "Low cache hit rate..."},
      #   ...
      # ]

      # Apply automatic optimizations
      Optimizer.optimize()
  """

  alias Droodotfoo.Performance.{Cache, Metrics, Monitor}
  require Logger

  @type optimization :: %{
          type: atom(),
          priority: :low | :medium | :high,
          description: String.t(),
          action: (-> any())
        }

  @type analysis :: %{
          cache_efficiency: float(),
          memory_pressure: :low | :medium | :high,
          process_utilization: float(),
          bottlenecks: [atom()],
          recommendations: [optimization()]
        }

  ## Analysis

  @doc """
  Performs comprehensive performance analysis.

  Returns analysis results with recommendations.

  ## Examples

      Optimizer.analyze()
      # => %{
      #   cache_efficiency: 0.85,
      #   memory_pressure: :low,
      #   process_utilization: 0.13,
      #   bottlenecks: [:spotify_api],
      #   recommendations: [...]
      # }
  """
  @spec analyze() :: analysis()
  def analyze do
    cache_stats = analyze_cache_efficiency()
    memory_stats = analyze_memory_pressure()
    process_stats = Monitor.process_stats()
    bottlenecks = detect_bottlenecks()

    %{
      cache_efficiency: cache_stats.hit_rate,
      memory_pressure: memory_stats.pressure_level,
      process_utilization: process_stats.utilization,
      bottlenecks: bottlenecks,
      recommendations: generate_recommendations(cache_stats, memory_stats, bottlenecks)
    }
  end

  @doc """
  Returns optimization recommendations based on current performance.

  ## Examples

      Optimizer.recommendations()
      # => [
      #   %{
      #     type: :cache,
      #     priority: :high,
      #     description: "Cache hit rate is 45% (target: >80%)",
      #     action: #Function<...>
      #   }
      # ]
  """
  @spec recommendations() :: [optimization()]
  def recommendations do
    analysis = analyze()
    analysis.recommendations
  end

  @doc """
  Applies automatic optimizations based on analysis.

  Returns list of applied optimizations.

  ## Examples

      Optimizer.optimize()
      # => [:cache_cleanup, :memory_gc]
  """
  @spec optimize() :: [atom()]
  def optimize do
    optimizations = []

    # Prune expired cache entries
    optimizations = maybe_prune_cache(optimizations)

    # Run garbage collection if memory pressure is high
    optimizations = maybe_run_gc(optimizations)

    # Optimize ETS tables
    optimizations = maybe_optimize_ets(optimizations)

    optimizations
  end

  ## Cache Analysis

  @doc """
  Analyzes cache efficiency across all namespaces.

  ## Examples

      Optimizer.analyze_cache_efficiency()
      # => %{
      #   hit_rate: 0.85,
      #   namespaces: %{
      #     spotify: %{hits: 1234, misses: 234, hit_rate: 0.84},
      #     github: %{hits: 890, misses: 110, hit_rate: 0.89}
      #   }
      # }
  """
  @spec analyze_cache_efficiency() :: map()
  def analyze_cache_efficiency do
    all_stats = Cache.stats(:all)
    total_hits = all_stats.hits
    total_misses = all_stats.misses
    total_requests = total_hits + total_misses

    hit_rate =
      if total_requests > 0 do
        Float.round(total_hits / total_requests, 2)
      else
        0.0
      end

    # Analyze individual namespaces
    namespaces = [:spotify, :github, :web3, :ipfs, :portal]

    namespace_stats =
      Map.new(namespaces, fn ns ->
        stats = Cache.stats(ns)
        requests = stats.hits + stats.misses

        ns_hit_rate =
          if requests > 0 do
            Float.round(stats.hits / requests, 2)
          else
            0.0
          end

        {ns, Map.put(stats, :hit_rate, ns_hit_rate)}
      end)

    %{
      hit_rate: hit_rate,
      total_requests: total_requests,
      namespaces: namespace_stats
    }
  end

  ## Memory Analysis

  @doc """
  Analyzes memory pressure and usage patterns.

  ## Examples

      Optimizer.analyze_memory_pressure()
      # => %{
      #   pressure_level: :low,
      #   total_mb: 43.2,
      #   available_mb: 512.0,
      #   utilization: 0.084
      # }
  """
  @spec analyze_memory_pressure() :: map()
  def analyze_memory_pressure do
    snapshot = Monitor.memory_snapshot()
    total_bytes = snapshot.total
    total_mb = total_bytes / 1_048_576

    # Rough estimation (this is simplified - real implementation would check system memory)
    # For now, assume we have 512MB available for the application
    available_mb = 512.0
    utilization = total_mb / available_mb

    pressure_level =
      cond do
        utilization > 0.8 -> :high
        utilization > 0.5 -> :medium
        true -> :low
      end

    %{
      pressure_level: pressure_level,
      total_mb: Float.round(total_mb, 2),
      available_mb: available_mb,
      utilization: Float.round(utilization, 3)
    }
  end

  ## Bottleneck Detection

  @doc """
  Detects performance bottlenecks based on metrics.

  Returns list of bottleneck identifiers (e.g., `:spotify_api`, `:github_api`).

  ## Examples

      Optimizer.detect_bottlenecks()
      # => [:spotify_api, :web3_api]
  """
  @spec detect_bottlenecks() :: [atom()]
  def detect_bottlenecks do
    timing_metrics = Metrics.all_metrics(:timing)

    Enum.filter(timing_metrics, fn metric ->
      case Metrics.stats(metric) do
        nil ->
          false

        stats ->
          # Consider it a bottleneck if p95 > 500ms or mean > 200ms
          stats.p95 > 500 or stats.mean > 200
      end
    end)
  end

  ## Recommendations

  defp generate_recommendations(cache_stats, memory_stats, bottlenecks) do
    []
    |> maybe_recommend_cache_improvement(cache_stats)
    |> maybe_recommend_memory_optimization(memory_stats)
    |> maybe_recommend_api_optimization(bottlenecks)
    |> Enum.sort_by(& &1.priority, fn
      :high, :medium -> true
      :high, :low -> true
      :medium, :low -> true
      _, _ -> false
    end)
  end

  defp maybe_recommend_cache_improvement(recommendations, cache_stats) do
    if cache_stats.hit_rate < 0.8 and cache_stats.total_requests > 100 do
      recommendation = %{
        type: :cache,
        priority: :high,
        description:
          "Cache hit rate is #{trunc(cache_stats.hit_rate * 100)}% (target: >80%). " <>
            "Consider increasing cache TTL or reviewing cache strategy.",
        action: fn ->
          Logger.info("Recommendation: Improve cache efficiency")
          {:cache_improvement, cache_stats}
        end
      }

      [recommendation | recommendations]
    else
      recommendations
    end
  end

  defp maybe_recommend_memory_optimization(recommendations, memory_stats) do
    if memory_stats.pressure_level == :high do
      recommendation = %{
        type: :memory,
        priority: :high,
        description:
          "Memory pressure is high (#{trunc(memory_stats.utilization * 100)}%). " <>
            "Consider running garbage collection or reducing cache size.",
        action: fn ->
          :erlang.garbage_collect()
          Logger.info("Performed garbage collection")
          :gc_executed
        end
      }

      [recommendation | recommendations]
    else
      recommendations
    end
  end

  defp maybe_recommend_api_optimization(recommendations, bottlenecks) do
    if length(bottlenecks) > 0 do
      bottleneck_names = Enum.map_join(bottlenecks, ", ", &":#{&1}")

      recommendation = %{
        type: :api,
        priority: :medium,
        description:
          "API bottlenecks detected: #{bottleneck_names}. " <>
            "Consider implementing request batching or increasing cache TTL.",
        action: fn ->
          Logger.info("Recommendation: Optimize API calls for #{bottleneck_names}")
          {:api_optimization, bottlenecks}
        end
      }

      [recommendation | recommendations]
    else
      recommendations
    end
  end

  ## Automatic Optimizations

  defp maybe_prune_cache(optimizations) do
    cache_stats = Cache.stats(:all)

    # Prune if cache has >1000 entries
    if cache_stats.size > 1000 do
      deleted = Cache.prune_expired()
      Logger.info("Pruned #{deleted} expired cache entries")
      [:cache_cleanup | optimizations]
    else
      optimizations
    end
  end

  defp maybe_run_gc(optimizations) do
    memory_stats = analyze_memory_pressure()

    if memory_stats.pressure_level == :high do
      :erlang.garbage_collect()
      Logger.info("Executed garbage collection due to high memory pressure")
      [:memory_gc | optimizations]
    else
      optimizations
    end
  end

  defp maybe_optimize_ets(optimizations) do
    # Currently no automatic ETS optimizations
    # Could add compaction or reorganization here
    optimizations
  end

  ## Formatted Reports

  @doc """
  Generates a formatted optimization report for terminal display.

  ## Examples

      IO.puts(Optimizer.format_report())
  """
  @spec format_report() :: String.t()
  def format_report do
    analysis = analyze()

    cache_status = format_status(analysis.cache_efficiency >= 0.8)
    memory_status = format_status(analysis.memory_pressure == :low)
    process_status = format_status(analysis.process_utilization < 0.5)

    recommendations_text =
      if Enum.empty?(analysis.recommendations) do
        "│  No recommendations - system is performing well!                 │"
      else
        analysis.recommendations
        |> Enum.take(5)
        |> Enum.map_join("\n", &format_recommendation/1)
      end

    """
    ┌─ PERFORMANCE OPTIMIZER ────────────────────────────────────────────┐
    │                                                                     │
    │  SYSTEM HEALTH                                                     │
    │  Cache Efficiency:  #{String.pad_trailing("#{trunc(analysis.cache_efficiency * 100)}%", 10)} #{cache_status}                    │
    │  Memory Pressure:   #{String.pad_trailing("#{analysis.memory_pressure}", 10)} #{memory_status}                    │
    │  Process Usage:     #{String.pad_trailing("#{analysis.process_utilization}%", 10)} #{process_status}                    │
    │                                                                     │
    │  BOTTLENECKS                                                       │
    #{format_bottlenecks(analysis.bottlenecks)}
    │                                                                     │
    │  RECOMMENDATIONS (Top 5)                                           │
    #{recommendations_text}
    │                                                                     │
    └─────────────────────────────────────────────────────────────────────┘
    """
  end

  defp format_status(true), do: "[OK]"
  defp format_status(false), do: "[WARN]"

  defp format_bottlenecks([]) do
    "│  (none detected)                                                   │"
  end

  defp format_bottlenecks(bottlenecks) do
    bottlenecks
    |> Enum.take(3)
    |> Enum.map_join("\n", fn bottleneck ->
      stats = Metrics.stats(bottleneck)

      name = to_string(bottleneck) |> String.pad_trailing(20)

      stats_text =
        if stats do
          "P95: #{trunc(stats.p95)}ms"
        else
          "N/A"
        end
        |> String.pad_trailing(15)

      "│  #{name} #{stats_text}                      │"
    end)
  end

  defp format_recommendation(rec) do
    priority_icon =
      case rec.priority do
        :high -> "[!]"
        :medium -> "[*]"
        :low -> "[-]"
      end

    # Truncate description to fit in box (max ~55 chars per line)
    lines = wrap_text(rec.description, 55)

    lines
    |> Enum.with_index()
    |> Enum.map_join("\n", fn {line, idx} ->
      if idx == 0 do
        "│  #{priority_icon} #{String.pad_trailing(line, 55)} │"
      else
        "│      #{String.pad_trailing(line, 55)} │"
      end
    end)
  end

  defp wrap_text(text, width) do
    words = String.split(text, " ")

    {lines, current} =
      Enum.reduce(words, {[], ""}, fn word, {lines, current} ->
        candidate = if current == "", do: word, else: "#{current} #{word}"

        if String.length(candidate) <= width do
          {lines, candidate}
        else
          {lines ++ [current], word}
        end
      end)

    if current != "" do
      lines ++ [current]
    else
      lines
    end
  end
end
