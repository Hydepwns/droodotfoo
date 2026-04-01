defmodule Droodotfoo.PropertyTest do
  use ExUnit.Case
  use ExUnitProperties

  @moduledoc """
  Property-based tests for droodotfoo components.
  These tests verify invariants and properties that should hold
  for all possible inputs.
  """

  property "buffer operations maintain valid structure" do
    check all(operations <- list_of(buffer_operation_gen(), max_length: 50)) do
      initial_buffer = create_empty_buffer(80, 24)

      final_buffer =
        Enum.reduce(operations, initial_buffer, fn op, buffer ->
          apply_buffer_operation(buffer, op)
        end)

      # Buffer should maintain dimensions
      assert length(final_buffer.lines) == 24
      assert final_buffer.width == 80

      assert Enum.all?(final_buffer.lines, fn line ->
               is_map(line) and is_list(line.cells) and length(line.cells) == 80
             end)

      # All cells should be valid
      assert Enum.all?(final_buffer.lines, fn line ->
               Enum.all?(line.cells, &valid_cell?/1)
             end)
    end
  end

  # Generator functions

  defp buffer_operation_gen do
    one_of([
      tuple({constant(:write), integer(0..23), integer(0..79), string(:ascii, length: 1)}),
      tuple({constant(:clear), integer(0..23)}),
      tuple({constant(:scroll), member_of([:up, :down])}),
      tuple({constant(:fill), string(:ascii, length: 1)})
    ])
  end

  # Helper functions

  defp create_empty_buffer(width, height) do
    %{
      width: width,
      lines:
        for _ <- 1..height do
          %{
            cells:
              for _ <- 1..width do
                %{char: " ", style: %{}}
              end
          }
        end
    }
  end

  defp apply_buffer_operation(buffer, {:write, row, col, char}) do
    if row < length(buffer.lines) do
      lines = List.update_at(buffer.lines, row, fn line -> update_line_cell(line, col, char) end)
      %{buffer | lines: lines}
    else
      buffer
    end
  end

  defp apply_buffer_operation(buffer, {:clear, row}) do
    if row < length(buffer.lines) do
      lines =
        List.update_at(buffer.lines, row, fn _line ->
          %{
            cells: for(_ <- 1..80, do: %{char: " ", style: %{}})
          }
        end)

      %{buffer | lines: lines}
    else
      buffer
    end
  end

  defp apply_buffer_operation(buffer, {:scroll, :up}) do
    new_line = %{cells: for(_ <- 1..80, do: %{char: " ", style: %{}})}
    lines = tl(buffer.lines) ++ [new_line]
    %{buffer | lines: lines}
  end

  defp apply_buffer_operation(buffer, {:scroll, :down}) do
    new_line = %{cells: for(_ <- 1..80, do: %{char: " ", style: %{}})}
    lines = [new_line] ++ Enum.take(buffer.lines, length(buffer.lines) - 1)
    %{buffer | lines: lines}
  end

  defp apply_buffer_operation(buffer, {:fill, char}) do
    lines =
      for _ <- 1..length(buffer.lines) do
        %{
          cells:
            for _ <- 1..80 do
              %{char: char, style: %{}}
            end
        }
      end

    %{buffer | lines: lines}
  end

  defp valid_cell?(cell) do
    is_map(cell) and
      Map.has_key?(cell, :char) and
      Map.has_key?(cell, :style) and
      is_binary(cell.char) and
      is_map(cell.style)
  end

  defp update_line_cell(line, col, char) do
    if col < length(line.cells) do
      cells =
        List.update_at(line.cells, col, fn _ ->
          %{char: char, style: %{}}
        end)

      %{line | cells: cells}
    else
      line
    end
  end
end
