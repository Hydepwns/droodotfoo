defmodule Droodotfoo.Content.PatternConfig do
  @moduledoc """
  Centralized configuration for pattern generation.
  All pattern parameters, defaults, and ranges are defined here.
  """

  @type range :: %{min: number, max: number}
  @type pattern_config :: %{
          optional(atom) => range | number | any
        }

  @doc """
  Returns configuration for waves pattern.
  """
  @spec waves_config :: pattern_config
  def waves_config do
    %{
      wave_count: %{min: 15, max: 40},
      amplitude: %{min: 30, max: 110},
      frequency: %{min: 0.003, max: 0.018},
      opacity: %{min: 0.1, max: 0.5},
      stroke_width: 2,
      point_spacing: 10
    }
  end

  @doc """
  Returns configuration for noise pattern.
  """
  @spec noise_config :: pattern_config
  def noise_config do
    %{
      cell_size: %{min: 5, max: 13},
      brightness_threshold: 0.5
    }
  end

  @doc """
  Returns configuration for dots pattern.
  """
  @spec dots_config :: pattern_config
  def dots_config do
    %{
      spacing: %{min: 15, max: 30},
      center_offset: %{min: 0.3, max: 0.7},
      size_randomness: %{min: 0.3, max: 1.0},
      opacity: 0.8
    }
  end

  @doc """
  Returns configuration for lines pattern.
  """
  @spec lines_config :: pattern_config
  def lines_config do
    %{
      parallel: %{
        count: 40,
        thickness: %{min: 1, max: 4},
        opacity: %{min: 0.2, max: 0.6}
      },
      radial: %{
        count: 60,
        thickness: %{min: 0.5, max: 2.5},
        opacity: %{min: 0.1, max: 0.4}
      }
    }
  end

  @doc """
  Returns configuration for circuit pattern.
  """
  @spec circuit_config :: pattern_config
  def circuit_config do
    %{
      trace_count: %{min: 30, max: 70},
      segments: %{min: 3, max: 8},
      segment_length: %{min: 50, max: 200},
      thickness: %{min: 1, max: 4},
      opacity: %{min: 0.2, max: 0.5}
    }
  end

  @doc """
  Returns configuration for glitch pattern.
  """
  @spec glitch_config :: pattern_config
  def glitch_config do
    %{
      bar_count: %{min: 20, max: 45},
      bar_width: %{min: 80, max: 480},
      bar_height: %{min: 3, max: 23},
      opacity: %{min: 0.15, max: 0.65},
      offset_chance: 0.4,
      offset_range: %{min: -15, max: 30},
      scanline_count: 10
    }
  end

  @doc """
  Returns configuration for geometric pattern.
  """
  @spec geometric_config :: pattern_config
  def geometric_config do
    %{
      shape_count: %{min: 12, max: 28},
      size: %{min: 40, max: 220},
      opacity: %{min: 0.15, max: 0.55},
      stroke_width: 2,
      shapes: [:circle, :rect, :triangle]
    }
  end

  @doc """
  Returns configuration for grid pattern.
  """
  @spec grid_config :: pattern_config
  def grid_config do
    %{
      cell_size: %{min: 25, max: 55},
      wave_frequency: %{min: 2, max: 7},
      opacity: %{min: 0.2, max: 0.7}
    }
  end

  @doc """
  Returns configuration for flow field pattern.
  """
  @spec flow_field_config :: pattern_config
  def flow_field_config do
    %{
      particle_count: %{min: 80, max: 200},
      steps: %{min: 30, max: 100},
      step_length: 4,
      stroke_width: %{min: 0.5, max: 2.5},
      opacity: %{min: 0.15, max: 0.6}
    }
  end

  @doc """
  Returns configuration for interference pattern.
  """
  @spec interference_config :: pattern_config
  def interference_config do
    %{
      # Concentric circles
      center_count: %{min: 2, max: 4},
      ring_spacing: %{min: 8, max: 20},
      # Wave interference
      wave_sources: %{min: 2, max: 5},
      wave_frequency: %{min: 0.02, max: 0.08},
      # Grid interference
      grid_count: %{min: 2, max: 3},
      grid_spacing: %{min: 6, max: 15},
      # Common
      stroke_width: %{min: 0.3, max: 1.0},
      opacity: %{min: 0.2, max: 0.5}
    }
  end

  @doc """
  Returns configuration for topology (contour lines) pattern.
  """
  @spec topology_config :: pattern_config
  def topology_config do
    %{
      contour_count: %{min: 8, max: 20},
      noise_scale: %{min: 0.003, max: 0.008},
      octaves: %{min: 2, max: 4},
      stroke_width: %{min: 0.5, max: 1.5},
      opacity: %{min: 0.3, max: 0.7}
    }
  end

  @doc """
  Returns configuration for Voronoi tessellation pattern.
  """
  @spec voronoi_config :: pattern_config
  def voronoi_config do
    %{
      cell_count: %{min: 20, max: 60},
      stroke_width: %{min: 0.5, max: 2.0},
      opacity: %{min: 0.3, max: 0.6},
      show_points_chance: 0.3
    }
  end

  @doc """
  Returns configuration for isometric 3D grid pattern.
  """
  @spec isometric_config :: pattern_config
  def isometric_config do
    %{
      cube_size: %{min: 30, max: 60},
      show_probability: %{min: 0.4, max: 0.8},
      height_variation: %{min: 0.2, max: 1.0},
      stroke_width: %{min: 0.5, max: 1.5},
      opacity: %{min: 0.3, max: 0.6}
    }
  end

  @doc """
  Returns configuration for composite layered pattern.
  """
  @spec composite_config :: pattern_config
  def composite_config do
    %{
      layer_count: %{min: 2, max: 3}
    }
  end

  @doc """
  Returns default SVG dimensions.
  """
  @spec default_dimensions :: %{width: pos_integer, height: pos_integer}
  def default_dimensions do
    %{
      width: 1200,
      height: 630
    }
  end

  @doc """
  Returns all available pattern styles.
  """
  @spec available_styles :: [atom]
  def available_styles do
    [
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
      :composite
    ]
  end

  @doc """
  Gets configuration for a specific pattern style.
  Returns `{:ok, config}` or `{:error, :unknown_style}`.
  """
  @spec get_config(atom) :: {:ok, pattern_config} | {:error, :unknown_style}
  def get_config(:waves), do: {:ok, waves_config()}
  def get_config(:noise), do: {:ok, noise_config()}
  def get_config(:dots), do: {:ok, dots_config()}
  def get_config(:lines), do: {:ok, lines_config()}
  def get_config(:circuit), do: {:ok, circuit_config()}
  def get_config(:glitch), do: {:ok, glitch_config()}
  def get_config(:geometric), do: {:ok, geometric_config()}
  def get_config(:grid), do: {:ok, grid_config()}
  def get_config(:flow_field), do: {:ok, flow_field_config()}
  def get_config(:interference), do: {:ok, interference_config()}
  def get_config(:topology), do: {:ok, topology_config()}
  def get_config(:voronoi), do: {:ok, voronoi_config()}
  def get_config(:isometric), do: {:ok, isometric_config()}
  def get_config(:composite), do: {:ok, composite_config()}
  def get_config(_), do: {:error, :unknown_style}

  @doc """
  Validates if a style is supported.
  """
  @spec valid_style?(atom) :: boolean
  def valid_style?(style) do
    style in available_styles()
  end

  @doc """
  Returns all available color palettes.
  Refined monochrome aesthetic with minimal grey tones.
  Uses pure black/white with opacity for variation.
  """
  @spec color_palettes :: %{atom => %{bg: String.t(), colors: [String.t()]}}
  def color_palettes do
    %{
      # Pure monochrome - black background, white elements
      pure_mono: %{
        bg: "#000000",
        colors: ["#ffffff", "#ffffff", "#ffffff"]
      },

      # Inverted monochrome - dark background, bright white elements
      mono_bright: %{
        bg: "#0a0a0a",
        colors: ["#ffffff", "#e6e6e6", "#ffffff"]
      },

      # Single accent grey - mostly white with one mid-tone
      mono_accent: %{
        bg: "#000000",
        colors: ["#ffffff", "#808080", "#ffffff"]
      }
    }
  end

  @doc """
  Gets a specific color palette by name.
  Returns `{:ok, palette}` or `{:error, :unknown_palette}`.
  """
  @spec get_palette(atom) ::
          {:ok, %{bg: String.t(), colors: [String.t()]}} | {:error, :unknown_palette}
  def get_palette(name) when is_atom(name) do
    palettes = color_palettes()

    case Map.get(palettes, name) do
      nil -> {:error, :unknown_palette}
      palette -> {:ok, palette}
    end
  end

  @doc """
  Chooses a color palette deterministically based on a seed.
  """
  @spec choose_palette(String.t() | integer) :: {atom, %{bg: String.t(), colors: [String.t()]}}
  def choose_palette(seed) when is_binary(seed) do
    choose_palette(:erlang.phash2(seed))
  end

  def choose_palette(seed) when is_integer(seed) do
    palettes = color_palettes()
    palette_names = Map.keys(palettes) |> Enum.sort()
    index = rem(seed, length(palette_names))
    name = Enum.at(palette_names, index)
    {name, Map.get(palettes, name)}
  end

  @doc """
  Chooses a color palette based on slug and style combination.
  This gives different palettes for the same slug depending on pattern style.
  """
  @spec choose_palette_for_style(String.t(), atom) ::
          {atom, %{bg: String.t(), colors: [String.t()]}}
  def choose_palette_for_style(slug, style) when is_binary(slug) and is_atom(style) do
    # Combine slug and style for seed
    combined_seed = "#{slug}-#{style}"
    choose_palette(combined_seed)
  end

  @doc """
  Chooses a color palette based on post tags.
  Falls back to standard palette selection if no tags match.
  """
  @spec choose_palette_for_tags([String.t()], String.t()) ::
          {atom, %{bg: String.t(), colors: [String.t()]}}
  def choose_palette_for_tags(tags, slug) when is_list(tags) and is_binary(slug) do
    alias Droodotfoo.Content.ColorExtractor

    case ColorExtractor.extract_accent_color(tags) do
      "#ffffff" ->
        # No tag match, use standard palette
        choose_palette(slug)

      _accent ->
        # Use tag-based palette
        {:tag_based, ColorExtractor.palette_from_tags(tags)}
    end
  end

  @doc """
  Chooses a muted palette based on post tags.
  Good for backgrounds where accent should be subtle.
  """
  @spec choose_muted_palette_for_tags([String.t()]) ::
          {atom, %{bg: String.t(), colors: [String.t()]}}
  def choose_muted_palette_for_tags(tags) when is_list(tags) do
    alias Droodotfoo.Content.ColorExtractor
    {:tag_based_muted, ColorExtractor.muted_palette_from_tags(tags)}
  end
end
