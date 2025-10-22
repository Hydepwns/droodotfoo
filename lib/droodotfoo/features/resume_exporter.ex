defmodule Droodotfoo.Features.ResumeExporter do
  @moduledoc """
  Export resume data in various formats.
  Dynamically generates exports from ResumeData.
  """

  alias Droodotfoo.Resume.ResumeData

  def export_markdown do
    resume = ResumeData.get_resume_data()

    experience_section = format_experience_section(resume.experience)
    projects_section = format_defense_projects_section(resume)
    portfolio_section = format_portfolio_section(resume)
    skills_by_category = aggregate_skills(resume)

    skills_section =
      skills_by_category
      |> Enum.map_join("\n\n", fn {category, items} ->
        category_name = category |> to_string() |> String.capitalize()
        "### #{category_name}\n- #{Enum.join(items, ", ")}"
      end)

    """
    # #{resume.personal_info.name} - #{resume.personal_info.title}

    **Email:** #{resume.contact.email}
    **GitHub:** #{resume.contact.github}
    **LinkedIn:** #{resume.contact.linkedin}
    **Twitter:** #{resume.contact.twitter}
    **Website:** #{resume.contact.website}

    ## Summary

    #{resume.summary}

    #{if resume[:focus_areas] && length(resume.focus_areas) > 0 do
      "**Focus Areas:** #{Enum.join(resume.focus_areas, ", ")}"
    else
      ""
    end}

    ## Technical Skills

    #{skills_section}

    ## Experience

    #{experience_section}

    ## Defense Projects

    #{projects_section}

    ## Portfolio

    #{portfolio_section}

    ## Education

    #{resume.education |> Enum.map_join("\n", fn edu -> """
      ### #{edu.degree} - #{edu.field}
      **#{edu.institution}** | #{edu.start_date} - #{edu.end_date}
      #{if edu[:concentration], do: "Concentration: #{edu.concentration}", else: ""}
      """ end)}

    ## Certifications

    #{resume.certifications |> Enum.map_join("\n", fn cert -> "- **#{cert.name}** - #{cert.issuer} (#{cert.date})" end)}

    ---
    *Generated from droo.foo terminal*
    """
  end

  defp format_experience_section(experience) do
    experience
    |> Enum.map_join("\n", fn exp ->
      achievements =
        (exp[:achievements] || [])
        |> Enum.map_join("\n", &"- #{&1}")

      """
      ### #{exp.position}
      **#{exp.company}** | #{exp.start_date} - #{exp.end_date}
      #{achievements}
      """
    end)
  end

  defp format_defense_projects_section(%{defense_projects: projects})
       when is_list(projects) and length(projects) > 0 do
    projects
    |> Enum.map_join("\n", fn project ->
      """
      ### #{project.name}
      #{project.description}
      """
    end)
  end

  defp format_defense_projects_section(_), do: ""

  defp format_portfolio_section(%{portfolio: %{projects: projects}}) when is_list(projects) do
    projects
    |> Enum.map_join("\n", fn project ->
      """
      ### #{project.name}
      #{project.description}
      Technologies: #{project[:language] || "N/A"}
      """
    end)
  end

  defp format_portfolio_section(_), do: ""

  def export_json do
    resume = ResumeData.get_resume_data()

    # Convert to exportable format
    export_data = %{
      personal_info: resume.personal_info,
      summary: resume.summary,
      availability: resume[:availability],
      focus_areas: resume[:focus_areas] || [],
      experience:
        Enum.map(resume.experience, fn exp ->
          %{
            company: exp.company,
            position: exp.position,
            location: exp[:location],
            employment_type: exp[:employment_type],
            start_date: exp.start_date,
            end_date: exp.end_date,
            description: exp[:description],
            achievements: exp[:achievements] || [],
            technologies: exp[:technologies] || %{}
          }
        end),
      education:
        Enum.map(resume.education, fn edu ->
          %{
            institution: edu.institution,
            degree: edu.degree,
            field: edu.field,
            concentration: edu[:concentration],
            start_date: edu.start_date,
            end_date: edu.end_date,
            achievements: edu[:achievements] || %{}
          }
        end),
      defense_projects: resume[:defense_projects] || [],
      portfolio: resume[:portfolio] || %{},
      certifications: resume.certifications,
      contact: resume.contact
    }

    Jason.encode!(export_data, pretty: true)
  end

  def export_text do
    resume = ResumeData.get_resume_data()

    experience_text =
      resume.experience
      |> Enum.map_join("\n", fn exp ->
        achievements =
          (exp[:achievements] || [])
          |> Enum.map_join("\n", &"- #{&1}")

        """
        #{exp.position} | #{exp.company} | #{exp.start_date} - #{exp.end_date}
        #{achievements}
        """
      end)

    skills_text =
      aggregate_skills(resume)
      |> Enum.map_join("\n", fn {category, items} ->
        category_name = category |> to_string() |> String.capitalize()
        "#{String.pad_trailing(category_name <> ":", 15)} #{Enum.join(items, ", ")}"
      end)

    projects_text =
      if resume[:defense_projects] && length(resume.defense_projects) > 0 do
        resume.defense_projects
        |> Enum.map_join("\n", fn project ->
          "* #{project.name} - #{project.description}"
        end)
      else
        ""
      end

    """
    ================================================================================
                                      RESUME
    ================================================================================

    #{String.upcase(resume.personal_info.name)}
    #{resume.personal_info.title}

    Contact:
    - Email: #{resume.contact.email}
    - GitHub: #{resume.contact.github}
    - LinkedIn: #{resume.contact.linkedin}
    - Twitter: #{resume.contact.twitter}
    - Website: #{resume.contact.website}

    --------------------------------------------------------------------------------
    SUMMARY
    --------------------------------------------------------------------------------
    #{resume.summary}

    #{if resume[:focus_areas] && length(resume.focus_areas) > 0 do
      "Focus Areas: #{Enum.join(resume.focus_areas, ", ")}"
    else
      ""
    end}

    --------------------------------------------------------------------------------
    TECHNICAL SKILLS
    --------------------------------------------------------------------------------
    #{skills_text}

    --------------------------------------------------------------------------------
    EXPERIENCE
    --------------------------------------------------------------------------------
    #{experience_text}

    --------------------------------------------------------------------------------
    DEFENSE PROJECTS
    --------------------------------------------------------------------------------
    #{projects_text}

    --------------------------------------------------------------------------------
    EDUCATION
    --------------------------------------------------------------------------------
    #{resume.education |> Enum.map_join("\n", fn edu -> "#{edu.degree} - #{edu.field} | #{edu.institution} | #{edu.start_date} - #{edu.end_date}" end)}

    --------------------------------------------------------------------------------
    CERTIFICATIONS
    --------------------------------------------------------------------------------
    #{resume.certifications |> Enum.map_join("\n", fn cert -> "* #{cert.name} - #{cert.issuer} (#{cert.date})" end)}

    ================================================================================
    Generated from droo.foo terminal
    ================================================================================
    """
  end

  # Aggregate skills from all experience items
  defp aggregate_skills(resume) do
    resume.experience
    |> Enum.flat_map(fn exp ->
      (exp[:technologies] || %{})
      |> Enum.reject(fn {_k, v} -> is_nil(v) || v == [] end)
      |> Enum.to_list()
    end)
    |> Enum.group_by(fn {category, _items} -> category end, fn {_category, items} -> items end)
    |> Enum.map(fn {category, items_lists} ->
      all_items = items_lists |> List.flatten() |> Enum.uniq() |> Enum.sort()
      {category, all_items}
    end)
  end
end
