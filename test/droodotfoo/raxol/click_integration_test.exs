defmodule Droodotfoo.Raxol.ClickIntegrationTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Raxol.{ClickableRegions, Renderer, State}
  alias Droodotfoo.TerminalBridge

  describe "click handling integration" do
    setup do
      # Create a realistic state with navigation
      state = State.initial(110, 45)

      # Render the buffer and get clickable regions
      {buffer, clickable_regions, _content_height} = Renderer.render(state)

      {:ok, buffer: buffer, clickable_regions: clickable_regions, state: state}
    end

    test "renderer creates clickable regions for navigation items", %{clickable_regions: regions} do
      # Verify navigation items are created
      nav_items = ClickableRegions.get_navigation_items(regions)
      assert length(nav_items) > 0
      assert :home in nav_items
      assert :experience in nav_items
      assert :contact in nav_items
    end

    test "clicking home navigation item returns correct region", %{clickable_regions: regions} do
      # Home should be at row 15, columns 0-29
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 15, 10)
      assert region.id == :home
      assert region.type == :navigation
      assert region.metadata.index == 0
    end

    test "clicking experience navigation item returns correct region", %{
      clickable_regions: regions
    } do
      # Experience should be at row 16, columns 0-29
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 16, 15)
      assert region.id == :experience
      assert region.type == :navigation
      assert region.metadata.index == 1
    end

    test "clicking contact navigation item returns correct region", %{clickable_regions: regions} do
      # Contact should be at row 17, columns 0-29
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 17, 20)
      assert region.id == :contact
      assert region.type == :navigation
      assert region.metadata.index == 2
    end

    test "clicking games navigation item returns correct region", %{clickable_regions: regions} do
      # Games should be at row 19 (after section header), columns 0-29
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 19, 10)
      assert region.id == :games
      assert region.type == :navigation
      assert region.metadata.index == 3
    end

    test "clicking stl_viewer navigation item returns correct region", %{
      clickable_regions: regions
    } do
      # STL Viewer should be at row 20, columns 0-29
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 20, 15)
      assert region.id == :stl_viewer
      assert region.type == :navigation
      assert region.metadata.index == 4
    end

    test "clicking web3 navigation item returns correct region", %{clickable_regions: regions} do
      # Web3 should be at row 21, columns 0-29
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 21, 25)
      assert region.id == :web3
      assert region.type == :navigation
      assert region.metadata.index == 5
    end

    test "clicking section header row returns error", %{clickable_regions: regions} do
      # Row 18 is the section header - should not be clickable
      assert :error == ClickableRegions.get_region_at(regions, 18, 10)
    end

    test "clicking outside navigation column bounds returns error", %{clickable_regions: regions} do
      # Column 30 is outside navigation bounds (0-29)
      assert :error == ClickableRegions.get_region_at(regions, 15, 30)
      assert :error == ClickableRegions.get_region_at(regions, 16, 35)
    end

    test "clicking outside navigation row bounds returns error", %{clickable_regions: regions} do
      # Row 14 is above navigation
      assert :error == ClickableRegions.get_region_at(regions, 14, 10)
      # Row 22 is below navigation
      assert :error == ClickableRegions.get_region_at(regions, 22, 10)
    end

    test "clicking at navigation boundaries works correctly", %{clickable_regions: regions} do
      # First column (0)
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 15, 0)
      assert region.id == :home

      # Last column (29)
      assert {:ok, region} = ClickableRegions.get_region_at(regions, 15, 29)
      assert region.id == :home

      # Just outside bounds
      assert :error == ClickableRegions.get_region_at(regions, 15, 30)
    end

    test "all navigation items have sequential indices", %{clickable_regions: regions} do
      nav_items = ClickableRegions.get_navigation_items(regions)

      nav_items
      |> Enum.with_index()
      |> Enum.each(fn {region_id, expected_index} ->
        {:ok, region} = ClickableRegions.get_region(regions, region_id)
        assert region.metadata.index == expected_index
      end)
    end

    test "terminal bridge adds data attributes to clickable cells", %{
      buffer: buffer,
      clickable_regions: clickable_regions
    } do
      # Render HTML with clickable regions
      html = TerminalBridge.terminal_to_html(buffer, clickable_regions)

      # HTML should contain data attributes for clickable cells
      assert html =~ ~s(data-clickable="true")
      assert html =~ ~s(data-region-id="home")
      assert html =~ ~s(data-region-id="experience")
      assert html =~ ~s(data-region-id="contact")

      # Should have row and column attributes
      assert html =~ ~s(data-row=)
      assert html =~ ~s(data-col=)
    end

    test "terminal bridge HTML structure is valid", %{
      buffer: buffer,
      clickable_regions: clickable_regions
    } do
      html = TerminalBridge.terminal_to_html(buffer, clickable_regions)

      # Basic HTML structure
      assert html =~ ~s(<div class="terminal-container")
      assert html =~ ~s(<div class="terminal-line">)
      assert html =~ ~s(<span class="cell)

      # Should properly close all tags
      assert html =~ ~s(</div>)
      assert html =~ ~s(</span>)
    end

    test "export to JSON creates valid structure", %{clickable_regions: regions} do
      json = ClickableRegions.export_to_json(regions)

      # Should have correct structure
      assert is_map(json.regions)
      assert is_list(json.navigation_items)

      # Each region should have required fields
      Enum.each(json.regions, fn {_id, region} ->
        assert Map.has_key?(region, :id)
        assert Map.has_key?(region, :type)
        assert Map.has_key?(region, :bounds)
        assert Map.has_key?(region, :action)
        assert Map.has_key?(region, :metadata)

        # Bounds should have all coordinates
        assert Map.has_key?(region.bounds, :row_start)
        assert Map.has_key?(region.bounds, :row_end)
        assert Map.has_key?(region.bounds, :col_start)
        assert Map.has_key?(region.bounds, :col_end)
      end)
    end

    test "clicking each cell in a navigation row returns same region", %{
      clickable_regions: regions
    } do
      # All cells in row 15, columns 0-29 should return :home
      for col <- 0..29 do
        assert {:ok, region} = ClickableRegions.get_region_at(regions, 15, col)
        assert region.id == :home
      end
    end

    test "region actions are correctly formatted", %{clickable_regions: regions} do
      nav_items = [
        {:home, "select:home"},
        {:experience, "select:experience"},
        {:contact, "select:contact"},
        {:games, "select:games"},
        {:stl_viewer, "select:stl_viewer"},
        {:web3, "select:web3"}
      ]

      Enum.each(nav_items, fn {region_id, expected_action} ->
        {:ok, region} = ClickableRegions.get_region(regions, region_id)
        assert region.action == expected_action
      end)
    end

    test "coordinate validation edge cases", %{clickable_regions: regions} do
      # Negative coordinates
      assert :error == ClickableRegions.get_region_at(regions, -1, 10)
      assert :error == ClickableRegions.get_region_at(regions, 15, -1)

      # Very large coordinates
      assert :error == ClickableRegions.get_region_at(regions, 1000, 10)
      assert :error == ClickableRegions.get_region_at(regions, 15, 1000)

      # Zero coordinates (should work if in a region)
      # Note: row 0 and col 0 are typically not in navigation regions
      result = ClickableRegions.get_region_at(regions, 0, 0)
      # Should either be error or a valid region, but not crash
      assert result == :error or match?({:ok, _}, result)
    end
  end

  describe "multiple render cycles preserve clickable regions" do
    test "regions are consistent across renders" do
      state1 = State.initial(110, 45)
      {_buffer1, regions1, _content_height1} = Renderer.render(state1)

      state2 = State.initial(110, 45)
      {_buffer2, regions2, _content_height2} = Renderer.render(state2)

      # Should produce identical region structures
      nav_items1 = ClickableRegions.get_navigation_items(regions1)
      nav_items2 = ClickableRegions.get_navigation_items(regions2)

      assert nav_items1 == nav_items2

      # Each corresponding region should have same properties
      Enum.each(nav_items1, fn region_id ->
        {:ok, region1} = ClickableRegions.get_region(regions1, region_id)
        {:ok, region2} = ClickableRegions.get_region(regions2, region_id)

        assert region1.id == region2.id
        assert region1.type == region2.type
        assert region1.bounds == region2.bounds
        assert region1.action == region2.action
        assert region1.metadata == region2.metadata
      end)
    end

    test "changing state section does not affect region definitions" do
      state_home = %{State.initial(110, 45) | current_section: :home}
      state_experience = %{State.initial(110, 45) | current_section: :experience}

      {_buffer1, regions1, _content_height1} = Renderer.render(state_home)
      {_buffer2, regions2, _content_height2} = Renderer.render(state_experience)

      # Navigation regions should be identical regardless of current section
      nav_items1 = ClickableRegions.get_navigation_items(regions1)
      nav_items2 = ClickableRegions.get_navigation_items(regions2)

      assert nav_items1 == nav_items2
    end
  end

  describe "performance characteristics" do
    test "region lookup is fast even with many regions" do
      # Create state and render
      state = State.initial(110, 45)
      {_buffer, regions, _content_height} = Renderer.render(state)

      # Measure lookup time for 1000 lookups
      start_time = System.monotonic_time(:microsecond)

      for _ <- 1..1000 do
        ClickableRegions.get_region_at(regions, 15, 10)
      end

      end_time = System.monotonic_time(:microsecond)
      elapsed = end_time - start_time

      # Should complete 1000 lookups in under 10ms (10,000 microseconds)
      # This is a very conservative threshold - actual performance should be much better
      assert elapsed < 10_000,
             "1000 region lookups took #{elapsed}μs, expected < 10,000μs"
    end

    test "position map scales linearly with region size" do
      # Small region (1 cell)
      small_regions =
        ClickableRegions.new()
        |> ClickableRegions.add_rect_region(:small, :action, 0, 0, 0, 0, "action")

      assert map_size(small_regions.region_by_position) == 1

      # Medium region (10x10 = 100 cells)
      medium_regions =
        ClickableRegions.new()
        |> ClickableRegions.add_rect_region(:medium, :action, 0, 9, 0, 9, "action")

      assert map_size(medium_regions.region_by_position) == 100

      # Large region (30x6 = 180 cells, like navigation)
      large_regions =
        ClickableRegions.new()
        |> ClickableRegions.add_rect_region(:large, :action, 0, 5, 0, 29, "action")

      assert map_size(large_regions.region_by_position) == 180
    end
  end
end
