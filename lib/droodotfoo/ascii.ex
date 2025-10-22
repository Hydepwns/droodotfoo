defmodule Droodotfoo.Ascii do
  @moduledoc """
  Shared ASCII art and text formatting utilities.
  Used across plugins and display modules for consistent text handling.
  """

  alias Droodotfoo.TimeFormatter

  @doc """
  Formats large numbers with K/M suffixes for compact display.

  ## Examples

      iex> Droodotfoo.Ascii.format_number(999)
      "999"

      iex> Droodotfoo.Ascii.format_number(5_432)
      "5.4K"

      iex> Droodotfoo.Ascii.format_number(2_500_000)
      "2.5M"

      iex> Droodotfoo.Ascii.format_number(nil)
      "0"
  """
  def format_number(nil), do: "0"
  def format_number(num) when num < 1_000, do: Integer.to_string(num)

  def format_number(num) when num < 1_000_000 do
    "#{Float.round(num / 1_000, 1)}K"
  end

  def format_number(num) do
    "#{Float.round(num / 1_000_000, 1)}M"
  end

  @doc """
  Truncates text to maximum length with ellipsis if needed.

  ## Examples

      iex> Droodotfoo.Ascii.truncate_text("short", 10)
      "short"

      iex> Droodotfoo.Ascii.truncate_text("this is a very long text", 15)
      "this is a ve..."

      iex> Droodotfoo.Ascii.truncate_text(nil, 10)
      ""
  """
  def truncate_text(nil, _max_length), do: ""
  def truncate_text(text, max_length) when byte_size(text) <= max_length, do: text

  def truncate_text(text, max_length) do
    String.slice(text, 0, max_length - 3) <> "..."
  end

  @doc """
  Wraps text to fit within maximum width, splitting on word boundaries when possible.
  Preserves existing line breaks.

  ## Examples

      iex> Droodotfoo.Ascii.wrap_text("short", 10)
      ["short"]

      iex> Droodotfoo.Ascii.wrap_text("this is a very long line", 10)
      ["this is a", "very long", "line"]

      iex> Droodotfoo.Ascii.wrap_text("Line 1\\nLine 2", 20)
      ["Line 1", "Line 2"]
  """
  def wrap_text(text, max_width) do
    text
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      if String.length(line) <= max_width do
        [line]
      else
        wrap_line_by_words(line, max_width)
      end
    end)
  end

  defp wrap_line_by_words(line, max_width) do
    words = String.split(line, " ")

    {lines, current} =
      Enum.reduce(words, {[], ""}, fn word, {lines, current} ->
        test_line = if current == "", do: word, else: "#{current} #{word}"

        if String.length(test_line) <= max_width do
          {lines, test_line}
        else
          {lines ++ [current], word}
        end
      end)

    if current == "", do: lines, else: lines ++ [current]
  end

  @doc """
  Formats duration in milliseconds to M:SS format.
  Delegates to TimeFormatter.

  ## Examples

      iex> Droodotfoo.Ascii.format_duration_ms(65_000)
      "1:05"

      iex> Droodotfoo.Ascii.format_duration_ms(3_661_000)
      "61:01"

      iex> Droodotfoo.Ascii.format_duration_ms(nil)
      "--:--"
  """
  defdelegate format_duration_ms(ms), to: TimeFormatter

  @doc """
  Formats duration in seconds to relative time (e.g., "5m ago", "2h ago").
  Delegates to TimeFormatter.

  ## Examples

      iex> Droodotfoo.Ascii.format_relative_time(45)
      "45s ago"

      iex> Droodotfoo.Ascii.format_relative_time(3600)
      "1h ago"

      iex> Droodotfoo.Ascii.format_relative_time(86400)
      "1d ago"
  """
  defdelegate format_relative_time(seconds), to: TimeFormatter

  @doc """
  Creates a padded line for box drawing with consistent formatting.

  ## Examples

      iex> Droodotfoo.Ascii.box_line("Hello", 20)
      "│ Hello              │"

      iex> Droodotfoo.Ascii.box_line("Text", 15, "║")
      "║ Text         ║"
  """
  def box_line(text, width, border_char \\ "│") do
    content_width = width - 4
    "#{border_char} #{String.pad_trailing(text, content_width)} #{border_char}"
  end

  @doc """
  Renders a list or shows an empty message if the list is empty.

  ## Examples

      iex> render_fn = fn item -> "Item: \#{item}" end
      iex> Droodotfoo.Ascii.render_list_or_empty([1, 2], "No items", 30, render_fn)
      ["Item: 1", "Item: 2"]

      iex> render_fn = fn item -> "Item: \#{item}" end
      iex> Droodotfoo.Ascii.render_list_or_empty([], "No items", 30, render_fn)
      ["│ No items                   │"]
  """
  def render_list_or_empty(list, empty_msg, width, render_fn) do
    if Enum.empty?(list) do
      [box_line(empty_msg, width)]
    else
      Enum.map(list, render_fn)
    end
  end

  @doc """
  Creates a box header with title and optional border style.

  ## Examples

      iex> Droodotfoo.Ascii.box_header("Title", 30)
      "┌─ Title ────────────────────┐"

      iex> Droodotfoo.Ascii.box_header("Test", 20, :simple)
      "+-- Test --------------+"
  """
  def box_header(title, width, style \\ :rounded) do
    {left, fill, right, prefix} =
      case style do
        :simple -> {"+", "-", "+", "-- "}
        :double -> {"╔", "═", "╗", "═ "}
        _ -> {"┌", "─", "┐", "─ "}
      end

    title_part = prefix <> title <> " "
    remaining = width - String.length(title_part) - 2

    left <> title_part <> String.duplicate(fill, max(0, remaining)) <> right
  end

  @doc """
  Creates a box footer with optional border style.

  ## Examples

      iex> Droodotfoo.Ascii.box_footer(30)
      "└────────────────────────────┘"

      iex> Droodotfoo.Ascii.box_footer(20, :simple)
      "+------------------+"
  """
  def box_footer(width, style \\ :rounded) do
    {left, fill, right} =
      case style do
        :simple -> {"+", "-", "+"}
        :double -> {"╚", "═", "╝"}
        _ -> {"└", "─", "┘"}
      end

    left <> String.duplicate(fill, width - 2) <> right
  end

  @doc """
  Creates a box content line with proper padding and borders.

  ## Examples

      iex> Droodotfoo.Ascii.box_content("Hello world", 30)
      "│ Hello world                 │"

      iex> Droodotfoo.Ascii.box_content("Test", 20, :simple)
      "| Test               |"
  """
  def box_content(text, width, style \\ :rounded) do
    border =
      case style do
        :simple -> "|"
        :double -> "║"
        _ -> "│"
      end

    content_width = width - 4
    "#{border} #{String.pad_trailing(text, content_width)} #{border}"
  end
end
