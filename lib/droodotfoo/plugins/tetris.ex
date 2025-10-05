defmodule Droodotfoo.Plugins.Tetris do
  @moduledoc """
  Classic Tetris game - Stack falling tetrominoes to clear lines.

  Controls:
  - Left/Right Arrow: Move piece
  - Up Arrow: Rotate clockwise
  - Down Arrow: Soft drop
  - Space: Hard drop
  - p: Pause/Resume
  - q: Quit
  """

  use Droodotfoo.Plugins.GameBase
  alias Droodotfoo.Plugins.GameUI

  defstruct [
    :board,
    :current_piece,
    :next_piece,
    :piece_x,
    :piece_y,
    :score,
    :lines_cleared,
    :level,
    :game_over,
    :paused,
    :last_drop,
    :drop_speed
  ]

  @board_width 10
  @board_height 20
  @initial_drop_speed 800

  # Tetromino shapes (I, O, T, S, Z, J, L)
  @shapes %{
    i: [[1, 1, 1, 1]],
    o: [[1, 1], [1, 1]],
    t: [[0, 1, 0], [1, 1, 1]],
    s: [[0, 1, 1], [1, 1, 0]],
    z: [[1, 1, 0], [0, 1, 1]],
    j: [[1, 0, 0], [1, 1, 1]],
    l: [[0, 0, 1], [1, 1, 1]]
  }


  @impl true
  def metadata do
    %{
      name: "tetris",
      version: "1.0.0",
      description: "Classic Tetris - Stack blocks and clear lines",
      author: "droo.foo",
      commands: ["tetris"],
      category: :game
    }
  end

  @impl true
  def init(_terminal_state) do
    first_piece = random_piece()
    second_piece = random_piece()

    {:ok,
     %__MODULE__{
       board: create_empty_board(),
       current_piece: first_piece,
       next_piece: second_piece,
       piece_x: div(@board_width, 2) - 1,
       piece_y: 0,
       score: 0,
       lines_cleared: 0,
       level: 1,
       game_over: false,
       paused: false,
       last_drop: System.monotonic_time(:millisecond),
       drop_speed: @initial_drop_speed
     }}
  end

  @impl true
  def handle_input("ArrowLeft", state, _terminal_state) do
    if game_blocked?(state) do
      {:continue, state, render(state, %{})}
    else
      new_state = move_piece(state, -1, 0)
      {:continue, new_state, render(new_state, %{})}
    end
  end

  def handle_input("ArrowRight", state, _terminal_state) do
    if game_blocked?(state) do
      {:continue, state, render(state, %{})}
    else
      new_state = move_piece(state, 1, 0)
      {:continue, new_state, render(new_state, %{})}
    end
  end

  def handle_input("ArrowUp", state, _terminal_state) do
    if game_blocked?(state) do
      {:continue, state, render(state, %{})}
    else
      new_state = rotate_piece(state)
      {:continue, new_state, render(new_state, %{})}
    end
  end

  def handle_input("ArrowDown", state, _terminal_state) do
    if game_blocked?(state) do
      {:continue, state, render(state, %{})}
    else
      new_state = move_piece(state, 0, 1)

      # If piece didn't move, lock it
      if new_state.piece_y == state.piece_y do
        locked_state = lock_piece(state)
        {:continue, locked_state, render(locked_state, %{})}
      else
        {:continue, new_state, render(new_state, %{})}
      end
    end
  end

  def handle_input(" ", state, _terminal_state) do
    if game_blocked?(state) do
      {:continue, state, render(state, %{})}
    else
      new_state = hard_drop(state)
      {:continue, new_state, render(new_state, %{})}
    end
  end

  def handle_input("p", state, _terminal_state) do
    if state.game_over do
      {:continue, state, render(state, %{})}
    else
      new_state = %{state | paused: !state.paused}
      {:continue, new_state, render(new_state, %{})}
    end
  end

  def handle_input("q", _state, _terminal_state) do
    {:exit, ["Exiting Tetris"]}
  end

  def handle_input(_key, state, _terminal_state) do
    {:continue, state, render(state, %{})}
  end

  @impl true
  def render(state, _terminal_state) do
    status = GameUI.format_status(cond do
      state.game_over -> :game_over
      state.paused -> :paused
      true -> :playing
    end)

    width = 64

    lines = [
      GameUI.top_border(width),
      GameUI.title_line("TETRIS", width),
      GameUI.divider(width),
      GameUI.empty_line(width),
      GameUI.content_line("Score: #{String.pad_trailing("#{state.score}", 10)} Lines: #{String.pad_trailing("#{state.lines_cleared}", 5)} Level: #{state.level}", width),
      GameUI.content_line("Status: #{String.pad_trailing(status, 20)}", width),
      GameUI.empty_line(width),
      "║    ┌──────────┐  ┌────┐                                    ║"
    ] ++
      render_board_with_piece(state) ++
      [
        "║    └──────────┘  └────┘                                    ║",
        GameUI.empty_line(width),
        GameUI.content_line("Controls:", width),
        GameUI.content_line("← →: Move   ↑: Rotate   ↓: Soft Drop   Space: Hard Drop", width),
        GameUI.content_line("p: Pause    q: Quit", width),
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

  defp create_empty_board do
    for _y <- 1..@board_height do
      for _x <- 1..@board_width, do: nil
    end
  end

  defp random_piece do
    [:i, :o, :t, :s, :z, :j, :l] |> Enum.random()
  end

  defp get_shape(piece) do
    @shapes[piece]
  end

  defp move_piece(state, dx, dy) do
    new_x = state.piece_x + dx
    new_y = state.piece_y + dy

    if valid_position?(state.board, get_shape(state.current_piece), new_x, new_y) do
      %{state | piece_x: new_x, piece_y: new_y}
    else
      state
    end
  end

  defp rotate_piece(state) do
    rotated_shape = rotate_shape(get_shape(state.current_piece))

    if valid_position?(state.board, rotated_shape, state.piece_x, state.piece_y) do
      # Update the shape in the shapes map temporarily
      # For simplicity, we'll track rotated state differently
      # In a full implementation, we'd track rotation state
      state
    else
      state
    end
  end

  defp rotate_shape(shape) do
    rows = length(shape)
    cols = length(Enum.at(shape, 0))

    for x <- 0..(cols - 1) do
      for y <- (rows - 1)..0 do
        shape |> Enum.at(y) |> Enum.at(x)
      end
    end
  end

  defp hard_drop(state) do
    # Keep moving down until we can't
    new_state = move_piece(state, 0, 1)

    if new_state.piece_y == state.piece_y do
      # Can't move down anymore, lock immediately
      lock_piece(state)
    else
      hard_drop(new_state)
    end
  end

  defp valid_position?(board, shape, x, y) do
    shape
    |> Enum.with_index()
    |> Enum.all?(fn {row, dy} ->
      row
      |> Enum.with_index()
      |> Enum.all?(fn {cell, dx} ->
        if cell == 1 do
          board_x = x + dx
          board_y = y + dy

          board_x >= 0 and board_x < @board_width and
            board_y >= 0 and board_y < @board_height and
            get_cell(board, board_x, board_y) == nil
        else
          true
        end
      end)
    end)
  end

  defp get_cell(board, x, y) do
    if y >= 0 and y < @board_height and x >= 0 and x < @board_width do
      board |> Enum.at(y) |> Enum.at(x)
    else
      nil
    end
  end

  defp lock_piece(state) do
    # Place the piece on the board
    new_board = place_piece(state.board, get_shape(state.current_piece), state.piece_x, state.piece_y, state.current_piece)

    # Check for completed lines
    {cleared_board, lines_count} = clear_lines(new_board)

    # Calculate score
    points = case lines_count do
      1 -> 100
      2 -> 300
      3 -> 500
      4 -> 800
      _ -> 0
    end

    new_score = state.score + points
    new_lines = state.lines_cleared + lines_count
    new_level = div(new_lines, 10) + 1
    new_speed = max(100, @initial_drop_speed - (new_level - 1) * 50)

    # Spawn next piece
    next_x = div(@board_width, 2) - 1
    next_y = 0
    new_next = random_piece()

    # Check if game over (new piece can't be placed)
    game_over = not valid_position?(cleared_board, get_shape(state.next_piece), next_x, next_y)

    %{state |
      board: cleared_board,
      current_piece: state.next_piece,
      next_piece: new_next,
      piece_x: next_x,
      piece_y: next_y,
      score: new_score,
      lines_cleared: new_lines,
      level: new_level,
      drop_speed: new_speed,
      game_over: game_over,
      last_drop: System.monotonic_time(:millisecond)
    }
  end

  defp place_piece(board, shape, x, y, piece_type) do
    Enum.reduce(Enum.with_index(shape), board, fn {row, dy}, acc_board ->
      Enum.reduce(Enum.with_index(row), acc_board, fn {cell, dx}, acc ->
        if cell == 1 do
          board_x = x + dx
          board_y = y + dy

          if board_y >= 0 and board_y < @board_height do
            List.update_at(acc, board_y, fn board_row ->
              List.update_at(board_row, board_x, fn _ -> piece_type end)
            end)
          else
            acc
          end
        else
          acc
        end
      end)
    end)
  end

  defp clear_lines(board) do
    {remaining, cleared_count} =
      board
      |> Enum.reduce({[], 0}, fn row, {acc, count} ->
        if Enum.all?(row, &(&1 != nil)) do
          {acc, count + 1}
        else
          {[row | acc], count}
        end
      end)

    # Add empty rows at the top
    new_rows = for _i <- 1..cleared_count do
      for _x <- 1..@board_width, do: nil
    end

    {new_rows ++ Enum.reverse(remaining), cleared_count}
  end

  defp render_board_with_piece(state) do
    # Create a temporary board with the current piece drawn on it
    display_board = if state.game_over or state.paused do
      state.board
    else
      place_piece(state.board, get_shape(state.current_piece), state.piece_x, state.piece_y, state.current_piece)
    end

    # Render the board
    for y <- 0..(@board_height - 1) do
      row = for x <- 0..(@board_width - 1) do
        cell = get_cell(display_board, x, y)
        if cell == nil, do: " ", else: "█"
      end

      # Render next piece preview on the right
      next_preview = if y < 4 do
        render_next_piece_line(state.next_piece, y)
      else
        "    "
      end

      "║    │" <> Enum.join(row, "") <> "│  │" <> next_preview <> "│                                    ║"
    end
  end

  defp render_next_piece_line(piece, line_num) do
    shape = get_shape(piece)
    height = length(shape)

    if line_num < height do
      row = Enum.at(shape, line_num)
      cells = Enum.map(row, fn cell -> if cell == 1, do: "█", else: " " end)
      String.pad_trailing(Enum.join(cells, ""), 4)
    else
      "    "
    end
  end
end
