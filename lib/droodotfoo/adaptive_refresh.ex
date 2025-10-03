defmodule Droodotfoo.AdaptiveRefresh do
  @moduledoc """
  Adaptive refresh rate system that adjusts frame rate based on activity.
  Reduces CPU usage during idle periods and increases responsiveness during interaction.
  """

  defstruct [
    :mode,
    :current_fps,
    :target_fps,
    :last_activity,
    :last_render,
    :dirty,
    :activity_count,
    :render_times
  ]

  # Refresh modes
  # 5 FPS when idle (200ms)
  @idle_fps 5
  # 30 FPS for normal interaction (33ms)
  @normal_fps 30
  # 60 FPS for active typing/animation (16ms)
  @fast_fps 60
  # 15 FPS during transitions (66ms)
  @transition_fps 15

  # Timing thresholds
  # Go idle after 3 seconds of no activity
  @idle_threshold_ms 3000
  # Transition mode after 500ms
  @transition_threshold_ms 500
  # Keep last 10 render times for averaging
  @max_render_history 10

  @doc """
  Initialize a new adaptive refresh state.
  """
  def new do
    %__MODULE__{
      mode: :normal,
      current_fps: @normal_fps,
      target_fps: @normal_fps,
      last_activity: System.monotonic_time(:millisecond),
      last_render: System.monotonic_time(:millisecond),
      dirty: false,
      activity_count: 0,
      render_times: []
    }
  end

  @doc """
  Record user activity (keyboard input, mouse movement, etc.)
  """
  def record_activity(state) do
    now = System.monotonic_time(:millisecond)

    %{state | last_activity: now, activity_count: state.activity_count + 1, dirty: true}
    |> update_mode()
  end

  @doc """
  Record render completion and timing.
  """
  def record_render(state, render_time_ms) do
    render_times =
      [render_time_ms | state.render_times]
      |> Enum.take(@max_render_history)

    %{
      state
      | last_render: System.monotonic_time(:millisecond),
        render_times: render_times,
        dirty: false
    }
  end

  @doc """
  Check if a render is needed based on current FPS target.
  """
  def should_render?(state) do
    now = System.monotonic_time(:millisecond)
    time_since_render = now - state.last_render
    frame_interval = 1000 / state.current_fps

    # Always render if dirty (content changed)
    state.dirty || time_since_render >= frame_interval
  end

  @doc """
  Get the current interval in milliseconds for timer.
  """
  def get_interval_ms(state) do
    round(1000 / state.current_fps)
  end

  @doc """
  Mark content as dirty (needs re-render).
  """
  def mark_dirty(state) do
    %{state | dirty: true}
  end

  @doc """
  Get performance metrics.
  """
  def get_metrics(state) do
    avg_render_time =
      case state.render_times do
        [] -> 0
        times -> Enum.sum(times) / length(times)
      end

    %{
      mode: state.mode,
      current_fps: state.current_fps,
      target_fps: state.target_fps,
      avg_render_time: safe_round(avg_render_time, 2),
      activity_count: state.activity_count,
      is_dirty: state.dirty
    }
  end

  # Private functions

  defp update_mode(state) do
    now = System.monotonic_time(:millisecond)
    time_since_activity = now - state.last_activity
    avg_render_time = calculate_avg_render_time(state)

    new_mode = determine_mode(time_since_activity, avg_render_time, state)

    if new_mode != state.mode do
      target_fps = fps_for_mode(new_mode)

      %{
        state
        | mode: new_mode,
          target_fps: target_fps,
          current_fps: smoothly_transition_fps(state.current_fps, target_fps)
      }
    else
      # Smoothly adjust FPS if not at target
      if state.current_fps != state.target_fps do
        %{state | current_fps: smoothly_transition_fps(state.current_fps, state.target_fps)}
      else
        state
      end
    end
  end

  defp determine_mode(time_since_activity, avg_render_time, state) do
    cond do
      # Go idle if no activity for threshold
      time_since_activity > @idle_threshold_ms ->
        :idle

      # Fast mode for rapid activity or complex renders
      state.activity_count > 5 || avg_render_time > 10 ->
        :fast

      # Transition mode for recent but not immediate activity
      time_since_activity > @transition_threshold_ms ->
        :transition

      # Normal mode for regular interaction
      true ->
        :normal
    end
  end

  defp fps_for_mode(mode) do
    case mode do
      :idle -> @idle_fps
      :transition -> @transition_fps
      :normal -> @normal_fps
      :fast -> @fast_fps
    end
  end

  defp smoothly_transition_fps(current, target) when current == target, do: current

  defp smoothly_transition_fps(current, target) when current < target do
    # Increase FPS quickly for responsiveness
    min(current + 15, target)
  end

  defp smoothly_transition_fps(current, target) when current > target do
    # Decrease FPS slowly to avoid jarring transitions
    max(current - 5, target)
  end

  defp calculate_avg_render_time(state) do
    case state.render_times do
      [] -> 0
      times -> Enum.sum(times) / length(times)
    end
  end

  defp safe_round(value, precision) when is_float(value) do
    Float.round(value, precision)
  end

  defp safe_round(value, _precision) when is_integer(value) do
    value * 1.0
  end

  defp safe_round(value, _precision), do: value

  @doc """
  Reset activity counter (call periodically to track activity rate).
  """
  def reset_activity_count(state) do
    %{state | activity_count: 0}
  end
end
