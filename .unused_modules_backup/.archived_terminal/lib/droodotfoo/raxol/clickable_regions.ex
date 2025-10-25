defmodule Droodotfoo.Raxol.ClickableRegions do
  @moduledoc """
  Manages clickable region metadata for the terminal UI.

  This module provides a data-driven system for defining and managing
  clickable regions in the terminal. Instead of hard-coding coordinates
  in event handlers, regions are defined semantically with bounds and
  action identifiers.

  ## Features

  - **Semantic identifiers**: Regions have meaningful IDs like `:nav_home`
  - **Bounds tracking**: Automatic coordinate range management
  - **Action routing**: Map regions to actions without coordinate logic
  - **Visual states**: Support for hover, active, disabled states
  - **Fast lookup**: Efficient coordinate-to-region mapping

  ## Example

      regions = ClickableRegions.new()
      regions = ClickableRegions.add_navigation_item(regions, :home, 15, 0, 29)

      case ClickableRegions.get_region_at(regions, 15, 5) do
        {:ok, region} -> handle_click(region.id)
        :error -> :ignore
      end

  """

  defstruct regions: %{},
            region_by_position: %{},
            navigation_items: []

  @type region_id :: atom()
  @type region :: %{
          id: region_id(),
          type: :navigation | :action | :content,
          bounds: bounds(),
          action: String.t() | nil,
          metadata: map()
        }
  @type bounds :: %{
          row_start: non_neg_integer(),
          row_end: non_neg_integer(),
          col_start: non_neg_integer(),
          col_end: non_neg_integer()
        }
  @type t :: %__MODULE__{
          regions: %{region_id() => region()},
          region_by_position: %{{row :: integer(), col :: integer()} => region_id()},
          navigation_items: [region_id()]
        }

  @doc """
  Creates a new empty clickable regions collection.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      regions: %{},
      region_by_position: %{},
      navigation_items: []
    }
  end

  @doc """
  Adds a navigation menu item as a clickable region.

  Navigation items are special clickable regions that correspond to
  menu items in the terminal UI. They are tracked in order for proper
  cursor navigation.

  ## Parameters

  - `regions` - The regions collection
  - `id` - Semantic identifier (e.g., `:home`, `:experience`)
  - `row` - Row number where the item appears
  - `col_start` - Starting column (default: 0)
  - `col_end` - Ending column (default: 29)

  ## Examples

      regions = ClickableRegions.new()
      regions = ClickableRegions.add_navigation_item(regions, :home, 15)
      regions = ClickableRegions.add_navigation_item(regions, :experience, 16)

  """
  @spec add_navigation_item(t(), region_id(), integer(), integer(), integer()) :: t()
  def add_navigation_item(regions, id, row, col_start \\ 0, col_end \\ 29) do
    region = %{
      id: id,
      type: :navigation,
      bounds: %{
        row_start: row,
        row_end: row,
        col_start: col_start,
        col_end: col_end
      },
      action: "select:#{id}",
      metadata: %{
        index: length(regions.navigation_items)
      }
    }

    add_region(regions, region)
    |> Map.update!(:navigation_items, &(&1 ++ [id]))
  end

  @doc """
  Adds a generic clickable region.

  ## Parameters

  - `regions` - The regions collection
  - `region` - Region map with id, type, bounds, action, metadata

  """
  @spec add_region(t(), region()) :: t()
  def add_region(regions, region) do
    # Add region to regions map
    updated_regions = Map.put(regions.regions, region.id, region)

    # Build position lookup map for all cells in this region
    updated_position_map =
      build_position_map(regions.region_by_position, region)

    %{
      regions
      | regions: updated_regions,
        region_by_position: updated_position_map
    }
  end

  @doc """
  Adds a rectangular clickable region (e.g., button, link).

  Convenience function for adding non-navigation clickable regions
  like buttons, links, or interactive content areas.

  ## Parameters

  - `regions` - The regions collection
  - `id` - Semantic identifier
  - `type` - Region type (`:action`, `:content`)
  - `row_start` - Starting row
  - `row_end` - Ending row
  - `col_start` - Starting column
  - `col_end` - Ending column
  - `action` - Action identifier or command string
  - `metadata` - Additional metadata (optional)

  """
  @spec add_rect_region(
          t(),
          region_id(),
          atom(),
          integer(),
          integer(),
          integer(),
          integer(),
          String.t(),
          map()
        ) :: t()
  def add_rect_region(
        regions,
        id,
        type,
        row_start,
        row_end,
        col_start,
        col_end,
        action,
        metadata \\ %{}
      ) do
    region = %{
      id: id,
      type: type,
      bounds: %{
        row_start: row_start,
        row_end: row_end,
        col_start: col_start,
        col_end: col_end
      },
      action: action,
      metadata: metadata
    }

    add_region(regions, region)
  end

  @doc """
  Looks up a region at the given row and column coordinates.

  Returns the region if found, otherwise returns :error.

  ## Examples

      case ClickableRegions.get_region_at(regions, 15, 5) do
        {:ok, region} -> IO.inspect(region.id)
        :error -> IO.puts("No region at that position")
      end

  """
  @spec get_region_at(t(), integer(), integer()) :: {:ok, region()} | :error
  def get_region_at(regions, row, col) do
    case Map.get(regions.region_by_position, {row, col}) do
      nil -> :error
      region_id -> {:ok, Map.get(regions.regions, region_id)}
    end
  end

  @doc """
  Gets a region by its ID.

  ## Examples

      case ClickableRegions.get_region(regions, :home) do
        {:ok, region} -> IO.inspect(region)
        :error -> IO.puts("Region not found")
      end

  """
  @spec get_region(t(), region_id()) :: {:ok, region()} | :error
  def get_region(regions, id) do
    case Map.get(regions.regions, id) do
      nil -> :error
      region -> {:ok, region}
    end
  end

  @doc """
  Gets all navigation items in order.

  Returns a list of region IDs in the order they were added.
  This is useful for cursor navigation and keyboard shortcuts.
  """
  @spec get_navigation_items(t()) :: [region_id()]
  def get_navigation_items(regions) do
    regions.navigation_items
  end

  @doc """
  Finds the navigation index for a given region ID.

  Returns `{:ok, index}` if the region is a navigation item,
  otherwise returns `:error`.
  """
  @spec get_navigation_index(t(), region_id()) :: {:ok, integer()} | :error
  def get_navigation_index(regions, id) do
    case Enum.find_index(regions.navigation_items, &(&1 == id)) do
      nil -> :error
      index -> {:ok, index}
    end
  end

  @doc """
  Exports regions to a JSON-serializable map for client-side use.

  The exported format includes all region data in a structure
  optimized for JavaScript consumption.

  ## Example Output

      %{
        regions: %{
          home: %{
            type: "navigation",
            bounds: %{row_start: 15, row_end: 15, col_start: 0, col_end: 29},
            action: "select:home",
            metadata: %{index: 0}
          }
        },
        navigation_items: [:home, :experience, :contact]
      }

  """
  @spec export_to_json(t()) :: map()
  def export_to_json(regions) do
    %{
      regions:
        regions.regions
        |> Enum.map(fn {id, region} ->
          {id,
           %{
             id: id,
             type: Atom.to_string(region.type),
             bounds: region.bounds,
             action: region.action,
             metadata: region.metadata
           }}
        end)
        |> Enum.into(%{}),
      navigation_items: regions.navigation_items
    }
  end

  @doc """
  Checks if a coordinate is within any clickable region.

  Returns true if the position is clickable, false otherwise.
  """
  @spec clickable?(t(), integer(), integer()) :: boolean()
  def clickable?(regions, row, col) do
    Map.has_key?(regions.region_by_position, {row, col})
  end

  ## Private functions

  # Build position lookup map for a region's bounds
  defp build_position_map(existing_map, region) do
    bounds = region.bounds

    # Generate all (row, col) positions within bounds
    for row <- bounds.row_start..bounds.row_end,
        col <- bounds.col_start..bounds.col_end,
        reduce: existing_map do
      acc ->
        Map.put(acc, {row, col}, region.id)
    end
  end
end
