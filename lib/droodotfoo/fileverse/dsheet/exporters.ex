defmodule Droodotfoo.Fileverse.DSheet.Exporters do
  @moduledoc """
  Export functionality for dSheets.
  Supports CSV and JSON formats.
  """

  @doc """
  Export sheet data to CSV format.
  """
  def to_csv(sheet) do
    header_line = Enum.join(sheet.headers, ",")

    data_lines =
      Enum.map(sheet.rows, fn row ->
        Enum.map_join(row, ",", &format_cell_for_csv/1)
      end)

    csv_content = Enum.join([header_line | data_lines], "\n")
    {:ok, csv_content}
  end

  @doc """
  Export sheet data to JSON format.
  """
  def to_json(sheet) do
    data = %{
      id: sheet.id,
      name: sheet.name,
      owner: sheet.owner,
      description: sheet.description,
      headers: sheet.headers,
      rows: format_rows_for_json(sheet.rows),
      metadata: %{
        row_count: sheet.row_count,
        col_count: sheet.col_count,
        sheet_type: to_string(sheet.sheet_type),
        created_at: DateTime.to_iso8601(sheet.created_at),
        updated_at: DateTime.to_iso8601(sheet.updated_at)
      }
    }

    case Jason.encode(data, pretty: true) do
      {:ok, json} -> {:ok, json}
      {:error, reason} -> {:error, reason}
    end
  end

  defp format_cell_for_csv(cell) do
    value = to_string(cell.value)

    if String.contains?(value, [",", "\""]) do
      "\"#{String.replace(value, "\"", "\"\"")}\""
    else
      value
    end
  end

  defp format_rows_for_json(rows) do
    Enum.map(rows, fn row ->
      Enum.map(row, fn cell ->
        %{value: cell.value, type: to_string(cell.type)}
      end)
    end)
  end
end
