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
  Generate a horizontal bar chart.

  ## Examples

      iex> AsciiChart.bar_chart(75, max: 100, width: 20)
      "███████████████░░░░░"
  """
  def bar_chart(value, opts \\ []) do
    max_value = Keyword.get(opts, :max, 100)
    width = Keyword.get(opts, :width, 20)

    filled = round(value / max_value * width)
    filled = min(filled, width)
    empty = width - filled

    String.duplicate("█", filled) <> String.duplicate("░", empty)
  end

  @doc """
  Generate a percentage bar with label.

  ## Examples

      iex> AsciiChart.percent_bar("Memory", 65.5, width: 30)
      "Memory     [████████████████████░░░░░░░░░░] 65.5%"
  """
  def percent_bar(label, value, opts \\ []) do
    width = Keyword.get(opts, :width, 20)
    label_width = Keyword.get(opts, :label_width, 10)

    padded_label = String.pad_trailing(label, label_width)
    bar = bar_chart(value, max: 100, width: width)

    # Handle both integers and floats
    percent = if is_float(value) do
      :erlang.float_to_binary(value, decimals: 1)
    else
      "#{value}.0"
    end

    "#{padded_label} [#{bar}] #{percent}%"
  end

  @doc """
  Generate a mini line chart with axes.

  ## Examples

      iex> AsciiChart.line_chart([10, 20, 15, 25, 30], width: 20, height: 5)
  """
  def line_chart(data, opts \\ []) do
    width = Keyword.get(opts, :width, 40)
    height = Keyword.get(opts, :height, 8)

    sampled = sample_data(data, width)
    normalized = normalize_data(sampled, height - 1)

    # Build chart from top to bottom
    for y <- (height - 1)..0 do
      row = for x <- 0..(width - 1) do
        point_value = Enum.at(normalized, x, 0)
        cond do
          point_value > y -> "▄"
          point_value == y -> "▄"
          true -> " "
        end
      end

      Enum.join(row)
    end
  end

  @doc """
  Create a threshold indicator.
  Returns a character indicating status based on thresholds.
  """
  def threshold_indicator(value, opts \\ []) do
    good = Keyword.get(opts, :good, 0)
    warning = Keyword.get(opts, :warning, 50)
    critical = Keyword.get(opts, :critical, 80)

    cond do
      value >= critical -> "!"
      value >= warning -> "*"
      value >= good -> "+"
      true -> "-"
    end
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
end
