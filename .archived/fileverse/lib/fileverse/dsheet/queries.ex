defmodule Droodotfoo.Fileverse.DSheet.Queries do
  @moduledoc """
  Query handlers for blockchain data.
  Creates sheets from different query types.
  """

  alias Droodotfoo.Fileverse.DSheet.{Formatting, Headers, MockData}

  @doc """
  Execute a query and return a sheet.
  """
  def execute(:token_balances, params, wallet_address) do
    address = Map.get(params, :address, wallet_address)

    build_query_sheet(
      address,
      wallet_address,
      :token_balances,
      8,
      "ERC-20 token balances with USD values"
    )
  end

  def execute(:nft_holdings, params, wallet_address) do
    address = Map.get(params, :address, wallet_address)
    build_query_sheet(address, wallet_address, :nft_collection, 5, "NFT collection with metadata")
  end

  def execute(:transactions, params, wallet_address) do
    address = Map.get(params, :address, wallet_address)
    build_query_sheet(address, wallet_address, :transactions, 15, "Recent transaction history")
  end

  def execute(:contract_state, _params, wallet_address) do
    build_contract_state_sheet(wallet_address)
  end

  def execute(_, _params, _wallet_address), do: {:error, :invalid_query_type}

  # Private helpers

  defp build_query_sheet(address, wallet_address, sheet_type, row_count, description) do
    headers = Headers.for_type(sheet_type)
    rows = MockData.generate_rows(sheet_type, row_count)

    sheet = %{
      id: "query_" <> generate_id(),
      name: "#{sheet_type_name(sheet_type)} for #{Formatting.shorten_address(address)}",
      owner: wallet_address,
      description: description,
      headers: headers,
      rows: rows,
      row_count: row_count,
      col_count: length(headers),
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      sheet_type: sheet_type
    }

    {:ok, sheet}
  end

  defp build_contract_state_sheet(wallet_address) do
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

  defp sheet_type_name(:token_balances), do: "Token Balances"
  defp sheet_type_name(:nft_collection), do: "NFT Holdings"
  defp sheet_type_name(:transactions), do: "Transactions"
  defp sheet_type_name(_), do: "Data"

  defp generate_id do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end
end
