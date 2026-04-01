defmodule Droodotfoo.Fileverse.DSheet.MockData do
  @moduledoc """
  Mock data generation for dSheet demonstration.
  Provides sample blockchain data for testing and preview.
  """

  @doc """
  Generate mock rows for the specified sheet type.
  """
  def generate_rows(:token_balances, count) do
    token_data()
    |> Enum.take(count)
    |> Enum.map(&token_to_row/1)
  end

  def generate_rows(:nft_collection, count) do
    nft_data()
    |> Enum.take(count)
    |> Enum.map(&nft_to_row/1)
  end

  def generate_rows(:transactions, count) do
    transaction_data()
    |> Stream.cycle()
    |> Enum.take(count)
    |> Enum.map(&transaction_to_row/1)
  end

  def generate_rows(_, count) do
    List.duplicate(
      [
        %{value: "Sample", type: :text, format: nil},
        %{value: "Data", type: :text, format: nil},
        %{value: "Here", type: :text, format: nil}
      ],
      count
    )
  end

  @doc """
  Generate a complete mock sheet.
  """
  def generate_sheet(sheet_id, wallet_address) do
    sheet_type = determine_sheet_type(sheet_id)
    headers = Droodotfoo.Fileverse.DSheet.Headers.for_type(sheet_type)
    rows = generate_rows(sheet_type, 10)

    %{
      id: sheet_id,
      name: "Sample #{sheet_type} Sheet",
      owner: wallet_address,
      description: "Mock data for #{sheet_type}",
      headers: headers,
      rows: rows,
      row_count: length(rows),
      col_count: length(headers),
      created_at: DateTime.utc_now() |> DateTime.add(-86_400, :second),
      updated_at: DateTime.utc_now(),
      sheet_type: sheet_type
    }
  end

  @doc """
  Generate list of mock sheet summaries for a wallet.
  """
  def generate_sheet_list(wallet_address) do
    now = DateTime.utc_now()

    [
      %{
        id: "sheet_001",
        name: "Token Portfolio",
        owner: wallet_address,
        description: "ERC-20 token balances with USD values",
        row_count: 8,
        col_count: 6,
        created_at: DateTime.add(now, -86_400, :second),
        updated_at: DateTime.add(now, -3600, :second),
        sheet_type: :token_balances
      },
      %{
        id: "sheet_002",
        name: "NFT Collection",
        owner: wallet_address,
        description: "NFT holdings with metadata",
        row_count: 12,
        col_count: 5,
        created_at: DateTime.add(now, -172_800, :second),
        updated_at: now,
        sheet_type: :nft_collection
      },
      %{
        id: "sheet_003",
        name: "Recent Transactions",
        owner: wallet_address,
        description: "Last 20 transactions",
        row_count: 20,
        col_count: 7,
        created_at: DateTime.add(now, -259_200, :second),
        updated_at: DateTime.add(now, -1800, :second),
        sheet_type: :transactions
      }
    ]
  end

  # Private helpers

  defp determine_sheet_type(sheet_id) do
    cond do
      String.contains?(sheet_id, "001") -> :token_balances
      String.contains?(sheet_id, "002") -> :nft_collection
      String.contains?(sheet_id, "003") -> :transactions
      true -> :token_balances
    end
  end

  defp token_data do
    [
      {"ETH", "1.5234", "$2,450.00", "$3,732.33", "+2.5%", "Ethereum"},
      {"USDC", "5,000.00", "$1.00", "$5,000.00", "0.0%", "Ethereum"},
      {"WBTC", "0.05", "$62,000.00", "$3,100.00", "+1.2%", "Ethereum"},
      {"DAI", "2,500.00", "$1.00", "$2,500.00", "+0.1%", "Ethereum"},
      {"LINK", "100.00", "$15.25", "$1,525.00", "-0.8%", "Ethereum"},
      {"UNI", "250.00", "$6.50", "$1,625.00", "+3.2%", "Ethereum"},
      {"MATIC", "1,000.00", "$0.85", "$850.00", "+5.1%", "Polygon"},
      {"AAVE", "10.00", "$95.00", "$950.00", "-1.5%", "Ethereum"}
    ]
  end

  defp token_to_row({symbol, balance, price, value, change, chain}) do
    [
      %{value: symbol, type: :text, format: nil},
      %{value: balance, type: :number, format: nil},
      %{value: price, type: :number, format: "currency"},
      %{value: value, type: :number, format: "currency"},
      %{value: change, type: :text, format: nil},
      %{value: chain, type: :text, format: nil}
    ]
  end

  defp nft_data do
    [
      {"Bored Ape #1234", "#1234", "Bored Ape", "0x1234...5678", "50 ETH"},
      {"CryptoPunk #5678", "#5678", "CryptoPunk", "0x1234...5678", "75 ETH"},
      {"Azuki #9012", "#9012", "Azuki", "0x1234...5678", "15 ETH"},
      {"Doodle #3456", "#3456", "Doodles", "0x1234...5678", "8 ETH"},
      {"BAYC #7890", "#7890", "Bored Ape", "0x1234...5678", "50 ETH"}
    ]
  end

  defp nft_to_row({collection, token_id, name, owner, floor}) do
    [
      %{value: collection, type: :text, format: nil},
      %{value: token_id, type: :text, format: nil},
      %{value: name, type: :text, format: nil},
      %{value: owner, type: :address, format: nil},
      %{value: floor, type: :text, format: nil}
    ]
  end

  defp transaction_data do
    [
      {"0xabc123...", "0x1234...", "0x5678...", "1.5", "0.002", "2m ago", "Success"},
      {"0xdef456...", "0x5678...", "0x9abc...", "0.5", "0.001", "5m ago", "Success"},
      {"0xghi789...", "0x9abc...", "0xdef0...", "2.0", "0.003", "10m ago", "Success"}
    ]
  end

  defp transaction_to_row({hash, from, to, value, gas, time, status}) do
    [
      %{value: hash, type: :hash, format: nil},
      %{value: from, type: :address, format: nil},
      %{value: to, type: :address, format: nil},
      %{value: value, type: :number, format: nil},
      %{value: gas, type: :number, format: nil},
      %{value: time, type: :date, format: nil},
      %{value: status, type: :text, format: nil}
    ]
  end
end
