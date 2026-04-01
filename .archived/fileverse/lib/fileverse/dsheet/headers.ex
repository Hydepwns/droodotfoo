defmodule Droodotfoo.Fileverse.DSheet.Headers do
  @moduledoc """
  Header definitions for different dSheet types.
  """

  @doc """
  Get default headers for a sheet type.
  """
  def for_type(:token_balances) do
    ["Symbol", "Balance", "Price (USD)", "Value (USD)", "24h Change", "Chain"]
  end

  def for_type(:nft_collection) do
    ["Collection", "Token ID", "Name", "Owner", "Floor Price"]
  end

  def for_type(:transactions) do
    ["Hash", "From", "To", "Value (ETH)", "Gas", "Time", "Status"]
  end

  def for_type(_) do
    ["Column A", "Column B", "Column C"]
  end
end
