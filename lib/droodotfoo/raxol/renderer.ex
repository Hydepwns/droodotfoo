defmodule Droodotfoo.Raxol.Renderer do
  @moduledoc """
  Handles all rendering logic for the terminal UI.
  """

  alias Droodotfoo.TerminalBridge
  alias Droodotfoo.CursorTrail

  @width 80
  @height 24

  @doc """
  Main render function that orchestrates all drawing operations
  """
  def render(state) do
    buffer = TerminalBridge.create_blank_buffer(@width, @height)

    buffer
    |> draw_ascii_logo()
    |> draw_navigation(state.cursor_y)
    |> draw_cursor_trail(state)
    |> draw_content(state.current_section, state)
    |> draw_command_line(state)
  end

  defp draw_ascii_logo(buffer) do
    logo_lines = [
      "╭────────────────────────────────────────────────────────────╮",
      "│                                                            │",
      "│           ██████╗ ██████╗  ██████╗  ██████╗                │",
      "│           ██╔══██╗██╔══██╗██╔═══██╗██╔═══██╗               │",
      "│           ██║  ██║██████╔╝██║   ██║██║   ██║               │",
      "│           ██║  ██║██╔══██╗██║   ██║██║   ██║               │",
      "│           ██████╔╝██║  ██║╚██████╔╝╚██████╔╝               │",
      "│           ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝                │",
      "│                                                            │",
      "╰────────────────────────────────────────────────────────────╯"
    ]

    logo_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, y}, buf ->
      TerminalBridge.write_at(buf, 0, y, line)
    end)
  end

  defp draw_navigation(buffer, cursor_y) do
    nav_y = 13

    nav_items = [
      {" Home                    ", :home, 0},
      {" Projects                ", :projects, 1},
      {" Skills                  ", :skills, 2},
      {" Experience              ", :experience, 3},
      {" Contact                 ", :contact, 4}
    ]

    buffer = TerminalBridge.draw_box(buffer, 0, nav_y, 30, 12, :single)
    buffer = TerminalBridge.write_at(buffer, 2, nav_y, "─ Navigation ──────────────")

    nav_items
    |> Enum.reduce(buffer, fn {text, _key, idx}, buf ->
      y_pos = nav_y + 2 + idx
      cursor = if idx == cursor_y, do: "▶", else: "▷"
      TerminalBridge.write_at(buf, 2, y_pos, cursor <> text)
    end)
    |> draw_navigation_help(nav_y + 8)
  end

  defp draw_navigation_help(buffer, y) do
    buffer
    |> TerminalBridge.write_at(2, y, " Commands:")
    |> TerminalBridge.write_at(2, y + 1, " j/k - Navigate")
    |> TerminalBridge.write_at(2, y + 2, " Enter - Select")
    |> TerminalBridge.write_at(2, y + 3, " t/T - Trail on/clear")
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
              color: trail_pos.style[:color] || "white",
              background: nil
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

  defp draw_command_line(buffer, %{command_mode: true} = state) do
    # Draw command input line at bottom
    y_pos = @height - 1
    prompt = ":" <> state.command_buffer <> "_"
    TerminalBridge.write_at(buffer, 0, y_pos, prompt)
  end

  defp draw_command_line(buffer, _state) do
    # Show hint when not in command mode
    y_pos = @height - 1
    hint = "Press ':' for commands, '/' for search, 'hjkl' to navigate"
    TerminalBridge.write_at(buffer, 0, y_pos, hint)
  end

  # Content drawing functions
  defp draw_content(buffer, :home, _state) do
    about_lines = [
      "┌─ About ───────────────────────────┐",
      "│                                   │",
      "│ Multi Disciplinary Engineer       │",
      "│ expertise in distributed systems  │",
      "│ and real-time apps.               │",
      "│                                   │",
      "│ • 5+ years building scalable      │",
      "│ • Elixir, Phoenix, LiveView       │",
      "│ • Terminal UI and CLI enthusiast  │",
      "│                                   │",
      "└───────────────────────────────────┘"
    ]

    recent_lines = [
      "",
      "┌─ Recent Activity ─────────────────┐",
      "│                                   │",
      "│ 2025-09  Terminal droo.foo        │",
      "│ 2025-08  Data pipeline            │",
      "│ 2025-07  Elixir telemetry         │",
      "│                                   │",
      "└───────────────────────────────────┘"
    ]

    # Draw About section
    buffer =
      about_lines
      |> Enum.with_index()
      |> Enum.reduce(buffer, fn {line, idx}, buf ->
        TerminalBridge.write_at(buf, 32, 2 + idx, line)
      end)

    # Draw Recent Activity section (fits within 24 rows)
    recent_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, 32, 2 + length(about_lines) + idx, line)
    end)
  end

  defp draw_content(buffer, :projects, _state) do
    project_lines = [
      "┌─ Projects ───────────────────────────────────┐",
      "│                                              │",
      "│ ▪ Terminal droo.foo System                   │",
      "│   This droo.foo! Built with Raxol            │",
      "│   [Elixir] [Phoenix] [LiveView] [60fps]      │",
      "│                                              │",
      "│ ▪ Real-time Collaboration Platform           │",
      "│   WebRTC-based pair programming tool         │",
      "│   [Elixir] [Phoenix Channels] [WebRTC]       │",
      "│                                              │",
      "│ ▪ Distributed Event Processing               │",
      "│   High-throughput event stream processor     │",
      "│   [Elixir] [Broadway] [Kafka] [ClickHouse]   │",
      "│                                              │",
      "└──────────────────────────────────────────────┘"
    ]

    project_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, 32, 13 + idx, line)
    end)
  end

  defp draw_content(buffer, :skills, _state) do
    skills_lines = [
      "┌─ Technical Skills ────────────────────────────┐",
      "│                                               │",
      "│ Languages:                                    │",
      "│ ██████████████████████████░░  Elixir    90%   │",
      "│ ████████████████████████░░░░  Phoenix   85%   │",
      "│ ████████████████████░░░░░░░░  JavaScript 75%  │",
      "│ ██████████████████░░░░░░░░░░  TypeScript 70%  │",
      "│                                               │",
      "│ Frameworks & Libraries:                       │",
      "│ • Phoenix, LiveView, Ecto, Broadway           │",
      "│ • React, Vue.js, Node.js, Express             │",
      "│ • GraphQL, REST APIs, WebSockets              │",
      "│                                               │",
      "│ Infrastructure: Docker, K8s, AWS, Fly.io      │",
      "│                                               │",
      "└───────────────────────────────────────────────┘"
    ]

    skills_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, 32, 13 + idx, line)
    end)
  end

  defp draw_content(buffer, :experience, _state) do
    exp_lines = [
      "┌─ Experience ──────────────────────────────────┐",
      "│                                               │",
      "│ ▪ Senior Backend Engineer                     │",
      "│   axol.io | 2023 - Present                    │",
      "│   • Built event-driven microservices          │",
      "│   • Reduced API response time by 70%          │",
      "│                                               │",
      "│ ▪ Elixir Developer                            │",
      "│   FinTech Startup | 2019 - 2021               │",
      "│   • Designed real-time payment processing     │",
      "│   • Handled 1M+ transactions daily            │",
      "│                                               │",
      "│ ▪ Full Stack Developer                        │",
      "│   Digital Agency | 2017 - 2019                │",
      "│                                               │",
      "└───────────────────────────────────────────────┘"
    ]

    exp_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, 32, 13 + idx, line)
    end)
  end

  defp draw_content(buffer, :contact, _state) do
    contact_lines = [
      "┌─ Contact ───────────────────────────────────┐",
      "│                                             │",
      "│ Let's connect:                              │",
      "│                                             │",
      "│ ▪ Email: drew@axol.io                       │",
      "│ ▪ GitHub: github.com/hydepwns               │",
      "│ ▪ LinkedIn: linkedin.com/in/drew-hiro       │",
      "│ ▪ X/Twitter: @MF_DROO                       │",
      "│                                             │",
      "│ ┌─────────────────────────────────────────┐ │",
      "│ │  Available for consulting on Elixir,    │ │",
      "│ │  Phoenix, and distributed systems       │ │",
      "│ └─────────────────────────────────────────┘ │",
      "│                                             │",
      "└─────────────────────────────────────────────┘"
    ]

    contact_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, 32, 13 + idx, line)
    end)
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

    matrix_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, 32, 13 + idx, line)
    end)
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

    ssh_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, 32, 13 + idx, line)
    end)
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

    export_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, 32, 13 + idx, line)
    end)
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

    analytics_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, 32, 13 + idx, line)
    end)
  end

  defp draw_content(buffer, :search_results, state) do
    search_state = state.search_state

    # Build search results display
    header = [
      "┌─ Search Results ──────────────────────────────┐",
      "│ Query: #{String.slice(search_state.query, 0, 38)} │",
      "│ Mode: #{search_state.mode} | Results: #{length(search_state.results)} found  │",
      "├───────────────────────────────────────────────┤"
    ]

    # Display results (limited to fit screen)
    results_lines =
      if length(search_state.results) > 0 do
        search_state.results
        |> Enum.take(8)
        |> Enum.map(fn result ->
          section = result.section |> Atom.to_string() |> String.upcase()
          line = String.slice(result.line, 0, 35)
          score = :erlang.float_to_binary(result.score, decimals: 2)
          "│ [#{section}] #{line}... (#{score}) │"
        end)
      else
        ["│ No results found                             │"]
      end

    footer = [
      "├───────────────────────────────────────────────┤",
      "│ Commands: --fuzzy --exact --regex            │",
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

    help_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, 32, 13 + idx, line)
    end)
  end

  defp draw_content(buffer, :performance, _state) do
    # Get performance metrics
    metrics = Droodotfoo.PerformanceMonitor.get_summary()

    content_lines = [
      "┌─ Performance Metrics ─────────────────────────┐",
      "│                                               │",
      "│  System Health Monitor                        │",
      "│  ────────────────────                         │",
      "│                                               │",
      "│  Uptime:         #{String.pad_trailing(to_string(metrics.uptime_hours) <> " hours", 20)}     │",
      "│  Requests:       #{String.pad_trailing(to_string(metrics.total_requests), 20)}     │",
      "│  Req/min:        #{String.pad_trailing(to_string(metrics.requests_per_minute), 20)}     │",
      "│  Errors:         #{String.pad_trailing(to_string(metrics.total_errors) <> " (" <> to_string(metrics.error_rate) <> "%)", 20)}     │",
      "│                                               │",
      "│  Render Performance                           │",
      "│  ─────────────────                            │",
      "│  Average:        #{String.pad_trailing(to_string(metrics.avg_render_time) <> "ms", 20)}     │",
      "│  Min:            #{String.pad_trailing(to_string(metrics.min_render_time) <> "ms", 20)}     │",
      "│  Max:            #{String.pad_trailing(to_string(metrics.max_render_time) <> "ms", 20)}     │",
      "│  95th %tile:     #{String.pad_trailing(to_string(metrics.p95_render_time) <> "ms", 20)}     │",
      "│                                               │",
      "│  System Resources                             │",
      "│  ───────────────                              │",
      "│  Memory:         #{String.pad_trailing(to_string(metrics.current_memory) <> "MB", 20)}     │",
      "│  Avg Memory:     #{String.pad_trailing(to_string(metrics.avg_memory) <> "MB", 20)}     │",
      "│  Processes:      #{String.pad_trailing(to_string(metrics.current_processes), 20)}     │",
      "│  Avg Processes:  #{String.pad_trailing(to_string(metrics.avg_processes), 20)}     │",
      "│                                               │",
      "│  [Auto-refreshes every 5 seconds]             │",
      "│                                               │",
      "└───────────────────────────────────────────────┘"
    ]

    content_lines
    |> Enum.with_index()
    |> Enum.take(min(length(content_lines), 22))  # Ensure it fits
    |> Enum.reduce(buffer, fn {line, idx}, acc ->
      TerminalBridge.write_at(acc, 32, 2 + idx, line)
    end)
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

    ls_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, 32, 13 + idx, line)
    end)
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
    |> Enum.with_index()
    |> Enum.take(min(length(all_lines), 24 - 2))  # Ensure it fits in buffer
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      TerminalBridge.write_at(buf, 32, 2 + idx, line)
    end)
  end

  defp draw_content(buffer, _, _state), do: buffer

  defp format_terminal_line(line) do
    # Truncate long lines to fit
    String.slice(line, 0..44)
  end
end
