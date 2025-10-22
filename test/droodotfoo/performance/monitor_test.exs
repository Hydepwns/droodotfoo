defmodule Droodotfoo.Performance.MonitorTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.Performance.Monitor

  describe "memory_snapshot/0" do
    test "returns memory usage statistics" do
      snapshot = Monitor.memory_snapshot()

      assert is_integer(snapshot.total)
      assert is_integer(snapshot.processes)
      assert is_integer(snapshot.atom)
      assert is_integer(snapshot.binary)
      assert is_integer(snapshot.code)
      assert is_integer(snapshot.ets)
      assert snapshot.total > 0
    end
  end

  describe "format_memory/1" do
    test "formats bytes correctly" do
      assert Monitor.format_memory(512) == "512 B"
      assert Monitor.format_memory(2048) == "2.0 KB"
      assert Monitor.format_memory(2_097_152) == "2.0 MB"
      assert Monitor.format_memory(2_147_483_648) == "2.0 GB"
    end
  end

  describe "memory_percentage/2" do
    test "calculates percentage correctly" do
      assert Monitor.memory_percentage(25, 100) == 25.0
      assert Monitor.memory_percentage(50, 100) == 50.0
      assert Monitor.memory_percentage(0, 100) == 0.0
    end

    test "handles zero total gracefully" do
      assert Monitor.memory_percentage(10, 0) == 0.0
    end
  end

  describe "process_stats/0" do
    test "returns process statistics" do
      stats = Monitor.process_stats()

      assert is_integer(stats.count)
      assert is_integer(stats.limit)
      assert is_float(stats.utilization)
      assert stats.count > 0
      assert stats.limit > 0
      assert stats.utilization >= 0.0
    end
  end

  describe "check_genserver_health/1" do
    test "returns health info for alive process" do
      # Use :init as it's always running
      health = Monitor.check_genserver_health(:init)

      assert health.alive == true
      assert is_integer(health.message_queue_len)
      assert is_integer(health.memory)
      assert is_integer(health.reductions)
    end

    test "returns dead status for non-existent process" do
      health = Monitor.check_genserver_health(:nonexistent_process)

      assert health.alive == false
    end
  end

  describe "ets_stats/0" do
    test "returns ETS table statistics" do
      stats = Monitor.ets_stats()

      assert is_list(stats)
      assert length(stats) > 0

      first = List.first(stats)
      assert is_atom(first.name)
      assert is_integer(first.size)
      assert is_integer(first.memory)
      assert is_atom(first.type)
    end
  end

  describe "total_ets_memory/0" do
    test "calculates total ETS memory" do
      total = Monitor.total_ets_memory()

      assert is_integer(total)
      assert total > 0
    end
  end

  describe "system_info/0" do
    test "returns system information" do
      info = Monitor.system_info()

      assert is_binary(info.otp_release)
      assert is_binary(info.erts_version)
      assert is_integer(info.schedulers)
      assert is_integer(info.schedulers_online)
      assert is_integer(info.uptime_seconds)
      assert info.schedulers > 0
    end
  end

  describe "format_report/0" do
    test "generates formatted report" do
      report = Monitor.format_report()

      assert is_binary(report)
      assert String.contains?(report, "PERFORMANCE MONITOR")
      assert String.contains?(report, "MEMORY USAGE")
      assert String.contains?(report, "PROCESSES")
      assert String.contains?(report, "SYSTEM")
    end
  end

  describe "format_summary/0" do
    test "generates compact summary" do
      summary = Monitor.format_summary()

      assert is_binary(summary)
      assert String.contains?(summary, "MEM:")
      assert String.contains?(summary, "PROC:")
      assert String.contains?(summary, "ETS:")
    end
  end
end
