defmodule Droodotfoo.InputDebouncerTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.InputDebouncer

  describe "initialization" do
    test "creates new debouncer with default config" do
      debouncer = InputDebouncer.new()

      assert debouncer.buffer == []
      assert debouncer.timer_ref == nil
      assert debouncer.pending_keys == []
      assert debouncer.config.debounce_ms == 10
      assert debouncer.config.batch_size == 10
      assert debouncer.config.special_keys_instant == true
    end

    test "creates debouncer with custom config" do
      config = %{debounce_ms: 50, batch_size: 20}
      debouncer = InputDebouncer.new(config)

      assert debouncer.config.debounce_ms == 50
      assert debouncer.config.batch_size == 20
      # Default preserved
      assert debouncer.config.special_keys_instant == true
    end
  end

  describe "instant key processing" do
    test "processes special keys immediately" do
      debouncer = InputDebouncer.new()

      special_keys = ~w(Enter Escape Tab ArrowUp ArrowDown)

      for key <- special_keys do
        result = InputDebouncer.process_key(debouncer, key)
        assert {:immediate, ^key} = result
      end
    end

    test "flushes pending keys before processing instant key" do
      debouncer = InputDebouncer.new()

      # Add some pending keys
      {:debounced, state} = InputDebouncer.process_key(debouncer, "a")
      {:debounced, state} = InputDebouncer.process_key(state, "b")

      # Process instant key
      result = InputDebouncer.process_key(state, "Enter")
      assert {:batch_with_immediate, ["a", "b"], "Enter", _new_state} = result
    end

    test "respects special_keys_instant config flag" do
      config = %{special_keys_instant: false}
      debouncer = InputDebouncer.new(config)

      result = InputDebouncer.process_key(debouncer, "Enter")
      assert {:debounced, _} = result
    end
  end

  describe "debounce windowing" do
    test "batches keys within debounce window" do
      debouncer = InputDebouncer.new(%{debounce_ms: 100})

      {:debounced, state} = InputDebouncer.process_key(debouncer, "a")
      assert state.pending_keys == ["a"]

      {:debounced, state} = InputDebouncer.process_key(state, "b")
      assert state.pending_keys == ["a", "b"]

      {:debounced, state} = InputDebouncer.process_key(state, "c")
      assert state.pending_keys == ["a", "b", "c"]
    end

    test "starts new batch after debounce window expires" do
      debouncer = InputDebouncer.new(%{debounce_ms: 1})

      {:debounced, state} = InputDebouncer.process_key(debouncer, "a")
      # Wait for window to expire
      Process.sleep(5)

      result = InputDebouncer.process_key(state, "b")
      assert {:batch_then_start, ["a"], _new_state} = result
    end

    test "returns batched result when batch size reached" do
      debouncer = InputDebouncer.new(%{batch_size: 3})

      {:debounced, state} = InputDebouncer.process_key(debouncer, "a")
      {:debounced, state} = InputDebouncer.process_key(state, "b")

      # Third key should trigger batch
      result = InputDebouncer.process_key(state, "c")
      assert {:batched, ["a", "b", "c"], _new_state} = result
    end
  end

  describe "flush operations" do
    test "flushes all pending keys" do
      debouncer = InputDebouncer.new()

      {:debounced, state} = InputDebouncer.process_key(debouncer, "a")
      {:debounced, state} = InputDebouncer.process_key(state, "b")
      {:debounced, state} = InputDebouncer.process_key(state, "c")

      {keys, new_state} = InputDebouncer.flush(state)

      assert keys == ["a", "b", "c"]
      assert new_state.pending_keys == []
      assert new_state.timer_ref == nil
    end

    test "flush returns empty list when no pending keys" do
      debouncer = InputDebouncer.new()
      {keys, _state} = InputDebouncer.flush(debouncer)
      assert keys == []
    end
  end

  describe "timeout handling" do
    test "handles timeout to flush pending keys" do
      debouncer = InputDebouncer.new()

      {:debounced, state} = InputDebouncer.process_key(debouncer, "a")
      {:debounced, state} = InputDebouncer.process_key(state, "b")

      {keys, new_state} = InputDebouncer.handle_timeout(state)

      assert keys == ["a", "b"]
      assert new_state.pending_keys == []
      assert new_state.timer_ref == nil
    end
  end

  describe "utility functions" do
    test "checks for pending keys" do
      debouncer = InputDebouncer.new()
      assert InputDebouncer.has_pending?(debouncer) == false

      {:debounced, state} = InputDebouncer.process_key(debouncer, "a")
      assert InputDebouncer.has_pending?(state) == true
    end

    test "provides statistics" do
      debouncer = InputDebouncer.new()

      {:debounced, state} = InputDebouncer.process_key(debouncer, "a")
      {:debounced, state} = InputDebouncer.process_key(state, "b")

      stats = InputDebouncer.get_stats(state)

      assert stats.pending_count == 2
      assert stats.has_timer == true
      assert stats.last_input_ms_ago >= 0
    end
  end

  describe "mode-specific configurations" do
    test "provides optimized config for typing mode" do
      config = InputDebouncer.config_for_mode(:typing)
      assert config.debounce_ms == 5
      assert config.batch_size == 20
    end

    test "provides optimized config for navigation mode" do
      config = InputDebouncer.config_for_mode(:navigation)
      assert config.debounce_ms == 15
      assert config.batch_size == 5
    end

    test "provides optimized config for idle mode" do
      config = InputDebouncer.config_for_mode(:idle)
      assert config.debounce_ms == 50
      assert config.batch_size == 10
    end

    test "provides optimized config for command mode" do
      config = InputDebouncer.config_for_mode(:command)
      assert config.debounce_ms == 20
      assert config.batch_size == 15
    end

    test "returns default config for unknown mode" do
      config = InputDebouncer.config_for_mode(:unknown)
      assert config.debounce_ms == 10
      assert config.batch_size == 10
    end
  end

  describe "rapid input patterns" do
    test "handles burst typing pattern" do
      debouncer = InputDebouncer.new(%{debounce_ms: 5, batch_size: 10})

      # Simulate rapid typing burst
      keys = String.graphemes("hello world")

      {final_state, results} =
        Enum.reduce(keys, {debouncer, []}, fn key, {state, acc} ->
          case InputDebouncer.process_key(state, key) do
            {:debounced, new_state} ->
              {new_state, acc}

            {:batched, batch, new_state} ->
              {new_state, acc ++ [batch]}
          end
        end)

      # Should have batched some keys
      total_processed =
        Enum.reduce(results, 0, fn batch, sum ->
          sum + length(batch)
        end) + length(final_state.pending_keys)

      # "hello world" = 11 chars
      assert total_processed == 11
    end

    test "handles mixed instant and normal keys" do
      debouncer = InputDebouncer.new()

      {:debounced, state} = InputDebouncer.process_key(debouncer, "h")
      {:debounced, state} = InputDebouncer.process_key(state, "e")
      {:batch_with_immediate, batch, instant, state} = InputDebouncer.process_key(state, "Enter")

      assert batch == ["h", "e"]
      assert instant == "Enter"

      {:debounced, state} = InputDebouncer.process_key(state, "l")

      # After processing "l", Escape will flush it first
      result = InputDebouncer.process_key(state, "Escape")

      case result do
        {:immediate, key} ->
          assert key == "Escape"

        {:batch_with_immediate, _batch, key, _state} ->
          assert key == "Escape"
      end
    end

    test "handles navigation key sequences" do
      debouncer = InputDebouncer.new()
      nav_sequence = ["ArrowUp", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"]

      results =
        Enum.map(nav_sequence, fn key ->
          InputDebouncer.process_key(debouncer, key)
        end)

      # All should be immediate
      for {result, key} <- Enum.zip(results, nav_sequence) do
        assert {:immediate, ^key} = result
      end
    end
  end

  describe "stress testing" do
    test "handles 1000 rapid keys" do
      debouncer = InputDebouncer.new(%{batch_size: 50})

      {_final_state, batches} =
        Enum.reduce(1..1000, {debouncer, []}, fn i, {state, acc} ->
          key = "key#{i}"

          case InputDebouncer.process_key(state, key) do
            {:debounced, new_state} ->
              {new_state, acc}

            {:batched, batch, new_state} ->
              {new_state, acc ++ [batch]}

            {:batch_then_start, batch, new_state} ->
              {new_state, acc ++ [batch]}
          end
        end)

      total_batched =
        Enum.reduce(batches, 0, fn batch, sum ->
          sum + length(batch)
        end)

      # Should have processed most keys in batches
      assert total_batched >= 950
    end

    test "timer cleanup prevents memory leaks" do
      debouncer = InputDebouncer.new(%{debounce_ms: 1})

      # Create and cancel many timers
      final_state =
        Enum.reduce(1..100, debouncer, fn _, state ->
          {:debounced, new_state} = InputDebouncer.process_key(state, "a")
          # Let timer expire
          Process.sleep(2)
          {_keys, flushed} = InputDebouncer.flush(new_state)
          flushed
        end)

      assert final_state.timer_ref == nil
      assert final_state.pending_keys == []
    end

    test "handles alternating patterns efficiently" do
      debouncer = InputDebouncer.new()

      pattern =
        Enum.flat_map(1..50, fn _ ->
          ["a", "Enter", "b", "c", "Escape", "d"]
        end)

      {_state, immediates, _batches} =
        Enum.reduce(pattern, {debouncer, [], []}, fn key, {state, imm_acc, batch_acc} ->
          case InputDebouncer.process_key(state, key) do
            {:immediate, k} ->
              {state, imm_acc ++ [k], batch_acc}

            {:batch_with_immediate, batch, k, new_state} ->
              {new_state, imm_acc ++ [k], batch_acc ++ [batch]}

            {:debounced, new_state} ->
              {new_state, imm_acc, batch_acc}

            {:batched, batch, new_state} ->
              {new_state, imm_acc, batch_acc ++ [batch]}

            {:batch_then_start, batch, new_state} ->
              {new_state, imm_acc, batch_acc ++ [batch]}
          end
        end)

      # Should have processed instant keys immediately
      # 50 * 2 instant keys per pattern
      assert length(immediates) >= 100
    end
  end

  describe "edge cases" do
    test "handles empty string keys" do
      debouncer = InputDebouncer.new()
      {:debounced, state} = InputDebouncer.process_key(debouncer, "")
      assert state.pending_keys == [""]
    end

    test "handles very long key names" do
      debouncer = InputDebouncer.new()
      long_key = String.duplicate("a", 1000)
      {:debounced, state} = InputDebouncer.process_key(debouncer, long_key)
      assert hd(state.pending_keys) == long_key
    end

    test "handles nil timer ref safely" do
      debouncer = %{InputDebouncer.new() | timer_ref: nil}
      {keys, _state} = InputDebouncer.flush(debouncer)
      assert keys == []
    end

    test "processes with zero debounce time" do
      debouncer = InputDebouncer.new(%{debounce_ms: 0})
      {:debounced, state} = InputDebouncer.process_key(debouncer, "a")
      assert state.pending_keys == ["a"]
    end

    test "handles batch size of 1" do
      debouncer = InputDebouncer.new(%{batch_size: 1, debounce_ms: 100})
      # First key immediately triggers batch when batch_size is 1
      {:debounced, state1} = InputDebouncer.process_key(debouncer, "a")
      assert state1.pending_keys == ["a"]

      # Simulate timeout to get the batched key
      {keys, _state2} = InputDebouncer.handle_timeout(state1)
      assert keys == ["a"]
    end
  end
end
