defmodule Droodotfoo.Content.Patterns.Dots do
  @moduledoc """
  Halftone dot matrix pattern generator.

  Generates a gradient-based halftone effect with dots radiating
  from a random center point.

  This is a refactored proof-of-concept showing the new architecture:
  - Uses PatternConfig for configuration
  - Uses RandomGenerator for deterministic randomness
  - Uses SVGBuilder for structured element generation
  - Returns structured data instead of strings
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}

  @doc """
  Generates a dots pattern.

  ## Parameters

    * `width` - Canvas width in pixels
    * `height` - Canvas height in pixels
    * `rng` - Random generator state
    * `palette` - Color palette map with :colors list
    * `animate` - Whether to include animation classes

  ## Returns

  `{elements, new_rng}` where elements is a list of SVG element structs.

  ## Examples

      iex> rng = RandomGenerator.new("test-slug")
      iex> palette = %{colors: ["#ffffff"]}
      iex> {elements, _rng} = Dots.generate(1200, 630, rng, palette, false)
      iex> is_list(elements)
      true
  """
  @spec generate(number, number, RandomGenerator.t(), map, boolean) ::
          {[SVGBuilder.element()], RandomGenerator.t()}
  def generate(width, height, rng, _palette, animate \\ false) do
    config = PatternConfig.dots_config()

    # Generate random parameters using config
    {dot_spacing, rng} = RandomGenerator.uniform_range(rng, config.spacing)
    {center_x_factor, rng} = RandomGenerator.uniform_range(rng, config.center_offset)
    {center_y_factor, rng} = RandomGenerator.uniform_range(rng, config.center_offset)

    # Calculate grid dimensions
    cols = div(width, trunc(dot_spacing)) + 1
    rows = div(height, trunc(dot_spacing)) + 1

    # Random center point for gradient
    center_x = width * center_x_factor
    center_y = height * center_y_factor
    max_distance = :math.sqrt(:math.pow(width / 2, 2) + :math.pow(height / 2, 2))

    # Generate dots for each grid position
    {dots, rng} =
      generate_dots_grid(
        rows,
        cols,
        dot_spacing,
        center_x,
        center_y,
        max_distance,
        config,
        rng,
        animate
      )

    {dots, rng}
  end

  # Private helper to generate all dots in the grid
  defp generate_dots_grid(
         rows,
         cols,
         spacing,
         center_x,
         center_y,
         max_distance,
         config,
         rng,
         animate
       ) do
    positions =
      for row <- 0..(rows - 1),
          col <- 0..(cols - 1) do
        {col * spacing, row * spacing}
      end

    # Generate each dot with updated RNG state
    Enum.map_reduce(positions, rng, fn {x, y}, acc_rng ->
      generate_single_dot(
        x,
        y,
        center_x,
        center_y,
        max_distance,
        spacing,
        config,
        acc_rng,
        animate
      )
    end)
    |> then(fn {dots, final_rng} ->
      # Filter out nil values (dots that were too small)
      {Enum.reject(dots, &is_nil/1), final_rng}
    end)
  end

  # Private helper to generate a single dot
  defp generate_single_dot(x, y, center_x, center_y, max_distance, spacing, config, rng, animate) do
    # Calculate distance from center for gradient effect
    distance = :math.sqrt(:math.pow(x - center_x, 2) + :math.pow(y - center_y, 2))
    size_factor = 1 - distance / max_distance

    # Add randomness to size
    {random_factor, rng} = RandomGenerator.uniform_range(rng, config.size_randomness)
    size_factor = size_factor * random_factor

    # Calculate final radius
    radius = max(1, size_factor * (spacing / 1.5))

    # Only create dot if radius is meaningful
    dot =
      if radius > 1 do
        dot_element =
          SVGBuilder.circle(x, y, radius, %{})
          |> SVGBuilder.with_attrs(%{
            fill: "#ffffff",
            opacity: config.opacity
          })

        # Add animation class if requested
        if animate do
          SVGBuilder.with_class(dot_element, "dot-pulse")
        else
          dot_element
        end
      else
        nil
      end

    {dot, rng}
  end

  @doc """
  Convenience function to generate and render dots pattern to SVG string.

  Refined monochrome aesthetic with minimal grey tones.

  ## Examples

      iex> svg = Dots.generate_svg("test-slug", 1200, 630, true)
      iex> String.contains?(svg, "<circle")
      true
  """
  @spec generate_svg(String.t(), number, number, boolean) :: String.t()
  def generate_svg(slug, width, height, animate \\ false) do
    rng = RandomGenerator.new(slug)
    {_palette_name, palette} = PatternConfig.choose_palette_for_style(slug, :dots)
    {elements, _rng} = generate(width, height, rng, palette, animate)

    animations =
      if animate do
        Droodotfoo.Content.PatternAnimations.get_animations(:dots)
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
