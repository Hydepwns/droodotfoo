defmodule Droodotfoo.Projects do
  @moduledoc """
  Portfolio project data management.
  Dynamically loads from ResumeData (defense_projects + portfolio.projects).
  """

  alias Droodotfoo.Resume.ResumeData

  defstruct [
    :id,
    :name,
    :tagline,
    :description,
    :tech_stack,
    :github_url,
    :demo_url,
    :live_demo,
    :status,
    :highlights,
    :year,
    :ascii_thumbnail
  ]

  @type t :: %__MODULE__{
          id: atom(),
          name: String.t(),
          tagline: String.t(),
          description: String.t(),
          tech_stack: list(String.t()),
          github_url: String.t() | nil,
          demo_url: String.t() | nil,
          live_demo: boolean(),
          status: :active | :completed | :archived,
          highlights: list(String.t()),
          year: integer(),
          ascii_thumbnail: list(String.t())
        }

  @doc """
  Returns all projects from resume data (defense_projects + portfolio.projects).
  """
  @spec all() :: list(t())
  def all do
    resume = ResumeData.get_resume_data()

    # Convert defense projects
    defense = convert_defense_projects(resume[:defense_projects] || [])

    # Convert portfolio projects
    portfolio = convert_portfolio_projects(resume[:portfolio][:projects] || [])

    # Combine and return
    portfolio ++ defense
  end

  # Convert defense projects to Projects struct format
  defp convert_defense_projects(defense_projects) do
    defense_projects
    |> Enum.map(fn project ->
      tech_stack = extract_tech_stack(project[:technologies] || %{})

      %__MODULE__{
        id:
          project.name
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9]+/, "_")
          |> String.to_atom(),
        name: project.name,
        tagline: extract_tagline(project.description),
        description: project.description,
        tech_stack: tech_stack,
        github_url:
          if(project[:url] in ["Classified", "Proprietary"], do: nil, else: project[:url]),
        demo_url: nil,
        live_demo: false,
        status: parse_status(project[:status] || "Completed"),
        highlights: [project.description],
        year: extract_year(project[:start_date]),
        ascii_thumbnail: generate_defense_thumbnail(project.name)
      }
    end)
  end

  # Convert portfolio projects to Projects struct format
  defp convert_portfolio_projects(portfolio_projects) do
    portfolio_projects
    |> Enum.map(fn project ->
      %__MODULE__{
        id:
          project.name
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9]+/, "_")
          |> String.to_atom(),
        name: project.name,
        tagline: project.description,
        description: project.description,
        tech_stack: [project[:language] || "N/A"],
        github_url: project.url,
        demo_url: if(project[:status] == "active", do: project.url, else: nil),
        live_demo: project[:status] == "active",
        status: parse_status(project[:status] || "active"),
        highlights: [project.description],
        year: extract_current_year(),
        ascii_thumbnail: generate_portfolio_thumbnail(project.name)
      }
    end)
  end

  # Extract tech stack from nested technologies structure
  defp extract_tech_stack(technologies) when is_map(technologies) do
    technologies
    |> Enum.reject(fn {_k, v} -> is_nil(v) || v == [] end)
    |> Enum.flat_map(fn {_category, items} -> items end)
    |> Enum.uniq()
  end

  defp extract_tech_stack(_), do: []

  # Extract first sentence as tagline
  defp extract_tagline(description) do
    description
    |> String.split(". ")
    |> List.first()
    |> String.slice(0..60)
  end

  # Parse status string to atom
  defp parse_status(status) when is_binary(status) do
    case String.downcase(status) do
      "active" -> :active
      "completed" -> :completed
      "archived" -> :archived
      _ -> :completed
    end
  end

  defp parse_status(_), do: :completed

  # Extract year from ISO date format (YYYY-MM)
  defp extract_year(date) when is_binary(date) do
    date
    |> String.split("-")
    |> List.first()
    |> String.to_integer()
  rescue
    _ -> extract_current_year()
  end

  defp extract_year(_), do: extract_current_year()

  defp extract_current_year do
    DateTime.utc_now().year
  end

  # Generate ASCII thumbnails for defense projects
  defp generate_defense_thumbnail(name) do
    [
      "╭──────────────────────╮",
      "│  #{String.pad_trailing("DEFENSE PROJECT", 21)}│",
      "│  #{String.pad_trailing("═══════════════", 21)}│",
      "│                     │",
      "│  ╔═══════════════╗  │",
      "│  ║  CLASSIFIED   ║  │",
      "│  ║   █████████   ║  │",
      "│  ║   ░░░░░░░░░   ║  │",
      "│  ╚═══════════════╝  │",
      "│                     │",
      "│  #{String.pad_trailing(String.slice(name, 0..19), 21)}│",
      "╰──────────────────────╯"
    ]
  end

  # Generate ASCII thumbnails for portfolio projects
  defp generate_portfolio_thumbnail(name) do
    [
      "╭──────────────────────╮",
      "│  #{String.pad_trailing("OPEN SOURCE", 21)}│",
      "│  #{String.pad_trailing("═══════════", 21)}│",
      "│                     │",
      "│      ╭─────────╮    │",
      "│      │  CODE   │    │",
      "│      │  ░▒▓▒░  │    │",
      "│      │  ░▒▓▒░  │    │",
      "│      ╰─────────╯    │",
      "│                     │",
      "│  #{String.pad_trailing(String.slice(name, 0..19), 21)}│",
      "╰──────────────────────╯"
    ]
  end

  @doc """
  Gets a project by ID
  """
  @spec get(atom()) :: t() | nil
  def get(id) do
    Enum.find(all(), &(&1.id == id))
  end

  @doc """
  Returns active projects only
  """
  @spec active() :: list(t())
  def active do
    all()
    |> Enum.filter(&(&1.status == :active))
  end

  @doc """
  Returns projects with live demos
  """
  @spec with_live_demos() :: list(t())
  def with_live_demos do
    all()
    |> Enum.filter(&(&1.live_demo == true))
  end

  @doc """
  Filters projects by tech stack
  """
  @spec filter_by_tech(String.t()) :: list(t())
  def filter_by_tech(tech) do
    tech_lower = String.downcase(tech)

    all()
    |> Enum.filter(fn project ->
      Enum.any?(project.tech_stack, fn stack_item ->
        String.downcase(stack_item) == tech_lower
      end)
    end)
  end

  @doc """
  Returns a color-coded status indicator for a project.
  Uses ASCII art and gradient characters for visual appeal.
  """
  @spec status_indicator(:active | :completed | :archived) :: String.t()
  def status_indicator(:active), do: "█ Active"
  def status_indicator(:completed), do: "▓ Done"
  def status_indicator(:archived), do: "░ Archive"

  @doc """
  Returns count of projects
  """
  @spec count() :: integer()
  def count, do: length(all())
end
