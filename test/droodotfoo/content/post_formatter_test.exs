defmodule Droodotfoo.Content.PostFormatterTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Content.PostFormatter
  alias Droodotfoo.Content.Posts.Post

  describe "format_header/1" do
    test "formats post header with all fields" do
      post = %Post{
        title: "test post",
        description: "A test post description",
        date: ~D[2025-10-19],
        read_time: 5,
        tags: ["elixir", "testing", "phoenix"]
      }

      result = PostFormatter.format_header(post)

      assert result.title == "TEST POST"
      assert result.description == "A test post description"

      assert result.metadata == [
               {"Published", "2025-10-19"},
               {"Reading", "5 min"},
               {"Tags", "elixir, testing, phoenix"}
             ]
    end

    test "uppercases title" do
      post = %Post{
        title: "lowercase title",
        description: "",
        date: ~D[2025-01-01],
        read_time: 1,
        tags: []
      }

      result = PostFormatter.format_header(post)
      assert result.title == "LOWERCASE TITLE"
    end

    test "handles title with mixed case" do
      post = %Post{
        title: "MiXeD CaSe TiTlE",
        description: "",
        date: ~D[2025-01-01],
        read_time: 1,
        tags: []
      }

      result = PostFormatter.format_header(post)
      assert result.title == "MIXED CASE TITLE"
    end

    test "formats metadata with date" do
      post = %Post{
        title: "Test",
        description: "",
        date: ~D[2025-10-19],
        read_time: 3,
        tags: []
      }

      result = PostFormatter.format_header(post)

      assert {"Published", "2025-10-19"} in result.metadata
      assert {"Reading", "3 min"} in result.metadata
    end

    test "includes reading time in metadata" do
      post = %Post{
        title: "Test",
        description: "",
        date: ~D[2025-01-01],
        read_time: 10,
        tags: []
      }

      result = PostFormatter.format_header(post)
      assert {"Reading", "10 min"} in result.metadata
    end

    test "includes tags in metadata when present" do
      post = %Post{
        title: "Test",
        description: "",
        date: ~D[2025-01-01],
        read_time: 1,
        tags: ["tag1", "tag2"]
      }

      result = PostFormatter.format_header(post)
      assert {"Tags", "tag1, tag2"} in result.metadata
    end

    test "excludes tags from metadata when empty" do
      post = %Post{
        title: "Test",
        description: "",
        date: ~D[2025-01-01],
        read_time: 1,
        tags: []
      }

      result = PostFormatter.format_header(post)

      # Tags should not be in metadata
      refute Enum.any?(result.metadata, fn {key, _} -> key == "Tags" end)
    end

    test "preserves description as-is" do
      post = %Post{
        title: "Test",
        description: "This is a Description with Mixed Case!",
        date: ~D[2025-01-01],
        read_time: 1,
        tags: []
      }

      result = PostFormatter.format_header(post)
      assert result.description == "This is a Description with Mixed Case!"
    end

    test "handles empty description" do
      post = %Post{
        title: "Test",
        description: "",
        date: ~D[2025-01-01],
        read_time: 1,
        tags: []
      }

      result = PostFormatter.format_header(post)
      assert result.description == ""
    end

    test "handles single tag" do
      post = %Post{
        title: "Test",
        description: "",
        date: ~D[2025-01-01],
        read_time: 1,
        tags: ["elixir"]
      }

      result = PostFormatter.format_header(post)
      assert {"Tags", "elixir"} in result.metadata
    end

    test "handles many tags" do
      post = %Post{
        title: "Test",
        description: "",
        date: ~D[2025-01-01],
        read_time: 1,
        tags: ["elixir", "phoenix", "liveview", "testing", "functional"]
      }

      result = PostFormatter.format_header(post)
      assert {"Tags", "elixir, phoenix, liveview, testing, functional"} in result.metadata
    end

    test "formats date correctly" do
      dates = [
        ~D[2025-01-01],
        ~D[2025-12-31],
        ~D[2024-06-15],
        ~D[2026-03-10]
      ]

      for date <- dates do
        post = %Post{
          title: "Test",
          description: "",
          date: date,
          read_time: 1,
          tags: []
        }

        result = PostFormatter.format_header(post)
        assert {"Published", Date.to_string(date)} in result.metadata
      end
    end

    test "handles zero read time" do
      post = %Post{
        title: "Test",
        description: "",
        date: ~D[2025-01-01],
        read_time: 0,
        tags: []
      }

      result = PostFormatter.format_header(post)
      assert {"Reading", "0 min"} in result.metadata
    end

    test "metadata is a list" do
      post = %Post{
        title: "Test",
        description: "",
        date: ~D[2025-01-01],
        read_time: 1,
        tags: []
      }

      result = PostFormatter.format_header(post)
      assert is_list(result.metadata)
    end

    test "metadata order is consistent" do
      post = %Post{
        title: "Test",
        description: "",
        date: ~D[2025-01-01],
        read_time: 5,
        tags: ["a", "b"]
      }

      result = PostFormatter.format_header(post)

      # Published should be first, Reading second, Tags third
      assert Enum.at(result.metadata, 0) == {"Published", "2025-01-01"}
      assert Enum.at(result.metadata, 1) == {"Reading", "5 min"}
      assert Enum.at(result.metadata, 2) == {"Tags", "a, b"}
    end
  end

  describe "back_link/1" do
    test "formats default back link" do
      assert PostFormatter.back_link() == "← Back to Home"
    end

    test "formats custom back link text" do
      assert PostFormatter.back_link("Return to Posts") == "← Return to Posts"
    end

    test "prepends arrow to text" do
      assert PostFormatter.back_link("Custom Text") == "← Custom Text"
    end

    test "handles empty string" do
      assert PostFormatter.back_link("") == "← "
    end

    test "handles special characters" do
      assert PostFormatter.back_link("Back & Forward") == "← Back & Forward"
    end

    test "handles unicode characters" do
      assert PostFormatter.back_link("Zurück zur Startseite") == "← Zurück zur Startseite"
    end

    test "does not add extra spaces" do
      result = PostFormatter.back_link("Test")
      assert result == "← Test"
      refute String.contains?(result, "  ")
    end
  end

  describe "format_tags/1" do
    test "returns empty string for empty list" do
      assert PostFormatter.format_tags([]) == ""
    end

    test "formats single tag" do
      assert PostFormatter.format_tags(["elixir"]) == "[elixir]"
    end

    test "formats two tags" do
      assert PostFormatter.format_tags(["elixir", "phoenix"]) == "[elixir] [phoenix]"
    end

    test "formats multiple tags" do
      result = PostFormatter.format_tags(["elixir", "phoenix", "liveview"])
      assert result == "[elixir] [phoenix] [liveview]"
    end

    test "preserves tag capitalization" do
      result = PostFormatter.format_tags(["Elixir", "Phoenix", "LiveView"])
      assert result == "[Elixir] [Phoenix] [LiveView]"
    end

    test "handles tags with spaces" do
      result = PostFormatter.format_tags(["web development", "functional programming"])
      assert result == "[web development] [functional programming]"
    end

    test "handles tags with special characters" do
      result = PostFormatter.format_tags(["c++", "f#", ".net"])
      assert result == "[c++] [f#] [.net]"
    end

    test "handles tags with numbers" do
      result = PostFormatter.format_tags(["elixir1.15", "phoenix1.7"])
      assert result == "[elixir1.15] [phoenix1.7]"
    end

    test "separates tags with space" do
      result = PostFormatter.format_tags(["a", "b", "c"])
      assert result == "[a] [b] [c]"
      # Count the number of spaces
      assert String.split(result, " ") |> length() == 3
    end

    test "handles single character tags" do
      result = PostFormatter.format_tags(["a", "b"])
      assert result == "[a] [b]"
    end

    test "handles long tag names" do
      long_tag = String.duplicate("a", 50)
      result = PostFormatter.format_tags([long_tag])
      assert result == "[#{long_tag}]"
    end

    test "handles many tags" do
      tags = for i <- 1..10, do: "tag#{i}"
      result = PostFormatter.format_tags(tags)

      # Should have all 10 tags
      for tag <- tags do
        assert String.contains?(result, "[#{tag}]")
      end
    end

    test "result is a string" do
      assert is_binary(PostFormatter.format_tags(["test"]))
      assert is_binary(PostFormatter.format_tags([]))
    end
  end
end
