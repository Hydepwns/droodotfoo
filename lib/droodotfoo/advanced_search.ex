defmodule Droodotfoo.AdvancedSearch do
  @moduledoc """
  Advanced search functionality with fuzzy matching, regex support, and highlighting
  """

  defstruct [
    :query,
    :mode,
    :results,
    :history,
    :max_history,
    :highlight_color,
    :case_sensitive
  ]

  @type search_mode :: :fuzzy | :exact | :regex
  @type search_result :: %{
    section: atom(),
    line: String.t(),
    line_number: integer(),
    match_positions: [integer()],
    score: float()
  }

  @doc """
  Creates a new search state
  """
  def new(opts \\ []) do
    %__MODULE__{
      query: "",
      mode: Keyword.get(opts, :mode, :fuzzy),
      results: [],
      history: [],
      max_history: Keyword.get(opts, :max_history, 50),
      highlight_color: Keyword.get(opts, :highlight_color, :yellow),
      case_sensitive: Keyword.get(opts, :case_sensitive, false)
    }
  end

  @doc """
  Performs a search across all content sections
  """
  def search(state, query, content_map) when is_binary(query) do
    results =
      case state.mode do
        :fuzzy -> fuzzy_search(query, content_map, state.case_sensitive)
        :exact -> exact_search(query, content_map, state.case_sensitive)
        :regex -> regex_search(query, content_map, state.case_sensitive)
      end

    new_history = add_to_history(state.history, query, state.max_history)

    %{state |
      query: query,
      results: results |> Enum.sort_by(&(-&1.score)),
      history: new_history
    }
  end

  @doc """
  Fuzzy search with scoring based on match quality
  """
  def fuzzy_search(query, content_map, case_sensitive) do
    query_chars = prepare_query(query, case_sensitive) |> String.graphemes()

    content_map
    |> Enum.flat_map(fn {section, content} ->
      content
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.map(fn {line, line_num} ->
        case fuzzy_match(query_chars, line, case_sensitive) do
          {true, positions, score} ->
            %{
              section: section,
              line: line,
              line_number: line_num,
              match_positions: positions,
              score: score
            }
          {false, _, _} ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    end)
  end

  @doc """
  Exact substring search
  """
  def exact_search(query, content_map, case_sensitive) do
    search_query = prepare_query(query, case_sensitive)

    content_map
    |> Enum.flat_map(fn {section, content} ->
      content
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.map(fn {line, line_num} ->
        search_line = prepare_query(line, case_sensitive)

        if String.contains?(search_line, search_query) do
          positions = find_all_positions(search_line, search_query)
          %{
            section: section,
            line: line,
            line_number: line_num,
            match_positions: positions,
            score: calculate_exact_score(positions, String.length(line))
          }
        else
          nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    end)
  end

  @doc """
  Regular expression search
  """
  def regex_search(query, content_map, case_sensitive) do
    case compile_regex(query, case_sensitive) do
      {:ok, regex} ->
        content_map
        |> Enum.flat_map(fn {section, content} ->
          content
          |> String.split("\n")
          |> Enum.with_index(1)
          |> Enum.map(fn {line, line_num} ->
            case Regex.run(regex, line, return: :index) do
              nil ->
                nil
              matches ->
                positions = extract_match_positions(matches)
                %{
                  section: section,
                  line: line,
                  line_number: line_num,
                  match_positions: positions,
                  score: calculate_regex_score(positions, String.length(line))
                }
            end
          end)
          |> Enum.reject(&is_nil/1)
        end)

      {:error, _} ->
        []
    end
  end

  @doc """
  Highlights matches in a line of text
  """
  def highlight_line(line, positions, color \\ :yellow) do
    positions
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.reduce(line, fn pos, acc ->
      {before, rest} = String.split_at(acc, pos)
      {char, after_char} = String.split_at(rest, 1)

      highlighted_char = apply_color(char, color)
      before <> highlighted_char <> after_char
    end)
  end

  @doc """
  Gets search suggestions based on history and current input
  """
  def get_suggestions(state, partial_query) do
    state.history
    |> Enum.filter(fn hist_query ->
      String.starts_with?(
        String.downcase(hist_query),
        String.downcase(partial_query)
      )
    end)
    |> Enum.take(5)
  end

  @doc """
  Switches search mode
  """
  def set_mode(state, mode) when mode in [:fuzzy, :exact, :regex] do
    %{state | mode: mode}
  end

  @doc """
  Clears search results
  """
  def clear(state) do
    %{state | query: "", results: []}
  end

  # Private helper functions

  defp prepare_query(text, false), do: String.downcase(text)
  defp prepare_query(text, true), do: text

  defp fuzzy_match(query_chars, line, case_sensitive) do
    line_to_search = prepare_query(line, case_sensitive)

    result =
      query_chars
      |> Enum.reduce_while({[], 0}, fn char, {positions, last_pos} ->
        # Find the character starting from last position
        case find_char_position(line_to_search, char, last_pos) do
          nil ->
            {:halt, :no_match}
          pos ->
            {:cont, {[pos | positions], pos + 1}}
        end
      end)

    case result do
      :no_match ->
        {false, [], 0.0}
      {positions, _} ->
        positions_list = Enum.reverse(positions)
        score = calculate_fuzzy_score(positions_list, String.length(line))
        {true, positions_list, score}
    end
  end

  defp find_char_position(text, char, start_from) do
    substring = String.slice(text, start_from..-1//1)
    case :binary.match(substring, char) do
      {pos, _} -> start_from + pos
      :nomatch -> nil
    end
  end

  defp find_all_positions(text, substring) do
    find_all_positions(text, substring, 0, [])
  end

  defp find_all_positions(text, substring, offset, positions) do
    case :binary.match(text, substring, [{:scope, {offset, byte_size(text) - offset}}]) do
      {pos, len} ->
        new_positions = Enum.to_list(pos..(pos + len - 1)) ++ positions
        find_all_positions(text, substring, pos + len, new_positions)
      :nomatch ->
        Enum.reverse(positions)
    end
  end

  defp compile_regex(pattern, case_sensitive) do
    options = if case_sensitive, do: [], else: [:caseless]

    try do
      {:ok, Regex.compile!(pattern, options)}
    rescue
      _ -> {:error, "Invalid regex pattern"}
    end
  end

  defp extract_match_positions(matches) do
    matches
    |> Enum.flat_map(fn
      {start, length} -> Enum.to_list(start..(start + length - 1))
      _ -> []
    end)
  end

  defp calculate_fuzzy_score(positions, line_length) do
    if positions == [], do: 0.0, else: calculate_fuzzy_score_impl(positions, line_length)
  end

  defp calculate_fuzzy_score_impl(positions, line_length) do

    # Score based on:
    # 1. Compactness of matches (closer together is better)
    # 2. Early matches (matches near beginning are better)
    # 3. Match density (more matches relative to line length)

    compactness =
      if length(positions) > 1 do
        range = Enum.max(positions) - Enum.min(positions)
        1.0 - (range / line_length)
      else
        1.0
      end

    earliness = 1.0 - (Enum.min(positions) / line_length)
    density = length(positions) / line_length

    (compactness * 0.4 + earliness * 0.4 + density * 0.2)
  end

  defp calculate_exact_score(positions, line_length) do
    if positions == [], do: 0.0, else: calculate_exact_score_impl(positions, line_length)
  end

  defp calculate_exact_score_impl(positions, line_length) do

    # Exact matches score higher based on position and frequency
    position_score = 1.0 - (Enum.min(positions) / line_length)
    frequency_score = length(positions) / line_length

    (position_score * 0.7 + frequency_score * 0.3)
  end

  defp calculate_regex_score(positions, line_length) do
    if positions == [], do: 0.0, else: calculate_regex_score_impl(positions, line_length)
  end

  defp calculate_regex_score_impl(positions, line_length) do

    # Regex matches score based on coverage and position
    coverage = length(positions) / line_length
    position_score = 1.0 - (Enum.min(positions) / line_length)

    (coverage * 0.5 + position_score * 0.5)
  end

  defp add_to_history(history, query, max_history) do
    [query | Enum.reject(history, &(&1 == query))]
    |> Enum.take(max_history)
  end

  defp apply_color(text, color) do
    # ANSI color codes for terminal display
    color_code =
      case color do
        :yellow -> "33"
        :red -> "31"
        :green -> "32"
        :blue -> "34"
        :magenta -> "35"
        :cyan -> "36"
        _ -> "33"
      end

    "\e[#{color_code};1m#{text}\e[0m"
  end
end