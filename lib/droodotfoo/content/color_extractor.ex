defmodule Droodotfoo.Content.ColorExtractor do
  @moduledoc """
  Extracts color palettes from blog post metadata.

  Maps tags and content to accent colors while maintaining
  the monochrome aesthetic of the site.
  """

  @type palette :: %{bg: String.t(), colors: [String.t()]}

  # Tag to accent color mappings
  # Colors are muted to work with monochrome aesthetic
  @tag_colors %{
    # Languages
    "elixir" => "#9b59b6",
    "phoenix" => "#f47920",
    "erlang" => "#a90533",
    "rust" => "#dea584",
    "go" => "#00add8",
    "golang" => "#00add8",
    "python" => "#3776ab",
    "javascript" => "#f7df1e",
    "typescript" => "#3178c6",
    "ruby" => "#cc342d",
    "haskell" => "#5e5086",
    "gleam" => "#ffaff3",
    "lua" => "#000080",
    "zig" => "#f7a41d",

    # Web/frameworks
    "react" => "#61dafb",
    "vue" => "#42b883",
    "svelte" => "#ff3e00",
    "tailwind" => "#06b6d4",
    "css" => "#264de4",
    "html" => "#e34c26",

    # Blockchain/web3
    "ethereum" => "#627eea",
    "solidity" => "#363636",
    "blockchain" => "#f7931a",
    "web3" => "#627eea",
    "defi" => "#8b5cf6",
    "nft" => "#ff6b6b",

    # Infrastructure
    "docker" => "#2496ed",
    "kubernetes" => "#326ce5",
    "aws" => "#ff9900",
    "linux" => "#fcc624",
    "nix" => "#5277c3",
    "terraform" => "#7b42bc",

    # Concepts
    "security" => "#ef4444",
    "cryptography" => "#10b981",
    "performance" => "#f59e0b",
    "testing" => "#22c55e",
    "architecture" => "#6366f1",
    "functional" => "#8b5cf6",
    "systems" => "#64748b",
    "distributed" => "#0ea5e9",

    # Topics
    "ai" => "#10b981",
    "ml" => "#10b981",
    "database" => "#336791",
    "postgres" => "#336791",
    "redis" => "#dc382d",
    "api" => "#0ea5e9",
    "cli" => "#4ade80",
    "terminal" => "#22c55e",
    "vim" => "#019733",
    "neovim" => "#57a143",
    "emacs" => "#7f5ab6"
  }

  # Category accent colors for when no specific tag matches
  @category_colors %{
    programming: "#a855f7",
    infrastructure: "#0ea5e9",
    web: "#f97316",
    blockchain: "#627eea",
    design: "#ec4899",
    tutorial: "#22c55e",
    default: "#ffffff"
  }

  @doc """
  Extracts a color palette based on post tags.

  Returns a palette with the primary accent color derived from tags,
  maintaining the monochrome base aesthetic.

  ## Examples

      iex> ColorExtractor.palette_from_tags(["elixir", "phoenix"])
      %{bg: "#000000", colors: ["#9b59b6", "#ffffff", "#9b59b6"]}

      iex> ColorExtractor.palette_from_tags([])
      %{bg: "#000000", colors: ["#ffffff", "#ffffff", "#ffffff"]}
  """
  @spec palette_from_tags([String.t()]) :: palette
  def palette_from_tags(tags) when is_list(tags) do
    accent = extract_accent_color(tags)

    %{
      bg: "#000000",
      colors: [accent, "#ffffff", accent]
    }
  end

  @doc """
  Extracts a muted palette (lower saturation) for subtle accents.
  """
  @spec muted_palette_from_tags([String.t()]) :: palette
  def muted_palette_from_tags(tags) when is_list(tags) do
    accent = extract_accent_color(tags)
    muted = mute_color(accent, 0.4)

    %{
      bg: "#000000",
      colors: [muted, "#ffffff", muted]
    }
  end

  @doc """
  Extracts accent color from a list of tags.
  Returns the first matching tag's color, or white if no match.
  """
  @spec extract_accent_color([String.t()]) :: String.t()
  def extract_accent_color(tags) when is_list(tags) do
    tags
    |> Enum.map(&String.downcase/1)
    |> Enum.find_value(fn tag ->
      Map.get(@tag_colors, tag)
    end)
    |> case do
      nil -> infer_category_color(tags)
      color -> color
    end
  end

  @doc """
  Gets the color for a specific tag.
  """
  @spec color_for_tag(String.t()) :: String.t() | nil
  def color_for_tag(tag) when is_binary(tag) do
    Map.get(@tag_colors, String.downcase(tag))
  end

  @doc """
  Returns all known tag-to-color mappings.
  """
  @spec tag_colors :: %{String.t() => String.t()}
  def tag_colors, do: @tag_colors

  # Infer a category color based on tag patterns
  defp infer_category_color(tags) do
    downcased = Enum.map(tags, &String.downcase/1)

    cond do
      Enum.any?(downcased, &programming_tag?/1) -> @category_colors.programming
      Enum.any?(downcased, &infra_tag?/1) -> @category_colors.infrastructure
      Enum.any?(downcased, &web_tag?/1) -> @category_colors.web
      Enum.any?(downcased, &blockchain_tag?/1) -> @category_colors.blockchain
      Enum.any?(downcased, &design_tag?/1) -> @category_colors.design
      Enum.any?(downcased, &tutorial_tag?/1) -> @category_colors.tutorial
      true -> @category_colors.default
    end
  end

  defp programming_tag?(tag) do
    String.contains?(tag, "code") or
      String.contains?(tag, "programming") or
      String.contains?(tag, "lang")
  end

  defp infra_tag?(tag) do
    String.contains?(tag, "deploy") or
      String.contains?(tag, "server") or
      String.contains?(tag, "devops")
  end

  defp web_tag?(tag) do
    String.contains?(tag, "web") or
      String.contains?(tag, "frontend") or
      String.contains?(tag, "backend")
  end

  defp blockchain_tag?(tag) do
    String.contains?(tag, "crypto") or
      String.contains?(tag, "chain") or
      String.contains?(tag, "token")
  end

  defp design_tag?(tag) do
    String.contains?(tag, "design") or
      String.contains?(tag, "ui") or
      String.contains?(tag, "ux")
  end

  defp tutorial_tag?(tag) do
    String.contains?(tag, "tutorial") or
      String.contains?(tag, "guide") or
      String.contains?(tag, "howto")
  end

  # Mute a hex color by reducing saturation
  defp mute_color("#" <> hex, factor) when byte_size(hex) == 6 do
    {r, g, b} = parse_hex(hex)
    {h, s, l} = rgb_to_hsl(r, g, b)
    {r2, g2, b2} = hsl_to_rgb(h, s * factor, l)
    format_hex(r2, g2, b2)
  end

  defp mute_color(color, _factor), do: color

  defp parse_hex(<<r::binary-size(2), g::binary-size(2), b::binary-size(2)>>) do
    {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}
  end

  defp format_hex(r, g, b) do
    r_hex = Integer.to_string(round(r), 16) |> String.pad_leading(2, "0")
    g_hex = Integer.to_string(round(g), 16) |> String.pad_leading(2, "0")
    b_hex = Integer.to_string(round(b), 16) |> String.pad_leading(2, "0")
    "#" <> r_hex <> g_hex <> b_hex
  end

  # RGB to HSL conversion
  defp rgb_to_hsl(r, g, b) do
    r = r / 255
    g = g / 255
    b = b / 255

    max = Enum.max([r, g, b])
    min = Enum.min([r, g, b])
    l = (max + min) / 2

    if max == min do
      {0, 0, l}
    else
      d = max - min

      s =
        if l > 0.5 do
          d / (2 - max - min)
        else
          d / (max + min)
        end

      h =
        cond do
          max == r -> (g - b) / d + if(g < b, do: 6, else: 0)
          max == g -> (b - r) / d + 2
          true -> (r - g) / d + 4
        end

      {h / 6, s, l}
    end
  end

  # HSL to RGB conversion
  defp hsl_to_rgb(h, s, l) do
    if s == 0 do
      v = round(l * 255)
      {v, v, v}
    else
      q = if l < 0.5, do: l * (1 + s), else: l + s - l * s
      p = 2 * l - q

      r = hue_to_rgb(p, q, h + 1 / 3)
      g = hue_to_rgb(p, q, h)
      b = hue_to_rgb(p, q, h - 1 / 3)

      {round(r * 255), round(g * 255), round(b * 255)}
    end
  end

  defp hue_to_rgb(p, q, t) do
    t = if t < 0, do: t + 1, else: t
    t = if t > 1, do: t - 1, else: t

    cond do
      t < 1 / 6 -> p + (q - p) * 6 * t
      t < 1 / 2 -> q
      t < 2 / 3 -> p + (q - p) * (2 / 3 - t) * 6
      true -> p
    end
  end
end
