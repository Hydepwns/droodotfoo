defmodule Droodotfoo.Content.Patterns.FlowField do
  @moduledoc """
  Flow field pattern generator using Perlin-like noise.

  Creates organic, flowing curves that follow a vector field derived
  from layered noise. Particles trace paths through the field,
  creating natural, wind-like patterns.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  # Noise parameters for flow field generation
  @noise_scale 0.005
  @noise_octaves 3
  @noise_persistence 0.5

  @doc """
  Generates a flow field pattern.

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
    config = PatternConfig.flow_field_config()

    # Generate noise seed for this pattern
    {noise_seed, rng} = RandomGenerator.uniform_float(rng, 0, 1000)

    # Generate random particle count
    {num_particles, rng} = RandomGenerator.uniform_range(rng, config.particle_count)

    # Generate all flow lines with threaded RNG state
    {elements, rng} =
      Enum.map_reduce(1..num_particles, rng, fn i, acc_rng ->
        generate_flow_line(i, width, height, config, palette, noise_seed, acc_rng, animate)
      end)

    {elements, rng}
  end

  # Generate a single flow line that follows the vector field
  defp generate_flow_line(index, width, height, config, palette, noise_seed, rng, animate) do
    # Random starting position
    {start_x, rng} = RandomGenerator.uniform_float(rng, 0, width)
    {start_y, rng} = RandomGenerator.uniform_float(rng, 0, height)

    # Random line properties
    {steps, rng} = RandomGenerator.uniform_range(rng, config.steps)
    {opacity, rng} = RandomGenerator.uniform_range(rng, config.opacity)
    {stroke_width, rng} = RandomGenerator.uniform_range(rng, config.stroke_width)

    # Pick color from palette
    color = Enum.at(palette.colors, rem(index, length(palette.colors)))

    # Trace the flow field from starting point
    points = trace_flow(start_x, start_y, steps, width, height, noise_seed, config.step_length)

    # Build path if we have enough points
    element =
      if length(points) >= 2 do
        path_data = points_to_smooth_path(points)

        path =
          SVGBuilder.path(path_data)
          |> SVGBuilder.with_attrs(%{
            stroke: color,
            "stroke-width": stroke_width,
            "stroke-linecap": "round",
            "stroke-linejoin": "round",
            fill: "none",
            opacity: opacity
          })

        Base.maybe_animate(path, animate, "flow-line", index, 4)
      else
        # Return an invisible element for short traces
        SVGBuilder.circle(0, 0, 0, %{opacity: 0})
      end

    {element, rng}
  end

  # Trace a path through the flow field
  defp trace_flow(start_x, start_y, steps, width, height, noise_seed, step_length) do
    initial_state = {start_x, start_y, [{start_x, start_y}]}

    {_, _, points} =
      Enum.reduce_while(1..steps, initial_state, fn _, {x, y, acc} ->
        # Get flow angle at current position
        angle = get_flow_angle(x, y, noise_seed)

        # Move in the direction of the flow
        new_x = x + :math.cos(angle) * step_length
        new_y = y + :math.sin(angle) * step_length

        # Check bounds
        if new_x < 0 or new_x > width or new_y < 0 or new_y > height do
          {:halt, {new_x, new_y, acc}}
        else
          {:cont, {new_x, new_y, [{new_x, new_y} | acc]}}
        end
      end)

    Enum.reverse(points)
  end

  # Get the flow direction at a given point using layered noise
  defp get_flow_angle(x, y, seed) do
    noise_value = layered_noise(x * @noise_scale, y * @noise_scale, seed)
    # Map noise to full rotation (0 to 2*PI)
    noise_value * :math.pi() * 2
  end

  # Layered noise using multiple octaves for more natural look
  defp layered_noise(x, y, seed) do
    Enum.reduce(0..(@noise_octaves - 1), 0, fn octave, acc ->
      frequency = :math.pow(2, octave)
      amplitude = :math.pow(@noise_persistence, octave)
      acc + simple_noise(x * frequency, y * frequency, seed) * amplitude
    end) / total_amplitude()
  end

  # Pre-calculate total amplitude for normalization
  defp total_amplitude do
    Enum.reduce(0..(@noise_octaves - 1), 0, fn octave, acc ->
      acc + :math.pow(@noise_persistence, octave)
    end)
  end

  # Simple deterministic noise using sine waves
  # This creates smooth, continuous noise without external dependencies
  defp simple_noise(x, y, seed) do
    # Combine multiple sine waves at different frequencies for pseudo-random noise
    n1 = :math.sin(x * 1.0 + seed) * :math.cos(y * 1.0 + seed * 0.7)
    n2 = :math.sin(x * 2.3 + y * 1.7 + seed * 1.3) * 0.5
    n3 = :math.cos(x * 3.7 + y * 2.9 + seed * 0.9) * 0.25
    n4 = :math.sin((x + y) * 1.5 + seed * 2.1) * 0.125

    # Normalize to 0-1 range
    (n1 + n2 + n3 + n4 + 1.0) / 2.0
  end

  # Convert points to a smooth cubic bezier path
  defp points_to_smooth_path(points) when length(points) < 2, do: ""

  defp points_to_smooth_path(points) do
    [{first_x, first_y} | _rest] = points

    # Start path
    start = "M #{format_num(first_x)},#{format_num(first_y)}"

    # Use catmull-rom to bezier conversion for smooth curves
    curves = points_to_curves(points)

    start <> " " <> curves
  end

  # Convert points to smooth curves using Catmull-Rom spline
  defp points_to_curves(points) when length(points) < 4 do
    # Fall back to simple lines for short paths
    points
    |> Enum.drop(1)
    |> Enum.map_join(" ", fn {x, y} -> "L #{format_num(x)},#{format_num(y)}" end)
  end

  defp points_to_curves(points) do
    # Add phantom points at start and end for full curve coverage
    first = hd(points)
    last = List.last(points)
    extended = [first | points] ++ [last]

    extended
    |> Enum.chunk_every(4, 1, :discard)
    |> Enum.map(&catmull_to_bezier/1)
    |> Enum.join(" ")
  end

  # Convert 4 Catmull-Rom points to a cubic bezier curve
  defp catmull_to_bezier([{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}]) do
    # Catmull-Rom to Bezier conversion (tension = 0.5)
    tension = 6.0

    cp1x = x1 + (x2 - x0) / tension
    cp1y = y1 + (y2 - y0) / tension
    cp2x = x2 - (x3 - x1) / tension
    cp2y = y2 - (y3 - y1) / tension

    "C #{format_num(cp1x)},#{format_num(cp1y)} #{format_num(cp2x)},#{format_num(cp2y)} #{format_num(x2)},#{format_num(y2)}"
  end

  defp format_num(n), do: :erlang.float_to_binary(n * 1.0, decimals: 2)

  @doc """
  Convenience function to generate and render flow field pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :flow_field, slug, width, height, animate, tags)
  end
end
