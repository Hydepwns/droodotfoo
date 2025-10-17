defmodule Droodotfoo.ProjectsTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Projects

  describe "all/0" do
    test "returns all projects" do
      projects = Projects.all()

      assert length(projects) == 6
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
    test "returns project by ID" do
      project = Projects.get(:droodotfoo)

      assert project
      assert project.id == :droodotfoo
      assert project.name == "droo.foo Terminal Portfolio"
    end

    test "returns nil for non-existent project" do
      assert Projects.get(:nonexistent) == nil
    end

    test "can retrieve all projects by their IDs" do
      project_ids = [
        :droodotfoo,
        :raxol_web,
        :crdt_collab,
        :obsidian_blog,
        :fintech_payments,
        :event_microservices
      ]

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

      assert length(active_projects) > 0
      assert Enum.all?(active_projects, &(&1.status == :active))
    end

    test "includes droodotfoo and crdt_collab" do
      active_projects = Projects.active()
      active_ids = Enum.map(active_projects, & &1.id)

      assert :droodotfoo in active_ids
      assert :crdt_collab in active_ids
    end
  end

  describe "with_live_demos/0" do
    test "returns only projects with live demos" do
      demo_projects = Projects.with_live_demos()

      assert length(demo_projects) > 0
      assert Enum.all?(demo_projects, &(&1.live_demo == true))
    end

    test "includes droodotfoo" do
      demo_projects = Projects.with_live_demos()
      demo_ids = Enum.map(demo_projects, & &1.id)

      assert :droodotfoo in demo_ids
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

    test "can filter by Phoenix" do
      phoenix_projects = Projects.filter_by_tech("Phoenix")

      assert length(phoenix_projects) > 0

      assert Enum.all?(phoenix_projects, fn p ->
               Enum.any?(p.tech_stack, &(&1 == "Phoenix"))
             end)
    end
  end

  describe "count/0" do
    test "returns correct number of projects" do
      assert Projects.count() == 6
    end
  end

  describe "project data integrity" do
    test "droodotfoo project has correct data" do
      project = Projects.get(:droodotfoo)

      assert project.name == "droo.foo Terminal Portfolio"
      assert project.status == :active
      assert project.live_demo == true
      assert project.demo_url == "https://droo.foo"
      assert "Elixir" in project.tech_stack
      assert "Phoenix" in project.tech_stack
      assert length(project.highlights) == 6
    end

    test "raxol_web project has correct data" do
      project = Projects.get(:raxol_web)

      assert project.name == "RaxolWeb Framework"
      assert project.status == :completed
      assert project.live_demo == false
      assert project.year == 2025
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
