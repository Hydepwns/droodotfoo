defmodule Droodotfoo.Effects.TypingAnimation do
  @moduledoc """
  Typing animation effect for content display.
  """

  # characters per second
  @typing_speed 30

  def calculate_visible_chars(start_time) do
    current_time = System.monotonic_time(:millisecond)
    elapsed_ms = current_time - start_time

    # Calculate how many characters should be visible
    round(elapsed_ms * @typing_speed / 1000)
  end

  def apply_typing_effect(text, visible_chars) do
    if visible_chars >= String.length(text) do
      text
    else
      String.slice(text, 0, visible_chars) <> "_"
    end
  end

  def apply_to_lines(lines, visible_chars) do
    {result, _} =
      Enum.reduce(lines, {[], visible_chars}, fn line, {acc, remaining} ->
        line_length = String.length(line)

        cond do
          remaining <= 0 ->
            {acc, 0}

          remaining >= line_length ->
            {acc ++ [line], remaining - line_length}

          true ->
            visible_line = apply_typing_effect(line, remaining)
            {acc ++ [visible_line], 0}
        end
      end)

    result
  end
end
