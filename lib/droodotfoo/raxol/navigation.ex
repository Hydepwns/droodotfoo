defmodule Droodotfoo.Raxol.Navigation do
  @moduledoc """
  Handles navigation logic for the terminal UI.
  """

  alias Droodotfoo.CursorTrail
  alias Droodotfoo.Raxol.State

  @doc """
  Handles navigation-related input when not in command mode.
  Returns updated state with new cursor position.
  """

  # Arrow key navigation (primary for normal users)
  def handle_input("ArrowDown", state) do
    if state.current_section == :projects and not state.project_detail_view do
      move_project_down(state)
    else
      move_down(state)
    end
  end

  def handle_input("ArrowUp", state) do
    if state.current_section == :projects and not state.project_detail_view do
      move_project_up(state)
    else
      move_up(state)
    end
  end

  def handle_input("ArrowRight", state), do: move_down(state)
  def handle_input("ArrowLeft", state), do: move_up(state)

  # Vim navigation (requires vim_mode enabled)
  # Special handling for STL viewer controls
  def handle_input("j", state) do
    cond do
      state.current_section == :stl_viewer ->
        # Mark for STL viewer rotation (handled by LiveView)
        Map.put(state, :stl_viewer_action, {:rotate, :down})

      State.vim_mode?(state) ->
        move_down(state)

      true ->
        state
    end
  end

  def handle_input("k", state) do
    cond do
      state.current_section == :stl_viewer ->
        Map.put(state, :stl_viewer_action, {:rotate, :up})

      State.vim_mode?(state) ->
        move_up(state)

      true ->
        state
    end
  end

  def handle_input("h", state) do
    cond do
      state.current_section == :stl_viewer ->
        Map.put(state, :stl_viewer_action, {:zoom, :out})

      State.vim_mode?(state) ->
        move_up(state)

      true ->
        state
    end
  end

  def handle_input("l", state) do
    cond do
      state.current_section == :stl_viewer ->
        Map.put(state, :stl_viewer_action, {:zoom, :in})

      State.vim_mode?(state) ->
        move_down(state)

      true ->
        state
    end
  end

  # STL Viewer specific controls
  def handle_input("r", state) do
    cond do
      state.current_section == :spotify ->
        # Refresh Spotify data
        Map.put(state, :spotify_action, :refresh)

      state.current_section == :stl_viewer ->
        Map.put(state, :stl_viewer_action, {:reset, nil})

      true ->
        state
    end
  end

  def handle_input("m", state) do
    cond do
      state.current_section == :spotify ->
        # Toggle compact mode
        %{state | spotify_compact_mode: !state.spotify_compact_mode}

      state.current_section == :stl_viewer ->
        Map.put(state, :stl_viewer_action, {:cycle_mode, nil})

      true ->
        state
    end
  end

  def handle_input("q", state) do
    if state.current_section == :stl_viewer do
      # Exit viewer, return to home
      %{state | current_section: :home}
    else
      state
    end
  end

  # Spotify specific controls
  def handle_input("a", state) do
    if state.current_section == :spotify do
      Map.put(state, :spotify_action, :start_auth)
    else
      state
    end
  end

  # Escape key - return to dashboard from Spotify sub-modes
  def handle_input("Escape", state) do
    if state.current_section == :spotify and state.spotify_mode != :dashboard do
      %{state | spotify_mode: :dashboard}
    else
      state
    end
  end

  def handle_input("p", state) do
    if state.current_section == :spotify do
      %{state | spotify_mode: :playlists}
    else
      state
    end
  end

  def handle_input("d", state) do
    if state.current_section == :spotify do
      %{state | spotify_mode: :devices}
    else
      state
    end
  end

  def handle_input("s", state) do
    if state.current_section == :spotify do
      %{state | spotify_mode: :search}
    else
      state
    end
  end

  def handle_input("c", state) do
    if state.current_section == :spotify do
      %{state | spotify_mode: :controls}
    else
      state
    end
  end

  # Spotify playback controls
  def handle_input(" ", state) do
    if state.current_section == :spotify do
      Map.put(state, :spotify_action, :play_pause)
    else
      state
    end
  end

  def handle_input("]", state) do
    if state.current_section == :spotify do
      Map.put(state, :spotify_action, :next_track)
    else
      state
    end
  end

  def handle_input("[", state) do
    if state.current_section == :spotify do
      Map.put(state, :spotify_action, :previous_track)
    else
      state
    end
  end

  def handle_input("=", state) do
    if state.current_section == :spotify do
      Map.put(state, :spotify_action, :volume_up)
    else
      state
    end
  end

  def handle_input("-", state) do
    if state.current_section == :spotify do
      Map.put(state, :spotify_action, :volume_down)
    else
      state
    end
  end

  def handle_input("g", state) do
    if State.vim_mode?(state) do
      # Go to top
      trail = update_trail_if_enabled(state, 0)
      %{state | cursor_y: 0, cursor_trail: trail}
    else
      state
    end
  end

  def handle_input("G", state) do
    if State.vim_mode?(state) do
      # Go to bottom
      max_y = length(state.navigation_items) - 1
      trail = update_trail_if_enabled(state, max_y)
      %{state | cursor_y: max_y, cursor_trail: trail}
    else
      state
    end
  end

  def handle_input("Enter", state) do
    if state.current_section == :projects and not state.project_detail_view do
      # Enter detail view for selected project
      %{state | project_detail_view: true}
    else
      # Select current item
      selected = Enum.at(state.navigation_items, state.cursor_y)
      %{state | current_section: selected}
    end
  end

  # Backspace to return from project detail view
  def handle_input("Backspace", state) do
    if state.current_section == :projects and state.project_detail_view do
      %{state | project_detail_view: false}
    else
      state
    end
  end

  # Handle direct cursor positioning (for mouse clicks)
  def handle_input("cursor_set:" <> idx_str, state) do
    case Integer.parse(idx_str) do
      {idx, ""} when idx >= 0 and idx < length(state.navigation_items) ->
        trail = update_trail_if_enabled(state, idx)
        %{state | cursor_y: idx, cursor_trail: trail}

      _ ->
        state
    end
  end

  # Number key shortcuts (1-8) - jump to menu item and select
  def handle_input("1", state), do: jump_to_and_select(state, 0)
  def handle_input("2", state), do: jump_to_and_select(state, 1)
  def handle_input("3", state), do: jump_to_and_select(state, 2)
  def handle_input("4", state), do: jump_to_and_select(state, 3)
  def handle_input("5", state), do: jump_to_and_select(state, 4)
  def handle_input("6", state), do: jump_to_and_select(state, 5)
  def handle_input("7", state), do: jump_to_and_select(state, 6)
  def handle_input("8", state), do: jump_to_and_select(state, 7)

  # Toggle vim mode with 'v' key
  def handle_input("v", state) do
    %{state | vim_mode: !state.vim_mode}
  end

  def handle_input("V", state) do
    # Same as 'v' - toggle vim mode
    %{state | vim_mode: !state.vim_mode}
  end

  # Set vim mode directly (for persistence from localStorage)
  def handle_input("set_vim_on", state) do
    %{state | vim_mode: true}
  end

  def handle_input("set_vim_off", state) do
    %{state | vim_mode: false}
  end

  # Restore section from localStorage
  def handle_input("restore_section:" <> section_str, state) do
    try do
      section_atom = String.to_existing_atom(section_str)

      if section_atom in state.navigation_items or section_atom in [:terminal, :search_results, :performance, :matrix, :ssh, :analytics, :help, :spotify] do
        %{state | current_section: section_atom}
      else
        state
      end
    rescue
      _ -> state
    end
  end

  # Search navigation - next match with 'n'
  # Also used for Spotify next track
  def handle_input("n", state) do
    cond do
      state.current_section == :search_results ->
        updated_search = Droodotfoo.AdvancedSearch.next_match(state.search_state)
        %{state | search_state: updated_search}

      state.current_section == :spotify ->
        Map.put(state, :spotify_action, :next_track)

      true ->
        state
    end
  end

  # 'b' for Spotify previous track (back)
  def handle_input("b", state) do
    if state.current_section == :spotify do
      Map.put(state, :spotify_action, :previous_track)
    else
      state
    end
  end

  # Search navigation - previous match with 'N'
  def handle_input("N", state) do
    if state.current_section == :search_results do
      updated_search = Droodotfoo.AdvancedSearch.previous_match(state.search_state)
      %{state | search_state: updated_search}
    else
      state
    end
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

  defp jump_to_and_select(state, idx) do
    if idx >= 0 and idx < length(state.navigation_items) do
      selected = Enum.at(state.navigation_items, idx)
      trail = update_trail_if_enabled(state, idx)
      %{state | cursor_y: idx, current_section: selected, cursor_trail: trail}
    else
      state
    end
  end

  # Movement helper functions
  defp move_down(state) do
    max_y = length(state.navigation_items) - 1
    new_y = min(state.cursor_y + 1, max_y)
    trail = update_trail_if_enabled(state, new_y)
    %{state | cursor_y: new_y, cursor_trail: trail}
  end

  defp move_up(state) do
    new_y = max(state.cursor_y - 1, 0)
    trail = update_trail_if_enabled(state, new_y)
    %{state | cursor_y: new_y, cursor_trail: trail}
  end

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
    # Navigation box starts at row 13, items start at row 15 (13 + 2)
    base_row = 15
    # 1 row between items (they're consecutive now)
    row = base_row + cursor_y
    # Fixed column for navigation cursor (column 2 is where cursor displays)
    col = 2
    {row, col}
  end

  # Project-specific navigation helpers
  defp move_project_down(state) do
    project_count = Droodotfoo.Projects.count()
    new_idx = min((state.selected_project_index || 0) + 1, project_count - 1)
    %{state | selected_project_index: new_idx}
  end

  defp move_project_up(state) do
    new_idx = max((state.selected_project_index || 0) - 1, 0)
    %{state | selected_project_index: new_idx}
  end
end
