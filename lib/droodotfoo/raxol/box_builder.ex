defmodule Droodotfoo.Raxol.BoxBuilder do
  @moduledoc """
  High-level box building utilities that reduce boilerplate.

  This module builds on top of `BoxConfig` to provide convenient functions
  for common box-building patterns like complete boxes with headers/footers,
  inner boxes, info lines, and sections.

  ## Usage Examples

      # Build a simple box with header and content
      BoxBuilder.build("Settings", [
        "Theme: Dark",
        "Font Size: 14px",
        "Auto-save: Enabled"
      ])

      # Build a box with info lines
      BoxBuilder.build_with_info("User Profile", [
        {"Name", "Drew Hiro"},
        {"Email", "drew@axol.io"},
        {"Role", "Engineer"}
      ])

      # Build an inner box
      BoxBuilder.inner_box("Status", [
        "Connected: Yes",
        "Latency: 45ms"
      ])

  """

  alias Droodotfoo.Raxol.BoxConfig

  @doc """
  Build a complete box with header, content lines, and footer.

  ## Parameters
  - `title` - The box header title
  - `content_lines` - List of content strings (will be auto-padded)
  - `style` - Box style (default: `:sharp`)

  ## Examples

      iex> BoxBuilder.build("Test", ["Line 1", "Line 2"])
      [
        "┌─ Test ─────────────────────────────────────────────────────────────┐",
        "│  Line 1                                                             │",
        "│  Line 2                                                             │",
        "└─────────────────────────────────────────────────────────────────────┘"
      ]

  """
  @spec build(String.t(), [String.t()], :sharp | :rounded | :double) :: [String.t()]
  def build(title, content_lines, style \\ :sharp) do
    header = BoxConfig.header_line(title, style)
    footer = BoxConfig.footer_line(style)

    body_lines =
      content_lines
      |> Enum.map(fn line ->
        BoxConfig.box_line(line, style)
      end)

    [header] ++ body_lines ++ [footer]
  end

  @doc """
  Build a box with info lines (label: value pairs).

  Each info line is formatted as "Label: Value" with proper alignment.

  ## Parameters
  - `title` - The box header title
  - `info_pairs` - List of `{label, value}` tuples
  - `opts` - Options:
    - `:style` - Box style (default: `:sharp`)
    - `:label_width` - Width for labels (default: 15)
    - `:separator` - Separator between label and value (default: ": ")

  ## Examples

      iex> BoxBuilder.build_with_info("Settings", [
      ...>   {"Theme", "Dark"},
      ...>   {"Font", "Monaspace"}
      ...> ])
      [
        "┌─ Settings ─────────────────────────────────────────────────────────┐",
        "│  Theme:          Dark                                               │",
        "│  Font:           Monaspace                                          │",
        "└─────────────────────────────────────────────────────────────────────┘"
      ]

  """
  @spec build_with_info(String.t(), [{String.t(), String.t()}], keyword()) :: [String.t()]
  def build_with_info(title, info_pairs, opts \\ []) do
    style = Keyword.get(opts, :style, :sharp)
    label_width = Keyword.get(opts, :label_width, 15)
    separator = Keyword.get(opts, :separator, ": ")

    content_lines =
      Enum.map(info_pairs, fn {label, value} ->
        info_line(label, value, label_width: label_width, separator: separator)
      end)

    build(title, content_lines, style)
  end

  @doc """
  Build an info line with label and value.

  ## Parameters
  - `label` - The label text
  - `value` - The value text
  - `opts` - Options:
    - `:label_width` - Width to pad label to (default: 15)
    - `:separator` - Separator between label and value (default: ": ")

  ## Examples

      iex> BoxBuilder.info_line("Status", "Connected")
      "Status:          Connected"

      iex> BoxBuilder.info_line("Port", "4000", label_width: 10)
      "Port:      4000"

  """
  @spec info_line(String.t(), String.t(), keyword()) :: String.t()
  def info_line(label, value, opts \\ []) do
    label_width = Keyword.get(opts, :label_width, 15)
    separator = Keyword.get(opts, :separator, ": ")

    # Calculate available space for value
    # inner_width - 2 (indent) - label_width - separator_length
    value_width = BoxConfig.inner_width() - 2 - label_width - String.length(separator)

    padded_label = String.pad_trailing(label <> separator, label_width + String.length(separator))
    truncated_value = BoxConfig.truncate_text(value, value_width)

    padded_label <> truncated_value
  end

  @doc """
  Build an inner box (box within a box).

  ## Parameters
  - `title` - Inner box title (optional, can be empty string)
  - `content_lines` - List of content strings
  - `style` - Box style (default: `:sharp`)

  ## Examples

      iex> BoxBuilder.inner_box("Status", ["All systems operational"])
      [
        "│  ┌─ Status ────────────────────────────────────────────────────┐  │",
        "│  │ All systems operational                                     │  │",
        "│  └─────────────────────────────────────────────────────────────┘  │"
      ]

  """
  @spec inner_box(String.t(), [String.t()], :sharp | :rounded | :double) :: [String.t()]
  def inner_box(title, content_lines, style \\ :sharp) do
    chars = BoxConfig.box_chars(style)

    # Inner box width: content_width - 6 (outer borders + padding)
    # Total line: │  │ content │  │ = 71 chars
    # So: 1 + 2 + 1 + 1 + content + 1 + 1 + 2 + 1 = 71
    # content = 71 - 10 = 61
    inner_box_width = BoxConfig.content_width() - 6
    inner_content_width = BoxConfig.content_width() - 10

    # Build header
    title_prefix = if title != "", do: "─ #{title} ", else: ""
    title_len = String.length(title_prefix)
    header_fill_len = inner_box_width - 2 - title_len
    header_fill = String.duplicate(chars.horizontal, max(0, header_fill_len))

    header =
      "#{chars.vertical}  #{chars.top_left}#{title_prefix}#{header_fill}#{chars.top_right}  #{chars.vertical}"

    # Build content lines
    body_lines =
      Enum.map(content_lines, fn line ->
        padded = BoxConfig.truncate_and_pad(line, inner_content_width)
        "#{chars.vertical}  #{chars.vertical} #{padded} #{chars.vertical}  #{chars.vertical}"
      end)

    # Build footer
    footer_fill = String.duplicate(chars.horizontal, inner_box_width - 2)

    footer =
      "#{chars.vertical}  #{chars.bottom_left}#{footer_fill}#{chars.bottom_right}  #{chars.vertical}"

    [header] ++ body_lines ++ [footer]
  end

  @doc """
  Build a section divider line.

  Creates a line like: "├─ Section Name ─────────────┤"

  ## Parameters
  - `title` - The section title
  - `style` - Box style (default: `:sharp`)

  ## Examples

      iex> BoxBuilder.section("Settings")
      "├─ Settings ────────────────────────────────────────────────────────┤"

  """
  @spec section(String.t(), :sharp | :rounded | :double) :: String.t()
  def section(title, style \\ :sharp) do
    chars = BoxConfig.box_chars(style)

    # Format: "├─ Title ─────...─────┤"
    max_title_width = BoxConfig.content_width() - 6

    # Truncate title if too long
    safe_title = BoxConfig.truncate_text(title, max_title_width)

    # Calculate available space for horizontal lines
    prefix = "├#{chars.horizontal} #{safe_title} "
    prefix_len = String.length(prefix)

    # Fill remaining space with horizontal lines
    remaining = BoxConfig.content_width() - prefix_len - 1
    fill = String.duplicate(chars.horizontal, max(0, remaining))

    # Section divider uses same style
    right_char =
      case style do
        :sharp -> "┤"
        :rounded -> "┤"
        :double -> "╣"
      end

    "#{prefix}#{fill}#{right_char}"
  end

  @doc """
  Build an empty line (just borders with spaces).

  ## Parameters
  - `count` - Number of empty lines to generate (default: 1)

  ## Examples

      iex> BoxBuilder.empty_lines(2)
      [
        "│                                                                     │",
        "│                                                                     │"
      ]

  """
  @spec empty_lines(pos_integer()) :: [String.t()]
  def empty_lines(count \\ 1) do
    List.duplicate(BoxConfig.empty_line(), count)
  end

  @doc """
  Build a box with sections.

  Sections are separated by section divider lines.

  ## Parameters
  - `title` - The box header title
  - `sections` - List of `{section_title, content_lines}` tuples
  - `style` - Box style (default: `:sharp`)

  ## Examples

      iex> BoxBuilder.build_with_sections("Dashboard", [
      ...>   {"Status", ["All systems operational"]},
      ...>   {"Metrics", ["CPU: 45%", "Memory: 2.3GB"]}
      ...> ])
      [
        "┌─ Dashboard ────────────────────────────────────────────────────────┐",
        "├─ Status ───────────────────────────────────────────────────────────┤",
        "│  All systems operational                                            │",
        "├─ Metrics ──────────────────────────────────────────────────────────┤",
        "│  CPU: 45%                                                           │",
        "│  Memory: 2.3GB                                                      │",
        "└─────────────────────────────────────────────────────────────────────┘"
      ]

  """
  @spec build_with_sections(String.t(), [{String.t(), [String.t()]}], :sharp | :rounded | :double) ::
          [String.t()]
  def build_with_sections(title, sections, style \\ :sharp) do
    header = BoxConfig.header_line(title, style)
    footer = BoxConfig.footer_line(style)

    section_lines =
      sections
      |> Enum.flat_map(fn {section_title, content_lines} ->
        divider = section(section_title, style)

        body =
          Enum.map(content_lines, fn line ->
            BoxConfig.box_line(line, style)
          end)

        [divider] ++ body
      end)

    [header] ++ section_lines ++ [footer]
  end

  @doc """
  Wrap long text into multiple box lines.

  Automatically splits text into lines that fit within the box width.

  ## Parameters
  - `text` - The text to wrap
  - `max_width` - Maximum width per line (default: inner_width - 2 for indent)

  ## Examples

      iex> BoxBuilder.wrap_text("This is a very long line that needs to be wrapped", 20)
      [
        "This is a very long",
        "line that needs to",
        "be wrapped"
      ]

  """
  @spec wrap_text(String.t(), pos_integer()) :: [String.t()]
  def wrap_text(text, max_width \\ BoxConfig.inner_width() - 2) do
    # Handle empty text
    if text == "" do
      [""]
    else
      words = String.split(text, " ")

      {lines, current_line} =
        Enum.reduce(words, {[], ""}, fn word, acc ->
          add_word_to_lines(word, acc, max_width)
        end)

      # Add final line if not empty
      finalize_wrapped_lines(lines, current_line)
    end
  end

  defp add_word_to_lines(word, {lines, current_line}, max_width) do
    test_line = build_test_line(current_line, word)

    if String.length(test_line) <= max_width do
      {lines, test_line}
    else
      flush_current_line(lines, current_line, word)
    end
  end

  defp build_test_line("", word), do: word
  defp build_test_line(current_line, word), do: current_line <> " " <> word

  defp flush_current_line(lines, "", word), do: {lines, word}
  defp flush_current_line(lines, current_line, word), do: {lines ++ [current_line], word}

  defp finalize_wrapped_lines(lines, ""), do: lines
  defp finalize_wrapped_lines(lines, current_line), do: lines ++ [current_line]
end
