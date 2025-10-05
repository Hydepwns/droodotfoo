defmodule Droodotfoo.Plugins.TwentyFortyEight do
  @moduledoc """
  2048 - Sliding tile puzzle game.

  Combine tiles with the same number to create larger numbers.
  Goal: Reach the 2048 tile!

  Controls:
  - Arrow Keys: Slide tiles
  - r: Restart game
  - u: Undo last move
  - q: Quit
  """

  use Droodotfoo.Plugins.GameBase
  alias Droodotfoo.Plugins.GameUI

  defstruct [
    :grid,
    :score,
    :best_score,
    :game_over,
    :won,
    :move_history,
    :can_undo
  ]

  @grid_size 4

  @impl true
  def metadata do
    %{
      name: "2048",
      version: "1.0.0",
      description: "2048 - Sliding tile puzzle game",
      author: "droo.foo",
      commands: ["2048", "twenty48"],
      category: :game
    }
  end

  @impl true
  def init(_terminal_state) do
    grid = create_empty_grid()

    grid_with_tiles =
      grid
      |> add_random_tile()
      |> add_random_tile()

    {:ok,
     %__MODULE__{
       grid: grid_with_tiles,
       score: 0,
       best_score: 0,
       game_over: false,
       won: false,
       move_history: [],
       can_undo: false
     }}
  end

  @impl true
  def handle_input("ArrowUp", state, _terminal_state) do
    if game_blocked?(state) do
      {:continue, state, render(state, %{})}
    else
      new_state = make_move(state, :up)
      {:continue, new_state, render(new_state, %{})}
    end
  end

  def handle_input("ArrowDown", state, _terminal_state) do
    if game_blocked?(state) do
      {:continue, state, render(state, %{})}
    else
      new_state = make_move(state, :down)
      {:continue, new_state, render(new_state, %{})}
    end
  end

  def handle_input("ArrowLeft", state, _terminal_state) do
    if game_blocked?(state) do
      {:continue, state, render(state, %{})}
    else
      new_state = make_move(state, :left)
      {:continue, new_state, render(new_state, %{})}
    end
  end

  def handle_input("ArrowRight", state, _terminal_state) do
    if game_blocked?(state) do
      {:continue, state, render(state, %{})}
    else
      new_state = make_move(state, :right)
      {:continue, new_state, render(new_state, %{})}
    end
  end

  def handle_input("r", _state, terminal_state) do
    handle_restart(__MODULE__, terminal_state)
  end

  def handle_input("u", state, _terminal_state) do
    # Undo last move
    if state.can_undo and length(state.move_history) > 0 do
      [previous_state | remaining_history] = state.move_history

      restored_state = %{
        previous_state
        | move_history: remaining_history,
          can_undo: length(remaining_history) > 0
      }

      {:continue, restored_state, render(restored_state, %{})}
    else
      {:continue, state, render(state, %{})}
    end
  end

  def handle_input("q", _state, _terminal_state) do
    {:exit, ["Exiting 2048"]}
  end

  def handle_input(_key, state, _terminal_state) do
    {:continue, state, render(state, %{})}
  end

  @impl true
  def render(state, _terminal_state) do
    status =
      cond do
        state.won and not state.game_over -> "YOU WIN! (Keep playing)"
        state.game_over -> GameUI.format_status(:game_over)
        true -> GameUI.format_status(:playing)
      end

    width = 61

    lines =
      [
        GameUI.top_border(width),
        GameUI.title_line("2048", width),
        GameUI.divider(width),
        GameUI.empty_line(width),
        GameUI.content_line("Score: #{String.pad_trailing("#{state.score}", 10)} Best: #{String.pad_trailing("#{state.best_score}", 10)} Status: #{String.pad_trailing(status, 15)}", width),
        GameUI.empty_line(width),
        "║      ┌──────┬──────┬──────┬──────┐                        ║"
      ] ++
        render_grid(state.grid) ++
        [
          "║      └──────┴──────┴──────┴──────┘                        ║",
          GameUI.empty_line(width),
          GameUI.content_line("Join the numbers to get to 2048!", width),
          GameUI.empty_line(width),
          GameUI.content_line("Controls:", width),
          GameUI.content_line("Arrow Keys: Slide tiles  r: Restart  u: Undo  q: Quit", width),
          GameUI.empty_line(width),
          GameUI.bottom_border(width)
        ]

    lines
  end

  @impl true
  def cleanup(_state) do
    :ok
  end

  # Private helper functions

  defp create_empty_grid do
    create_grid(@grid_size, @grid_size, nil)
  end

  defp add_random_tile(grid) do
    empty_cells = get_empty_cells(grid)

    if empty_cells == [] do
      grid
    else
      {row, col} = Enum.random(empty_cells)
      value = if :rand.uniform() < 0.9, do: 2, else: 4

      List.update_at(grid, row, fn row_data ->
        List.update_at(row_data, col, fn _ -> value end)
      end)
    end
  end

  defp get_empty_cells(grid) do
    for row <- 0..(@grid_size - 1),
        col <- 0..(@grid_size - 1),
        get_cell(grid, row, col) == nil do
      {row, col}
    end
  end

  defp get_cell(grid, row, col) do
    grid |> Enum.at(row, []) |> Enum.at(col)
  end

  defp make_move(state, direction) do
    # Save current state to history
    state_snapshot = %{state | move_history: [], can_undo: false}

    {new_grid, points_earned} = slide_and_merge(state.grid, direction)

    # Check if move changed anything
    if new_grid == state.grid do
      # No change, don't add random tile or update history
      state
    else
      # Add random tile after successful move
      grid_with_new_tile = add_random_tile(new_grid)
      new_score = state.score + points_earned
      new_best = max(new_score, state.best_score)

      # Check win condition (reached 2048)
      won = has_tile_with_value?(grid_with_new_tile, 2048)

      # Check game over condition
      game_over = is_game_over?(grid_with_new_tile)

      %{
        state
        | grid: grid_with_new_tile,
          score: new_score,
          best_score: new_best,
          won: won or state.won,
          game_over: game_over,
          move_history: [state_snapshot | Enum.take(state.move_history, 9)],
          can_undo: true
      }
    end
  end

  defp slide_and_merge(grid, direction) do
    # Rotate grid based on direction (always work with left slide)
    rotated_grid = rotate_grid_for_direction(grid, direction)

    # Slide and merge each row
    {merged_grid, total_points} =
      Enum.map_reduce(rotated_grid, 0, fn row, acc_points ->
        {merged_row, row_points} = slide_and_merge_row(row)
        {merged_row, acc_points + row_points}
      end)

    # Rotate back
    final_grid = rotate_grid_back(merged_grid, direction)

    {final_grid, total_points}
  end

  defp rotate_grid_for_direction(grid, :left), do: grid
  defp rotate_grid_for_direction(grid, :right), do: reverse_rows(grid)
  defp rotate_grid_for_direction(grid, :up), do: transpose(grid)
  defp rotate_grid_for_direction(grid, :down), do: grid |> transpose() |> reverse_rows()

  defp rotate_grid_back(grid, :left), do: grid
  defp rotate_grid_back(grid, :right), do: reverse_rows(grid)
  defp rotate_grid_back(grid, :up), do: transpose(grid)
  defp rotate_grid_back(grid, :down), do: grid |> reverse_rows() |> transpose()

  defp reverse_rows(grid) do
    Enum.map(grid, &Enum.reverse/1)
  end

  defp transpose(grid) do
    grid
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end

  defp slide_and_merge_row(row) do
    # Remove nils and slide left
    non_nil_values = Enum.reject(row, &is_nil/1)

    # Merge adjacent equal values
    {merged_values, points} = merge_values(non_nil_values, [])

    # Pad with nils to maintain row size
    final_row = merged_values ++ List.duplicate(nil, @grid_size - length(merged_values))

    {final_row, points}
  end

  defp merge_values([], acc), do: {Enum.reverse(acc), 0}
  defp merge_values([value], acc), do: {Enum.reverse([value | acc]), 0}

  defp merge_values([first, second | rest], acc) do
    if first == second do
      merged_value = first * 2
      {remaining, points} = merge_values(rest, [merged_value | acc])
      {remaining, points + merged_value}
    else
      merge_values([second | rest], [first | acc])
    end
  end

  defp has_tile_with_value?(grid, value) do
    Enum.any?(grid, fn row ->
      Enum.any?(row, fn cell -> cell == value end)
    end)
  end

  defp is_game_over?(grid) do
    # Game over if no empty cells and no possible merges
    no_empty_cells = get_empty_cells(grid) == []

    if not no_empty_cells do
      false
    else
      # Check if any adjacent tiles can merge
      not has_possible_merge?(grid)
    end
  end

  defp has_possible_merge?(grid) do
    # Check horizontal merges
    horizontal_merge =
      Enum.any?(grid, fn row ->
        row
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.any?(fn [a, b] -> a == b and a != nil end)
      end)

    # Check vertical merges
    vertical_merge =
      grid
      |> transpose()
      |> Enum.any?(fn col ->
        col
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.any?(fn [a, b] -> a == b and a != nil end)
      end)

    horizontal_merge or vertical_merge
  end

  defp render_grid(grid) do
    for row <- grid do
      cells =
        Enum.map(row, fn cell ->
          format_cell(cell)
        end)

      "║      │" <> Enum.join(cells, "│") <> "│                        ║"
    end
  end

  defp format_cell(nil), do: "      "
  defp format_cell(value) when value < 10, do: "   #{value}  "
  defp format_cell(value) when value < 100, do: "  #{value}  "
  defp format_cell(value) when value < 1000, do: "  #{value} "
  defp format_cell(value) when value < 10000, do: " #{value} "
  defp format_cell(value), do: "#{value}"
end
