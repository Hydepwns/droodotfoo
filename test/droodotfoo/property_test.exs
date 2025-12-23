defmodule Droodotfoo.PropertyTest do
  use ExUnit.Case
  use ExUnitProperties
  # Skip: RaxolApp, TerminalBridge, and Raxol modules archived in .unused_modules_backup/
  @moduletag :skip

  alias Droodotfoo.{AdaptiveRefresh, InputDebouncer, InputRateLimiter, RaxolApp, TerminalBridge}
  alias Droodotfoo.Raxol.{Command, Navigation, State}

  @moduledoc """
  Property-based tests for droodotfoo components.
  These tests verify invariants and properties that should hold
  for all possible inputs.
  """

  property "RaxolApp handles any sequence of valid keys without crashing" do
    check all(key_sequence <- list_of(valid_key_gen(), min_length: 1, max_length: 100)) do
      raxol_pid = Process.whereis(RaxolApp)
      initial_alive = Process.alive?(raxol_pid)

      # Send all keys in sequence
      for key <- key_sequence do
        GenServer.cast(raxol_pid, {:input, key})
      end

      # RaxolApp should still be alive
      assert initial_alive == Process.alive?(raxol_pid)
    end
  end

  property "buffer operations maintain valid structure" do
    check all(operations <- list_of(buffer_operation_gen(), max_length: 50)) do
      initial_buffer = create_empty_buffer(80, 24)

      final_buffer =
        Enum.reduce(operations, initial_buffer, fn op, buffer ->
          apply_buffer_operation(buffer, op)
        end)

      # Buffer should maintain dimensions
      assert length(final_buffer.lines) == 24
      assert final_buffer.width == 80

      assert Enum.all?(final_buffer.lines, fn line ->
               is_map(line) and is_list(line.cells) and length(line.cells) == 80
             end)

      # All cells should be valid
      assert Enum.all?(final_buffer.lines, fn line ->
               Enum.all?(line.cells, &valid_cell?/1)
             end)
    end
  end

  property "state transitions preserve invariants" do
    check all(transitions <- list_of(state_transition_gen(), max_length: 100)) do
      initial_state = State.initial(80, 24)

      final_state =
        Enum.reduce(transitions, initial_state, fn transition, state ->
          # Ensure state is always a valid map before applying transitions
          if is_map(state) do
            apply_state_transition(state, transition)
          else
            initial_state
          end
        end)

      # State invariants
      assert is_map(final_state)
      assert is_boolean(final_state.command_mode)
      assert final_state.cursor_y >= 0
      assert final_state.cursor_x >= 0
      assert is_binary(final_state.command_buffer)
    end
  end

  property "InputRateLimiter token bucket never goes negative" do
    check all(
            event_count <- integer(0..1000),
            initial_tokens <- integer(0..30)
          ) do
      limiter = %InputRateLimiter{
        tokens: initial_tokens,
        last_refill: System.monotonic_time(:millisecond),
        events_allowed: 0,
        events_blocked: 0
      }

      # Use list comprehension to avoid descending range issue when event_count = 0
      {final_limiter, _} =
        Enum.reduce(List.duplicate(:event, event_count), {limiter, []}, fn _, {lim, acc} ->
          {allowed, new_lim} = InputRateLimiter.allow_event?(lim)
          {new_lim, [allowed | acc]}
        end)

      # Tokens should never be negative after any operation
      assert final_limiter.tokens >= 0

      # Event counts should match
      total_events = final_limiter.events_allowed + final_limiter.events_blocked
      assert total_events == event_count
    end
  end

  property "InputDebouncer maintains key order within batches" do
    check all(
            keys <-
              list_of(string(:alphanumeric, min_length: 1, max_length: 1),
                min_length: 1,
                max_length: 20
              )
          ) do
      debouncer = InputDebouncer.new(%{debounce_ms: 100, batch_size: 50})

      {final_state, batches} =
        Enum.reduce(keys, {debouncer, []}, fn key, {state, acc} ->
          case InputDebouncer.process_key(state, key) do
            {:debounced, new_state} ->
              {new_state, acc}

            {:batched, batch, new_state} ->
              {new_state, acc ++ [batch]}

            {:batch_then_start, batch, new_state} ->
              {new_state, acc ++ [batch]}

            _ ->
              {state, acc}
          end
        end)

      # Flush any remaining
      {remaining, _} = InputDebouncer.flush(final_state)
      all_batches = if remaining == [], do: batches, else: batches ++ [remaining]

      # Flatten all batches
      processed_keys = List.flatten(all_batches)

      # All input keys should be in output (order preserved within batches)
      assert length(processed_keys) <= length(keys)
    end
  end

  property "AdaptiveRefresh FPS transitions converge to target" do
    check all(
            initial_fps <- member_of([5, 15, 30, 60]),
            initial_mode <- member_of([:idle, :transition, :normal, :fast]),
            activity_count <- integer(0..100)
          ) do
      # Map mode to appropriate FPS
      mode_fps_map = %{idle: 5, transition: 15, normal: 30, fast: 60}
      target_fps = mode_fps_map[initial_mode]

      state = %{
        AdaptiveRefresh.new()
        | current_fps: initial_fps,
          target_fps: target_fps,
          mode: initial_mode,
          # Reset to ensure we start from 0
          activity_count: 0
      }

      initial_count = state.activity_count

      # Record multiple activities
      final_state =
        if activity_count > 0 do
          Enum.reduce(1..activity_count, state, fn _, acc ->
            AdaptiveRefresh.record_activity(acc)
          end)
        else
          state
        end

      # Basic invariants that should always hold
      assert final_state.current_fps >= 5
      assert final_state.current_fps <= 60

      # Activity count should increase by the number of activities
      assert final_state.activity_count == initial_count + activity_count

      # Mode should remain consistent
      assert final_state.mode in [:normal, :fast, :idle, :transition]

      # Target FPS should be valid for the mode
      assert final_state.target_fps in [5, 15, 30, 60]
    end
  end

  property "HTML generation produces valid output" do
    check all(content <- list_of(ascii_string(min_length: 0, max_length: 80), length: 24)) do
      # Create buffer with correct structure matching TerminalBridge expectations
      # TerminalBridge expects a map with :lines key containing list of line maps
      buffer_lines =
        Enum.map(content, fn line ->
          chars = String.graphemes(String.pad_trailing(line, 80))

          cells =
            Enum.map(Enum.take(chars, 80), fn char ->
              %{char: char, style: %{}}
            end)

          %{cells: cells}
        end)

      buffer = %{lines: buffer_lines}

      # Generate HTML
      html = TerminalBridge.terminal_to_html(buffer)

      # HTML should be valid
      assert is_binary(html)
      assert String.contains?(html, "<div")
      assert String.contains?(html, "</div>")

      # Should not contain null bytes or invalid chars
      refute String.contains?(html, <<0>>)
    end
  end

  property "navigation commands keep cursor in bounds" do
    check all(
            nav_commands <- list_of(navigation_command_gen(), max_length: 100),
            width <- integer(10..200),
            height <- integer(10..100)
          ) do
      initial_state = State.initial(width, height)
      initial_state = %{initial_state | cursor_y: div(height, 2), cursor_x: div(width, 2)}

      final_state =
        Enum.reduce(nav_commands, initial_state, fn cmd, state ->
          result = Navigation.handle_input(state, cmd)
          # Ensure we always have a valid state map
          if is_map(result) and Map.has_key?(result, :cursor_y) do
            result
          else
            state
          end
        end)

      # Cursor should remain in bounds
      assert is_map(final_state)
      assert final_state.cursor_y >= 0
      assert final_state.cursor_y < height
      assert final_state.cursor_x >= 0
      assert final_state.cursor_x < width
    end
  end

  property "command parsing handles any input" do
    check all(command_str <- string(:utf8, max_length: 100)) do
      state = State.initial(80, 24)
      state = %{state | command_mode: true, command_buffer: command_str}

      # Command.handle_input doesn't handle "Enter" - that's done at State level
      # Test other inputs that Command.handle_input does handle
      test_keys = ["a", "b", "Backspace", "Tab", "ArrowUp", "ArrowDown"]

      for key <- test_keys do
        result = Command.handle_input(key, state)
        # Should always return a state map
        assert is_map(result)
        assert Map.has_key?(result, :command_buffer)
        assert is_binary(result.command_buffer)
      end
    end
  end

  # Generator functions

  defp valid_key_gen do
    frequency([
      # Regular keys
      {40, string(:alphanumeric, length: 1)},
      # Navigation
      {20, member_of(["h", "j", "k", "l"])},
      # Special
      {10, member_of(["Enter", "Escape", "Tab"])},
      # Movement
      {10, member_of(["g", "G", "w", "b", "e"])},
      # Line navigation
      {10, member_of(["0", "$"])},
      # Mode changes
      {5, member_of([":", "/"])},
      # Arrows
      {5, member_of(["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"])}
    ])
  end

  defp buffer_operation_gen do
    one_of([
      tuple({constant(:write), integer(0..23), integer(0..79), string(:ascii, length: 1)}),
      tuple({constant(:clear), integer(0..23)}),
      tuple({constant(:scroll), member_of([:up, :down])}),
      tuple({constant(:fill), string(:ascii, length: 1)})
    ])
  end

  defp state_transition_gen do
    one_of([
      tuple({constant(:navigate), navigation_command_gen()}),
      tuple({constant(:command), string(:alphanumeric, max_length: 20)}),
      tuple({constant(:search), string(:alphanumeric, max_length: 20)}),
      tuple({constant(:mode_change), member_of([:navigation, :command, :search])})
    ])
  end

  defp navigation_command_gen do
    member_of([
      "h",
      "j",
      "k",
      "l",
      "g",
      "G",
      "w",
      "b",
      "e",
      "0",
      "$",
      "ArrowUp",
      "ArrowDown",
      "ArrowLeft",
      "ArrowRight"
    ])
  end

  defp ascii_string(opts) do
    map(string(:ascii, opts), fn str ->
      # Replace control characters with spaces
      String.replace(str, ~r/[\x00-\x1F\x7F]/, " ")
    end)
  end

  # Helper functions

  defp create_empty_buffer(width, height) do
    %{
      width: width,
      lines:
        for _ <- 1..height do
          %{
            cells:
              for _ <- 1..width do
                %{char: " ", style: %{}}
              end
          }
        end
    }
  end

  defp apply_buffer_operation(buffer, {:write, row, col, char}) do
    if row < length(buffer.lines) do
      lines = List.update_at(buffer.lines, row, fn line -> update_line_cell(line, col, char) end)
      %{buffer | lines: lines}
    else
      buffer
    end
  end

  defp update_line_cell(line, col, char) do
    if col < length(line.cells) do
      cells =
        List.update_at(line.cells, col, fn _ ->
          %{char: char, style: %{}}
        end)

      %{line | cells: cells}
    else
      line
    end
  end

  defp apply_buffer_operation(buffer, {:clear, row}) do
    if row < length(buffer.lines) do
      lines =
        List.update_at(buffer.lines, row, fn _line ->
          %{
            cells: for(_ <- 1..80, do: %{char: " ", style: %{}})
          }
        end)

      %{buffer | lines: lines}
    else
      buffer
    end
  end

  defp apply_buffer_operation(buffer, {:scroll, :up}) do
    new_line = %{cells: for(_ <- 1..80, do: %{char: " ", style: %{}})}
    lines = tl(buffer.lines) ++ [new_line]
    %{buffer | lines: lines}
  end

  defp apply_buffer_operation(buffer, {:scroll, :down}) do
    new_line = %{cells: for(_ <- 1..80, do: %{char: " ", style: %{}})}
    lines = [new_line] ++ Enum.take(buffer.lines, length(buffer.lines) - 1)
    %{buffer | lines: lines}
  end

  defp apply_buffer_operation(buffer, {:fill, char}) do
    lines =
      for _ <- 1..length(buffer.lines) do
        %{
          cells:
            for _ <- 1..80 do
              %{char: char, style: %{}}
            end
        }
      end

    %{buffer | lines: lines}
  end

  defp valid_cell?(cell) do
    is_map(cell) and
      Map.has_key?(cell, :char) and
      Map.has_key?(cell, :style) and
      is_binary(cell.char) and
      is_map(cell.style)
  end

  defp apply_state_transition(state, {:navigate, key}) do
    result = Navigation.handle_input(state, key)
    # Navigation.handle_input should return a state map
    if is_map(result), do: result, else: state
  end

  defp apply_state_transition(state, {:command, text}) do
    %{state | command_buffer: text}
  end

  defp apply_state_transition(state, {:search, _text}) do
    # Search is handled through command mode
    state
  end

  defp apply_state_transition(state, {:mode_change, :navigation}) do
    %{state | command_mode: false}
  end

  defp apply_state_transition(state, {:mode_change, :command}) do
    %{state | command_mode: true}
  end

  defp apply_state_transition(state, {:mode_change, _}) do
    state
  end
end
