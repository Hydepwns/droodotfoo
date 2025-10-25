defmodule Droodotfoo.Raxol.Renderer do
  @moduledoc """
  Main renderer orchestration for the terminal UI.

  This module has been refactored into focused submodules:
  - Renderer.Helpers - Shared utility functions
  - Renderer.Games - Games menu and selection
  - Renderer.Web3 - Web3 wallet UI
  - Renderer.Portal - Portal P2P status displays
  - Renderer.Projects - Project showcase
  - Renderer.Content - Static content sections
  - Renderer.Home - Home section
  - Renderer.STL - STL viewer components
  """

  alias Droodotfoo.{CursorTrail, TerminalBridge}
  alias Droodotfoo.Raxol.{BoxConfig, ClickableRegions, Config, State}

  alias Droodotfoo.Raxol.Renderer.{
    Games,
    Helpers,
    Home,
    Portal,
    STL
  }

  @doc """
  Main render function that orchestrates all drawing operations.
  Returns a tuple of {buffer, clickable_regions, updated_state} for enhanced click handling
  and state updates (content_height tracking).
  """
  def render(state) do
    # Always use standard height - scrolling is handled via viewport windowing
    buffer_height = Config.height()

    buffer = TerminalBridge.create_blank_buffer(Config.width(), buffer_height)

    # Initialize clickable regions
    clickable_regions = ClickableRegions.new()

    # Build navigation and populate clickable regions
    {buffer, clickable_regions} = draw_navigation_with_regions(buffer, state, clickable_regions)

    # Draw content and add content-specific clickable regions
    {buffer, clickable_regions} =
      draw_content_with_regions(buffer, state.current_section, state, clickable_regions)

    # Add clickable region for command bar (click to focus)
    command_y = Config.command_line_y()

    clickable_regions =
      ClickableRegions.add_rect_region(
        clickable_regions,
        :command_bar_focus,
        :action,
        command_y,
        command_y,
        0,
        Config.width(),
        "focus_command_bar",
        %{description: "Click to focus command bar"}
      )

    # Continue with other rendering operations
    buffer =
      buffer
      |> draw_breadcrumb(state)
      |> draw_cursor_trail(state)
      |> Portal.draw_enhanced_ui(state)
      |> draw_status_bar(state)
      |> draw_command_line(state)
      |> draw_help_modal(state)

    # Calculate content height for scrollable sections
    content_height = calculate_content_height(state)

    {buffer, clickable_regions, content_height}
  end

  # Calculate total content height for current section
  defp calculate_content_height(state) do
    case state.current_section do
      :home ->
        # Calculate actual home content height
        posts = Home.get_posts()
        home_lines = Home.build_unified_home(posts)
        length(home_lines)

      :experience ->
        if state.resume_data && map_size(state.resume_data) > 0 do
          experience_items = Map.get(state.resume_data, :experience, [])
          # Estimate: each item is ~7-12 lines (position, company, achievements, tech)
          # Average of 10 lines per item
          length(experience_items) * 10
        else
          # Default experience height
          20
        end

      :projects ->
        # Project count * estimated rows per project
        project_count =
          try do
            Droodotfoo.Projects.count()
          rescue
            _ -> 6
          end

        project_count * 6

      :contact ->
        # Contact section has nested boxes for email, github, linkedin, etc
        # Approximately 25-30 lines
        30

      :web3 ->
        # Web3 section has wallet connection UI and ENS info
        20

      :games ->
        # Games section lists available games
        15

      :performance ->
        # Performance dashboard
        25

      :help ->
        # Help section with commands
        30

      _ ->
        # Non-scrollable section
        0
    end
  end

  # Core UI Functions

  defp draw_breadcrumb(buffer, state) do
    breadcrumb = format_breadcrumb(state.current_section)
    TerminalBridge.write_at(buffer, 2, 11, breadcrumb)
  end

  defp format_breadcrumb(:home), do: "Home"
  defp format_breadcrumb(:terminal), do: "Home > Terminal"

  defp format_breadcrumb(section) do
    section_name = section |> Atom.to_string() |> String.capitalize()
    "Home > #{section_name}"
  end

  # New function that draws navigation and populates clickable regions
  defp draw_navigation_with_regions(buffer, state, clickable_regions) do
    nav_y = 13
    cursor_y = state.cursor_y

    nav_items = [
      {" Home                    ", :home, 0},
      {" Games                   ", :games, 1}
    ]

    buffer = TerminalBridge.draw_box(buffer, 0, nav_y, 30, 13, :single)
    buffer = TerminalBridge.write_at(buffer, 2, nav_y, "─ Navigation ──────────────")

    # Process nav items and build clickable regions
    {buffer, clickable_regions, _} =
      nav_items
      |> Enum.reduce({buffer, clickable_regions, 0}, fn item, {buf, regions, row_offset} ->
        case item do
          {:section_header, label, _} ->
            y_pos = nav_y + 2 + row_offset
            buf = TerminalBridge.write_at(buf, 2, y_pos, "─ #{label} ───────────────────")
            {buf, regions, row_offset + 1}

          {text, key, idx} ->
            y_pos = nav_y + 2 + row_offset
            cursor = get_nav_cursor(idx, cursor_y)
            buf = TerminalBridge.write_at(buf, 2, y_pos, cursor <> text)

            # Add clickable region for this navigation item
            regions =
              ClickableRegions.add_navigation_item(
                regions,
                key,
                y_pos,
                0,
                29
              )

            {buf, regions, row_offset + 1}
        end
      end)

    {buffer, clickable_regions}
  end

  defp draw_cursor_trail(buffer, state) do
    trail_enabled = Map.get(state, :trail_enabled, false)
    cursor_trail = Map.get(state, :cursor_trail)

    if trail_enabled == true and cursor_trail do
      trail_overlay = CursorTrail.get_trail_overlay(cursor_trail)

      Enum.reduce(trail_overlay, buffer, fn trail_pos, buf ->
        draw_trail_position(buf, trail_pos)
      end)
    else
      buffer
    end
  end

  defp draw_trail_position(buffer, trail_pos) do
    if trail_pos.row >= 0 and trail_pos.row < Config.height() and
         trail_pos.col >= 0 and trail_pos.col < Config.width() do
      write_trail_char(buffer, trail_pos)
    else
      buffer
    end
  end

  defp write_trail_char(buffer, trail_pos) do
    if buffer && Map.has_key?(buffer, :lines) && is_list(buffer.lines) do
      line = Enum.at(buffer.lines, trail_pos.row)

      if line && Map.has_key?(line, :cells) && is_list(line.cells) do
        update_trail_cell(buffer, line, trail_pos)
      else
        buffer
      end
    else
      buffer
    end
  end

  defp update_trail_cell(buffer, line, trail_pos) do
    existing = Enum.at(line.cells, trail_pos.col)

    if existing && Map.has_key?(existing, :char) &&
         (existing.char == " " or existing.char == "") do
      trail_cell = %{
        char: trail_pos.char,
        style: %{
          fg_color: trail_pos.style[:color] || :white,
          bg_color: nil,
          bold: false,
          italic: false,
          underline: false,
          reverse: false
        }
      }

      updated_cells = List.replace_at(line.cells, trail_pos.col, trail_cell)
      updated_line = %{line | cells: updated_cells}
      updated_lines = List.replace_at(buffer.lines, trail_pos.row, updated_line)
      %{buffer | lines: updated_lines}
    else
      buffer
    end
  end

  defp draw_status_bar(buffer, state) do
    y_pos = Config.status_bar_y()

    # Breadcrumb removed - tree view at top left already shows current section
    breadcrumb = ""

    vim_indicator = if State.vim_mode?(state), do: " [VIM]", else: ""
    cmd_indicator = if state.command_mode, do: " [CMD]", else: ""

    search_indicator =
      if state.command_mode && String.starts_with?(state.command_buffer, "search "),
        do: " [SEARCH]",
        else: ""

    privacy_indicator = if state.privacy_mode, do: " [PRIVACY]", else: ""
    encryption_indicator = if state.encryption_keys, do: " [E2E]", else: ""
    wallet_indicator = if state.web3_wallet_connected, do: " [WALLET]", else: ""

    {:ok, now} = DateTime.now("Europe/Madrid")
    time_str = Calendar.strftime(now, "%H:%M:%S")
    right_side = "#{time_str} │ ● "

    middle_content =
      vim_indicator <>
        cmd_indicator <>
        search_indicator <>
        privacy_indicator <>
        encryption_indicator <>
        wallet_indicator

    left_section = breadcrumb
    right_section = right_side

    total_width = Config.width()

    used_width =
      String.length(left_section) + String.length(middle_content) + String.length(right_section)

    spacing = max(0, total_width - used_width)

    left_spacing = div(spacing, 2)
    right_spacing = spacing - left_spacing

    status_line =
      left_section <>
        String.duplicate(" ", left_spacing) <>
        middle_content <>
        String.duplicate(" ", right_spacing) <>
        right_section

    status_line = String.pad_trailing(String.slice(status_line, 0, total_width), total_width)

    TerminalBridge.write_at(buffer, 0, y_pos, status_line)
  end

  # Modern always-visible REPL command bar
  defp draw_command_line(buffer, state) do
    y_pos = Config.command_line_y()

    # Command bar is always visible
    {prompt_line, show_suggestions} =
      if state.command_mode do
        # Focused: show command buffer with cursor
        cmd_text = state.command_buffer
        cursor = if rem(:erlang.system_time(:millisecond), 1000) < 500, do: "█", else: " "
        line = "⟩ " <> cmd_text <> cursor
        {line, cmd_text != ""}
      else
        # Unfocused: show placeholder hint
        {"⟩ Start typing or press Tab to search commands... (? for help)", false}
      end

    buffer = TerminalBridge.write_at(buffer, 0, y_pos, prompt_line)

    # Show suggestions dropdown if focused and has input
    suggestions = Map.get(state, :autocomplete_suggestions, [])

    if show_suggestions && suggestions != [] do
      draw_autocomplete_dropdown(buffer, state)
    else
      buffer
    end
  end

  defp draw_autocomplete_dropdown(buffer, state) do
    command_y = Config.command_line_y()
    max_suggestions = 8
    suggestions = Enum.take(state.autocomplete_suggestions, max_suggestions)

    dropdown_y = command_y - length(suggestions) - 3

    # Wider dropdown to show full descriptions (70 chars wide)
    dropdown_width = 70
    content_width = dropdown_width - 2

    # Build header with count
    count_info = " (#{length(suggestions)})"
    title = "Command Suggestions#{count_info}"
    title_prefix = "┌─ #{title} "
    fill_width = dropdown_width - String.length(title_prefix) - 1
    header = title_prefix <> String.duplicate("─", fill_width) <> "┐"

    # Build content lines with category badges
    content_lines =
      suggestions
      |> Enum.with_index()
      |> Enum.map(fn {suggestion, idx} ->
        selected = idx == state.autocomplete_index
        marker = if selected, do: "▸ ", else: "  "

        # Get category badge with color coding
        badge = format_category_badge(suggestion.category)

        # Format: "▸ [badge] command - description"
        # Truncate description to fit in remaining space
        cmd_part = "#{marker}#{badge} #{suggestion.command}"
        remaining_width = content_width - String.length(cmd_part) - 3
        desc_part = String.slice(suggestion.description, 0, remaining_width)

        text = "#{cmd_part} - #{desc_part}"
        padded_text = BoxConfig.truncate_and_pad(text, content_width)
        "│#{padded_text}│"
      end)

    # Build footer with navigation hint
    footer_text = " ↑↓ navigate • ⏎ select • Esc exit "
    footer_padding = content_width - String.length(footer_text)
    left_pad = div(footer_padding, 2)
    right_pad = footer_padding - left_pad

    footer_content =
      String.duplicate(" ", left_pad) <> footer_text <> String.duplicate(" ", right_pad)

    footer = "└#{footer_content}┘"

    # Combine all lines
    dropdown_lines = [header] ++ content_lines ++ [footer]

    # Draw at position using helper
    Helpers.draw_box_at(buffer, dropdown_lines, 2, dropdown_y)
  end

  # Format category badge with consistent width
  defp format_category_badge(category) do
    badge_text =
      case category do
        :game -> "GAME"
        :integration -> "INTG"
        :navigation -> "NAV "
        :content -> "INFO"
        :utility -> "UTIL"
        :tool -> "TOOL"
        :effect -> "FX  "
        :system -> "SYS "
        :file -> "FILE"
        _ -> "CMD "
      end

    "[#{badge_text}]"
  end

  # Content drawing with clickable regions - delegates to submodules

  # Draw content with clickable regions for interactive sections
  defp draw_content_with_regions(buffer, :games, state, clickable_regions) do
    # Draw the games content
    buffer = draw_content(buffer, :games, state)

    # Add clickable regions for each game entry
    # Games are displayed starting at y=17 (13 + 2 header + 2 first line)
    # Each game takes 5 lines (name, command, description, controls, blank line)
    game_y_start = 17

    games_data = [
      {:play_tetris, "Tetris"},
      {:play_snake, "Snake"},
      {:play_2048, "2048"},
      {:play_wordle, "Wordle"},
      {:play_conway, "Conway's Life"},
      {:play_typing, "Typing Test"}
    ]

    clickable_regions =
      games_data
      |> Enum.with_index()
      |> Enum.reduce(clickable_regions, fn {{game_id, game_name}, idx}, regions ->
        # Each game entry spans 5 lines, clickable on name row
        y_pos = game_y_start + idx * 5

        ClickableRegions.add_rect_region(
          regions,
          game_id,
          :action,
          y_pos,
          y_pos,
          35,
          105,
          "play:#{game_id}",
          %{game_name: game_name}
        )
      end)

    {buffer, clickable_regions}
  end

  # Projects and Web3 sections archived - no longer rendered in terminal
  defp draw_content_with_regions(buffer, :projects, _state, clickable_regions) do
    {buffer, clickable_regions}
  end

  defp draw_content_with_regions(buffer, :web3, _state, clickable_regions) do
    {buffer, clickable_regions}
  end

  # Default: just draw content, no additional clickable regions
  defp draw_content_with_regions(buffer, section, state, clickable_regions) do
    buffer = draw_content(buffer, section, state)
    {buffer, clickable_regions}
  end

  # Content drawing - delegates to submodules

  defp draw_content(buffer, :home, state) do
    posts = Home.get_posts()
    home_lines = Home.build_unified_home(posts)

    # Calculate content height (subtract box borders: top + bottom)
    content_height = max(0, length(home_lines) - 2)

    # Get scroll offset
    scroll_offset = Map.get(state, :scroll_offset, 0)

    # Apply viewport windowing to show only visible portion
    {windowed_lines, scroll_info} =
      apply_viewport_window(
        home_lines,
        scroll_offset,
        content_height
      )

    # Draw the windowed content
    buffer = Helpers.draw_box_at(buffer, windowed_lines, 35, 13)

    # Draw scroll indicators if content is scrollable
    if scroll_info.is_scrollable do
      draw_scroll_indicators(buffer, 35, 13, scroll_info)
    else
      buffer
    end
  end

  # Archived sections - users should visit web pages instead
  defp draw_content(buffer, :projects, _state), do: buffer
  defp draw_content(buffer, :skills, _state), do: buffer
  defp draw_content(buffer, :experience, _state), do: buffer
  defp draw_content(buffer, :contact, _state), do: buffer

  # All Content module sections archived - these are rarely used command-mode sections
  defp draw_content(buffer, :matrix, _state), do: buffer
  defp draw_content(buffer, :ssh, _state), do: buffer
  defp draw_content(buffer, :export_markdown, _state), do: buffer
  defp draw_content(buffer, :analytics, _state), do: buffer
  defp draw_content(buffer, :search_results, _state), do: buffer
  defp draw_content(buffer, :help, _state), do: buffer
  defp draw_content(buffer, :performance, _state), do: buffer
  defp draw_content(buffer, :ls, _state), do: buffer
  defp draw_content(buffer, :terminal, _state), do: buffer

  defp draw_content(buffer, :games, state) do
    games_lines = Games.draw_games_menu(state)
    Helpers.draw_box_at(buffer, games_lines, 35, 13)
  end

  defp draw_content(buffer, :stl_viewer, state) do
    stl_lines = STL.draw_viewer(state)
    Helpers.draw_box_at(buffer, stl_lines, 35, 13)
  end

  # Web3 section archived - users should visit /web3 page
  defp draw_content(buffer, :web3, _state), do: buffer

  defp draw_content(buffer, _, _state), do: buffer

  defp draw_help_modal(buffer, state) do
    if state.help_modal_open do
      draw_help_overlay(buffer, state)
    else
      buffer
    end
  end

  defp draw_help_overlay(buffer, state) do
    vim_mode = State.vim_mode?(state)
    vim_status = if vim_mode, do: "ON", else: "OFF"

    help_lines = [
      "╔═══════════════════════════════════════════════════════════════════════════╗",
      "║                          KEYBOARD SHORTCUTS HELP                        ║",
      "╠═══════════════════════════════════════════════════════════════════════════╣",
      "║                                                                         ║",
      "║  NAVIGATION                                                             ║",
      "║  ↑ ↓ ← →           Navigate menu items (arrow keys)                     ║",
      "║  Enter             Select current menu item                             ║",
      "║  1-5               Jump to menu item by number                          ║",
      "║  Click             Click any menu item to select                        ║",
      "║                                                                         ║",
      "║  VIM MODE (currently: #{String.pad_trailing(vim_status, 3)})                           ║",
      "║  v                 Toggle vim mode on/off                               ║",
      if(vim_mode,
        do: "║  h j k l           Navigate (left/down/up/right) when vim mode is on       ║",
        else: "║  h j k l           (Disabled - enable vim mode with 'v')                  ║"
      ),
      if(vim_mode,
        do: "║  g / G             Jump to top / bottom when vim mode is on               ║",
        else: "║  g / G             (Disabled - enable vim mode with 'v')                  ║"
      ),
      "║                                                                         ║",
      "║  COMMANDS                                                               ║",
      "║  :                 Enter command mode                                   ║",
      "║  /                 Enter search mode                                    ║",
      "║  Esc               Exit command/search mode                             ║",
      "║                                                                         ║",
      "║  HELP                                                                   ║",
      "║  ?                 Toggle this help modal                               ║",
      "║                                                                         ║",
      "╚═══════════════════════════════════════════════════════════════════════════╝"
    ]

    Helpers.draw_box_at(buffer, help_lines, 2, 0)
  end

  defp get_nav_cursor(idx, cursor_y) do
    if idx == cursor_y, do: "█", else: "░"
  end

  # Viewport windowing helpers

  # Apply viewport windowing to content lines based on scroll offset.
  # Returns {windowed_lines, scroll_info} where scroll_info contains metadata.
  defp apply_viewport_window(lines, scroll_offset, content_height) do
    # Dynamic calculation based on terminal height
    viewport_height = Config.content_viewport_height()

    # Check if content is scrollable
    is_scrollable = content_height > viewport_height

    if not is_scrollable do
      # Content fits, no windowing needed
      scroll_info = %{
        is_scrollable: false,
        scroll_offset: 0,
        visible_start: 0,
        visible_end: content_height,
        total_height: content_height,
        scroll_percent: 0
      }

      {lines, scroll_info}
    else
      # Extract header and footer (first and last lines are box borders)
      [header | rest] = lines
      content_with_footer = rest
      footer = List.last(content_with_footer) || ""
      pure_content = Enum.drop(content_with_footer, -1)

      # Calculate visible window
      visible_start = scroll_offset
      visible_end = min(scroll_offset + viewport_height, length(pure_content))

      # Extract visible content
      visible_content =
        pure_content
        |> Enum.slice(visible_start, viewport_height)

      # Pad if needed to maintain box height
      padding_needed = max(0, viewport_height - length(visible_content))

      padded_content =
        visible_content ++ List.duplicate("│#{String.duplicate(" ", 69)}│", padding_needed)

      # Reconstruct with header and footer
      windowed_lines = [header] ++ padded_content ++ [footer]

      scroll_info = %{
        is_scrollable: true,
        scroll_offset: scroll_offset,
        visible_start: visible_start,
        visible_end: visible_end,
        total_height: content_height,
        scroll_percent: round(scroll_offset / max(1, content_height - viewport_height) * 100)
      }

      {windowed_lines, scroll_info}
    end
  end

  # Draw scroll indicators showing position and available content.
  defp draw_scroll_indicators(buffer, box_x, box_y, scroll_info) do
    viewport_height = Config.content_viewport_height()

    # Calculate indicator positions
    can_scroll_up = scroll_info.scroll_offset > 0
    can_scroll_down = scroll_info.visible_end < scroll_info.total_height

    # Top indicator (arrow up when scrolled down)
    buffer =
      if can_scroll_up do
        # Draw up arrow in top-right of box (inside border)
        indicator = " ↑ More "
        # Right side of 71-char box
        x_pos = box_x + 64
        TerminalBridge.write_at(buffer, x_pos, box_y + 1, indicator)
      else
        buffer
      end

    # Bottom indicator (arrow down when more content below)
    buffer =
      if can_scroll_down do
        # Draw down arrow in bottom-right of box
        indicator = " ↓ More "
        x_pos = box_x + 64
        # Bottom of box
        y_pos = box_y + viewport_height + 3
        TerminalBridge.write_at(buffer, x_pos, y_pos, indicator)
      else
        buffer
      end

    # Scroll position indicator in top-left corner
    scroll_text = " #{scroll_info.scroll_percent}% "
    TerminalBridge.write_at(buffer, box_x + 2, box_y + 1, scroll_text)
  end
end
