defmodule Droodotfoo.Web3.Networks do
  @moduledoc """
  Network and chain ID utilities for Web3 integrations.

  Provides human-readable names for blockchain networks
  and chain ID validation.
  """

  @doc """
  Get human-readable network name from chain ID.

  ## Examples

      iex> get_network_name(1)
      "Ethereum Mainnet"

      iex> get_network_name(137)
      "Polygon Mainnet"

      iex> get_network_name(99999)
      "Chain ID: 99999"
  """
  def get_network_name(1), do: "Ethereum Mainnet"
  def get_network_name(5), do: "Hoodi Testnet"
  def get_network_name(11_155_111), do: "Sepolia Testnet"
  def get_network_name(137), do: "Polygon Mainnet"
  def get_network_name(80_001), do: "Mumbai Testnet"
  def get_network_name(42_161), do: "Arbitrum One"
  def get_network_name(10), do: "Optimism"
  def get_network_name(8453), do: "Base"
  def get_network_name(chain_id), do: "Chain ID: #{chain_id}"

  @doc """
  Get all supported chain IDs.

  ## Examples

      iex> supported_chains()
      [1, 5, 11_155_111, 137, 80_001, 42_161, 10, 8453]
  """
  def supported_chains do
    [1, 5, 11_155_111, 137, 80_001, 42_161, 10, 8453]
  end

  @doc """
  Check if a chain ID is supported.

  ## Examples

      iex> supported_chain?(1)
      true

      iex> supported_chain?(99999)
      false
  """
  def supported_chain?(chain_id) do
    chain_id in supported_chains()
  end
end
