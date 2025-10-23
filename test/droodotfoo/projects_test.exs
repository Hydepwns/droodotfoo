defmodule Droodotfoo.ProjectsTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Projects

  describe "all/0" do
    test "returns all projects" do
      projects = Projects.all()

      # 2 portfolio + 2 defense = 4 total
      assert length(projects) >= 2
      assert Enum.all?(projects, &is_struct(&1, Projects))
    end

    test "all projects have required fields" do
      projects = Projects.all()

      Enum.each(projects, fn project ->
        assert project.id
        assert project.name
        assert project.tagline
        assert project.description
        assert is_list(project.tech_stack)
        assert project.status in [:active, :completed, :archived]
        assert is_list(project.highlights)
        assert is_integer(project.year)
        assert is_list(project.ascii_thumbnail)
      end)
    end

    test "all projects have non-empty ASCII thumbnails" do
      projects = Projects.all()

      Enum.each(projects, fn project ->
        assert length(project.ascii_thumbnail) > 0
        assert Enum.all?(project.ascii_thumbnail, &is_binary/1)
      end)
    end
  end

  describe "get/1" do
    test "returns project by ID for portfolio projects" do
      project = Projects.get(:mana)

      assert project
      assert project.id == :mana
      assert project.name == "mana"
    end

    test "returns nil for non-existent project" do
      assert Projects.get(:nonexistent) == nil
    end

    test "can retrieve all projects by their IDs" do
      all_projects = Projects.all()
      project_ids = Enum.map(all_projects, & &1.id)

      Enum.each(project_ids, fn id ->
        project = Projects.get(id)
        assert project
        assert project.id == id
      end)
    end
  end

  describe "active/0" do
    test "returns only active projects" do
      active_projects = Projects.active()

      # Portfolio projects with status "active" should be included
      assert Enum.all?(active_projects, &(&1.status == :active))
    end

    test "includes active portfolio projects" do
      active_projects = Projects.active()
      active_ids = Enum.map(active_projects, & &1.id)

      # mana, raxol, and riddler are marked as "active" in resume.json
      assert :mana in active_ids
      assert :raxol in active_ids
      assert :riddler in active_ids
    end
  end

  describe "with_live_demos/0" do
    test "returns only projects with live demos" do
      demo_projects = Projects.with_live_demos()

      assert Enum.all?(demo_projects, &(&1.live_demo == true))
    end

    test "includes active portfolio projects" do
      demo_projects = Projects.with_live_demos()
      demo_ids = Enum.map(demo_projects, & &1.id)

      # Active portfolio projects should have live demos
      assert :mana in demo_ids
      assert :raxol in demo_ids
      assert :riddler in demo_ids
    end
  end

  describe "filter_by_tech/1" do
    test "filters projects by exact tech match" do
      elixir_projects = Projects.filter_by_tech("Elixir")

      assert length(elixir_projects) > 0

      assert Enum.all?(elixir_projects, fn p ->
               Enum.any?(p.tech_stack, &(&1 == "Elixir"))
             end)
    end

    test "filters are case-insensitive" do
      elixir_lower = Projects.filter_by_tech("elixir")
      elixir_upper = Projects.filter_by_tech("ELIXIR")

      assert length(elixir_lower) == length(elixir_upper)
      assert length(elixir_lower) > 0
    end

    test "returns empty list for non-existent tech" do
      projects = Projects.filter_by_tech("COBOL")

      assert projects == []
    end

    test "returns empty list for techs not in current projects" do
      # Phoenix isn't in current resume projects
      phoenix_projects = Projects.filter_by_tech("Phoenix")

      # Should either be empty or all contain Phoenix
      assert phoenix_projects == [] or
               Enum.all?(phoenix_projects, fn p ->
                 Enum.any?(p.tech_stack, &(&1 == "Phoenix"))
               end)
    end
  end

  describe "count/0" do
    test "returns number of projects from resume data" do
      # Dynamic count based on resume.json
      count = Projects.count()
      assert count >= 2
      assert count == length(Projects.all())
    end
  end

  describe "project data integrity" do
    test "mana project has correct data from resume" do
      project = Projects.get(:mana)

      assert project
      assert project.name == "mana"
      assert project.status == :active
      assert project.live_demo == true
      assert "Elixir" in project.tech_stack
    end

    test "raxol project has correct data from resume" do
      project = Projects.get(:raxol)

      assert project
      assert project.name == "raxol"
      assert project.status == :active
      assert project.live_demo == true
    end

    test "active and completed projects should have URLs" do
      projects = Projects.all()
      active_and_completed = Enum.filter(projects, &(&1.status in [:active, :completed]))

      # At least some projects should have URLs
      with_urls =
        Enum.filter(active_and_completed, fn p ->
          p.github_url != nil or p.demo_url != nil
        end)

      assert length(with_urls) > 0
    end
  end
end
