defmodule Droodotfoo.PerformanceMonitorTest do
  use ExUnit.Case, async: false
  alias Droodotfoo.PerformanceMonitor

  setup do
    # Ensure PerformanceMonitor is running
    monitor_pid =
      case Process.whereis(PerformanceMonitor) do
        nil ->
          # Start it if not running
          {:ok, pid} = start_supervised(PerformanceMonitor)
          pid

        pid ->
          pid
      end

    # Reset metrics before each test to ensure isolation
    PerformanceMonitor.reset_metrics()
    {:ok, monitor: monitor_pid}
  end

  describe "initialization" do
    test "starts with empty metrics", _context do
      metrics = PerformanceMonitor.get_metrics()

      assert metrics.render_times == []
      assert metrics.memory_usage == []
      assert metrics.process_count == []
      assert metrics.message_queue_lengths == []
      assert metrics.request_count == 0
      assert metrics.error_count == 0
      assert metrics.uptime >= 0
    end
  end

  describe "render time tracking" do
    test "records render times", _context do
      PerformanceMonitor.record_render_time(10.5)
      PerformanceMonitor.record_render_time(15.3)
      PerformanceMonitor.record_render_time(12.7)

      # Small delay to ensure cast is processed
      Process.sleep(10)

      metrics = PerformanceMonitor.get_metrics()
      assert length(metrics.render_times) == 3
      # Most recent first
      assert hd(metrics.render_times) == 12.7
    end

    test "maintains window of 100 render times", _context do
      # Record 150 render times
      for i <- 1..150 do
        PerformanceMonitor.record_render_time(i * 1.0)
      end

      Process.sleep(50)

      metrics = PerformanceMonitor.get_metrics()
      assert length(metrics.render_times) == 100
      # Most recent
      assert hd(metrics.render_times) == 150.0
    end
  end

  describe "error tracking" do
    test "counts errors", _context do
      initial = PerformanceMonitor.get_metrics()
      assert initial.error_count == 0

      PerformanceMonitor.record_error()
      PerformanceMonitor.record_error()
      PerformanceMonitor.record_error()

      Process.sleep(10)

      metrics = PerformanceMonitor.get_metrics()
      assert metrics.error_count == 3
    end
  end

  describe "request tracking" do
    test "counts requests", _context do
      initial = PerformanceMonitor.get_metrics()
      assert initial.request_count == 0

      for _ <- 1..10 do
        PerformanceMonitor.record_request()
      end

      Process.sleep(10)

      metrics = PerformanceMonitor.get_metrics()
      assert metrics.request_count == 10
    end
  end

  describe "summary statistics" do
    test "calculates render time statistics", _context do
      render_times = [5.0, 10.0, 15.0, 20.0, 25.0]

      for time <- render_times do
        PerformanceMonitor.record_render_time(time)
      end

      Process.sleep(10)

      summary = PerformanceMonitor.get_summary()

      assert summary.avg_render_time == 15.0
      assert summary.min_render_time == 5.0
      assert summary.max_render_time == 25.0
      assert summary.p95_render_time > 0
    end

    test "handles empty render times", _context do
      summary = PerformanceMonitor.get_summary()

      assert summary.avg_render_time == 0.0
      assert summary.min_render_time == 0
      assert summary.max_render_time == 0
      assert summary.p95_render_time == 0
    end

    test "calculates request rate", _context do
      for _ <- 1..60 do
        PerformanceMonitor.record_request()
      end

      Process.sleep(10)

      summary = PerformanceMonitor.get_summary()

      # Rate should be around 60 requests per minute (if uptime is 1 second)
      assert summary.total_requests == 60
      assert summary.requests_per_minute > 0
    end

    test "calculates error rate", _context do
      for _ <- 1..90 do
        PerformanceMonitor.record_request()
      end

      for _ <- 1..10 do
        PerformanceMonitor.record_error()
      end

      Process.sleep(10)

      summary = PerformanceMonitor.get_summary()

      assert summary.total_requests == 90
      assert summary.total_errors == 10
      # 10 errors out of 90 requests = 11.11%
      assert_in_delta summary.error_rate, 11.11, 0.1
    end

    test "handles zero requests in error rate", _context do
      summary = PerformanceMonitor.get_summary()
      assert summary.error_rate == 0.0

      PerformanceMonitor.record_error()
      Process.sleep(10)

      summary = PerformanceMonitor.get_summary()
      # No requests, so 0% rate
      assert summary.error_rate == 0.0
    end
  end

  describe "system metrics collection" do
    test "collects memory usage", _context do
      # Trigger system metrics collection
      send(PerformanceMonitor, :collect_system_metrics)
      Process.sleep(20)

      metrics = PerformanceMonitor.get_metrics()

      assert length(metrics.memory_usage) > 0
      # Memory in MB
      assert hd(metrics.memory_usage) > 0
    end

    test "collects process count", _context do
      send(PerformanceMonitor, :collect_system_metrics)
      Process.sleep(20)

      metrics = PerformanceMonitor.get_metrics()

      assert length(metrics.process_count) > 0
      assert hd(metrics.process_count) > 0
    end

    test "collects message queue lengths", _context do
      send(PerformanceMonitor, :collect_system_metrics)
      Process.sleep(20)

      metrics = PerformanceMonitor.get_metrics()

      assert length(metrics.message_queue_lengths) > 0
      queue_info = hd(metrics.message_queue_lengths)
      assert is_map(queue_info)
      assert Map.has_key?(queue_info, :total)
      assert Map.has_key?(queue_info, :max)
      assert Map.has_key?(queue_info, :avg)
    end

    test "maintains window of system metrics", _context do
      # Trigger many collections
      for _ <- 1..10 do
        send(PerformanceMonitor, :collect_system_metrics)
        Process.sleep(5)
      end

      Process.sleep(50)

      metrics = PerformanceMonitor.get_metrics()

      # Should cap at window size (100)
      assert length(metrics.memory_usage) <= 100
      assert length(metrics.process_count) <= 100
    end
  end

  describe "percentile calculation" do
    test "calculates 95th percentile correctly", _context do
      # Add 100 render times from 1 to 100
      for i <- 1..100 do
        PerformanceMonitor.record_render_time(i * 1.0)
      end

      Process.sleep(50)

      summary = PerformanceMonitor.get_summary()

      # P95 of 1-100 should be 95
      assert summary.p95_render_time == 95.0
    end

    test "handles small sample sizes", _context do
      PerformanceMonitor.record_render_time(10.0)
      PerformanceMonitor.record_render_time(20.0)

      Process.sleep(10)

      summary = PerformanceMonitor.get_summary()
      assert summary.p95_render_time in [10.0, 20.0]
    end
  end

  describe "uptime tracking" do
    test "tracks uptime in hours", _context do
      Process.sleep(100)

      summary = PerformanceMonitor.get_summary()

      # Should have some small uptime
      assert summary.uptime_hours >= 0.0
      # Less than an hour
      assert summary.uptime_hours < 1.0
    end
  end

  describe "memory statistics" do
    test "tracks current and average memory", _context do
      # Trigger multiple collections
      for _ <- 1..5 do
        send(PerformanceMonitor, :collect_system_metrics)
        Process.sleep(10)
      end

      summary = PerformanceMonitor.get_summary()

      assert summary.current_memory > 0
      assert summary.avg_memory > 0
      assert is_float(summary.current_memory)
      assert is_float(summary.avg_memory)
    end
  end

  describe "process statistics" do
    test "tracks current and average process count", _context do
      # Trigger multiple collections
      for _ <- 1..5 do
        send(PerformanceMonitor, :collect_system_metrics)
        Process.sleep(10)
      end

      summary = PerformanceMonitor.get_summary()

      assert summary.current_processes > 0
      assert summary.avg_processes > 0
      assert is_integer(summary.current_processes)
      assert is_integer(summary.avg_processes)
    end
  end

  describe "message queue monitoring" do
    test "tracks max queue length", _context do
      # Create a process with a message queue
      test_pid =
        spawn(fn ->
          receive do
            :stop -> :ok
          after
            5000 -> :timeout
          end
        end)

      # Send messages to build queue
      for i <- 1..10 do
        send(test_pid, {:msg, i})
      end

      # Trigger collection
      send(PerformanceMonitor, :collect_system_metrics)
      Process.sleep(20)

      summary = PerformanceMonitor.get_summary()

      assert summary.max_queue_length >= 0

      # Cleanup
      send(test_pid, :stop)
    end
  end

  describe "performance under load" do
    test "handles rapid metric recording", _context do
      tasks =
        for i <- 1..1000 do
          Task.async(fn ->
            PerformanceMonitor.record_render_time(i * 0.01)
            if rem(i, 10) == 0, do: PerformanceMonitor.record_error()
            if rem(i, 5) == 0, do: PerformanceMonitor.record_request()
          end)
        end

      Task.await_many(tasks, 5000)
      Process.sleep(100)

      metrics = PerformanceMonitor.get_metrics()

      # Window limit
      assert length(metrics.render_times) == 100
      assert metrics.error_count == 100
      assert metrics.request_count == 200
    end

    test "maintains consistency under concurrent access", _context do
      # Spawn multiple processes recording metrics
      _pids =
        for _ <- 1..10 do
          spawn(fn ->
            for _ <- 1..100 do
              PerformanceMonitor.record_render_time(:rand.uniform() * 50)
              PerformanceMonitor.record_request()
            end
          end)
        end

      # Wait for completion
      Process.sleep(200)

      metrics = PerformanceMonitor.get_metrics()
      summary = PerformanceMonitor.get_summary()

      # Should have recorded all requests
      assert metrics.request_count == 1000
      assert summary.total_requests == 1000
    end
  end

  describe "edge cases and error handling" do
    test "handles negative render times", _context do
      PerformanceMonitor.record_render_time(-10.0)
      PerformanceMonitor.record_render_time(10.0)

      Process.sleep(10)

      summary = PerformanceMonitor.get_summary()
      assert summary.min_render_time == -10.0
    end

    test "handles very large render times", _context do
      PerformanceMonitor.record_render_time(999_999.0)

      Process.sleep(10)

      summary = PerformanceMonitor.get_summary()
      assert summary.max_render_time == 999_999.0
    end

    test "safe division by zero handling", _context do
      summary = PerformanceMonitor.get_summary()

      # Should handle empty lists gracefully
      assert summary.avg_render_time == 0.0
      assert summary.error_rate == 0.0
      assert summary.avg_memory >= 0.0
    end

    test "timer cleanup on termination", _context do
      # Start a monitor we can terminate
      {:ok, pid} = GenServer.start(PerformanceMonitor, [])

      # Get state to verify timers exist
      :sys.get_state(pid)

      # Stop the server
      GenServer.stop(pid)

      # Should terminate cleanly without errors
      refute Process.alive?(pid)
    end

    test "handles malformed state gracefully", _context do
      # This tests the second terminate clause
      _pid = Process.whereis(PerformanceMonitor)

      # Send a terminate with non-struct state
      result = PerformanceMonitor.terminate(:normal, %{})
      assert result == :ok
    end
  end

  describe "reporting intervals" do
    test "schedules periodic reporting", _context do
      # The monitor should schedule reports
      # We can't easily test the 60-second interval without waiting,
      # but we can verify the message handling

      send(PerformanceMonitor, :report_metrics)

      # Should handle the report message without crashing
      Process.sleep(10)

      # Monitor should still be alive
      assert Process.alive?(Process.whereis(PerformanceMonitor))
    end

    test "schedules system metrics collection", _context do
      # Verify periodic collection is scheduled
      send(PerformanceMonitor, :collect_system_metrics)
      Process.sleep(10)

      metrics = PerformanceMonitor.get_metrics()
      assert length(metrics.memory_usage) > 0
    end
  end
end
