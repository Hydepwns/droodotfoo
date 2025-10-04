defmodule Droodotfoo.Plugins.GameUITest do
  use ExUnit.Case, async: true
  alias Droodotfoo.Plugins.GameUI

  describe "border functions" do
    test "top_border/1 creates correct border with default width" do
      result = GameUI.top_border()
      assert String.starts_with?(result, "╔")
      assert String.ends_with?(result, "╗")
      assert String.length(result) == 64
    end

    test "top_border/1 creates correct border with custom width" do
      result = GameUI.top_border(20)
      assert String.starts_with?(result, "╔")
      assert String.ends_with?(result, "╗")
      assert String.length(result) == 20
    end

    test "bottom_border/1 creates correct border" do
      result = GameUI.bottom_border(20)
      assert String.starts_with?(result, "╚")
      assert String.ends_with?(result, "╝")
      assert String.length(result) == 20
    end

    test "divider/1 creates correct divider" do
      result = GameUI.divider(20)
      assert String.starts_with?(result, "╠")
      assert String.ends_with?(result, "╣")
      assert String.length(result) == 20
    end
  end

  describe "title_line/2" do
    test "creates title line with default width" do
      result = GameUI.title_line("TETRIS")
      assert String.starts_with?(result, "║ ")
      assert String.ends_with?(result, " ║")
      assert String.contains?(result, "TETRIS")
    end

    test "creates title line with custom width" do
      result = GameUI.title_line("TEST", 20)
      assert String.length(result) == 20
      assert String.contains?(result, "TEST")
    end

    test "pads title text correctly" do
      result = GameUI.title_line("HI", 20)
      # Should be: "║ HI               ║"
      assert String.length(result) == 20
      assert String.starts_with?(result, "║ HI")
    end
  end

  describe "content_line/3" do
    test "creates content line with default settings" do
      result = GameUI.content_line("Score: 100")
      assert String.starts_with?(result, "║ ")
      assert String.ends_with?(result, "║")
      assert String.contains?(result, "Score: 100")
    end

    test "creates content line with custom width" do
      result = GameUI.content_line("Test", 20)
      assert String.length(result) == 20
    end

    test "creates content line with custom left padding" do
      result = GameUI.content_line("Test", 20, 2)
      assert String.contains?(result, "  Test")
    end
  end

  describe "empty_line/1" do
    test "creates empty line with default width" do
      result = GameUI.empty_line()
      assert result == "║ " <> String.duplicate(" ", 60) <> " ║"
    end

    test "creates empty line with custom width" do
      result = GameUI.empty_line(20)
      assert String.length(result) == 20
      assert result == "║ " <> String.duplicate(" ", 16) <> " ║"
    end
  end

  describe "format_status/1" do
    test "formats playing status" do
      assert GameUI.format_status(:playing) == "PLAYING"
    end

    test "formats paused status" do
      assert GameUI.format_status(:paused) == "PAUSED"
    end

    test "formats game over status" do
      assert GameUI.format_status(:game_over) == "GAME OVER"
    end

    test "formats won status" do
      assert GameUI.format_status(:won) == "YOU WIN!"
    end

    test "formats custom status string" do
      assert GameUI.format_status("CUSTOM") == "CUSTOM"
    end
  end

  describe "frame/3" do
    test "creates complete frame with title and content" do
      result = GameUI.frame("TEST", ["Line 1", "Line 2"], 20)

      assert length(result) == 6
      assert Enum.at(result, 0) == GameUI.top_border(20)
      assert Enum.at(result, 1) == GameUI.title_line("TEST", 20)
      assert Enum.at(result, 2) == GameUI.divider(20)
      assert String.contains?(Enum.at(result, 3), "Line 1")
      assert String.contains?(Enum.at(result, 4), "Line 2")
      assert Enum.at(result, 5) == GameUI.bottom_border(20)
    end

    test "preserves pre-formatted lines starting with ║" do
      custom_line = "║ Custom formatted  ║"
      result = GameUI.frame("TEST", [custom_line], 20)

      assert Enum.at(result, 3) == custom_line
    end
  end

  describe "controls_help/1" do
    test "formats single control pair" do
      result = GameUI.controls_help([{"Space", "Jump"}])
      assert result == ["Space: Jump"]
    end

    test "formats multiple control pairs" do
      result = GameUI.controls_help([
        {"Arrow Keys", "Move"},
        {"Space", "Jump"},
        {"Q", "Quit"}
      ])

      assert result == ["Arrow Keys: Move  Space: Jump  Q: Quit"]
    end
  end

  describe "centered/2" do
    test "centers text with default width" do
      result = GameUI.centered("TEST", 20)
      assert String.starts_with?(result, "║ ")
      assert String.ends_with?(result, " ║")
      assert String.length(result) == 20
    end

    test "centers text correctly" do
      result = GameUI.centered("HI", 20)
      # Content width is 16, "HI" is 2, so 7 spaces on each side
      # "║ " + 7 spaces + "HI" + 7 spaces + " ║"
      assert String.contains?(result, "HI")
      assert String.length(result) == 20
    end

    test "handles odd-length text" do
      result = GameUI.centered("ODD", 20)
      assert String.contains?(result, "ODD")
      assert String.length(result) == 20
    end
  end

  describe "line consistency" do
    test "all line types have consistent width" do
      width = 30

      top = GameUI.top_border(width)
      title = GameUI.title_line("TEST", width)
      div = GameUI.divider(width)
      content = GameUI.content_line("Content", width)
      empty = GameUI.empty_line(width)
      centered = GameUI.centered("Center", width)
      bottom = GameUI.bottom_border(width)

      assert String.length(top) == width
      assert String.length(title) == width
      assert String.length(div) == width
      assert String.length(content) == width
      assert String.length(empty) == width
      assert String.length(centered) == width
      assert String.length(bottom) == width
    end
  end
end
