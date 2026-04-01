defmodule Droodotfoo.Plugins.Tetris.PieceLogic do
  @moduledoc """
  Tetromino piece shapes and rotation logic.
  """

  @type piece_type :: :i | :o | :t | :s | :z | :j | :l
  @type shape :: [[integer()]]

  @shapes %{
    i: [[1, 1, 1, 1]],
    o: [[1, 1], [1, 1]],
    t: [[0, 1, 0], [1, 1, 1]],
    s: [[0, 1, 1], [1, 1, 0]],
    z: [[1, 1, 0], [0, 1, 1]],
    j: [[1, 0, 0], [1, 1, 1]],
    l: [[0, 0, 1], [1, 1, 1]]
  }

  @piece_types [:i, :o, :t, :s, :z, :j, :l]

  @doc """
  Get the shape matrix for a piece type.
  """
  @spec get_shape(piece_type()) :: shape()
  def get_shape(piece), do: @shapes[piece]

  @doc """
  Get a random piece type.
  """
  @spec random_piece() :: piece_type()
  def random_piece, do: Enum.random(@piece_types)

  @doc """
  Rotate a shape 90 degrees clockwise.
  """
  @spec rotate(shape()) :: shape()
  def rotate(shape) do
    rows = length(shape)
    cols = length(Enum.at(shape, 0))

    for x <- 0..(cols - 1) do
      for y <- (rows - 1)..0//-1 do
        shape |> Enum.at(y) |> Enum.at(x)
      end
    end
  end

  @doc """
  Get the width of a shape.
  """
  @spec width(shape()) :: non_neg_integer()
  def width(shape), do: shape |> Enum.at(0) |> length()

  @doc """
  Get the height of a shape.
  """
  @spec height(shape()) :: non_neg_integer()
  def height(shape), do: length(shape)
end
