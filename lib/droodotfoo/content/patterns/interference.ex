defmodule Droodotfoo.Content.Patterns.Interference do
  @moduledoc """
  Moire/wave interference pattern generator.

  Creates visually striking patterns from overlapping waves or concentric
  circles. The interference between patterns creates emergent structures.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  @doc """
  Generates an interference pattern.

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
    config = PatternConfig.interference_config()

    # Choose interference type
    {type_idx, rng} = RandomGenerator.uniform_int(rng, 3)

    case type_idx do
      1 -> generate_concentric(width, height, rng, palette, config, animate)
      2 -> generate_wave(width, height, rng, palette, config, animate)
      3 -> generate_grid(width, height, rng, palette, config, animate)
    end
  end

  # Concentric circles interference - overlapping ring patterns
  defp generate_concentric(width, height, rng, palette, config, animate) do
    {num_centers, rng} = RandomGenerator.uniform_range(rng, config.center_count)

    # Generate centers with their ring sets
    {centers, rng} =
      Enum.map_reduce(1..num_centers, rng, fn _, acc_rng ->
        {cx, acc_rng} = RandomGenerator.uniform_float(acc_rng, 0, width)
        {cy, acc_rng} = RandomGenerator.uniform_float(acc_rng, 0, height)
        {{cx, cy}, acc_rng}
      end)

    # Generate rings for each center
    {ring_spacing, rng} = RandomGenerator.uniform_range(rng, config.ring_spacing)
    max_radius = :math.sqrt(width * width + height * height)
    num_rings = trunc(max_radius / ring_spacing)

    {elements, rng} =
      Enum.map_reduce(centers, rng, fn {cx, cy}, acc_rng ->
        {opacity, acc_rng} = RandomGenerator.uniform_range(acc_rng, config.opacity)
        {stroke_width, acc_rng} = RandomGenerator.uniform_range(acc_rng, config.stroke_width)

        color = Enum.at(palette.colors, 0)

        rings =
          for i <- 1..num_rings do
            radius = i * ring_spacing

            ring =
              SVGBuilder.circle(cx, cy, radius)
              |> SVGBuilder.with_attrs(%{
                stroke: color,
                "stroke-width": stroke_width,
                fill: "none",
                opacity: opacity
              })

            Base.maybe_animate(ring, animate, "interference-ring")
          end

        {rings, acc_rng}
      end)

    {List.flatten(elements), rng}
  end

  # Wave interference - overlapping sine waves
  defp generate_wave(width, height, rng, palette, config, animate) do
    {num_sources, rng} = RandomGenerator.uniform_range(rng, config.wave_sources)

    # Generate wave sources
    {sources, rng} =
      Enum.map_reduce(1..num_sources, rng, fn _, acc_rng ->
        {cx, acc_rng} = RandomGenerator.uniform_float(acc_rng, 0, width)
        {cy, acc_rng} = RandomGenerator.uniform_float(acc_rng, 0, height)
        {freq, acc_rng} = RandomGenerator.uniform_range(acc_rng, config.wave_frequency)
        {phase, acc_rng} = RandomGenerator.uniform_float(acc_rng, 0, :math.pi() * 2)
        {{cx, cy, freq, phase}, acc_rng}
      end)

    # Create interference field as horizontal scan lines
    line_spacing = 6
    num_lines = trunc(height / line_spacing)

    {opacity, rng} = RandomGenerator.uniform_range(rng, config.opacity)
    color = Enum.at(palette.colors, 0)

    elements =
      for line_idx <- 0..num_lines do
        y = line_idx * line_spacing

        # Sample interference at each x position
        points =
          for x <- 0..width//8 do
            # Sum wave contributions from all sources
            wave_sum =
              Enum.reduce(sources, 0.0, fn {cx, cy, freq, phase}, acc ->
                dist = :math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy))
                acc + :math.sin(dist * freq + phase)
              end)

            # Normalize and map to y offset
            normalized = wave_sum / length(sources)
            y_offset = normalized * 8
            {x, y + y_offset}
          end

        path_data = points_to_path(points)

        path =
          SVGBuilder.path(path_data)
          |> SVGBuilder.with_attrs(%{
            stroke: color,
            "stroke-width": 1,
            fill: "none",
            opacity: opacity * (0.3 + normalized_line_opacity(line_idx, num_lines))
          })

        Base.maybe_animate(path, animate, "interference-wave", line_idx, 3)
      end

    {elements, rng}
  end

  defp normalized_line_opacity(idx, total) do
    # Fade edges
    center_dist = abs(idx - total / 2) / (total / 2)
    0.7 * (1 - center_dist * 0.5)
  end

  # Grid interference - overlapping rotated grids
  defp generate_grid(width, height, rng, palette, config, animate) do
    {num_grids, rng} = RandomGenerator.uniform_range(rng, config.grid_count)

    {grids, rng} =
      Enum.map_reduce(1..num_grids, rng, fn i, acc_rng ->
        {angle, acc_rng} = RandomGenerator.uniform_float(acc_rng, 0, :math.pi())
        {spacing, acc_rng} = RandomGenerator.uniform_range(acc_rng, config.grid_spacing)
        {opacity, acc_rng} = RandomGenerator.uniform_range(acc_rng, config.opacity)

        color = Enum.at(palette.colors, rem(i - 1, length(palette.colors)))

        lines = generate_rotated_grid(width, height, angle, spacing, color, opacity, animate, i)

        {lines, acc_rng}
      end)

    {List.flatten(grids), rng}
  end

  defp generate_rotated_grid(width, height, angle, spacing, color, opacity, animate, grid_idx) do
    # Extend bounds to cover rotation
    diagonal = :math.sqrt(width * width + height * height)
    cx = width / 2
    cy = height / 2

    cos_a = :math.cos(angle)
    sin_a = :math.sin(angle)

    num_lines = trunc(diagonal / spacing) + 1
    half_lines = div(num_lines, 2)

    for i <- -half_lines..half_lines do
      offset = i * spacing

      # Line perpendicular to angle, offset along angle direction
      # Start and end points extended beyond canvas
      x1 = cx + offset * cos_a - diagonal * sin_a
      y1 = cy + offset * sin_a + diagonal * cos_a
      x2 = cx + offset * cos_a + diagonal * sin_a
      y2 = cy + offset * sin_a - diagonal * cos_a

      line =
        SVGBuilder.line(x1, y1, x2, y2)
        |> SVGBuilder.with_attrs(%{
          stroke: color,
          "stroke-width": 0.5,
          opacity: opacity
        })

      Base.maybe_animate(line, animate, "interference-grid", grid_idx, 2)
    end
  end

  defp points_to_path([]), do: ""

  defp points_to_path([{x, y} | rest]) do
    start = "M #{format_num(x)},#{format_num(y)}"

    rest_path =
      Enum.map_join(rest, " ", fn {px, py} ->
        "L #{format_num(px)},#{format_num(py)}"
      end)

    start <> " " <> rest_path
  end

  defp format_num(n) when is_float(n), do: Float.round(n, 2)
  defp format_num(n) when is_integer(n), do: n

  @doc """
  Convenience function to generate and render interference pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :interference, slug, width, height, animate, tags)
  end
end
