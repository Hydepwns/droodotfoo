defmodule Droodotfoo.AsciiChart do
  @moduledoc """
  ASCII chart rendering utilities for terminal visualization.
  Generates sparklines, bar charts, and other visualizations.
  """

  alias Droodotfoo.Ascii.{Boxes, Navigation, ThresholdIndicator}

  # Delegate to extracted modules
  defdelegate message_box(message, severity \\ :info, opts \\ []), to: Boxes
  defdelegate meter(title, value, opts \\ []), to: Boxes
  defdelegate progress(current, total, opts \\ []), to: Boxes
  defdelegate suggestion_box(message, opts \\ []), to: Boxes

  defdelegate section_indicator(from_section, to_section), to: Navigation
  defdelegate breadcrumb(current_section, opts \\ []), to: Navigation
  defdelegate nav_hint(text, opts \\ []), to: Navigation

  @doc """
  Generate a sparkline from a list of values.
  Returns a string of block characters representing the data.

  ## Options
  - `:width` - Width of the sparkline (default: length of data)
  - `:height` - Height levels (default: 8 for full block characters)

  ## Examples

      iex> AsciiChart.sparkline([1, 2, 3, 4, 5])
      "_.-=^"
  """
  def sparkline(data, opts \\ [])
  def sparkline([], _opts), do: ""
  def sparkline([_single], _opts), do: "-"

  def sparkline(data, opts) do
    width = Keyword.get(opts, :width, length(data))

    data
    |> sample_data(width)
    |> normalize_data(7)
    |> Enum.map_join("", &value_to_block/1)
  end

  @doc """
  Generate a horizontal bar chart with gradient effect.

  ## Examples

      iex> AsciiChart.bar_chart(75, max: 100, width: 20)
      "################===."
  """
  def bar_chart(value, opts \\ []) do
    max_value = Keyword.get(opts, :max, 100)
    width = Keyword.get(opts, :width, 20)
    gradient = Keyword.get(opts, :gradient, false)

    filled = round(value / max_value * width)
    filled = min(filled, width)
    empty = width - filled

    if gradient do
      full_chars = max(0, filled - 3)
      gradient_chars = min(3, filled)

      full = String.duplicate("#", full_chars)
      grad = gradient_tail(gradient_chars)
      empty_str = String.duplicate(".", empty)

      full <> grad <> empty_str
    else
      String.duplicate("#", filled) <> String.duplicate(".", empty)
    end
  end

  @doc """
  Generate a percentage bar with label and optional gradient.

  ## Examples

      iex> AsciiChart.percent_bar("Memory", 65.5, width: 30)
      "Memory     [####################===.........]  65.5%"
  """
  def percent_bar(label, value, opts \\ []) do
    width = Keyword.get(opts, :width, 20)
    label_width = Keyword.get(opts, :label_width, 10)
    gradient = Keyword.get(opts, :gradient, true)
    style = Keyword.get(opts, :style, :rounded)

    padded_label = String.pad_trailing(label, label_width)
    bar = bar_chart(value, max: 100, width: width, gradient: gradient)

    percent = format_percent(value)

    {left, right} = bracket_style(style)

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

    data
    |> sample_data(width)
    |> normalize_data(height - 1)
    |> build_chart_rows(width, height, frame)
    |> maybe_add_frame(width, frame)
  end

  @doc """
  Create a threshold indicator with visual symbols.
  Returns a character indicating status based on thresholds.
  """
  def threshold_indicator(value, opts \\ []) do
    ThresholdIndicator.render(value, opts)
  end

  @doc """
  Showcase all chart types with beautiful gradients and borders.
  Returns a list of strings demonstrating the enhanced visuals.
  """
  def showcase do
    [
      "+- ASCII Chart Showcase ------------------------------------------------+",
      "|                                                                       |",
      "|  Sparkline (data trends):                                             |",
      "|  #{sparkline([1, 3, 2, 5, 4, 7, 6, 8, 9, 7, 8, 10], width: 40)}                            |",
      "|                                                                       |",
      "|  Gradient Bars:                                                       |",
      "|  #{percent_bar("Elixir", 92, width: 30, label_width: 10, style: :rounded)}        |",
      "|  #{percent_bar("Phoenix", 88, width: 30, label_width: 10, style: :rounded)}       |",
      "|  #{percent_bar("LiveView", 95, width: 30, label_width: 10, style: :rounded)}      |",
      "|                                                                       |",
      "|  Threshold Indicators:                                                |",
      "|  Blocks: #{threshold_indicator(20, style: :blocks)} #{threshold_indicator(60, style: :blocks)} #{threshold_indicator(90, style: :blocks)}  Dots: #{threshold_indicator(20, style: :dots)} #{threshold_indicator(60, style: :dots)} #{threshold_indicator(90, style: :dots)}                         |",
      "|                                                                       |",
      "+-----------------------------------------------------------------------+"
    ]
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
      ".=#*",
      "=#*.",
      "#*. ",
      "*. ="
    ]

    Enum.at(frames, rem(frame, length(frames)))
  end

  # Private functions

  defp sample_data(data, target_width) when length(data) <= target_width, do: data

  defp sample_data(data, target_width) do
    step = length(data) / target_width

    0..(target_width - 1)
    |> Enum.map(fn i ->
      index = round(i * step)
      Enum.at(data, index, 0)
    end)
  end

  defp normalize_data([], _max), do: []

  defp normalize_data(data, max_value) do
    min = Enum.min(data)
    max = Enum.max(data)
    range = max - min

    if range == 0 do
      Enum.map(data, fn _ -> div(max_value, 2) end)
    else
      Enum.map(data, fn value ->
        round((value - min) / range * max_value)
      end)
    end
  end

  defp value_to_block(0), do: "_"
  defp value_to_block(1), do: "."
  defp value_to_block(2), do: "-"
  defp value_to_block(3), do: "="
  defp value_to_block(4), do: "+"
  defp value_to_block(5), do: "*"
  defp value_to_block(6), do: "#"
  defp value_to_block(7), do: "^"
  defp value_to_block(_), do: "^"

  defp gradient_tail(0), do: ""
  defp gradient_tail(1), do: "="
  defp gradient_tail(2), do: "=+"
  defp gradient_tail(3), do: "==+"
  defp gradient_tail(n) when n > 3, do: "==+"

  defp build_chart_rows(normalized, width, height, frame) do
    for y <- (height - 1)..0//-1 do
      row = build_chart_row(normalized, width, y)
      format_chart_row(row, frame)
    end
  end

  defp build_chart_row(normalized, width, y) do
    for x <- 0..(width - 1) do
      point_value = Enum.at(normalized, x, 0)
      gradient_char_for_point(point_value, y)
    end
  end

  defp gradient_char_for_point(point_value, y) do
    cond do
      point_value > y -> "#"
      point_value == y -> "="
      point_value == y - 1 -> "+"
      point_value == y - 2 -> "."
      true -> " "
    end
  end

  defp format_chart_row(row, true), do: "| " <> Enum.join(row) <> " |"
  defp format_chart_row(row, false), do: Enum.join(row)

  defp maybe_add_frame(rows, width, true) do
    top = "+-" <> String.duplicate("-", width) <> "-+"
    bottom = "+-" <> String.duplicate("-", width) <> "-+"
    [top] ++ rows ++ [bottom]
  end

  defp maybe_add_frame(rows, _width, false), do: rows

  defp format_percent(value) when is_float(value) do
    :erlang.float_to_binary(value, decimals: 1)
  end

  defp format_percent(value), do: "#{value}.0"

  defp bracket_style(:rounded), do: {"[", "]"}
  defp bracket_style(:square), do: {"[", "]"}
  defp bracket_style(:double), do: {"[", "]"}
  defp bracket_style(_), do: {"[", "]"}
end
