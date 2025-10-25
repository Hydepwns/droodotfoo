defmodule Droodotfoo.Terminal.FuzzySearch do
  @moduledoc """
  Fuzzy search algorithm for command matching.

  Implements a character-by-character matching algorithm with scoring
  to find commands even with typos or partial input.

  ## Examples

      iex> FuzzySearch.match?("tetris", "ttr")
      true

      iex> FuzzySearch.match?("snake", "snek")
      true

      iex> FuzzySearch.score("tetris", "tet")
      90
  """

  @doc """
  Check if a query matches a target string using fuzzy matching.

  Matches if all characters in query appear in target in order,
  but not necessarily consecutively.
  """
  @spec fuzzy_match?(String.t(), String.t()) :: boolean()
  def fuzzy_match?(target, query) when is_binary(target) and is_binary(query) do
    target_chars = String.downcase(target) |> String.graphemes()
    query_chars = String.downcase(query) |> String.graphemes()

    do_match?(target_chars, query_chars)
  end

  defp do_match?(_target, []), do: true
  defp do_match?([], _query), do: false

  defp do_match?([target_char | target_rest], [query_char | query_rest] = query) do
    if target_char == query_char do
      # Character matched, consume both
      do_match?(target_rest, query_rest)
    else
      # Character didn't match, try next target character
      do_match?(target_rest, query)
    end
  end

  @doc """
  Calculate a score for how well a query matches a target.

  Higher scores indicate better matches. Scoring factors:
  - Consecutive character matches get bonus points
  - Matches at word boundaries get bonus points
  - Shorter targets with same match quality score higher
  - Earlier matches score higher

  Returns 0 if no match, 1-100 for quality of match.
  """
  @spec score(String.t(), String.t()) :: non_neg_integer()
  def score(target, query) when is_binary(target) and is_binary(query) do
    if query == "" do
      0
    else
      target_lower = String.downcase(target)
      query_lower = String.downcase(query)

      if not fuzzy_match?(target_lower, query_lower) do
        0
      else
        # Calculate base score based on match quality
        base_score = calculate_match_score(target_lower, query_lower)

        # Apply bonuses
        bonus = calculate_bonuses(target, query, target_lower, query_lower)

        # Normalize to 1-100 range
        min(100, base_score + bonus)
      end
    end
  end

  defp calculate_match_score(target, query) do
    target_chars = String.graphemes(target)
    query_chars = String.graphemes(query)

    # Find all match positions
    positions = find_match_positions(target_chars, query_chars, 0, [])

    if positions == [] do
      0
    else
      # Calculate score based on consecutiveness
      consecutive_bonus = calculate_consecutive_bonus(positions)

      # Calculate score based on how early matches appear
      early_bonus = calculate_early_bonus(positions, String.length(target))

      # Base score inversely proportional to target length (shorter = better)
      length_score = 100 - min(50, String.length(target))

      div(length_score + consecutive_bonus + early_bonus, 3)
    end
  end

  defp find_match_positions(target_chars, query_chars, pos, acc)
  defp find_match_positions(_target, [], _pos, acc), do: Enum.reverse(acc)
  defp find_match_positions([], _query, _pos, _acc), do: []

  defp find_match_positions(
         [target_char | target_rest],
         [query_char | query_rest] = query,
         pos,
         acc
       ) do
    if target_char == query_char do
      find_match_positions(target_rest, query_rest, pos + 1, [pos | acc])
    else
      find_match_positions(target_rest, query, pos + 1, acc)
    end
  end

  defp calculate_consecutive_bonus(positions) do
    # Count consecutive matches
    positions
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.count(fn [a, b] -> b - a == 1 end)
    |> Kernel.*(10)
  end

  defp calculate_early_bonus(positions, target_length) do
    # Earlier matches get higher scores
    avg_position = Enum.sum(positions) / length(positions)
    ratio = 1 - avg_position / target_length
    trunc(ratio * 30)
  end

  defp calculate_bonuses(target, _query, target_lower, query_lower) do
    bonus = 0

    # Exact match bonus
    bonus = if target_lower == query_lower, do: bonus + 50, else: bonus

    # Prefix match bonus
    bonus = if String.starts_with?(target_lower, query_lower), do: bonus + 20, else: bonus

    # Word boundary bonus (matches at start of words)
    bonus = bonus + word_boundary_bonus(target, query_lower)

    # Alias match bonus (if target is short, likely an alias)
    bonus =
      if String.length(target_lower) <= 3 and fuzzy_match?(target_lower, query_lower),
        do: bonus + 15,
        else: bonus

    bonus
  end

  defp word_boundary_bonus(target, query) do
    # Check if query matches at word boundaries (after space, dash, underscore)
    words = String.split(target, [" ", "-", "_"])

    matching_words =
      Enum.count(words, fn word ->
        String.downcase(word) |> String.starts_with?(query)
      end)

    matching_words * 10
  end

  @doc """
  Search a list of items and return matches sorted by score.

  Takes a list of items and a search function that extracts
  searchable text from each item.

  ## Examples

      commands = [
        %{name: "tetris", aliases: ["t"]},
        %{name: "snake", aliases: []}
      ]

      FuzzySearch.search(commands, "ttr", fn cmd ->
        [cmd.name | cmd.aliases]
      end)
      # Returns commands sorted by match quality
  """
  @spec search(list(), String.t(), (any() -> list(String.t()))) ::
          list({any(), non_neg_integer()})
  def search(items, query, text_fn) when is_list(items) and is_binary(query) do
    items
    |> Enum.map(fn item ->
      # Get all searchable strings for this item
      searchable_strings = text_fn.(item)

      # Calculate max score across all searchable strings
      max_score =
        searchable_strings
        |> Enum.map(&score(&1, query))
        |> Enum.max(fn -> 0 end)

      {item, max_score}
    end)
    |> Enum.filter(fn {_item, score} -> score > 0 end)
    |> Enum.sort_by(fn {_item, score} -> score end, :desc)
  end
end
