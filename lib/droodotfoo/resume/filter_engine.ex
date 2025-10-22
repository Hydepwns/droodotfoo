defmodule Droodotfoo.Resume.FilterEngine do
  @moduledoc """
  Core filtering engine for resume data.

  Provides comprehensive filtering capabilities including:
  - Technology filtering (languages, frameworks, tools)
  - Company/position filtering
  - Date range filtering
  - Achievement and description text matching
  - Logical combinations (AND/OR)

  ## Examples

      iex> resume_data = ResumeData.get_resume_data()
      iex> FilterEngine.filter(resume_data, %{technologies: ["Elixir"]})
      %{experience: [...], education: [...]}

      iex> FilterEngine.filter(resume_data, %{
      ...>   technologies: ["Rust", "Go"],
      ...>   logic: :or
      ...> })
      %{experience: [...]}

  """

  @type filter_options :: %{
          optional(:technologies) => list(String.t()),
          optional(:companies) => list(String.t()),
          optional(:positions) => list(String.t()),
          optional(:date_range) => %{from: String.t(), to: String.t()},
          optional(:text_search) => String.t(),
          optional(:logic) => :and | :or,
          optional(:include_sections) => list(atom())
        }

  @type filtered_result :: %{
          experience: list(map()),
          education: list(map()),
          defense_projects: list(map()),
          portfolio: map(),
          certifications: list(map()),
          match_count: non_neg_integer(),
          filters_applied: map()
        }

  @doc """
  Filters resume data based on provided criteria.

  ## Options

    * `:technologies` - List of technology names to match (languages, frameworks, tools)
    * `:companies` - List of company names to match
    * `:positions` - List of position titles to match
    * `:date_range` - Date range filter %{from: "2020-01", to: "2024-01"}
    * `:text_search` - Free text search across descriptions and achievements
    * `:logic` - Combination logic `:and` or `:or` (default: `:and`)
    * `:include_sections` - Sections to include in results (default: all)

  ## Examples

      # Filter by technology
      filter(resume_data, %{technologies: ["Elixir", "Rust"]})

      # Filter by company OR position
      filter(resume_data, %{
        companies: ["Blockdaemon"],
        positions: ["CEO"],
        logic: :or
      })

      # Text search with date range
      filter(resume_data, %{
        text_search: "blockchain",
        date_range: %{from: "2022-01", to: "2024-12"}
      })

  """
  @spec filter(map(), filter_options()) :: filtered_result()
  def filter(resume_data, options \\ %{})

  def filter(resume_data, options) when is_map(options) do
    filter_options = parse_filter_options(options)
    filtered = build_filtered_results(resume_data, filter_options)

    Map.merge(filtered, %{
      match_count: calculate_match_count(filtered),
      filters_applied: options
    })
  end

  defp parse_filter_options(options) do
    %{
      logic: Map.get(options, :logic, :and),
      include_sections:
        Map.get(options, :include_sections, [
          :experience,
          :education,
          :defense_projects,
          :portfolio,
          :certifications
        ]),
      options: options
    }
  end

  defp build_filtered_results(resume_data, filter_options) do
    %{
      experience:
        filter_if_included(
          resume_data,
          :experience,
          filter_options,
          &filter_experience/3
        ),
      education:
        filter_if_included(
          resume_data,
          :education,
          filter_options,
          &filter_education/3
        ),
      defense_projects:
        filter_if_included(
          resume_data,
          :defense_projects,
          filter_options,
          &filter_defense_projects/3
        ),
      portfolio:
        filter_if_included(
          resume_data,
          :portfolio,
          filter_options,
          &filter_portfolio/3
        ),
      certifications:
        filter_if_included(
          resume_data,
          :certifications,
          filter_options,
          &filter_certifications/3
        )
    }
  end

  defp filter_if_included(resume_data, section, filter_options, filter_fn) do
    case section in filter_options.include_sections do
      true ->
        data = Map.get(resume_data, section, default_value_for(section))
        filter_fn.(data, filter_options.options, filter_options.logic)

      false ->
        default_value_for(section)
    end
  end

  defp default_value_for(:portfolio), do: %{}
  defp default_value_for(_), do: []

  defp calculate_match_count(filtered) do
    portfolio_count =
      case map_size(filtered.portfolio) do
        0 -> 0
        _ -> 1
      end

    length(filtered.experience) +
      length(filtered.education) +
      length(filtered.defense_projects) +
      length(filtered.certifications) +
      portfolio_count
  end

  @doc """
  Filters experience entries based on criteria.
  """
  @spec filter_experience(list(map()), filter_options(), :and | :or) :: list(map())
  def filter_experience(experience_list, options, logic) do
    matcher_fns = [
      &match_technologies?/2,
      &match_companies?/2,
      &match_positions?/2,
      &match_date_range?/2,
      &match_text_search?/2
    ]

    filter_section(experience_list, matcher_fns, options, logic)
  end

  @doc """
  Filters education entries.
  """
  @spec filter_education(list(map()), filter_options(), :and | :or) :: list(map())
  def filter_education(education_list, options, logic) do
    matcher_fns = [
      &match_text_search_education?/2,
      &match_date_range?/2
    ]

    filter_section(education_list, matcher_fns, options, logic)
  end

  @doc """
  Filters defense project entries.
  """
  @spec filter_defense_projects(list(map()), filter_options(), :and | :or) :: list(map())
  def filter_defense_projects(projects, options, logic) do
    matcher_fns = [
      &match_technologies_defense?/2,
      &match_text_search_defense?/2,
      &match_date_range?/2
    ]

    filter_section(projects, matcher_fns, options, logic)
  end

  @doc """
  Filters portfolio based on criteria.
  Returns empty map if no matches, original portfolio if matches.
  """
  @spec filter_portfolio(map(), filter_options(), :and | :or) :: map()
  def filter_portfolio(portfolio, _options, _logic) when map_size(portfolio) == 0, do: %{}

  def filter_portfolio(portfolio, options, logic) do
    projects = Map.get(portfolio, :projects, [])

    matcher_fns = [
      &match_text_search_portfolio?/2,
      &match_technologies_portfolio?/2
    ]

    filtered_projects = filter_section(projects, matcher_fns, options, logic)

    case filtered_projects do
      [] -> %{}
      projects -> Map.put(portfolio, :projects, projects)
    end
  end

  @doc """
  Filters certifications.
  """
  @spec filter_certifications(list(map()), filter_options(), :and | :or) :: list(map())
  def filter_certifications(certifications, options, logic) do
    matcher_fns = [
      &match_text_search_certification?/2
    ]

    filter_section(certifications, matcher_fns, options, logic)
  end

  # Private helper functions

  # Generic filter function for any section type
  defp filter_section(items, matcher_fns, options, logic) when is_list(items) do
    Enum.filter(items, fn item ->
      matches =
        matcher_fns
        |> Enum.map(fn matcher_fn -> matcher_fn.(item, options) end)
        |> Enum.reject(&is_nil/1)

      apply_logic(matches, logic)
    end)
  end

  # Generic text search matcher - takes field names to search
  defp match_text_in_fields(_item, %{text_search: nil}, _fields), do: nil
  defp match_text_in_fields(_item, %{text_search: ""}, _fields), do: nil

  defp match_text_in_fields(item, %{text_search: query}, fields) when is_list(fields) do
    searchable_text =
      fields
      |> Enum.map_join(" ", fn field ->
        case Map.get(item, field) do
          value when is_list(value) -> Enum.join(value, " ")
          value when is_binary(value) -> value
          _ -> ""
        end
      end)
      |> String.downcase()

    String.contains?(searchable_text, String.downcase(query))
  end

  defp match_text_in_fields(_item, _options, _fields), do: nil

  # No filters means match all
  defp apply_logic([], _logic), do: true
  defp apply_logic(matches, :and), do: Enum.all?(matches)
  defp apply_logic(matches, :or), do: Enum.any?(matches)

  defp match_technologies?(_exp, %{technologies: []}), do: nil
  defp match_technologies?(_exp, %{technologies: nil}), do: nil

  defp match_technologies?(exp, %{technologies: techs}) do
    exp_techs = extract_technologies(exp)

    Enum.any?(techs, fn tech ->
      Enum.any?(exp_techs, fn exp_tech ->
        String.downcase(exp_tech) =~ String.downcase(tech)
      end)
    end)
  end

  defp match_technologies?(_exp, _options), do: nil

  defp match_technologies_defense?(_project, %{technologies: []}), do: nil
  defp match_technologies_defense?(_project, %{technologies: nil}), do: nil

  defp match_technologies_defense?(project, %{technologies: techs}) do
    project_techs = extract_technologies_defense(project)

    Enum.any?(techs, fn tech ->
      Enum.any?(project_techs, fn proj_tech ->
        String.downcase(proj_tech) =~ String.downcase(tech)
      end)
    end)
  end

  defp match_technologies_defense?(_project, _options), do: nil

  defp match_technologies_portfolio?(_project, %{technologies: []}), do: nil
  defp match_technologies_portfolio?(_project, %{technologies: nil}), do: nil

  defp match_technologies_portfolio?(project, %{technologies: techs}) do
    project_lang = Map.get(project, :language, "")

    Enum.any?(techs, fn tech ->
      String.downcase(project_lang) =~ String.downcase(tech)
    end)
  end

  defp match_technologies_portfolio?(_project, _options), do: nil

  defp match_companies?(_exp, %{companies: []}), do: nil
  defp match_companies?(_exp, %{companies: nil}), do: nil

  defp match_companies?(exp, %{companies: companies}) do
    exp_company = Map.get(exp, :company, "")

    Enum.any?(companies, fn company ->
      String.downcase(exp_company) =~ String.downcase(company)
    end)
  end

  defp match_companies?(_exp, _options), do: nil

  defp match_positions?(_exp, %{positions: []}), do: nil
  defp match_positions?(_exp, %{positions: nil}), do: nil

  defp match_positions?(exp, %{positions: positions}) do
    exp_position = Map.get(exp, :position, "")

    Enum.any?(positions, fn position ->
      String.downcase(exp_position) =~ String.downcase(position)
    end)
  end

  defp match_positions?(_exp, _options), do: nil

  defp match_date_range?(_item, %{date_range: nil}), do: nil
  defp match_date_range?(_item, %{date_range: %{from: nil, to: nil}}), do: nil

  defp match_date_range?(item, %{date_range: %{from: from_date, to: to_date}}) do
    start_date = Map.get(item, :start_date, "")
    end_date = Map.get(item, :end_date, "Present")

    # Normalize "Current" or "Present" to today's date for comparison
    end_date_normalized =
      if end_date in ["Current", "Present"],
        do: Date.to_iso8601(Date.utc_today()),
        else: end_date

    # Check if date ranges overlap
    date_in_range?(start_date, end_date_normalized, from_date, to_date)
  end

  defp match_date_range?(_item, _options), do: nil

  defp match_text_search?(exp, options) do
    match_text_in_fields(exp, options, [:company, :position, :description, :achievements])
  end

  defp match_text_search_education?(edu, options) do
    match_text_in_fields(edu, options, [:institution, :degree, :field, :concentration])
  end

  defp match_text_search_defense?(project, options) do
    match_text_in_fields(project, options, [:name, :description, :role])
  end

  defp match_text_search_portfolio?(project, options) do
    match_text_in_fields(project, options, [:name, :description, :language])
  end

  defp match_text_search_certification?(cert, options) do
    match_text_in_fields(cert, options, [:name, :issuer])
  end

  defp extract_technologies(exp) do
    technologies = Map.get(exp, :technologies, %{})

    [
      Map.get(technologies, :languages, []),
      Map.get(technologies, :frameworks, []),
      Map.get(technologies, :tools, []),
      Map.get(technologies, :methodologies, [])
    ]
    |> List.flatten()
  end

  defp extract_technologies_defense(project) do
    technologies = Map.get(project, :technologies, %{})

    [
      Map.get(technologies, :domains, []),
      Map.get(technologies, :systems, []),
      Map.get(technologies, :methodologies, []),
      Map.get(technologies, :impact, [])
    ]
    |> List.flatten()
  end

  defp date_in_range?(start_date, end_date, from_date, to_date) do
    # Parse dates in YYYY-MM format
    with {:ok, start} <- parse_date(start_date),
         {:ok, end_d} <- parse_date(end_date),
         {:ok, from} <- parse_date(from_date),
         {:ok, to} <- parse_date(to_date) do
      # Check if ranges overlap
      Date.compare(start, to) != :gt and Date.compare(end_d, from) != :lt
    else
      _ -> false
    end
  end

  defp parse_date(date_string) when is_binary(date_string) do
    case String.split(date_string, "-") do
      [year, month] ->
        Date.new(String.to_integer(year), String.to_integer(month), 1)

      [year, month, day] ->
        Date.new(String.to_integer(year), String.to_integer(month), String.to_integer(day))

      _ ->
        {:error, :invalid_format}
    end
  rescue
    _ -> {:error, :parse_error}
  end

  defp parse_date(_), do: {:error, :invalid_input}
end
