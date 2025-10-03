defmodule Droodotfoo.AdvancedSearchTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.AdvancedSearch

  @sample_content %{
    projects: """
    Elixir Terminal Framework
    Real-time collaboration tools
    Phoenix LiveView applications
    Distributed systems monitoring
    """,
    skills: """
    Elixir programming language
    Ruby on Rails development
    JavaScript and TypeScript
    PostgreSQL database management
    """,
    experience: """
    Senior Software Engineer at TechCorp
    Lead developer for distributed systems
    Open source contributor to Elixir projects
    Technical mentor and team lead
    """
  }

  describe "new/1" do
    test "creates search state with default settings" do
      search = AdvancedSearch.new()

      assert search.query == ""
      assert search.mode == :fuzzy
      assert search.results == []
      assert search.history == []
      assert search.max_history == 50
      assert search.case_sensitive == false
    end

    test "accepts custom options" do
      search = AdvancedSearch.new(
        mode: :exact,
        max_history: 100,
        case_sensitive: true
      )

      assert search.mode == :exact
      assert search.max_history == 100
      assert search.case_sensitive == true
    end
  end

  describe "fuzzy_search/3" do
    test "finds matches with characters in order" do
      results = AdvancedSearch.fuzzy_search("elx", @sample_content, false)

      assert length(results) > 0
      # Should match "Elixir" in multiple places
      assert Enum.any?(results, fn r ->
        String.contains?(String.downcase(r.line), "elixir")
      end)
    end

    test "scores closer matches higher" do
      results = AdvancedSearch.fuzzy_search("elixir", @sample_content, false)

      # Results should be found
      assert length(results) > 0

      # Lines with exact "elixir" should score higher
      top_result = List.first(results)
      assert String.contains?(String.downcase(top_result.line), "elixir")
    end

    test "respects case sensitivity when enabled" do
      results_insensitive = AdvancedSearch.fuzzy_search("ELIXIR", @sample_content, false)
      results_sensitive = AdvancedSearch.fuzzy_search("ELIXIR", @sample_content, true)

      assert length(results_insensitive) > 0
      assert length(results_sensitive) == 0
    end
  end

  describe "exact_search/3" do
    test "finds exact substring matches" do
      results = AdvancedSearch.exact_search("Software Engineer", @sample_content, false)

      assert length(results) == 1
      assert List.first(results).section == :experience
      assert String.contains?(List.first(results).line, "Software Engineer")
    end

    test "finds all occurrences of substring" do
      results = AdvancedSearch.exact_search("systems", @sample_content, false)

      # Should find "systems" in multiple sections
      assert length(results) >= 2
      sections = results |> Enum.map(& &1.section) |> Enum.uniq()
      assert :projects in sections
      assert :experience in sections
    end

    test "returns empty list for non-existent substring" do
      results = AdvancedSearch.exact_search("nonexistent", @sample_content, false)
      assert results == []
    end
  end

  describe "regex_search/3" do
    test "finds matches with valid regex pattern" do
      results = AdvancedSearch.regex_search("^[A-Z]\\w+", @sample_content, false)

      # Should match lines starting with capital letters
      assert length(results) > 0
      assert Enum.all?(results, fn r ->
        String.match?(r.line, ~r/^[A-Z]/)
      end)
    end

    test "handles complex regex patterns" do
      results = AdvancedSearch.regex_search("(Elixir|Ruby|JavaScript)", @sample_content, false)

      assert length(results) > 0
      assert Enum.any?(results, fn r ->
        String.contains?(r.line, "Elixir") or
        String.contains?(r.line, "Ruby") or
        String.contains?(r.line, "JavaScript")
      end)
    end

    test "returns empty list for invalid regex" do
      results = AdvancedSearch.regex_search("[invalid(regex", @sample_content, false)
      assert results == []
    end
  end

  describe "search/3" do
    test "performs search with current mode and updates state" do
      search = AdvancedSearch.new(mode: :fuzzy)
      updated = AdvancedSearch.search(search, "elixir", @sample_content)

      assert updated.query == "elixir"
      assert length(updated.results) > 0
      assert "elixir" in updated.history
    end

    test "sorts results by score" do
      search = AdvancedSearch.new(mode: :fuzzy)
      updated = AdvancedSearch.search(search, "elixir", @sample_content)

      scores = Enum.map(updated.results, & &1.score)
      assert scores == Enum.sort(scores, &>=/2)
    end

    test "maintains search history" do
      search = AdvancedSearch.new()

      search = AdvancedSearch.search(search, "first", @sample_content)
      assert search.history == ["first"]

      search = AdvancedSearch.search(search, "second", @sample_content)
      assert search.history == ["second", "first"]

      # Duplicate queries don't create duplicate history entries
      search = AdvancedSearch.search(search, "first", @sample_content)
      assert search.history == ["first", "second"]
    end
  end

  describe "highlight_line/3" do
    test "highlights matched positions in text" do
      line = "Elixir programming language"
      positions = [0, 1, 2, 3, 4, 5]  # "Elixir"

      highlighted = AdvancedSearch.highlight_line(line, positions)

      # Should contain ANSI escape codes for highlighting
      assert String.contains?(highlighted, "\e[")
      assert String.contains?(highlighted, "m")
    end

    test "highlights multiple separate matches" do
      line = "Elixir and Erlang are great"
      positions = [0, 1, 2, 3, 4, 5, 11, 12, 13, 14, 15, 16]  # "Elixir" and "Erlang"

      highlighted = AdvancedSearch.highlight_line(line, positions)

      # Should contain multiple escape sequences
      escape_count = highlighted |> String.graphemes() |> Enum.count(&(&1 == "\e"))
      assert escape_count >= 4  # At least 2 highlights (start and end for each)
    end
  end

  describe "set_mode/2" do
    test "changes search mode" do
      search = AdvancedSearch.new(mode: :fuzzy)

      search = AdvancedSearch.set_mode(search, :exact)
      assert search.mode == :exact

      search = AdvancedSearch.set_mode(search, :regex)
      assert search.mode == :regex
    end
  end

  describe "get_suggestions/2" do
    test "returns matching suggestions from history" do
      search = %AdvancedSearch{
        history: ["elixir", "erlang", "ruby", "rust", "python"]
      }

      suggestions = AdvancedSearch.get_suggestions(search, "r")
      assert "ruby" in suggestions
      assert "rust" in suggestions
      assert "elixir" not in suggestions
    end

    test "limits suggestions to 5" do
      search = %AdvancedSearch{
        history: ["test1", "test2", "test3", "test4", "test5", "test6", "test7"]
      }

      suggestions = AdvancedSearch.get_suggestions(search, "test")
      assert length(suggestions) == 5
    end
  end

  describe "clear/1" do
    test "clears query and results" do
      search = %AdvancedSearch{
        query: "test",
        results: [%{section: :test, line: "test line"}],
        history: ["test"]
      }

      cleared = AdvancedSearch.clear(search)

      assert cleared.query == ""
      assert cleared.results == []
      # History should be preserved
      assert cleared.history == ["test"]
    end
  end

  describe "scoring algorithms" do
    test "fuzzy search favors compact matches" do
      content = %{
        test: """
        elixir is great
        e l i x i r spread out
        """
      }

      results = AdvancedSearch.fuzzy_search("elixir", content, false)

      # First result should be the compact "elixir"
      assert List.first(results).line == "elixir is great"
    end

    test "exact search favors early matches" do
      content = %{
        test: """
        later in line has elixir here
        elixir at the beginning
        """
      }

      results = AdvancedSearch.exact_search("elixir", content, false)

      # Should have found both lines
      assert length(results) == 2

      # Sort by score to check which scored higher
      sorted_results = Enum.sort_by(results, & &1.score, &>=/2)
      top_result = List.first(sorted_results)

      # The line starting with "elixir" should score higher
      assert String.trim(top_result.line) == "elixir at the beginning"
    end
  end

  describe "integration" do
    test "complete search workflow" do
      # Initialize search
      search = AdvancedSearch.new()

      # Perform fuzzy search
      search = AdvancedSearch.search(search, "prog", @sample_content)
      assert length(search.results) > 0

      # Switch to exact mode
      search = AdvancedSearch.set_mode(search, :exact)
      search = AdvancedSearch.search(search, "Elixir", @sample_content)
      assert Enum.all?(search.results, fn r ->
        String.contains?(r.line, "Elixir")
      end)

      # Try regex search
      search = AdvancedSearch.set_mode(search, :regex)
      search = AdvancedSearch.search(search, "^[A-Z]", @sample_content)
      assert length(search.results) > 0

      # Check history accumulated
      assert length(search.history) == 3

      # Get suggestions
      suggestions = AdvancedSearch.get_suggestions(search, "")
      assert length(suggestions) <= 5

      # Clear search
      search = AdvancedSearch.clear(search)
      assert search.results == []
      assert search.query == ""
    end
  end
end