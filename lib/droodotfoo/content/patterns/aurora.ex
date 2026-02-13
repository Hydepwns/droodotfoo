defmodule Droodotfoo.Content.Patterns.Aurora do
  @moduledoc """
  Aurora pattern generator.

  Creates northern lights-style flowing bands that emerge and
  shimmer across the canvas with organic wave motion.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  @doc """
  Generates an aurora pattern.

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
    config = PatternConfig.aurora_config()

    {band_count, rng} = RandomGenerator.uniform_range(rng, config.band_count)
    band_count = trunc(band_count)

    {elements, rng} =
      Enum.map_reduce(1..band_count, rng, fn i, acc_rng ->
        generate_band(i, width, height, config, palette, acc_rng, animate)
      end)

    {elements, rng}
  end

  defp generate_band(index, width, height, config, palette, rng, animate) do
    # Random band parameters
    {base_y, rng} = RandomGenerator.uniform_float(rng, height * 0.2, height * 0.8)
    {amplitude, rng} = RandomGenerator.uniform_range(rng, config.amplitude)
    {frequency, rng} = RandomGenerator.uniform_range(rng, config.frequency)
    {thickness, rng} = RandomGenerator.uniform_range(rng, config.thickness)
    {opacity, rng} = RandomGenerator.uniform_range(rng, config.opacity)
    {phase, rng} = RandomGenerator.uniform_float(rng, 0, :math.pi() * 2)

    color = Enum.at(palette.colors, rem(index, length(palette.colors)))

    # Generate wave path points
    points = generate_wave_points(width, base_y, amplitude, frequency, phase)

    # Create filled path with gradient-like effect using multiple strokes
    path_data = points_to_smooth_path(points)

    element =
      SVGBuilder.path(path_data)
      |> SVGBuilder.with_attrs(%{
        stroke: color,
        "stroke-width": thickness,
        fill: "none",
        opacity: opacity,
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
        filter: "url(#aurora-glow)"
      })

    element =
      if animate do
        SVGBuilder.with_class(element, "aurora-band-#{rem(index, 4)}")
        |> SVGBuilder.with_attrs(%{style: "--i: #{index}"})
      else
        element
      end

    {element, rng}
  end

  defp generate_wave_points(width, base_y, amplitude, frequency, phase) do
    step = 20

    0..trunc(width)
    |> Enum.take_every(step)
    |> Enum.map(fn x ->
      # Layered sine waves for organic look
      y =
        base_y +
          amplitude * :math.sin(x * frequency + phase) +
          amplitude * 0.5 * :math.sin(x * frequency * 2.3 + phase * 1.7) +
          amplitude * 0.25 * :math.cos(x * frequency * 0.7 + phase * 0.5)

      {x, y}
    end)
  end

  defp points_to_smooth_path(points) when length(points) < 2, do: ""

  defp points_to_smooth_path(points) do
    [{first_x, first_y} | _] = points
    start = "M #{format_num(first_x)},#{format_num(first_y)}"
    curves = points_to_curves(points)
    start <> " " <> curves
  end

  defp points_to_curves(points) when length(points) < 4 do
    points
    |> Enum.drop(1)
    |> Enum.map_join(" ", fn {x, y} -> "L #{format_num(x)},#{format_num(y)}" end)
  end

  defp points_to_curves(points) do
    first = hd(points)
    last = List.last(points)
    extended = [first | points] ++ [last]

    extended
    |> Enum.chunk_every(4, 1, :discard)
    |> Enum.map_join(" ", &catmull_to_bezier/1)
  end

  defp catmull_to_bezier([{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}]) do
    tension = 6.0

    cp1x = x1 + (x2 - x0) / tension
    cp1y = y1 + (y2 - y0) / tension
    cp2x = x2 - (x3 - x1) / tension
    cp2y = y2 - (y3 - y1) / tension

    "C #{format_num(cp1x)},#{format_num(cp1y)} #{format_num(cp2x)},#{format_num(cp2y)} #{format_num(x2)},#{format_num(y2)}"
  end

  defp format_num(n), do: :erlang.float_to_binary(n * 1.0, decimals: 2)

  @doc """
  Convenience function to generate and render aurora pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :aurora, slug, width, height, animate, tags)
  end
end
