defmodule Droodotfoo.GitHubTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.GitHub
  alias Droodotfoo.Projects

  describe "enrich_project/1" do
    test "returns project unchanged when no github_url" do
      project = %Projects{
        id: "test",
        name: "test",
        tagline: "test",
        description: "test",
        tech_stack: [],
        topics: [],
        github_url: nil,
        demo_url: nil,
        live_demo: false,
        status: :active,
        highlights: [],
        year: 2024,
        github_data: nil
      }

      result = GitHub.enrich_project(project)
      assert result == project
    end

    test "returns project unchanged for invalid github_url" do
      project = %Projects{
        id: "test",
        name: "test",
        tagline: "test",
        description: "test",
        tech_stack: [],
        topics: [],
        github_url: "not-a-valid-url",
        demo_url: nil,
        live_demo: false,
        status: :active,
        highlights: [],
        year: 2024,
        github_data: nil
      }

      result = GitHub.enrich_project(project)
      assert result == project
    end
  end

  describe "enrich_projects/1" do
    test "returns empty list for empty input" do
      assert GitHub.enrich_projects([]) == []
    end

    test "handles projects without github_url" do
      projects = [
        %Projects{
          id: "test1",
          name: "test1",
          tagline: "test",
          description: "test",
          tech_stack: [],
          topics: [],
          github_url: nil,
          demo_url: nil,
          live_demo: false,
          status: :active,
          highlights: [],
          year: 2024,
          github_data: nil
        }
      ]

      result = GitHub.enrich_projects(projects)
      assert length(result) == 1
    end
  end

  describe "clear_cache/0" do
    test "clears the cache without error" do
      assert GitHub.clear_cache() == :ok
    end
  end
end
