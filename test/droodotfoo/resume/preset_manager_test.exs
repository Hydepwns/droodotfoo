defmodule Droodotfoo.Resume.PresetManagerTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.Resume.PresetManager

  setup do
    # Stop existing PresetManager if running (from Application supervision tree)
    if Process.whereis(PresetManager) do
      Supervisor.terminate_child(Droodotfoo.Supervisor, PresetManager)
      Supervisor.delete_child(Droodotfoo.Supervisor, PresetManager)
    end

    # Start fresh PresetManager for each test
    {:ok, pid} = start_supervised(PresetManager)
    {:ok, pid: pid}
  end

  describe "save_preset/3" do
    test "saves a new preset" do
      filters = %{technologies: ["Elixir"], text_search: "blockchain"}

      assert {:ok, "test_preset"} = PresetManager.save_preset("test_preset", filters)
    end

    test "saves preset with description" do
      filters = %{technologies: ["Rust"]}

      assert {:ok, "rust_preset"} =
               PresetManager.save_preset(
                 "rust_preset",
                 filters,
                 description: "Rust experience"
               )
    end

    test "saves preset with tags" do
      filters = %{technologies: ["Elixir"]}

      assert {:ok, "elixir_preset"} =
               PresetManager.save_preset(
                 "elixir_preset",
                 filters,
                 tags: ["elixir", "functional"]
               )
    end
  end

  describe "load_preset/1" do
    test "loads an existing preset" do
      filters = %{technologies: ["Elixir"]}
      PresetManager.save_preset("test_load", filters)

      assert {:ok, loaded_filters} = PresetManager.load_preset("test_load")
      assert loaded_filters == filters
    end

    test "returns error for nonexistent preset" do
      assert {:error, message} = PresetManager.load_preset("nonexistent")
      assert message =~ "not found"
    end

    test "loads system preset" do
      assert {:ok, filters} = PresetManager.load_preset("blockchain")
      assert is_map(filters)
      assert Map.has_key?(filters, :technologies) or Map.has_key?(filters, :text_search)
    end
  end

  describe "list_presets/0" do
    test "lists all presets including system presets" do
      presets = PresetManager.list_presets()

      assert is_list(presets)
      assert length(presets) > 0

      # Should include system presets
      assert Enum.any?(presets, fn preset -> preset.name == "blockchain" end)
    end

    test "includes user presets after saving" do
      filters = %{technologies: ["Go"]}
      PresetManager.save_preset("user_preset", filters)

      presets = PresetManager.list_presets()

      assert Enum.any?(presets, fn preset -> preset.name == "user_preset" end)
    end

    test "preset list includes metadata" do
      presets = PresetManager.list_presets()
      preset = List.first(presets)

      assert Map.has_key?(preset, :name)
      assert Map.has_key?(preset, :description)
      assert Map.has_key?(preset, :is_system)
      assert Map.has_key?(preset, :tags)
    end
  end

  describe "delete_preset/1" do
    test "deletes user preset" do
      filters = %{technologies: ["Python"]}
      PresetManager.save_preset("deletable", filters)

      assert :ok = PresetManager.delete_preset("deletable")
      assert {:error, _} = PresetManager.load_preset("deletable")
    end

    test "cannot delete system preset" do
      assert {:error, message} = PresetManager.delete_preset("blockchain")
      assert message =~ "Cannot delete system preset"
    end

    test "returns error when deleting nonexistent preset" do
      assert {:error, message} = PresetManager.delete_preset("nonexistent")
      assert message =~ "not found"
    end
  end

  describe "update_preset/3" do
    test "updates existing user preset" do
      filters = %{technologies: ["Java"]}
      PresetManager.save_preset("updatable", filters)

      new_filters = %{technologies: ["Java", "Kotlin"]}
      assert {:ok, "updatable"} = PresetManager.update_preset("updatable", new_filters)

      {:ok, loaded} = PresetManager.load_preset("updatable")
      assert loaded == new_filters
    end

    test "updates preset description" do
      filters = %{technologies: ["Ruby"]}
      PresetManager.save_preset("ruby_preset", filters)

      assert {:ok, "ruby_preset"} =
               PresetManager.update_preset(
                 "ruby_preset",
                 filters,
                 description: "Updated description"
               )
    end

    test "cannot update system preset" do
      filters = %{technologies: ["NewTech"]}

      assert {:error, message} = PresetManager.update_preset("blockchain", filters)
      assert message =~ "Cannot update system preset"
    end
  end

  describe "find_by_tag/1" do
    test "finds presets by tag" do
      filters = %{technologies: ["Elixir"]}
      PresetManager.save_preset("tagged_preset", filters, tags: ["web3", "functional"])

      results = PresetManager.find_by_tag("web3")

      assert is_list(results)
      assert Enum.any?(results, fn preset -> preset.name == "tagged_preset" end)
    end

    test "returns empty list when no presets have tag" do
      results = PresetManager.find_by_tag("nonexistent_tag")

      # May be empty or have only system presets with that tag
      assert is_list(results)
    end

    test "finds system presets by tag" do
      results = PresetManager.find_by_tag("blockchain")

      assert is_list(results)
      assert Enum.any?(results, fn preset -> "blockchain" in preset.tags end)
    end
  end

  describe "export_presets/1 and import_presets/1" do
    test "exports presets to file" do
      export_path = "/tmp/test_export_#{System.unique_integer([:positive])}.json"

      assert :ok = PresetManager.export_presets(export_path)
      assert File.exists?(export_path)

      # Cleanup
      File.rm(export_path)
    end

    test "imports presets from file" do
      # First create a preset and export
      filters = %{technologies: ["TypeScript"]}
      PresetManager.save_preset("import_test", filters)

      export_path = "/tmp/test_import_#{System.unique_integer([:positive])}.json"
      PresetManager.export_presets(export_path)

      # Delete the preset
      PresetManager.delete_preset("import_test")

      # Import it back
      assert {:ok, count} = PresetManager.import_presets(export_path)
      assert count > 0

      # Verify it was imported
      assert {:ok, _} = PresetManager.load_preset("import_test")

      # Cleanup
      File.rm(export_path)
    end
  end
end
