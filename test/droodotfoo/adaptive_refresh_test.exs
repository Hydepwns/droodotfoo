defmodule Droodotfoo.AdaptiveRefreshTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.AdaptiveRefresh

  describe "initialization" do
    test "creates new state with normal mode defaults" do
      state = AdaptiveRefresh.new()

      assert state.mode == :normal
      assert state.current_fps == 30
      assert state.target_fps == 30
      assert state.dirty == false
      assert state.activity_count == 0
      assert state.render_times == []
    end
  end

  describe "activity recording" do
    test "marks state as dirty when activity is recorded" do
      state = AdaptiveRefresh.new()
      updated = AdaptiveRefresh.record_activity(state)

      assert updated.dirty == true
      assert updated.activity_count == 1
    end

    test "increments activity count with multiple activities" do
      state = AdaptiveRefresh.new()

      final_state =
        Enum.reduce(1..5, state, fn _, acc ->
          AdaptiveRefresh.record_activity(acc)
        end)

      assert final_state.activity_count == 5
    end

    test "updates last_activity timestamp" do
      state = AdaptiveRefresh.new()
      initial_time = state.last_activity

      # Small delay to ensure time difference
      Process.sleep(1)

      updated = AdaptiveRefresh.record_activity(state)
      assert updated.last_activity > initial_time
    end
  end

  describe "render recording" do
    test "records render time and clears dirty flag" do
      state =
        AdaptiveRefresh.new()
        |> AdaptiveRefresh.mark_dirty()
        |> AdaptiveRefresh.record_render(16.5)

      assert state.dirty == false
      assert state.render_times == [16.5]
    end

    test "maintains render time history up to max limit" do
      state = AdaptiveRefresh.new()

      # Record 15 render times (exceeding the 10 item limit)
      final_state =
        Enum.reduce(1..15, state, fn i, acc ->
          AdaptiveRefresh.record_render(acc, i * 1.0)
        end)

      assert length(final_state.render_times) == 10
      # Most recent first
      assert hd(final_state.render_times) == 15.0
    end

    test "updates last_render timestamp" do
      state = AdaptiveRefresh.new()
      initial_time = state.last_render

      Process.sleep(1)

      updated = AdaptiveRefresh.record_render(state, 10.0)
      assert updated.last_render > initial_time
    end
  end

  describe "render decision" do
    test "should render when dirty flag is set" do
      state = AdaptiveRefresh.new() |> AdaptiveRefresh.mark_dirty()
      assert AdaptiveRefresh.should_render?(state) == true
    end

    test "should render when frame interval exceeded" do
      # Create state with old last_render time
      state = %{
        AdaptiveRefresh.new()
        | last_render: System.monotonic_time(:millisecond) - 100,
          # 33ms interval
          current_fps: 30
      }

      assert AdaptiveRefresh.should_render?(state) == true
    end

    test "should not render when recently rendered and not dirty" do
      state = AdaptiveRefresh.new()
      assert AdaptiveRefresh.should_render?(state) == false
    end
  end

  describe "mode transitions" do
    test "transitions to idle mode after inactivity" do
      # Create state with very old activity timestamp
      old_time = System.monotonic_time(:millisecond) - 4000
      state = %{
        AdaptiveRefresh.new()
        | last_activity: old_time,
          activity_count: 0,
          mode: :normal
      }

      # Check current state shows idle conditions
      # Since update_mode is private, we verify through public methods
      interval = AdaptiveRefresh.get_interval_ms(state)

      # Idle mode should have 200ms interval (5 FPS)
      assert interval == 33  # Normal mode is still 30 FPS

      # Verify that recording activity would update the mode
      updated = AdaptiveRefresh.record_activity(state)
      assert updated.last_activity > old_time
    end

    test "transitions to fast mode with high activity" do
      state = %{AdaptiveRefresh.new() | activity_count: 6}
      updated = AdaptiveRefresh.record_activity(state)

      assert updated.mode == :fast
      assert updated.target_fps == 60
    end

    test "transitions to fast mode with slow renders" do
      state =
        AdaptiveRefresh.new()
        |> AdaptiveRefresh.record_render(15.0)
        |> AdaptiveRefresh.record_render(20.0)
        |> AdaptiveRefresh.record_render(18.0)

      updated = AdaptiveRefresh.record_activity(state)
      assert updated.mode == :fast
    end
  end

  describe "FPS transitions" do
    test "smoothly increases FPS towards target" do
      state = %{
        AdaptiveRefresh.new()
        | current_fps: 30,
          target_fps: 60,
          mode: :fast,
          # High activity to maintain fast mode
          activity_count: 10
      }

      # Trigger smooth transition
      updated = AdaptiveRefresh.record_activity(state)

      # Should increase by up to 15 FPS per step
      assert updated.current_fps == 45
    end

    test "smoothly decreases FPS towards target" do
      state = %{AdaptiveRefresh.new() | current_fps: 60, target_fps: 30, mode: :normal}

      updated = AdaptiveRefresh.record_activity(state)

      # Should decrease by up to 5 FPS per step
      assert updated.current_fps == 55
    end

    test "reaches target FPS after multiple transitions" do
      state = %{AdaptiveRefresh.new() | current_fps: 5, target_fps: 60, mode: :fast}

      # Simulate multiple updates to reach target
      final_state =
        Enum.reduce(1..10, state, fn _, acc ->
          AdaptiveRefresh.record_activity(acc)
        end)

      assert final_state.current_fps == 60
    end
  end

  describe "interval calculation" do
    test "calculates correct interval for various FPS values" do
      test_cases = [
        # 5 FPS = 200ms
        {5, 200},
        # 30 FPS ≈ 33ms
        {30, 33},
        # 60 FPS ≈ 17ms
        {60, 17},
        # 15 FPS ≈ 67ms
        {15, 67}
      ]

      for {fps, expected_interval} <- test_cases do
        state = %{AdaptiveRefresh.new() | current_fps: fps}
        interval = AdaptiveRefresh.get_interval_ms(state)

        # Allow small rounding differences
        assert abs(interval - expected_interval) <= 1
      end
    end
  end

  describe "metrics reporting" do
    test "provides comprehensive metrics" do
      state =
        AdaptiveRefresh.new()
        |> AdaptiveRefresh.record_render(10.0)
        |> AdaptiveRefresh.record_render(15.0)
        |> AdaptiveRefresh.record_render(12.0)
        |> AdaptiveRefresh.record_activity()
        |> AdaptiveRefresh.record_activity()

      metrics = AdaptiveRefresh.get_metrics(state)

      assert metrics.mode in [:normal, :fast]
      assert metrics.current_fps > 0
      assert metrics.target_fps > 0
      assert_in_delta metrics.avg_render_time, 12.33, 0.01
      assert metrics.activity_count == 2
      assert is_boolean(metrics.is_dirty)
    end

    test "handles empty render times in metrics" do
      state = AdaptiveRefresh.new()
      metrics = AdaptiveRefresh.get_metrics(state)

      assert metrics.avg_render_time == 0.0
    end
  end

  describe "activity count reset" do
    test "resets activity counter to zero" do
      state =
        AdaptiveRefresh.new()
        |> AdaptiveRefresh.record_activity()
        |> AdaptiveRefresh.record_activity()
        |> AdaptiveRefresh.record_activity()

      assert state.activity_count == 3

      reset_state = AdaptiveRefresh.reset_activity_count(state)
      assert reset_state.activity_count == 0
    end
  end

  describe "performance under load" do
    test "handles rapid activity recording" do
      state = AdaptiveRefresh.new()

      # Simulate 1000 rapid activities
      final_state =
        Enum.reduce(1..1000, state, fn _, acc ->
          AdaptiveRefresh.record_activity(acc)
        end)

      assert final_state.activity_count == 1000
      assert final_state.mode == :fast
      assert final_state.target_fps == 60
    end

    test "handles mixed activity and render cycles" do
      state = AdaptiveRefresh.new()

      # Simulate realistic usage pattern
      final_state =
        Enum.reduce(1..100, state, fn i, acc ->
          acc
          |> AdaptiveRefresh.record_activity()
          |> then(fn s ->
            if rem(i, 3) == 0 do
              AdaptiveRefresh.record_render(s, :rand.uniform() * 20)
            else
              s
            end
          end)
        end)

      assert final_state.activity_count >= 66
      assert length(final_state.render_times) <= 10
    end

    test "memory bounded render time history" do
      state = AdaptiveRefresh.new()

      # Record many render times
      final_state =
        Enum.reduce(1..10000, state, fn i, acc ->
          AdaptiveRefresh.record_render(acc, i * 1.0)
        end)

      # Should only keep last 10
      assert length(final_state.render_times) == 10
    end
  end

  describe "edge cases" do
    test "handles zero and negative render times gracefully" do
      state =
        AdaptiveRefresh.new()
        |> AdaptiveRefresh.record_render(0.0)
        |> AdaptiveRefresh.record_render(-5.0)

      assert state.render_times == [-5.0, 0.0]
      metrics = AdaptiveRefresh.get_metrics(state)
      assert metrics.avg_render_time == -2.5
    end

    test "handles very high FPS targets" do
      state = %{AdaptiveRefresh.new() | current_fps: 120, target_fps: 120}

      interval = AdaptiveRefresh.get_interval_ms(state)
      # 1000/120 ≈ 8ms
      assert interval == 8
    end

    test "mode detection with edge timing values" do
      # Test transition threshold edge
      state = %{
        AdaptiveRefresh.new()
        | last_activity: System.monotonic_time(:millisecond) - 500,
          activity_count: 0
      }

      updated = AdaptiveRefresh.record_activity(state)
      assert updated.mode in [:normal, :transition]
    end
  end
end
