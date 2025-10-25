defmodule Droodotfoo.Content.Portfolio do
  @moduledoc """
  Portfolio content for search and display throughout the application.
  Dynamically loads content from ResumeData.
  """

  alias Droodotfoo.Terminal.CommandRegistry
  alias Droodotfoo.Resume.ResumeData

  @doc """
  Returns searchable content organized by section.
  """
  def searchable_content do
    %{
      help: help_content(),
      home: home_content(),
      projects: projects_content(),
      skills: skills_content(),
      experience: experience_content(),
      contact: contact_content()
    }
  end

  @doc """
  Returns help/documentation content.
  """
  def help_content do
    """
    Available Commands:
    #{Enum.join(CommandRegistry.help_text(), "\n    ")}

    Navigation:
    hjkl - Vim-style navigation
    Arrow keys - Alternative navigation
    g/G - Jump to top/bottom
    Tab - Command completion
    Enter - Select item
    Escape - Exit mode
    n/N - Next/previous search result
    ? - Toggle help modal
    """
  end

  @doc """
  Returns home/bio content.
  """
  def home_content do
    resume = ResumeData.get_resume_data()
    name = resume.personal_info.name
    title = resume.personal_info.title
    summary = resume.summary

    """
    #{name} - #{title}
    Welcome to droo.foo
    #{summary}
    Interactive terminal portfolio - Navigate with vim keys or use commands
    """
  end

  @doc """
  Returns projects content.
  """
  def projects_content do
    resume = ResumeData.get_resume_data()

    # Combine defense_projects and portfolio.projects
    defense_projects =
      (resume[:defense_projects] || [])
      |> Enum.map(fn project ->
        "#{project.name} - #{project.description}"
      end)

    portfolio_projects =
      if resume[:portfolio] && resume.portfolio[:projects] do
        resume.portfolio.projects
        |> Enum.map(fn project ->
          "#{project.name} - #{project.description} (#{project[:language] || "N/A"})"
        end)
      else
        []
      end

    all_projects = defense_projects ++ portfolio_projects

    if all_projects == [] do
      "No projects available"
    else
      Enum.join(all_projects, "\n")
    end
  end

  @doc """
  Returns skills content.
  Aggregates technologies from all experience items.
  """
  def skills_content do
    resume = ResumeData.get_resume_data()

    # Collect all technologies from experience
    all_technologies =
      resume.experience
      |> Enum.flat_map(fn exp ->
        (exp[:technologies] || %{})
        |> Enum.reject(fn {_k, v} -> is_nil(v) || v == [] end)
        |> Enum.to_list()
      end)
      |> Enum.group_by(fn {category, _items} -> category end, fn {_category, items} -> items end)
      |> Enum.map(fn {category, items_lists} ->
        all_items = items_lists |> List.flatten() |> Enum.uniq() |> Enum.sort()
        category_name = category |> to_string() |> String.capitalize()
        "#{category_name}: #{Enum.join(all_items, ", ")}"
      end)

    if all_technologies == [] do
      "No skills data available"
    else
      Enum.join(all_technologies, "\n")
    end
  end

  @doc """
  Returns experience content.
  """
  def experience_content do
    resume = ResumeData.get_resume_data()

    resume.experience
    |> Enum.map(fn exp ->
      employment_type = exp[:employment_type] || "full-time"
      "#{exp.company} - #{exp.position} (#{exp.start_date} - #{exp.end_date}) [#{employment_type}] - #{exp[:description] || ""}"
    end)
    |> Enum.join("\n")
  end

  @doc """
  Returns contact information.
  """
  def contact_content do
    resume = ResumeData.get_resume_data()

    """
    Email: #{resume.contact.email}
    GitHub: #{resume.contact.github}
    LinkedIn: #{resume.contact.linkedin}
    Twitter: #{resume.contact.twitter}
    Website: #{resume.contact.website}
    """
  end
end
