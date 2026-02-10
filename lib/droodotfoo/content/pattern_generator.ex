defmodule Droodotfoo.Content.PatternGenerator do
  @moduledoc """
  Generates deterministic black and white SVG patterns for blog posts.
  Each post gets a unique generative art pattern based on its slug,
  perfect for social sharing cards.

  All patterns now use the refactored architecture with PatternConfig,
  PatternAnimations, RandomGenerator, and SVGBuilder modules.
  """

  alias Droodotfoo.Content.PatternConfig

  # Refactored pattern modules
  alias Droodotfoo.Content.Patterns

  @type pattern_style ::
          :waves
          | :noise
          | :lines
          | :dots
          | :circuit
          | :glitch
          | :geometric
          | :grid
          | :flow_field
          | :interference
          | :topology
          | :voronoi
          | :isometric
          | :composite
  @type animation_mode :: :none | :css | :smil
  @type generate_opts :: [
          width: pos_integer(),
          height: pos_integer(),
          style: pattern_style() | nil,
          animate: boolean(),
          animation_mode: animation_mode(),
          tags: [String.t()]
        ]

  @doc """
  Generates an SVG pattern based on the post slug.

  ## Options

    * `:width` - Image width in pixels (default: 1200, max: 2400)
    * `:height` - Image height in pixels (default: 630, max: 2400)
    * `:style` - Pattern style (default: random based on slug)
      - `:waves` - Flowing sine waves (refactored)
      - `:noise` - Static/TV noise effect (refactored)
      - `:lines` - Parallel or radiating lines (refactored)
      - `:dots` - Halftone dot matrix (refactored)
      - `:circuit` - Circuit board traces (refactored)
      - `:glitch` - Corrupted data/glitch art (refactored)
      - `:geometric` - Classic geometric shapes (refactored)
      - `:grid` - Cellular grid pattern (refactored)
    * `:animate` - Enable CSS animations (default: false)

  ## Examples

      iex> PatternGenerator.generate_svg("my-post-slug")
      "<?xml version=\\"1.0\\"...>"

      iex> PatternGenerator.generate_svg("my-post", style: :waves, animate: true)
      "<?xml version=\\"1.0\\"...>"

  ## Returns

  Returns the generated SVG as a string. If validation fails, returns a
  simple fallback pattern instead of crashing.
  """
  @spec generate_svg(String.t(), generate_opts()) :: String.t()
  def generate_svg(slug, opts \\ []) do
    # Validate and extract options
    case validate_options(slug, opts) do
      {:ok, validated_opts} ->
        generate_svg_validated(slug, validated_opts)

      {:error, reason} ->
        # Log error and return fallback pattern
        require Logger
        Logger.warning("Pattern generation failed: #{inspect(reason)}, using fallback")
        generate_fallback_pattern(1200, 630)
    end
  end

  # Validates input options
  defp validate_options(slug, opts) do
    with :ok <- validate_slug(slug),
         {:ok, width} <- validate_dimension(Keyword.get(opts, :width, 1200)),
         {:ok, height} <- validate_dimension(Keyword.get(opts, :height, 630)),
         {:ok, style} <- validate_style(Keyword.get(opts, :style)),
         {:ok, animate} <- validate_boolean(Keyword.get(opts, :animate, false)),
         {:ok, tags} <- validate_tags(Keyword.get(opts, :tags, [])) do
      {:ok, %{width: width, height: height, style: style, animate: animate, tags: tags}}
    end
  end

  defp validate_slug(slug) when is_binary(slug) and byte_size(slug) > 0, do: :ok
  defp validate_slug(_), do: {:error, :invalid_slug}

  defp validate_dimension(dim) when is_integer(dim) and dim > 0 and dim <= 2400, do: {:ok, dim}
  defp validate_dimension(_), do: {:error, :invalid_dimension}

  defp validate_style(nil), do: {:ok, nil}

  defp validate_style(style) when is_atom(style) do
    if PatternConfig.valid_style?(style) do
      {:ok, style}
    else
      {:error, :invalid_style}
    end
  end

  defp validate_style(_), do: {:error, :invalid_style}

  defp validate_boolean(val) when is_boolean(val), do: {:ok, val}
  defp validate_boolean(_), do: {:error, :invalid_boolean}

  defp validate_tags(tags) when is_list(tags) do
    if Enum.all?(tags, &is_binary/1) do
      {:ok, tags}
    else
      {:error, :invalid_tags}
    end
  end

  defp validate_tags(_), do: {:error, :invalid_tags}

  # Generates SVG with validated options
  defp generate_svg_validated(slug, opts) do
    width = opts.width
    height = opts.height
    animate = opts.animate
    tags = opts.tags

    # Choose style based on slug if not specified
    style = opts.style || choose_style(slug)

    # Generate pattern using refactored modules
    # All patterns now use the new architecture and return complete SVG
    # Tags are passed for accent color extraction
    case style do
      :waves -> Patterns.Waves.generate_svg(slug, width, height, animate, tags)
      :noise -> Patterns.Noise.generate_svg(slug, width, height, animate, tags)
      :lines -> Patterns.Lines.generate_svg(slug, width, height, animate, tags)
      :dots -> Patterns.Dots.generate_svg(slug, width, height, animate, tags)
      :circuit -> Patterns.Circuit.generate_svg(slug, width, height, animate, tags)
      :glitch -> Patterns.Glitch.generate_svg(slug, width, height, animate, tags)
      :geometric -> Patterns.Geometric.generate_svg(slug, width, height, animate, tags)
      :grid -> Patterns.Grid.generate_svg(slug, width, height, animate, tags)
      :flow_field -> Patterns.FlowField.generate_svg(slug, width, height, animate, tags)
      :interference -> Patterns.Interference.generate_svg(slug, width, height, animate, tags)
      :topology -> Patterns.Topology.generate_svg(slug, width, height, animate, tags)
      :voronoi -> Patterns.Voronoi.generate_svg(slug, width, height, animate, tags)
      :isometric -> Patterns.Isometric.generate_svg(slug, width, height, animate, tags)
      :constellation -> Patterns.Constellation.generate_svg(slug, width, height, animate, tags)
      :aurora -> Patterns.Aurora.generate_svg(slug, width, height, animate, tags)
      :composite -> Patterns.Composite.generate_svg(slug, width, height, animate, tags)
      _ -> Patterns.Waves.generate_svg(slug, width, height, animate, tags)
    end
  end

  # Generates a simple fallback pattern when generation fails
  defp generate_fallback_pattern(width, height) do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{width} #{height}" preserveAspectRatio="none" style="width: 100%; height: 100%; display: block;">
      <rect width="#{width}" height="#{height}" fill="#000000"/>
      <circle cx="#{width / 2}" cy="#{height / 2}" r="100" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.5"/>
    </svg>
    """
  end

  # Choose a style deterministically based on slug
  defp choose_style(slug) do
    styles = [
      :waves,
      :noise,
      :lines,
      :dots,
      :circuit,
      :glitch,
      :geometric,
      :grid,
      :flow_field,
      :interference,
      :topology,
      :voronoi,
      :isometric,
      :constellation,
      :aurora,
      :composite
    ]

    hash = :erlang.phash2(slug)
    index = rem(hash, length(styles))
    Enum.at(styles, index)
  end

  @doc """
  Generates an SVG pattern with SMIL animations for social cards.

  SMIL animations are embedded directly in SVG elements and work
  without CSS, making them ideal for OG images and static contexts.

  ## Options

    * `:width` - Image width in pixels (default: 1200)
    * `:height` - Image height in pixels (default: 630)
    * `:style` - Pattern style (default: random based on slug)
    * `:tags` - Blog post tags for color extraction

  ## Examples

      iex> PatternGenerator.generate_social_card_svg("my-post")
      "<?xml version=\\"1.0\\"...>"
  """
  @spec generate_social_card_svg(String.t(), generate_opts()) :: String.t()
  def generate_social_card_svg(slug, opts \\ []) do
    alias Droodotfoo.Content.{RandomGenerator, SMILAnimations, SVGBuilder}

    case validate_options(slug, Keyword.put(opts, :animate, false)) do
      {:ok, validated_opts} ->
        width = validated_opts.width
        height = validated_opts.height
        tags = validated_opts.tags
        style = validated_opts.style || choose_style(slug)

        rng = RandomGenerator.new(slug)
        {_palette_name, palette} = PatternConfig.choose_palette_for_tags(tags, slug)

        # Generate base pattern elements
        {elements, _rng} = generate_pattern_elements(style, width, height, rng, palette)

        # Add SMIL animations to elements
        animated_elements = add_smil_animations(elements, style)

        SVGBuilder.build_svg(animated_elements,
          width: width,
          height: height,
          background: palette.bg
        )

      {:error, _reason} ->
        generate_fallback_pattern(1200, 630)
    end
  end

  # Generate pattern elements without CSS animations
  defp generate_pattern_elements(style, width, height, rng, palette) do
    case style do
      :waves -> Patterns.Waves.generate(width, height, rng, palette, false)
      :noise -> Patterns.Noise.generate(width, height, rng, palette, false)
      :lines -> Patterns.Lines.generate(width, height, rng, palette, false)
      :dots -> Patterns.Dots.generate(width, height, rng, palette, false)
      :circuit -> Patterns.Circuit.generate(width, height, rng, palette, false)
      :glitch -> Patterns.Glitch.generate(width, height, rng, palette, false)
      :geometric -> Patterns.Geometric.generate(width, height, rng, palette, false)
      :grid -> Patterns.Grid.generate(width, height, rng, palette, false)
      :flow_field -> Patterns.FlowField.generate(width, height, rng, palette, false)
      :interference -> Patterns.Interference.generate(width, height, rng, palette, false)
      :topology -> Patterns.Topology.generate(width, height, rng, palette, false)
      :voronoi -> Patterns.Voronoi.generate(width, height, rng, palette, false)
      :isometric -> Patterns.Isometric.generate(width, height, rng, palette, false)
      :constellation -> Patterns.Constellation.generate(width, height, rng, palette, false)
      :aurora -> Patterns.Aurora.generate(width, height, rng, palette, false)
      :composite -> Patterns.Composite.generate(width, height, rng, palette, false)
      _ -> Patterns.Waves.generate(width, height, rng, palette, false)
    end
  end

  # Add SMIL animations based on pattern style
  defp add_smil_animations(elements, style) do
    alias Droodotfoo.Content.{SMILAnimations, SVGBuilder}

    elements
    |> Enum.with_index()
    |> Enum.map(fn {element, index} ->
      smil = get_smil_for_style(style, index)
      if smil, do: SVGBuilder.with_smil(element, smil), else: element
    end)
  end

  alias Droodotfoo.Content.SMILAnimations

  defp get_smil_for_style(:waves, index) do
    delay = SMILAnimations.stagger_delay(index, 0.1)

    SMILAnimations.transform(
      type: "translate",
      values: "0,0;0,-5;0,0",
      dur: 4 + rem(index, 3),
      begin: delay
    )
  end

  defp get_smil_for_style(:dots, index) do
    delay = SMILAnimations.stagger_delay(index, 0.05)

    SMILAnimations.pulse(
      dur: 3 + rem(index, 2),
      begin: delay,
      scale_range: {0.9, 1.1},
      opacity_range: {0.5, 0.9}
    )
  end

  defp get_smil_for_style(:circuit, index) do
    delay = SMILAnimations.stagger_delay(index, 0.15)
    SMILAnimations.opacity(values: [0.3, 0.9, 0.3], dur: 2 + rem(index, 3), begin: delay)
  end

  defp get_smil_for_style(:lines, index) do
    delay = SMILAnimations.stagger_delay(index, 0.08)
    SMILAnimations.opacity(values: [0.2, 0.7, 0.2], dur: 3, begin: delay)
  end

  defp get_smil_for_style(:geometric, index) do
    delay = SMILAnimations.stagger_delay(index, 0.2)
    direction = if rem(index, 2) == 0, do: 360, else: -360
    SMILAnimations.rotate(dur: 15 + rem(index, 5), begin: delay, to: direction)
  end

  defp get_smil_for_style(:grid, index) do
    delay = SMILAnimations.stagger_delay(index, 0.1)

    SMILAnimations.pulse(
      dur: 4,
      begin: delay,
      scale_range: {0.95, 1.05},
      opacity_range: {0.3, 0.7}
    )
  end

  defp get_smil_for_style(:flow_field, index) do
    delay = SMILAnimations.stagger_delay(index, 0.05)
    SMILAnimations.stroke_dash(from: 200, to: 0, dur: 8 + rem(index, 4), begin: delay)
  end

  defp get_smil_for_style(:topology, index) do
    delay = SMILAnimations.stagger_delay(index, 0.2)
    SMILAnimations.stroke_dash(from: 500, to: 0, dur: 10, begin: delay)
  end

  defp get_smil_for_style(:voronoi, index) do
    delay = SMILAnimations.stagger_delay(index, 0.1)
    SMILAnimations.opacity(values: [0.3, 0.6, 0.3], dur: 5, begin: delay)
  end

  defp get_smil_for_style(:isometric, index) do
    delay = SMILAnimations.stagger_delay(index, 0.08)
    SMILAnimations.opacity(values: [0.4, 0.8, 0.4], dur: 4, begin: delay)
  end

  defp get_smil_for_style(:noise, index) do
    delay = SMILAnimations.stagger_delay(index, 0.02)
    SMILAnimations.opacity(values: [0.3, 0.9, 0.5, 0.8, 0.3], dur: 2, begin: delay)
  end

  defp get_smil_for_style(:glitch, index) do
    delay = SMILAnimations.stagger_delay(index, 0.05)

    SMILAnimations.transform(
      type: "translate",
      values: "0,0;-10,0;5,0;0,0",
      dur: 0.5 + rem(index, 3) * 0.2,
      begin: delay
    )
  end

  defp get_smil_for_style(:interference, index) do
    delay = SMILAnimations.stagger_delay(index, 0.1)

    SMILAnimations.pulse(
      dur: 6,
      begin: delay,
      scale_range: {0.99, 1.01},
      opacity_range: {0.3, 0.5}
    )
  end

  defp get_smil_for_style(:composite, index) do
    delay = SMILAnimations.stagger_delay(index, 0.1)
    SMILAnimations.opacity(values: [0.4, 0.7, 0.4], dur: 5, begin: delay)
  end

  defp get_smil_for_style(:constellation, index) do
    delay = SMILAnimations.stagger_delay(index, 0.08)

    SMILAnimations.pulse(
      dur: 4 + rem(index, 3),
      begin: delay,
      scale_range: {0.8, 1.2},
      opacity_range: {0.2, 0.9}
    )
  end

  defp get_smil_for_style(:aurora, index) do
    delay = SMILAnimations.stagger_delay(index, 0.15)

    SMILAnimations.transform(
      type: "translate",
      values: "0,0;0,-10;0,5;0,0",
      dur: 6 + rem(index, 4),
      begin: delay
    )
  end

  defp get_smil_for_style(_, _), do: nil
end
