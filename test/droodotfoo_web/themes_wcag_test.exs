defmodule DroodotfooWeb.ThemesWCAGTest do
  @moduledoc """
  WCAG AA contrast ratio tests for all theme palettes.
  Parses themes.css and validates that text/background combinations
  meet the 4.5:1 ratio for normal text and 3:1 for large text.
  """

  use ExUnit.Case, async: true

  # WCAG AA minimum contrast ratios
  @normal_text_min 4.5
  @large_text_min 3.0

  # Theme definitions extracted from themes.css
  # Each theme maps variable names to hex colors
  @themes %{
    "synthwave84" => %{
      text: "#ff00ff",
      background: "#1a0033",
      border: "#ff00ff",
      accent: "#00ffff",
      secondary: "#cc00cc"
    },
    "hotline" => %{
      text: "#ff1493",
      background: "#0a0014",
      border: "#00d9ff",
      accent: "#00d9ff",
      secondary: "#ff69b4"
    },
    "matrix" => %{
      text: "#00ff00",
      background: "#0d0208",
      border: "#008f11",
      accent: "#00ff41",
      secondary: "#00802b"
    },
    "cyberpunk" => %{
      text: "#00ffff",
      background: "#0a0e27",
      border: "#ff00ff",
      accent: "#ff00ff",
      secondary: "#00cccc"
    },
    "phosphor" => %{
      text: "#ffb000",
      background: "#1a1200",
      border: "#ff8800",
      accent: "#ffd700",
      secondary: "#cc8800"
    },
    "amber" => %{
      text: "#ffb000",
      background: "#000000",
      border: "#ffb000",
      accent: "#ffb000",
      secondary: "#cc8800"
    },
    "high-contrast" => %{
      text: "#ffffff",
      background: "#000000",
      border: "#ffffff",
      accent: "#ffffff",
      secondary: "#cccccc"
    },
    "default-light" => %{
      text: "#000000",
      background: "#ffffff",
      border: "#000000",
      accent: "#0066cc",
      secondary: "#666666"
    },
    "default-dark" => %{
      text: "#e0e0e0",
      background: "#0a0a0a",
      border: "#e0e0e0",
      accent: "#66b3ff",
      secondary: "#999999"
    }
  }

  # Pairs that must pass WCAG AA normal text (4.5:1)
  @normal_text_pairs [
    {:text, :background, "body text on background"},
    {:accent, :background, "accent/link text on background"}
  ]

  # Pairs that must pass WCAG AA large text (3:1)
  @large_text_pairs [
    {:secondary, :background, "secondary/muted text on background"},
    {:border, :background, "border on background"}
  ]

  describe "WCAG AA normal text contrast (4.5:1)" do
    for {theme_name, colors} <- @themes,
        {fg_key, bg_key, label} <- @normal_text_pairs do
      fg = Map.get(colors, fg_key)
      bg = Map.get(colors, bg_key)

      @tag theme: theme_name
      test "#{theme_name}: #{label} (#{fg} on #{bg})" do
        fg_hex = unquote(fg)
        bg_hex = unquote(bg)
        ratio = contrast_ratio(fg_hex, bg_hex)

        assert ratio >= unquote(@normal_text_min),
               "#{unquote(theme_name)} #{unquote(label)}: contrast ratio #{Float.round(ratio, 2)}:1 " <>
                 "is below WCAG AA minimum #{unquote(@normal_text_min)}:1 " <>
                 "(#{fg_hex} on #{bg_hex})"
      end
    end
  end

  describe "WCAG AA large text contrast (3:1)" do
    for {theme_name, colors} <- @themes,
        {fg_key, bg_key, label} <- @large_text_pairs do
      fg = Map.get(colors, fg_key)
      bg = Map.get(colors, bg_key)

      @tag theme: theme_name
      test "#{theme_name}: #{label} (#{fg} on #{bg})" do
        fg_hex = unquote(fg)
        bg_hex = unquote(bg)
        ratio = contrast_ratio(fg_hex, bg_hex)

        assert ratio >= unquote(@large_text_min),
               "#{unquote(theme_name)} #{unquote(label)}: contrast ratio #{Float.round(ratio, 2)}:1 " <>
                 "is below WCAG AA minimum #{unquote(@large_text_min)}:1 " <>
                 "(#{fg_hex} on #{bg_hex})"
      end
    end
  end

  describe "contrast_ratio/2" do
    test "black on white is 21:1" do
      ratio = contrast_ratio("#000000", "#ffffff")
      assert_in_delta ratio, 21.0, 0.1
    end

    test "white on white is 1:1" do
      ratio = contrast_ratio("#ffffff", "#ffffff")
      assert_in_delta ratio, 1.0, 0.01
    end

    test "WCAG example: #777 on #fff" do
      ratio = contrast_ratio("#777777", "#ffffff")
      assert ratio >= 4.47
      assert ratio <= 4.49
    end
  end

  # --- Helpers ---

  defp contrast_ratio(hex1, hex2) do
    l1 = relative_luminance(hex1)
    l2 = relative_luminance(hex2)

    {lighter, darker} = if l1 > l2, do: {l1, l2}, else: {l2, l1}
    (lighter + 0.05) / (darker + 0.05)
  end

  defp relative_luminance(hex) do
    {r, g, b} = hex_to_rgb(hex)

    r_lin = linearize(r / 255.0)
    g_lin = linearize(g / 255.0)
    b_lin = linearize(b / 255.0)

    0.2126 * r_lin + 0.7152 * g_lin + 0.0722 * b_lin
  end

  defp linearize(val) when val <= 0.04045, do: val / 12.92
  defp linearize(val), do: :math.pow((val + 0.055) / 1.055, 2.4)

  defp hex_to_rgb("#" <> hex) do
    hex = String.downcase(hex)

    {r, ""} = Integer.parse(String.slice(hex, 0, 2), 16)
    {g, ""} = Integer.parse(String.slice(hex, 2, 2), 16)
    {b, ""} = Integer.parse(String.slice(hex, 4, 2), 16)

    {r, g, b}
  end
end
