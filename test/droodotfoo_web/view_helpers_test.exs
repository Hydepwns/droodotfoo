defmodule DroodotfooWeb.ViewHelpersTest do
  use ExUnit.Case, async: true

  alias DroodotfooWeb.ViewHelpers

  describe "format_date_range/2" do
    test "formats range with Present end date" do
      assert ViewHelpers.format_date_range("2020-01", "Present") == "2020-01 - Present"
    end

    test "formats range with specific end date" do
      assert ViewHelpers.format_date_range("2020-01", "2022-12") == "2020-01 - 2022-12"
    end

    test "handles same start and end date" do
      assert ViewHelpers.format_date_range("2023-06", "2023-06") == "2023-06 - 2023-06"
    end
  end

  describe "format_status/1" do
    test "formats active status" do
      assert ViewHelpers.format_status(:active) == "Active Development"
    end

    test "formats completed status" do
      assert ViewHelpers.format_status(:completed) == "Completed"
    end

    test "formats archived status" do
      assert ViewHelpers.format_status(:archived) == "Archived"
    end

    test "returns unknown for unrecognized status" do
      assert ViewHelpers.format_status(:unknown) == "Unknown Status"
      assert ViewHelpers.format_status(:pending) == "Unknown Status"
      assert ViewHelpers.format_status("active") == "Unknown Status"
    end
  end

  describe "extract_languages/1" do
    test "extracts languages from experience entries with atom keys" do
      experience = [
        %{technologies: %{languages: ["Elixir", "TypeScript"]}},
        %{technologies: %{languages: ["Elixir", "Rust"]}}
      ]

      result = ViewHelpers.extract_languages(experience)
      assert "Elixir" in result
      assert "TypeScript" in result
      assert "Rust" in result
      # Elixir appears twice, should be first
      assert hd(result) == "Elixir"
    end

    test "extracts languages from experience with string keys" do
      experience = [
        %{technologies: %{"languages" => ["Go", "Python"]}}
      ]

      result = ViewHelpers.extract_languages(experience)
      assert "Go" in result
      assert "Python" in result
    end

    test "returns empty list for experience without technologies" do
      experience = [%{company: "Acme", role: "Developer"}]
      assert ViewHelpers.extract_languages(experience) == []
    end

    test "returns empty list for non-list input" do
      assert ViewHelpers.extract_languages(nil) == []
      assert ViewHelpers.extract_languages(%{}) == []
    end

    test "handles mixed entries" do
      experience = [
        %{technologies: %{languages: ["Elixir"]}},
        %{company: "No tech field"},
        %{technologies: %{frameworks: ["Phoenix"]}}
      ]

      result = ViewHelpers.extract_languages(experience)
      assert result == ["Elixir"]
    end

    test "orders by frequency" do
      experience = [
        %{technologies: %{languages: ["Go", "Rust"]}},
        %{technologies: %{languages: ["Go", "Python"]}},
        %{technologies: %{languages: ["Go"]}}
      ]

      result = ViewHelpers.extract_languages(experience)
      # Go appears 3 times, should be first
      assert hd(result) == "Go"
    end
  end
end
