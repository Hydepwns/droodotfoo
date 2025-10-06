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

  require Logger

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

  ## Parameters

  - `name`: Sheet name
  - `opts`: Keyword list of options
    - `:wallet_address` - Owner's wallet address (required)
    - `:sheet_type` - Type of sheet (:token_balances, :nft_collection, etc.)
    - `:description` - Sheet description

  ## Examples

      iex> DSheet.create("My Tokens", wallet_address: "0x...", sheet_type: :token_balances)
      {:ok, %{id: "sheet_123", name: "My Tokens", ...}}

  """
  @spec create(String.t(), keyword()) :: {:ok, sheet()} | {:error, atom()}
  def create(name, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)
    sheet_type = Keyword.get(opts, :sheet_type, :custom)
    description = Keyword.get(opts, :description, "")

    if is_nil(wallet_address) do
      {:error, :wallet_required}
    else
      headers = default_headers_for_type(sheet_type)

      sheet = %{
        id: "sheet_" <> generate_id(),
        name: name,
        owner: wallet_address,
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
    end
  end

  @doc """
  Get a sheet by ID.

  ## Examples

      iex> DSheet.get("sheet_123", "0x...")
      {:ok, %{id: "sheet_123", name: "My Tokens", ...}}

  """
  @spec get(String.t(), String.t()) :: {:ok, sheet()} | {:error, atom()}
  def get(sheet_id, wallet_address) do
    if is_nil(wallet_address) do
      {:error, :wallet_required}
    else
      # Mock implementation with sample data
      case String.starts_with?(sheet_id, "sheet_") do
        true ->
          sheet = generate_mock_sheet(sheet_id, wallet_address)
          {:ok, sheet}

        false ->
          {:error, :not_found}
      end
    end
  end

  @doc """
  List sheets for a wallet address.

  ## Examples

      iex> DSheet.list("0x...")
      {:ok, [%{id: "sheet_123", name: "My Tokens", ...}]}

  """
  @spec list(String.t()) :: {:ok, [sheet()]} | {:error, atom()}
  def list(wallet_address) do
    if is_nil(wallet_address) do
      {:error, :wallet_required}
    else
      # Mock sheets
      sheets = [
        %{
          id: "sheet_001",
          name: "Token Portfolio",
          owner: wallet_address,
          description: "ERC-20 token balances with USD values",
          row_count: 8,
          col_count: 6,
          created_at: DateTime.utc_now() |> DateTime.add(-86400, :second),
          updated_at: DateTime.utc_now() |> DateTime.add(-3600, :second),
          sheet_type: :token_balances
        },
        %{
          id: "sheet_002",
          name: "NFT Collection",
          owner: wallet_address,
          description: "NFT holdings with metadata",
          row_count: 12,
          col_count: 5,
          created_at: DateTime.utc_now() |> DateTime.add(-172800, :second),
          updated_at: DateTime.utc_now(),
          sheet_type: :nft_collection
        },
        %{
          id: "sheet_003",
          name: "Recent Transactions",
          owner: wallet_address,
          description: "Last 20 transactions",
          row_count: 20,
          col_count: 7,
          created_at: DateTime.utc_now() |> DateTime.add(-259200, :second),
          updated_at: DateTime.utc_now() |> DateTime.add(-1800, :second),
          sheet_type: :transactions
        }
      ]

      {:ok, sheets}
    end
  end

  @doc """
  Query blockchain data and create a sheet from it.

  ## Parameters

  - `query_type`: Type of query (:token_balances, :nft_holdings, :transactions, :contract_state)
  - `params`: Query parameters (contract address, token IDs, etc.)
  - `opts`: Options including wallet_address

  ## Examples

      iex> DSheet.query(:token_balances, %{address: "0x..."}, wallet_address: "0x...")
      {:ok, sheet}

  """
  @spec query(atom(), map(), keyword()) :: {:ok, sheet()} | {:error, atom()}
  def query(query_type, params, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)

    if is_nil(wallet_address) do
      {:error, :wallet_required}
    else
      case query_type do
        :token_balances ->
          query_token_balances(params, wallet_address)

        :nft_holdings ->
          query_nft_holdings(params, wallet_address)

        :transactions ->
          query_transactions(params, wallet_address)

        :contract_state ->
          query_contract_state(params, wallet_address)

        _ ->
          {:error, :invalid_query_type}
      end
    end
  end

  @doc """
  Filter sheet rows based on criteria.

  ## Examples

      iex> DSheet.filter(sheet, fn row -> row.value > 100 end)
      {:ok, filtered_sheet}

  """
  @spec filter(sheet(), (row() -> boolean())) :: {:ok, sheet()}
  def filter(sheet, filter_fn) when is_function(filter_fn, 1) do
    filtered_rows = Enum.filter(sheet.rows, filter_fn)

    filtered_sheet = %{
      sheet
      | rows: filtered_rows,
        row_count: length(filtered_rows)
    }

    {:ok, filtered_sheet}
  end

  @doc """
  Sort sheet rows by column index.

  ## Examples

      iex> DSheet.sort(sheet, 2, :asc)
      {:ok, sorted_sheet}

  """
  @spec sort(sheet(), integer(), :asc | :desc) :: {:ok, sheet()}
  def sort(sheet, col_index, direction \\ :asc) do
    sorted_rows =
      sheet.rows
      |> Enum.sort_by(
        fn row ->
          cell = Enum.at(row, col_index)
          cell && cell.value
        end,
        direction
      )

    sorted_sheet = %{sheet | rows: sorted_rows}
    {:ok, sorted_sheet}
  end

  @doc """
  Export sheet data to CSV format.

  ## Examples

      iex> DSheet.export_csv(sheet)
      {:ok, "Symbol,Balance,Price,...\\nETH,1.5,$2000,..."}

  """
  @spec export_csv(sheet()) :: {:ok, String.t()}
  def export_csv(sheet) do
    # Build CSV header
    header_line = Enum.join(sheet.headers, ",")

    # Build CSV rows
    data_lines =
      Enum.map(sheet.rows, fn row ->
        row
        |> Enum.map(fn cell -> format_cell_for_export(cell) end)
        |> Enum.join(",")
      end)

    csv_content = Enum.join([header_line | data_lines], "\n")
    {:ok, csv_content}
  end

  @doc """
  Export sheet data to JSON format.

  ## Examples

      iex> DSheet.export_json(sheet)
      {:ok, json_string}

  """
  @spec export_json(sheet()) :: {:ok, String.t()} | {:error, atom()}
  def export_json(sheet) do
    # Convert to JSON-friendly structure
    data = %{
      id: sheet.id,
      name: sheet.name,
      owner: sheet.owner,
      description: sheet.description,
      headers: sheet.headers,
      rows:
        Enum.map(sheet.rows, fn row ->
          Enum.map(row, fn cell ->
            %{
              value: cell.value,
              type: to_string(cell.type)
            }
          end)
        end),
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

  @doc """
  Format sheet as ASCII table for terminal display.

  ## Examples

      iex> DSheet.format_table(sheet)
      "Symbol | Balance | Price\\n--------|---------|------\\nETH    | 1.5     | $2000"

  """
  @spec format_table(sheet(), keyword()) :: String.t()
  def format_table(sheet, opts \\ []) do
    max_rows = Keyword.get(opts, :max_rows, 20)
    max_col_width = Keyword.get(opts, :max_col_width, 20)

    # Calculate column widths
    col_widths =
      sheet.headers
      |> Enum.with_index()
      |> Enum.map(fn {header, idx} ->
        header_width = String.length(header)

        data_width =
          sheet.rows
          |> Enum.take(max_rows)
          |> Enum.map(fn row ->
            cell = Enum.at(row, idx)
            cell && String.length(to_string(cell.value)) || 0
          end)
          |> Enum.max(fn -> 0 end)

        min(max(header_width, data_width), max_col_width)
      end)

    # Build header row
    header_row =
      sheet.headers
      |> Enum.zip(col_widths)
      |> Enum.map(fn {header, width} ->
        String.pad_trailing(truncate(header, width), width)
      end)
      |> Enum.join(" | ")

    # Build separator
    separator =
      col_widths
      |> Enum.map(&String.duplicate("-", &1))
      |> Enum.join("-+-")

    # Build data rows
    data_rows =
      sheet.rows
      |> Enum.take(max_rows)
      |> Enum.map(fn row ->
        row
        |> Enum.zip(col_widths)
        |> Enum.map(fn {cell, width} ->
          value = format_cell_value(cell)
          String.pad_trailing(truncate(value, width), width)
        end)
        |> Enum.join(" | ")
      end)

    # Combine all parts
    table_lines = [header_row, separator | data_rows]

    # Add row count footer if truncated
    footer =
      if sheet.row_count > max_rows do
        "\n... #{sheet.row_count - max_rows} more rows (#{sheet.row_count} total)"
      else
        ""
      end

    Enum.join(table_lines, "\n") <> footer
  end

  # Private Functions

  defp generate_id do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  defp default_headers_for_type(:token_balances) do
    ["Symbol", "Balance", "Price (USD)", "Value (USD)", "24h Change", "Chain"]
  end

  defp default_headers_for_type(:nft_collection) do
    ["Collection", "Token ID", "Name", "Owner", "Floor Price"]
  end

  defp default_headers_for_type(:transactions) do
    ["Hash", "From", "To", "Value (ETH)", "Gas", "Time", "Status"]
  end

  defp default_headers_for_type(_) do
    ["Column A", "Column B", "Column C"]
  end

  defp generate_mock_sheet(sheet_id, wallet_address) do
    # Determine sheet type from ID
    sheet_type =
      cond do
        String.contains?(sheet_id, "001") -> :token_balances
        String.contains?(sheet_id, "002") -> :nft_collection
        String.contains?(sheet_id, "003") -> :transactions
        true -> :token_balances
      end

    headers = default_headers_for_type(sheet_type)
    rows = generate_mock_rows(sheet_type, 10)

    %{
      id: sheet_id,
      name: "Sample #{sheet_type} Sheet",
      owner: wallet_address,
      description: "Mock data for #{sheet_type}",
      headers: headers,
      rows: rows,
      row_count: length(rows),
      col_count: length(headers),
      created_at: DateTime.utc_now() |> DateTime.add(-86400, :second),
      updated_at: DateTime.utc_now(),
      sheet_type: sheet_type
    }
  end

  defp generate_mock_rows(:token_balances, count) do
    tokens = [
      {"ETH", "1.5234", "$2,450.00", "$3,732.33", "+2.5%", "Ethereum"},
      {"USDC", "5,000.00", "$1.00", "$5,000.00", "0.0%", "Ethereum"},
      {"WBTC", "0.05", "$62,000.00", "$3,100.00", "+1.2%", "Ethereum"},
      {"DAI", "2,500.00", "$1.00", "$2,500.00", "+0.1%", "Ethereum"},
      {"LINK", "100.00", "$15.25", "$1,525.00", "-0.8%", "Ethereum"},
      {"UNI", "250.00", "$6.50", "$1,625.00", "+3.2%", "Ethereum"},
      {"MATIC", "1,000.00", "$0.85", "$850.00", "+5.1%", "Polygon"},
      {"AAVE", "10.00", "$95.00", "$950.00", "-1.5%", "Ethereum"}
    ]

    tokens
    |> Enum.take(count)
    |> Enum.map(fn {symbol, balance, price, value, change, chain} ->
      [
        %{value: symbol, type: :text, format: nil},
        %{value: balance, type: :number, format: nil},
        %{value: price, type: :number, format: "currency"},
        %{value: value, type: :number, format: "currency"},
        %{value: change, type: :text, format: nil},
        %{value: chain, type: :text, format: nil}
      ]
    end)
  end

  defp generate_mock_rows(:nft_collection, count) do
    nfts = [
      {"Bored Ape #1234", "#1234", "Bored Ape", "0x1234...5678", "50 ETH"},
      {"CryptoPunk #5678", "#5678", "CryptoPunk", "0x1234...5678", "75 ETH"},
      {"Azuki #9012", "#9012", "Azuki", "0x1234...5678", "15 ETH"},
      {"Doodle #3456", "#3456", "Doodles", "0x1234...5678", "8 ETH"},
      {"BAYC #7890", "#7890", "Bored Ape", "0x1234...5678", "50 ETH"}
    ]

    nfts
    |> Enum.take(count)
    |> Enum.map(fn {collection, token_id, name, owner, floor} ->
      [
        %{value: collection, type: :text, format: nil},
        %{value: token_id, type: :text, format: nil},
        %{value: name, type: :text, format: nil},
        %{value: owner, type: :address, format: nil},
        %{value: floor, type: :text, format: nil}
      ]
    end)
  end

  defp generate_mock_rows(:transactions, count) do
    transactions = [
      {"0xabc123...", "0x1234...", "0x5678...", "1.5", "0.002", "2m ago", "Success"},
      {"0xdef456...", "0x5678...", "0x9abc...", "0.5", "0.001", "5m ago", "Success"},
      {"0xghi789...", "0x9abc...", "0xdef0...", "2.0", "0.003", "10m ago", "Success"}
    ]

    transactions
    |> Stream.cycle()
    |> Enum.take(count)
    |> Enum.map(fn {hash, from, to, value, gas, time, status} ->
      [
        %{value: hash, type: :hash, format: nil},
        %{value: from, type: :address, format: nil},
        %{value: to, type: :address, format: nil},
        %{value: value, type: :number, format: nil},
        %{value: gas, type: :number, format: nil},
        %{value: time, type: :date, format: nil},
        %{value: status, type: :text, format: nil}
      ]
    end)
  end

  defp generate_mock_rows(_, count) do
    List.duplicate(
      [
        %{value: "Sample", type: :text, format: nil},
        %{value: "Data", type: :text, format: nil},
        %{value: "Here", type: :text, format: nil}
      ],
      count
    )
  end

  defp query_token_balances(params, wallet_address) do
    address = Map.get(params, :address, wallet_address)

    sheet = %{
      id: "query_" <> generate_id(),
      name: "Token Balances for #{shorten_address(address)}",
      owner: wallet_address,
      description: "ERC-20 token balances with USD values",
      headers: default_headers_for_type(:token_balances),
      rows: generate_mock_rows(:token_balances, 8),
      row_count: 8,
      col_count: 6,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      sheet_type: :token_balances
    }

    {:ok, sheet}
  end

  defp query_nft_holdings(params, wallet_address) do
    address = Map.get(params, :address, wallet_address)

    sheet = %{
      id: "query_" <> generate_id(),
      name: "NFT Holdings for #{shorten_address(address)}",
      owner: wallet_address,
      description: "NFT collection with metadata",
      headers: default_headers_for_type(:nft_collection),
      rows: generate_mock_rows(:nft_collection, 5),
      row_count: 5,
      col_count: 5,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      sheet_type: :nft_collection
    }

    {:ok, sheet}
  end

  defp query_transactions(params, wallet_address) do
    address = Map.get(params, :address, wallet_address)

    sheet = %{
      id: "query_" <> generate_id(),
      name: "Transactions for #{shorten_address(address)}",
      owner: wallet_address,
      description: "Recent transaction history",
      headers: default_headers_for_type(:transactions),
      rows: generate_mock_rows(:transactions, 15),
      row_count: 15,
      col_count: 7,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      sheet_type: :transactions
    }

    {:ok, sheet}
  end

  defp query_contract_state(_params, wallet_address) do
    sheet = %{
      id: "query_" <> generate_id(),
      name: "Contract State",
      owner: wallet_address,
      description: "Smart contract state variables",
      headers: ["Variable", "Type", "Value"],
      rows: [
        [
          %{value: "totalSupply", type: :text, format: nil},
          %{value: "uint256", type: :text, format: nil},
          %{value: "1000000", type: :number, format: nil}
        ],
        [
          %{value: "owner", type: :text, format: nil},
          %{value: "address", type: :text, format: nil},
          %{value: "0x1234...5678", type: :address, format: nil}
        ]
      ],
      row_count: 2,
      col_count: 3,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      sheet_type: :custom
    }

    {:ok, sheet}
  end

  defp format_cell_value(cell) do
    case cell.type do
      :address -> shorten_address(cell.value)
      :hash -> shorten_hash(cell.value)
      _ -> to_string(cell.value)
    end
  end

  defp format_cell_for_export(cell) do
    value = to_string(cell.value)

    # Escape commas and quotes for CSV
    if String.contains?(value, [",", "\""]) do
      "\"#{String.replace(value, "\"", "\"\"")}\""
    else
      value
    end
  end

  defp shorten_address(address) when is_binary(address) and byte_size(address) > 12 do
    prefix = String.slice(address, 0..5)
    suffix = String.slice(address, -4..-1//1)
    "#{prefix}...#{suffix}"
  end

  defp shorten_address(address), do: to_string(address)

  defp shorten_hash(hash) when is_binary(hash) and byte_size(hash) > 12 do
    prefix = String.slice(hash, 0..7)
    "#{prefix}..."
  end

  defp shorten_hash(hash), do: to_string(hash)

  defp truncate(string, max_length) when is_binary(string) do
    if String.length(string) > max_length do
      String.slice(string, 0, max_length - 3) <> "..."
    else
      string
    end
  end

  defp truncate(value, max_length) do
    value |> to_string() |> truncate(max_length)
  end
end
