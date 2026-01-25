defmodule Droodotfoo.Plugins.Tetris.BoardState do
  @moduledoc """
  Tetris board operations for managing the game grid.
  """

  alias Droodotfoo.Plugins.Tetris.PieceLogic

  @type cell :: PieceLogic.piece_type() | nil
  @type board :: [[cell()]]

  @board_width 10
  @board_height 20

  @doc """
  Create an empty game board.
  """
  @spec create_empty() :: board()
  def create_empty do
    for _y <- 1..@board_height do
      for _x <- 1..@board_width, do: nil
    end
  end

  @doc """
  Get the width of the board.
  """
  @spec width() :: non_neg_integer()
  def width, do: @board_width

  @doc """
  Get the height of the board.
  """
  @spec height() :: non_neg_integer()
  def height, do: @board_height

  @doc """
  Get a cell value at the given position.
  """
  @spec get_cell(board(), integer(), integer()) :: cell()
  def get_cell(board, x, y) do
    if y >= 0 and y < @board_height and x >= 0 and x < @board_width do
      board |> Enum.at(y) |> Enum.at(x)
    else
      nil
    end
  end

  @doc """
  Check if a piece at the given position is valid.
  """
  @spec valid_position?(board(), PieceLogic.shape(), integer(), integer()) :: boolean()
  def valid_position?(board, shape, x, y) do
    shape
    |> Enum.with_index()
    |> Enum.all?(fn {row, dy} ->
      validate_row_position(board, row, x, y + dy)
    end)
  end

  defp validate_row_position(board, row, x, y) do
    row
    |> Enum.with_index()
    |> Enum.all?(fn {cell, dx} ->
      validate_cell_position(board, cell, x + dx, y)
    end)
  end

  defp validate_cell_position(_board, 0, _x, _y), do: true

  defp validate_cell_position(board, 1, x, y) do
    x >= 0 and x < @board_width and
      y >= 0 and y < @board_height and
      get_cell(board, x, y) == nil
  end

  @doc """
  Place a piece on the board.
  """
  @spec place_piece(board(), PieceLogic.shape(), integer(), integer(), PieceLogic.piece_type()) ::
          board()
  def place_piece(board, shape, x, y, piece_type) do
    Enum.reduce(Enum.with_index(shape), board, fn {row, dy}, acc_board ->
      place_piece_row(acc_board, row, x, y + dy, piece_type)
    end)
  end

  defp place_piece_row(board, row, x, y, piece_type) do
    Enum.reduce(Enum.with_index(row), board, fn {cell, dx}, acc ->
      place_piece_cell(acc, cell, x + dx, y, piece_type)
    end)
  end

  defp place_piece_cell(board, 0, _x, _y, _piece_type), do: board

  defp place_piece_cell(board, 1, x, y, piece_type) do
    if y >= 0 and y < @board_height do
      update_cell(board, x, y, piece_type)
    else
      board
    end
  end

  @doc """
  Update a single cell on the board.
  """
  @spec update_cell(board(), integer(), integer(), cell()) :: board()
  def update_cell(board, x, y, value) do
    List.update_at(board, y, fn board_row ->
      List.update_at(board_row, x, fn _ -> value end)
    end)
  end

  @doc """
  Clear completed lines and return the new board with line count.
  """
  @spec clear_lines(board()) :: {board(), non_neg_integer()}
  def clear_lines(board) do
    {remaining, cleared_count} =
      board
      |> Enum.reduce({[], 0}, fn row, {acc, count} ->
        if Enum.all?(row, &(&1 != nil)) do
          {acc, count + 1}
        else
          {[row | acc], count}
        end
      end)

    new_rows =
      for _i <- 1..cleared_count do
        for _x <- 1..@board_width, do: nil
      end

    {new_rows ++ Enum.reverse(remaining), cleared_count}
  end
end
