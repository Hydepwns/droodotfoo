defmodule Droodotfoo.Raxol.Navigation do
  @moduledoc """
  Handles navigation logic for the terminal UI.
  """

  alias Droodotfoo.CursorTrail

  @doc """
  Handles navigation-related input when not in command mode.
  Returns updated state with new cursor position.
  """
  def handle_input("j", state) do
    # Move cursor down
    max_y = length(state.navigation_items) - 1
    new_y = min(state.cursor_y + 1, max_y)

    # Update trail if enabled
    trail =
      if state.trail_enabled do
        calculate_cursor_position(state, new_y)
        |> then(&CursorTrail.add_position(state.cursor_trail, &1))
      else
        state.cursor_trail
      end

    %{state | cursor_y: new_y, cursor_trail: trail}
  end

  def handle_input("k", state) do
    # Move cursor up
    new_y = max(state.cursor_y - 1, 0)

    # Update trail if enabled
    trail =
      if state.trail_enabled do
        calculate_cursor_position(state, new_y)
        |> then(&CursorTrail.add_position(state.cursor_trail, &1))
      else
        state.cursor_trail
      end

    %{state | cursor_y: new_y, cursor_trail: trail}
  end

  def handle_input("h", state) do
    # Move to previous section (same as up)
    new_y = max(state.cursor_y - 1, 0)
    trail = update_trail_if_enabled(state, new_y)
    %{state | cursor_y: new_y, cursor_trail: trail}
  end

  def handle_input("l", state) do
    # Move to next section (same as down)
    max_y = length(state.navigation_items) - 1
    new_y = min(state.cursor_y + 1, max_y)
    trail = update_trail_if_enabled(state, new_y)
    %{state | cursor_y: new_y, cursor_trail: trail}
  end

  def handle_input("g", state) do
    # Go to top
    trail = update_trail_if_enabled(state, 0)
    %{state | cursor_y: 0, cursor_trail: trail}
  end

  def handle_input("G", state) do
    # Go to bottom
    max_y = length(state.navigation_items) - 1
    trail = update_trail_if_enabled(state, max_y)
    %{state | cursor_y: max_y, cursor_trail: trail}
  end

  def handle_input("Enter", state) do
    # Select current item
    selected = Enum.at(state.navigation_items, state.cursor_y)
    %{state | current_section: selected}
  end

  # Toggle trail with 't' key
  def handle_input("t", state) do
    trail =
      if state.trail_enabled do
        CursorTrail.clear_trail(state.cursor_trail)
      else
        state.cursor_trail
      end

    %{state | trail_enabled: !state.trail_enabled, cursor_trail: trail}
  end

  # Clear trail with 'T' key
  def handle_input("T", state) do
    %{state | cursor_trail: CursorTrail.clear_trail(state.cursor_trail)}
  end

  def handle_input(_key, state), do: state

  # Private helpers

  defp update_trail_if_enabled(state, new_y) do
    if state.trail_enabled do
      calculate_cursor_position(state, new_y)
      |> then(&CursorTrail.add_position(state.cursor_trail, &1))
    else
      state.cursor_trail
    end
  end

  defp calculate_cursor_position(_state, cursor_y) do
    # Calculate the actual terminal position for the cursor
    # Navigation items start at row 10 in the terminal
    base_row = 10
    # 2 rows between items
    row = base_row + cursor_y * 2
    # Fixed column for navigation cursor
    col = 5
    {row, col}
  end
end
