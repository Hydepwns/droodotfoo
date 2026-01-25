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
          :waves | :noise | :lines | :dots | :circuit | :glitch | :geometric | :grid
  @type generate_opts :: [
          width: pos_integer(),
          height: pos_integer(),
          style: pattern_style() | nil,
          animate: boolean()
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
         {:ok, animate} <- validate_boolean(Keyword.get(opts, :animate, false)) do
      {:ok, %{width: width, height: height, style: style, animate: animate}}
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

  # Generates SVG with validated options
  defp generate_svg_validated(slug, opts) do
    width = opts.width
    height = opts.height
    animate = opts.animate

    # Choose style based on slug if not specified
    style = opts.style || choose_style(slug)

    # Generate pattern using refactored modules
    # All patterns now use the new architecture and return complete SVG
    case style do
      :waves -> Patterns.Waves.generate_svg(slug, width, height, animate)
      :noise -> Patterns.Noise.generate_svg(slug, width, height, animate)
      :lines -> Patterns.Lines.generate_svg(slug, width, height, animate)
      :dots -> Patterns.Dots.generate_svg(slug, width, height, animate)
      :circuit -> Patterns.Circuit.generate_svg(slug, width, height, animate)
      :glitch -> Patterns.Glitch.generate_svg(slug, width, height, animate)
      :geometric -> Patterns.Geometric.generate_svg(slug, width, height, animate)
      :grid -> Patterns.Grid.generate_svg(slug, width, height, animate)
      _ -> Patterns.Waves.generate_svg(slug, width, height, animate)
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
    styles = [:waves, :noise, :lines, :dots, :circuit, :glitch, :geometric, :grid]
    hash = :erlang.phash2(slug)
    index = rem(hash, length(styles))
    Enum.at(styles, index)
  end
end
