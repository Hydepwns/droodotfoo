defmodule Droodotfoo.Plugins.UIHelpers do
  @moduledoc """
  Shared UI rendering utilities for plugins.
  Provides common formatting and rendering patterns to reduce duplication across plugins.

  ## Usage

  Import this module in your plugin to access all helper functions:

      defmodule MyPlugin do
        @behaviour Droodotfoo.PluginSystem.Plugin
        import Droodotfoo.Plugins.UIHelpers

        def render(state, _terminal_state) do
          header("MY PLUGIN", 78) ++
            [
              "",
              "Content goes here",
              "",
              divider(78)
            ]
        end
      end

  ## Common Patterns

  ### Plugin Headers

  Use `header/3` for centered titles:

      header("SPOTIFY CONTROLLER", 78)
      # =>
      # ==============================================================================
      #                            SPOTIFY CONTROLLER
      # ==============================================================================

  Use `header_left/3` for left-aligned titles:

      header_left("GITHUB PLUGIN HELP", 78)
      # =>
      # ==============================================================================
      # GITHUB PLUGIN HELP
      # ==============================================================================

  ### Dividers and Sections

  Simple dividers:

      divider(78)         # => "=============================================================================="
      divider(40, "-")    # => "----------------------------------------"

  Section dividers with labels:

      section_divider("RESULTS", 78)
      # => "────── RESULTS ────────────────────────────────────────────────────────"

  ### Text Formatting

  Center text within a width:

      center_text("HELLO", 20)
      # => "       HELLO        "

  Fit text to exact width (pad or truncate):

      fit_text("Short", 20)          # => "Short               "
      fit_text("Very long text...", 10)  # => "Very lo..."

  ### Boxes and Frames

  Create bordered boxes:

      box_frame(["Line 1", "Line 2"], 40)
      # =>
      # ╔══════════════════════════════════════╗
      # ║Line 1                                ║
      # ║Line 2                                ║
      # ╚══════════════════════════════════════╝

  ### Progress Indicators

  Display progress bars:

      progress_bar(50, 100, 20)
      # => "[██████████░░░░░░░░░░] 50%"

  ### Status Indicators

  Show status symbols:

      status_indicator(:success)  # => "[OK]"
      status_indicator(:error)    # => "[X]"
      status_indicator(:warning)  # => "[!]"

  ## Benefits

  - **DRY Code**: Eliminate duplicate formatting logic across plugins
  - **Consistency**: Ensure uniform look and feel across all plugins
  - **Maintainability**: Update rendering in one place
  - **Readability**: Clear, semantic function names

  ## Related Modules

  - `Droodotfoo.Plugins.GameBase` - Shared game logic utilities
  - `Droodotfoo.Plugins.GameUI` - Game-specific UI utilities
  """

  @doc """
  Creates a divider line of specified width and character.

  ## Examples

      iex> UIHelpers.divider(40, "=")
      "========================================"

      iex> UIHelpers.divider(10)
      "=========="
  """
  @spec divider(integer(), String.t()) :: String.t()
  def divider(width, char \\ "=") do
    String.duplicate(char, width)
  end

  @doc """
  Creates a header block with title and dividers.

  ## Examples

      iex> UIHelpers.header("MY PLUGIN", 20)
      [
        "====================",
        "     MY PLUGIN      ",
        "===================="
      ]
  """
  @spec header(String.t(), integer(), String.t()) :: [String.t()]
  def header(title, width \\ 78, divider_char \\ "=") do
    div = divider(width, divider_char)
    centered_title = center_text(title, width)

    [div, centered_title, div]
  end

  @doc """
  Creates a header block with title left-padded.
  """
  @spec header_left(String.t(), integer(), String.t()) :: [String.t()]
  def header_left(title, width \\ 78, divider_char \\ "=") do
    div = divider(width, divider_char)
    padded_title = String.pad_trailing(title, width)

    [div, padded_title, div]
  end

  @doc """
  Centers text within a given width.

  ## Examples

      iex> UIHelpers.center_text("HELLO", 11)
      "   HELLO   "
  """
  @spec center_text(String.t(), integer()) :: String.t()
  def center_text(text, width) when is_binary(text) and is_integer(width) do
    text_length = String.length(text)

    if text_length >= width do
      text
    else
      total_padding = width - text_length
      left_padding = div(total_padding, 2)
      right_padding = total_padding - left_padding

      String.duplicate(" ", left_padding) <> text <> String.duplicate(" ", right_padding)
    end
  end

  @doc """
  Creates a simple section divider with optional label.

  ## Examples

      iex> UIHelpers.section_divider("RESULTS", 40)
      "────── RESULTS ──────────────────────"
  """
  @spec section_divider(String.t() | nil, integer(), String.t()) :: String.t()
  def section_divider(label \\ nil, width \\ 78, char \\ "─")

  def section_divider(nil, width, char) do
    divider(width, char)
  end

  def section_divider(label, width, char) do
    label_with_spaces = " #{label} "
    label_length = String.length(label_with_spaces)

    if label_length >= width do
      label
    else
      left_chars = 6
      right_chars = width - left_chars - label_length

      String.duplicate(char, left_chars) <>
        label_with_spaces <>
        String.duplicate(char, right_chars)
    end
  end

  @doc """
  Pads or truncates text to exact width.
  """
  @spec fit_text(String.t(), integer(), String.t()) :: String.t()
  def fit_text(text, width, pad_char \\ " ") do
    text_length = String.length(text)

    cond do
      text_length == width -> text
      text_length < width -> String.pad_trailing(text, width, pad_char)
      text_length > width -> String.slice(text, 0, width - 3) <> "..."
    end
  end

  @doc """
  Creates a key-value display line.

  ## Examples

      iex> UIHelpers.kv_line("Name", "John Doe", 40)
      "Name: John Doe                          "
  """
  @spec kv_line(String.t(), String.t(), integer()) :: String.t()
  def kv_line(key, value, width \\ 78) do
    line = "#{key}: #{value}"
    fit_text(line, width)
  end

  @doc """
  Creates a box frame around content.
  """
  @spec box_frame([String.t()], integer(), map()) :: [String.t()]
  def box_frame(content_lines, width \\ 78, opts \\ %{}) do
    top_char = Map.get(opts, :top, "═")
    side_char = Map.get(opts, :side, "║")
    top_left = Map.get(opts, :top_left, "╔")
    top_right = Map.get(opts, :top_right, "╗")
    bottom_left = Map.get(opts, :bottom_left, "╚")
    bottom_right = Map.get(opts, :bottom_right, "╝")

    inner_width = width - 2
    top = top_left <> String.duplicate(top_char, inner_width) <> top_right
    bottom = bottom_left <> String.duplicate(top_char, inner_width) <> bottom_right

    framed_content =
      Enum.map(content_lines, fn line ->
        padded = fit_text(line, inner_width)
        "#{side_char}#{padded}#{side_char}"
      end)

    [top] ++ framed_content ++ [bottom]
  end

  @doc """
  Creates an empty/spacer line for plugin output.
  """
  @spec empty_line(integer()) :: String.t()
  def empty_line(width \\ 78) do
    String.duplicate(" ", width)
  end

  @doc """
  Indents text by specified number of spaces.
  """
  @spec indent(String.t(), integer()) :: String.t()
  def indent(text, spaces \\ 2) do
    String.duplicate(" ", spaces) <> text
  end

  @doc """
  Indents multiple lines.
  """
  @spec indent_lines([String.t()], integer()) :: [String.t()]
  def indent_lines(lines, spaces \\ 2) do
    Enum.map(lines, &indent(&1, spaces))
  end

  @doc """
  Creates a progress indicator.

  ## Examples

      iex> UIHelpers.progress_bar(50, 100, 20)
      "[██████████░░░░░░░░░░] 50%"
  """
  @spec progress_bar(integer(), integer(), integer()) :: String.t()
  def progress_bar(current, total, width \\ 20) do
    percentage = if total > 0, do: current / total * 100, else: 0
    filled_width = round(current / total * width)
    empty_width = width - filled_width

    bar =
      "[" <>
        String.duplicate("█", filled_width) <>
        String.duplicate("░", empty_width) <>
        "]"

    "#{bar} #{round(percentage)}%"
  end

  @doc """
  Creates a simple table row with columns.
  """
  @spec table_row([String.t()], [integer()]) :: String.t()
  def table_row(columns, widths) do
    columns
    |> Enum.zip(widths)
    |> Enum.map_join(" | ", fn {text, width} -> fit_text(text, width) end)
  end

  @doc """
  Creates a status indicator with color/symbol.
  Uses ASCII-only characters per project guidelines.
  """
  @spec status_indicator(atom()) :: String.t()
  def status_indicator(status) do
    case status do
      :success -> "[OK]"
      :error -> "[X]"
      :warning -> "[!]"
      :info -> "[i]"
      :pending -> "[...]"
      _ -> "[ ]"
    end
  end
end
