defmodule Droodotfoo.Ascii.Boxes do
  @moduledoc """
  Bordered container rendering for ASCII UI elements.
  Provides message boxes, meters, progress bars, and suggestion boxes.
  """

  alias Droodotfoo.AsciiChart

  @doc """
  Create a message box with severity indicator.

  Severity levels:
  - :error - Critical status
  - :warning - Caution status
  - :info - Neutral status
  - :success - Positive status

  ## Options
  - `:width` - Box width (default: 60)
  """
  @spec message_box(String.t(), atom(), keyword()) :: [String.t()]
  def message_box(message, severity \\ :info, opts \\ []) do
    width = Keyword.get(opts, :width, 60)

    {icon, label} = severity_display(severity)
    message_lines = wrap_message(message, width - 6)

    top =
      "+-  #{icon} #{label} #{String.duplicate("-", max(0, width - String.length(label) - 7))}+"

    content =
      Enum.map(message_lines, fn line ->
        "| #{String.pad_trailing(line, width - 2)} |"
      end)

    bottom = "+#{String.duplicate("-", width)}+"

    [top] ++ content ++ [bottom]
  end

  @doc """
  Create a visual meter with title and gradient bar.

  ## Options
  - `:width` - Meter width (default: 30)
  - `:max` - Maximum value (default: 100)
  """
  @spec meter(String.t(), number(), keyword()) :: [String.t()]
  def meter(title, value, opts \\ []) do
    width = Keyword.get(opts, :width, 30)
    max_value = Keyword.get(opts, :max, 100)

    bar_width = width - 4
    bar = AsciiChart.bar_chart(value, max: max_value, width: bar_width, gradient: true)

    percent = format_percent(value)

    title_padding = max(0, width - String.length(title) - 6)
    top = "+- #{title} #{String.duplicate("-", title_padding)}+"
    mid = "| #{bar} |"
    bottom_padding = max(0, width - String.length(percent) - 5)
    bottom = "+#{String.duplicate("-", bottom_padding)} #{percent}% -+"

    [top, mid, bottom]
  end

  @doc """
  Create a progress indicator with gradient fill.

  ## Options
  - `:label` - Progress label (default: "Progress")
  - `:width` - Box width (default: 30)
  """
  @spec progress(number(), number(), keyword()) :: [String.t()]
  def progress(current, total, opts \\ []) do
    label = Keyword.get(opts, :label, "Progress")
    width = Keyword.get(opts, :width, 30)

    percentage = if total > 0, do: round(current / total * 100), else: 0

    bar_width = width - 4
    bar = AsciiChart.bar_chart(percentage, max: 100, width: bar_width, gradient: true)

    title_padding = max(0, width - String.length(label) - 6)
    top = "+- #{label} #{String.duplicate("-", title_padding)}+"
    mid = "| #{bar} |"
    bottom_padding = max(0, width - 7)
    bottom = "+#{String.duplicate("-", bottom_padding)} #{percentage}% -+"

    [top, mid, bottom]
  end

  @doc """
  Create a suggestion/hint box with rounded borders.

  ## Options
  - `:width` - Box width (default: 60)
  - `:icon` - Icon character (default: "+")
  """
  @spec suggestion_box(String.t(), keyword()) :: [String.t()]
  def suggestion_box(message, opts \\ []) do
    width = Keyword.get(opts, :width, 60)
    icon = Keyword.get(opts, :icon, "+")

    message_lines = wrap_message(message, width - 6)

    top = "+- #{icon} Hint #{String.duplicate("-", max(0, width - 10))}+"

    content =
      Enum.map(message_lines, fn line ->
        "| #{String.pad_trailing(line, width - 2)} |"
      end)

    bottom = "+#{String.duplicate("-", width)}+"

    [top] ++ content ++ [bottom]
  end

  # Private helpers

  defp severity_display(:error), do: {"!", "ERROR"}
  defp severity_display(:warning), do: {"*", "WARNING"}
  defp severity_display(:info), do: {"-", "INFO"}
  defp severity_display(:success), do: {"+", "SUCCESS"}

  defp format_percent(value) when is_float(value) do
    :erlang.float_to_binary(value, decimals: 1)
  end

  defp format_percent(value), do: "#{value}.0"

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
end
