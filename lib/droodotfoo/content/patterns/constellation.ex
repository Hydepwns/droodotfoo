defmodule Droodotfoo.Content.Patterns.Constellation do
  @moduledoc """
  Constellation pattern generator.

  Creates a starfield with points that fade in and connecting lines
  that draw themselves, creating an emergence effect like stars
  appearing in the night sky.
  """

  alias Droodotfoo.Content.{PatternConfig, RandomGenerator, SVGBuilder}
  alias Droodotfoo.Content.Patterns.Base

  @doc """
  Generates a constellation pattern.

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
    config = PatternConfig.constellation_config()

    {star_count, rng} = RandomGenerator.uniform_range(rng, config.star_count)
    {connection_distance, rng} = RandomGenerator.uniform_range(rng, config.connection_distance)

    star_count = trunc(star_count)

    # Generate star positions
    {stars, rng} =
      Enum.map_reduce(1..star_count, rng, fn i, acc_rng ->
        {x, acc_rng} = RandomGenerator.uniform_float(acc_rng, 20, width - 20)
        {y, acc_rng} = RandomGenerator.uniform_float(acc_rng, 20, height - 20)
        {size, acc_rng} = RandomGenerator.uniform_range(acc_rng, config.star_size)
        {brightness, acc_rng} = RandomGenerator.uniform_range(acc_rng, config.brightness)
        {{i, x, y, size, brightness}, acc_rng}
      end)

    # Generate connection lines between nearby stars
    connections = generate_connections(stars, connection_distance)

    # Build line elements
    color = Enum.at(palette.colors, 0)

    line_elements =
      connections
      |> Enum.with_index()
      |> Enum.map(fn {{x1, y1, x2, y2}, idx} ->
        element =
          SVGBuilder.line(x1, y1, x2, y2, %{
            stroke: color,
            "stroke-width": 0.5,
            opacity: 0.3,
            "stroke-linecap": "round"
          })

        if animate do
          SVGBuilder.with_class(element, "constellation-line-#{rem(idx, 4)}")
          |> SVGBuilder.with_attrs(%{style: "--i: #{idx}"})
        else
          element
        end
      end)

    # Build star elements
    star_elements =
      stars
      |> Enum.map(fn {i, x, y, size, brightness} ->
        element =
          SVGBuilder.circle(x, y, size, %{
            fill: color,
            opacity: brightness
          })

        if animate do
          SVGBuilder.with_class(element, "constellation-star-#{rem(i, 3)}")
          |> SVGBuilder.with_attrs(%{style: "--i: #{i}"})
        else
          element
        end
      end)

    # Lines first, then stars on top
    {line_elements ++ star_elements, rng}
  end

  defp generate_connections(stars, max_distance) do
    # For each star, connect to nearby stars (avoiding duplicates)
    stars
    |> Enum.flat_map(fn {i1, x1, y1, _s1, _b1} ->
      stars
      |> Enum.filter(fn {i2, x2, y2, _s2, _b2} ->
        i2 > i1 && Base.distance(x1, y1, x2, y2) < max_distance
      end)
      |> Enum.take(3)
      |> Enum.map(fn {_i2, x2, y2, _s2, _b2} ->
        {x1, y1, x2, y2}
      end)
    end)
  end

  @doc """
  Convenience function to generate and render constellation pattern to SVG string.
  """
  @spec generate_svg(String.t(), number, number, boolean, [String.t()]) :: String.t()
  def generate_svg(slug, width, height, animate \\ false, tags \\ []) do
    Base.generate_svg(__MODULE__, :constellation, slug, width, height, animate, tags)
  end
end
