defmodule Droodotfoo.Raxol.Renderer.Content do
  @moduledoc """
  Static content section UI rendering for the terminal.
  Handles rendering of skills, experience, contact, help, and other informational sections.
  """

  alias Droodotfoo.Raxol.{BoxBuilder, BoxConfig}
  alias Droodotfoo.TerminalBridge

  @doc """
  Draw the skills section with progress bars showing proficiency levels.
  """
  def draw_skills do
    [
      "╭─ Technical Skills ──────────────────────────────────────────────────╮",
      "│                                                                    │",
      "│  Languages:                                                        │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("Elixir", 90, width: 35, label_width: 12, gradient: true, style: :rounded)}        │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("Phoenix", 85, width: 35, label_width: 12, gradient: true, style: :rounded)}       │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("JavaScript", 75, width: 35, label_width: 12, gradient: true, style: :rounded)}    │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("TypeScript", 70, width: 35, label_width: 12, gradient: true, style: :rounded)}    │",
      "│                                                                   │",
      "│  Frameworks & Libraries:                                          │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("LiveView", 95, width: 35, label_width: 12, gradient: true, style: :rounded)}      │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("React", 80, width: 35, label_width: 12, gradient: true, style: :rounded)}         │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("GraphQL", 75, width: 35, label_width: 12, gradient: true, style: :rounded)}       │",
      "│                                                                   │",
      "│  Infrastructure & Tools:                                          │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("Docker", 85, width: 35, label_width: 12, gradient: true, style: :rounded)}        │",
      "│  #{Droodotfoo.AsciiChart.percent_bar("PostgreSQL", 90, width: 35, label_width: 12, gradient: true, style: :rounded)}    │",
      "│                                                                   │",
      "╰─────────────────────────────────────────────────────────────────────╯"
    ]
  end

  @doc """
  Draw the work experience section.
  """
  def draw_experience do
    BoxBuilder.build("Experience", [
      "",
      "▪ Senior Backend Engineer",
      "  axol.io | 2023 - Present",
      "  • Built event-driven microservices architecture",
      "  • Reduced API response time by 70% through optimization",
      "",
      "▪ Elixir Developer",
      "  FinTech Startup | 2019 - 2021",
      "  • Designed and implemented real-time payment processing",
      "  • Handled 1M+ transactions daily with 99.9% uptime",
      "",
      "▪ Full Stack Developer",
      "  Digital Agency | 2017 - 2019",
      "  • Built web applications for diverse clients",
      ""
    ])
  end

  @doc """
  Draw the contact information section.
  """
  def draw_contact do
    [
      "╭─ Contact ───────────────────────────────────────────────────────────╮",
      "│                                                                   │",
      "│  Let's connect:                                                   │",
      "│                                                                   │",
      "│  ╭─ Email ──────────────────────────────────────────────────────╮   │",
      "│  │ → drew@axol.io                                             │   │",
      "│  ╰──────────────────────────────────────────────────────────────╯   │",
      "│                                                                   │",
      "│  ╭─ GitHub ────────────────────────────────────────────────────╮    │",
      "│  │ → github.com/hydepwns                                      │   │",
      "│  ╰─────────────────────────────────────────────────────────────╯    │",
      "│                                                                   │",
      "│  ╭─ LinkedIn ──────────────────────────────────────────────────╮    │",
      "│  │ → linkedin.com/in/drew-hiro                                │   │",
      "│  ╰─────────────────────────────────────────────────────────────╯    │",
      "│                                                                   │",
      "│  ╭─ X/Twitter ─────────────────────────────────────────────────╮    │",
      "│  │ → @MF_DROO                                                 │   │",
      "│  ╰─────────────────────────────────────────────────────────────╯    │",
      "│                                                                   │",
      "│  ╭─ Availability ──────────────────────────────────────────────╮   │",
      "│  │ ● Available for consulting on Elixir, Phoenix, LiveView,   │   │",
      "│  │   and distributed systems architecture                     │   │",
      "│  ╰─────────────────────────────────────────────────────────────╯    │",
      "│                                                                   │",
      "╰─────────────────────────────────────────────────────────────────────╯"
    ]
  end

  @doc """
  Draw the Matrix rain easter egg.
  """
  def draw_matrix do
    BoxBuilder.build("Matrix Rain", [
      "",
      "01001101 01100001 01110100 01110010 0110101",
      "░ Follow the white rabbit ░",
      "",
      "  █ ░ █ ░ █ ░ █ ░ █ ░ █ ░ █ ░ █",
      "  ░ █ ░ █ ░ █ ░ █ ░ █ ░ █ ░ █ ░",
      "  █ ░ █ ░ █ ░ █ ░ █ ░ █ ░ █ ░ █",
      "  ░ █ ░ █ ░ █ ░ █ ░ █ ░ █ ░ █ ░",
      "",
      "       Welcome to the Matrix, Neo...",
      "",
      "      Type :clear to exit the Matrix",
      ""
    ])
  end

  @doc """
  Draw SSH simulation easter egg.
  """
  def draw_ssh do
    timestamp =
      DateTime.utc_now() |> DateTime.truncate(:second) |> to_string() |> String.slice(0, 19)

    BoxBuilder.build("SSH Session", [
      "",
      "$ ssh droo@droo.foo",
      "Password: ****",
      "",
      "Welcome to droo.foo OS 1.0 LTS",
      "Last login: #{timestamp}",
      "",
      "[droo@droo ~]$ ls",
      "projects/ skills/ experience/ contact/",
      "",
      "[droo@droo ~]$ _",
      ""
    ])
  end

  @doc """
  Draw export markdown preview.
  """
  def draw_export_markdown do
    BoxBuilder.build("Export: Markdown", [
      "",
      "# Droo - Multidisciplinary Engineer",
      "",
      "**Email:** drew@axol.io",
      "**GitHub:** github.com/hydepwns",
      "",
      "## Summary",
      "Senior Software Engineer with expertise...",
      "",
      "[Download resume.md]",
      ""
    ])
  end

  @doc """
  Draw analytics dashboard.
  """
  def draw_analytics do
    BoxBuilder.build("Analytics Dashboard", [
      "",
      "Page Views:      247",
      "Unique Visitors:  42",
      "Avg. Duration:   3m 27s",
      "",
      "Top Commands:    Top Sections:",
      "1. help (31)     1. projects (89)",
      "2. ls (27)       2. skills (67)",
      "3. cat (19)      3. experience (45)",
      "",
      "Peak Hours: 14:00-15:00, 20:00-21:00",
      ""
    ])
  end

  @doc """
  Draw search results view with results from state.
  """
  def draw_search_results(buffer, state) do
    search_state = state.search_state
    match_counter = Droodotfoo.AdvancedSearch.match_counter(search_state)

    header = [
      "┌─ Search Results ───────────────────────────────┐",
      "│ Query: #{String.pad_trailing(String.slice(search_state.query, 0, 38), 38)} │",
      "│ Mode: #{search_state.mode} | #{String.pad_trailing(match_counter, 24)} │",
      "├────────────────────────────────────────────────┤"
    ]

    results_lines =
      if length(search_state.results) > 0 do
        search_state.results
        |> Enum.take(8)
        |> Enum.with_index()
        |> Enum.map(fn {result, idx} ->
          format_search_result(result, idx, search_state.current_match_index)
        end)
      else
        ["│ No results found                             │"]
      end

    footer = [
      "├────────────────────────────────────────────────┤",
      "│ n/N: next/prev  --fuzzy --exact --regex       │",
      "│ Press ESC to exit search                      │",
      "└────────────────────────────────────────────────┘"
    ]

    all_lines = header ++ results_lines ++ footer

    all_lines
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {line, idx}, buf ->
      padded_line = String.pad_trailing(line, 49)
      TerminalBridge.write_at(buf, 16, 8 + idx, padded_line)
    end)
  end

  @doc """
  Draw help menu.
  """
  def draw_help do
    BoxBuilder.build_with_sections("Help", [
      {"Available Commands",
       [
         ":help      - Show this help menu",
         ":ls        - List available sections",
         ":cat <sec> - Display section content",
         ":clear     - Clear screen",
         ":matrix     - Matrix rain effect",
         ":perf       - Performance metrics dashboard",
         ":metrics    - Alias for :perf",
         "/query      - Search for content",
         ":ssh        - SSH simulation",
         ":export fmt - Export resume (md/json/txt)",
         ":analytics  - View analytics dashboard"
       ]},
      {"Navigation",
       [
         "hjkl       - Vim-style navigation",
         "g/G        - Jump to top/bottom",
         "Tab        - Command completion",
         "Enter      - Select item",
         "Escape     - Exit mode"
       ]}
    ])
  end

  @doc """
  Draw performance metrics dashboard.
  """
  def draw_performance do
    summary = Droodotfoo.PerformanceMonitor.get_summary()
    raw_metrics = Droodotfoo.PerformanceMonitor.get_metrics()

    render_sparkline = Droodotfoo.AsciiChart.sparkline(raw_metrics.render_times, width: 20)
    memory_sparkline = Droodotfoo.AsciiChart.sparkline(raw_metrics.memory_usage, width: 20)

    uptime_str = "#{summary.uptime_hours}h"
    req_rate = "#{summary.requests_per_minute}/min"

    [
      "╔══════════════════════════════════════════════════════════════════════════════╗",
      "║ PERFORMANCE DASHBOARD                                    [Updated: now]    ║",
      "╠══════════════════════════════════════════════════════════════════════════════╣",
      "║                                                                            ║",
      "║  Render Time (ms)              Memory (MB)              Request Rate       ║",
      "║  ┌─────────────────┐          ┌──────────────┐         ┌─────────────────┐   ║",
      "║  │ #{String.pad_trailing(render_sparkline, 15)} │          │ #{String.pad_trailing(memory_sparkline, 12)} │         │    #{String.pad_trailing(req_rate, 13)}│  ║",
      "║  └─────────────────┘          └──────────────┘         └─────────────────┘   ║",
      "║    Avg: #{String.pad_trailing("#{summary.avg_render_time}ms", 18)}   Cur: #{String.pad_trailing("#{summary.current_memory}MB", 18)}   Total: #{String.pad_trailing("#{summary.total_requests}", 10)}    ║",
      "║                                                                            ║",
      "║  System Status                                                             ║",
      "║  ──────────────────────────────────────────────────────────────────────────  ║",
      "║                                                                            ║",
      "║  Uptime:         #{String.pad_trailing(uptime_str, 15)}  Errors:       #{String.pad_trailing("#{summary.total_errors} (#{summary.error_rate}%)", 20)}  ║",
      "║  Processes:      #{String.pad_trailing("#{summary.current_processes}", 15)}  Avg Memory:  #{String.pad_trailing("#{summary.avg_memory}MB", 20)}  ║",
      "║  P95 Render:     #{String.pad_trailing("#{summary.p95_render_time}ms", 15)}  Max Render:  #{String.pad_trailing("#{summary.max_render_time}ms", 20)}  ║",
      "║                                                                            ║",
      "║  Performance Indicators:                                                   ║",
      "║                                                                            ║",
      "║  #{Droodotfoo.AsciiChart.percent_bar("Render", min(summary.avg_render_time * 10, 100), width: 30, label_width: 10, gradient: true, style: :rounded)}                    ║",
      "║  #{Droodotfoo.AsciiChart.percent_bar("Memory", min(summary.current_memory * 2, 100), width: 30, label_width: 10, gradient: true, style: :rounded)}                    ║",
      "║                                                                            ║",
      "╚══════════════════════════════════════════════════════════════════════════════╝"
    ]
  end

  @doc """
  Draw directory listing (ls command output).
  """
  def draw_ls do
    BoxBuilder.build("Directory Listing", [
      "",
      "drwxr-xr-x  ./",
      "-rw-r--r--  home",
      "-rw-r--r--  projects",
      "-rw-r--r--  skills",
      "-rw-r--r--  experience",
      "-rw-r--r--  contact",
      "",
      "Use ':cat <section>' to view content",
      ""
    ])
  end

  @doc """
  Draw terminal output section with state.
  """
  def draw_terminal(state) do
    output_lines =
      state.terminal_output
      |> String.split("\n")
      |> Enum.take(-8)
      |> Enum.map(&format_terminal_line/1)

    padded_lines = output_lines ++ List.duplicate("", max(0, 8 - length(output_lines)))

    terminal_lines = [
      "┌─ Terminal ──────────────────────────────────────────────────────────┐",
      "│                                                                     │"
    ]

    middle_lines =
      padded_lines
      |> Enum.map(fn line ->
        "│ " <> BoxConfig.truncate_and_pad(line, BoxConfig.inner_width()) <> " │"
      end)

    prompt_with_cursor = Map.get(state, :prompt, "") <> "_"

    footer_lines = [
      "│ " <> BoxConfig.truncate_and_pad(prompt_with_cursor, BoxConfig.inner_width()) <> " │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    terminal_lines ++ middle_lines ++ footer_lines
  end

  # Format a terminal line by truncating to fit width.
  defp format_terminal_line(line) do
    String.slice(line, 0..66)
  end

  defp format_search_result(result, idx, current_match_index) do
    section = result.section |> Atom.to_string() |> String.upcase()
    line = String.slice(result.line, 0, 30)
    marker = if idx == current_match_index, do: ">", else: " "
    "│ #{marker}[#{String.pad_trailing(section, 10)}] #{String.pad_trailing(line, 30)} │"
  end
end
