defmodule Droodotfoo.Content.Patterns.Lines do
  @moduledoc """
  Parallel and radial lines pattern generator.

  Generates either parallel vertical lines or radial lines
  emanating from center, chosen randomly.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  @doc """
  Generates a lines pattern.

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
    config = PatternConfig.lines_config()

    # Choose pattern type (parallel or radial)
    {pattern_choice, rng} = RandomGenerator.uniform_int(rng, 2)

    case rem(pattern_choice, 2) do
      0 -> generate_parallel_lines(width, height, rng, config.parallel, palette, animate)
      _ -> generate_radial_lines(width, height, rng, config.radial, palette, animate)
    end
  end

  # Generate parallel vertical lines
  defp generate_parallel_lines(width, height, rng, config, palette, animate) do
    num_lines = config.count
    spacing = width / num_lines

    Enum.map_reduce(0..(num_lines - 1), rng, fn i, acc_rng ->
      offset = i * spacing
      {thickness, acc_rng} = RandomGenerator.uniform_range(acc_rng, config.thickness)
      {opacity, acc_rng} = RandomGenerator.uniform_range(acc_rng, config.opacity)

      # Pick color from palette
      color = Enum.at(palette.colors, rem(i, length(palette.colors)))

      # Create vertical line
      line_element =
        SVGBuilder.line(offset, 0, offset, height)
        |> SVGBuilder.with_attrs(%{
          stroke: color,
          "stroke-width": thickness,
          opacity: opacity
        })

      {Base.maybe_animate(line_element, animate, "line-pulse"), acc_rng}
    end)
  end

  # Generate radial lines from center
  defp generate_radial_lines(width, height, rng, config, palette, animate) do
    center_x = width / 2
    center_y = height / 2
    num_lines = config.count
    length = max(width, height)

    Enum.map_reduce(0..(num_lines - 1), rng, fn i, acc_rng ->
      angle = i * (360 / num_lines)
      angle_rad = angle * :math.pi() / 180

      # Calculate end point
      x2 = center_x + length * :math.cos(angle_rad)
      y2 = center_y + length * :math.sin(angle_rad)

      {thickness, acc_rng} = RandomGenerator.uniform_range(acc_rng, config.thickness)
      {opacity, acc_rng} = RandomGenerator.uniform_range(acc_rng, config.opacity)

      # Pick color from palette
      color = Enum.at(palette.colors, rem(i, length(palette.colors)))

      # Create radial line
      line_element =
        SVGBuilder.line(center_x, center_y, x2, y2)
        |> SVGBuilder.with_attrs(%{
          stroke: color,
          "stroke-width": thickness,
          opacity: opacity
        })

      {Base.maybe_animate(line_element, animate, "line-pulse"), acc_rng}
    end)
  end

  @doc """
  Convenience function to generate and render lines pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :lines, slug, width, height, animate, tags)
  end
end
