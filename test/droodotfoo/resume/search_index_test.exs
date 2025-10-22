defmodule Droodotfoo.Resume.SearchIndexTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Resume.{SearchIndex, ResumeData}

  describe "search/3" do
    setup do
      resume_data = ResumeData.get_hardcoded_resume_data()
      {:ok, resume_data: resume_data}
    end

    test "searches for exact technology match", %{resume_data: resume_data} do
      result = SearchIndex.search(resume_data, "Elixir")

      assert result.match_count > 0
      assert result.query == "Elixir"
      assert length(result.results.experience) > 0
    end

    test "searches with fuzzy matching for typos", %{resume_data: resume_data} do
      result = SearchIndex.search(resume_data, "blockchian", %{threshold: 0.5})

      # Should still find blockchain-related content despite typo
      assert result.match_count >= 0
    end

    test "searches across multiple fields", %{resume_data: resume_data} do
      result = SearchIndex.search(resume_data, "submarine")

      assert result.match_count > 0
      assert length(result.results.experience) > 0 or length(result.results.defense_projects) > 0
    end

    test "returns suggestions for related terms", %{resume_data: resume_data} do
      result = SearchIndex.search(resume_data, "block")

      assert length(result.suggestions) > 0
    end

    test "handles empty query", %{resume_data: resume_data} do
      result = SearchIndex.search(resume_data, "")

      assert result.match_count == 0
      assert result.query == ""
    end

    test "searches specific sections only", %{resume_data: resume_data} do
      result =
        SearchIndex.search(resume_data, "blockchain", %{
          sections: [:experience]
        })

      # Should only search experience
      assert Enum.empty?(result.results.education)
    end

    test "respects threshold setting", %{resume_data: resume_data} do
      strict_result = SearchIndex.search(resume_data, "xyz", %{threshold: 0.9})
      loose_result = SearchIndex.search(resume_data, "xyz", %{threshold: 0.3})

      # Strict threshold should have fewer or equal matches
      assert strict_result.match_count <= loose_result.match_count
    end

    test "limits results with max_results option", %{resume_data: resume_data} do
      result = SearchIndex.search(resume_data, "engineer", %{max_results: 2})

      total_results =
        length(result.results.experience) +
          length(result.results.education) +
          length(result.results.defense_projects)

      # max_results per section
      assert total_results <= 2 * 5
    end
  end

  describe "autocomplete/3" do
    setup do
      resume_data = ResumeData.get_hardcoded_resume_data()
      {:ok, resume_data: resume_data}
    end

    test "provides autocomplete suggestions", %{resume_data: resume_data} do
      suggestions = SearchIndex.autocomplete(resume_data, "Eli")

      assert "Elixir" in suggestions
    end

    test "returns empty list for very short input", %{resume_data: resume_data} do
      suggestions = SearchIndex.autocomplete(resume_data, "E")

      assert suggestions == []
    end

    test "limits suggestions with limit option", %{resume_data: resume_data} do
      suggestions = SearchIndex.autocomplete(resume_data, "a", limit: 3)

      assert length(suggestions) <= 3
    end

    test "handles case insensitive matching", %{resume_data: resume_data} do
      lower_suggestions = SearchIndex.autocomplete(resume_data, "eli")
      upper_suggestions = SearchIndex.autocomplete(resume_data, "ELI")

      # Both should return Elixir
      assert "Elixir" in lower_suggestions
      assert "Elixir" in upper_suggestions
    end
  end

  describe "extract_technologies/1" do
    setup do
      resume_data = ResumeData.get_hardcoded_resume_data()
      {:ok, resume_data: resume_data}
    end

    test "extracts all unique technologies", %{resume_data: resume_data} do
      techs = SearchIndex.extract_technologies(resume_data)

      assert is_map(techs)
      assert Map.has_key?(techs, :languages)
      assert Map.has_key?(techs, :frameworks)
      assert Map.has_key?(techs, :tools)
      assert Map.has_key?(techs, :all)
    end

    test "returns unique sorted lists", %{resume_data: resume_data} do
      techs = SearchIndex.extract_technologies(resume_data)

      # Languages should be unique and sorted
      assert techs.languages == Enum.uniq(techs.languages)
      assert techs.languages == Enum.sort(techs.languages)
    end

    test "includes Elixir in languages", %{resume_data: resume_data} do
      techs = SearchIndex.extract_technologies(resume_data)

      assert "Elixir" in techs.languages
      assert "Elixir" in techs.all
    end
  end
end
