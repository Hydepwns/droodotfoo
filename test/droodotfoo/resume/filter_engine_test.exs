defmodule Droodotfoo.Resume.FilterEngineTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Resume.{FilterEngine, ResumeData}

  describe "filter/2" do
    setup do
      resume_data = ResumeData.get_hardcoded_resume_data()
      {:ok, resume_data: resume_data}
    end

    test "filters by technology with AND logic", %{resume_data: resume_data} do
      result =
        FilterEngine.filter(resume_data, %{
          technologies: ["Elixir"],
          logic: :and
        })

      assert result.match_count > 0
      assert result.experience != []

      # Check that all matched experience entries contain Elixir
      Enum.each(result.experience, fn exp ->
        techs = Map.get(exp, :technologies, %{})
        languages = Map.get(techs, :languages, [])
        assert "Elixir" in languages
      end)
    end

    test "filters by multiple technologies with OR logic", %{resume_data: resume_data} do
      result =
        FilterEngine.filter(resume_data, %{
          technologies: ["Elixir", "Rust", "Go"],
          logic: :or
        })

      assert result.match_count > 0
      assert result.experience != []
    end

    test "filters by company name", %{resume_data: resume_data} do
      result =
        FilterEngine.filter(resume_data, %{
          companies: ["Blockdaemon"],
          logic: :and
        })

      assert result.match_count > 0
      assert result.experience != []

      # Check that matched company is correct
      exp = List.first(result.experience)
      assert exp.company =~ "Blockdaemon"
    end

    test "filters by position title", %{resume_data: resume_data} do
      result =
        FilterEngine.filter(resume_data, %{
          positions: ["CEO"],
          logic: :and
        })

      assert result.match_count > 0
      assert result.experience != []

      exp = List.first(result.experience)
      assert exp.position =~ "CEO"
    end

    test "filters by date range", %{resume_data: resume_data} do
      result =
        FilterEngine.filter(resume_data, %{
          date_range: %{from: "2022-01", to: "2024-12"},
          logic: :and
        })

      assert result.match_count > 0
      assert result.experience != []
    end

    test "filters by text search across descriptions", %{resume_data: resume_data} do
      result =
        FilterEngine.filter(resume_data, %{
          text_search: "blockchain",
          logic: :and
        })

      assert result.match_count > 0
    end

    test "combines multiple filters with AND logic", %{resume_data: resume_data} do
      result =
        FilterEngine.filter(resume_data, %{
          technologies: ["Elixir"],
          companies: ["axol.io"],
          logic: :and
        })

      assert result.match_count > 0

      # All results should match both criteria
      exp = List.first(result.experience)
      assert exp.company =~ "axol.io"

      techs = Map.get(exp, :technologies, %{})
      languages = Map.get(techs, :languages, [])
      assert "Elixir" in languages
    end

    test "returns empty results when no matches", %{resume_data: resume_data} do
      result =
        FilterEngine.filter(resume_data, %{
          technologies: ["NonexistentTech"],
          logic: :and,
          include_sections: [:experience]
        })

      # Should have no experience matches
      assert result.experience == []
    end

    test "filters specific sections only", %{resume_data: resume_data} do
      result =
        FilterEngine.filter(resume_data, %{
          include_sections: [:experience],
          text_search: "blockchain"
        })

      # Should only return experience, not education or other sections
      assert Enum.empty?(result.education)
      assert Enum.empty?(result.certifications)
    end

    test "handles empty filter options", %{resume_data: resume_data} do
      result = FilterEngine.filter(resume_data, %{})

      # Empty filter should return all items
      assert result.match_count > 0
      assert length(result.experience) == length(resume_data.experience)
    end

    test "filters portfolio projects by language", %{resume_data: resume_data} do
      result =
        FilterEngine.filter(resume_data, %{
          technologies: ["Elixir"],
          include_sections: [:portfolio]
        })

      if map_size(result.portfolio) > 0 do
        projects = Map.get(result.portfolio, :projects, [])
        assert projects != []

        # Check that at least one project is Elixir
        assert Enum.any?(projects, fn proj ->
                 Map.get(proj, :language) == "Elixir"
               end)
      end
    end

    test "filters certifications by text search", %{resume_data: resume_data} do
      result =
        FilterEngine.filter(resume_data, %{
          text_search: "Security",
          include_sections: [:certifications]
        })

      if result.certifications != [] do
        cert = List.first(result.certifications)
        cert_text = "#{cert.name} #{cert.issuer}"
        assert String.contains?(String.downcase(cert_text), "security")
      end
    end
  end

  describe "filter_experience/3" do
    setup do
      experience = [
        %{
          company: "Test Company",
          position: "Engineer",
          start_date: "2022-01",
          end_date: "2024-01",
          technologies: %{languages: ["Elixir", "Rust"]},
          achievements: ["Built something cool"]
        }
      ]

      {:ok, experience: experience}
    end

    test "filters experience by technology", %{experience: experience} do
      result = FilterEngine.filter_experience(experience, %{technologies: ["Elixir"]}, :and)

      assert length(result) == 1
    end

    test "filters experience by company", %{experience: experience} do
      result = FilterEngine.filter_experience(experience, %{companies: ["Test Company"]}, :and)

      assert length(result) == 1
    end

    test "returns empty when no match", %{experience: experience} do
      result = FilterEngine.filter_experience(experience, %{companies: ["Other Company"]}, :and)

      assert result == []
    end
  end
end
