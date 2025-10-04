defmodule Droodotfoo.Raxol.Renderer do
  @moduledoc """
  Handles all rendering logic for the terminal UI.
  """

  alias Droodotfoo.TerminalBridge
  alias Droodotfoo.CursorTrail

  @width 110
  @height 35

  @doc """
  Main render function that orchestrates all drawing operations
  """
  def render(state) do
    buffer = TerminalBridge.create_blank_buffer(@width, @height)

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
      {" STL Viewer              ", :stl_viewer, 5}
    ]

    buffer = TerminalBridge.draw_box(buffer, 0, nav_y, 30, 9, :single)
    buffer = TerminalBridge.write_at(buffer, 2, nav_y, "─ Navigation ──────────────")

    nav_items
    |> Enum.reduce(buffer, fn {text, _key, idx}, buf ->
      y_pos = nav_y + 2 + idx
      cursor = if idx == cursor_y, do: ">", else: " "
      TerminalBridge.write_at(buf, 2, y_pos, cursor <> text)
    end)
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
        if trail_pos.row >= 0 and trail_pos.row < @height and
             trail_pos.col >= 0 and trail_pos.col < @width do
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
    y_pos = @height - 2

    # Left side: current section breadcrumb
    section_name = format_section_name(state.current_section)
    breadcrumb = " #{section_name}"

    # Middle: vim mode and command mode indicators
    vim_indicator = if Map.get(state, :vim_mode, false), do: " VIM", else: ""
    cmd_indicator = if state.command_mode, do: " CMD", else: ""
    search_indicator = if state.command_mode && String.starts_with?(state.command_buffer, "search "), do: " SEARCH", else: ""

    # Right side: time and connection status
    {:ok, now} = DateTime.now("Etc/UTC")
    time_str = Calendar.strftime(now, "%H:%M:%S")
    right_side = "#{time_str} | LIVE "

    # Calculate spacing
    middle_content = vim_indicator <> cmd_indicator <> search_indicator
    left_section = breadcrumb
    right_section = right_side

    # Build status bar with proper spacing (total width is 110)
    total_width = @width
    used_width = String.length(left_section) + String.length(middle_content) + String.length(right_section)
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
    y_pos = @height - 1
    prompt = ":" <> state.command_buffer <> "_"
    TerminalBridge.write_at(buffer, 0, y_pos, prompt)
  end

  defp draw_command_line(buffer, _state) do
    # Show hint when not in command mode
    y_pos = @height - 1
    hint = "? help • : cmd • / search"
    TerminalBridge.write_at(buffer, 0, y_pos, hint)
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

  defp draw_content(buffer, :projects, _state) do
    project_lines = [
      "┌─ Projects ──────────────────────────────────────────────────────────┐",
      "│                                                                     │",
      "│  ▪ Terminal droo.foo System                                         │",
      "│    This droo.foo! Built with Raxol terminal framework               │",
      "│    [Elixir] [Phoenix] [LiveView] [60fps]                            │",
      "│                                                                     │",
      "│  ▪ Real-time Collaboration Platform                                 │",
      "│    WebRTC-based pair programming tool with live code sharing        │",
      "│    [Elixir] [Phoenix Channels] [WebRTC]                             │",
      "│                                                                     │",
      "│  ▪ Distributed Event Processing                                     │",
      "│    High-throughput event stream processor handling millions/day     │",
      "│    [Elixir] [Broadway] [Kafka] [ClickHouse]                         │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    draw_box_at(buffer, project_lines, 35, 13)
  end

  defp draw_content(buffer, :skills, _state) do
    skills_lines = [
      "┌─ Technical Skills ──────────────────────────────────────────────────┐",
      "│                                                                     │",
      "│  Languages:                                                         │",
      "│  ██████████████████████████████████████░░░░  Elixir          90%    │",
      "│  ████████████████████████████████████░░░░░░  Phoenix         85%    │",
      "│  ██████████████████████████████░░░░░░░░░░░░  JavaScript      75%    │",
      "│  ████████████████████████████░░░░░░░░░░░░░░  TypeScript      70%    │",
      "│                                                                     │",
      "│  Frameworks & Libraries:                                            │",
      "│  • Phoenix, LiveView, Ecto, Broadway                                │",
      "│  • React, Vue.js, Node.js, Express                                  │",
      "│  • GraphQL, REST APIs, WebSockets                                   │",
      "│                                                                     │",
      "│  Infrastructure: Docker, K8s, AWS, Fly.io, PostgreSQL, Redis        │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
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
      "┌─ Contact ───────────────────────────────────────────────────────────┐",
      "│                                                                     │",
      "│  Let's connect:                                                     │",
      "│                                                                     │",
      "│  ▪ Email:     drew@axol.io                                          │",
      "│  ▪ GitHub:    github.com/hydepwns                                   │",
      "│  ▪ LinkedIn:  linkedin.com/in/drew-hiro                             │",
      "│  ▪ X/Twitter: @MF_DROO                                              │",
      "│                                                                     │",
      "│  ┌──────────────────────────────────────────────────────────────┐   │",
      "│  │  Available for consulting on Elixir, Phoenix, LiveView, and  │   │",
      "│  │  distributed systems architecture                            │   │",
      "│  └──────────────────────────────────────────────────────────────┘   │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
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

  defp draw_content(buffer, :stl_viewer, state) do
    viewer_state = state.stl_viewer_state || Droodotfoo.StlViewerState.new()
    info_lines = Droodotfoo.StlViewerState.format_model_info(viewer_state)
    status = Droodotfoo.StlViewerState.status_message(viewer_state)

    # Build the viewer HUD overlay
    viewer_lines = [
      "┌─ STL Viewer ──────────────────────────────────────────────────┐",
      "│                                                               │",
      "│  #{String.pad_trailing(status, 60)} │"
    ] ++
    Enum.map(info_lines, fn line ->
      "│  #{String.pad_trailing(line, 60)} │"
    end) ++
    [
      "│                                                               │",
      "│  Controls: j/k rotate • h/l zoom • r reset • m mode • q quit │",
      "│                                                               │",
      "│  ┌─ 3D Viewport ───────────────────────────────────────────┐ │",
      "│  │                                                          │ │",
      "│  │                                                          │ │",
      "│  │                                                          │ │",
      "│  │            [WebGL Canvas Renders Here]                   │ │",
      "│  │                                                          │ │",
      "│  │                                                          │ │",
      "│  │                                                          │ │",
      "│  └──────────────────────────────────────────────────────────┘ │",
      "│                                                               │",
      "└───────────────────────────────────────────────────────────────┘"
    ]

    draw_box_at(buffer, viewer_lines, 35, 13)
  end

  defp draw_content(buffer, :export_markdown, _state) do
    export_lines = [
      "┌─ Export: Markdown ────────────────────────────┐",
      "│                                               │",
      "│ # Droo - Senior Software Engineer             │",
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

          "│#{marker}[#{String.pad_trailing(section, 10)}] #{String.pad_trailing(line, 30)}│"
        end)
      else
        ["│ No results found                             │"]
      end

    footer = [
      "├───────────────────────────────────────────────┤",
      "│ n/N: next/prev  --fuzzy --exact --regex      │",
      "│ Press ESC to exit search                     │",
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
      "║  ┌─────────────────┐          ┌──────────────┐         ┌─────────────────┐  ║",
      "║  │ #{String.pad_trailing(render_sparkline, 15)} │          │ #{String.pad_trailing(memory_sparkline, 12)} │         │    #{String.pad_trailing(req_rate, 13)}│  ║",
      "║  └─────────────────┘          └──────────────┘         └─────────────────┘  ║",
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
      "║  #{Droodotfoo.AsciiChart.percent_bar("Render", min(summary.avg_render_time * 10, 100), width: 30, label_width: 10)}                    ║",
      "║  #{Droodotfoo.AsciiChart.percent_bar("Memory", min(summary.current_memory * 2, 100), width: 30, label_width: 10)}                    ║",
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

  defp draw_content(buffer, _, _state), do: buffer

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
    vim_mode = Map.get(state, :vim_mode, false)
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
end
