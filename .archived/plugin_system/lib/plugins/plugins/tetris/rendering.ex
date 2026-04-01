defmodule Droodotfoo.Plugins.Tetris.Rendering do
  @moduledoc """
  Board rendering for Tetris display.
  """

  alias Droodotfoo.Plugins.Tetris.{BoardState, PieceLogic}

  @board_width 10
  @board_height 20

  @doc """
  Render the board with the current piece overlaid.
  Returns a list of strings for each row.
  """
  @spec render_board_with_piece(map()) :: [String.t()]
  def render_board_with_piece(state) do
    display_board =
      if state.game_over or state.paused do
        state.board
      else
        BoardState.place_piece(
          state.board,
          PieceLogic.get_shape(state.current_piece),
          state.piece_x,
          state.piece_y,
          state.current_piece
        )
      end

    for y <- 0..(@board_height - 1) do
      render_board_row(display_board, y, state.next_piece)
    end
  end

  @doc """
  Render a single row of the board with the next piece preview.
  """
  @spec render_board_row(BoardState.board(), integer(), PieceLogic.piece_type()) :: String.t()
  def render_board_row(display_board, y, next_piece) do
    row =
      for x <- 0..(@board_width - 1) do
        cell = BoardState.get_cell(display_board, x, y)
        if cell == nil, do: " ", else: "#"
      end

    next_preview =
      if y < 4 do
        render_next_piece_line(next_piece, y)
      else
        "    "
      end

    "|    |" <>
      Enum.join(row, "") <> "|  |" <> next_preview <> "|                                    |"
  end

  @doc """
  Render a line of the next piece preview.
  """
  @spec render_next_piece_line(PieceLogic.piece_type(), integer()) :: String.t()
  def render_next_piece_line(piece, line_num) do
    shape = PieceLogic.get_shape(piece)
    height = PieceLogic.height(shape)

    if line_num < height do
      row = Enum.at(shape, line_num)
      cells = Enum.map(row, &render_piece_cell/1)
      String.pad_trailing(Enum.join(cells, ""), 4)
    else
      "    "
    end
  end

  defp render_piece_cell(1), do: "#"
  defp render_piece_cell(_), do: " "
end
