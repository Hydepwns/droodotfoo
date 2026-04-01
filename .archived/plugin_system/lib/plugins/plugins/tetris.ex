defmodule Droodotfoo.Plugins.Tetris do
  @moduledoc """
  Classic Tetris game - Stack falling tetrominoes to clear lines.

  Guide falling tetromino pieces to complete horizontal lines. Complete lines
  are cleared and award points. The game speeds up as you progress through levels.

  ## Tetrominoes

  Seven classic shapes: I, O, T, S, Z, J, L pieces
  Each piece type displayed in the "Next" preview box

  ## Scoring System

  - 1 line: 100 points
  - 2 lines: 300 points
  - 3 lines: 500 points
  - 4 lines (Tetris): 800 points

  ## Controls

  - **Left/Right Arrow**: Move piece horizontally
  - **Up Arrow**: Rotate piece clockwise
  - **Down Arrow**: Soft drop (move down faster)
  - **Space**: Hard drop (instant drop to bottom)
  - **P**: Pause/Resume
  - **Q**: Quit game
  """

  use Droodotfoo.Plugins.GameBase

  alias Droodotfoo.Plugins.GameUI
  alias Droodotfoo.Plugins.Tetris.{BoardState, PieceLogic, Rendering, Scoring}

  @type state :: %__MODULE__{
          board: BoardState.board(),
          current_piece: PieceLogic.piece_type(),
          next_piece: PieceLogic.piece_type(),
          piece_x: integer(),
          piece_y: integer(),
          score: integer(),
          lines_cleared: integer(),
          level: integer(),
          game_over: boolean(),
          paused: boolean(),
          last_drop: integer(),
          drop_speed: integer()
        }

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

  @initial_drop_speed 800

  @impl true
  def metadata do
    game_metadata(
      "tetris",
      "1.0.0",
      "Classic Tetris - Stack blocks and clear lines",
      "droo.foo",
      ["tetris"]
    )
  end

  @impl true
  def init(_terminal_state) do
    {:ok,
     %__MODULE__{
       board: BoardState.create_empty(),
       current_piece: PieceLogic.random_piece(),
       next_piece: PieceLogic.random_piece(),
       piece_x: div(BoardState.width(), 2) - 1,
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
    handle_movement(state, -1, 0)
  end

  def handle_input("ArrowRight", state, _terminal_state) do
    handle_movement(state, 1, 0)
  end

  def handle_input("ArrowUp", state, _terminal_state) do
    if game_blocked?(state) do
      continue_render(state)
    else
      new_state = rotate_piece(state)
      continue_render(new_state)
    end
  end

  def handle_input("ArrowDown", state, _terminal_state) do
    if game_blocked?(state) do
      continue_render(state)
    else
      new_state = move_piece(state, 0, 1)

      if new_state.piece_y == state.piece_y do
        locked_state = lock_piece(state)
        continue_render(locked_state)
      else
        continue_render(new_state)
      end
    end
  end

  def handle_input(" ", state, _terminal_state) do
    if game_blocked?(state) do
      continue_render(state)
    else
      new_state = hard_drop(state)
      continue_render(new_state)
    end
  end

  def handle_input("p", state, _terminal_state) do
    if state.game_over do
      continue_render(state)
    else
      continue_render(%{state | paused: !state.paused})
    end
  end

  def handle_input("q", _state, _terminal_state) do
    {:exit, ["Exiting Tetris"]}
  end

  def handle_input(_key, state, _terminal_state) do
    continue_render(state)
  end

  @impl true
  def render(state, _terminal_state) do
    status = format_game_status(state)
    width = 64

    [
      GameUI.top_border(width),
      GameUI.title_line("TETRIS", width),
      GameUI.divider(width),
      GameUI.empty_line(width),
      GameUI.content_line(
        "Score: #{String.pad_trailing("#{state.score}", 10)} Lines: #{String.pad_trailing("#{state.lines_cleared}", 5)} Level: #{state.level}",
        width
      ),
      GameUI.content_line("Status: #{String.pad_trailing(status, 20)}", width),
      GameUI.empty_line(width),
      "|    +----------+  +----+                                    |"
    ] ++
      Rendering.render_board_with_piece(state) ++
      [
        "|    +----------+  +----+                                    |",
        GameUI.empty_line(width),
        GameUI.content_line("Controls:", width),
        GameUI.content_line(
          "<- ->: Move   Up: Rotate   Down: Soft Drop   Space: Hard Drop",
          width
        ),
        GameUI.content_line("p: Pause    q: Quit", width),
        GameUI.empty_line(width),
        GameUI.bottom_border(width)
      ]
  end

  @impl true
  def cleanup(_state), do: :ok

  # Private helpers

  defp continue_render(state), do: {:continue, state, render(state, %{})}

  defp handle_movement(state, dx, dy) do
    if game_blocked?(state) do
      continue_render(state)
    else
      new_state = move_piece(state, dx, dy)
      continue_render(new_state)
    end
  end

  defp format_game_status(state) do
    cond do
      state.game_over -> GameUI.format_status(:game_over)
      state.paused -> GameUI.format_status(:paused)
      true -> GameUI.format_status(:playing)
    end
  end

  defp move_piece(state, dx, dy) do
    new_x = state.piece_x + dx
    new_y = state.piece_y + dy
    shape = PieceLogic.get_shape(state.current_piece)

    if BoardState.valid_position?(state.board, shape, new_x, new_y) do
      %{state | piece_x: new_x, piece_y: new_y}
    else
      state
    end
  end

  defp rotate_piece(state) do
    rotated = PieceLogic.rotate(PieceLogic.get_shape(state.current_piece))

    if BoardState.valid_position?(state.board, rotated, state.piece_x, state.piece_y) do
      state
    else
      state
    end
  end

  defp hard_drop(state) do
    new_state = move_piece(state, 0, 1)

    if new_state.piece_y == state.piece_y do
      lock_piece(state)
    else
      hard_drop(new_state)
    end
  end

  defp lock_piece(state) do
    shape = PieceLogic.get_shape(state.current_piece)

    new_board =
      BoardState.place_piece(
        state.board,
        shape,
        state.piece_x,
        state.piece_y,
        state.current_piece
      )

    {cleared_board, lines_count} = BoardState.clear_lines(new_board)

    {new_score, new_lines, new_level, new_speed} =
      Scoring.update_stats(state.score, state.lines_cleared, lines_count)

    next_x = div(BoardState.width(), 2) - 1
    next_y = 0
    new_next = PieceLogic.random_piece()
    next_shape = PieceLogic.get_shape(state.next_piece)

    game_over = not BoardState.valid_position?(cleared_board, next_shape, next_x, next_y)

    %{
      state
      | board: cleared_board,
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
end
