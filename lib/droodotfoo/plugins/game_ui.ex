defmodule Droodotfoo.Plugins.GameUI do
  @moduledoc """
  Shared UI utilities for terminal game plugins.

  Provides helper functions for common rendering patterns like box borders,
  status lines, and control help text. Games can use these utilities for
  consistency while maintaining flexibility for custom layouts.
  """

  @default_width 64

  @doc """
  Creates a top border for a game UI box.

  ## Examples

      iex> GameUI.top_border(10)
      "╔════════╗"
  """
  def top_border(width \\ @default_width) do
    "╔" <> String.duplicate("═", width - 2) <> "╗"
  end

  @doc """
  Creates a bottom border for a game UI box.
  """
  def bottom_border(width \\ @default_width) do
    "╚" <> String.duplicate("═", width - 2) <> "╝"
  end

  @doc """
  Creates a horizontal divider line.
  """
  def divider(width \\ @default_width) do
    "╠" <> String.duplicate("═", width - 2) <> "╣"
  end

  @doc """
  Creates a title line with centered or left-aligned text.

  ## Examples

      iex> GameUI.title_line("TETRIS", 20)
      "║ TETRIS             ║"
  """
  def title_line(title, width \\ @default_width) do
    content_width = width - 4
    padded = String.pad_trailing(title, content_width)
    "║ #{padded} ║"
  end

  @doc """
  Creates a content line with optional left padding.

  ## Examples

      iex> GameUI.content_line("Score: 100")
      "║ Score: 100         ║"
  """
  def content_line(text, width \\ @default_width, left_pad \\ 1) do
    # Total content area between borders
    # Remove 4 for "║ " and " ║"
    content_area = width - 4

    # Available space for padding + text
    padding = String.duplicate(" ", left_pad)
    text_length = String.length(text)
    padding_length = String.length(padding)

    # Calculate right padding to fill the line
    right_padding_length = content_area - padding_length - text_length
    right_padding = String.duplicate(" ", max(0, right_padding_length))

    "║ #{padding}#{text}#{right_padding} ║"
  end

  @doc """
  Creates an empty line (just borders).
  """
  def empty_line(width \\ @default_width) do
    content_width = width - 4
    "║ #{String.duplicate(" ", content_width)} ║"
  end

  @doc """
  Formats a status message (game over, paused, playing, etc).

  ## Examples

      iex> GameUI.format_status(:playing)
      "PLAYING"

      iex> GameUI.format_status(:game_over)
      "GAME OVER"
  """
  def format_status(:playing), do: "PLAYING"
  def format_status(:paused), do: "PAUSED"
  def format_status(:game_over), do: "GAME OVER"
  def format_status(:won), do: "YOU WIN!"
  def format_status(custom) when is_binary(custom), do: custom

  @doc """
  Creates a complete frame with title and content.

  This is a convenience function that combines borders, title, and content.

  ## Examples

      iex> GameUI.frame("GAME", ["Line 1", "Line 2"])
      [
        "╔══════════╗",
        "║ GAME     ║",
        "╠══════════╣",
        "║ Line 1   ║",
        "║ Line 2   ║",
        "╚══════════╝"
      ]
  """
  def frame(title, content_lines, width \\ @default_width) do
    [
      top_border(width),
      title_line(title, width),
      divider(width)
    ] ++
      Enum.map(content_lines, fn line ->
        if String.starts_with?(line, "║") do
          line
        else
          content_line(line, width)
        end
      end) ++
      [bottom_border(width)]
  end

  @doc """
  Formats control help text in a consistent way.

  ## Examples

      iex> GameUI.controls_help([{"Arrow Keys", "Move"}, {"Space", "Drop"}])
      ["Arrow Keys: Move  Space: Drop"]
  """
  def controls_help(control_pairs) do
    control_pairs
    |> Enum.map_join("  ", fn {key, action} -> "#{key}: #{action}" end)
    |> List.wrap()
  end

  @doc """
  Creates a centered text line.

  ## Examples

      iex> GameUI.centered("TETRIS", 20)
      "║      TETRIS      ║"
  """
  def centered(text, width \\ @default_width) do
    content_width = width - 4
    text_len = String.length(text)
    left_pad = div(content_width - text_len, 2)
    right_pad = content_width - text_len - left_pad

    "║ " <>
      String.duplicate(" ", left_pad) <>
      text <>
      String.duplicate(" ", right_pad) <>
      " ║"
  end

  @doc """
  Alias for frame/3. Creates a complete game frame with title and content.
  This naming makes it clear the frame is for a game UI.
  """
  def game_frame(title, content_lines, width \\ @default_width) do
    frame(title, content_lines, width)
  end

  @doc """
  Creates a game frame with status and optional score.
  Includes title, status line, and content in a bordered frame.

  ## Examples

      iex> GameUI.game_frame_with_status("TETRIS", :playing, 1000, ["Line 1", "Line 2"])
      # Returns frame with title, status, score, and content
  """
  def game_frame_with_status(title, status, score, content_lines, width \\ @default_width) do
    status_text = format_status(status)

    header = [
      top_border(width),
      title_line(title, width),
      divider(width),
      content_line("Status: #{status_text}", width),
      content_line("Score: #{score}", width),
      divider(width)
    ]

    formatted_content =
      Enum.map(content_lines, fn line ->
        if String.starts_with?(line, "║") do
          line
        else
          content_line(line, width)
        end
      end)

    header ++ formatted_content ++ [bottom_border(width)]
  end

  @doc """
  Formats a score line for consistent display.

  ## Examples

      iex> GameUI.score_line(1000)
      "Score: 1,000"

      iex> GameUI.score_line(1000000)
      "Score: 1,000,000"
  """
  def score_line(score) when is_integer(score) do
    formatted =
      score
      |> Integer.to_string()
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.map(&Enum.reverse/1)
      |> Enum.map(&Enum.join/1)
      |> Enum.reverse()
      |> Enum.join(",")

    "Score: #{formatted}"
  end

  @doc """
  Creates an info panel with key-value pairs.

  ## Examples

      iex> GameUI.info_panel([{"Level", "5"}, {"Lines", "42"}])
      ["Level: 5", "Lines: 42"]
  """
  def info_panel(info_pairs) do
    Enum.map(info_pairs, fn {key, value} ->
      "#{key}: #{value}"
    end)
  end

  @doc """
  Creates a horizontal border with custom characters.
  Useful for ASCII art boxes with different border styles.

  ## Examples

      iex> GameUI.horizontal_border(20, "+", "-", "+")
      "+------------------+"

      iex> GameUI.horizontal_border(15, "┌", "─", "┐")
      "┌─────────────┐"
  """
  def horizontal_border(width, left_char, fill_char, right_char) do
    left_char <> String.duplicate(fill_char, width - 2) <> right_char
  end

  @doc """
  Creates a padded content line with custom border characters.

  ## Examples

      iex> GameUI.padded_line("Hello", 20, "│")
      "│ Hello              │"

      iex> GameUI.padded_line("Test", 15, "|")
      "| Test            |"
  """
  def padded_line(content, width, border_char \\ "│") do
    content_width = width - 4
    "#{border_char} #{String.pad_trailing(content, content_width)} #{border_char}"
  end
end
