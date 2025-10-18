defmodule Droodotfoo.Raxol.Renderer do
  @moduledoc """
  Main renderer orchestration for the terminal UI.

  This module has been refactored into focused submodules:
  - Renderer.Helpers - Shared utility functions
  - Renderer.Games - Games menu and selection
  - Renderer.Spotify - Spotify UI components
  - Renderer.Web3 - Web3 wallet UI
  - Renderer.Portal - Portal P2P status displays
  - Renderer.Projects - Project showcase
  - Renderer.Content - Static content sections
  - Renderer.Home - Home section
  """

  alias Droodotfoo.{CursorTrail, TerminalBridge}
  alias Droodotfoo.Raxol.{BoxConfig, Config, State}

  alias Droodotfoo.Raxol.Renderer.{
    Content,
    Games,
    Helpers,
    Home,
    Portal,
    Projects,
    Spotify,
    STL,
    Web3
  }

  @doc """
  Main render function that orchestrates all drawing operations
  """
  def render(state) do
    # Use dynamic height for scrollable sections (experience, projects)
    buffer_height =
      if state.current_section in [:experience, :projects] and has_scrollable_content?(state) do
        Config.max_scrollable_height()
      else
        Config.height()
      end

    buffer = TerminalBridge.create_blank_buffer(Config.width(), buffer_height)

    buffer
    |> draw_ascii_logo()
    |> draw_breadcrumb(state)
    |> draw_navigation(state)
    |> draw_cursor_trail(state)
    |> draw_content(state.current_section, state)
    |> Portal.draw_enhanced_ui(state)
    |> draw_status_bar(state)
    |> draw_command_line(state)
    |> draw_help_modal(state)
  end

  # Check if current section has scrollable content
  defp has_scrollable_content?(%{current_section: :experience, resume_data: resume_data})
       when is_map(resume_data) and resume_data != %{},
       do: true

  defp has_scrollable_content?(_state), do: false

  # Core UI Functions

  defp draw_ascii_logo(buffer) do
    logo_lines = [
      "╭────────────────────────────────────────────────────────────────────────────────────────────────────────╮",
      "│                                                                                                        │",
      "│                     ██████╗ ██████╗  ██████╗  ██████╗                                                  │",
      "│                     ██╔══██╗██╔══██╗██╔═══██╗██╔═══██╗                                                 │",
      "│                     ██║  ██║██████╔╝██║   ██║██║   ██║                                                 │",
      "│                     ██║  ██║██╔══██╗██║   ██║██║   ██║                                                 │",
      "│                     ██████╔╝██║  ██║╚██████╔╝╚██████╔╝                                                 │",
      "│                     ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝                                                  │",
      "│                                                                                                        │",
      "╰────────────────────────────────────────────────────────────────────────────────────────────────────────╯"
    ]

    Helpers.draw_box_at(buffer, logo_lines, 0, 0)
  end

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

  defp draw_navigation(buffer, state) do
    nav_y = 13
    cursor_y = state.cursor_y

    nav_items = [
      {" Home                    ", :home, 0},
      {" Experience              ", :experience, 1},
      {" Contact                 ", :contact, 2},
      {:section_header, "Fun", nil},
      {" Games                   ", :games, 3},
      {" Spotify                 ", :spotify, 4},
      {" STL Viewer              ", :stl_viewer, 5},
      {" Web3                    ", :web3, 6}
    ]

    buffer = TerminalBridge.draw_box(buffer, 0, nav_y, 30, 13, :single)
    buffer = TerminalBridge.write_at(buffer, 2, nav_y, "─ Navigation ──────────────")

    nav_items
    |> Enum.reduce({buffer, 0}, fn item, {buf, row_offset} ->
      case item do
        {:section_header, label, _} ->
          y_pos = nav_y + 2 + row_offset
          buf = TerminalBridge.write_at(buf, 2, y_pos, "─ #{label} ───────────────────")
          {buf, row_offset + 1}

        {text, _key, idx} ->
          y_pos = nav_y + 2 + row_offset
          cursor = get_nav_cursor(idx, cursor_y)
          buf = TerminalBridge.write_at(buf, 2, y_pos, cursor <> text)
          {buf, row_offset + 1}
      end
    end)
    |> elem(0)
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

    {:ok, now} = DateTime.now("Etc/UTC")
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

  defp draw_command_line(buffer, %{command_mode: true} = state) do
    y_pos = Config.command_line_y()
    prompt = ":" <> state.command_buffer <> "_"
    buffer = TerminalBridge.write_at(buffer, 0, y_pos, prompt)

    suggestions = Map.get(state, :autocomplete_suggestions, [])

    if suggestions != [] do
      draw_autocomplete_dropdown(buffer, state)
    else
      buffer
    end
  end

  defp draw_command_line(buffer, _state) do
    y_pos = Config.command_line_y()
    hint = "? help • : cmd • / search"
    TerminalBridge.write_at(buffer, 0, y_pos, hint)
  end

  defp draw_autocomplete_dropdown(buffer, state) do
    command_y = Config.command_line_y()
    max_suggestions = 8
    suggestions = Enum.take(state.autocomplete_suggestions, max_suggestions)

    dropdown_y = command_y - length(suggestions) - 3

    # Build compact dropdown box (42 chars wide)
    dropdown_width = 42
    # 40 chars for content
    content_width = dropdown_width - 2

    # Build header
    title = "Suggestions"
    title_prefix = "┌─ #{title} "
    fill_width = dropdown_width - String.length(title_prefix) - 1
    header = title_prefix <> String.duplicate("─", fill_width) <> "┐"

    # Build content lines with selection markers
    content_lines =
      suggestions
      |> Enum.with_index()
      |> Enum.map(fn {suggestion, idx} ->
        selected = idx == state.autocomplete_index
        marker = if selected, do: "> ", else: "  "
        text = marker <> suggestion
        padded_text = BoxConfig.truncate_and_pad(text, content_width)
        "│#{padded_text}│"
      end)

    # Build footer
    footer = "└" <> String.duplicate("─", content_width) <> "┘"

    # Combine all lines
    dropdown_lines = [header] ++ content_lines ++ [footer]

    # Draw at position using helper
    Helpers.draw_box_at(buffer, dropdown_lines, 2, dropdown_y)
  end

  # Content drawing - delegates to submodules

  defp draw_content(buffer, :home, _state) do
    posts = Home.get_posts()
    home_lines = Home.build_unified_home(posts)
    Helpers.draw_box_at(buffer, home_lines, 35, 13)
  end

  defp draw_content(buffer, :projects, state) do
    if Map.get(state, :project_detail_view, false) do
      Projects.draw_detail(buffer, state)
    else
      Projects.draw_list(buffer, state)
    end
  end

  defp draw_content(buffer, :skills, _state) do
    Helpers.draw_box_at(buffer, Content.draw_skills(), 35, 13)
  end

  defp draw_content(buffer, :experience, state) do
    Helpers.draw_box_at(buffer, Content.draw_experience(state), 35, 13)
  end

  defp draw_content(buffer, :contact, _state) do
    Helpers.draw_box_at(buffer, Content.draw_contact(), 35, 13)
  end

  defp draw_content(buffer, :matrix, _state) do
    Helpers.draw_box_at(buffer, Content.draw_matrix(), 35, 13)
  end

  defp draw_content(buffer, :ssh, _state) do
    Helpers.draw_box_at(buffer, Content.draw_ssh(), 35, 13)
  end

  defp draw_content(buffer, :export_markdown, _state) do
    Helpers.draw_box_at(buffer, Content.draw_export_markdown(), 35, 13)
  end

  defp draw_content(buffer, :analytics, _state) do
    Helpers.draw_box_at(buffer, Content.draw_analytics(), 35, 13)
  end

  defp draw_content(buffer, :search_results, state) do
    Content.draw_search_results(buffer, state)
  end

  defp draw_content(buffer, :help, _state) do
    Helpers.draw_box_at(buffer, Content.draw_help(), 35, 13)
  end

  defp draw_content(buffer, :performance, _state) do
    performance_lines = Content.draw_performance()

    performance_lines
    |> Enum.take(min(length(performance_lines), 22))
    |> then(&Helpers.draw_box_at(buffer, &1, 0, 1))
  end

  defp draw_content(buffer, :ls, _state) do
    Helpers.draw_box_at(buffer, Content.draw_ls(), 35, 13)
  end

  defp draw_content(buffer, :terminal, state) do
    terminal_lines = Content.draw_terminal(state)

    terminal_lines
    |> Enum.take(min(length(terminal_lines), 35 - 13))
    |> then(&Helpers.draw_box_at(buffer, &1, 35, 13))
  end

  defp draw_content(buffer, :spotify, state) do
    auth_status = Droodotfoo.Spotify.auth_status()

    spotify_lines =
      case auth_status do
        :authenticated -> Spotify.draw_view(state)
        _ -> Spotify.draw_auth_prompt()
      end

    Helpers.draw_box_at(buffer, spotify_lines, 35, 13)
  end

  defp draw_content(buffer, :games, state) do
    games_lines = Games.draw_games_menu(state)
    Helpers.draw_box_at(buffer, games_lines, 35, 13)
  end

  defp draw_content(buffer, :stl_viewer, state) do
    stl_lines = STL.draw_viewer(state)
    Helpers.draw_box_at(buffer, stl_lines, 35, 13)
  end

  defp draw_content(buffer, :web3, state) do
    web3_lines =
      if state.web3_wallet_connected do
        Web3.draw_connected(state)
      else
        Web3.draw_connect_prompt(state)
      end

    Helpers.draw_box_at(buffer, web3_lines, 35, 13)
  end

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
end
