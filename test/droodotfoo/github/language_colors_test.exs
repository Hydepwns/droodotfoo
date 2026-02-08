defmodule Droodotfoo.GitHub.LanguageColorsTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.GitHub.LanguageColors

  describe "get_color/1" do
    test "returns correct color for Elixir" do
      assert LanguageColors.get_color("Elixir") == "#6e4a7e"
    end

    test "returns correct color for JavaScript" do
      assert LanguageColors.get_color("JavaScript") == "#f1e05a"
    end

    test "returns correct color for TypeScript" do
      assert LanguageColors.get_color("TypeScript") == "#3178c6"
    end

    test "returns correct color for Python" do
      assert LanguageColors.get_color("Python") == "#3572A5"
    end

    test "returns correct color for Rust" do
      assert LanguageColors.get_color("Rust") == "#dea584"
    end

    test "returns correct color for Go" do
      assert LanguageColors.get_color("Go") == "#00ADD8"
    end

    test "returns correct color for Solidity" do
      assert LanguageColors.get_color("Solidity") == "#AA6746"
    end

    test "returns default gray for unknown language" do
      assert LanguageColors.get_color("Unknown") == "#858585"
      assert LanguageColors.get_color("COBOL") == "#858585"
    end

    test "returns default gray for non-string input" do
      assert LanguageColors.get_color(nil) == "#858585"
      assert LanguageColors.get_color(123) == "#858585"
      assert LanguageColors.get_color(:elixir) == "#858585"
    end

    test "is case-sensitive" do
      assert LanguageColors.get_color("elixir") == "#858585"
      assert LanguageColors.get_color("ELIXIR") == "#858585"
    end
  end
end
