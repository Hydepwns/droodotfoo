defmodule Droodotfoo.Raxol.BoxConfigTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.Raxol.BoxConfig

  describe "dimension constants" do
    test "terminal_width/0 returns 106" do
      assert BoxConfig.terminal_width() == 106
    end

    test "nav_width/0 returns 35" do
      assert BoxConfig.nav_width() == 35
    end

    test "content_width/0 returns 71" do
      assert BoxConfig.content_width() == 71
    end

    test "inner_width/0 returns 67" do
      assert BoxConfig.inner_width() == 67
    end

    test "dimensions are consistent" do
      assert BoxConfig.terminal_width() == BoxConfig.nav_width() + BoxConfig.content_width()
      assert BoxConfig.content_width() == BoxConfig.inner_width() + 4
    end
  end

  describe "box_chars/1" do
    test "returns sharp style by default" do
      chars = BoxConfig.box_chars()
      assert chars.top_left == "┌"
      assert chars.top_right == "┐"
      assert chars.bottom_left == "└"
      assert chars.bottom_right == "┘"
      assert chars.horizontal == "─"
      assert chars.vertical == "│"
    end

    test "returns sharp style when explicitly requested" do
      chars = BoxConfig.box_chars(:sharp)
      assert chars.top_left == "┌"
      assert chars.vertical == "│"
    end

    test "returns rounded style" do
      chars = BoxConfig.box_chars(:rounded)
      assert chars.top_left == "╭"
      assert chars.top_right == "╮"
      assert chars.bottom_left == "╰"
      assert chars.bottom_right == "╯"
      assert chars.horizontal == "─"
      assert chars.vertical == "│"
    end

    test "returns double style" do
      chars = BoxConfig.box_chars(:double)
      assert chars.top_left == "╔"
      assert chars.top_right == "╗"
      assert chars.bottom_left == "╚"
      assert chars.bottom_right == "╝"
      assert chars.horizontal == "═"
      assert chars.vertical == "║"
    end
  end

  describe "box_line/2" do
    test "creates a box line with default style" do
      result = BoxConfig.box_line("Hello")
      assert String.starts_with?(result, "│")
      assert String.ends_with?(result, "│")
      assert String.length(result) == 71
      assert String.contains?(result, "Hello")
    end

    test "creates a box line with rounded style" do
      result = BoxConfig.box_line("Test", :rounded)
      assert String.starts_with?(result, "│")
      assert String.ends_with?(result, "│")
      assert String.length(result) == 71
    end

    test "creates a box line with double style" do
      result = BoxConfig.box_line("Test", :double)
      assert String.starts_with?(result, "║")
      assert String.ends_with?(result, "║")
      assert String.length(result) == 71
    end

    test "box line handles empty string" do
      result = BoxConfig.box_line("")
      assert String.length(result) == 71
      assert String.starts_with?(result, "│  ")
      assert String.ends_with?(result, "│")
    end
  end

  describe "padded_line/2" do
    test "pads short text to inner_width by default" do
      result = BoxConfig.padded_line("Hello")
      assert String.length(result) == 67
      assert String.starts_with?(result, "  Hello")
      assert String.ends_with?(result, " ")
    end

    test "pads text to custom width" do
      result = BoxConfig.padded_line("Test", 20)
      assert String.length(result) == 20
      assert String.starts_with?(result, "  Test")
    end

    test "truncates text that exceeds width" do
      long_text = String.duplicate("x", 100)
      result = BoxConfig.padded_line(long_text, 20)
      assert String.length(result) == 20
      assert String.ends_with?(result, "...")
    end

    test "handles empty string" do
      result = BoxConfig.padded_line("")
      assert String.length(result) == 67
      assert String.starts_with?(result, "  ")
    end
  end

  describe "header_line/2" do
    test "creates header with title using sharp style" do
      result = BoxConfig.header_line("Spotify")
      assert String.starts_with?(result, "┌─ Spotify ")
      assert String.ends_with?(result, "┐")
      assert String.length(result) == 71
      assert String.contains?(result, "─")
    end

    test "creates header with rounded style" do
      result = BoxConfig.header_line("Settings", :rounded)
      assert String.starts_with?(result, "╭─ Settings ")
      assert String.ends_with?(result, "╮")
      assert String.length(result) == 71
    end

    test "creates header with double style" do
      result = BoxConfig.header_line("Web3", :double)
      assert String.starts_with?(result, "╔═ Web3 ")
      assert String.ends_with?(result, "╗")
      assert String.length(result) == 71
      assert String.contains?(result, "═")
    end

    test "handles empty title" do
      result = BoxConfig.header_line("")
      assert String.length(result) == 71
      assert String.starts_with?(result, "┌─  ")
    end

    test "handles very long title" do
      long_title = String.duplicate("x", 100)
      result = BoxConfig.header_line(long_title)
      assert String.length(result) == 71
      assert String.starts_with?(result, "┌─")
      assert String.ends_with?(result, "┐")
    end
  end

  describe "footer_line/1" do
    test "creates footer with sharp style" do
      result = BoxConfig.footer_line()
      assert String.starts_with?(result, "└")
      assert String.ends_with?(result, "┘")
      assert String.length(result) == 71
      assert String.contains?(result, "─")
    end

    test "creates footer with rounded style" do
      result = BoxConfig.footer_line(:rounded)
      assert String.starts_with?(result, "╰")
      assert String.ends_with?(result, "╯")
      assert String.length(result) == 71
    end

    test "creates footer with double style" do
      result = BoxConfig.footer_line(:double)
      assert String.starts_with?(result, "╚")
      assert String.ends_with?(result, "╝")
      assert String.length(result) == 71
      assert String.contains?(result, "═")
    end
  end

  describe "empty_line/0" do
    test "creates empty line with correct width" do
      result = BoxConfig.empty_line()
      assert String.length(result) == 71
      assert String.starts_with?(result, "│")
      assert String.ends_with?(result, "│")
    end

    test "empty line contains only spaces between borders" do
      result = BoxConfig.empty_line()
      # Extract content between borders (skip first and last char)
      content = String.slice(result, 1..-2//1)
      assert String.trim(content) == ""
      assert String.length(content) == 69
    end
  end

  describe "truncate_and_pad/2" do
    test "pads short text to specified width" do
      result = BoxConfig.truncate_and_pad("Hello", 10)
      assert result == "Hello     "
      assert String.length(result) == 10
    end

    test "truncates long text and pads to width" do
      long_text = "This is a very long string that needs truncation"
      result = BoxConfig.truncate_and_pad(long_text, 10)
      assert String.length(result) == 10
      assert String.ends_with?(result, "...")
    end

    test "handles exact width match" do
      result = BoxConfig.truncate_and_pad("12345", 5)
      assert result == "12345"
      assert String.length(result) == 5
    end

    test "handles empty string" do
      result = BoxConfig.truncate_and_pad("", 10)
      assert String.length(result) == 10
      assert String.trim(result) == ""
    end

    test "handles width smaller than ellipsis" do
      result = BoxConfig.truncate_and_pad("Hello", 2)
      assert String.length(result) == 2
    end
  end

  describe "truncate_text/2" do
    test "returns text unchanged if shorter than max_width" do
      assert BoxConfig.truncate_text("Hello", 10) == "Hello"
      assert BoxConfig.truncate_text("Test", 20) == "Test"
    end

    test "returns text unchanged if equal to max_width" do
      assert BoxConfig.truncate_text("12345", 5) == "12345"
    end

    test "truncates text longer than max_width with ellipsis" do
      result = BoxConfig.truncate_text("Hello World", 8)
      # 8 chars total = 5 chars of text + 3 chars for "..."
      assert result == "Hello..."
      assert String.length(result) == 8
    end

    test "handles very long text" do
      long_text = String.duplicate("x", 100)
      result = BoxConfig.truncate_text(long_text, 20)
      assert String.length(result) == 20
      assert String.ends_with?(result, "...")
    end

    test "handles max_width smaller than ellipsis" do
      result = BoxConfig.truncate_text("Hello", 2)
      assert String.length(result) <= 2
    end

    test "handles empty string" do
      assert BoxConfig.truncate_text("", 10) == ""
    end
  end

  describe "inner box helpers" do
    test "inner_box_header/1 creates proper header" do
      result = BoxConfig.inner_box_header()
      assert String.starts_with?(result, "│  ┌")
      assert String.ends_with?(result, "┐  │")
      assert String.length(result) == 71
    end

    test "inner_box_header/1 with rounded style" do
      result = BoxConfig.inner_box_header(:rounded)
      assert String.starts_with?(result, "│  ╭")
      assert String.ends_with?(result, "╮  │")
      assert String.length(result) == 71
    end

    test "inner_box_footer/1 creates proper footer" do
      result = BoxConfig.inner_box_footer()
      assert String.starts_with?(result, "│  └")
      assert String.ends_with?(result, "┘  │")
      assert String.length(result) == 71
    end

    test "inner_box_line/2 creates content line" do
      result = BoxConfig.inner_box_line("Status: OK")
      assert String.starts_with?(result, "│  │")
      assert String.ends_with?(result, "│  │")
      assert String.length(result) == 71
      assert String.contains?(result, "Status: OK")
    end

    test "inner_box_line/2 truncates long text" do
      long_text = String.duplicate("x", 100)
      result = BoxConfig.inner_box_line(long_text)
      assert String.length(result) == 71
      assert String.ends_with?(result, "│  │")
    end
  end

  describe "integration tests" do
    test "can build a complete box structure" do
      header = BoxConfig.header_line("Test Box")
      empty = BoxConfig.empty_line()
      content = BoxConfig.box_line("Content line")
      footer = BoxConfig.footer_line()

      # All lines should be exactly 71 chars
      assert String.length(header) == 71
      assert String.length(empty) == 71
      assert String.length(content) == 71
      assert String.length(footer) == 71

      # Should form a valid box
      assert String.starts_with?(header, "┌")
      assert String.ends_with?(header, "┐")
      assert String.starts_with?(footer, "└")
      assert String.ends_with?(footer, "┘")
    end

    test "all box styles produce consistent widths" do
      for style <- [:sharp, :rounded, :double] do
        header = BoxConfig.header_line("Title", style)
        footer = BoxConfig.footer_line(style)

        assert String.length(header) == 71,
               "#{style} header should be 71 chars"

        assert String.length(footer) == 71,
               "#{style} footer should be 71 chars"
      end
    end
  end
end
