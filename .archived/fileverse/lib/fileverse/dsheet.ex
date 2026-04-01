defmodule Droodotfoo.Fileverse.DSheet do
  @moduledoc """
  Fileverse dSheets integration for onchain data visualization.

  Provides spreadsheet-like views of blockchain data including:
  - ERC-20 token balances
  - NFT metadata collections
  - Transaction history
  - Contract state data

  Note: Full implementation requires Fileverse dSheets API integration.
  This is a stub implementation demonstrating the architecture.
  """

  alias Droodotfoo.Fileverse.DSheet.{
    Exporters,
    Formatting,
    Headers,
    MockData,
    Queries,
    Validation
  }

  @type cell :: %{
          value: any(),
          type: :text | :number | :address | :hash | :date,
          format: String.t() | nil
        }

  @type row :: [cell()]

  @type sheet :: %{
          id: String.t(),
          name: String.t(),
          owner: String.t(),
          description: String.t(),
          headers: [String.t()],
          rows: [row()],
          row_count: integer(),
          col_count: integer(),
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          sheet_type: :token_balances | :nft_collection | :transactions | :custom
        }

  @doc """
  Create a new dSheet.
  """
  @spec create(String.t(), keyword()) :: {:ok, sheet()} | {:error, atom()}
  def create(name, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)
    sheet_type = Keyword.get(opts, :sheet_type, :custom)
    description = Keyword.get(opts, :description, "")

    Validation.with_wallet(wallet_address, fn wallet ->
      headers = Headers.for_type(sheet_type)

      sheet = %{
        id: "sheet_" <> generate_id(),
        name: name,
        owner: wallet,
        description: description,
        headers: headers,
        rows: [],
        row_count: 0,
        col_count: length(headers),
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        sheet_type: sheet_type
      }

      {:ok, sheet}
    end)
  end

  @doc """
  Get a sheet by ID.
  """
  @spec get(String.t(), String.t()) :: {:ok, sheet()} | {:error, atom()}
  def get(sheet_id, wallet_address) do
    Validation.with_wallet(wallet_address, fn wallet ->
      if Validation.valid_sheet_id?(sheet_id) do
        {:ok, MockData.generate_sheet(sheet_id, wallet)}
      else
        {:error, :not_found}
      end
    end)
  end

  @doc """
  List sheets for a wallet address.
  """
  @spec list(String.t()) :: {:ok, [sheet()]} | {:error, atom()}
  def list(wallet_address) do
    Validation.with_wallet(wallet_address, fn wallet ->
      {:ok, MockData.generate_sheet_list(wallet)}
    end)
  end

  @doc """
  Query blockchain data and create a sheet from it.
  """
  @spec query(atom(), map(), keyword()) :: {:ok, sheet()} | {:error, atom()}
  def query(query_type, params, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)

    Validation.with_wallet(wallet_address, fn wallet ->
      Queries.execute(query_type, params, wallet)
    end)
  end

  @doc """
  Filter sheet rows based on criteria.
  """
  @spec filter(sheet(), (row() -> boolean())) :: {:ok, sheet()}
  def filter(sheet, filter_fn) when is_function(filter_fn, 1) do
    filtered_rows = Enum.filter(sheet.rows, filter_fn)

    {:ok, %{sheet | rows: filtered_rows, row_count: length(filtered_rows)}}
  end

  @doc """
  Sort sheet rows by column index.
  """
  @spec sort(sheet(), integer(), :asc | :desc) :: {:ok, sheet()}
  def sort(sheet, col_index, direction \\ :asc) do
    sorted_rows =
      Enum.sort_by(
        sheet.rows,
        fn row ->
          cell = Enum.at(row, col_index)
          cell && cell.value
        end,
        direction
      )

    {:ok, %{sheet | rows: sorted_rows}}
  end

  @doc """
  Export sheet data to CSV format.
  """
  @spec export_csv(sheet()) :: {:ok, String.t()}
  defdelegate export_csv(sheet), to: Exporters, as: :to_csv

  @doc """
  Export sheet data to JSON format.
  """
  @spec export_json(sheet()) :: {:ok, String.t()} | {:error, atom()}
  defdelegate export_json(sheet), to: Exporters, as: :to_json

  @doc """
  Format sheet as ASCII table for terminal display.
  """
  @spec format_table(sheet(), keyword()) :: String.t()
  defdelegate format_table(sheet, opts \\ []), to: Formatting

  # Private

  defp generate_id do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end
end
