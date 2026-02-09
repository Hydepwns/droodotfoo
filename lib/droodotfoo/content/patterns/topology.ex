defmodule Droodotfoo.Content.Patterns.Topology do
  @moduledoc """
  Topographic contour line pattern generator.

  Generates elevation map-style contour lines using Perlin noise
  to create organic terrain-like patterns.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  # Config struct for contour line generation
  defmodule ContourConfig do
    @moduledoc false
    defstruct [
      :noise_scale,
      :octaves,
      :offset_x,
      :offset_y,
      :stroke_width,
      :opacity,
      :animate
    ]
  end

  # Marching squares lookup table: case index -> edge pairs
  # Each edge: :left, :right, :top, :bottom
  # Returns list of {from_edge, to_edge} tuples for line segments
  @marching_squares_table %{
    0 => [],
    1 => [{:left, :bottom}],
    2 => [{:bottom, :right}],
    3 => [{:left, :right}],
    4 => [{:top, :right}],
    5 => [{:left, :top}, {:bottom, :right}],
    6 => [{:top, :bottom}],
    7 => [{:left, :top}],
    8 => [{:top, :left}],
    9 => [{:top, :bottom}],
    10 => [{:top, :right}, {:left, :bottom}],
    11 => [{:top, :right}],
    12 => [{:left, :right}],
    13 => [{:bottom, :right}],
    14 => [{:left, :bottom}],
    15 => []
  }

  @doc """
  Generates a topology pattern with contour lines.

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
  def generate(width, height, rng, _palette, animate \\ false) do
    config = PatternConfig.topology_config()

    # Generate random parameters
    {contour_count, rng} = RandomGenerator.uniform_range(rng, config.contour_count)
    {noise_scale, rng} = RandomGenerator.uniform_range(rng, config.noise_scale)
    {octaves, rng} = RandomGenerator.uniform_range(rng, config.octaves)
    {stroke_width, rng} = RandomGenerator.uniform_range(rng, config.stroke_width)
    {opacity, rng} = RandomGenerator.uniform_range(rng, config.opacity)

    # Generate offset values for noise
    {offset_x, rng} = RandomGenerator.uniform_float(rng, 0, 1000)
    {offset_y, rng} = RandomGenerator.uniform_float(rng, 0, 1000)

    contour_count = trunc(contour_count)

    contour_config = %ContourConfig{
      noise_scale: noise_scale,
      octaves: trunc(octaves),
      offset_x: offset_x,
      offset_y: offset_y,
      stroke_width: stroke_width,
      opacity: opacity,
      animate: animate
    }

    # Generate contour lines at different threshold levels
    {contours, rng} =
      Enum.map_reduce(0..(contour_count - 1), rng, fn level, acc_rng ->
        threshold = level / contour_count
        contour = generate_contour_line(width, height, threshold, level, contour_config)
        {contour, acc_rng}
      end)

    elements =
      contours
      |> Enum.reject(&is_nil/1)
      |> List.flatten()

    {elements, rng}
  end

  defp generate_contour_line(width, height, threshold, level, config) do
    %ContourConfig{
      noise_scale: noise_scale,
      octaves: octaves,
      offset_x: offset_x,
      offset_y: offset_y,
      stroke_width: stroke_width,
      opacity: base_opacity,
      animate: animate
    } = config

    # Sample noise field and find contour crossings using marching squares
    step = 15
    cols = div(trunc(width), step)
    rows = div(trunc(height), step)

    # Generate path segments for this contour level
    segments =
      for row <- 0..(rows - 1),
          col <- 0..(cols - 1) do
        x = col * step
        y = row * step

        # Sample corners of cell
        tl = sample_noise(x, y, noise_scale, octaves, offset_x, offset_y)
        tr = sample_noise(x + step, y, noise_scale, octaves, offset_x, offset_y)
        bl = sample_noise(x, y + step, noise_scale, octaves, offset_x, offset_y)
        br = sample_noise(x + step, y + step, noise_scale, octaves, offset_x, offset_y)

        # Marching squares case
        marching_squares_segment(x, y, step, threshold, tl, tr, bl, br)
      end
      |> List.flatten()
      |> Enum.reject(&is_nil/1)

    # Build paths from connected segments
    if segments != [] do
      path_data = build_contour_paths(segments)

      # Vary opacity slightly per contour level
      opacity = base_opacity * (0.5 + 0.5 * (1 - threshold))

      element =
        SVGBuilder.path(path_data, %{})
        |> SVGBuilder.with_attrs(%{
          stroke: "#ffffff",
          "stroke-width": stroke_width,
          fill: "none",
          opacity: opacity,
          "stroke-linecap": "round",
          "stroke-linejoin": "round"
        })

      Base.maybe_animate(element, animate, "topo-line", level, 3)
    else
      nil
    end
  end

  # Simplified Perlin-like noise using sine waves
  defp sample_noise(x, y, scale, octaves, offset_x, offset_y) do
    nx = (x + offset_x) * scale
    ny = (y + offset_y) * scale

    Enum.reduce(1..octaves, 0, fn octave, acc ->
      freq = :math.pow(2, octave - 1)
      amp = :math.pow(0.5, octave - 1)

      val =
        :math.sin(nx * freq) * :math.cos(ny * freq * 0.7) +
          :math.sin((nx + ny) * freq * 0.5) * 0.5

      acc + val * amp
    end)
    # Normalize to 0-1
    |> then(fn v -> (v + 1) / 2 end)
  end

  # Marching squares - returns line segment for cell
  defp marching_squares_segment(x, y, step, threshold, tl, tr, bl, br) do
    # Classify corners (8=TL, 4=TR, 2=BR, 1=BL)
    case_index =
      if(tl >= threshold, do: 8, else: 0) +
        if(tr >= threshold, do: 4, else: 0) +
        if(br >= threshold, do: 2, else: 0) +
        if bl >= threshold, do: 1, else: 0

    # Interpolate edge crossings
    edges = %{
      left: {x, y + step * Base.lerp_factor(tl, bl, threshold)},
      right: {x + step, y + step * Base.lerp_factor(tr, br, threshold)},
      top: {x + step * Base.lerp_factor(tl, tr, threshold), y},
      bottom: {x + step * Base.lerp_factor(bl, br, threshold), y + step}
    }

    # Look up edge pairs and resolve to coordinates
    @marching_squares_table
    |> Map.get(case_index, [])
    |> Enum.map(fn {from_edge, to_edge} ->
      {edges[from_edge], edges[to_edge]}
    end)
  end

  defp build_contour_paths(segments) do
    segments
    |> Enum.map(fn {{x1, y1}, {x2, y2}} ->
      "M#{Base.round_coord(x1)},#{Base.round_coord(y1)} L#{Base.round_coord(x2)},#{Base.round_coord(y2)}"
    end)
    |> Enum.join(" ")
  end

  @doc """
  Convenience function to generate and render topology pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :topology, slug, width, height, animate, tags)
  end
end
