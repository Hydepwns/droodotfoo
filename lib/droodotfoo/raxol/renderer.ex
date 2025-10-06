defmodule Droodotfoo.Raxol.Renderer do
  @moduledoc """
  Handles all rendering logic for the terminal UI.
  """

  alias Droodotfoo.TerminalBridge
  alias Droodotfoo.CursorTrail
  alias Droodotfoo.Raxol.{State, Config}

  @doc """
  Main render function that orchestrates all drawing operations
  """
  def render(state) do
    buffer = TerminalBridge.create_blank_buffer(Config.width(), Config.height())

    buffer
    |> draw_ascii_logo()
    |> draw_breadcrumb(state)
    |> draw_navigation(state)
    |> draw_cursor_trail(state)
    |> draw_content(state.current_section, state)
    |> draw_status_bar(state)
    |> draw_command_line(state)
    |> draw_help_modal(state)
  end

  # Helper function to reduce repetition in drawing boxes
  defp draw_box_at(buffer, lines, x, y) do
    lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, x, y + idx, line)
    end)
  end

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

    draw_box_at(buffer, logo_lines, 0, 0)
  end

  defp draw_breadcrumb(buffer, state) do
    breadcrumb = format_breadcrumb(state.current_section)
    # Draw breadcrumb at row 11, centered
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
      {" Projects                ", :projects, 1},
      {" Skills                  ", :skills, 2},
      {" Experience              ", :experience, 3},
      {" Contact                 ", :contact, 4},
      {:section_header, "Tools", nil},
      {" Spotify                 ", :spotify, 5},
      {" STL Viewer              ", :stl_viewer, 6},
      {" Web3                    ", :web3, 7}
    ]

    # Box now has extra lines for the Tools section header, Spotify, STL Viewer, and Web3
    buffer = TerminalBridge.draw_box(buffer, 0, nav_y, 30, 12, :single)
    buffer = TerminalBridge.write_at(buffer, 2, nav_y, "─ Navigation ──────────────")

    nav_items
    |> Enum.reduce({buffer, 0}, fn item, {buf, row_offset} ->
      case item do
        {:section_header, label, _} ->
          # Draw section header
          y_pos = nav_y + 2 + row_offset
          buf = TerminalBridge.write_at(buf, 2, y_pos, "─ #{label} ───────────────────")
          {buf, row_offset + 1}

        {text, _key, idx} ->
          # Draw navigation item with gradient for selected
          y_pos = nav_y + 2 + row_offset
          cursor = if idx == cursor_y, do: "█", else: "░"
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
      # Get trail overlay from cursor trail
      trail_overlay = CursorTrail.get_trail_overlay(cursor_trail)

      # Apply each trail position to the buffer
      Enum.reduce(trail_overlay, buffer, fn trail_pos, buf ->
        # Only draw if within bounds
        if trail_pos.row >= 0 and trail_pos.row < Config.height() and
             trail_pos.col >= 0 and trail_pos.col < Config.width() do
          # Write the trail character with styling
          write_trail_char(buf, trail_pos)
        else
          buf
        end
      end)
    else
      buffer
    end
  end

  defp write_trail_char(buffer, trail_pos) do
    # Get the current cell at this position
    # Buffer is a map with :lines key containing list of lines
    # First check if buffer has lines
    if buffer && Map.has_key?(buffer, :lines) && is_list(buffer.lines) do
      line = Enum.at(buffer.lines, trail_pos.row)

      # Check if line exists and has cells before accessing
      if line && Map.has_key?(line, :cells) && is_list(line.cells) do
        existing = Enum.at(line.cells, trail_pos.col)

        # Only draw trail if the cell exists and is empty or space
        if existing && Map.has_key?(existing, :char) &&
             (existing.char == " " or existing.char == "") do
          # Create a styled trail cell
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

          # Update the buffer at this position
          updated_cells = List.replace_at(line.cells, trail_pos.col, trail_cell)
          updated_line = %{line | cells: updated_cells}
          updated_lines = List.replace_at(buffer.lines, trail_pos.row, updated_line)
          %{buffer | lines: updated_lines}
        else
          buffer
        end
      else
        buffer
      end
    else
      buffer
    end
  end

  defp draw_status_bar(buffer, state) do
    y_pos = Config.status_bar_y()

    # Left side: current section breadcrumb with gradient
    section_name = format_section_name(state.current_section)
    breadcrumb = " █▓▒░ #{section_name}"

    # Middle: vim mode and command mode indicators with gradient
    vim_indicator = if State.vim_mode?(state), do: " ▓VIM", else: ""
    cmd_indicator = if state.command_mode, do: " ▓CMD", else: ""

    search_indicator =
      if state.command_mode && String.starts_with?(state.command_buffer, "search "),
        do: " ▓SEARCH",
        else: ""

    # Right side: time and connection status with gradient
    {:ok, now} = DateTime.now("Etc/UTC")
    time_str = Calendar.strftime(now, "%H:%M:%S")
    right_side = "#{time_str} │ ░▒▓█ "

    # Calculate spacing
    middle_content = vim_indicator <> cmd_indicator <> search_indicator
    left_section = breadcrumb
    right_section = right_side

    # Build status bar with proper spacing
    total_width = Config.width()

    used_width =
      String.length(left_section) + String.length(middle_content) + String.length(right_section)

    spacing = max(0, total_width - used_width)

    # Distribute spacing: middle gets centered
    left_spacing = div(spacing, 2)
    right_spacing = spacing - left_spacing

    status_line =
      left_section <>
        String.duplicate(" ", left_spacing) <>
        middle_content <>
        String.duplicate(" ", right_spacing) <>
        right_section

    # Ensure exactly the right width
    status_line = String.pad_trailing(String.slice(status_line, 0, total_width), total_width)

    TerminalBridge.write_at(buffer, 0, y_pos, status_line)
  end

  defp format_section_name(:home), do: "Home"
  defp format_section_name(:terminal), do: "Terminal"
  defp format_section_name(:performance), do: "Performance"
  defp format_section_name(:stl_viewer), do: "STL Viewer"
  defp format_section_name(:search_results), do: "Search Results"

  defp format_section_name(section) do
    section
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp draw_command_line(buffer, %{command_mode: true} = state) do
    # Draw command input line at bottom
    y_pos = Config.command_line_y()
    prompt = ":" <> state.command_buffer <> "_"
    buffer = TerminalBridge.write_at(buffer, 0, y_pos, prompt)

    # Draw autocomplete dropdown if suggestions exist
    suggestions = Map.get(state, :autocomplete_suggestions, [])
    if suggestions != [] do
      draw_autocomplete_dropdown(buffer, state)
    else
      buffer
    end
  end

  defp draw_command_line(buffer, _state) do
    # Show hint when not in command mode
    y_pos = Config.command_line_y()
    hint = "? help • : cmd • / search"
    TerminalBridge.write_at(buffer, 0, y_pos, hint)
  end

  defp draw_autocomplete_dropdown(buffer, state) do
    # Draw autocomplete suggestions above the command line
    command_y = Config.command_line_y()
    max_suggestions = 8
    suggestions = Enum.take(state.autocomplete_suggestions, max_suggestions)

    # Calculate dropdown position (above command line, above status bar)
    dropdown_y = command_y - length(suggestions) - 3

    # Draw dropdown box
    buffer =
      suggestions
      |> Enum.with_index()
      |> Enum.reduce(buffer, fn {suggestion, idx}, buf ->
        y = dropdown_y + idx + 1
        selected = idx == state.autocomplete_index

        # Format suggestion line with selection indicator
        line =
          if selected do
            "> #{suggestion}"
          else
            "  #{suggestion}"
          end

        TerminalBridge.write_at(buf, 2, y, String.pad_trailing(line, 40))
      end)

    # Draw top border
    buffer = TerminalBridge.write_at(buffer, 2, dropdown_y, "┌─ Suggestions " <> String.duplicate("─", 25) <> "┐")

    # Draw bottom border
    bottom_y = dropdown_y + length(suggestions) + 1
    buffer = TerminalBridge.write_at(buffer, 2, bottom_y, "└" <> String.duplicate("─", 40) <> "┘")

    buffer
  end

  # Content drawing functions
  defp draw_content(buffer, :home, _state) do
    about_lines = [
      "┌─ About ─────────────────────────────────────────────────────────────┐",
      "│                                                                     │",
      "│  Multi Disciplinary Engineer                                        │",
      "│  expertise in distributed systems and real-time apps.               │",
      "│                                                                     │",
      "│  • 5+ years building scalable distributed systems                   │",
      "│  • Elixir, Phoenix, LiveView expert                                 │",
      "│  • Terminal UI and CLI enthusiast                                   │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    recent_lines = [
      "",
      "┌─ Recent Activity ───────────────────────────────────────────────────┐",
      "│                                                                     │",
      "│  2025-09  Terminal droo.foo System                                  │",
      "│  2025-08  Data pipeline infrastructure                              │",
      "│  2025-07  Elixir telemetry monitoring                               │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    buffer
    |> draw_box_at(about_lines, 35, 13)
    |> draw_box_at(recent_lines, 35, 13 + length(about_lines))
  end

  defp draw_content(buffer, :projects, state) do
    if Map.get(state, :project_detail_view, false) do
      draw_project_detail(buffer, state)
    else
      draw_project_list(buffer, state)
    end
  end

  defp draw_content(buffer, :skills, _state) do
    skills_lines = [
      "╭─ Technical Skills ──────────────────────────────────────────────────╮",
      "│                                                                     │",
      "│  Languages:                                                         │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("Elixir", 90, width: 35, label_width: 12, gradient: true, style: :rounded)}        │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("Phoenix", 85, width: 35, label_width: 12, gradient: true, style: :rounded)}       │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("JavaScript", 75, width: 35, label_width: 12, gradient: true, style: :rounded)}    │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("TypeScript", 70, width: 35, label_width: 12, gradient: true, style: :rounded)}    │",
      "│                                                                     │",
      "│  Frameworks & Libraries:                                            │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("LiveView", 95, width: 35, label_width: 12, gradient: true, style: :rounded)}      │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("React", 80, width: 35, label_width: 12, gradient: true, style: :rounded)}         │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("GraphQL", 75, width: 35, label_width: 12, gradient: true, style: :rounded)}       │",
      "│                                                                     │",
      "│  Infrastructure & Tools:                                            │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("Docker", 85, width: 35, label_width: 12, gradient: true, style: :rounded)}        │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("PostgreSQL", 90, width: 35, label_width: 12, gradient: true, style: :rounded)}    │",
      "│                                                                     │",
      "╰─────────────────────────────────────────────────────────────────────╯"
    ]

    draw_box_at(buffer, skills_lines, 35, 13)
  end

  defp draw_content(buffer, :experience, _state) do
    exp_lines = [
      "┌─ Experience ─────────────────────────────────────────────────┐",
      "│                                                              │",
      "│  ▪ Senior Backend Engineer                                   │",
      "│    axol.io | 2023 - Present                                  │",
      "│    • Built event-driven microservices architecture           │",
      "│    • Reduced API response time by 70% through optimization   │",
      "│                                                              │",
      "│  ▪ Elixir Developer                                          │",
      "│    FinTech Startup | 2019 - 2021                             │",
      "│    • Designed and implemented real-time payment processing   │",
      "│    • Handled 1M+ transactions daily with 99.9% uptime        │",
      "│                                                              │",
      "│  ▪ Full Stack Developer                                      │",
      "│    Digital Agency | 2017 - 2019                              │",
      "│    • Built web applications for diverse clients              │",
      "│                                                              │",
      "└──────────────────────────────────────────────────────────────┘"
    ]

    draw_box_at(buffer, exp_lines, 35, 13)
  end

  defp draw_content(buffer, :contact, _state) do
    contact_lines = [
      "╭─ Contact ───────────────────────────────────────────────────────────╮",
      "│                                                                     │",
      "│  Let's connect:                                                     │",
      "│                                                                     │",
      "│  ╭─ Email ─────────────────────────────────────────────────────╮   │",
      "│  │ █▓▒░ drew@axol.io                                           │   │",
      "│  ╰─────────────────────────────────────────────────────────────╯   │",
      "│                                                                     │",
      "│  ╭─ GitHub ────────────────────────────────────────────────────╮   │",
      "│  │ █▓▒░ github.com/hydepwns                                    │   │",
      "│  ╰─────────────────────────────────────────────────────────────╯   │",
      "│                                                                     │",
      "│  ╭─ LinkedIn ──────────────────────────────────────────────────╮   │",
      "│  │ █▓▒░ linkedin.com/in/drew-hiro                              │   │",
      "│  ╰─────────────────────────────────────────────────────────────╯   │",
      "│                                                                     │",
      "│  ╭─ X/Twitter ─────────────────────────────────────────────────╮   │",
      "│  │ █▓▒░ @MF_DROO                                               │   │",
      "│  ╰─────────────────────────────────────────────────────────────╯   │",
      "│                                                                     │",
      "│  ╭─ Availability ──────────────────────────────────────────────╮   │",
      "│  │ ░▒▓█ Available for consulting on Elixir, Phoenix, LiveView, │   │",
      "│  │      and distributed systems architecture                   │   │",
      "│  ╰─────────────────────────────────────────────────────────────╯   │",
      "│                                                                     │",
      "╰─────────────────────────────────────────────────────────────────────╯"
    ]

    draw_box_at(buffer, contact_lines, 35, 13)
  end

  defp draw_content(buffer, :matrix, _state) do
    matrix_lines = [
      "┌─ Matrix Rain ───────────────────────────────┐",
      "│                                             │",
      "│ 01001101 01100001 01110100 01110010 0110101 │",
      "│ ▓▒░ Follow the white rabbit ░▒▓             │",
      "│                                             │",
      "│   █▓▒░ ▓█▒░ ▒▓█░ ░█▓▒ █░▒▓ ▓▒░█ ░▒█▓ ▓█░▒   │",
      "│   ░▒▓█ ▒░█▓ █▒▓░ ▓▒█░ ░▓▒█ █▓░▒ ▒█▓░ ░▓█▒   │",
      "│   ▓█░▒ █▓▒░ ░█▒▓ ▒░▓█ ▓█░▒ ░█▓▒ █░▓▒ ▒░█▓   │",
      "│   ▒▓█░ ░█▓▒ ▓░▒█ █▓░▒ ▒░█▓ ▓▒█░ ░▓▒█ █▓▒░   │",
      "│                                             │",
      "│        Welcome to the Matrix, Neo...        │",
      "│                                             │",
      "│       Type :clear to exit the Matrix        │",
      "│                                             │",
      "└─────────────────────────────────────────────┘"
    ]

    draw_box_at(buffer, matrix_lines, 35, 13)
  end

  defp draw_content(buffer, :ssh, _state) do
    ssh_lines = [
      "┌─ SSH Session ─────────────────────────────────┐",
      "│                                               │",
      "│ $ ssh droo@droo.foo                           │",
      "│ Password: ****                                │",
      "│                                               │",
      "│ Welcome to droo.foo OS 1.0 LTS                │",
      "│ Last login: #{DateTime.utc_now() |> DateTime.truncate(:second) |> to_string() |> String.slice(0, 19)} │",
      "│                                               │",
      "│ [droo@droo ~]$ ls                             │",
      "│ projects/ skills/ experience/ contact/        │",
      "│                                               │",
      "│ [droo@droo ~]$ _                              │",
      "│                                               │",
      "└───────────────────────────────────────────────┘"
    ]

    draw_box_at(buffer, ssh_lines, 35, 13)
  end

  defp draw_content(buffer, :export_markdown, _state) do
    export_lines = [
      "┌─ Export: Markdown ────────────────────────────┐",
      "│                                               │",
      "│ # Droo - Multidisciplinary Engineer           │",
      "│                                               │",
      "│ **Email:** drew@axol.io                       │",
      "│ **GitHub:** github.com/hydepwns               │",
      "│                                               │",
      "│ ## Summary                                    │",
      "│ Senior Software Engineer with expertise...    │",
      "│                                               │",
      "│ [Download resume.md]                          │",
      "│                                               │",
      "└───────────────────────────────────────────────┘"
    ]

    draw_box_at(buffer, export_lines, 35, 13)
  end

  defp draw_content(buffer, :analytics, _state) do
    analytics_lines = [
      "┌─ Analytics Dashboard ─────────────────────────┐",
      "│                                               │",
      "│  Page Views:      247                         │",
      "│  Unique Visitors:  42                         │",
      "│  Avg. Duration:   3m 27s                      │",
      "│                                               │",
      "│  Top Commands:    Top Sections:               │",
      "│  1. help (31)     1. projects (89)            │",
      "│  2. ls (27)       2. skills (67)              │",
      "│  3. cat (19)      3. experience (45)          │",
      "│                                               │",
      "│  Peak Hours: 14:00-15:00, 20:00-21:00         │",
      "│                                               │",
      "└───────────────────────────────────────────────┘"
    ]

    draw_box_at(buffer, analytics_lines, 35, 13)
  end

  defp draw_content(buffer, :search_results, state) do
    search_state = state.search_state
    match_counter = Droodotfoo.AdvancedSearch.match_counter(search_state)

    # Build search results display
    header = [
      "┌─ Search Results ──────────────────────────────┐",
      "│ Query: #{String.pad_trailing(String.slice(search_state.query, 0, 38), 38)} │",
      "│ Mode: #{search_state.mode} | #{String.pad_trailing(match_counter, 24)} │",
      "├───────────────────────────────────────────────┤"
    ]

    # Display results (limited to fit screen)
    results_lines =
      if length(search_state.results) > 0 do
        search_state.results
        |> Enum.take(8)
        |> Enum.with_index()
        |> Enum.map(fn {result, idx} ->
          section = result.section |> Atom.to_string() |> String.upcase()

          # Highlight matched positions in the line (but strip ANSI for now due to rendering complexity)
          # highlighted_line = Droodotfoo.AdvancedSearch.highlight_line(
          #   result.line,
          #   result.match_positions,
          #   search_state.highlight_color
          # )
          line = String.slice(result.line, 0, 30)

          # Mark current match with arrow
          marker = if idx == search_state.current_match_index, do: ">", else: " "

          "│ #{marker}[#{String.pad_trailing(section, 10)}] #{String.pad_trailing(line, 30)} │"
        end)
      else
        ["│ No results found                             │"]
      end

    footer = [
      "├───────────────────────────────────────────────┤",
      "│ n/N: next/prev  --fuzzy --exact --regex       │",
      "│ Press ESC to exit search                      │",
      "└───────────────────────────────────────────────┘"
    ]

    all_lines = header ++ results_lines ++ footer

    all_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      # Pad line to exactly 49 chars for box drawing
      padded_line = String.pad_trailing(line, 49)
      TerminalBridge.write_at(buf, 16, 8 + idx, padded_line)
    end)
  end

  defp draw_content(buffer, :help, _state) do
    help_lines = [
      "┌─ Help ───────────────────────────────────────┐",
      "│                                              │",
      "│ Available Commands:                          │",
      "│                                              │",
      "│  :help      - Show this help menu            │",
      "│  :ls        - List available sections        │",
      "│  :cat <sec> - Display section content        │",
      "│  :clear     - Clear screen                   │",
      "│  :matrix     - Matrix rain effect            │",
      "│  :perf       - Performance metrics dashboard │",
      "│  :metrics    - Alias for :perf               │",
      "│  /query      - Search for content            │",
      "│  :ssh        - SSH simulation                │",
      "│  :export fmt - Export resume (md/json/txt)   │",
      "│  :analytics  - View analytics dashboard      │",
      "│                                              │",
      "│ Navigation:                                  │",
      "│  hjkl       - Vim-style navigation           │",
      "│  g/G        - Jump to top/bottom             │",
      "│  Tab        - Command completion             │",
      "│  Enter      - Select item                    │",
      "│  Escape     - Exit mode                      │",
      "│                                              │",
      "└──────────────────────────────────────────────┘"
    ]

    draw_box_at(buffer, help_lines, 35, 13)
  end

  defp draw_content(buffer, :performance, _state) do
    # Get both summary and raw metrics for charts
    summary = Droodotfoo.PerformanceMonitor.get_summary()
    raw_metrics = Droodotfoo.PerformanceMonitor.get_metrics()

    # Generate sparklines from raw data
    render_sparkline = Droodotfoo.AsciiChart.sparkline(raw_metrics.render_times, width: 20)
    memory_sparkline = Droodotfoo.AsciiChart.sparkline(raw_metrics.memory_usage, width: 20)

    # Format values
    uptime_str = "#{summary.uptime_hours}h"
    req_rate = "#{summary.requests_per_minute}/min"

    content_lines = [
      "╔══════════════════════════════════════════════════════════════════════════════╗",
      "║ PERFORMANCE DASHBOARD                                    [Updated: now]      ║",
      "╠══════════════════════════════════════════════════════════════════════════════╣",
      "║                                                                              ║",
      "║  Render Time (ms)              Memory (MB)              Request Rate         ║",
      "║  ┌─────────────────┐          ┌──────────────┐         ┌─────────────────┐   ║",
      "║  │ #{String.pad_trailing(render_sparkline, 15)} │          │ #{String.pad_trailing(memory_sparkline, 12)} │         │    #{String.pad_trailing(req_rate, 13)}│  ║",
      "║  └─────────────────┘          └──────────────┘         └─────────────────┘   ║",
      "║    Avg: #{String.pad_trailing("#{summary.avg_render_time}ms", 18)}   Cur: #{String.pad_trailing("#{summary.current_memory}MB", 18)}   Total: #{String.pad_trailing("#{summary.total_requests}", 10)}    ║",
      "║                                                                              ║",
      "║  System Status                                                               ║",
      "║  ──────────────────────────────────────────────────────────────────────────  ║",
      "║                                                                              ║",
      "║  Uptime:         #{String.pad_trailing(uptime_str, 15)}  Errors:       #{String.pad_trailing("#{summary.total_errors} (#{summary.error_rate}%)", 20)}  ║",
      "║  Processes:      #{String.pad_trailing("#{summary.current_processes}", 15)}  Avg Memory:  #{String.pad_trailing("#{summary.avg_memory}MB", 20)}  ║",
      "║  P95 Render:     #{String.pad_trailing("#{summary.p95_render_time}ms", 15)}  Max Render:  #{String.pad_trailing("#{summary.max_render_time}ms", 20)}  ║",
      "║                                                                              ║",
      "║  Performance Indicators:                                                     ║",
      "║                                                                              ║",
      "║  #{Droodotfoo.AsciiChart.percent_bar("Render", min(summary.avg_render_time * 10, 100), width: 30, label_width: 10, gradient: true, style: :rounded)}                    ║",
      "║  #{Droodotfoo.AsciiChart.percent_bar("Memory", min(summary.current_memory * 2, 100), width: 30, label_width: 10, gradient: true, style: :rounded)}                    ║",
      "║                                                                              ║",
      "╚══════════════════════════════════════════════════════════════════════════════╝"
    ]

    content_lines
    |> Enum.take(min(length(content_lines), 22))
    |> then(&draw_box_at(buffer, &1, 0, 1))
  end

  defp draw_content(buffer, :ls, _state) do
    ls_lines = [
      "┌─ Directory Listing ──────────────────────────┐",
      "│                                              │",
      "│ drwxr-xr-x  ./                               │",
      "│ -rw-r--r--  home                             │",
      "│ -rw-r--r--  projects                         │",
      "│ -rw-r--r--  skills                           │",
      "│ -rw-r--r--  experience                       │",
      "│ -rw-r--r--  contact                          │",
      "│                                              │",
      "│ Use ':cat <section>' to view content         │",
      "│                                              │",
      "└──────────────────────────────────────────────┘"
    ]

    draw_box_at(buffer, ls_lines, 35, 13)
  end

  defp draw_content(buffer, :terminal, state) do
    # Draw terminal output with actual content
    # Split output into lines and format for display
    output_lines =
      state.terminal_output
      |> String.split("\n")
      # Show last 8 lines to leave room for prompt
      |> Enum.take(-8)
      |> Enum.map(&format_terminal_line/1)

    # Pad with empty lines if needed
    padded_lines = output_lines ++ List.duplicate("", max(0, 8 - length(output_lines)))

    # Build the terminal display
    terminal_lines = [
      "┌─ Terminal ────────────────────────────────────┐",
      "│                                               │"
    ]

    middle_lines =
      padded_lines
      |> Enum.map(fn line ->
        "│ " <> String.pad_trailing(line, 45) <> " │"
      end)

    prompt_with_cursor = Map.get(state, :prompt, "") <> "_"

    footer_lines = [
      "│ " <> String.pad_trailing(prompt_with_cursor, 45) <> " │",
      "│                                               │",
      "└───────────────────────────────────────────────┘"
    ]

    all_lines = terminal_lines ++ middle_lines ++ footer_lines

    all_lines
    |> Enum.take(min(length(all_lines), 35 - 13))
    |> then(&draw_box_at(buffer, &1, 35, 13))
  end

  defp draw_content(buffer, :spotify, state) do
    alias Droodotfoo.Spotify.Manager

    # Check auth status
    auth_status = Manager.auth_status()

    spotify_lines = case auth_status do
      :authenticated ->
        draw_spotify_view(state)

      _ ->
        draw_spotify_auth_prompt()
    end

    draw_box_at(buffer, spotify_lines, 35, 13)
  end

  defp draw_content(buffer, :web3, state) do
    # Check wallet connection status
    web3_lines = if state.web3_wallet_connected do
      draw_web3_connected(state)
    else
      draw_web3_connect_prompt(state)
    end

    draw_box_at(buffer, web3_lines, 35, 13)
  end

  defp draw_content(buffer, _, _state), do: buffer

  # Spotify helper functions

  defp draw_spotify_auth_prompt do
    [
      "┌─ Spotify ───────────────────────────────────────────────────────────┐",
      "│                                                                     │",
      "│  Status: [NOT AUTHENTICATED]                                       │",
      "│                                                                     │",
      "│  To use Spotify features, authenticate:                            │",
      "│                                                                     │",
      "│  ┌──────────────────────────────────────────────────────────────┐  │",
      "│  │  1. Run: :spotify auth                                       │  │",
      "│  │     - Opens browser automatically                            │  │",
      "│  │     - Log in with your Spotify account                       │  │",
      "│  │     - Grant access to droo.foo                               │  │",
      "│  └──────────────────────────────────────────────────────────────┘  │",
      "│                                                                     │",
      "│  Or visit manually:                                                 │",
      "│    http://localhost:4000/auth/spotify                              │",
      "│                                                                     │",
      "│  Features available after auth:                                    │",
      "│    [>] Now Playing Display with real-time progress                 │",
      "│    [>] Playback Controls (play/pause/next/prev/volume)             │",
      "│    [>] Playlist Browser                                            │",
      "│    [>] Device Control                                              │",
      "│    [>] Search & Play                                               │",
      "│                                                                     │",
      "│  Press 'a' to start authentication                                 │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]
  end

  defp draw_spotify_dashboard do
    alias Droodotfoo.Spotify.Manager

    # Get current playback
    current_track = Manager.current_track()
    playback = Manager.playback_state()
    loading = Manager.loading?()
    last_error = Manager.last_error()

    # Determine playback state icon
    state_icon = cond do
      loading -> "[~]"
      playback && playback.is_playing -> "[>]"
      playback && !playback.is_playing -> "[||]"
      true -> "[--]"
    end

    # Connection status
    status_line = cond do
      loading ->
        "│  Status: [LOADING...]                                         │"

      last_error ->
        error_msg = String.slice(to_string(last_error), 0..40)
        "│  Status: [ERROR: #{String.pad_trailing(error_msg, 40)}] │"

      true ->
        "│  Status: [CONNECTED]                                          │"
    end

    now_playing = case current_track do
      %{name: name, artists: artists} ->
        artist_names = Enum.map_join(artists, ", ", & &1["name"])
        truncated_name = String.slice(name, 0..40)
        truncated_artist = String.slice(artist_names, 0..40)

        # Build progress bar if we have playback data
        progress_bar = build_progress_bar(playback)

        [
          "│  Now Playing: #{state_icon}                                         │",
          "│    #{String.pad_trailing(truncated_name, 63)}│",
          "│    #{String.pad_trailing(truncated_artist, 63)}│",
          "│                                                                     │",
          "│  #{progress_bar} │"
        ]

      _ ->
        [
          "│  Now Playing: #{state_icon} --                                      │",
          "│                                                                     │"
        ]
    end

    # Playback controls
    controls = [
      "│                                                                     │",
      "│      [<< PREV]       [SPACE PLAY/PAUSE]       [NEXT >>]            │"
    ]

    # Last update timestamp
    last_update_line = case Manager.playback_state() do
      %{timestamp: ts} when not is_nil(ts) ->
        time_ago = format_time_ago(ts)
        "│  Last refresh: #{String.pad_trailing(time_ago, 50)}│"

      _ ->
        "│  Last refresh: --                                              │"
    end

    header = [
      "┌─ Spotify ───────────────────────────────────────────────────────────┐",
      "│                                                                     │",
      status_line,
      last_update_line,
      "│                                                                     │"
    ]

    buttons = [
      "│                                                                     │",
      "│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │",
      "│  │ [P]LAYLISTS  │  │  [D]EVICES   │  │   [S]EARCH   │             │",
      "│  └──────────────┘  └──────────────┘  └──────────────┘             │",
      "│                                                                     │",
      "│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │",
      "│  │ [C]ONTROLS   │  │  [M]COMPACT  │  │  [R]EFRESH   │             │",
      "│  └──────────────┘  └──────────────┘  └──────────────┘             │",
      "│                                                                     │",
      "│  Quick: [SPACE]Play/Pause [[]Back []]Next [=/-]Volume              │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    header ++ now_playing ++ controls ++ buttons
  end

  defp draw_spotify_view(state) do
    case Map.get(state, :spotify_mode, :dashboard) do
      :dashboard -> draw_spotify_dashboard()
      :playlists -> draw_spotify_playlists()
      :devices -> draw_spotify_devices()
      :search -> draw_spotify_search()
      :controls -> draw_spotify_controls()
      _ -> draw_spotify_dashboard()
    end
  end

  defp draw_spotify_playlists do
    alias Droodotfoo.Spotify.Manager

    playlists = Manager.playlists() || []

    header = [
      "┌─ Spotify > Playlists ───────────────────────────────────────────────┐",
      "│                                                                     │"
    ]

    playlist_lines = if Enum.empty?(playlists) do
      [
        "│  No playlists found.                                               │",
        "│                                                                     │",
        "│  Loading playlists...                                              │"
      ]
    else
      playlists
      |> Enum.take(15)
      |> Enum.map(fn playlist ->
        name = String.slice(playlist["name"] || "Untitled", 0..55)
        track_count = playlist["tracks"]["total"] || 0
        info = "#{track_count} tracks"
        "│  > #{String.pad_trailing(name, 50)} #{String.pad_trailing(info, 10)}│"
      end)
    end

    footer = [
      "│                                                                     │",
      "│  [ESC] Back to Dashboard  [ENTER] Play Playlist                    │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    header ++ playlist_lines ++ footer
  end

  defp draw_spotify_devices do
    alias Droodotfoo.Spotify.Manager

    playback = Manager.playback_state()
    current_device = playback && playback.device

    header = [
      "┌─ Spotify > Devices ─────────────────────────────────────────────────┐",
      "│                                                                     │"
    ]

    device_lines = if current_device do
      device_name = String.slice(current_device["name"] || "Unknown", 0..40)
      device_type = String.slice(current_device["type"] || "Unknown", 0..15)
      volume = current_device["volume_percent"] || 0
      is_active = if current_device["is_active"], do: "[ACTIVE]", else: ""

      [
        "│  Current Device:                                                   │",
        "│    #{String.pad_trailing(device_name, 63)}│",
        "│    Type: #{String.pad_trailing(device_type, 56)}│",
        "│    Volume: #{String.pad_trailing("#{volume}%", 54)}│",
        "│    #{String.pad_trailing(is_active, 63)}│"
      ]
    else
      [
        "│  No active device found.                                           │",
        "│                                                                     │",
        "│  Please start playback on a Spotify device.                        │"
      ]
    end

    footer = [
      "│                                                                     │",
      "│  [ESC] Back to Dashboard  [=/-] Adjust Volume                      │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    header ++ device_lines ++ footer
  end

  defp draw_spotify_search do
    header = [
      "┌─ Spotify > Search ──────────────────────────────────────────────────┐",
      "│                                                                     │",
      "│  Search Mode                                                        │",
      "│                                                                     │",
      "│  Enter search query:                                                │",
      "│  ┌──────────────────────────────────────────────────────────────┐  │",
      "│  │ _                                                            │  │",
      "│  └──────────────────────────────────────────────────────────────┘  │",
      "│                                                                     │",
      "│  Results will appear here...                                        │",
      "│                                                                     │",
      "│  Search for:                                                        │",
      "│    - Tracks                                                         │",
      "│    - Albums                                                         │",
      "│    - Artists                                                        │",
      "│    - Playlists                                                      │",
      "│                                                                     │",
      "│  [ESC] Back to Dashboard  [ENTER] Search                           │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    header
  end

  defp draw_spotify_controls do
    alias Droodotfoo.Spotify.Manager

    current_track = Manager.current_track()
    playback = Manager.playback_state()

    state_icon = cond do
      playback && playback.is_playing -> "[>]"
      playback && !playback.is_playing -> "[||]"
      true -> "[--]"
    end

    progress_bar = build_progress_bar(playback)

    now_playing = case current_track do
      %{name: name, artists: artists} ->
        artist_names = Enum.map_join(artists, ", ", & &1["name"])
        truncated_name = String.slice(name, 0..50)
        truncated_artist = String.slice(artist_names, 0..50)

        [
          "│  #{state_icon} #{String.pad_trailing(truncated_name, 61)}│",
          "│    by #{String.pad_trailing(truncated_artist, 59)}│"
        ]

      _ ->
        [
          "│  #{state_icon} No track playing                                          │",
          "│                                                                     │"
        ]
    end

    header = [
      "┌─ Spotify > Playback Controls ───────────────────────────────────────┐",
      "│                                                                     │"
    ]

    controls = [
      "│                                                                     │",
      "│  #{progress_bar} │",
      "│                                                                     │",
      "│                  Playback Controls                                  │",
      "│                                                                     │",
      "│              ┌──────────────────────────────┐                       │",
      "│              │   [[] PREVIOUS  [SPACE] PLAY │                       │",
      "│              │   []] NEXT     [=/-] VOLUME  │                       │",
      "│              └──────────────────────────────┘                       │",
      "│                                                                     │"
    ]

    footer = [
      "│  [ESC] Back to Dashboard  [R] Refresh                              │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    header ++ now_playing ++ controls ++ footer
  end

  defp build_progress_bar(playback) do
    case playback do
      %{progress_ms: progress, duration_ms: duration} when progress > 0 and duration > 0 ->
        # Calculate progress percentage
        percentage = progress / duration
        bar_width = 50
        filled = round(percentage * bar_width)
        empty = bar_width - filled

        # Build bar with block characters
        bar = String.duplicate("█", filled) <> String.duplicate("░", empty)

        # Format time
        current_time = format_time(progress)
        total_time = format_time(duration)

        time_str = "#{current_time} / #{total_time}"
        padding = String.duplicate(" ", max(0, 67 - String.length(bar) - String.length(time_str) - 2))

        "#{bar}  #{time_str}#{padding}"

      _ ->
        # No playback data
        String.pad_trailing("--:-- / --:--", 67)
    end
  end

  defp format_time(ms) when is_integer(ms) do
    total_seconds = div(ms, 1000)
    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(seconds), 2, "0")}"
  end

  defp format_time(_), do: "--:--"

  defp format_time_ago(timestamp) when is_integer(timestamp) do
    now = System.system_time(:millisecond)
    diff_ms = now - timestamp
    diff_seconds = div(diff_ms, 1000)

    cond do
      diff_seconds < 10 -> "just now"
      diff_seconds < 60 -> "#{diff_seconds}s ago"
      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        "#{minutes}m ago"
      true ->
        hours = div(diff_seconds, 3600)
        "#{hours}h ago"
    end
  end

  defp format_time_ago(_), do: "never"

  # Project view helper functions

  # Draw the project list view with thumbnails
  defp draw_project_list(buffer, state) do
    projects = Droodotfoo.Projects.all()
    selected_idx = Map.get(state, :selected_project_index, 0)

    # Header
    header_lines = [
      "┌─ Project Showcase ──────────────────────────────────────────────────┐",
      "│                                                                     │",
      "│  Use ↑↓ to navigate, Enter to view details, Backspace to return    │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    buffer = draw_box_at(buffer, header_lines, 35, 13)

    # Draw projects in a grid (2 columns)
    y_offset = 13 + length(header_lines)

    projects
    |> Enum.with_index()
    |> Enum.chunk_every(2)
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {row_projects, row_idx}, acc_buffer ->
      draw_project_row(acc_buffer, row_projects, selected_idx, 35, y_offset + row_idx * 12)
    end)
  end

  # Draw a row of projects (up to 2 projects side by side)
  defp draw_project_row(buffer, row_projects, selected_idx, x_offset, y_offset) do
    row_projects
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {{project, proj_idx}, col_idx}, acc_buffer ->
      x = x_offset + col_idx * 37
      draw_project_card(acc_buffer, project, proj_idx == selected_idx, x, y_offset)
    end)
  end

  # Draw a single project card with thumbnail
  defp draw_project_card(buffer, project, is_selected, x, y) do
    indicator = if is_selected, do: ">", else: " "
    border_char = if is_selected, do: "═", else: "─"
    status_text = Droodotfoo.Projects.status_indicator(project.status)

    # Build the card
    card_lines = [
      "┌#{String.duplicate(border_char, 33)}┐",
      "│ #{indicator} #{String.pad_trailing(project.name, 29)} │",
      "│   #{String.pad_trailing(status_text, 29)} │"
    ]

    # Add ASCII thumbnail
    thumbnail_lines =
      Enum.map(project.ascii_thumbnail, fn line ->
        "│ #{String.pad_trailing(line, 31)} │"
      end)

    # Add tagline
    tagline_lines = [
      "│#{String.duplicate(" ", 33)}│",
      "│ #{String.pad_trailing(project.tagline, 31)} │",
      "└#{String.duplicate(border_char, 33)}┘"
    ]

    lines = card_lines ++ thumbnail_lines ++ tagline_lines

    draw_box_at(buffer, lines, x, y)
  end

  # Draw the detailed project view
  defp draw_project_detail(buffer, state) do
    projects = Droodotfoo.Projects.all()
    selected_idx = Map.get(state, :selected_project_index, 0)
    project = Enum.at(projects, selected_idx)

    if project do
      detail_lines = build_project_detail_lines(project)
      draw_box_at(buffer, detail_lines, 35, 13)
    else
      # Fallback if no project selected
      draw_project_list(buffer, %{state | project_detail_view: false})
    end
  end

  # Build the detailed view lines for a project
  defp build_project_detail_lines(project) do
    status_text = Droodotfoo.Projects.status_indicator(project.status)

    [
      "┌─ #{project.name} ────────────────────────────────────────────────────┐",
      "│                                                                     │",
      "│  #{String.pad_trailing(project.tagline, 67)}│",
      "│  Status: #{String.pad_trailing(status_text, 58)}│",
      "│                                                                     │"
    ] ++
      wrap_text(project.description, 67) ++
      [
        "│                                                                     │",
        "│  Tech Stack:                                                        │"
      ] ++
      build_tech_stack_lines(project.tech_stack) ++
      [
        "│                                                                     │",
        "│  Highlights:                                                        │"
      ] ++
      build_highlights_lines(project.highlights) ++
      build_links_section(project) ++
      [
        "│                                                                     │",
        "│  Press Backspace to return to project list                         │",
        "└─────────────────────────────────────────────────────────────────────┘"
      ]
  end

  defp wrap_text(text, width) do
    text
    |> String.split(" ")
    |> Enum.reduce({[], ""}, fn word, {lines, current_line} ->
      test_line = if current_line == "", do: word, else: current_line <> " " <> word

      if String.length(test_line) <= width - 4 do
        {lines, test_line}
      else
        {lines ++ ["│  #{String.pad_trailing(current_line, width)}│"], word}
      end
    end)
    |> then(fn {lines, last_line} ->
      if last_line != "" do
        lines ++ ["│  #{String.pad_trailing(last_line, width)}│"]
      else
        lines
      end
    end)
  end

  defp build_tech_stack_lines(tech_stack) do
    tech_text = Enum.join(tech_stack, ", ")
    wrap_text("  " <> tech_text, 67)
  end

  defp build_highlights_lines(highlights) do
    highlights
    |> Enum.flat_map(fn highlight ->
      ["│  • #{String.pad_trailing(highlight, 65)}│"]
    end)
  end

  defp build_links_section(project) do
    lines = ["│                                                                     │"]

    lines =
      if project.github_url do
        lines ++ ["│  GitHub: #{String.pad_trailing(project.github_url, 58)}│"]
      else
        lines
      end

    lines =
      if project.demo_url do
        lines ++ ["│  Demo:   #{String.pad_trailing(project.demo_url, 58)}│"]
      else
        lines
      end

    if project.live_demo do
      lines ++ ["│  ✓ Live demo available!                                             │"]
    else
      lines
    end
  end

  # Terminal view helper functions

  defp format_terminal_line(line) do
    # Truncate long lines to fit
    String.slice(line, 0..44)
  end

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
      "║                          KEYBOARD SHORTCUTS HELP                          ║",
      "╠═══════════════════════════════════════════════════════════════════════════╣",
      "║                                                                           ║",
      "║  NAVIGATION                                                               ║",
      "║  ↑ ↓ ← →           Navigate menu items (arrow keys)                       ║",
      "║  Enter             Select current menu item                               ║",
      "║  1-5               Jump to menu item by number                            ║",
      "║  Click             Click any menu item to select                          ║",
      "║                                                                           ║",
      "║  VIM MODE (currently: #{String.pad_trailing(vim_status, 3)})                                                ║",
      "║  v                 Toggle vim mode on/off                                 ║",
      if(vim_mode,
        do: "║  h j k l           Navigate (left/down/up/right) when vim mode is on       ║",
        else: "║  h j k l           (Disabled - enable vim mode with 'v')                  ║"
      ),
      if(vim_mode,
        do: "║  g / G             Jump to top / bottom when vim mode is on               ║",
        else: "║  g / G             (Disabled - enable vim mode with 'v')                  ║"
      ),
      "║                                                                           ║",
      "║  COMMANDS                                                                 ║",
      "║  :                 Enter command mode                                     ║",
      "║  /                 Enter search mode                                      ║",
      "║  Esc               Exit command/search mode                               ║",
      "║                                                                           ║",
      "║  HELP                                                                     ║",
      "║  ?                 Toggle this help modal                                 ║",
      "║                                                                           ║",
      "╚═══════════════════════════════════════════════════════════════════════════╝"
    ]

    # Center the modal (start at column 2, row 0)
    draw_box_at(buffer, help_lines, 2, 0)
  end

  # Web3 helper functions

  defp draw_web3_connect_prompt(state) do
    connecting = state.web3_connecting

    status_line = if connecting do
      "│  Status: [CONNECTING...]                                        │"
    else
      "│  Status: [NOT CONNECTED]                                        │"
    end

    [
      "┌─ Web3 Wallet ───────────────────────────────────────────────────┐",
      "│                                                                     │",
      status_line,
      "│                                                                     │",
      "│  Connect your wallet to access Web3 features:                      │",
      "│                                                                     │",
      "│  ┌──────────────────────────────────────────────────────────────┐  │",
      "│  │  Supported Wallets:                                          │  │",
      "│  │    [>] MetaMask                                              │  │",
      "│  │    [>] WalletConnect (coming soon)                           │  │",
      "│  │    [>] Coinbase Wallet (coming soon)                         │  │",
      "│  └──────────────────────────────────────────────────────────────┘  │",
      "│                                                                     │",
      "│  Commands:                                                          │",
      "│    :web3 connect   - Connect MetaMask wallet                       │",
      "│    :wallet         - Alias for :web3 connect                       │",
      "│    :w3             - Short alias                                   │",
      "│                                                                     │",
      "│  Features available after connection:                               │",
      "│    [>] ENS Name Resolution (vitalik.eth)                           │",
      "│    [>] NFT Gallery Viewer                                          │",
      "│    [>] Token Balances (ERC-20)                                     │",
      "│    [>] Transaction History                                         │",
      "│    [>] Smart Contract Interaction                                  │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]
  end

  defp draw_web3_connected(state) do
    address = state.web3_wallet_address || "Unknown"
    chain_id = state.web3_chain_id || 1

    # Abbreviate address (0x1234...5678)
    abbreviated_address = abbreviate_address(address)

    # Get network name
    network_name = get_network_name(chain_id)

    # Try to resolve ENS name (if on mainnet)
    ens_lines = if chain_id == 1 and address != "Unknown" do
      case Droodotfoo.Web3.Manager.resolve_ens(address) do
        {:ok, ens_name} when ens_name != address ->
          [
            "│  │                                                              │  │",
            "│  │  ENS Name:                                                   │  │",
            "│  │    #{String.pad_trailing(ens_name, 56)}│  │"
          ]

        _ ->
          []
      end
    else
      []
    end

    [
      "┌─ Web3 Wallet ───────────────────────────────────────────────────┐",
      "│                                                                     │",
      "│  Status: [CONNECTED]                                                │",
      "│                                                                     │",
      "│  ┌──────────────────────────────────────────────────────────────┐  │",
      "│  │  Wallet Address:                                             │  │",
      "│  │    #{String.pad_trailing(abbreviated_address, 56)}│  │"
    ] ++
    ens_lines ++
    [
      "│  │                                                              │  │",
      "│  │  Network:                                                    │  │",
      "│  │    #{String.pad_trailing(network_name, 56)}│  │",
      "│  └──────────────────────────────────────────────────────────────┘  │",
      "│                                                                     │",
      "│  Available Commands:                                                │",
      "│    :web3 disconnect   - Disconnect wallet                          │",
      "│    :ens <name>        - Resolve ENS name                           │",
      "│    :nft list          - View your NFTs                             │",
      "│    :tokens            - View token balances                        │",
      "│    :tx history        - View transaction history                   │",
      "│                                                                     │",
      "│  Quick Actions:                                                     │",
      "│    [D]isconnect  [E]NS  [N]FTs  [T]okens  [H]istory               │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]
  end

  defp abbreviate_address(address) when is_binary(address) do
    if String.length(address) > 12 do
      prefix = String.slice(address, 0..5)
      suffix = String.slice(address, -4..-1)
      "#{prefix}...#{suffix}"
    else
      address
    end
  end

  defp abbreviate_address(_), do: "Unknown"

  defp get_network_name(1), do: "Ethereum Mainnet"
  defp get_network_name(5), do: "Goerli Testnet"
  defp get_network_name(11155111), do: "Sepolia Testnet"
  defp get_network_name(137), do: "Polygon Mainnet"
  defp get_network_name(80001), do: "Mumbai Testnet"
  defp get_network_name(42161), do: "Arbitrum One"
  defp get_network_name(10), do: "Optimism"
  defp get_network_name(8453), do: "Base"
  defp get_network_name(chain_id), do: "Chain ID: #{chain_id}"
end
