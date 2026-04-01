defmodule Droodotfoo.Plugins.Tetris.Scoring do
  @moduledoc """
  Scoring system for Tetris.
  """

  @initial_drop_speed 800

  @doc """
  Calculate points for clearing lines.

  - 1 line: 100 points
  - 2 lines: 300 points
  - 3 lines: 500 points
  - 4 lines (Tetris): 800 points
  """
  @spec points_for_lines(non_neg_integer()) :: non_neg_integer()
  def points_for_lines(1), do: 100
  def points_for_lines(2), do: 300
  def points_for_lines(3), do: 500
  def points_for_lines(4), do: 800
  def points_for_lines(_), do: 0

  @doc """
  Calculate level from total lines cleared.
  Level increases every 10 lines.
  """
  @spec level_for_lines(non_neg_integer()) :: non_neg_integer()
  def level_for_lines(lines_cleared), do: div(lines_cleared, 10) + 1

  @doc """
  Calculate drop speed for a given level.
  Speed decreases by 50ms per level (min 100ms).
  """
  @spec speed_for_level(non_neg_integer()) :: non_neg_integer()
  def speed_for_level(level) do
    max(100, @initial_drop_speed - (level - 1) * 50)
  end

  @doc """
  Update score stats after clearing lines.
  Returns {new_score, new_lines, new_level, new_speed}.
  """
  @spec update_stats(non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
          {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()}
  def update_stats(current_score, current_lines, lines_cleared) do
    points = points_for_lines(lines_cleared)
    new_score = current_score + points
    new_lines = current_lines + lines_cleared
    new_level = level_for_lines(new_lines)
    new_speed = speed_for_level(new_level)

    {new_score, new_lines, new_level, new_speed}
  end
end
