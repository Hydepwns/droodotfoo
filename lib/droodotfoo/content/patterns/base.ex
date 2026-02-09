defmodule Droodotfoo.Content.Patterns.Base do
  @moduledoc """
  Shared utilities for pattern generators.

  Reduces boilerplate across pattern modules by providing common
  functions for SVG generation, palette selection, and element building.
  """

  alias Droodotfoo.Content.{PatternAnimations, PatternConfig, RandomGenerator, SVGBuilder}

  @doc """
  Generates complete SVG string from a pattern module.

  Handles the common flow: create RNG -> choose palette -> generate elements -> build SVG.

  ## Parameters

    * `pattern_module` - The pattern module (must implement `generate/5`)
    * `pattern_style` - Atom for palette/animation lookup (e.g., `:topology`)
    * `slug` - Post slug for deterministic generation
    * `width` - Canvas width
    * `height` - Canvas height
    * `animate` - Whether to include CSS animations
    * `tags` - Post tags for color extraction

  ## Example

      Base.generate_svg(__MODULE__, :topology, slug, 1200, 630, true, [])
  """
  @spec generate_svg(module, atom, String.t(), number, number, boolean, [String.t()]) ::
          String.t()
  def generate_svg(pattern_module, pattern_style, slug, width, height, animate, tags) do
    rng = RandomGenerator.new(slug)
    {_name, palette} = choose_palette(pattern_style, slug, tags)
    {elements, _rng} = pattern_module.generate(width, height, rng, palette, animate)

    animations = if animate, do: PatternAnimations.get_animations(pattern_style), else: ""

    SVGBuilder.build_svg(elements,
      width: width,
      height: height,
      background: palette.bg,
      animations: animations
    )
  end

  @doc """
  Chooses palette based on tags or style.
  """
  @spec choose_palette(atom, String.t(), [String.t()]) ::
          {atom, %{bg: String.t(), colors: [String.t()]}}
  def choose_palette(style, slug, []), do: PatternConfig.choose_palette_for_style(slug, style)
  def choose_palette(_style, _slug, tags), do: PatternConfig.choose_palette_for_tags(tags, "")

  @doc """
  Conditionally adds animation class to element.
  """
  @spec maybe_animate(SVGBuilder.element(), boolean, String.t()) :: SVGBuilder.element()
  def maybe_animate(element, false, _class), do: element
  def maybe_animate(element, true, class), do: SVGBuilder.with_class(element, class)

  @doc """
  Conditionally adds animation class with index-based variation.
  """
  @spec maybe_animate(SVGBuilder.element(), boolean, String.t(), integer, integer) ::
          SVGBuilder.element()
  def maybe_animate(element, false, _prefix, _index, _variants), do: element

  def maybe_animate(element, true, prefix, index, variants) do
    class = "#{prefix}-#{rem(index, variants)}"
    SVGBuilder.with_class(element, class)
  end

  @doc """
  Euclidean distance between two points.
  """
  @spec distance(number, number, number, number) :: float
  def distance(x1, y1, x2, y2) do
    :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2))
  end

  @doc """
  Ensures value is a float for Float.round/2.
  """
  @spec to_float(number) :: float
  def to_float(n) when is_float(n), do: n
  def to_float(n) when is_integer(n), do: n * 1.0

  @doc """
  Rounds a coordinate to 1 decimal place, handling both int and float.
  """
  @spec round_coord(number) :: float
  def round_coord(n), do: Float.round(to_float(n), 1)

  @doc """
  Clamps a value between min and max.
  """
  @spec clamp(number, number, number) :: number
  def clamp(val, min, max), do: val |> max(min) |> min(max)

  @doc """
  Linear interpolation factor between two values at a threshold.
  Returns 0.5 if values are too close (avoids division by zero).
  """
  @spec lerp_factor(number, number, number) :: float
  def lerp_factor(v1, v2, threshold) do
    if abs(v2 - v1) < 0.0001 do
      0.5
    else
      clamp((threshold - v1) / (v2 - v1), 0, 1)
    end
  end
end
