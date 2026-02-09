defmodule Droodotfoo.Content.Patterns.Voronoi do
  @moduledoc """
  Voronoi cell tessellation pattern generator.

  Generates organic cell-like patterns using Voronoi diagram principles
  with random seed points.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  @doc """
  Generates a Voronoi tessellation pattern.

  ## Parameters

    * `width` - Canvas width in pixels
    * `height` - Canvas height in pixels
    * `rng` - Random generator state
    * `palette` - Color palette map with :colors list
    * `animate` - Whether to include animation classes

  ## Returns

  `{elements, new_rng}` where elements is a list of SVG element structs.
  """
  @spec generate(number, number, RandomGenerator.t(), map, boolean) ::
          {[SVGBuilder.element()], RandomGenerator.t()}
  def generate(width, height, rng, _palette, animate \\ false) do
    config = PatternConfig.voronoi_config()

    # Generate random parameters
    {cell_count, rng} = RandomGenerator.uniform_range(rng, config.cell_count)
    {stroke_width, rng} = RandomGenerator.uniform_range(rng, config.stroke_width)
    {opacity, rng} = RandomGenerator.uniform_range(rng, config.opacity)
    {show_points, rng} = RandomGenerator.chance(rng, config.show_points_chance)

    cell_count = trunc(cell_count)

    # Generate random seed points
    {points, rng} =
      Enum.map_reduce(1..cell_count, rng, fn _i, acc_rng ->
        {x, acc_rng} = RandomGenerator.uniform_float(acc_rng, 0, width)
        {y, acc_rng} = RandomGenerator.uniform_float(acc_rng, 0, height)
        {{x, y}, acc_rng}
      end)

    # Generate Voronoi edges using brute-force approach
    edges = generate_voronoi_edges(points, width, height)

    # Build edge elements
    edge_elements =
      edges
      |> Enum.with_index()
      |> Enum.map(fn {{{x1, y1}, {x2, y2}}, index} ->
        element =
          SVGBuilder.line(x1, y1, x2, y2, %{})
          |> SVGBuilder.with_attrs(%{
            stroke: "#ffffff",
            "stroke-width": stroke_width,
            opacity: opacity
          })

        Base.maybe_animate(element, animate, "voronoi-edge", index, 3)
      end)

    # Optionally show seed points
    point_elements =
      if show_points do
        points
        |> Enum.with_index()
        |> Enum.map(fn {{x, y}, index} ->
          element =
            SVGBuilder.circle(x, y, 3, %{})
            |> SVGBuilder.with_attrs(%{
              fill: "#ffffff",
              opacity: opacity * 0.7
            })

          Base.maybe_animate(element, animate, "voronoi-point", index, 2)
        end)
      else
        []
      end

    {edge_elements ++ point_elements, rng}
  end

  # Generate Voronoi edges using perpendicular bisectors
  defp generate_voronoi_edges(points, width, height) do
    # For each pair of adjacent cells, compute the perpendicular bisector
    points_with_index = Enum.with_index(points)

    for {{px1, py1}, i} <- points_with_index,
        {{px2, py2}, j} <- points_with_index,
        i < j,
        Base.distance(px1, py1, px2, py2) < max(width, height) / 3 do
      # Midpoint of the two seed points
      mid_x = (px1 + px2) / 2
      mid_y = (py1 + py2) / 2

      # Direction perpendicular to line between points
      dx = px2 - px1
      dy = py2 - py1
      len = :math.sqrt(dx * dx + dy * dy)

      if len > 0.001 do
        # Perpendicular direction
        perp_x = -dy / len
        perp_y = dx / len

        # Extend line in both directions
        extent = max(width, height) / 2
        x1 = mid_x + perp_x * extent
        y1 = mid_y + perp_y * extent
        x2 = mid_x - perp_x * extent
        y2 = mid_y - perp_y * extent

        # Clip to canvas bounds
        clip_line_to_bounds({x1, y1}, {x2, y2}, width, height)
      else
        nil
      end
    end
    |> Enum.reject(&is_nil/1)
  end

  defp clip_line_to_bounds({x1, y1}, {x2, y2}, width, height) do
    # Simple clipping - ensure both points are within bounds
    x1 = max(0, min(width, x1))
    y1 = max(0, min(height, y1))
    x2 = max(0, min(width, x2))
    y2 = max(0, min(height, y2))

    # Only return if line is meaningful
    if abs(x2 - x1) > 1 or abs(y2 - y1) > 1 do
      {{x1, y1}, {x2, y2}}
    else
      nil
    end
  end

  @doc """
  Convenience function to generate and render Voronoi pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :voronoi, slug, width, height, animate, tags)
  end
end
