defmodule Droodotfoo.Fileverse.DSheet.Formatting do
  @moduledoc """
  Formatting utilities for dSheet display.
  Handles cell value formatting and ASCII table generation.
  """

  @doc """
  Format a cell value for display based on its type.
  """
  def format_cell_value(cell) do
    case cell.type do
      :address -> shorten_address(cell.value)
      :hash -> shorten_hash(cell.value)
      _ -> to_string(cell.value)
    end
  end

  @doc """
  Format sheet as ASCII table for terminal display.
  """
  def format_table(sheet, opts \\ []) do
    max_rows = Keyword.get(opts, :max_rows, 20)
    max_col_width = Keyword.get(opts, :max_col_width, 20)

    col_widths = calculate_column_widths(sheet, max_rows, max_col_width)

    header_row = format_header_row(sheet.headers, col_widths)
    separator = format_separator(col_widths)
    data_rows = format_data_rows(sheet.rows, col_widths, max_rows)
    footer = format_footer(sheet.row_count, max_rows)

    Enum.join([header_row, separator | data_rows], "\n") <> footer
  end

  @doc """
  Shorten an Ethereum address for display.
  """
  def shorten_address(address) when is_binary(address) and byte_size(address) > 12 do
    prefix = String.slice(address, 0..5)
    suffix = String.slice(address, -4..-1//1)
    "#{prefix}...#{suffix}"
  end

  def shorten_address(address), do: to_string(address)

  @doc """
  Shorten a transaction hash for display.
  """
  def shorten_hash(hash) when is_binary(hash) and byte_size(hash) > 12 do
    "#{String.slice(hash, 0..7)}..."
  end

  def shorten_hash(hash), do: to_string(hash)

  @doc """
  Truncate a string to max length with ellipsis.
  """
  def truncate(string, max_length) when is_binary(string) do
    if String.length(string) > max_length do
      String.slice(string, 0, max_length - 3) <> "..."
    else
      string
    end
  end

  def truncate(value, max_length), do: value |> to_string() |> truncate(max_length)

  # Private helpers

  defp calculate_column_widths(sheet, max_rows, max_col_width) do
    sheet.headers
    |> Enum.with_index()
    |> Enum.map(fn {header, idx} ->
      header_width = String.length(header)

      data_width =
        sheet.rows
        |> Enum.take(max_rows)
        |> Enum.map(fn row ->
          cell = Enum.at(row, idx)
          (cell && String.length(to_string(cell.value))) || 0
        end)
        |> Enum.max(fn -> 0 end)

      min(max(header_width, data_width), max_col_width)
    end)
  end

  defp format_header_row(headers, col_widths) do
    headers
    |> Enum.zip(col_widths)
    |> Enum.map_join(" | ", fn {header, width} ->
      String.pad_trailing(truncate(header, width), width)
    end)
  end

  defp format_separator(col_widths) do
    Enum.map_join(col_widths, "-+-", &String.duplicate("-", &1))
  end

  defp format_data_rows(rows, col_widths, max_rows) do
    rows
    |> Enum.take(max_rows)
    |> Enum.map(fn row ->
      row
      |> Enum.zip(col_widths)
      |> Enum.map_join(" | ", fn {cell, width} ->
        value = format_cell_value(cell)
        String.pad_trailing(truncate(value, width), width)
      end)
    end)
  end

  defp format_footer(row_count, max_rows) do
    if row_count > max_rows do
      "\n... #{row_count - max_rows} more rows (#{row_count} total)"
    else
      ""
    end
  end
end
