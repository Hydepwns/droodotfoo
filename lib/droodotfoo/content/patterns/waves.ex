defmodule Droodotfoo.Content.Patterns.Waves do
  @moduledoc """
  Flowing sine waves pattern generator.

  Generates multiple layered sine waves with varying amplitude,
  frequency, and phase for organic, flowing visuals.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  @doc """
  Generates a waves pattern.

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
    config = PatternConfig.waves_config()

    # Generate random wave count
    {num_waves, rng} = RandomGenerator.uniform_range(rng, config.wave_count)

    # Generate all waves with threaded RNG state
    Enum.map_reduce(1..num_waves, rng, fn i, acc_rng ->
      generate_single_wave(i, width, height, config, palette, acc_rng, animate)
    end)
  end

  # Private helper to generate a single wave
  defp generate_single_wave(index, width, height, config, palette, rng, animate) do
    # Generate random wave parameters
    {amplitude, rng} = RandomGenerator.uniform_range(rng, config.amplitude)
    {frequency, rng} = RandomGenerator.uniform_range(rng, config.frequency)
    {phase, rng} = RandomGenerator.uniform_float(rng, 0, :math.pi() * 2)
    {y_offset, rng} = RandomGenerator.uniform_float(rng, 0, height)
    {opacity, rng} = RandomGenerator.uniform_range(rng, config.opacity)

    # Pick color from palette
    color = Enum.at(palette.colors, rem(index, length(palette.colors)))

    # Generate smooth path points for wave
    points =
      for x <- 0..width//config.point_spacing do
        y = y_offset + amplitude * :math.sin(frequency * x + phase)
        {x, y}
      end

    # Build path data string
    path_data =
      Enum.map_join(points, " L ", fn {x, y} -> "#{x},#{y}" end)
      |> then(&("M " <> &1))

    # Create SVG path element
    wave_element =
      SVGBuilder.path(path_data)
      |> SVGBuilder.with_attrs(%{
        stroke: color,
        "stroke-width": config.stroke_width,
        fill: "none",
        opacity: opacity
      })

    {Base.maybe_animate(wave_element, animate, "wave", index, 3), rng}
  end

  @doc """
  Convenience function to generate and render waves pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :waves, slug, width, height, animate, tags)
  end
end
