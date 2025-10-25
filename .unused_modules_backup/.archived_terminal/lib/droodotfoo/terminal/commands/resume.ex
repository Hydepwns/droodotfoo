defmodule Droodotfoo.Terminal.Commands.Resume do
  @moduledoc """
  Terminal commands for interactive resume filtering and searching.

  Provides commands for:
  - Filtering: resume filter <criteria>
  - Searching: resume search <query>
  - Presets: resume preset save/load/list
  - Export: resume export [format]
  """

  use Droodotfoo.Terminal.CommandBase

  alias Droodotfoo.Resume.{FilterEngine, PresetManager, QueryBuilder, ResumeData, SearchIndex}

  @impl true
  def execute("resume", [], state) do
    help_text = """
    Resume Commands
    ===============

    Available subcommands:
      filter <criteria>              Apply filters to resume
      search <query>                 Fuzzy search across resume
      clear                          Clear all filters
      preset save <name>             Save current filter as preset
      preset load <name>             Load saved preset
      preset list                    List all available presets
      preset delete <name>           Delete a preset
      export [format]                Export filtered resume
      technologies                   List all technologies in resume
      autocomplete <partial>         Get autocomplete suggestions

    Filter Syntax:
      tech:<technology>              Filter by technology
      company:<company>              Filter by company
      position:<position>            Filter by position title
      from:<YYYY-MM> to:<YYYY-MM>    Filter by date range
      text:"<query>"                 Text search
      OR / AND                       Combine filters with logic

    Examples:
      resume filter tech:Elixir
      resume filter tech:Rust OR tech:Go
      resume search blockchain
      resume filter from:2022-01 to:2024-12
      resume preset load blockchain
      resume export pdf
    """

    {:ok, help_text, state}
  end

  @impl true
  def execute("resume", ["filter" | filter_args], state) do
    case apply_filter(filter_args) do
      {:ok, result} ->
        output = format_filter_results(result)
        new_state = Map.put(state, :resume_filter, result)
        {:ok, output, new_state}

      {:error, reason} ->
        {:error, "Filter error: #{reason}", state}
    end
  end

  @impl true
  def execute("resume", ["search" | search_args], state) do
    query = Enum.join(search_args, " ")

    resume_data = ResumeData.get_resume_data()
    result = SearchIndex.search(resume_data, query)

    output = format_search_results(result)
    new_state = Map.put(state, :resume_search, result)

    {:ok, output, new_state}
  end

  @impl true
  def execute("resume", ["clear"], state) do
    new_state =
      state
      |> Map.delete(:resume_filter)
      |> Map.delete(:resume_search)

    {:ok, "All resume filters cleared", new_state}
  end

  @impl true
  def execute("resume", ["preset", "save", name], state) do
    current_filter = Map.get(state, :resume_filter)

    if current_filter && current_filter.filters_applied do
      case PresetManager.save_preset(name, current_filter.filters_applied) do
        {:ok, ^name} ->
          {:ok, "Preset '#{name}' saved successfully", state}

        {:error, reason} ->
          {:error, "Failed to save preset: #{reason}", state}
      end
    else
      {:error, "No active filter to save. Apply a filter first.", state}
    end
  end

  @impl true
  def execute("resume", ["preset", "load", name], state) do
    case PresetManager.load_preset(name) do
      {:ok, filters} ->
        resume_data = ResumeData.get_resume_data()
        result = FilterEngine.filter(resume_data, filters)

        output = """
        Loaded preset: #{name}

        #{format_filter_results(result)}
        """

        new_state = Map.put(state, :resume_filter, result)
        {:ok, output, new_state}

      {:error, reason} ->
        {:error, reason, state}
    end
  end

  @impl true
  def execute("resume", ["preset", "list"], state) do
    presets = PresetManager.list_presets()

    output = format_preset_list(presets)
    {:ok, output, state}
  end

  @impl true
  def execute("resume", ["preset", "delete", name], state) do
    case PresetManager.delete_preset(name) do
      :ok ->
        {:ok, "Preset '#{name}' deleted successfully", state}

      {:error, reason} ->
        {:error, reason, state}
    end
  end

  @impl true
  def execute("resume", ["export"], state) do
    execute("resume", ["export", "pdf"], state)
  end

  @impl true
  def execute("resume", ["export", format], state) do
    current_filter = Map.get(state, :resume_filter)

    output =
      if current_filter do
        """
        Exporting filtered resume (#{format})...

        Filters applied:
        #{format_filters_summary(current_filter.filters_applied)}

        Matched items: #{current_filter.match_count}

        [============================] 100%

        Export complete: resume_filtered.#{format}

        Note: Visit /resume to download the PDF
        """
      else
        """
        Exporting full resume (#{format})...

        [============================] 100%

        Export complete: resume.#{format}

        Note: Visit /resume to download the PDF
        """
      end

    {:ok, output, state}
  end

  @impl true
  def execute("resume", ["technologies"], state) do
    resume_data = ResumeData.get_resume_data()
    techs = SearchIndex.extract_technologies(resume_data)

    output = """
    Technologies in Resume
    ======================

    Languages (#{length(techs.languages)}):
      #{Enum.join(techs.languages, ", ")}

    Frameworks (#{length(techs.frameworks)}):
      #{Enum.join(techs.frameworks, ", ")}

    Tools (#{length(techs.tools)}):
      #{Enum.join(techs.tools, ", ")}

    Total technologies: #{length(techs.all)}
    """

    {:ok, output, state}
  end

  @impl true
  def execute("resume", ["autocomplete" | partial_args], state) do
    partial = Enum.join(partial_args, " ")
    resume_data = ResumeData.get_resume_data()

    suggestions = SearchIndex.autocomplete(resume_data, partial)

    output =
      if Enum.empty?(suggestions) do
        "No suggestions for '#{partial}'"
      else
        """
        Autocomplete suggestions for '#{partial}':
          #{Enum.join(suggestions, "\n  ")}
        """
      end

    {:ok, output, state}
  end

  @impl true
  def execute("resume", args, state) do
    {:error, "Unknown resume command. Try 'resume' for help. Args: #{inspect(args)}", state}
  end

  # Private helper functions

  defp apply_filter(filter_args) do
    query_string = Enum.join(filter_args, " ")

    case QueryBuilder.parse_query(query_string) do
      {:ok, query_builder} ->
        case QueryBuilder.build(query_builder) do
          {:ok, filter_options} ->
            resume_data = ResumeData.get_resume_data()
            result = FilterEngine.filter(resume_data, filter_options)
            {:ok, result}

          {:error, errors} when is_list(errors) ->
            {:error, Enum.join(errors, "; ")}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp format_filter_results(result) do
    sections = []

    sections =
      if length(result.experience) > 0 do
        sections ++ [format_experience_section(result.experience)]
      else
        sections
      end

    sections =
      if length(result.education) > 0 do
        sections ++ [format_education_section(result.education)]
      else
        sections
      end

    sections =
      if length(result.defense_projects) > 0 do
        sections ++ [format_defense_section(result.defense_projects)]
      else
        sections
      end

    sections =
      if map_size(result.portfolio) > 0 do
        sections ++ [format_portfolio_section(result.portfolio)]
      else
        sections
      end

    sections =
      if length(result.certifications) > 0 do
        sections ++ [format_certifications_section(result.certifications)]
      else
        sections
      end

    header = """
    Resume Filter Results
    =====================

    Filters applied: #{format_filters_summary(result.filters_applied)}
    Total matches: #{result.match_count}
    """

    if Enum.empty?(sections) do
      header <> "\nNo matches found. Try adjusting your filters."
    else
      header <> "\n\n" <> Enum.join(sections, "\n\n")
    end
  end

  defp format_search_results(result) do
    header = """
    Resume Search Results
    =====================

    Query: #{result.query}
    #{if result.corrected_query, do: "Did you mean: #{result.corrected_query}?\n", else: ""}
    Total matches: #{result.match_count}
    """

    if result.match_count == 0 do
      suggestions_text =
        if length(result.suggestions) > 0 do
          "\nSuggestions:\n  " <> Enum.join(result.suggestions, "\n  ")
        else
          ""
        end

      header <> "\nNo matches found." <> suggestions_text
    else
      sections = []

      sections =
        if length(result.results.experience) > 0 do
          sections ++ [format_experience_section(result.results.experience)]
        else
          sections
        end

      sections =
        if length(result.results.education) > 0 do
          sections ++ [format_education_section(result.results.education)]
        else
          sections
        end

      header <> "\n\n" <> Enum.join(sections, "\n\n")
    end
  end

  defp format_experience_section(experience_list) do
    """
    Experience (#{length(experience_list)} matches):
    #{Enum.map_join(experience_list, "\n", fn exp -> "  - #{exp.position} at #{exp.company} (#{exp.start_date} - #{exp.end_date})" end)}
    """
  end

  defp format_education_section(education_list) do
    """
    Education (#{length(education_list)} matches):
    #{Enum.map_join(education_list, "\n", fn edu -> "  - #{edu.degree} in #{edu.field}, #{edu.institution}" end)}
    """
  end

  defp format_defense_section(projects) do
    """
    Defense Projects (#{length(projects)} matches):
    #{Enum.map_join(projects, "\n", fn proj -> "  - #{proj.name} (#{proj.role})" end)}
    """
  end

  defp format_portfolio_section(portfolio) do
    projects = Map.get(portfolio, :projects, [])

    """
    Portfolio (#{length(projects)} projects):
    #{Enum.map_join(projects, "\n", fn proj -> "  - #{proj.name} (#{proj.language}): #{proj.description}" end)}
    """
  end

  defp format_certifications_section(certifications) do
    """
    Certifications (#{length(certifications)} matches):
    #{Enum.map_join(certifications, "\n", fn cert -> "  - #{cert.name} from #{cert.issuer}" end)}
    """
  end

  defp format_filters_summary(filters) when is_map(filters) do
    parts =
      [
        format_filter_technologies(filters),
        format_filter_companies(filters),
        format_filter_text_search(filters),
        format_filter_date_range(filters),
        format_filter_logic(filters)
      ]
      |> Enum.reject(&is_nil/1)

    if Enum.empty?(parts) do
      "None"
    else
      Enum.join(parts, " | ")
    end
  end

  defp format_filters_summary(_), do: "None"

  defp format_filter_technologies(%{technologies: techs})
       when is_list(techs) and length(techs) > 0,
       do: "Technologies: #{Enum.join(techs, ", ")}"

  defp format_filter_technologies(_), do: nil

  defp format_filter_companies(%{companies: companies})
       when is_list(companies) and length(companies) > 0,
       do: "Companies: #{Enum.join(companies, ", ")}"

  defp format_filter_companies(_), do: nil

  defp format_filter_text_search(%{text_search: search}) when is_binary(search),
    do: "Text: \"#{search}\""

  defp format_filter_text_search(_), do: nil

  defp format_filter_date_range(%{date_range: %{from: from, to: to}}),
    do: "Date: #{from} to #{to}"

  defp format_filter_date_range(_), do: nil

  defp format_filter_logic(%{logic: :or}), do: "(OR logic)"
  defp format_filter_logic(_), do: nil

  defp format_preset_list([]), do: "No saved presets"

  defp format_preset_list(presets) do
    header = """
    Saved Resume Filter Presets
    ===========================

    """

    system_presets = Enum.filter(presets, & &1.is_system)
    user_presets = Enum.reject(presets, & &1.is_system)

    system_section = format_preset_section("System Presets", system_presets)
    user_section = format_preset_section("User Presets", user_presets)

    header <> system_section <> user_section
  end

  defp format_preset_section(_title, []), do: ""

  defp format_preset_section(title, presets) do
    """
    #{title}:
    #{Enum.map_join(presets, "\n", &format_preset_item/1)}

    """
  end

  defp format_preset_item(preset) do
    tags = format_preset_tags(preset.tags)
    description = preset.description || "No description"
    "  #{preset.name}#{tags} - #{description}"
  end

  defp format_preset_tags([]), do: ""
  defp format_preset_tags(tags), do: " [#{Enum.join(tags, ", ")}]"
end
