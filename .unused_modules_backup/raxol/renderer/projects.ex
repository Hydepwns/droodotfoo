defmodule Droodotfoo.Raxol.Renderer.Projects do
  @moduledoc """
  Project showcase UI rendering components for the terminal.
  Handles project list view and detailed project view.
  """

  alias Droodotfoo.Raxol.{BoxBuilder, BoxConfig}
  alias Droodotfoo.Raxol.Renderer.Helpers

  @doc """
  Draw the project list view with thumbnails in a grid layout.
  """
  def draw_list(buffer, state) do
    projects = Droodotfoo.Projects.all()
    selected_idx = Map.get(state, :selected_project_index, 0)

    # Header
    header_lines =
      BoxBuilder.build("Project Showcase", [
        "",
        "Use ↑↓ to navigate, Enter to view details, Backspace to return",
        ""
      ])

    buffer = Helpers.draw_box_at(buffer, header_lines, 35, 13)

    # Draw projects in a grid (2 columns)
    y_offset = 13 + length(header_lines)

    projects
    |> Enum.with_index()
    |> Enum.chunk_every(2)
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {row_projects, row_idx}, acc_buffer ->
      draw_row(acc_buffer, row_projects, selected_idx, 35, y_offset + row_idx * 12)
    end)
  end

  # Draw a row of projects (up to 2 projects side by side).
  defp draw_row(buffer, row_projects, selected_idx, x_offset, y_offset) do
    row_projects
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {{project, proj_idx}, col_idx}, acc_buffer ->
      x = x_offset + col_idx * 37
      draw_card(acc_buffer, project, proj_idx == selected_idx, x, y_offset)
    end)
  end

  # Draw a single project card with thumbnail.
  defp draw_card(buffer, project, is_selected, x, y) do
    indicator = if is_selected, do: ">", else: " "
    border_char = if is_selected, do: "═", else: "─"
    status_text = Droodotfoo.Projects.status_indicator(project.status)

    # Build the card (project cards are 35 chars wide - intentional exception)
    card_lines = [
      "┌#{String.duplicate(border_char, 33)}┐",
      "│ #{indicator} #{BoxConfig.truncate_and_pad(project.name, 29)} │",
      "│   #{BoxConfig.truncate_and_pad(status_text, 29)} │"
    ]

    # Add ASCII thumbnail
    thumbnail_lines =
      Enum.map(project.ascii_thumbnail, fn line ->
        "│ #{BoxConfig.truncate_and_pad(line, 31)} │"
      end)

    # Add tagline
    tagline_lines = [
      "│#{String.duplicate(" ", 33)}│",
      "│ #{BoxConfig.truncate_and_pad(project.tagline, 31)} │",
      "└#{String.duplicate(border_char, 33)}┘"
    ]

    lines = card_lines ++ thumbnail_lines ++ tagline_lines

    Helpers.draw_box_at(buffer, lines, x, y)
  end

  @doc """
  Draw the detailed project view for a single project.
  """
  def draw_detail(buffer, state) do
    projects = Droodotfoo.Projects.all()
    selected_idx = Map.get(state, :selected_project_index, 0)
    project = Enum.at(projects, selected_idx)

    if project do
      detail_lines = build_detail_lines(project)
      Helpers.draw_box_at(buffer, detail_lines, 35, 13)
    else
      # Fallback if no project selected
      draw_list(buffer, %{state | project_detail_view: false})
    end
  end

  # Build the detailed view lines for a project.
  defp build_detail_lines(project) do
    status_text = Droodotfoo.Projects.status_indicator(project.status)

    # Intro section
    intro_lines =
      [
        "",
        project.tagline,
        "Status: #{status_text}",
        ""
      ] ++ BoxBuilder.wrap_text(project.description)

    # Tech stack section
    tech_stack_text = "  " <> Enum.join(project.tech_stack, ", ")
    tech_stack_lines = BoxBuilder.wrap_text(tech_stack_text)

    # Highlights section
    highlights_lines =
      Enum.map(project.highlights, fn highlight ->
        "• #{highlight}"
      end)

    # Links section
    links_lines = build_links_list(project)

    # Build with sections
    sections = [
      {"", intro_lines},
      {"Tech Stack", tech_stack_lines},
      {"Highlights", highlights_lines}
    ]

    sections =
      if length(links_lines) > 0 do
        sections ++ [{"", links_lines}]
      else
        sections
      end

    # Add footer hint to last section
    final_sections = sections ++ [{"", ["", "Press Backspace to return to project list"]}]

    BoxBuilder.build_with_sections(project.name, final_sections)
  end

  # Build links list for a project (GitHub, Demo, Live Demo).
  defp build_links_list(project) do
    lines = []

    lines =
      if project.github_url do
        lines ++ [BoxBuilder.info_line("GitHub", project.github_url, label_width: 8)]
      else
        lines
      end

    lines =
      if project.demo_url do
        lines ++ [BoxBuilder.info_line("Demo", project.demo_url, label_width: 8)]
      else
        lines
      end

    lines =
      if project.live_demo do
        lines ++ ["[+] Live demo available!"]
      else
        lines
      end

    if length(lines) > 0, do: [""] ++ lines, else: []
  end
end
