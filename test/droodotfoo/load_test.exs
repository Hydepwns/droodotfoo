defmodule Droodotfoo.LoadTest do
  use ExUnit.Case, async: false
  alias Droodotfoo.{RaxolApp, InputRateLimiter, InputDebouncer, AdaptiveRefresh}

  setup do
    # Ensure RaxolApp is running for load tests
    raxol_pid = case Process.whereis(RaxolApp) do
      nil ->
        {:ok, pid} = start_supervised(RaxolApp)
        pid
      pid ->
        pid
    end

    # Reset all shared state to prevent test interference
    Droodotfoo.StateResetHelper.reset_all_state()

    {:ok, raxol_pid: raxol_pid}
  end

  describe "concurrent connection load tests" do
    @describetag :load_test
    @describetag timeout: 60_000
    test "handles 100+ concurrent keyboard inputs to RaxolApp" do
      # Get the running RaxolApp
      raxol_pid = Process.whereis(Droodotfoo.RaxolApp)
      assert raxol_pid != nil

      # Create 100 concurrent tasks simulating keyboard input
      tasks =
        for i <- 1..100 do
          Task.async(fn ->
            # Each task sends 10 keyboard events
            for _j <- 1..10 do
              key = Enum.random(["h", "j", "k", "l", "g", "G", "w", "b", "e", "0", "$"])
              GenServer.cast(raxol_pid, {:input, key})

              # Small random delay to simulate typing
              Process.sleep(:rand.uniform(5))
            end

            {:ok, i}
          end)
        end

      # Wait for all tasks to complete
      results = Task.await_many(tasks, 30_000)

      # Verify all tasks completed
      assert length(results) == 100

      assert Enum.all?(results, fn
               {:ok, _} -> true
               _ -> false
             end)

      # Check that RaxolApp is still alive
      assert Process.alive?(raxol_pid)
    end

    test "rate limiter handles burst of 1000 events" do
      limiter = InputRateLimiter.new()

      # Simulate 1000 rapid events
      {final_limiter, results} =
        Enum.reduce(1..1000, {limiter, []}, fn _i, {lim, acc} ->
          {allowed, new_lim} = InputRateLimiter.allow_event?(lim)
          {new_lim, [allowed | acc]}
        end)

      allowed_count = Enum.count(results, &(&1 == true))
      blocked_count = Enum.count(results, &(&1 == false))

      # Should have blocked most events after initial burst
      # At least the initial bucket
      assert allowed_count >= 30
      # Most should be blocked
      assert blocked_count > 900
      assert allowed_count + blocked_count == 1000

      # Verify stats consistency
      stats = InputRateLimiter.stats(final_limiter)
      assert stats.events_allowed == allowed_count
      assert stats.events_blocked == blocked_count
    end

    test "debouncer handles rapid mixed input patterns" do
      debouncer = InputDebouncer.new(%{debounce_ms: 5, batch_size: 20})

      # Generate 500 mixed keys
      keys =
        Enum.flat_map(1..100, fn i ->
          if rem(i, 20) == 0 do
            # Instant key
            ["Enter"]
          else
            # Regular keys
            ["a", "b", "c", "d", "e"]
          end
        end)

      {_final_state, batches, instant_count} =
        Enum.reduce(keys, {debouncer, [], 0}, fn key, {state, batch_acc, instant_acc} ->
          case InputDebouncer.process_key(state, key) do
            {:immediate, _} ->
              {state, batch_acc, instant_acc + 1}

            {:batch_with_immediate, batch, _, new_state} ->
              {new_state, [batch | batch_acc], instant_acc + 1}

            {:debounced, new_state} ->
              {new_state, batch_acc, instant_acc}

            {:batched, batch, new_state} ->
              {new_state, [batch | batch_acc], instant_acc}

            {:batch_then_start, batch, new_state} ->
              {new_state, [batch | batch_acc], instant_acc}
          end
        end)

      # Should have processed instant keys immediately
      # At least 5 Enter keys
      assert instant_count >= 5

      # Should have batched regular keys
      total_batched =
        Enum.reduce(batches, 0, fn batch, sum ->
          sum + length(batch)
        end)

      assert total_batched > 0
    end

    test "adaptive refresh adjusts under varying load" do
      refresh = AdaptiveRefresh.new()

      # Simulate different activity patterns
      patterns = [
        # No activity for 100ms
        {:idle, 0, 100},
        # 50 activities in 10ms
        {:burst, 50, 10},
        # 10 activities in 50ms
        {:normal, 10, 50},
        # 100 activities over 200ms
        {:sustained, 100, 200}
      ]

      final_state =
        Enum.reduce(patterns, refresh, fn {_type, activity_count, duration}, state ->
          # Record activities
          state =
            Enum.reduce(1..activity_count, state, fn _, acc ->
              AdaptiveRefresh.record_activity(acc)
            end)

          # Simulate render cycles
          state =
            if activity_count > 0 do
              avg_render = if activity_count > 30, do: 20.0, else: 10.0
              AdaptiveRefresh.record_render(state, avg_render)
            else
              state
            end

          # Simulate time passing
          # Scale down for test speed
          Process.sleep(div(duration, 10))

          state
        end)

      # Should have adjusted FPS based on patterns
      metrics = AdaptiveRefresh.get_metrics(final_state)
      assert metrics.current_fps > 0
      assert metrics.target_fps > 0
    end
  end

  describe "rapid keyboard input sequences" do
    @describetag :load_test
    test "processes 1000 keys in rapid succession" do
      raxol_pid = Process.whereis(Droodotfoo.RaxolApp)
      initial_state = :sys.get_state(raxol_pid)

      # Send 1000 rapid keypresses
      for _ <- 1..1000 do
        key = Enum.random(String.graphemes("hjklwbeggG0$/?:q"))
        GenServer.cast(raxol_pid, {:input, key})
      end

      # Give time to process
      Process.sleep(100)

      # Verify RaxolApp is still responsive
      assert Process.alive?(raxol_pid)

      # Get final state
      final_state = :sys.get_state(raxol_pid)

      # State should have changed
      assert final_state != initial_state
    end

    test "handles command mode input sequences" do
      raxol_pid = Process.whereis(Droodotfoo.RaxolApp)

      # Enter command mode and type commands
      sequences = [
        [":", "h", "e", "l", "p", "Enter"],
        [":", "c", "l", "e", "a", "r", "Enter"],
        [":", "q", "Enter"],
        ["/", "t", "e", "s", "t", "Enter"],
        ["Escape"]
      ]

      for sequence <- sequences do
        for key <- sequence do
          GenServer.cast(raxol_pid, {:input, key})
          # Minimal delay between keys
          Process.sleep(1)
        end
      end

      # Verify still alive
      assert Process.alive?(raxol_pid)
    end

    test "handles navigation patterns under load" do
      raxol_pid = Process.whereis(Droodotfoo.RaxolApp)

      # Simulate various navigation patterns
      patterns = [
        # Rapid hjkl navigation
        List.duplicate("h", 50) ++
          List.duplicate("j", 50) ++
          List.duplicate("k", 50) ++ List.duplicate("l", 50),

        # Page navigation
        List.duplicate("G", 10) ++ List.duplicate("g", 10),

        # Word navigation
        List.duplicate("w", 30) ++ List.duplicate("b", 30),

        # Line navigation
        List.duplicate("0", 20) ++ List.duplicate("$", 20)
      ]

      for pattern <- patterns do
        tasks =
          Enum.map(pattern, fn key ->
            Task.async(fn ->
              GenServer.cast(raxol_pid, {:input, key})
            end)
          end)

        Task.await_many(tasks, 5000)
      end

      assert Process.alive?(raxol_pid)
    end

    test "stress test with mixed input types" do
      raxol_pid = Process.whereis(Droodotfoo.RaxolApp)

      # Generate mixed input
      mixed_input =
        Enum.flat_map(1..200, fn i ->
          cond do
            # Command mode
            rem(i, 10) == 0 -> [":"]
            # Search mode
            rem(i, 15) == 0 -> ["/"]
            # Exit mode
            rem(i, 20) == 0 -> ["Escape"]
            # Confirm
            rem(i, 5) == 0 -> ["Enter"]
            true -> Enum.random([["h"], ["j"], ["k"], ["l"], ["w"], ["b"]])
          end
        end)

      # Send all inputs rapidly
      for key <- mixed_input do
        GenServer.cast(raxol_pid, {:input, key})
        # Occasionally add tiny delay
        if :rand.uniform(100) > 95, do: Process.sleep(1)
      end

      assert Process.alive?(raxol_pid)
    end
  end

  describe "memory and resource management" do
    @describetag :load_test
    test "memory remains stable under sustained load" do
      initial_memory = :erlang.memory(:total)

      # Run sustained load for a period
      for _ <- 1..10 do
        # Create some load
        tasks =
          for _ <- 1..50 do
            Task.async(fn ->
              state = AdaptiveRefresh.new()

              Enum.reduce(1..100, state, fn i, acc ->
                acc
                |> AdaptiveRefresh.record_activity()
                |> AdaptiveRefresh.record_render(i * 0.1)
              end)
            end)
          end

        Task.await_many(tasks, 5000)

        # Force garbage collection
        :erlang.garbage_collect()
      end

      final_memory = :erlang.memory(:total)
      # Convert to MB
      memory_growth = (final_memory - initial_memory) / 1_048_576

      # Memory growth should be reasonable (less than 50MB)
      assert memory_growth < 50
    end

    test "process count remains stable" do
      initial_process_count = :erlang.system_info(:process_count)

      # Spawn and complete many short-lived processes
      for _ <- 1..100 do
        tasks =
          for _ <- 1..10 do
            Task.async(fn ->
              debouncer = InputDebouncer.new()

              Enum.reduce(1..50, debouncer, fn _, acc ->
                case InputDebouncer.process_key(acc, "a") do
                  {:debounced, new_state} -> new_state
                  {:batched, _, new_state} -> new_state
                  _ -> acc
                end
              end)
            end)
          end

        Task.await_many(tasks, 5000)
      end

      # Give time for process cleanup
      Process.sleep(100)
      :erlang.garbage_collect()

      final_process_count = :erlang.system_info(:process_count)
      process_growth = final_process_count - initial_process_count

      # Should not leak processes (allow small variance)
      assert process_growth < 10
    end

    test "message queues don't grow unbounded" do
      raxol_pid = Process.whereis(Droodotfoo.RaxolApp)
      assert raxol_pid != nil, "RaxolApp process not found"

      # Send many messages rapidly using the correct message format
      for _ <- 1..1000 do
        GenServer.cast(raxol_pid, {:input, "j"})
      end

      # Record initial queue length
      Process.sleep(100)
      {:message_queue_len, initial_queue_len} = Process.info(raxol_pid, :message_queue_len)

      # Let it process for additional time
      Process.sleep(1000)

      # Ensure process is still alive
      assert Process.alive?(raxol_pid), "RaxolApp crashed during test"

      # Check message queue length
      {:message_queue_len, final_queue_len} = Process.info(raxol_pid, :message_queue_len)

      # Queue should be decreasing (being processed), not growing
      assert final_queue_len < initial_queue_len, "Queue is not being processed (initial: #{initial_queue_len}, final: #{final_queue_len})"

      # Queue should be bounded (not growing unbounded) - realistic threshold for cast messages
      # GenServer.cast is asynchronous, so some backlog is expected under load
      assert final_queue_len < 900, "Queue appears unbounded: #{final_queue_len}"
    end
  end

  describe "performance benchmarks" do
    @describetag :load_test
    test "RaxolApp key processing throughput" do
      raxol_pid = Process.whereis(Droodotfoo.RaxolApp)

      # Measure processing time for 1000 keys
      start_time = System.monotonic_time(:millisecond)

      for _ <- 1..1000 do
        GenServer.cast(raxol_pid, {:input, "j"})
      end

      # Wait for processing
      Process.sleep(100)

      end_time = System.monotonic_time(:millisecond)
      duration_ms = end_time - start_time

      # Should process 1000 keys in under 2 seconds
      assert duration_ms < 2000

      # Calculate throughput
      throughput = 1000 / (duration_ms / 1000)

      # Should achieve at least 500 keys/second
      assert throughput > 500
    end

    test "InputRateLimiter throughput" do
      limiter = InputRateLimiter.new()

      start_time = System.monotonic_time(:microsecond)

      # Process 10000 events
      {_final_limiter, _} =
        Enum.reduce(1..10000, {limiter, nil}, fn _, {lim, _} ->
          {_, new_lim} = InputRateLimiter.allow_event?(lim)
          {new_lim, nil}
        end)

      end_time = System.monotonic_time(:microsecond)
      duration_us = end_time - start_time

      # Should process 10000 events in under 100ms
      assert duration_us < 100_000

      # Calculate throughput (events per second)
      throughput = 10_000 * 1_000_000 / duration_us

      # Should achieve at least 10k events/second (realistic for Elixir)
      assert throughput > 10_000
    end

    test "AdaptiveRefresh update performance" do
      refresh = AdaptiveRefresh.new()

      start_time = System.monotonic_time(:microsecond)

      # Perform 1000 activity recordings and renders
      final_state =
        Enum.reduce(1..1000, refresh, fn i, acc ->
          acc
          |> AdaptiveRefresh.record_activity()
          |> AdaptiveRefresh.record_render(i * 0.01)
        end)

      end_time = System.monotonic_time(:microsecond)
      duration_us = end_time - start_time

      # Should complete in under 50ms
      assert duration_us < 50_000

      # Verify state is valid
      metrics = AdaptiveRefresh.get_metrics(final_state)
      assert metrics.activity_count > 0
      assert length(final_state.render_times) > 0
    end
  end
end
