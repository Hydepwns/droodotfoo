defmodule Droodotfoo.Resume.PDFGenerator do
  @moduledoc """
  PDF generation for resume exports with multiple formats and real-time preview.
  """

  alias Droodotfoo.Resume.ResumeData

  @doc """
  Generate PDF resume in the specified format.
  Returns the PDF binary content directly.
  """
  def generate_pdf(format \\ "technical") do
    resume_data = ResumeData.get_resume_data()

    result =
      case format do
        "technical" -> generate_technical_pdf(resume_data)
        "executive" -> generate_executive_pdf(resume_data)
        "minimal" -> generate_minimal_pdf(resume_data)
        "detailed" -> generate_detailed_pdf(resume_data)
        _ -> generate_technical_pdf(resume_data)
      end

    case result do
      {:ok, pdf_content} -> pdf_content
      {:error, reason} -> raise "PDF generation failed: #{reason}"
    end
  end

  @doc """
  Generate HTML preview for real-time viewing.
  """
  def generate_html_preview(format \\ "technical") do
    resume_data = ResumeData.get_resume_data()

    case format do
      "technical" -> generate_technical_html(resume_data)
      "executive" -> generate_executive_html(resume_data)
      "minimal" -> generate_minimal_html(resume_data)
      "detailed" -> generate_detailed_html(resume_data)
      _ -> generate_technical_html(resume_data)
    end
  end

  # Technical Resume (Developer-focused)
  defp generate_technical_pdf(resume_data) do
    html_content = generate_technical_html(resume_data)
    convert_html_to_pdf(html_content, "technical")
  end

  defp generate_technical_html(resume_data) do
    ~s"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>#{resume_data.personal_info.name} - Technical Resume</title>
      <style>
        body {
          font-family: 'Courier New', monospace;
          font-size: 11px;
          line-height: 1.4;
          margin: 0;
          padding: 20px;
          background: #fff;
          color: #000;
        }
        .header {
          border-bottom: 2px solid #000;
          padding-bottom: 10px;
          margin-bottom: 20px;
        }
        .name {
          font-size: 24px;
          font-weight: bold;
          margin: 0;
        }
        .title {
          font-size: 14px;
          color: #333;
          margin: 5px 0;
        }
        .contact {
          font-size: 10px;
          margin-top: 10px;
        }
        .section {
          margin: 20px 0;
        }
        .section-title {
          font-size: 14px;
          font-weight: bold;
          border-bottom: 1px solid #000;
          padding-bottom: 2px;
          margin-bottom: 10px;
        }
        .experience-item, .project-item {
          margin-bottom: 15px;
        }
        .company, .project-name {
          font-weight: bold;
          font-size: 12px;
        }
        .position, .technologies {
          font-style: italic;
          color: #666;
        }
        .date {
          float: right;
          font-size: 10px;
          color: #666;
        }
        .description {
          margin: 5px 0;
          white-space: pre-line;
        }
        .achievements {
          margin: 5px 0;
        }
        .achievement {
          margin: 3px 0;
          padding-left: 10px;
        }
        .tech-stack {
          font-size: 9px;
          color: #888;
          margin-top: 5px;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <div class="name">#{resume_data.personal_info.name}</div>
        <div class="title">#{resume_data.personal_info.title}</div>
        <div class="contact">
          #{resume_data.personal_info.location} | #{resume_data.contact.email} | #{resume_data.contact.website}
        </div>
      </div>

      <div class="section">
        <div class="section-title">SUMMARY</div>
        <div class="description">#{resume_data.summary}</div>
      </div>

      #{if resume_data[:focus_areas] && length(resume_data.focus_areas) > 0 do
      ~s"""
      <div class="section">
        <div class="section-title">FOCUS AREAS</div>
        <div class="description">#{Enum.join(resume_data.focus_areas, " | ")}</div>
      </div>
      """
    else
      ""
    end}

      <div class="section">
        <div class="section-title">TECHNICAL EXPERIENCE</div>
        #{Enum.map_join(resume_data.experience, "", &format_experience_item/1)}
      </div>

      #{if resume_data[:defense_projects] && length(resume_data.defense_projects) > 0 do
      ~s"""
      <div class="section">
        <div class="section-title">DEFENSE PROJECTS</div>
        #{Enum.map_join(resume_data.defense_projects, "", &format_defense_project_item/1)}
      </div>
      """
    else
      ""
    end}

      #{if resume_data[:portfolio] && resume_data.portfolio[:projects] do
      ~s"""
      <div class="section">
        <div class="section-title">PORTFOLIO</div>
        #{if resume_data.portfolio[:organization] do
        ~s"""
        <div class="project-item">
          <div class="project-name">#{resume_data.portfolio.organization.name}</div>
          <div class="description">#{resume_data.portfolio.organization.description}</div>
          <div class="tech-stack">#{resume_data.portfolio.organization.url}</div>
        </div>
        """
      else
        ""
      end}
        #{Enum.map_join(resume_data.portfolio.projects, "", &format_portfolio_project_item/1)}
      </div>
      """
    else
      ""
    end}

      <div class="section">
        <div class="section-title">EDUCATION</div>
        #{Enum.map_join(resume_data.education, "", &format_education_item/1)}
      </div>

      <div class="section">
        <div class="section-title">CERTIFICATIONS</div>
        #{Enum.map_join(resume_data.certifications, "", &format_certification_item/1)}
      </div>
    </body>
    </html>
    """
  end

  # Executive Resume (High-level overview)
  defp generate_executive_pdf(resume_data) do
    html_content = generate_executive_html(resume_data)
    convert_html_to_pdf(html_content, "executive")
  end

  defp generate_executive_html(resume_data) do
    # Extract key achievements from experience
    key_achievements =
      resume_data.experience
      |> Enum.flat_map(fn exp -> exp[:achievements] || [] end)
      |> Enum.take(5)

    ~s"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>#{resume_data.personal_info.name} - Executive Summary</title>
      <style>
        body {
          font-family: 'Times New Roman', serif;
          font-size: 12px;
          line-height: 1.6;
          margin: 0;
          padding: 30px;
          background: #fff;
          color: #000;
        }
        .header {
          text-align: center;
          margin-bottom: 30px;
        }
        .name {
          font-size: 28px;
          font-weight: bold;
          margin: 0;
        }
        .title {
          font-size: 16px;
          color: #333;
          margin: 10px 0;
        }
        .contact {
          font-size: 11px;
          margin-top: 15px;
        }
        .section {
          margin: 25px 0;
        }
        .section-title {
          font-size: 16px;
          font-weight: bold;
          border-bottom: 2px solid #000;
          padding-bottom: 5px;
          margin-bottom: 15px;
        }
        .executive-summary {
          font-size: 13px;
          line-height: 1.8;
          text-align: justify;
        }
        .achievement {
          margin: 10px 0;
          padding-left: 20px;
        }
        .experience-item {
          margin-bottom: 20px;
        }
        .company {
          font-weight: bold;
          font-size: 14px;
        }
        .position {
          font-style: italic;
          color: #666;
        }
        .date {
          float: right;
          font-size: 11px;
          color: #666;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <div class="name">#{resume_data.personal_info.name}</div>
        <div class="title">#{resume_data.personal_info.title}</div>
        <div class="contact">
          #{resume_data.personal_info.location} | #{resume_data.contact.email} | #{resume_data.contact.website}
        </div>
      </div>

      <div class="section">
        <div class="section-title">EXECUTIVE SUMMARY</div>
        <div class="executive-summary">#{resume_data.summary}</div>
      </div>

      <div class="section">
        <div class="section-title">KEY ACHIEVEMENTS</div>
        #{Enum.map_join(key_achievements, "", fn achievement -> ~s"""
      <div class="achievement">• #{achievement}</div>
      """ end)}
      </div>

      <div class="section">
        <div class="section-title">PROFESSIONAL EXPERIENCE</div>
        #{Enum.map_join(resume_data.experience, "", &format_executive_experience/1)}
      </div>

      <div class="section">
        <div class="section-title">EDUCATION & CERTIFICATIONS</div>
        #{Enum.map_join(resume_data.education, "", &format_education_item/1)}
      </div>
    </body>
    </html>
    """
  end

  # Minimal Resume (Clean and concise)
  defp generate_minimal_pdf(resume_data) do
    html_content = generate_minimal_html(resume_data)
    convert_html_to_pdf(html_content, "minimal")
  end

  defp generate_minimal_html(resume_data) do
    ~s"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>#{resume_data.personal_info.name} - Resume</title>
      <style>
        body {
          font-family: 'Arial', sans-serif;
          font-size: 12px;
          line-height: 1.5;
          margin: 0;
          padding: 25px;
          background: #fff;
          color: #000;
        }
        .header {
          text-align: center;
          margin-bottom: 25px;
        }
        .name {
          font-size: 22px;
          font-weight: bold;
          margin: 0;
        }
        .title {
          font-size: 14px;
          color: #333;
          margin: 5px 0;
        }
        .contact {
          font-size: 11px;
          margin-top: 10px;
        }
        .section {
          margin: 20px 0;
        }
        .section-title {
          font-size: 14px;
          font-weight: bold;
          color: #000;
          margin-bottom: 10px;
        }
        .item {
          margin-bottom: 12px;
        }
        .item-title {
          font-weight: bold;
        }
        .item-subtitle {
          color: #666;
          font-size: 11px;
        }
        .item-date {
          float: right;
          font-size: 10px;
          color: #666;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <div class="name">#{resume_data.personal_info.name}</div>
        <div class="title">#{resume_data.personal_info.title}</div>
        <div class="contact">
          #{resume_data.contact.email} | #{resume_data.contact.website} | #{resume_data.personal_info.location}
        </div>
      </div>

      <div class="section">
        <div class="section-title">EXPERIENCE</div>
        #{Enum.map_join(resume_data.experience, "", &format_minimal_experience/1)}
      </div>

      #{if resume_data[:defense_projects] && length(resume_data.defense_projects) > 0 do
      ~s"""
      <div class="section">
        <div class="section-title">DEFENSE PROJECTS</div>
        #{Enum.map_join(resume_data.defense_projects, "", &format_minimal_defense_project/1)}
      </div>
      """
    else
      ""
    end}

      <div class="section">
        <div class="section-title">EDUCATION</div>
        #{Enum.map_join(resume_data.education, "", &format_minimal_education/1)}
      </div>
    </body>
    </html>
    """
  end

  # Detailed Resume (Comprehensive)
  defp generate_detailed_pdf(resume_data) do
    html_content = generate_detailed_html(resume_data)
    convert_html_to_pdf(html_content, "detailed")
  end

  defp generate_detailed_html(resume_data) do
    ~s"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>#{resume_data.personal_info.name} - Detailed Resume</title>
      <style>
        body {
          font-family: 'Georgia', serif;
          font-size: 11px;
          line-height: 1.6;
          margin: 0;
          padding: 25px;
          background: #fff;
          color: #000;
        }
        .header {
          border-bottom: 3px solid #000;
          padding-bottom: 15px;
          margin-bottom: 25px;
        }
        .name {
          font-size: 26px;
          font-weight: bold;
          margin: 0;
        }
        .title {
          font-size: 15px;
          color: #333;
          margin: 8px 0;
        }
        .contact {
          font-size: 11px;
          margin-top: 12px;
        }
        .section {
          margin: 25px 0;
        }
        .section-title {
          font-size: 15px;
          font-weight: bold;
          border-bottom: 2px solid #000;
          padding-bottom: 3px;
          margin-bottom: 12px;
        }
        .experience-item, .project-item {
          margin-bottom: 20px;
          page-break-inside: avoid;
        }
        .company, .project-name {
          font-weight: bold;
          font-size: 13px;
        }
        .position, .role {
          font-style: italic;
          color: #666;
          font-size: 12px;
        }
        .date {
          float: right;
          font-size: 10px;
          color: #666;
        }
        .description {
          margin: 8px 0;
          white-space: pre-line;
          font-size: 11px;
        }
        .achievements {
          margin: 8px 0;
        }
        .achievement {
          margin: 5px 0;
          padding-left: 15px;
        }
        .tech-stack {
          font-size: 9px;
          color: #888;
          margin-top: 5px;
        }
        .project-url {
          font-size: 10px;
          color: #0066cc;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <div class="name">#{resume_data.personal_info.name}</div>
        <div class="title">#{resume_data.personal_info.title}</div>
        <div class="contact">
          #{resume_data.personal_info.location} (#{resume_data.personal_info[:timezone] || "Remote"}) | #{resume_data.contact.email} | #{resume_data.contact.website}
        </div>
      </div>

      <div class="section">
        <div class="section-title">PROFESSIONAL SUMMARY</div>
        <div class="description">#{resume_data.summary}</div>
        #{if resume_data[:focus_areas] && length(resume_data.focus_areas) > 0 do
      ~s"""
      <div class="tech-stack">Focus Areas: #{Enum.join(resume_data.focus_areas, ", ")}</div>
      """
    else
      ""
    end}
      </div>

      <div class="section">
        <div class="section-title">PROFESSIONAL EXPERIENCE</div>
        #{Enum.map_join(resume_data.experience, "", &format_detailed_experience/1)}
      </div>

      #{if resume_data[:defense_projects] && length(resume_data.defense_projects) > 0 do
      ~s"""
      <div class="section">
        <div class="section-title">DEFENSE PROJECTS</div>
        #{Enum.map_join(resume_data.defense_projects, "", &format_detailed_defense_project/1)}
      </div>
      """
    else
      ""
    end}

      #{if resume_data[:portfolio] && resume_data.portfolio[:projects] do
      ~s"""
      <div class="section">
        <div class="section-title">PORTFOLIO</div>
        #{if resume_data.portfolio[:organization] do
        ~s"""
        <div class="project-item">
          <div class="project-name">#{resume_data.portfolio.organization.name}</div>
          <div class="description">#{resume_data.portfolio.organization.description}</div>
          <div class="project-url">#{resume_data.portfolio.organization.url}</div>
        </div>
        """
      else
        ""
      end}
        #{Enum.map_join(resume_data.portfolio.projects, "", &format_detailed_portfolio_project/1)}
      </div>
      """
    else
      ""
    end}

      <div class="section">
        <div class="section-title">EDUCATION</div>
        #{Enum.map_join(resume_data.education, "", &format_detailed_education/1)}
      </div>

      <div class="section">
        <div class="section-title">CERTIFICATIONS</div>
        #{Enum.map_join(resume_data.certifications, "", &format_detailed_certification/1)}
      </div>
    </body>
    </html>
    """
  end

  # Helper functions for formatting resume items

  defp format_experience_item(exp) do
    tech_categories =
      (exp[:technologies] || %{})
      |> Enum.reject(fn {_k, v} -> is_nil(v) || v == [] end)
      |> Enum.map_join(" | ", fn {category, items} ->
        "#{category |> to_string() |> String.capitalize()}: #{Enum.join(items, ", ")}"
      end)

    achievements_html =
      if exp[:achievements] && length(exp.achievements) > 0 do
        ~s"""
        <div class="achievements">
          #{Enum.map_join(exp.achievements, "", fn achievement -> ~s"""
          <div class="achievement">• #{achievement}</div>
          """ end)}
        </div>
        """
      else
        ""
      end

    ~s"""
    <div class="experience-item">
      <div class="company">#{exp.company}</div>
      <div class="date">#{exp.start_date} - #{exp.end_date}</div>
      <div class="position">#{exp.position} | #{exp[:location] || "Remote"}</div>
      #{if exp[:description],
      do: ~s"""
      <div class="description">#{exp.description}</div>
      """,
      else: ""}
      #{achievements_html}
      #{if tech_categories != "",
      do: ~s"""
      <div class="tech-stack">#{tech_categories}</div>
      """,
      else: ""}
    </div>
    """
  end

  defp format_defense_project_item(project) do
    tech_categories =
      (project[:technologies] || %{})
      |> Enum.reject(fn {_k, v} -> is_nil(v) || v == [] end)
      |> Enum.map_join(" | ", fn {category, items} ->
        "#{category |> to_string() |> String.capitalize()}: #{Enum.join(items, ", ")}"
      end)

    ~s"""
    <div class="project-item">
      <div class="project-name">#{project.name}</div>
      <div class="date">#{project[:start_date]} - #{project[:end_date]}</div>
      <div class="position">#{project[:role] || "Contributor"} | #{project[:status] || "Completed"}</div>
      <div class="description">#{project.description}</div>
      #{if tech_categories != "",
      do: ~s"""
      <div class="tech-stack">#{tech_categories}</div>
      """,
      else: ""}
    </div>
    """
  end

  defp format_portfolio_project_item(project) do
    ~s"""
    <div class="project-item">
      <div class="project-name">#{project.name}</div>
      <div class="description">#{project.description}</div>
      <div class="tech-stack">#{project[:language] || ""} | #{project.url}</div>
    </div>
    """
  end

  defp format_education_item(edu) do
    achievements_html =
      if is_map(edu[:achievements]) do
        edu.achievements
        |> Enum.flat_map(fn {_category, items} -> items end)
        |> Enum.map_join("", fn achievement ->
          ~s"""
          <div class="achievement">• #{achievement}</div>
          """
        end)
      else
        ""
      end

    ~s"""
    <div class="experience-item">
      <div class="company">#{edu.institution}</div>
      <div class="date">#{edu.start_date} - #{edu.end_date}</div>
      <div class="position">#{edu.degree} - #{edu.field}#{if edu[:concentration], do: " (#{edu.concentration})", else: ""}</div>
      #{if achievements_html != "",
      do: ~s"""
      <div class="achievements">#{achievements_html}</div>
      """,
      else: ""}
    </div>
    """
  end

  defp format_certification_item(cert) do
    ~s"""
    <div class="experience-item">
      <div class="company">#{cert.name}</div>
      <div class="date">#{cert.date}</div>
      <div class="position">#{cert.issuer}</div>
    </div>
    """
  end

  defp format_executive_experience(exp) do
    ~s"""
    <div class="experience-item">
      <div class="company">#{exp.company}</div>
      <div class="date">#{exp.start_date} - #{exp.end_date}</div>
      <div class="position">#{exp.position}</div>
      <div class="description">#{exp[:description] || ""}</div>
    </div>
    """
  end

  defp format_minimal_experience(exp) do
    ~s"""
    <div class="item">
      <div class="item-title">#{exp.company}</div>
      <div class="item-date">#{exp.start_date} - #{exp.end_date}</div>
      <div class="item-subtitle">#{exp.position}</div>
    </div>
    """
  end

  defp format_minimal_defense_project(project) do
    ~s"""
    <div class="item">
      <div class="item-title">#{project.name}</div>
      <div class="item-subtitle">#{project[:role] || "Contributor"}</div>
    </div>
    """
  end

  defp format_minimal_education(edu) do
    ~s"""
    <div class="item">
      <div class="item-title">#{edu.institution}</div>
      <div class="item-subtitle">#{edu.degree} - #{edu.field}</div>
    </div>
    """
  end

  defp format_detailed_experience(exp) do
    tech_categories =
      (exp[:technologies] || %{})
      |> Enum.reject(fn {_k, v} -> is_nil(v) || v == [] end)
      |> Enum.map_join(" | ", fn {category, items} ->
        "#{category |> to_string() |> String.capitalize()}: #{Enum.join(items, ", ")}"
      end)

    achievements_html =
      if exp[:achievements] && length(exp.achievements) > 0 do
        ~s"""
        <div class="achievements">
          #{Enum.map_join(exp.achievements, "", fn achievement -> ~s"""
          <div class="achievement">• #{achievement}</div>
          """ end)}
        </div>
        """
      else
        ""
      end

    ~s"""
    <div class="experience-item">
      <div class="company">#{exp.company}</div>
      <div class="date">#{exp.start_date} - #{exp.end_date}</div>
      <div class="position">#{exp.position} | #{exp[:location] || "Remote"} | #{exp[:employment_type] || "Full-time"}</div>
      #{if exp[:description],
      do: ~s"""
      <div class="description">#{exp.description}</div>
      """,
      else: ""}
      #{achievements_html}
      #{if tech_categories != "",
      do: ~s"""
      <div class="tech-stack">#{tech_categories}</div>
      """,
      else: ""}
    </div>
    """
  end

  defp format_detailed_defense_project(project) do
    tech_categories =
      (project[:technologies] || %{})
      |> Enum.reject(fn {_k, v} -> is_nil(v) || v == [] end)
      |> Enum.map_join(" | ", fn {category, items} ->
        "#{category |> to_string() |> String.capitalize()}: #{Enum.join(items, ", ")}"
      end)

    ~s"""
    <div class="project-item">
      <div class="project-name">#{project.name}</div>
      <div class="date">#{project[:start_date]} - #{project[:end_date]}</div>
      <div class="role">#{project[:role] || "Contributor"} | #{project[:status] || "Completed"}</div>
      <div class="description">#{project.description}</div>
      #{if tech_categories != "",
      do: ~s"""
      <div class="tech-stack">#{tech_categories}</div>
      """,
      else: ""}
    </div>
    """
  end

  defp format_detailed_portfolio_project(project) do
    ~s"""
    <div class="project-item">
      <div class="project-name">#{project.name}</div>
      <div class="description">#{project.description}</div>
      <div class="tech-stack">Language: #{project[:language] || "N/A"} | Status: #{String.capitalize(project[:status] || "active")}</div>
      <div class="project-url">#{project.url}</div>
    </div>
    """
  end

  defp format_detailed_education(edu) do
    achievements_html =
      if is_map(edu[:achievements]) do
        edu.achievements
        |> Enum.map_join("", fn {category, items} ->
          category_name = category |> to_string() |> String.capitalize()

          ~s"""
          <div style="margin-top: 8px;">
            <strong>#{category_name}:</strong>
            #{Enum.map_join(items, "", fn achievement -> ~s"""
            <div class="achievement">• #{achievement}</div>
            """ end)}
          </div>
          """
        end)
      else
        ""
      end

    ~s"""
    <div class="experience-item">
      <div class="company">#{edu.institution}</div>
      <div class="date">#{edu.start_date} - #{edu.end_date}</div>
      <div class="position">#{edu.degree} - #{edu.field}#{if edu[:concentration], do: " (#{edu.concentration})", else: ""}</div>
      #{if edu[:minor],
      do: ~s"""
      <div class="description">Minor: #{edu.minor}</div>
      """,
      else: ""}
      #{if achievements_html != "",
      do: ~s"""
      <div class="achievements">#{achievements_html}</div>
      """,
      else: ""}
    </div>
    """
  end

  defp format_detailed_certification(cert) do
    ~s"""
    <div class="experience-item">
      <div class="company">#{cert.name}</div>
      <div class="date">#{cert.date}</div>
      <div class="position">#{cert.issuer}#{if cert[:credential_id], do: " | #{cert.credential_id}", else: ""}</div>
    </div>
    """
  end

  # Convert HTML to PDF using ChromicPDF
  defp convert_html_to_pdf(html_content, _format) do
    case ChromicPDF.print_to_pdf({:html, html_content},
           format: :a4,
           margin: %{top: "0.5in", bottom: "0.5in", left: "0.5in", right: "0.5in"}
         ) do
      {:ok, pdf_content} -> {:ok, pdf_content}
      {:error, reason} -> {:error, "Failed to generate PDF: #{reason}"}
    end
  end
end
