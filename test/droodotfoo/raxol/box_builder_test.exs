defmodule Droodotfoo.Raxol.BoxBuilderTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.Raxol.{BoxBuilder, BoxConfig}

  describe "build/3" do
    test "builds a simple box with header and content" do
      result = BoxBuilder.build("Test", ["Line 1", "Line 2"])

      assert length(result) == 4
      assert Enum.at(result, 0) |> String.starts_with?("┌─ Test")
      assert Enum.at(result, 1) |> String.contains?("Line 1")
      assert Enum.at(result, 2) |> String.contains?("Line 2")
      assert Enum.at(result, 3) |> String.starts_with?("└")

      # All lines should be exactly 71 chars
      Enum.each(result, fn line ->
        assert String.length(line) == 71
      end)
    end

    test "builds box with rounded style" do
      result = BoxBuilder.build("Rounded", ["Content"], :rounded)

      assert Enum.at(result, 0) |> String.starts_with?("╭─ Rounded")
      assert Enum.at(result, 2) |> String.starts_with?("╰")
    end

    test "builds box with double style" do
      result = BoxBuilder.build("Double", ["Content"], :double)

      assert Enum.at(result, 0) |> String.starts_with?("╔═ Double")
      assert Enum.at(result, 2) |> String.starts_with?("╚")
    end

    test "handles empty content list" do
      result = BoxBuilder.build("Empty", [])

      assert length(result) == 2
      assert Enum.at(result, 0) |> String.starts_with?("┌─ Empty")
      assert Enum.at(result, 1) |> String.starts_with?("└")
    end

    test "truncates long content lines" do
      long_text = String.duplicate("x", 100)
      result = BoxBuilder.build("Test", [long_text])

      content_line = Enum.at(result, 1)
      assert String.length(content_line) == 71
      assert String.contains?(content_line, "...")
    end
  end

  describe "build_with_info/3" do
    test "builds box with info pairs" do
      result =
        BoxBuilder.build_with_info("Settings", [
          {"Theme", "Dark"},
          {"Font", "Monaspace"}
        ])

      assert length(result) == 4
      assert Enum.at(result, 0) |> String.starts_with?("┌─ Settings")

      content1 = Enum.at(result, 1)
      assert String.contains?(content1, "Theme:")
      assert String.contains?(content1, "Dark")

      content2 = Enum.at(result, 2)
      assert String.contains?(content2, "Font:")
      assert String.contains?(content2, "Monaspace")
    end

    test "respects custom label width" do
      result =
        BoxBuilder.build_with_info(
          "Test",
          [{"A", "B"}],
          label_width: 5
        )

      content = Enum.at(result, 1)
      # Label "A: " should be padded to 7 chars (5 + ": ")
      assert content |> String.contains?("A:   ")
    end

    test "respects custom separator" do
      result =
        BoxBuilder.build_with_info(
          "Test",
          [{"Name", "Value"}],
          separator: " = "
        )

      content = Enum.at(result, 1)
      assert String.contains?(content, "Name =")
      assert String.contains?(content, "Value")
    end

    test "handles empty info pairs" do
      result = BoxBuilder.build_with_info("Test", [])

      assert length(result) == 2
    end
  end

  describe "info_line/3" do
    test "creates info line with default settings" do
      result = BoxBuilder.info_line("Status", "Connected")

      assert String.starts_with?(result, "Status: ")
      assert String.contains?(result, "Connected")
    end

    test "pads label to specified width" do
      result = BoxBuilder.info_line("Port", "4000", label_width: 10)

      # "Port: " should be padded to 12 chars (10 + 2 for ": ")
      assert String.starts_with?(result, "Port:      ")
    end

    test "truncates long values" do
      long_value = String.duplicate("x", 100)
      result = BoxBuilder.info_line("Test", long_value)

      # Should not exceed inner_width - 2 - label_width - separator
      max_len = BoxConfig.inner_width() - 2 - 15 - 2
      value_part = String.slice(result, 17..-1//1)
      assert String.length(value_part) <= max_len
    end

    test "handles custom separator" do
      result = BoxBuilder.info_line("Key", "Value", separator: " -> ")

      assert String.contains?(result, "Key ->")
      assert String.contains?(result, "Value")
    end
  end

  describe "inner_box/3" do
    test "creates inner box with title and content" do
      result = BoxBuilder.inner_box("Status", ["All systems operational"])

      assert length(result) == 3
      assert Enum.at(result, 0) |> String.starts_with?("│  ┌─ Status")
      assert Enum.at(result, 1) |> String.contains?("All systems operational")
      assert Enum.at(result, 2) |> String.starts_with?("│  └")

      # All lines should be exactly 71 chars
      Enum.each(result, fn line ->
        assert String.length(line) == 71
      end)
    end

    test "creates inner box without title" do
      result = BoxBuilder.inner_box("", ["Content"])

      header = Enum.at(result, 0)
      assert String.starts_with?(header, "│  ┌")
      refute String.contains?(header, "─ ")
    end

    test "handles multiple content lines" do
      result = BoxBuilder.inner_box("Test", ["Line 1", "Line 2", "Line 3"])

      assert length(result) == 5
      assert Enum.at(result, 1) |> String.contains?("Line 1")
      assert Enum.at(result, 2) |> String.contains?("Line 2")
      assert Enum.at(result, 3) |> String.contains?("Line 3")
    end

    test "truncates long content lines" do
      long_text = String.duplicate("x", 100)
      result = BoxBuilder.inner_box("Test", [long_text])

      content_line = Enum.at(result, 1)
      assert String.length(content_line) == 71
      assert String.contains?(content_line, "...")
    end

    test "supports rounded style" do
      result = BoxBuilder.inner_box("Test", ["Content"], :rounded)

      assert Enum.at(result, 0) |> String.starts_with?("│  ╭")
      assert Enum.at(result, 2) |> String.starts_with?("│  ╰")
    end

    test "supports double style" do
      result = BoxBuilder.inner_box("Test", ["Content"], :double)

      assert Enum.at(result, 0) |> String.starts_with?("║  ╔")
      assert Enum.at(result, 2) |> String.starts_with?("║  ╚")
    end
  end

  describe "section/2" do
    test "creates section divider with title" do
      result = BoxBuilder.section("Settings")

      assert String.starts_with?(result, "├─ Settings")
      assert String.ends_with?(result, "┤")
      assert String.length(result) == 71
    end

    test "creates section with rounded style" do
      result = BoxBuilder.section("Test", :rounded)

      assert String.starts_with?(result, "├─ Test")
      assert String.ends_with?(result, "┤")
    end

    test "creates section with double style" do
      result = BoxBuilder.section("Test", :double)

      assert String.starts_with?(result, "├═ Test")
      assert String.ends_with?(result, "╣")
    end

    test "truncates very long section titles" do
      long_title = String.duplicate("x", 100)
      result = BoxBuilder.section(long_title)

      assert String.length(result) == 71
      assert String.contains?(result, "...")
    end

    test "handles empty title" do
      result = BoxBuilder.section("")

      assert String.starts_with?(result, "├─  ")
      assert String.length(result) == 71
    end
  end

  describe "empty_lines/1" do
    test "creates single empty line by default" do
      result = BoxBuilder.empty_lines()

      assert length(result) == 1
      assert Enum.at(result, 0) == BoxConfig.empty_line()
    end

    test "creates multiple empty lines" do
      result = BoxBuilder.empty_lines(3)

      assert length(result) == 3

      Enum.each(result, fn line ->
        assert line == BoxConfig.empty_line()
        assert String.length(line) == 71
      end)
    end
  end

  describe "build_with_sections/3" do
    test "builds box with multiple sections" do
      result =
        BoxBuilder.build_with_sections("Dashboard", [
          {"Status", ["All systems operational"]},
          {"Metrics", ["CPU: 45%", "Memory: 2.3GB"]}
        ])

      # Header + 2 sections (each with divider + content) + footer
      # = 1 + (1 + 1) + (1 + 2) + 1 = 7 lines
      assert length(result) == 7

      assert Enum.at(result, 0) |> String.starts_with?("┌─ Dashboard")
      assert Enum.at(result, 1) |> String.starts_with?("├─ Status")
      assert Enum.at(result, 2) |> String.contains?("All systems operational")
      assert Enum.at(result, 3) |> String.starts_with?("├─ Metrics")
      assert Enum.at(result, 4) |> String.contains?("CPU: 45%")
      assert Enum.at(result, 5) |> String.contains?("Memory: 2.3GB")
      assert Enum.at(result, 6) |> String.starts_with?("└")

      # All lines should be exactly 71 chars
      Enum.each(result, fn line ->
        assert String.length(line) == 71
      end)
    end

    test "handles empty sections" do
      result =
        BoxBuilder.build_with_sections("Test", [
          {"Empty Section", []}
        ])

      # Header + divider + footer = 3 lines
      assert length(result) == 3
    end

    test "supports different box styles" do
      result =
        BoxBuilder.build_with_sections(
          "Test",
          [{"Section", ["Content"]}],
          :rounded
        )

      assert Enum.at(result, 0) |> String.starts_with?("╭─ Test")
      assert Enum.at(result, 3) |> String.starts_with?("╰")
    end
  end

  describe "wrap_text/2" do
    test "wraps long text into multiple lines" do
      text = "This is a very long line that needs to be wrapped into multiple shorter lines"
      result = BoxBuilder.wrap_text(text, 20)

      assert length(result) > 1

      Enum.each(result, fn line ->
        assert String.length(line) <= 20
      end)
    end

    test "preserves short text as single line" do
      text = "Short text"
      result = BoxBuilder.wrap_text(text, 50)

      assert result == [text]
    end

    test "handles text with single very long word" do
      text = String.duplicate("x", 100)
      result = BoxBuilder.wrap_text(text, 20)

      # Single long word should still be on one line
      assert length(result) == 1
      assert Enum.at(result, 0) == text
    end

    test "uses default inner_width when max_width not specified" do
      text = String.duplicate("word ", 50)
      result = BoxBuilder.wrap_text(text)

      # Should wrap based on inner_width - 2
      max_width = BoxConfig.inner_width() - 2

      Enum.each(result, fn line ->
        assert String.length(line) <= max_width
      end)
    end

    test "handles empty text" do
      result = BoxBuilder.wrap_text("", 20)

      assert result == [""]
    end

    test "preserves words (doesn't break mid-word)" do
      text = "Hello world this is a test"
      result = BoxBuilder.wrap_text(text, 15)

      # Each line should contain complete words
      Enum.each(result, fn line ->
        # No partial words at start/end (except for very long words)
        words = String.split(line, " ")
        assert Enum.all?(words, &(String.length(&1) > 0))
      end)
    end
  end

  describe "integration tests" do
    test "build complex box with all features" do
      # Use multiple features together
      header = BoxBuilder.build("Settings", ["Welcome to settings"])

      info_box =
        BoxBuilder.build_with_info("User Profile", [
          {"Name", "Drew"},
          {"Email", "drew@axol.io"}
        ])

      sections_box =
        BoxBuilder.build_with_sections("Dashboard", [
          {"System", ["Status: OK"]},
          {"Metrics", ["CPU: 45%"]}
        ])

      # All boxes should have valid 71-char lines
      [header, info_box, sections_box]
      |> Enum.flat_map(& &1)
      |> Enum.each(fn line ->
        assert String.length(line) == 71
      end)
    end

    test "all box styles produce consistent widths" do
      for style <- [:sharp, :rounded, :double] do
        result = BoxBuilder.build("Test", ["Content"], style)

        Enum.each(result, fn line ->
          assert String.length(line) == 71,
                 "#{style} style should produce 71-char lines"
        end)
      end
    end
  end
end
