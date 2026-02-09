defmodule Droodotfoo.Content.Patterns.Noise do
  @moduledoc """
  TV static / noise effect pattern generator.

  Generates a grid of cells with random brightness,
  creating a digital noise aesthetic.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  @doc """
  Generates a noise pattern.

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
    config = PatternConfig.noise_config()

    # Generate random cell size
    {cell_size, rng} = RandomGenerator.uniform_range(rng, config.cell_size)

    # Calculate grid dimensions
    cols = div(width, trunc(cell_size)) + 1
    rows = div(height, trunc(cell_size)) + 1

    # Generate all cells
    positions =
      for row <- 0..(rows - 1),
          col <- 0..(cols - 1) do
        {col * cell_size, row * cell_size}
      end

    Enum.map_reduce(positions, rng, fn {x, y}, acc_rng ->
      generate_single_cell(x, y, cell_size, config, palette, acc_rng, animate)
    end)
    |> then(fn {cells, final_rng} ->
      {Enum.reject(cells, &is_nil/1), final_rng}
    end)
  end

  # Private helper to generate a single noise cell
  defp generate_single_cell(x, y, cell_size, config, palette, rng, animate) do
    {brightness, rng} = RandomGenerator.uniform(rng)

    cell =
      if brightness > config.brightness_threshold do
        opacity = (brightness - 0.5) * 2
        {color, rng} = RandomGenerator.choice(rng, palette.colors)

        cell_element =
          SVGBuilder.rect(x, y, cell_size, cell_size)
          |> SVGBuilder.with_attrs(%{
            fill: color,
            opacity: opacity
          })

        {Base.maybe_animate(cell_element, animate, "noise-cell"), rng}
      else
        {nil, rng}
      end

    cell
  end

  @doc """
  Convenience function to generate and render noise pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :noise, slug, width, height, animate, tags)
  end
end
