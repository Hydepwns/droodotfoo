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
  # Special handling for STL viewer controls and scrollable content
  def handle_input("j", state) do
    require Logger

    cond do
      state.current_section == :stl_viewer ->
        # Mark for STL viewer rotation (handled by LiveView)
        Map.put(state, :stl_viewer_action, {:rotate, :down})

      scrollable_section?(state.current_section) and State.vim_mode?(state) ->
        # Scroll content down by dynamic amount
        delta = calculate_scroll_delta(state, :line)

        Logger.debug(
          "j key - scrolling down, section: #{state.current_section}, delta: #{delta}, vim_mode: #{State.vim_mode?(state)}"
        )

        State.scroll_content(state, delta)

      State.vim_mode?(state) ->
        Logger.debug("j key - move_down (vim mode but not scrollable section)")
        move_down(state)

      true ->
        Logger.debug("j key - no action (not vim mode)")
        state
    end
  end

  def handle_input("k", state) do
    cond do
      state.current_section == :stl_viewer ->
        Map.put(state, :stl_viewer_action, {:rotate, :up})

      scrollable_section?(state.current_section) and State.vim_mode?(state) ->
        # Scroll content up by dynamic amount
        delta = calculate_scroll_delta(state, :line)
        State.scroll_content(state, -delta)

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
    if state.current_section == :stl_viewer do
      Map.put(state, :stl_viewer_action, {:reset, nil})
    else
      state
    end
  end

  def handle_input("m", state) do
    if state.current_section == :stl_viewer do
      Map.put(state, :stl_viewer_action, {:cycle_mode, nil})
    else
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

  def handle_input("g", state) do
    cond do
      scrollable_section?(state.current_section) and State.vim_mode?(state) ->
        # Scroll to top of content
        State.set_scroll_offset(state, 0)

      State.vim_mode?(state) ->
        # Go to top of navigation
        trail = update_trail_if_enabled(state, 0)
        %{state | cursor_y: 0, cursor_trail: trail}

      true ->
        state
    end
  end

  # PageDown - scroll content down by viewport height
  def handle_input("PageDown", state) do
    if scrollable_section?(state.current_section) do
      delta = calculate_scroll_delta(state, :page)
      State.scroll_content(state, delta)
    else
      state
    end
  end

  # PageUp - scroll content up by viewport height
  def handle_input("PageUp", state) do
    if scrollable_section?(state.current_section) do
      delta = calculate_scroll_delta(state, :page)
      State.scroll_content(state, -delta)
    else
      state
    end
  end

  # Vim-style half-page scroll down
  def handle_input("d", state) do
    if scrollable_section?(state.current_section) and State.vim_mode?(state) do
      delta = calculate_scroll_delta(state, :half_page)
      State.scroll_content(state, delta)
    else
      state
    end
  end

  # Vim-style half-page scroll up
  def handle_input("u", state) do
    if scrollable_section?(state.current_section) and State.vim_mode?(state) do
      delta = calculate_scroll_delta(state, :half_page)
      State.scroll_content(state, -delta)
    else
      state
    end
  end

  def handle_input("G", state) do
    cond do
      scrollable_section?(state.current_section) and State.vim_mode?(state) ->
        # Scroll to bottom of content
        viewport_height = State.get_viewport_height(state)
        max_scroll = max(0, state.content_height - viewport_height)
        State.set_scroll_offset(state, max_scroll)

      State.vim_mode?(state) ->
        # Go to bottom of navigation
        max_y = length(state.navigation_items) - 1
        trail = update_trail_if_enabled(state, max_y)
        %{state | cursor_y: max_y, cursor_trail: trail}

      true ->
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

  # Number key shortcuts (1-6) - jump to menu item and select
  def handle_input("1", state), do: jump_to_and_select(state, 0)
  def handle_input("2", state), do: jump_to_and_select(state, 1)
  def handle_input("3", state), do: jump_to_and_select(state, 2)
  def handle_input("4", state), do: jump_to_and_select(state, 3)
  def handle_input("5", state), do: jump_to_and_select(state, 4)
  def handle_input("6", state), do: jump_to_and_select(state, 5)

  # Toggle vim mode with 'v' key
  def handle_input("v", state) do
    %{state | vim_mode: !state.vim_mode}
  end

  def handle_input("V", state) do
    # Same as 'v' - toggle vim mode (capital V always toggles vim mode)
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
    section_atom = String.to_existing_atom(section_str)

    if section_atom in state.navigation_items or
         section_atom in [
           :terminal,
           :search_results,
           :performance,
           :matrix,
           :ssh,
           :analytics,
           :help
         ] do
      %{state | current_section: section_atom}
    else
      state
    end
  rescue
    _ -> state
  end

  # Search navigation - next match with 'n'
  def handle_input("n", state) do
    if state.current_section == :search_results do
      updated_search = Droodotfoo.AdvancedSearch.next_match(state.search_state)
      %{state | search_state: updated_search}
    else
      state
    end
  end

  def handle_input("b", state), do: state

  # Search navigation - previous match with 'N'
  def handle_input("N", state) do
    if state.current_section == :search_results do
      updated_search = Droodotfoo.AdvancedSearch.previous_match(state.search_state)
      %{state | search_state: updated_search}
    else
      state
    end
  end

  # Trail toggle removed to avoid conflict with command typing
  # Cursor trail is still active but cannot be toggled via 't' key
  # This prevents 't' from interfering when typing commands like ':tetris'

  # Clear trail with 'T' key (kept for manual clearing if needed)
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

  # Helper to identify sections with scrollable content
  defp scrollable_section?(:experience), do: true
  defp scrollable_section?(:projects), do: true
  defp scrollable_section?(:contact), do: true
  defp scrollable_section?(:web3), do: true
  defp scrollable_section?(:games), do: true
  defp scrollable_section?(:home), do: true
  defp scrollable_section?(:performance), do: true
  defp scrollable_section?(:help), do: true
  defp scrollable_section?(_), do: false

  # Calculate dynamic scroll delta based on viewport height
  # Uses adaptive minimums that scale with viewport size for better UX
  defp calculate_scroll_delta(state, type) do
    viewport = State.get_viewport_height(state)

    case type do
      :page ->
        # PageDown/PageUp: scroll 100% of viewport
        # Adaptive minimum: 25% of viewport or 3 lines (whichever is higher)
        # This prevents jumpy scrolling on small screens
        adaptive_min = max(3, div(viewport, 4))
        max(adaptive_min, viewport)

      :half_page ->
        # Vim d/u: scroll 50% of viewport
        # Adaptive minimum: 15% of viewport or 2 lines
        # Scales better from small to large screens
        adaptive_min = max(2, div(viewport, 6))
        max(adaptive_min, div(viewport, 2))

      :line ->
        # Vim j/k: scroll 10% of viewport
        # Adaptive maximum: 20% of viewport or 3 lines (whichever is higher)
        # Provides finer control on small screens, more speed on large screens
        delta = max(1, div(viewport, 10))
        adaptive_max = max(3, div(viewport, 5))
        min(delta, adaptive_max)
    end
  end
end
