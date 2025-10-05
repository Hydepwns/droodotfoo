defmodule Droodotfoo.AsciiChart do
  @moduledoc """
  ASCII chart rendering utilities for terminal visualization.
  Generates sparklines, bar charts, and other visualizations.
  """

  @doc """
  Generate a sparkline from a list of values.
  Returns a string of block characters representing the data.

  ## Options
  - `:width` - Width of the sparkline (default: length of data)
  - `:height` - Height levels (default: 8 for full block characters)

  ## Examples

      iex> AsciiChart.sparkline([1, 2, 3, 4, 5])
      "▁▂▄▆█"
  """
  def sparkline(data, opts \\ [])
  def sparkline([], _opts), do: ""
  def sparkline([_single], _opts), do: "▄"

  def sparkline(data, opts) do
    width = Keyword.get(opts, :width, length(data))

    # Sample data to fit width if needed
    sampled_data = sample_data(data, width)

    # Normalize to 0-7 range for 8 block levels
    normalized = normalize_data(sampled_data, 7)

    # Convert to block characters
    Enum.map(normalized, &value_to_block/1)
    |> Enum.join()
  end

  @doc """
  Generate a horizontal bar chart with gradient effect.

  ## Examples

      iex> AsciiChart.bar_chart(75, max: 100, width: 20)
      "████████████████▓▓▒░"
  """
  def bar_chart(value, opts \\ []) do
    max_value = Keyword.get(opts, :max, 100)
    width = Keyword.get(opts, :width, 20)
    gradient = Keyword.get(opts, :gradient, false)

    filled = round(value / max_value * width)
    filled = min(filled, width)
    empty = width - filled

    if gradient do
      # Create gradient effect
      full_chars = max(0, filled - 3)
      gradient_chars = min(3, filled)

      full = String.duplicate("█", full_chars)
      grad = gradient_tail(gradient_chars)
      empty_str = String.duplicate("░", empty)

      full <> grad <> empty_str
    else
      String.duplicate("█", filled) <> String.duplicate("░", empty)
    end
  end

  @doc """
  Generate a percentage bar with label and optional gradient.

  ## Examples

      iex> AsciiChart.percent_bar("Memory", 65.5, width: 30)
      "Memory     ╭────────────────────▓▒░░░░░░░░╮ 65.5%"
  """
  def percent_bar(label, value, opts \\ []) do
    width = Keyword.get(opts, :width, 20)
    label_width = Keyword.get(opts, :label_width, 10)
    gradient = Keyword.get(opts, :gradient, true)
    style = Keyword.get(opts, :style, :rounded)

    padded_label = String.pad_trailing(label, label_width)
    bar = bar_chart(value, max: 100, width: width, gradient: gradient)

    # Handle both integers and floats
    percent = if is_float(value) do
      :erlang.float_to_binary(value, decimals: 1)
    else
      "#{value}.0"
    end

    {left, right} = case style do
      :rounded -> {"╭", "╮"}
      :square -> {"[", "]"}
      :double -> {"╔", "╗"}
      _ -> {"[", "]"}
    end

    "#{padded_label} #{left}#{bar}#{right} #{percent}%"
  end

  @doc """
  Generate a mini line chart with gradient blocks and optional frame.

  ## Examples

      iex> AsciiChart.line_chart([10, 20, 15, 25, 30], width: 20, height: 5, frame: true)
  """
  def line_chart(data, opts \\ []) do
    width = Keyword.get(opts, :width, 40)
    height = Keyword.get(opts, :height, 8)
    frame = Keyword.get(opts, :frame, false)

    sampled = sample_data(data, width)
    normalized = normalize_data(sampled, height - 1)

    # Build chart from top to bottom with gradient effect
    rows = for y <- (height - 1)..0 do
      row = for x <- 0..(width - 1) do
        point_value = Enum.at(normalized, x, 0)
        cond do
          point_value > y -> "█"
          point_value == y -> "▓"
          point_value == y - 1 -> "▒"
          point_value == y - 2 -> "░"
          true -> " "
        end
      end

      if frame do
        "│ " <> Enum.join(row) <> " │"
      else
        Enum.join(row)
      end
    end

    if frame do
      top = "╭─" <> String.duplicate("─", width) <> "─╮"
      bottom = "╰─" <> String.duplicate("─", width) <> "─╯"
      [top] ++ rows ++ [bottom]
    else
      rows
    end
  end

  @doc """
  Create a threshold indicator with visual symbols.
  Returns a character indicating status based on thresholds.
  """
  def threshold_indicator(value, opts \\ []) do
    good = Keyword.get(opts, :good, 0)
    warning = Keyword.get(opts, :warning, 50)
    critical = Keyword.get(opts, :critical, 80)
    style = Keyword.get(opts, :style, :symbols)

    case style do
      :symbols ->
        cond do
          value >= critical -> "!"
          value >= warning -> "*"
          value >= good -> "+"
          true -> "-"
        end

      :blocks ->
        cond do
          value >= critical -> "█"
          value >= warning -> "▓"
          value >= good -> "▒"
          true -> "░"
        end

      :dots ->
        cond do
          value >= critical -> "●"
          value >= warning -> "◐"
          value >= good -> "◔"
          true -> "○"
        end

      _ ->
        cond do
          value >= critical -> "!"
          value >= warning -> "*"
          value >= good -> "+"
          true -> "-"
        end
    end
  end

  @doc """
  Create a visual meter with title and gradient bar.

  ## Examples

      iex> AsciiChart.meter("CPU", 75, width: 30)
      "╭─ CPU ─────────────────────╮
       │ █████████████████████▓▒░░░ │
       ╰───────────────────── 75% ─╯"
  """
  def meter(title, value, opts \\ []) do
    width = Keyword.get(opts, :width, 30)
    max_value = Keyword.get(opts, :max, 100)

    # Calculate bar width (account for borders and padding)
    bar_width = width - 4
    bar = bar_chart(value, max: max_value, width: bar_width, gradient: true)

    # Format percentage
    percent = if is_float(value) do
      :erlang.float_to_binary(value, decimals: 1)
    else
      "#{value}.0"
    end

    # Build the meter
    title_padding = max(0, width - String.length(title) - 6)
    top = "╭─ #{title} #{String.duplicate("─", title_padding)}╮"
    mid = "│ #{bar} │"
    bottom_padding = max(0, width - String.length(percent) - 5)
    bottom = "╰#{String.duplicate("─", bottom_padding)} #{percent}% ─╯"

    [top, mid, bottom]
  end

  @doc """
  Showcase all chart types with beautiful gradients and borders.
  Returns a list of strings demonstrating the enhanced visuals.
  """
  def showcase do
    [
      "╭─ ASCII Chart Showcase ────────────────────────────────────────╮",
      "│                                                               │",
      "│  Sparkline (data trends):                                    │",
      "│  #{sparkline([1, 3, 2, 5, 4, 7, 6, 8, 9, 7, 8, 10], width: 40)}                   │",
      "│                                                               │",
      "│  Gradient Bars:                                              │",
      "│  #{percent_bar("Elixir", 92, width: 30, label_width: 10, style: :rounded)}       │",
      "│  #{percent_bar("Phoenix", 88, width: 30, label_width: 10, style: :rounded)}      │",
      "│  #{percent_bar("LiveView", 95, width: 30, label_width: 10, style: :rounded)}     │",
      "│                                                               │",
      "│  Threshold Indicators:                                       │",
      "│  Blocks: #{threshold_indicator(20, style: :blocks)} #{threshold_indicator(60, style: :blocks)} #{threshold_indicator(90, style: :blocks)}  Dots: #{threshold_indicator(20, style: :dots)} #{threshold_indicator(60, style: :dots)} #{threshold_indicator(90, style: :dots)}                    │",
      "│                                                               │",
      "╰───────────────────────────────────────────────────────────────╯"
    ]
  end

  # Private functions

  # Sample data to fit target width
  defp sample_data(data, target_width) when length(data) <= target_width do
    data
  end

  defp sample_data(data, target_width) do
    step = length(data) / target_width

    0..(target_width - 1)
    |> Enum.map(fn i ->
      index = round(i * step)
      Enum.at(data, index, 0)
    end)
  end

  # Normalize data to 0..max_value range
  defp normalize_data([], _max), do: []

  defp normalize_data(data, max_value) do
    min = Enum.min(data)
    max = Enum.max(data)
    range = max - min

    if range == 0 do
      # All values are the same
      Enum.map(data, fn _ -> div(max_value, 2) end)
    else
      Enum.map(data, fn value ->
        round((value - min) / range * max_value)
      end)
    end
  end

  # Convert 0-7 value to block character
  defp value_to_block(0), do: "▁"
  defp value_to_block(1), do: "▂"
  defp value_to_block(2), do: "▃"
  defp value_to_block(3), do: "▄"
  defp value_to_block(4), do: "▅"
  defp value_to_block(5), do: "▆"
  defp value_to_block(6), do: "▇"
  defp value_to_block(7), do: "█"
  defp value_to_block(_), do: "█"

  # Generate gradient tail for bar charts
  defp gradient_tail(0), do: ""
  defp gradient_tail(1), do: "▒"
  defp gradient_tail(2), do: "▓▒"
  defp gradient_tail(3), do: "▓▓▒"
  defp gradient_tail(n) when n > 3, do: "▓▓▒"

  @doc """
  Create a message box with severity indicator.

  Severity levels:
  - :error - █ Red/critical (gradient: █▓▒░)
  - :warning - ▓ Yellow/caution (gradient: ▓▓▒░)
  - :info - ░ Blue/neutral (gradient: ░▒▓█)
  - :success - ▓ Green/positive (gradient: ▓█▓░)

  ## Examples

      message_box("Connection failed", :error)
      message_box("Compiling...", :info)
  """
  def message_box(message, severity \\ :info, opts \\ []) do
    width = Keyword.get(opts, :width, 60)

    {icon, label} = case severity do
      :error -> {"█", "ERROR"}
      :warning -> {"▓", "WARNING"}
      :info -> {"░", "INFO"}
      :success -> {"▓", "SUCCESS"}
    end

    # Wrap message text if needed
    message_lines = wrap_message(message, width - 6)

    # Build box
    top = "╭─ #{icon} #{label} #{String.duplicate("─", max(0, width - String.length(label) - 7))}╮"
    content = Enum.map(message_lines, fn line ->
      "│ #{String.pad_trailing(line, width - 2)} │"
    end)
    bottom = "╰#{String.duplicate("─", width)}╯"

    [top] ++ content ++ [bottom]
  end

  @doc """
  Create a loading spinner frame.
  Cycles through different gradient patterns for animation effect.

  ## Examples

      spinner(0)  # Frame 0
      spinner(1)  # Frame 1
  """
  def spinner(frame \\ 0) do
    frames = [
      "░▒▓█",
      "▒▓█░",
      "▓█░▒",
      "█░▒▓"
    ]

    Enum.at(frames, rem(frame, length(frames)))
  end

  @doc """
  Create a progress indicator with gradient fill.

  ## Examples

      progress(45, 100, label: "Loading")
      # => "╭─ Loading ──────────╮"
      # => "│ █████████▓▓▒░░░░░ │"
      # => "╰────────── 45% ────╯"
  """
  def progress(current, total, opts \\ []) do
    label = Keyword.get(opts, :label, "Progress")
    width = Keyword.get(opts, :width, 30)

    percentage = if total > 0, do: round(current / total * 100), else: 0

    bar_width = width - 4
    bar = bar_chart(percentage, max: 100, width: bar_width, gradient: true)

    title_padding = max(0, width - String.length(label) - 6)
    top = "╭─ #{label} #{String.duplicate("─", title_padding)}╮"
    mid = "│ #{bar} │"
    bottom_padding = max(0, width - 7)
    bottom = "╰#{String.duplicate("─", bottom_padding)} #{percentage}% ─╯"

    [top, mid, bottom]
  end

  @doc """
  Create a suggestion/hint box with rounded borders.

  ## Examples

      suggestion_box("Try 'help' for available commands")
  """
  def suggestion_box(message, opts \\ []) do
    width = Keyword.get(opts, :width, 60)
    icon = Keyword.get(opts, :icon, "▒")

    message_lines = wrap_message(message, width - 6)

    top = "╭─ #{icon} Hint #{String.duplicate("─", max(0, width - 10))}╮"
    content = Enum.map(message_lines, fn line ->
      "│ #{String.pad_trailing(line, width - 2)} │"
    end)
    bottom = "╰#{String.duplicate("─", width)}╯"

    [top] ++ content ++ [bottom]
  end

  # Helper to wrap message text
  defp wrap_message(text, max_width) do
    text
    |> String.split(" ")
    |> Enum.reduce({[], ""}, fn word, {lines, current_line} ->
      test_line = if current_line == "", do: word, else: current_line <> " " <> word

      if String.length(test_line) <= max_width do
        {lines, test_line}
      else
        {lines ++ [current_line], word}
      end
    end)
    |> then(fn {lines, last_line} ->
      if last_line != "", do: lines ++ [last_line], else: lines
    end)
  end

  @doc """
  Create a section transition indicator/breadcrumb.
  Shows current section with gradient styling.

  ## Examples

      section_indicator(:home, :projects)
      # => "░▒▓ Home → Projects ▓▒░"
  """
  def section_indicator(from_section, to_section) do
    from_name = format_section_name(from_section)
    to_name = format_section_name(to_section)
    "░▒▓ #{from_name} → #{to_name} ▓▒░"
  end

  @doc """
  Create a breadcrumb bar showing current location.

  ## Examples

      breadcrumb(:projects)
      # => "╭─ █▓▒░ Projects ░▒▓█ ─╮"
  """
  def breadcrumb(current_section, opts \\ []) do
    width = Keyword.get(opts, :width, 60)
    section_name = format_section_name(current_section)

    # Calculate padding for centered section name
    content = " █▓▒░ #{section_name} ░▒▓█ "
    padding_needed = max(0, width - String.length(content) - 4)
    left_pad = div(padding_needed, 2)
    right_pad = padding_needed - left_pad

    "╭─#{String.duplicate("─", left_pad)}#{content}#{String.duplicate("─", right_pad)}╮"
  end

  @doc """
  Create a navigation hint bar with gradient styling.

  ## Examples

      nav_hint("↑↓ Navigate  Enter Select  : Command")
      # => "│ ▒ ↑↓ Navigate  Enter Select  : Command          │"
  """
  def nav_hint(text, opts \\ []) do
    width = Keyword.get(opts, :width, 60)
    content = " ▒ #{text}"
    padded = String.pad_trailing(content, width - 2)
    "│#{padded}│"
  end

  # Helper to format section names
  defp format_section_name(:home), do: "Home"
  defp format_section_name(:projects), do: "Projects"
  defp format_section_name(:skills), do: "Skills"
  defp format_section_name(:experience), do: "Experience"
  defp format_section_name(:contact), do: "Contact"
  defp format_section_name(:help), do: "Help"
  defp format_section_name(:terminal), do: "Terminal"
  defp format_section_name(:matrix), do: "Matrix"
  defp format_section_name(:ssh), do: "SSH"
  defp format_section_name(:ls), do: "Directory"
  defp format_section_name(:performance), do: "Performance"
  defp format_section_name(:analytics), do: "Analytics"
  defp format_section_name(section), do: section |> to_string() |> String.capitalize()
end
