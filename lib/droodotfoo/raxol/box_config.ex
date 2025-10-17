defmodule Droodotfoo.Raxol.BoxConfig do
  @moduledoc """
  Central configuration for terminal box dimensions and layout.
  All box rendering should use these constants to maintain alignment.

  ## Box Dimensions

  The terminal uses a fixed layout with the following dimensions:

  - **Terminal width**: 106 characters
  - **Navigation width**: 35 characters (left sidebar)
  - **Content width**: 71 characters (106 - 35)
  - **Inner content width**: 67 characters (71 - 4 for borders and padding)

  ## Box Styles

  Three box drawing styles are supported:

  - `:sharp` - Standard box-drawing characters (┌─┐ └─┘)
  - `:rounded` - Rounded corners (╭─╮ ╰─╯)
  - `:double` - Double-line borders (╔═╗ ╚═╝)

  ## Usage Examples

      # Get dimension constants
      iex> BoxConfig.content_width()
      71

      # Create a padded line
      iex> BoxConfig.padded_line("Hello World")
      "│  Hello World                                                        │"

      # Create a header line
      iex> BoxConfig.header_line("My Section")
      "┌─ My Section ────────────────────────────────────────────────────────┐"

      # Truncate and pad text safely
      iex> BoxConfig.truncate_and_pad("Very long text that needs truncation", 20)
      "Very long text th..."

      # Create an empty line
      iex> BoxConfig.empty_line()
      "│                                                                     │"

  """

  # Terminal layout constants
  @terminal_width 106
  @nav_width 35
  # terminal_width - nav_width
  @content_width 71
  # content_width - 4 (2 for borders + 2 for padding)
  @inner_width 67

  # Box drawing characters by style
  @box_chars %{
    sharp: %{
      top_left: "┌",
      top_right: "┐",
      bottom_left: "└",
      bottom_right: "┘",
      horizontal: "─",
      vertical: "│"
    },
    rounded: %{
      top_left: "╭",
      top_right: "╮",
      bottom_left: "╰",
      bottom_right: "╯",
      horizontal: "─",
      vertical: "│"
    },
    double: %{
      top_left: "╔",
      top_right: "╗",
      bottom_left: "╚",
      bottom_right: "╝",
      horizontal: "═",
      vertical: "║"
    }
  }

  @doc """
  Returns the total terminal width in characters.
  """
  @spec terminal_width() :: pos_integer()
  def terminal_width, do: @terminal_width

  @doc """
  Returns the navigation sidebar width in characters.
  """
  @spec nav_width() :: pos_integer()
  def nav_width, do: @nav_width

  @doc """
  Returns the main content area width in characters.
  This is the width of box borders (top/bottom lines).
  """
  @spec content_width() :: pos_integer()
  def content_width, do: @content_width

  @doc """
  Returns the inner content width in characters.
  This is the usable width inside a box (excluding borders and padding).
  """
  @spec inner_width() :: pos_integer()
  def inner_width, do: @inner_width

  @doc """
  Returns the box drawing characters for the specified style.

  ## Parameters
  - `style` - One of `:sharp`, `:rounded`, or `:double` (default: `:sharp`)

  ## Examples

      iex> BoxConfig.box_chars(:sharp)
      %{top_left: "┌", top_right: "┐", ...}

      iex> BoxConfig.box_chars(:rounded)
      %{top_left: "╭", top_right: "╮", ...}

  """
  @spec box_chars(:sharp | :rounded | :double) :: map()
  def box_chars(style \\ :sharp)
  def box_chars(:sharp), do: @box_chars.sharp
  def box_chars(:rounded), do: @box_chars.rounded
  def box_chars(:double), do: @box_chars.double

  @doc """
  Creates a complete box line (with borders) containing the given text.

  The text is automatically padded to fill the inner width and wrapped
  with vertical borders.

  ## Parameters
  - `text` - The content text (will be padded to inner_width)
  - `style` - Box style (default: `:sharp`)

  ## Examples

      iex> BoxConfig.box_line("Hello")
      "│  Hello                                                              │"

      iex> BoxConfig.box_line("Status: OK", :double)
      "║  Status: OK                                                         ║"

  """
  @spec box_line(String.t(), :sharp | :rounded | :double) :: String.t()
  def box_line(text, style \\ :sharp) do
    chars = box_chars(style)
    # Inner width accounts for borders (2 chars) already
    # Content width is 71, minus 2 borders = 69 inner space
    inner_space = @content_width - 2
    padded = padded_line(text, inner_space)
    "#{chars.vertical}#{padded}#{chars.vertical}"
  end

  @doc """
  Pads text to the specified width with trailing spaces.

  If the text is longer than the width, it will be truncated.
  A 2-space indent is automatically added at the beginning.

  ## Parameters
  - `text` - The text to pad
  - `width` - The target width (default: inner_width)

  ## Examples

      iex> BoxConfig.padded_line("Hello", 20)
      "  Hello             "

      iex> BoxConfig.padded_line("Too long text here", 10)
      "  Too lon..."

  """
  @spec padded_line(String.t(), pos_integer()) :: String.t()
  def padded_line(text, width \\ @inner_width) do
    # Reserve 2 chars for leading indent
    content_width = width - 2
    truncated = truncate_text(text, content_width)
    "  #{String.pad_trailing(truncated, content_width)}"
  end

  @doc """
  Creates a header line with a title.

  The title is inserted after "┌─ " and followed by horizontal lines
  to fill the content width.

  ## Parameters
  - `title` - The header title
  - `style` - Box style (default: `:sharp`)

  ## Examples

      iex> BoxConfig.header_line("Spotify")
      "┌─ Spotify ───────────────────────────────────────────────────────────┐"

      iex> BoxConfig.header_line("Settings", :rounded)
      "╭─ Settings ──────────────────────────────────────────────────────────╮"

  """
  @spec header_line(String.t(), :sharp | :rounded | :double) :: String.t()
  def header_line(title, style \\ :sharp) do
    chars = box_chars(style)

    # Format: "┌─ Title ─────...─────┐"
    # Available space for title: content_width - corners - "─ " - " " - fill
    # Leave room for corners and padding
    max_title_width = @content_width - 6

    # Truncate title if too long
    safe_title = truncate_text(title, max_title_width)

    # Calculate available space for horizontal lines
    prefix = "#{chars.top_left}#{chars.horizontal} #{safe_title} "
    prefix_len = String.length(prefix)

    # Fill remaining space with horizontal lines
    # -1 for closing corner
    remaining = @content_width - prefix_len - 1
    fill = String.duplicate(chars.horizontal, max(0, remaining))

    "#{prefix}#{fill}#{chars.top_right}"
  end

  @doc """
  Creates a footer line (bottom border of a box).

  ## Parameters
  - `style` - Box style (default: `:sharp`)

  ## Examples

      iex> BoxConfig.footer_line()
      "└─────────────────────────────────────────────────────────────────────┘"

      iex> BoxConfig.footer_line(:double)
      "╚═════════════════════════════════════════════════════════════════════╝"

  """
  @spec footer_line(:sharp | :rounded | :double) :: String.t()
  def footer_line(style \\ :sharp) do
    chars = box_chars(style)
    fill = String.duplicate(chars.horizontal, @content_width - 2)
    "#{chars.bottom_left}#{fill}#{chars.bottom_right}"
  end

  @doc """
  Creates an empty line (just borders with spaces).

  ## Examples

      iex> BoxConfig.empty_line()
      "│                                                                     │"

  """
  @spec empty_line() :: String.t()
  def empty_line do
    chars = box_chars(:sharp)
    spaces = String.duplicate(" ", @content_width - 2)
    "#{chars.vertical}#{spaces}#{chars.vertical}"
  end

  @doc """
  Truncates text to the specified width and pads with trailing spaces.

  This is the safe way to handle dynamic content that might overflow.
  If text exceeds width, it's truncated with "..." suffix.

  ## Parameters
  - `text` - The text to truncate and pad
  - `width` - The target width

  ## Examples

      iex> BoxConfig.truncate_and_pad("Short", 10)
      "Short     "

      iex> BoxConfig.truncate_and_pad("Very long text here", 10)
      "Very lo..."

  """
  @spec truncate_and_pad(String.t(), pos_integer()) :: String.t()
  def truncate_and_pad(text, width) do
    truncated = truncate_text(text, width)
    String.pad_trailing(truncated, width)
  end

  @doc """
  Truncates text to fit within the specified width.

  If the text is longer than the width, it's truncated and "..." is appended.
  The total length including "..." will not exceed the width.

  ## Parameters
  - `text` - The text to truncate
  - `max_width` - The maximum width

  ## Examples

      iex> BoxConfig.truncate_text("Hello", 10)
      "Hello"

      iex> BoxConfig.truncate_text("Very long text here", 10)
      "Very lo..."

      iex> BoxConfig.truncate_text("Exact", 5)
      "Exact"

      iex> BoxConfig.truncate_text("Toolong", 5)
      "To..."

  """
  @spec truncate_text(String.t(), pos_integer()) :: String.t()
  def truncate_text(_text, max_width) when max_width <= 3 do
    # For very small widths, just return dots
    String.duplicate(".", min(max_width, 3))
  end

  def truncate_text(text, max_width) do
    if String.length(text) > max_width do
      # Truncate and add ellipsis (total length = max_width)
      # Keep (max_width - 3) chars, then add "..."
      keep_chars = max_width - 3
      String.slice(text, 0, keep_chars) <> "..."
    else
      text
    end
  end

  @doc """
  Creates an inner box header line.

  Inner boxes are used for nested content within a main box.
  They are indented by 2 spaces and 4 characters narrower than main boxes.

  ## Parameters
  - `style` - Box style (default: `:sharp`)

  ## Examples

      iex> BoxConfig.inner_box_header()
      "│  ┌───────────────────────────────────────────────────────────────┐  │"

  """
  @spec inner_box_header(:sharp | :rounded | :double) :: String.t()
  def inner_box_header(style \\ :sharp) do
    chars = box_chars(style)
    # Total: 71 = 1 (│) + 2 (  ) + inner_box + 2 (  ) + 1 (│)
    # So inner_box = 71 - 6 = 65
    inner_box_width = @content_width - 6
    fill = String.duplicate(chars.horizontal, inner_box_width - 2)
    "#{chars.vertical}  #{chars.top_left}#{fill}#{chars.top_right}  #{chars.vertical}"
  end

  @doc """
  Creates an inner box footer line.

  ## Parameters
  - `style` - Box style (default: `:sharp`)

  ## Examples

      iex> BoxConfig.inner_box_footer()
      "│  └───────────────────────────────────────────────────────────────┘  │"

  """
  @spec inner_box_footer(:sharp | :rounded | :double) :: String.t()
  def inner_box_footer(style \\ :sharp) do
    chars = box_chars(style)
    # Same calculation as header: inner_box = 71 - 6 = 65
    inner_box_width = @content_width - 6
    fill = String.duplicate(chars.horizontal, inner_box_width - 2)
    "#{chars.vertical}  #{chars.bottom_left}#{fill}#{chars.bottom_right}  #{chars.vertical}"
  end

  @doc """
  Creates an inner box content line.

  ## Parameters
  - `text` - The content text
  - `style` - Box style (default: `:sharp`)

  ## Examples

      iex> BoxConfig.inner_box_line("Status: OK")
      "│  │ Status: OK                                                      │  │"

  """
  @spec inner_box_line(String.t(), :sharp | :rounded | :double) :: String.t()
  def inner_box_line(text, style \\ :sharp) do
    chars = box_chars(style)

    # Total: 71 = 1 (│) + 2 (  ) + 1 (│) + 1 ( ) + content + 1 ( ) + 1 (│) + 2 (  ) + 1 (│)
    # So content = 71 - 10 = 61
    inner_content_width = @content_width - 10
    padded = String.pad_trailing(truncate_text(text, inner_content_width), inner_content_width)
    "#{chars.vertical}  #{chars.vertical} #{padded} #{chars.vertical}  #{chars.vertical}"
  end
end
