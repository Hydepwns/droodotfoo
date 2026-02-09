defmodule Droodotfoo.Content.Patterns.Circuit do
  @moduledoc """
  Circuit board traces pattern generator.

  Generates right-angled paths resembling circuit board traces
  for a technical, electronic aesthetic.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  @doc """
  Generates a circuit pattern.

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
    config = PatternConfig.circuit_config()

    # Generate random trace count
    {num_traces, rng} = RandomGenerator.uniform_range(rng, config.trace_count)

    # Generate all traces
    Enum.map_reduce(1..num_traces, rng, fn i, acc_rng ->
      generate_single_trace(i, width, height, config, palette, acc_rng, animate)
    end)
  end

  # Private helper to generate a single circuit trace
  defp generate_single_trace(index, width, height, config, palette, rng, animate) do
    # Generate random start point
    {start_x, rng} = RandomGenerator.uniform_float(rng, 0, width)
    {start_y, rng} = RandomGenerator.uniform_float(rng, 0, height)

    # Generate random number of segments
    {segments, rng} = RandomGenerator.uniform_range(rng, config.segments)

    # Build path with right-angle segments
    {points, rng} =
      Enum.reduce(1..segments, {[{start_x, start_y}], rng}, fn _, {points, acc_rng} ->
        [{last_x, last_y} | _] = points

        {segment_length, acc_rng} = RandomGenerator.uniform_range(acc_rng, config.segment_length)
        {direction, acc_rng} = RandomGenerator.uniform_int(acc_rng, 4)

        # Move in one of 4 cardinal directions
        {new_x, new_y, acc_rng} =
          case rem(direction, 2) do
            0 ->
              # Horizontal movement
              {is_positive, new_rng} = RandomGenerator.chance(acc_rng, 0.5)

              if is_positive do
                {last_x + segment_length, last_y, new_rng}
              else
                {last_x - segment_length, last_y, new_rng}
              end

            _ ->
              # Vertical movement
              {is_positive, new_rng} = RandomGenerator.chance(acc_rng, 0.5)

              if is_positive do
                {last_x, last_y + segment_length, new_rng}
              else
                {last_x, last_y - segment_length, new_rng}
              end
          end

        {[{new_x, new_y} | points], acc_rng}
      end)

    points = Enum.reverse(points)

    # Build path data string
    path_data =
      Enum.map_join(points, " L ", fn {x, y} -> "#{x},#{y}" end)
      |> then(&("M " <> &1))

    # Generate random styling
    {thickness, rng} = RandomGenerator.uniform_range(rng, config.thickness)
    {opacity, rng} = RandomGenerator.uniform_range(rng, config.opacity)

    # Pick color from palette
    color = Enum.at(palette.colors, rem(index, length(palette.colors)))

    # Create circuit trace element
    trace_element =
      SVGBuilder.path(path_data)
      |> SVGBuilder.with_attrs(%{
        stroke: color,
        "stroke-width": thickness,
        fill: "none",
        opacity: opacity,
        "stroke-linecap": "square"
      })

    {Base.maybe_animate(trace_element, animate, "circuit-glow"), rng}
  end

  @doc """
  Convenience function to generate and render circuit pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :circuit, slug, width, height, animate, tags)
  end
end
