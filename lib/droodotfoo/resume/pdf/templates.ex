defmodule Droodotfoo.Resume.PDF.Templates do
  @moduledoc """
  HTML template generation for resume PDFs.
  Provides unified template structure with format-specific content.
  """

  alias Droodotfoo.Resume.PDF.{ItemFormatters, Styles}

  @doc """
  Generate complete HTML for the specified format.
  """
  def generate(resume_data, :technical), do: generate_technical(resume_data)
  def generate(resume_data, :executive), do: generate_executive(resume_data)
  def generate(resume_data, :minimal), do: generate_minimal(resume_data)
  def generate(resume_data, :detailed), do: generate_detailed(resume_data)
  def generate(resume_data, _), do: generate_technical(resume_data)

  defp generate_technical(data) do
    wrap_html(data, :technical, "Technical Resume", fn ->
      [
        section("SUMMARY", ~s|<div class="description">#{data.summary}</div>|),
        focus_areas_section(data),
        section(
          "TECHNICAL EXPERIENCE",
          Enum.map_join(data.experience, "", &ItemFormatters.format_experience(&1, :technical))
        ),
        defense_projects_section(data, :technical),
        portfolio_section(data, :technical),
        section(
          "EDUCATION",
          Enum.map_join(data.education, "", &ItemFormatters.format_education(&1, :technical))
        ),
        section(
          "CERTIFICATIONS",
          Enum.map_join(
            data.certifications,
            "",
            &ItemFormatters.format_certification(&1, :technical)
          )
        )
      ]
      |> Enum.join("\n")
    end)
  end

  defp generate_executive(data) do
    key_achievements =
      data.experience
      |> Enum.flat_map(fn exp -> exp[:achievements] || [] end)
      |> Enum.take(5)

    wrap_html(data, :executive, "Executive Summary", fn ->
      [
        section("EXECUTIVE SUMMARY", ~s|<div class="executive-summary">#{data.summary}</div>|),
        section(
          "KEY ACHIEVEMENTS",
          Enum.map_join(key_achievements, "", fn achievement ->
            ~s|<div class="achievement">* #{achievement}</div>|
          end)
        ),
        section(
          "PROFESSIONAL EXPERIENCE",
          Enum.map_join(data.experience, "", &ItemFormatters.format_experience(&1, :executive))
        ),
        section(
          "EDUCATION & CERTIFICATIONS",
          Enum.map_join(data.education, "", &ItemFormatters.format_education(&1, :executive))
        )
      ]
      |> Enum.join("\n")
    end)
  end

  defp generate_minimal(data) do
    wrap_html(data, :minimal, "Resume", fn ->
      [
        section(
          "EXPERIENCE",
          Enum.map_join(data.experience, "", &ItemFormatters.format_experience(&1, :minimal))
        ),
        defense_projects_section(data, :minimal),
        section(
          "EDUCATION",
          Enum.map_join(data.education, "", &ItemFormatters.format_education(&1, :minimal))
        )
      ]
      |> Enum.join("\n")
    end)
  end

  defp generate_detailed(data) do
    wrap_html(data, :detailed, "Detailed Resume", fn ->
      focus_html =
        if has_focus_areas?(data) do
          ~s|<div class="tech-stack">Focus Areas: #{Enum.join(data.focus_areas, ", ")}</div>|
        else
          ""
        end

      [
        section(
          "PROFESSIONAL SUMMARY",
          ~s|<div class="description">#{data.summary}</div>#{focus_html}|
        ),
        section(
          "PROFESSIONAL EXPERIENCE",
          Enum.map_join(data.experience, "", &ItemFormatters.format_experience(&1, :detailed))
        ),
        defense_projects_section(data, :detailed),
        portfolio_section(data, :detailed),
        section(
          "EDUCATION",
          Enum.map_join(data.education, "", &ItemFormatters.format_education(&1, :detailed))
        ),
        section(
          "CERTIFICATIONS",
          Enum.map_join(
            data.certifications,
            "",
            &ItemFormatters.format_certification(&1, :detailed)
          )
        )
      ]
      |> Enum.join("\n")
    end)
  end

  # Template helpers

  defp wrap_html(data, format, title_suffix, content_fn) do
    contact_line = build_contact_line(data, format)

    ~s"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>#{data.personal_info.name} - #{title_suffix}</title>
      <style>
        #{Styles.get(format)}
      </style>
    </head>
    <body>
      <div class="header">
        <div class="name">#{data.personal_info.name}</div>
        <div class="title">#{data.personal_info.title}</div>
        <div class="contact">#{contact_line}</div>
      </div>

      #{content_fn.()}
    </body>
    </html>
    """
  end

  defp build_contact_line(data, :minimal) do
    "#{data.contact.email} | #{data.contact.website} | #{data.personal_info.location}"
  end

  defp build_contact_line(data, :detailed) do
    timezone = data.personal_info[:timezone] || "Remote"

    "#{data.personal_info.location} (#{timezone}) | #{data.contact.email} | #{data.contact.website}"
  end

  defp build_contact_line(data, _format) do
    "#{data.personal_info.location} | #{data.contact.email} | #{data.contact.website}"
  end

  defp section(title, content) do
    ~s"""
    <div class="section">
      <div class="section-title">#{title}</div>
      #{content}
    </div>
    """
  end

  defp focus_areas_section(data) do
    if has_focus_areas?(data) do
      section(
        "FOCUS AREAS",
        ~s|<div class="description">#{Enum.join(data.focus_areas, " | ")}</div>|
      )
    else
      ""
    end
  end

  defp defense_projects_section(data, format) do
    if has_defense_projects?(data) do
      section(
        "DEFENSE PROJECTS",
        Enum.map_join(
          data.defense_projects,
          "",
          &ItemFormatters.format_defense_project(&1, format)
        )
      )
    else
      ""
    end
  end

  defp portfolio_section(data, format) do
    if has_portfolio?(data) do
      org_html = render_portfolio_org(data.portfolio[:organization])

      projects_html =
        Enum.map_join(
          data.portfolio.projects,
          "",
          &ItemFormatters.format_portfolio_project(&1, format)
        )

      section("PORTFOLIO", org_html <> projects_html)
    else
      ""
    end
  end

  defp render_portfolio_org(nil), do: ""

  defp render_portfolio_org(org) do
    ~s"""
    <div class="project-item">
      <div class="project-name">#{org.name}</div>
      <div class="description">#{org.description}</div>
      <div class="tech-stack">#{org.url}</div>
    </div>
    """
  end

  defp has_focus_areas?(data), do: data[:focus_areas] && length(data.focus_areas) > 0

  defp has_defense_projects?(data),
    do: data[:defense_projects] && length(data.defense_projects) > 0

  defp has_portfolio?(data), do: data[:portfolio] && data.portfolio[:projects]
end
