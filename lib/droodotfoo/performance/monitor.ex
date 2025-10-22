defmodule Droodotfoo.Performance.Monitor do
  @moduledoc """
  Real-time performance monitoring for system resources and application health.

  This module provides utilities for monitoring memory usage, CPU usage, process
  health, and other system metrics. It integrates with the terminal UI to display
  performance data and can trigger alerts when thresholds are exceeded.

  ## Features

  - Memory usage tracking (total, processes, atoms, binary, ETS)
  - Process count and mailbox monitoring
  - ETS table statistics
  - GenServer health checks
  - Performance thresholds with alerts
  - ASCII-formatted reports for terminal display

  ## Usage

      # Get current memory snapshot
      Monitor.memory_snapshot()
      # => %{total: 45_234_567, processes: 12_345_678, ...}

      # Monitor critical GenServers
      Monitor.check_genserver_health(Droodotfoo.Spotify.Manager)
      # => %{alive: true, message_queue_len: 0, memory: 123456}

      # Get ETS table statistics
      Monitor.ets_stats()
      # => [%{name: :droodotfoo_cache, size: 1234, memory: 524288}, ...]

      # Format performance report for terminal
      Monitor.format_report()
      # => ASCII-formatted performance dashboard
  """

  require Logger

  @type memory_snapshot :: %{
          total: non_neg_integer(),
          processes: non_neg_integer(),
          atom: non_neg_integer(),
          binary: non_neg_integer(),
          code: non_neg_integer(),
          ets: non_neg_integer()
        }

  @type process_stats :: %{
          count: non_neg_integer(),
          max: non_neg_integer(),
          limit: non_neg_integer(),
          utilization: float()
        }

  @type genserver_health :: %{
          alive: boolean(),
          message_queue_len: non_neg_integer(),
          memory: non_neg_integer(),
          reductions: non_neg_integer()
        }

  @type ets_table_stats :: %{
          name: atom(),
          size: non_neg_integer(),
          memory: non_neg_integer(),
          type: atom()
        }

  ## Memory Monitoring

  @doc """
  Returns a snapshot of current memory usage across different categories.

  Memory values are in bytes.

  ## Examples

      Monitor.memory_snapshot()
      # => %{
      #   total: 45_234_567,
      #   processes: 12_345_678,
      #   atom: 567_890,
      #   binary: 8_901_234,
      #   code: 15_678_901,
      #   ets: 2_345_678
      # }
  """
  @spec memory_snapshot() :: memory_snapshot()
  def memory_snapshot do
    memory = :erlang.memory()

    %{
      total: Keyword.get(memory, :total, 0),
      processes: Keyword.get(memory, :processes, 0),
      atom: Keyword.get(memory, :atom, 0),
      binary: Keyword.get(memory, :binary, 0),
      code: Keyword.get(memory, :code, 0),
      ets: Keyword.get(memory, :ets, 0)
    }
  end

  @doc """
  Returns formatted memory usage in human-readable units (KB, MB, GB).

  ## Examples

      Monitor.format_memory(45_234_567)
      # => "43.15 MB"
  """
  @spec format_memory(non_neg_integer()) :: String.t()
  def format_memory(bytes) when bytes < 1024, do: "#{bytes} B"
  def format_memory(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 2)} KB"

  def format_memory(bytes) when bytes < 1_073_741_824,
    do: "#{Float.round(bytes / 1_048_576, 2)} MB"

  def format_memory(bytes), do: "#{Float.round(bytes / 1_073_741_824, 2)} GB"

  @doc """
  Returns the percentage of memory used by a specific category.

  ## Examples

      snapshot = Monitor.memory_snapshot()
      Monitor.memory_percentage(snapshot.processes, snapshot.total)
      # => 27.3
  """
  @spec memory_percentage(non_neg_integer(), non_neg_integer()) :: float()
  def memory_percentage(_used, 0), do: 0.0
  def memory_percentage(used, total), do: Float.round(used / total * 100, 1)

  ## Process Monitoring

  @doc """
  Returns statistics about BEAM processes.

  ## Examples

      Monitor.process_stats()
      # => %{count: 342, max: 500, limit: 262144, utilization: 0.13}
  """
  @spec process_stats() :: process_stats()
  def process_stats do
    count = :erlang.system_info(:process_count)
    limit = :erlang.system_info(:process_limit)

    # Track historical max (in process dictionary for simplicity)
    max = max(count, Process.get(:max_process_count, 0))
    Process.put(:max_process_count, max)

    %{
      count: count,
      max: max,
      limit: limit,
      utilization: Float.round(count / limit * 100, 2)
    }
  end

  @doc """
  Checks the health of a specific GenServer process.

  Returns process statistics if alive, or error information if dead.

  ## Examples

      Monitor.check_genserver_health(Droodotfoo.Spotify.Manager)
      # => %{alive: true, message_queue_len: 0, memory: 123456, reductions: 5678}

      Monitor.check_genserver_health(MyDeadServer)
      # => %{alive: false}
  """
  @spec check_genserver_health(atom() | pid()) :: genserver_health()
  def check_genserver_health(name_or_pid) do
    pid = resolve_pid(name_or_pid)

    if pid && Process.alive?(pid) do
      info = Process.info(pid, [:message_queue_len, :memory, :reductions])

      %{
        alive: true,
        message_queue_len: Keyword.get(info, :message_queue_len, 0),
        memory: Keyword.get(info, :memory, 0),
        reductions: Keyword.get(info, :reductions, 0)
      }
    else
      %{alive: false}
    end
  end

  @doc """
  Returns a list of processes with the largest mailboxes.

  Useful for identifying potential bottlenecks.

  ## Examples

      Monitor.top_mailboxes(5)
      # => [
      #   %{pid: #PID<0.123.0>, name: MyWorker, queue_len: 1234},
      #   ...
      # ]
  """
  @spec top_mailboxes(pos_integer()) :: [map()]
  def top_mailboxes(limit \\ 10) do
    Process.list()
    |> Enum.map(fn pid ->
      info = Process.info(pid, [:registered_name, :message_queue_len])

      %{
        pid: pid,
        name: Keyword.get(info, :registered_name),
        queue_len: Keyword.get(info, :message_queue_len, 0)
      }
    end)
    |> Enum.sort_by(& &1.queue_len, :desc)
    |> Enum.take(limit)
  end

  ## ETS Monitoring

  @doc """
  Returns statistics for all ETS tables in the system.

  ## Examples

      Monitor.ets_stats()
      # => [
      #   %{name: :droodotfoo_cache, size: 1234, memory: 524288, type: :set},
      #   %{name: :droodotfoo_cache_stats, size: 20, memory: 8192, type: :set}
      # ]
  """
  @spec ets_stats() :: [ets_table_stats()]
  def ets_stats do
    :ets.all()
    |> Enum.map(fn table ->
      info = :ets.info(table)
      wordsize = :erlang.system_info(:wordsize)

      %{
        name: Keyword.get(info, :name),
        size: Keyword.get(info, :size, 0),
        memory: Keyword.get(info, :memory, 0) * wordsize,
        type: Keyword.get(info, :type)
      }
    end)
    |> Enum.sort_by(& &1.memory, :desc)
  end

  @doc """
  Returns total memory used by all ETS tables.

  ## Examples

      Monitor.total_ets_memory()
      # => 2_097_152  # bytes
  """
  @spec total_ets_memory() :: non_neg_integer()
  def total_ets_memory do
    ets_stats()
    |> Enum.map(& &1.memory)
    |> Enum.sum()
  end

  ## System Information

  @doc """
  Returns general system information.

  ## Examples

      Monitor.system_info()
      # => %{
      #   otp_release: "26",
      #   erts_version: "14.0",
      #   schedulers: 8,
      #   uptime_seconds: 3661
      # }
  """
  @spec system_info() :: map()
  def system_info do
    %{
      otp_release: :erlang.system_info(:otp_release) |> to_string(),
      erts_version: :erlang.system_info(:version) |> to_string(),
      schedulers: :erlang.system_info(:schedulers),
      schedulers_online: :erlang.system_info(:schedulers_online),
      uptime_seconds: div(:erlang.statistics(:wall_clock) |> elem(0), 1000)
    }
  end

  ## Formatted Reports

  @doc """
  Generates an ASCII-formatted performance report for terminal display.

  ## Examples

      IO.puts(Monitor.format_report())
  """
  @spec format_report() :: String.t()
  def format_report do
    memory = memory_snapshot()
    processes = process_stats()
    sys_info = system_info()
    ets = ets_stats()

    """
    ┌─ PERFORMANCE MONITOR ──────────────────────────────────────────────────┐
    │                                                                         │
    │  MEMORY USAGE                                                          │
    │  Total:     #{String.pad_trailing(format_memory(memory.total), 15)} (100%)        │
    │  Processes: #{String.pad_trailing(format_memory(memory.processes), 15)} (#{memory_percentage(memory.processes, memory.total)}%)        │
    │  Atom:      #{String.pad_trailing(format_memory(memory.atom), 15)} (#{memory_percentage(memory.atom, memory.total)}%)        │
    │  Binary:    #{String.pad_trailing(format_memory(memory.binary), 15)} (#{memory_percentage(memory.binary, memory.total)}%)        │
    │  Code:      #{String.pad_trailing(format_memory(memory.code), 15)} (#{memory_percentage(memory.code, memory.total)}%)        │
    │  ETS:       #{String.pad_trailing(format_memory(memory.ets), 15)} (#{memory_percentage(memory.ets, memory.total)}%)        │
    │                                                                         │
    │  PROCESSES                                                             │
    │  Count:        #{processes.count} / #{processes.limit}                          │
    │  Utilization:  #{processes.utilization}%                                       │
    │                                                                         │
    │  SYSTEM                                                                │
    │  OTP Release:  #{sys_info.otp_release}                                          │
    │  Schedulers:   #{sys_info.schedulers_online} / #{sys_info.schedulers}                        │
    │  Uptime:       #{format_uptime(sys_info.uptime_seconds)}                       │
    │                                                                         │
    │  ETS TABLES (Top 5)                                                    │
    #{format_ets_table_list(Enum.take(ets, 5))}
    └─────────────────────────────────────────────────────────────────────────┘
    """
  end

  @doc """
  Generates a compact performance summary (one line).

  ## Examples

      Monitor.format_summary()
      # => "MEM: 43.2MB | PROC: 342/262144 (0.13%) | ETS: 2.0MB"
  """
  @spec format_summary() :: String.t()
  def format_summary do
    memory = memory_snapshot()
    processes = process_stats()
    ets_mem = total_ets_memory()

    "MEM: #{format_memory(memory.total)} | " <>
      "PROC: #{processes.count}/#{processes.limit} (#{processes.utilization}%) | " <>
      "ETS: #{format_memory(ets_mem)}"
  end

  ## Health Checks

  @doc """
  Checks the health of critical application GenServers.

  Returns a map of server names to health status.

  ## Examples

      Monitor.check_critical_servers()
      # => %{
      #   Droodotfoo.RaxolApp => %{alive: true, ...},
      #   Droodotfoo.Spotify.Manager => %{alive: true, ...}
      # }
  """
  @spec check_critical_servers() :: %{atom() => genserver_health()}
  def check_critical_servers do
    servers = [
      Droodotfoo.RaxolApp,
      Droodotfoo.Spotify.Manager,
      Droodotfoo.GitHub.Manager,
      Droodotfoo.Web3.Manager,
      Droodotfoo.Performance.Cache
    ]

    Map.new(servers, fn server ->
      {server, check_genserver_health(server)}
    end)
  end

  ## Private Functions

  defp resolve_pid(pid) when is_pid(pid), do: pid
  defp resolve_pid(name) when is_atom(name), do: Process.whereis(name)

  defp format_uptime(seconds) when seconds < 60, do: "#{seconds}s"
  defp format_uptime(seconds) when seconds < 3600, do: "#{div(seconds, 60)}m"

  defp format_uptime(seconds) when seconds < 86_400,
    do: "#{div(seconds, 3600)}h #{rem(div(seconds, 60), 60)}m"

  defp format_uptime(seconds),
    do: "#{div(seconds, 86_400)}d #{rem(div(seconds, 3600), 24)}h"

  defp format_ets_table_list([]),
    do: "│  (none)                                                             │\n"

  defp format_ets_table_list(tables) do
    tables
    |> Enum.map_join("\n", fn table ->
      name = table.name |> to_string() |> String.pad_trailing(25)
      size = table.size |> to_string() |> String.pad_leading(6)
      memory = format_memory(table.memory) |> String.pad_leading(10)

      "│  #{name} #{size} entries  #{memory}        │"
    end)
    |> then(&(&1 <> "\n"))
  end
end
