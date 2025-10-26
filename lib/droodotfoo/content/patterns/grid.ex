defmodule Droodotfoo.Content.Patterns.Grid do
  @moduledoc """
  Cellular grid pattern generator.

  Generates a grid of cells with wave-based fill probability
  for rhythmic, mathematical visuals.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}

  @doc """
  Generates a grid pattern.

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
    config = PatternConfig.grid_config()

    # Generate random grid parameters
    {cell_size, rng} = RandomGenerator.uniform_range(rng, config.cell_size)
    {wave_freq, rng} = RandomGenerator.uniform_range(rng, config.wave_frequency)

    # Calculate grid dimensions
    cols = div(width, trunc(cell_size)) + 1
    rows = div(height, trunc(cell_size)) + 1

    # Generate all cells
    positions =
      for row <- 0..(rows - 1),
          col <- 0..(cols - 1) do
        {row, col, col * cell_size, row * cell_size}
      end

    Enum.map_reduce(positions, rng, fn {row, col, x, y}, acc_rng ->
      generate_single_cell(
        row,
        col,
        x,
        y,
        cell_size,
        wave_freq,
        config,
        palette,
        acc_rng,
        animate
      )
    end)
    |> then(fn {cells, final_rng} ->
      {Enum.reject(cells, &is_nil/1), final_rng}
    end)
  end

  # Private helper to generate a single grid cell
  defp generate_single_cell(row, col, x, y, cell_size, wave_freq, config, palette, rng, animate) do
    # Calculate fill probability based on wave pattern
    fill_chance = :math.sin((col + row) / wave_freq) * 0.5 + 0.5

    {should_fill, rng} = RandomGenerator.chance(rng, fill_chance)

    cell =
      if should_fill do
        {opacity, rng} = RandomGenerator.uniform_range(rng, config.opacity)

        # Pick color from palette based on position
        color_index = rem(row + col, length(palette.colors))
        color = Enum.at(palette.colors, color_index)

        cell_element =
          SVGBuilder.rect(x, y, cell_size, cell_size)
          |> SVGBuilder.with_attrs(%{
            fill: color,
            opacity: opacity
          })

        cell_element =
          if animate do
            SVGBuilder.with_class(cell_element, "grid-cell")
          else
            cell_element
          end

        {cell_element, rng}
      else
        {nil, rng}
      end

    cell
  end

  @doc """
  Convenience function to generate and render grid pattern to SVG string.

  Refined monochrome aesthetic with minimal grey tones.
  """
  @spec generate_svg(String.t(), number, number, boolean) :: String.t()
  def generate_svg(slug, width, height, animate \\ false) do
    rng = RandomGenerator.new(slug)
    {_palette_name, palette} = PatternConfig.choose_palette_for_style(slug, :grid)
    {elements, _rng} = generate(width, height, rng, palette, animate)

    animations =
      if animate do
        Droodotfoo.Content.PatternAnimations.get_animations(:grid)
      else
        ""
      end

    SVGBuilder.build_svg(elements,
      width: width,
      height: height,
      background: palette.bg,
      animations: animations
    )
  end
end
