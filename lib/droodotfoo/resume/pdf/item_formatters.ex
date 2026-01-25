defmodule Droodotfoo.Resume.PDF.ItemFormatters do
  @moduledoc """
  HTML formatters for resume items (experience, education, certifications, projects).
  Uses pattern matching on format type to consolidate duplicated functions.
  """

  alias Droodotfoo.Resume.PDF.TechStackFormatter

  # Experience Formatting

  @doc """
  Format an experience item for the specified resume format.
  """
  def format_experience(exp, :technical) do
    tech_html = TechStackFormatter.render_tech_stack(exp[:technologies])
    achievements_html = render_achievements(exp[:achievements])

    ~s"""
    <div class="experience-item">
      <div class="company">#{exp.company}</div>
      <div class="date">#{exp.start_date} - #{exp.end_date}</div>
      <div class="position">#{exp.position} | #{exp[:location] || "Remote"}</div>
      #{render_description(exp[:description])}
      #{achievements_html}
      #{tech_html}
    </div>
    """
  end

  def format_experience(exp, :executive) do
    ~s"""
    <div class="experience-item">
      <div class="company">#{exp.company}</div>
      <div class="date">#{exp.start_date} - #{exp.end_date}</div>
      <div class="position">#{exp.position}</div>
      <div class="description">#{exp[:description] || ""}</div>
    </div>
    """
  end

  def format_experience(exp, :minimal) do
    ~s"""
    <div class="item">
      <div class="item-title">#{exp.company}</div>
      <div class="item-date">#{exp.start_date} - #{exp.end_date}</div>
      <div class="item-subtitle">#{exp.position}</div>
    </div>
    """
  end

  def format_experience(exp, :detailed) do
    tech_html = TechStackFormatter.render_tech_stack(exp[:technologies])
    achievements_html = render_achievements(exp[:achievements])

    ~s"""
    <div class="experience-item">
      <div class="company">#{exp.company}</div>
      <div class="date">#{exp.start_date} - #{exp.end_date}</div>
      <div class="position">#{exp.position} | #{exp[:location] || "Remote"} | #{exp[:employment_type] || "Full-time"}</div>
      #{render_description(exp[:description])}
      #{achievements_html}
      #{tech_html}
    </div>
    """
  end

  # Defense Project Formatting

  @doc """
  Format a defense project item for the specified resume format.
  """
  def format_defense_project(project, :technical) do
    tech_html = TechStackFormatter.render_tech_stack(project[:technologies])

    ~s"""
    <div class="project-item">
      <div class="project-name">#{project.name}</div>
      <div class="date">#{project[:start_date]} - #{project[:end_date]}</div>
      <div class="position">#{project[:role] || "Contributor"} | #{project[:status] || "Completed"}</div>
      <div class="description">#{project.description}</div>
      #{tech_html}
    </div>
    """
  end

  def format_defense_project(project, :minimal) do
    ~s"""
    <div class="item">
      <div class="item-title">#{project.name}</div>
      <div class="item-subtitle">#{project[:role] || "Contributor"}</div>
    </div>
    """
  end

  def format_defense_project(project, :detailed) do
    tech_html = TechStackFormatter.render_tech_stack(project[:technologies])

    ~s"""
    <div class="project-item">
      <div class="project-name">#{project.name}</div>
      <div class="date">#{project[:start_date]} - #{project[:end_date]}</div>
      <div class="role">#{project[:role] || "Contributor"} | #{project[:status] || "Completed"}</div>
      <div class="description">#{project.description}</div>
      #{tech_html}
    </div>
    """
  end

  # Portfolio Project Formatting

  @doc """
  Format a portfolio project item for the specified resume format.
  """
  def format_portfolio_project(project, :technical) do
    ~s"""
    <div class="project-item">
      <div class="project-name">#{project.name}</div>
      <div class="description">#{project.description}</div>
      <div class="tech-stack">#{project[:language] || ""} | #{project.url}</div>
    </div>
    """
  end

  def format_portfolio_project(project, :detailed) do
    ~s"""
    <div class="project-item">
      <div class="project-name">#{project.name}</div>
      <div class="description">#{project.description}</div>
      <div class="tech-stack">Language: #{project[:language] || "N/A"} | Status: #{String.capitalize(project[:status] || "active")}</div>
      <div class="project-url">#{project.url}</div>
    </div>
    """
  end

  # Education Formatting

  @doc """
  Format an education item for the specified resume format.
  """
  def format_education(edu, :technical) do
    achievements_html = render_education_achievements_flat(edu[:achievements])

    ~s"""
    <div class="experience-item">
      <div class="company">#{edu.institution}</div>
      <div class="date">#{edu.start_date} - #{edu.end_date}</div>
      <div class="position">#{edu.degree} - #{edu.field}#{concentration_suffix(edu[:concentration])}</div>
      #{wrap_achievements(achievements_html)}
    </div>
    """
  end

  def format_education(edu, :executive), do: format_education(edu, :technical)

  def format_education(edu, :minimal) do
    ~s"""
    <div class="item">
      <div class="item-title">#{edu.institution}</div>
      <div class="item-subtitle">#{edu.degree} - #{edu.field}</div>
    </div>
    """
  end

  def format_education(edu, :detailed) do
    achievements_html = render_education_achievements_categorized(edu[:achievements])

    ~s"""
    <div class="experience-item">
      <div class="company">#{edu.institution}</div>
      <div class="date">#{edu.start_date} - #{edu.end_date}</div>
      <div class="position">#{edu.degree} - #{edu.field}#{concentration_suffix(edu[:concentration])}</div>
      #{render_minor(edu[:minor])}
      #{wrap_achievements(achievements_html)}
    </div>
    """
  end

  # Certification Formatting

  @doc """
  Format a certification item for the specified resume format.
  """
  def format_certification(cert, :technical) do
    ~s"""
    <div class="experience-item">
      <div class="company">#{cert.name}</div>
      <div class="date">#{cert.date}</div>
      <div class="position">#{cert.issuer}</div>
    </div>
    """
  end

  def format_certification(cert, :detailed) do
    credential_suffix = if cert[:credential_id], do: " | #{cert.credential_id}", else: ""

    ~s"""
    <div class="experience-item">
      <div class="company">#{cert.name}</div>
      <div class="date">#{cert.date}</div>
      <div class="position">#{cert.issuer}#{credential_suffix}</div>
    </div>
    """
  end

  # Helper functions

  defp render_achievements(nil), do: ""
  defp render_achievements([]), do: ""

  defp render_achievements(achievements) do
    items =
      Enum.map_join(achievements, "", fn achievement ->
        ~s|<div class="achievement">* #{achievement}</div>|
      end)

    ~s|<div class="achievements">#{items}</div>|
  end

  defp render_description(nil), do: ""
  defp render_description(description), do: ~s|<div class="description">#{description}</div>|

  defp render_education_achievements_flat(nil), do: ""

  defp render_education_achievements_flat(achievements) when is_map(achievements) do
    achievements
    |> Enum.flat_map(fn {_category, items} -> items end)
    |> Enum.map_join("", fn achievement ->
      ~s|<div class="achievement">* #{achievement}</div>|
    end)
  end

  defp render_education_achievements_flat(_), do: ""

  defp render_education_achievements_categorized(nil), do: ""

  defp render_education_achievements_categorized(achievements) when is_map(achievements) do
    Enum.map_join(achievements, "", fn {category, items} ->
      category_name = category |> to_string() |> String.capitalize()

      items_html =
        Enum.map_join(items, "", fn achievement ->
          ~s|<div class="achievement">* #{achievement}</div>|
        end)

      ~s"""
      <div style="margin-top: 8px;">
        <strong>#{category_name}:</strong>
        #{items_html}
      </div>
      """
    end)
  end

  defp render_education_achievements_categorized(_), do: ""

  defp wrap_achievements(""), do: ""
  defp wrap_achievements(html), do: ~s|<div class="achievements">#{html}</div>|

  defp concentration_suffix(nil), do: ""
  defp concentration_suffix(concentration), do: " (#{concentration})"

  defp render_minor(nil), do: ""
  defp render_minor(minor), do: ~s|<div class="description">Minor: #{minor}</div>|
end
