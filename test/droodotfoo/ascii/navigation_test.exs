defmodule Droodotfoo.Ascii.NavigationTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Ascii.Navigation

  describe "section_indicator/2" do
    test "creates transition indicator between sections" do
      result = Navigation.section_indicator(:home, :projects)
      assert result == "> Home -> Projects"
    end

    test "uses section names from map" do
      result = Navigation.section_indicator(:terminal, :matrix)
      assert result == "> Terminal -> Matrix"
    end

    test "capitalizes unknown section names" do
      result = Navigation.section_indicator(:custom, :other)
      assert result == "> Custom -> Other"
    end
  end

  describe "breadcrumb/2" do
    test "creates breadcrumb with section name" do
      result = Navigation.breadcrumb(:projects)
      assert result =~ "Projects"
      assert String.starts_with?(result, "+-")
      assert String.ends_with?(result, "+")
    end

    test "respects width option" do
      result = Navigation.breadcrumb(:home, width: 40)
      # Content is padded based on width
      assert String.starts_with?(result, "+-")
      assert String.ends_with?(result, "+")
    end

    test "centers content" do
      result = Navigation.breadcrumb(:help)
      assert result =~ " > Help "
    end
  end

  describe "nav_hint/2" do
    test "creates hint bar with text" do
      result = Navigation.nav_hint("Press Enter to select")
      assert result =~ "Press Enter to select"
      assert String.starts_with?(result, "|")
      assert String.ends_with?(result, "|")
    end

    test "pads content to width" do
      result = Navigation.nav_hint("Short", width: 40)
      # Content is padded inside the | characters
      assert String.length(result) >= 40
    end

    test "includes navigation indicator" do
      result = Navigation.nav_hint("Test")
      assert result =~ " > "
    end
  end

  describe "format_section_name/1" do
    test "returns known section names" do
      assert Navigation.format_section_name(:home) == "Home"
      assert Navigation.format_section_name(:projects) == "Projects"
      assert Navigation.format_section_name(:skills) == "Skills"
      assert Navigation.format_section_name(:experience) == "Experience"
      assert Navigation.format_section_name(:contact) == "Contact"
    end

    test "capitalizes unknown section names" do
      assert Navigation.format_section_name(:unknown) == "Unknown"
      assert Navigation.format_section_name(:custom_section) == "Custom_section"
    end
  end
end
