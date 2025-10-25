defmodule Droodotfoo.Raxol.Renderer.Content do
  @moduledoc """
  Static content section UI rendering for the terminal.
  Handles rendering of skills, experience, contact, help, and other informational sections.
  """

  alias Droodotfoo.Raxol.{BoxBuilder, BoxConfig}
  alias Droodotfoo.Resume.DataAggregator
  alias Droodotfoo.TerminalBridge

  @doc """
  Draw the skills section with progress bars showing proficiency levels.
  Dynamically aggregates skills from experience technologies.
  """
  def draw_skills do
    resume = Droodotfoo.Resume.ResumeData.get_resume_data()

    # Aggregate all technologies from experience by category
    tech_by_category = DataAggregator.aggregate_technologies_by_category(resume.experience)

    # Build skill bars for each category
    lines = [
      "╭─ Technical Skills ──────────────────────────────────────────────────╮",
      "│                                                                     │"
    ]

    # Languages section
    lang_lines = build_category_skills(tech_by_category[:languages] || [], "Languages")

    # Frameworks section
    framework_lines = build_category_skills(tech_by_category[:frameworks] || [], "Frameworks")

    # Tools section
    tools_lines = build_category_skills(tech_by_category[:tools] || [], "Tools")

    # Combine all sections
    all_lines =
      lines ++
        lang_lines ++
        framework_lines ++
        tools_lines ++
        [
          "│                                                                     │",
          "╰─────────────────────────────────────────────────────────────────────╯"
        ]

    all_lines
  end

  # Build skill bars for a category
  defp build_category_skills(skills, category_name) when is_list(skills) and length(skills) > 0 do
    # Get max frequency for percentage calculation
    max_freq = skills |> Enum.map(fn {_, count} -> count end) |> Enum.max(fn -> 1 end)

    header = [
      "│  #{category_name}:#{String.duplicate(" ", 67 - String.length(category_name) - 5)}│"
    ]

    skill_bars =
      skills
      # Top 3 per category
      |> Enum.take(3)
      |> Enum.map(fn {tech, count} ->
        percentage = min(round(count / max_freq * 100), 100)

        bar =
          Droodotfoo.AsciiChart.percent_bar(tech, percentage,
            width: 35,
            label_width: 12,
            gradient: true,
            style: :rounded
          )

        "│  #{bar}#{String.duplicate(" ", max(0, 67 - String.length(bar) - 2))}│"
      end)

    footer = ["│                                                                     │"]

    header ++ skill_bars ++ footer
  end

  defp build_category_skills(_, _), do: []

  @doc """
  Draw the work experience section.
  Accepts optional state parameter to use uploaded resume data.
  """
  def draw_experience(state \\ nil) do
    resume_data = if state, do: Map.get(state, :resume_data), else: nil

    if resume_data && map_size(resume_data) > 0 do
      draw_experience_from_resume(resume_data)
    else
      draw_experience_default()
    end
  end

  # Default experience content (when no resume uploaded)
  defp draw_experience_default do
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
      "",
      "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
      "",
      "Upload a resume to auto-populate this section",
      "Press 'u' to upload resume (JSON format)",
      ""
    ])
  end

  # Generate experience from uploaded resume data with viewport windowing
  defp draw_experience_from_resume(resume_data) do
    experience_items = Map.get(resume_data, :experience, [])

    # Generate ALL content first to calculate total height
    all_content_items =
      experience_items
      |> Enum.map(fn exp ->
        # Format technologies if present
        tech_lines =
          if exp[:technologies] && map_size(exp.technologies) > 0 do
            tech_summary =
              exp.technologies
              |> Enum.reject(fn {_k, v} -> is_nil(v) || v == [] end)
              |> Enum.flat_map(fn {_category, items} -> items end)
              |> Enum.take(3)
              |> Enum.join(", ")

            if tech_summary != "" do
              # Wrap tech line if too long (67 - 8 for "  Tech: " prefix)
              tech_text = "Tech: #{tech_summary}"
              BoxConfig.wrap_text(tech_text, BoxConfig.inner_width() - 2)
              |> Enum.map(&("  " <> &1))
            else
              []
            end
          else
            []
          end

        # Wrap position if too long (accounting for "▪ " prefix)
        position_lines =
          BoxConfig.wrap_text(exp.position, BoxConfig.inner_width() - 4)
          |> Enum.with_index()
          |> Enum.map(fn {line, idx} ->
            if idx == 0, do: "▪ #{line}", else: "  #{line}"
          end)

        # Company/date line - truncate if too long
        company_line = BoxConfig.truncate_text(
          "#{exp.company} | #{exp.start_date} - #{exp.end_date}",
          BoxConfig.inner_width() - 2
        )

        # Base experience lines
        base_lines = ["", ""] ++ position_lines ++ ["  #{company_line}", ""]

        # Add achievements with wrapping
        achievement_lines =
          (exp[:achievements] || [])
          |> Enum.flat_map(fn achievement ->
            # Wrap each achievement (67 - 4 for "  • " prefix)
            BoxConfig.wrap_text(achievement, BoxConfig.inner_width() - 4)
            |> Enum.with_index()
            |> Enum.map(fn {line, idx} ->
              # First line gets bullet, subsequent lines get indent
              if idx == 0, do: "  • #{line}", else: "    #{line}"
            end)
          end)

        # Add extra spacing after each job for better readability
        base_lines ++ achievement_lines ++ tech_lines ++ [""]
      end)

    # Flatten to get all lines for height calculation
    all_lines = all_content_items |> List.flatten()

    # For now, render all content (viewport windowing will be applied at render level)
    title = "Experience (Resume) [#{length(experience_items)} items]"

    BoxBuilder.build(title, [""] ++ all_lines ++ [""])
  end

  @doc """
  Draw the contact information section.
  Dynamically loads from ResumeData.
  """
  def draw_contact do
    resume = Droodotfoo.Resume.ResumeData.get_resume_data()

    # Extract domain from URLs for cleaner display
    github = resume.contact.github |> String.replace(~r{^https?://}, "")
    linkedin = resume.contact.linkedin |> String.replace(~r{^https?://}, "")

    twitter_handle =
      resume.contact.twitter |> String.replace(~r{^https?://(www\.)?twitter\.com/}, "@")

    availability_text =
      case resume[:availability] do
        "open_to_consulting" -> "● Available for consulting on blockchain and distributed systems"
        "open_to_opportunities" -> "● Open to new opportunities"
        "not_available" -> "● Not currently available"
        _ -> "● Available for consulting"
      end

    # Calculate inner box content width: 71 (outer) - 10 (borders + padding) = 61
    # For lines with arrow: 61 - 3 (for " → ") = 58
    inner_content_width = BoxConfig.content_width() - 10
    arrow_content_width = inner_content_width - 3

    [
      BoxConfig.header_line("Contact", :rounded),
      BoxConfig.empty_line(),
      BoxConfig.box_line("Let's connect:"),
      BoxConfig.empty_line(),
      "│  ╭─ Email ──────────────────────────────────────────────────────╮  │",
      "│  │ → #{BoxConfig.truncate_and_pad(resume.contact.email, arrow_content_width)}│  │",
      "│  ╰──────────────────────────────────────────────────────────────╯  │",
      BoxConfig.empty_line(),
      "│  ╭─ GitHub ─────────────────────────────────────────────────────╮  │",
      "│  │ → #{BoxConfig.truncate_and_pad(github, arrow_content_width)}│  │",
      "│  ╰──────────────────────────────────────────────────────────────╯  │",
      BoxConfig.empty_line(),
      "│  ╭─ LinkedIn ───────────────────────────────────────────────────╮  │",
      "│  │ → #{BoxConfig.truncate_and_pad(linkedin, arrow_content_width)}│  │",
      "│  ╰──────────────────────────────────────────────────────────────╯  │",
      BoxConfig.empty_line(),
      "│  ╭─ X/Twitter ──────────────────────────────────────────────────╮  │",
      "│  │ → #{BoxConfig.truncate_and_pad(twitter_handle, arrow_content_width)}│  │",
      "│  ╰──────────────────────────────────────────────────────────────╯  │",
      BoxConfig.empty_line(),
      "│  ╭─ Availability ───────────────────────────────────────────────╮  │",
      "│  │ #{BoxConfig.truncate_and_pad(availability_text, inner_content_width)}│  │",
      "│  ╰──────────────────────────────────────────────────────────────╯  │",
      BoxConfig.empty_line(),
      BoxConfig.footer_line(:rounded)
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
    {:ok, now} = DateTime.now("Europe/Madrid")
    timestamp = now |> DateTime.truncate(:second) |> to_string() |> String.slice(0, 19)

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
      "│ n/N: next/prev  --fuzzy --exact --regex        │",
      "│ Press ESC to exit search                       │",
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
      "║ PERFORMANCE DASHBOARD                                      [Updated: now]    ║",
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
