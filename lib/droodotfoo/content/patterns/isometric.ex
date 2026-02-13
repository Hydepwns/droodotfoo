defmodule Droodotfoo.Content.Patterns.Isometric do
  @moduledoc """
  Isometric 3D grid pattern generator.

  Generates isometric cube grids and 3D-looking geometric patterns
  with depth and perspective.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  # Isometric angles (30 degrees converted to radians)
  @iso_angle :math.pi() / 6

  # Config struct for cube grid generation
  defmodule GridConfig do
    @moduledoc false
    defstruct [
      :cube_size,
      :iso_width,
      :iso_height,
      :show_probability,
      :height_variation,
      :stroke_width,
      :opacity,
      :animate
    ]
  end

  @doc """
  Generates an isometric 3D grid pattern.

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
    config = PatternConfig.isometric_config()

    # Generate random parameters
    {cube_size, rng} = RandomGenerator.uniform_range(rng, config.cube_size)
    {show_probability, rng} = RandomGenerator.uniform_range(rng, config.show_probability)
    {height_variation, rng} = RandomGenerator.uniform_range(rng, config.height_variation)
    {stroke_width, rng} = RandomGenerator.uniform_range(rng, config.stroke_width)
    {opacity, rng} = RandomGenerator.uniform_range(rng, config.opacity)

    # Calculate grid dimensions
    iso_width = cube_size * :math.cos(@iso_angle)
    iso_height = cube_size * :math.sin(@iso_angle)

    cols = trunc(width / iso_width) + 2
    rows = trunc(height / (iso_height * 2)) + 2

    # Start from offset position for centering
    start_x = width / 2
    start_y = height * 0.1

    grid_config = %GridConfig{
      cube_size: cube_size,
      iso_width: iso_width,
      iso_height: iso_height,
      show_probability: show_probability,
      height_variation: height_variation,
      stroke_width: stroke_width,
      opacity: opacity,
      animate: animate
    }

    # Generate cubes at grid positions
    {cubes, rng} = generate_cube_grid(cols, rows, start_x, start_y, grid_config, rng)

    {List.flatten(cubes), rng}
  end

  defp generate_cube_grid(cols, rows, start_x, start_y, config, rng) do
    %GridConfig{iso_width: iso_width, iso_height: iso_height} = config

    positions =
      for row <- 0..(rows - 1),
          col <- -div(cols, 2)..div(cols, 2) do
        # Isometric position calculation
        x = start_x + col * iso_width * 2 + if rem(row, 2) == 1, do: iso_width, else: 0
        y = start_y + row * iso_height * 2
        {x, y, row, col}
      end

    Enum.map_reduce(positions, rng, fn {x, y, row, col}, acc_rng ->
      # Decide whether to show this cube
      {show, acc_rng} = RandomGenerator.chance(acc_rng, config.show_probability)

      if show do
        # Random height multiplier for stacking effect
        {height_mult, acc_rng} =
          RandomGenerator.uniform_float(acc_rng, 1, 1 + config.height_variation)

        cube_elements = generate_isometric_cube(x, y, height_mult, row, col, config)

        {cube_elements, acc_rng}
      else
        {[], acc_rng}
      end
    end)
  end

  defp generate_isometric_cube(x, y, height_mult, row, col, config) do
    %GridConfig{
      cube_size: size,
      stroke_width: stroke_width,
      opacity: base_opacity,
      animate: animate
    } = config

    # Calculate isometric vectors
    iso_x = size * :math.cos(@iso_angle)
    iso_y = size * :math.sin(@iso_angle)
    height = size * height_mult

    # Define cube vertices
    # Top face
    top_center = {x, y}
    top_right = {x + iso_x, y + iso_y}
    top_far = {x, y + iso_y * 2}
    top_left = {x - iso_x, y + iso_y}

    # Bottom face (offset by height)
    bot_center = {x, y + height}
    bot_right = {x + iso_x, y + iso_y + height}
    _bot_far = {x, y + iso_y * 2 + height}
    bot_left = {x - iso_x, y + iso_y + height}

    index = row * 10 + col

    # Draw visible faces (top, left, right)
    [
      # Top face (brightest)
      build_face(
        [top_center, top_right, top_far, top_left],
        stroke_width,
        base_opacity,
        index,
        0,
        animate
      ),
      # Left face (medium)
      build_face(
        [top_center, top_left, bot_left, bot_center],
        stroke_width,
        base_opacity * 0.7,
        index,
        1,
        animate
      ),
      # Right face (darkest)
      build_face(
        [top_center, top_right, bot_right, bot_center],
        stroke_width,
        base_opacity * 0.5,
        index,
        2,
        animate
      ),
      # Visible back edges
      build_edge(top_left, bot_left, stroke_width, base_opacity * 0.6),
      build_edge(top_right, bot_right, stroke_width, base_opacity * 0.6),
      build_edge(bot_center, bot_left, stroke_width, base_opacity * 0.4),
      build_edge(bot_center, bot_right, stroke_width, base_opacity * 0.4)
    ]
    |> List.flatten()
  end

  defp build_face(vertices, stroke_width, opacity, index, face_type, animate) do
    points =
      Enum.map_join(vertices, " ", fn {x, y} ->
        "#{Base.round_coord(x)},#{Base.round_coord(y)}"
      end)

    element =
      SVGBuilder.polygon(points, %{})
      |> SVGBuilder.with_attrs(%{
        fill: "none",
        stroke: "#ffffff",
        "stroke-width": stroke_width,
        opacity: opacity
      })

    if animate do
      element
      |> SVGBuilder.with_class("iso-face-#{face_type}")
      |> SVGBuilder.with_attrs(%{style: "--index: #{index}"})
    else
      element
    end
  end

  defp build_edge({x1, y1}, {x2, y2}, stroke_width, opacity) do
    SVGBuilder.line(x1, y1, x2, y2, %{})
    |> SVGBuilder.with_attrs(%{
      stroke: "#ffffff",
      "stroke-width": stroke_width * 0.5,
      opacity: opacity
    })
  end

  @doc """
  Convenience function to generate and render isometric pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :isometric, slug, width, height, animate, tags)
  end
end
