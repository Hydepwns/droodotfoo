defmodule Droodotfoo.CursorTrail do
  @moduledoc """
  Manages a visual trail effect for cursor movement in the terminal.
  The trail fades out over time, creating a smooth visual effect.
  """

  @max_trail_length 8
  @trail_chars ["█", "▒", "░", "·", "·", "·", ".", "."]

  defstruct trail: [],
            last_position: nil,
            fade_timer: nil

  @doc """
  Create a new cursor trail manager
  """
  def new do
    %__MODULE__{
      trail: [],
      last_position: nil,
      fade_timer: nil
    }
  end

  @doc """
  Add a new position to the trail
  """
  def add_position(trail, {row, col}) do
    # Don't add if it's the same as the last position
    if trail.last_position == {row, col} do
      trail
    else
      new_trail =
        [{row, col, @max_trail_length - 1} | trail.trail]
        |> Enum.take(@max_trail_length)

      %{trail | trail: new_trail, last_position: {row, col}}
    end
  end

  @doc """
  Update trail by fading positions (decreasing intensity)
  """
  def fade_trail(%{trail: trail_list} = trail) do
    faded_trail =
      trail_list
      |> Enum.map(fn {row, col, intensity} ->
        if intensity > 0 do
          {row, col, intensity - 1}
        else
          nil
        end
      end)
      |> Enum.filter(&(&1 != nil))

    %{trail | trail: faded_trail}
  end

  @doc """
  Get the trail character for a given position
  Returns nil if no trail at that position
  """
  def get_trail_char(trail, {row, col}) do
    case Enum.find(trail.trail, fn {r, c, _} -> r == row && c == col end) do
      {_, _, intensity} when intensity >= 0 ->
        idx = @max_trail_length - 1 - intensity

        if idx < length(@trail_chars) do
          Enum.at(@trail_chars, idx)
        else
          nil
        end

      _ ->
        nil
    end
  end

  @doc """
  Get all trail positions with their characters and styles
  """
  def get_trail_overlay(trail) do
    trail.trail
    |> Enum.map(fn {row, col, intensity} ->
      idx = @max_trail_length - 1 - intensity
      char = if idx < length(@trail_chars), do: Enum.at(@trail_chars, idx), else: "."

      # Calculate opacity/color based on intensity
      opacity = (intensity + 1) / @max_trail_length
      color = calculate_trail_color(opacity)

      %{
        row: row,
        col: col,
        char: char,
        style: %{
          color: color,
          opacity: opacity
        }
      }
    end)
  end

  @doc """
  Clear the entire trail
  """
  def clear_trail(trail) do
    %{trail | trail: [], last_position: nil}
  end

  @doc """
  Check if a position is part of the trail
  """
  def in_trail?(trail, {row, col}) do
    Enum.any?(trail.trail, fn {r, c, _} -> r == row && c == col end)
  end

  @doc """
  Get the intensity level for a position (0-7, or nil if not in trail)
  """
  def get_intensity(trail, {row, col}) do
    case Enum.find(trail.trail, fn {r, c, _} -> r == row && c == col end) do
      {_, _, intensity} -> intensity
      _ -> nil
    end
  end

  # Private helpers

  defp calculate_trail_color(opacity) when opacity > 0.8, do: :bright_cyan
  defp calculate_trail_color(opacity) when opacity > 0.6, do: :cyan
  defp calculate_trail_color(opacity) when opacity > 0.4, do: :cyan
  defp calculate_trail_color(opacity) when opacity > 0.2, do: :bright_magenta
  defp calculate_trail_color(_), do: :magenta

  @doc """
  Create a trail animation frame for testing
  Returns a list of positions that form a trail pattern
  """
  def demo_trail_pattern(center_row, center_col, frame) do
    # Create a spiral pattern for demo
    positions =
      for i <- 0..(@max_trail_length - 1) do
        angle = (frame + i * 30) * :math.pi() / 180
        r = i * 0.5
        row = round(center_row + r * :math.sin(angle))
        # *2 for terminal aspect ratio
        col = round(center_col + r * :math.cos(angle) * 2)
        {row, col, @max_trail_length - 1 - i}
      end

    %__MODULE__{trail: positions}
  end
end
