defmodule Droodotfoo.Resume.SearchIndex do
  @moduledoc """
  Search indexing and fuzzy matching for resume data.

  Provides intelligent search capabilities including:
  - Fuzzy string matching with configurable threshold
  - Weighted search results based on field importance
  - Technology autocomplete suggestions
  - Search term highlighting

  ## Examples

      iex> resume_data = ResumeData.get_resume_data()
      iex> SearchIndex.search(resume_data, "blockchian")  # Typo
      %{results: [...], suggestions: ["blockchain"], match_count: 3}

      iex> SearchIndex.search(resume_data, "rust", threshold: 0.7)
      %{results: [...], match_count: 2}

  """

  @type search_result :: %{
          results: map(),
          suggestions: list(String.t()),
          match_count: non_neg_integer(),
          query: String.t(),
          corrected_query: String.t() | nil
        }

  @type search_options :: %{
          optional(:threshold) => float(),
          optional(:max_results) => non_neg_integer(),
          optional(:sections) => list(atom())
        }

  @doc """
  Performs fuzzy search across resume data.

  ## Options

    * `:threshold` - Fuzzy matching threshold (0.0-1.0, default: 0.6)
    * `:max_results` - Maximum number of results to return per section
    * `:sections` - Sections to search (default: all)

  ## Examples

      # Basic search
      search(resume_data, "blockchain")

      # Strict fuzzy matching
      search(resume_data, "elixr", threshold: 0.8)

      # Search specific sections only
      search(resume_data, "nuclear", sections: [:experience, :defense_projects])

  """
  @spec search(map(), String.t(), search_options()) :: search_result()
  def search(resume_data, query, options \\ %{})

  def search(_resume_data, "", _options) do
    %{
      results: %{},
      suggestions: [],
      match_count: 0,
      query: "",
      corrected_query: nil
    }
  end

  def search(resume_data, query, options) when is_binary(query) do
    search_options = parse_search_options(options)
    normalized_query = String.downcase(String.trim(query))

    results = build_search_results(resume_data, normalized_query, search_options)
    suggestions = generate_suggestions(resume_data, normalized_query, search_options.threshold)
    corrected = suggest_correction(suggestions, normalized_query, search_options.threshold)

    %{
      results: results,
      suggestions: suggestions,
      match_count: count_matches(results),
      query: query,
      corrected_query: corrected
    }
  end

  defp parse_search_options(options) do
    %{
      threshold: Map.get(options, :threshold, 0.6),
      max_results: Map.get(options, :max_results, 50),
      sections:
        Map.get(options, :sections, [
          :experience,
          :education,
          :defense_projects,
          :portfolio,
          :certifications
        ])
    }
  end

  defp build_search_results(resume_data, query, options) do
    %{
      experience: search_section(resume_data, :experience, query, options, &search_experience/4),
      education: search_section(resume_data, :education, query, options, &search_education/4),
      defense_projects:
        search_section(resume_data, :defense_projects, query, options, &search_defense_projects/4),
      portfolio: search_section(resume_data, :portfolio, query, options, &search_portfolio/3),
      certifications:
        search_section(resume_data, :certifications, query, options, &search_certifications/4)
    }
  end

  defp search_section(resume_data, section_name, query, options, search_fn)
       when section_name in [:experience, :education, :defense_projects, :certifications] do
    case section_name in options.sections do
      true ->
        data = Map.get(resume_data, section_name, [])
        search_fn.(data, query, options.threshold, options.max_results)

      false ->
        []
    end
  end

  defp search_section(resume_data, :portfolio, query, options, search_fn) do
    case :portfolio in options.sections do
      true ->
        data = Map.get(resume_data, :portfolio, %{})
        search_fn.(data, query, options.threshold)

      false ->
        %{}
    end
  end

  @doc """
  Generates autocomplete suggestions based on partial input.

  ## Examples

      iex> autocomplete(resume_data, "elix")
      ["Elixir"]

      iex> autocomplete(resume_data, "rus")
      ["Rust", "Russian"]

  """
  @spec autocomplete(map(), String.t(), keyword()) :: list(String.t())
  def autocomplete(resume_data, partial), do: autocomplete(resume_data, partial, [])

  def autocomplete(_resume_data, partial, _opts) when byte_size(partial) < 2, do: []

  def autocomplete(resume_data, partial, opts) do
    limit = Keyword.get(opts, :limit, 10)
    normalized_partial = String.downcase(String.trim(partial))

    resume_data
    |> extract_all_searchable_terms()
    |> Enum.filter(fn term ->
      String.downcase(term) |> String.starts_with?(normalized_partial)
    end)
    |> Enum.uniq()
    |> Enum.take(limit)
  end

  @doc """
  Extracts all unique technologies from resume data.
  Useful for building filter UIs and autocomplete.
  """
  @spec extract_technologies(map()) :: %{
          languages: list(String.t()),
          frameworks: list(String.t()),
          tools: list(String.t()),
          all: list(String.t())
        }
  def extract_technologies(resume_data) do
    experience = resume_data.experience || []

    all_techs =
      Enum.flat_map(experience, fn exp ->
        techs = Map.get(exp, :technologies, %{})

        [
          Map.get(techs, :languages, []),
          Map.get(techs, :frameworks, []),
          Map.get(techs, :tools, [])
        ]
        |> List.flatten()
      end)
      |> Enum.uniq()
      |> Enum.sort()

    languages =
      Enum.flat_map(experience, fn exp ->
        get_in(exp, [:technologies, :languages]) || []
      end)
      |> Enum.uniq()
      |> Enum.sort()

    frameworks =
      Enum.flat_map(experience, fn exp ->
        get_in(exp, [:technologies, :frameworks]) || []
      end)
      |> Enum.uniq()
      |> Enum.sort()

    tools =
      Enum.flat_map(experience, fn exp ->
        get_in(exp, [:technologies, :tools]) || []
      end)
      |> Enum.uniq()
      |> Enum.sort()

    %{
      languages: languages,
      frameworks: frameworks,
      tools: tools,
      all: all_techs
    }
  end

  # Private helper functions

  defp search_experience(experience_list, query, threshold, max_results) do
    experience_list
    |> Enum.map(fn exp ->
      score = calculate_experience_score(exp, query, threshold)
      {exp, score}
    end)
    |> Enum.filter(fn {_exp, score} -> score > 0 end)
    |> Enum.sort_by(fn {_exp, score} -> score end, :desc)
    |> Enum.take(max_results)
    |> Enum.map(fn {exp, _score} -> exp end)
  end

  defp search_education(education_list, query, threshold, max_results) do
    education_list
    |> Enum.map(fn edu ->
      score = calculate_education_score(edu, query, threshold)
      {edu, score}
    end)
    |> Enum.filter(fn {_edu, score} -> score > 0 end)
    |> Enum.sort_by(fn {_edu, score} -> score end, :desc)
    |> Enum.take(max_results)
    |> Enum.map(fn {edu, _score} -> edu end)
  end

  defp search_defense_projects(projects, query, threshold, max_results) do
    projects
    |> Enum.map(fn proj ->
      score = calculate_defense_score(proj, query, threshold)
      {proj, score}
    end)
    |> Enum.filter(fn {_proj, score} -> score > 0 end)
    |> Enum.sort_by(fn {_proj, score} -> score end, :desc)
    |> Enum.take(max_results)
    |> Enum.map(fn {proj, _score} -> proj end)
  end

  defp search_portfolio(portfolio, _query, _threshold) when map_size(portfolio) == 0, do: %{}

  defp search_portfolio(portfolio, query, threshold) do
    projects = Map.get(portfolio, :projects, [])

    matched_projects =
      projects
      |> Enum.map(fn proj ->
        score = calculate_portfolio_score(proj, query, threshold)
        {proj, score}
      end)
      |> Enum.filter(fn {_proj, score} -> score > 0 end)
      |> Enum.sort_by(fn {_proj, score} -> score end, :desc)
      |> Enum.map(fn {proj, _score} -> proj end)

    case matched_projects do
      [] -> %{}
      projects -> Map.put(portfolio, :projects, projects)
    end
  end

  defp search_certifications(certifications, query, threshold, max_results) do
    certifications
    |> Enum.map(fn cert ->
      score = calculate_certification_score(cert, query, threshold)
      {cert, score}
    end)
    |> Enum.filter(fn {_cert, score} -> score > 0 end)
    |> Enum.sort_by(fn {_cert, score} -> score end, :desc)
    |> Enum.take(max_results)
    |> Enum.map(fn {cert, _score} -> cert end)
  end

  # Scoring functions - weighted by field importance

  defp calculate_experience_score(exp, query, threshold) do
    company_score = fuzzy_match(Map.get(exp, :company, ""), query, threshold) * 3.0
    position_score = fuzzy_match(Map.get(exp, :position, ""), query, threshold) * 3.0
    description_score = fuzzy_match(Map.get(exp, :description, ""), query, threshold) * 1.5

    achievements = Map.get(exp, :achievements, [])

    achievements_score =
      achievements
      |> Enum.map(&fuzzy_match(&1, query, threshold))
      |> Enum.max(fn -> 0.0 end)
      |> Kernel.*(2.0)

    technologies = extract_experience_technologies(exp)

    tech_score =
      technologies
      |> Enum.map(&fuzzy_match(&1, query, threshold))
      |> Enum.max(fn -> 0.0 end)
      |> Kernel.*(2.5)

    company_score + position_score + description_score + achievements_score + tech_score
  end

  defp calculate_education_score(edu, query, threshold) do
    institution_score = fuzzy_match(Map.get(edu, :institution, ""), query, threshold) * 2.5
    degree_score = fuzzy_match(Map.get(edu, :degree, ""), query, threshold) * 2.0
    field_score = fuzzy_match(Map.get(edu, :field, ""), query, threshold) * 2.5

    institution_score + degree_score + field_score
  end

  defp calculate_defense_score(project, query, threshold) do
    name_score = fuzzy_match(Map.get(project, :name, ""), query, threshold) * 3.0
    description_score = fuzzy_match(Map.get(project, :description, ""), query, threshold) * 2.0
    role_score = fuzzy_match(Map.get(project, :role, ""), query, threshold) * 1.5

    name_score + description_score + role_score
  end

  defp calculate_portfolio_score(project, query, threshold) do
    name_score = fuzzy_match(Map.get(project, :name, ""), query, threshold) * 3.0
    description_score = fuzzy_match(Map.get(project, :description, ""), query, threshold) * 2.0
    language_score = fuzzy_match(Map.get(project, :language, ""), query, threshold) * 2.5

    name_score + description_score + language_score
  end

  defp calculate_certification_score(cert, query, threshold) do
    name_score = fuzzy_match(Map.get(cert, :name, ""), query, threshold) * 3.0
    issuer_score = fuzzy_match(Map.get(cert, :issuer, ""), query, threshold) * 1.5

    name_score + issuer_score
  end

  # Fuzzy matching using Jaro-Winkler distance approximation
  defp fuzzy_match(text, query, threshold) when is_binary(text) do
    normalized_text = String.downcase(text)
    normalized_query = String.downcase(query)

    cond do
      # Exact match - highest score
      normalized_text == normalized_query ->
        1.0

      # Contains exact query - high score
      String.contains?(normalized_text, normalized_query) ->
        0.9

      # Starts with query - good score
      String.starts_with?(normalized_text, normalized_query) ->
        0.85

      # Fuzzy match using simple Levenshtein-like approach
      true ->
        score = simple_fuzzy_score(normalized_text, normalized_query)

        case score >= threshold do
          true -> score
          false -> 0.0
        end
    end
  end

  defp fuzzy_match(_, _, _), do: 0.0

  # Simplified fuzzy matching algorithm (character overlap)
  defp simple_fuzzy_score(text, query) do
    text_chars = String.graphemes(text) |> MapSet.new()
    query_chars = String.graphemes(query) |> MapSet.new()

    intersection = MapSet.intersection(text_chars, query_chars) |> MapSet.size()
    union = MapSet.union(text_chars, query_chars) |> MapSet.size()

    case union do
      0 -> 0.0
      _ -> intersection / union
    end
  end

  defp extract_experience_technologies(exp) do
    techs = Map.get(exp, :technologies, %{})

    [
      Map.get(techs, :languages, []),
      Map.get(techs, :frameworks, []),
      Map.get(techs, :tools, [])
    ]
    |> List.flatten()
  end

  defp count_matches(results) do
    portfolio_count =
      case map_size(results.portfolio) do
        0 -> 0
        _ -> 1
      end

    length(results.experience) +
      length(results.education) +
      length(results.defense_projects) +
      length(results.certifications) +
      portfolio_count
  end

  defp generate_suggestions(resume_data, query, threshold) do
    all_terms = extract_all_searchable_terms(resume_data)

    all_terms
    |> Enum.map(fn term ->
      score = fuzzy_match(term, query, threshold * 0.7)
      {term, score}
    end)
    |> Enum.filter(fn {_term, score} -> score > 0 end)
    |> Enum.sort_by(fn {_term, score} -> score end, :desc)
    |> Enum.take(5)
    |> Enum.map(fn {term, _score} -> term end)
  end

  defp suggest_correction(suggestions, query, _threshold) do
    case suggestions do
      [best | _] when best != query -> best
      _ -> nil
    end
  end

  defp extract_all_searchable_terms(resume_data) do
    experience_terms = extract_experience_terms(resume_data.experience || [])
    technology_terms = extract_technology_terms(resume_data.experience || [])
    company_terms = Enum.map(resume_data.experience || [], &Map.get(&1, :company, ""))
    position_terms = Enum.map(resume_data.experience || [], &Map.get(&1, :position, ""))

    (experience_terms ++ technology_terms ++ company_terms ++ position_terms)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp extract_experience_terms(experience_list) do
    Enum.flat_map(experience_list, fn exp ->
      [
        Map.get(exp, :company, ""),
        Map.get(exp, :position, "")
      ]
    end)
  end

  defp extract_technology_terms(experience_list) do
    Enum.flat_map(experience_list, fn exp ->
      techs = Map.get(exp, :technologies, %{})

      [
        Map.get(techs, :languages, []),
        Map.get(techs, :frameworks, []),
        Map.get(techs, :tools, [])
      ]
      |> List.flatten()
    end)
  end
end
