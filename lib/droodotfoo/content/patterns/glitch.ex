defmodule Droodotfoo.Content.Patterns.Glitch do
  @moduledoc """
  Glitch art / corrupted data pattern generator.

  Generates horizontal bars with random offsets and vertical scanlines
  for a digital corruption aesthetic.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  @doc """
  Generates a glitch pattern.

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
    config = PatternConfig.glitch_config()

    # Generate random bar count
    {num_bars, rng} = RandomGenerator.uniform_range(rng, config.bar_count)

    # Generate glitch bars
    {bars, rng} =
      Enum.map_reduce(1..num_bars, rng, fn i, acc_rng ->
        generate_glitch_bar(i, width, height, config, palette, acc_rng, animate)
      end)

    # Generate scanlines
    {scanlines, rng} =
      Enum.map_reduce(0..config.scanline_count, rng, fn i, acc_rng ->
        generate_scanline(i, width, height, config, palette, acc_rng, animate)
      end)

    # Combine bars and scanlines
    {bars ++ scanlines, rng}
  end

  # Private helper to generate a single glitch bar
  defp generate_glitch_bar(index, width, height, config, palette, rng, animate) do
    {x, rng} = RandomGenerator.uniform_float(rng, 0, width)
    {y, rng} = RandomGenerator.uniform_float(rng, 0, height)
    {bar_width, rng} = RandomGenerator.uniform_range(rng, config.bar_width)
    {bar_height, rng} = RandomGenerator.uniform_range(rng, config.bar_height)
    {opacity, rng} = RandomGenerator.uniform_range(rng, config.opacity)

    # Sometimes add offset for glitch effect
    {should_offset, rng} = RandomGenerator.chance(rng, config.offset_chance)

    {offset_x, rng} =
      if should_offset do
        RandomGenerator.uniform_range(rng, config.offset_range)
      else
        {0, rng}
      end

    # Pick color from palette
    color = Enum.at(palette.colors, rem(index, length(palette.colors)))

    # Create glitch bar element
    bar_element =
      SVGBuilder.rect(x + offset_x, y, bar_width, bar_height)
      |> SVGBuilder.with_attrs(%{
        fill: color,
        opacity: opacity
      })

    {Base.maybe_animate(bar_element, animate, "glitch-bar"), rng}
  end

  # Private helper to generate a single scanline
  defp generate_scanline(index, width, height, config, palette, rng, animate) do
    x = index * (width / config.scanline_count)
    {opacity, rng} = RandomGenerator.uniform_float(rng, 0.05, 0.15)

    # Pick color from palette
    color = Enum.at(palette.colors, rem(index, length(palette.colors)))

    # Create scanline element
    line_element =
      SVGBuilder.line(x, 0, x, height)
      |> SVGBuilder.with_attrs(%{
        stroke: color,
        "stroke-width": 1,
        opacity: opacity
      })

    {Base.maybe_animate(line_element, animate, "scanline"), rng}
  end

  @doc """
  Convenience function to generate and render glitch pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :glitch, slug, width, height, animate, tags)
  end
end
