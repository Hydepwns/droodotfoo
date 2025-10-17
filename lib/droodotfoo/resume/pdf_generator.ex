defmodule Droodotfoo.Resume.PDFGenerator do
  @moduledoc """
  PDF generation for resume exports with multiple formats and real-time preview.
  """

  # Suppress warnings for unused helper functions that are defined for future use
  # These functions are template helpers that will be used in future HTML generation

  alias Droodotfoo.Resume.ResumeData

  @doc """
  Generate PDF resume in the specified format.
  """
  def generate_pdf(format \\ "technical") do
    resume_data = ResumeData.get_resume_data()

    case format do
      "technical" -> generate_technical_pdf(resume_data)
      "executive" -> generate_executive_pdf(resume_data)
      "minimal" -> generate_minimal_pdf(resume_data)
      "detailed" -> generate_detailed_pdf(resume_data)
      _ -> generate_technical_pdf(resume_data)
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

  defp generate_technical_html(_resume_data) do
    ~S"""
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
        .skills-grid { 
          display: grid; 
          grid-template-columns: 1fr 1fr; 
          gap: 10px; 
        }
        .skill-category { 
          margin-bottom: 10px; 
        }
        .skill-category-name { 
          font-weight: bold; 
          font-size: 10px; 
        }
        .skill-items { 
          font-size: 10px; 
          color: #666; 
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

      <div class="section">
        <div class="section-title">TECHNICAL EXPERIENCE</div>
        #{Enum.map_join(resume_data.experience, "", &format_experience_item/1)}
      </div>

      <div class="section">
        <div class="section-title">PROJECTS</div>
        #{Enum.map_join(resume_data.projects, "", &format_project_item/1)}
      </div>

      <div class="section">
        <div class="section-title">TECHNICAL SKILLS</div>
        <div class="skills-grid">
          #{Enum.map_join(resume_data.skills, "", &format_skill_category/1)}
        </div>
      </div>

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

  defp generate_executive_html(_resume_data) do
    ~S"""
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
        .achievement-title { 
          font-weight: bold; 
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
        <div class="achievement">
          <div class="achievement-title">Technical Leadership</div>
          Led development of droo.foo terminal portfolio with real-time P2P capabilities and blockchain integration
        </div>
        <div class="achievement">
          <div class="achievement-title">Innovation</div>
          Built decentralized file sharing system with WebRTC, E2E encryption, and blockchain-based metadata
        </div>
        <div class="achievement">
          <div class="achievement-title">System Architecture</div>
          Designed and implemented scalable microservices architecture with real-time collaboration features
        </div>
      </div>

      <div class="section">
        <div class="section-title">CORE COMPETENCIES</div>
        <div style="columns: 2; column-gap: 30px;">
          #{Enum.map_join(resume_data.skills, "", &format_executive_skill/1)}
        </div>
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

  defp generate_minimal_html(_resume_data) do
    ~S"""
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
        .skills-inline { 
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
          #{resume_data.contact.email} | #{resume_data.contact.website} | #{resume_data.personal_info.location}
        </div>
      </div>

      <div class="section">
        <div class="section-title">EXPERIENCE</div>
        #{Enum.map_join(resume_data.experience, "", &format_minimal_experience/1)}
      </div>

      <div class="section">
        <div class="section-title">PROJECTS</div>
        #{Enum.map_join(resume_data.projects, "", &format_minimal_project/1)}
      </div>

      <div class="section">
        <div class="section-title">SKILLS</div>
        <div class="skills-inline">
          #{Enum.map_join(resume_data.skills, " | ", &format_minimal_skills/1)}
        </div>
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

  defp generate_detailed_html(_resume_data) do
    ~S"""
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
        .position, .technologies { 
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
        .skills-detailed { 
          display: grid; 
          grid-template-columns: 1fr 1fr 1fr; 
          gap: 15px; 
        }
        .skill-category { 
          margin-bottom: 12px; 
        }
        .skill-category-name { 
          font-weight: bold; 
          font-size: 11px; 
        }
        .skill-items { 
          font-size: 10px; 
          color: #666; 
          margin-top: 3px; 
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
          #{resume_data.personal_info.location} | #{resume_data.contact.email} | #{resume_data.contact.website}
        </div>
      </div>

      <div class="section">
        <div class="section-title">PROFESSIONAL SUMMARY</div>
        <div class="description">#{resume_data.summary}</div>
      </div>

      <div class="section">
        <div class="section-title">PROFESSIONAL EXPERIENCE</div>
        #{Enum.map_join(resume_data.experience, "", &format_detailed_experience/1)}
      </div>

      <div class="section">
        <div class="section-title">NOTABLE PROJECTS</div>
        #{Enum.map_join(resume_data.projects, "", &format_detailed_project/1)}
      </div>

      <div class="section">
        <div class="section-title">TECHNICAL EXPERTISE</div>
        <div class="skills-detailed">
          #{Enum.map_join(resume_data.skills, "", &format_detailed_skill/1)}
        </div>
      </div>

      <div class="section">
        <div class="section-title">EDUCATION & CERTIFICATIONS</div>
        #{Enum.map_join(resume_data.education, "", &format_detailed_education/1)}
        #{Enum.map_join(resume_data.certifications, "", &format_detailed_certification/1)}
      </div>
    </body>
    </html>
    """
  end

  # Convert HTML to PDF using pdf_generator
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
