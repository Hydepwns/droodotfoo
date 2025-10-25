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
    :topics,
    :github_url,
    :demo_url,
    :live_demo,
    :status,
    :highlights,
    :year,
    :ascii_thumbnail,
    :github_data
  ]

  @type github_data :: %{
          repo_info: map() | nil,
          languages: map() | nil,
          latest_commit: map() | nil,
          latest_release: map() | nil
        }

  @type t :: %__MODULE__{
          id: atom(),
          name: String.t(),
          tagline: String.t(),
          description: String.t(),
          tech_stack: list(String.t()),
          topics: list(String.t()),
          github_url: String.t() | nil,
          demo_url: String.t() | nil,
          live_demo: boolean(),
          status: :active | :completed | :archived,
          highlights: list(String.t()),
          year: integer(),
          ascii_thumbnail: list(String.t()),
          github_data: github_data() | nil
        }

  @doc "Returns all projects from resume data (defense_projects + portfolio.projects)"
  @spec all() :: list(t())
  def all do
    resume = ResumeData.get_resume_data()
    defense = convert_defense_projects(resume[:defense_projects] || [])
    portfolio = convert_portfolio_projects(resume[:portfolio][:projects] || [])
    portfolio ++ defense
  end

  @doc "Gets a project by ID"
  @spec get(atom()) :: t() | nil
  def get(id), do: Enum.find(all(), &(&1.id == id))

  @doc "Returns active projects only"
  @spec active() :: list(t())
  def active, do: Enum.filter(all(), &(&1.status == :active))

  @doc "Returns projects with live demos"
  @spec with_live_demos() :: list(t())
  def with_live_demos, do: Enum.filter(all(), &(&1.live_demo))

  @doc "Filters projects by tech stack"
  @spec filter_by_tech(String.t()) :: list(t())
  def filter_by_tech(tech) do
    tech_lower = String.downcase(tech)
    Enum.filter(all(), &Enum.any?(&1.tech_stack, fn t -> String.downcase(t) == tech_lower end))
  end

  @doc "Enriches projects with GitHub data (cached or real-time)"
  @spec with_github_data() :: list(t())
  def with_github_data do
    all()
    |> Droodotfoo.GitHub.enrich_projects()
  end

  @doc "Enriches a single project with GitHub data"
  @spec enrich_with_github_data(t()) :: t()
  def enrich_with_github_data(project) do
    Droodotfoo.GitHub.enrich_project(project)
  end

  @doc "Returns a color-coded status indicator for a project"
  @spec status_indicator(:active | :completed | :archived) :: String.t()
  def status_indicator(:active), do: "█ Active"
  def status_indicator(:completed), do: "▓ Done"
  def status_indicator(:archived), do: "░ Archive"

  @doc "Returns count of projects"
  @spec count() :: integer()
  def count, do: length(all())

  # Private functions

  defp convert_defense_projects(projects) do
    Enum.map(projects, &build_project(:defense, &1))
  end

  defp convert_portfolio_projects(projects) do
    Enum.map(projects, &build_project(:portfolio, &1))
  end

  defp build_project(type, raw_project) do
    %__MODULE__{
      id: to_id(raw_project.name),
      name: raw_project.name,
      tagline: extract_tagline_for(type, raw_project),
      description: raw_project.description,
      tech_stack: extract_tech_stack_for(type, raw_project),
      topics: extract_topics_for(type, raw_project),
      github_url: extract_github_url_for(type, raw_project),
      demo_url: extract_demo_url_for(type, raw_project),
      live_demo: is_live_demo?(type, raw_project),
      status: parse_status(raw_project[:status], default_status_for(type)),
      highlights: extract_highlights_for(type, raw_project),
      year: extract_year_for(type, raw_project),
      ascii_thumbnail: generate_thumbnail(type, raw_project.name)
    }
  end

  # Type-specific extractors

  defp extract_tagline_for(:defense, raw_project),
    do: extract_tagline(raw_project.description)

  defp extract_tagline_for(:portfolio, raw_project),
    do: raw_project.description

  defp extract_tech_stack_for(:defense, raw_project),
    do: extract_tech_stack(raw_project[:technologies] || %{})

  defp extract_tech_stack_for(:portfolio, raw_project),
    do: [raw_project[:language] || "N/A"]

  defp extract_github_url_for(:defense, raw_project),
    do: normalize_url(raw_project[:url])

  defp extract_github_url_for(:portfolio, raw_project),
    do: raw_project.url

  defp extract_demo_url_for(:defense, _raw_project), do: nil

  defp extract_demo_url_for(:portfolio, raw_project),
    do: if(raw_project[:status] == "active", do: raw_project.url)

  defp is_live_demo?(:defense, _raw_project), do: false
  defp is_live_demo?(:portfolio, raw_project), do: raw_project[:status] == "active"

  defp default_status_for(:defense), do: :completed
  defp default_status_for(:portfolio), do: :active

  defp extract_year_for(:defense, raw_project), do: extract_year(raw_project[:start_date])
  defp extract_year_for(:portfolio, _raw_project), do: DateTime.utc_now().year

  defp extract_highlights_for(:defense, _raw_project), do: []
  defp extract_highlights_for(:portfolio, raw_project), do: raw_project[:highlights] || []

  defp extract_topics_for(:defense, _raw_project), do: []
  defp extract_topics_for(:portfolio, raw_project), do: raw_project[:topics] || []

  defp to_id(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.to_atom()
  end

  defp extract_tech_stack(technologies) when is_map(technologies) do
    technologies
    |> Enum.reject(fn {_k, v} -> is_nil(v) or v == [] end)
    |> Enum.flat_map(fn {_category, items} -> items end)
    |> Enum.uniq()
  end

  defp extract_tech_stack(_), do: []

  defp extract_tagline(description) do
    description |> String.split(". ") |> List.first() |> String.slice(0..60)
  end

  defp parse_status(status, default) when is_binary(status) do
    case String.downcase(status) do
      "active" -> :active
      "completed" -> :completed
      "archived" -> :archived
      _ -> default
    end
  end

  defp parse_status(_, default), do: default

  defp normalize_url(url) when url in ["Classified", "Proprietary", nil], do: nil
  defp normalize_url(url), do: url

  defp extract_year(date) when is_binary(date) do
    with [year | _] <- String.split(date, "-"),
         {year_int, ""} <- Integer.parse(year) do
      year_int
    else
      _ -> DateTime.utc_now().year
    end
  end

  defp extract_year(_), do: DateTime.utc_now().year

  defp generate_thumbnail(:defense, name) do
    [
      "╭──────────────────────╮",
      "│  DEFENSE PROJECT     │",
      "│  ═══════════════     │",
      "│                      │",
      "│  ╔═══════════════╗   │",
      "│  ║  CLASSIFIED   ║   │",
      "│  ║   █████████   ║   │",
      "│  ║   ░░░░░░░░░   ║   │",
      "│  ╚═══════════════╝   │",
      "│                      │",
      "│  #{pad(name)}        │",
      "╰──────────────────────╯"
    ]
  end

  defp generate_thumbnail(:portfolio, name) do
    [
      "╭──────────────────────╮",
      "│  OPEN SOURCE         │",
      "│  ═══════════         │",
      "│                      │",
      "│      ╭─────────╮     │",
      "│      │  CODE   │     │",
      "│      │  ░▒▓▒░  │     │",
      "│      │  ░▒▓▒░  │     │",
      "│      ╰─────────╯     │",
      "│                      │",
      "│  #{pad(name)}        │",
      "╰──────────────────────╯"
    ]
  end

  defp pad(name), do: name |> String.slice(0..19) |> String.pad_trailing(21)
end
