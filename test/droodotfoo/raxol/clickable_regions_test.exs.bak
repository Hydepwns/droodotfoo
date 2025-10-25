defmodule Droodotfoo.Raxol.ClickableRegionsTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Raxol.ClickableRegions

  describe "new/0" do
    test "creates an empty clickable regions collection" do
      regions = ClickableRegions.new()

      assert regions.regions == %{}
      assert regions.region_by_position == %{}
      assert regions.navigation_items == []
    end
  end

  describe "add_navigation_item/5" do
    test "adds a navigation item with default column bounds" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_navigation_item(:home, 15)

      assert map_size(regions.regions) == 1
      assert regions.navigation_items == [:home]

      region = regions.regions[:home]
      assert region.id == :home
      assert region.type == :navigation
      assert region.bounds.row_start == 15
      assert region.bounds.row_end == 15
      assert region.bounds.col_start == 0
      assert region.bounds.col_end == 29
      assert region.action == "select:home"
      assert region.metadata.index == 0
    end

    test "adds navigation item with custom column bounds" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_navigation_item(:experience, 16, 5, 35)

      region = regions.regions[:experience]
      assert region.bounds.col_start == 5
      assert region.bounds.col_end == 35
    end

    test "tracks navigation items in order" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_navigation_item(:home, 15)
        |> ClickableRegions.add_navigation_item(:experience, 16)
        |> ClickableRegions.add_navigation_item(:contact, 17)

      assert regions.navigation_items == [:home, :experience, :contact]

      # Check indices are sequential
      assert regions.regions[:home].metadata.index == 0
      assert regions.regions[:experience].metadata.index == 1
      assert regions.regions[:contact].metadata.index == 2
    end

    test "populates position lookup map" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_navigation_item(:home, 15, 0, 5)

      # Should have positions for all cells in bounds
      # Row 15, columns 0-5 (6 cells total)
      assert map_size(regions.region_by_position) == 6

      # Check specific positions
      assert regions.region_by_position[{15, 0}] == :home
      assert regions.region_by_position[{15, 3}] == :home
      assert regions.region_by_position[{15, 5}] == :home

      # Outside bounds should not exist
      assert regions.region_by_position[{15, 6}] == nil
      assert regions.region_by_position[{14, 0}] == nil
    end
  end

  describe "add_rect_region/8" do
    test "adds a rectangular clickable region" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_rect_region(
          :button1,
          :action,
          10,
          12,
          5,
          15,
          "click_button",
          %{label: "Submit"}
        )

      assert map_size(regions.regions) == 1

      region = regions.regions[:button1]
      assert region.id == :button1
      assert region.type == :action
      assert region.bounds.row_start == 10
      assert region.bounds.row_end == 12
      assert region.bounds.col_start == 5
      assert region.bounds.col_end == 15
      assert region.action == "click_button"
      assert region.metadata.label == "Submit"
    end

    test "adds region with default metadata" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_rect_region(:button2, :content, 5, 6, 0, 10, "action")

      region = regions.regions[:button2]
      assert region.metadata == %{}
    end

    test "populates position map for multi-row regions" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_rect_region(:box, :content, 10, 12, 5, 7, "click")

      # 3 rows (10, 11, 12) * 3 cols (5, 6, 7) = 9 cells
      assert map_size(regions.region_by_position) == 9

      # Check corners and middle
      assert regions.region_by_position[{10, 5}] == :box
      assert regions.region_by_position[{10, 7}] == :box
      assert regions.region_by_position[{12, 5}] == :box
      assert regions.region_by_position[{12, 7}] == :box
      assert regions.region_by_position[{11, 6}] == :box
    end
  end

  describe "get_region_at/3" do
    setup do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_navigation_item(:home, 15, 0, 29)
        |> ClickableRegions.add_navigation_item(:experience, 16, 0, 29)
        |> ClickableRegions.add_rect_region(:button, :action, 20, 22, 10, 20, "action")

      {:ok, regions: regions}
    end

    test "returns region when position is within bounds", %{regions: regions} do
      # Home region
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 15, 10)
      assert region.id == :home

      # Experience region
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 16, 5)
      assert region.id == :experience

      # Button region
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 21, 15)
      assert region.id == :button
    end

    test "returns error when position is outside all regions", %{regions: regions} do
      assert :error == ClickableRegions.get_region_at(regions, 0, 0)
      assert :error == ClickableRegions.get_region_at(regions, 100, 100)
      assert :error == ClickableRegions.get_region_at(regions, 15, 30)
    end

    test "handles edge cases at region boundaries", %{regions: regions} do
      # First cell of home region
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 15, 0)
      assert region.id == :home

      # Last cell of home region
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 15, 29)
      assert region.id == :home

      # Just outside home region
      assert :error == ClickableRegions.get_region_at(regions, 14, 15)
      assert :error == ClickableRegions.get_region_at(regions, 15, 30)
    end
  end

  describe "get_region/2" do
    setup do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_navigation_item(:home, 15)
        |> ClickableRegions.add_navigation_item(:contact, 17)

      {:ok, regions: regions}
    end

    test "returns region by ID when it exists", %{regions: regions} do
      assert {:ok, region} = ClickableRegions.get_region(regions, :home)
      assert region.id == :home
      assert region.type == :navigation

      assert {:ok, region} = ClickableRegions.get_region(regions, :contact)
      assert region.id == :contact
    end

    test "returns error when region ID does not exist", %{regions: regions} do
      assert :error == ClickableRegions.get_region(regions, :nonexistent)
      assert :error == ClickableRegions.get_region(regions, :invalid)
    end
  end

  describe "get_navigation_items/1" do
    test "returns empty list for new regions" do
      regions = ClickableRegions.new()
      assert ClickableRegions.get_navigation_items(regions) == []
    end

    test "returns navigation items in order they were added" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_navigation_item(:home, 15)
        |> ClickableRegions.add_navigation_item(:experience, 16)
        |> ClickableRegions.add_navigation_item(:contact, 17)
        |> ClickableRegions.add_rect_region(:button, :action, 20, 21, 10, 20, "action")

      items = ClickableRegions.get_navigation_items(regions)
      assert items == [:home, :experience, :contact]
      # Button should not be in navigation items
      refute :button in items
    end
  end

  describe "get_navigation_index/2" do
    setup do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_navigation_item(:home, 15)
        |> ClickableRegions.add_navigation_item(:experience, 16)
        |> ClickableRegions.add_navigation_item(:contact, 17)

      {:ok, regions: regions}
    end

    test "returns correct index for navigation items", %{regions: regions} do
      assert {:ok, 0} = ClickableRegions.get_navigation_index(regions, :home)
      assert {:ok, 1} = ClickableRegions.get_navigation_index(regions, :experience)
      assert {:ok, 2} = ClickableRegions.get_navigation_index(regions, :contact)
    end

    test "returns error for non-navigation items", %{regions: regions} do
      assert :error == ClickableRegions.get_navigation_index(regions, :nonexistent)
    end
  end

  describe "export_to_json/1" do
    test "exports empty regions to JSON format" do
      regions = ClickableRegions.new()
      json = ClickableRegions.export_to_json(regions)

      assert json.regions == %{}
      assert json.navigation_items == []
    end

    test "exports regions with all metadata" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_navigation_item(:home, 15, 0, 29)
        |> ClickableRegions.add_rect_region(
          :button,
          :action,
          20,
          22,
          10,
          20,
          "click_action",
          %{label: "Click Me"}
        )

      json = ClickableRegions.export_to_json(regions)

      # Check structure
      assert is_map(json.regions)
      assert is_list(json.navigation_items)

      # Check home region
      home = json.regions[:home]
      assert home.id == :home
      assert home.type == "navigation"
      assert home.bounds.row_start == 15
      assert home.bounds.row_end == 15
      assert home.bounds.col_start == 0
      assert home.bounds.col_end == 29
      assert home.action == "select:home"
      assert home.metadata.index == 0

      # Check button region
      button = json.regions[:button]
      assert button.id == :button
      assert button.type == "action"
      assert button.action == "click_action"
      assert button.metadata.label == "Click Me"

      # Check navigation items list
      assert json.navigation_items == [:home]
    end

    test "converts all types to strings for JSON compatibility" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_navigation_item(:experience, 16)

      json = ClickableRegions.export_to_json(regions)
      region = json.regions[:experience]

      # Type should be string, not atom
      assert is_binary(region.type)
      assert region.type == "navigation"
    end
  end

  describe "clickable?/3" do
    setup do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_navigation_item(:home, 15, 0, 10)

      {:ok, regions: regions}
    end

    test "returns true for positions within clickable regions", %{regions: regions} do
      assert ClickableRegions.clickable?(regions, 15, 0)
      assert ClickableRegions.clickable?(regions, 15, 5)
      assert ClickableRegions.clickable?(regions, 15, 10)
    end

    test "returns false for positions outside clickable regions", %{regions: regions} do
      refute ClickableRegions.clickable?(regions, 14, 5)
      refute ClickableRegions.clickable?(regions, 15, 11)
      refute ClickableRegions.clickable?(regions, 16, 5)
      refute ClickableRegions.clickable?(regions, 0, 0)
    end
  end

  describe "overlapping regions" do
    test "handles overlapping regions (last wins in position map)" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_rect_region(:region1, :content, 10, 12, 5, 15, "action1")
        |> ClickableRegions.add_rect_region(:region2, :content, 11, 13, 10, 20, "action2")

      # Position (11, 10) is in both regions - last one added should win
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 11, 10)
      assert region.id == :region2

      # Position (10, 5) is only in region1
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 10, 5)
      assert region.id == :region1

      # Position (13, 15) is only in region2
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 13, 15)
      assert region.id == :region2
    end
  end

  describe "integration scenario - full navigation menu" do
    test "simulates complete navigation menu with all items" do
      # Build a navigation menu matching the actual app
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_navigation_item(:home, 15, 0, 29)
        |> ClickableRegions.add_navigation_item(:experience, 16, 0, 29)
        |> ClickableRegions.add_navigation_item(:contact, 17, 0, 29)
        # Row 18 is section header - skip
        |> ClickableRegions.add_navigation_item(:games, 19, 0, 29)
        |> ClickableRegions.add_navigation_item(:stl_viewer, 20, 0, 29)
        |> ClickableRegions.add_navigation_item(:web3, 21, 0, 29)

      # Verify all navigation items are tracked
      nav_items = ClickableRegions.get_navigation_items(regions)
      assert length(nav_items) == 6
      assert nav_items == [:home, :experience, :contact, :games, :stl_viewer, :web3]

      # Verify clicking on each menu item works
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 15, 10)
      assert region.id == :home
      assert region.metadata.index == 0

      assert {:ok, region} = ClickableRegions.get_region_at(regions, 17, 15)
      assert region.id == :contact
      assert region.metadata.index == 2

      assert {:ok, region} = ClickableRegions.get_region_at(regions, 21, 5)
      assert region.id == :web3
      assert region.metadata.index == 5

      # Verify section header row (18) is not clickable
      assert :error == ClickableRegions.get_region_at(regions, 18, 10)

      # Verify positions outside navigation bounds are not clickable
      assert :error == ClickableRegions.get_region_at(regions, 15, 30)
      assert :error == ClickableRegions.get_region_at(regions, 14, 15)

      # Export and verify JSON structure
      json = ClickableRegions.export_to_json(regions)
      assert map_size(json.regions) == 6
      assert length(json.navigation_items) == 6
    end
  end

  describe "edge cases and error handling" do
    test "handles single-cell regions" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_rect_region(:pixel, :action, 5, 5, 10, 10, "click")

      assert map_size(regions.region_by_position) == 1
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 5, 10)
      assert region.id == :pixel
    end

    test "handles large regions efficiently" do
      # Create a 100x100 region
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_rect_region(:large, :content, 0, 99, 0, 99, "action")

      # Should have 10,000 position entries
      assert map_size(regions.region_by_position) == 10000

      # Verify lookups still work
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 50, 50)
      assert region.id == :large
    end

    test "handles regions at terminal boundaries (row 0, col 0)" do
      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_rect_region(:corner, :action, 0, 0, 0, 0, "click")

      assert {:ok, region} = ClickableRegions.get_region_at(regions, 0, 0)
      assert region.id == :corner
    end

    test "preserves region metadata through operations" do
      custom_metadata = %{
        color: "blue",
        priority: 10,
        enabled: true,
        data: %{nested: "value"}
      }

      regions =
        ClickableRegions.new()
        |> ClickableRegions.add_rect_region(
          :custom,
          :action,
          10,
          11,
          5,
          10,
          "action",
          custom_metadata
        )

      region = regions.regions[:custom]
      assert region.metadata == custom_metadata
      assert region.metadata.data.nested == "value"

      # Verify it survives JSON export
      json = ClickableRegions.export_to_json(regions)
      exported_region = json.regions[:custom]
      assert exported_region.metadata.color == "blue"
      assert exported_region.metadata.priority == 10
    end
  end
end
