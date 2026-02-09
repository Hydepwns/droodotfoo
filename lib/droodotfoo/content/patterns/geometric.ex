defmodule Droodotfoo.Content.Patterns.Geometric do
  @moduledoc """
  Geometric shapes pattern generator.

  Generates random circles, rectangles, and triangles with optional
  rotation for a classic geometric aesthetic.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  @doc """
  Generates a geometric pattern.

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
  def generate(width, height, rng, palette, animate \\ false) do
    config = PatternConfig.geometric_config()

    # Generate random shape count
    {num_shapes, rng} = RandomGenerator.uniform_range(rng, config.shape_count)

    # Generate all shapes
    Enum.map_reduce(1..num_shapes, rng, fn i, acc_rng ->
      generate_single_shape(i, width, height, config, palette, acc_rng, animate)
    end)
  end

  # Private helper to generate a single geometric shape
  defp generate_single_shape(index, width, height, config, palette, rng, animate) do
    {x, rng} = RandomGenerator.uniform_float(rng, 0, width)
    {y, rng} = RandomGenerator.uniform_float(rng, 0, height)
    {size, rng} = RandomGenerator.uniform_range(rng, config.size)
    {opacity, rng} = RandomGenerator.uniform_range(rng, config.opacity)

    # Choose shape type
    {shape_type, rng} = RandomGenerator.choice(rng, config.shapes)

    # Pick color from palette
    color = Enum.at(palette.colors, rem(index, length(palette.colors)))

    # Create shape element based on type
    {shape_element, rng} =
      case shape_type do
        :circle ->
          radius = size / 2

          element =
            SVGBuilder.circle(x, y, radius)
            |> SVGBuilder.with_attrs(%{
              fill: "none",
              stroke: color,
              "stroke-width": config.stroke_width,
              opacity: opacity
            })

          {element, rng}

        :rect ->
          {rotation, rng} = RandomGenerator.uniform_int(rng, 360)
          center_x = x + size / 2
          center_y = y + size / 2

          element =
            SVGBuilder.rect(x, y, size, size)
            |> SVGBuilder.with_attrs(%{
              fill: "none",
              stroke: color,
              "stroke-width": config.stroke_width,
              opacity: opacity,
              transform: "rotate(#{rotation} #{center_x} #{center_y})"
            })

          {element, rng}

        :triangle ->
          x1 = x
          y1 = y
          x2 = x + size
          y2 = y
          x3 = x + size / 2
          y3 = y + size

          element =
            SVGBuilder.polygon("#{x1},#{y1} #{x2},#{y2} #{x3},#{y3}")
            |> SVGBuilder.with_attrs(%{
              fill: "none",
              stroke: color,
              "stroke-width": config.stroke_width,
              opacity: opacity
            })

          {element, rng}
      end

    {Base.maybe_animate(shape_element, animate, "shape-rotate"), rng}
  end

  @doc """
  Convenience function to generate and render geometric pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :geometric, slug, width, height, animate, tags)
  end
end
