defmodule Droodotfoo.Web3.Transaction do
  @moduledoc """
  Ethereum transaction history and details utilities.

  Fetches transaction history from Etherscan API.
  """

  require Logger

  @type transaction :: %{
          hash: String.t(),
          from: String.t(),
          to: String.t(),
          value: String.t(),
          value_eth: float(),
          gas_price: String.t(),
          gas_used: String.t(),
          gas_cost_eth: float(),
          timestamp: integer(),
          status: String.t(),
          block_number: String.t(),
          method: String.t()
        }

  # Etherscan API endpoints
  # Reserved for future Etherscan API integration
  # @etherscan_api_base "https://api.etherscan.io/api"

  # Note: Etherscan requires API key for production use
  # Free tier: 5 calls/second, 100k calls/day
  # For demo purposes, we'll use mock data

  @doc """
  Fetch transaction history for an address.

  ## Parameters

  - `address`: Ethereum wallet address (0x-prefixed)
  - `opts`: Keyword list of options
    - `:limit` - Max number of transactions to return (default: 10)
    - `:offset` - Pagination offset (default: 0)

  ## Examples

      iex> Droodotfoo.Web3.Transaction.fetch_history("0x1234...")
      {:ok, [%{hash: "0xabc...", from: "0x123...", ...}, ...]}

  """
  @spec fetch_history(String.t(), keyword()) :: {:ok, [transaction()]} | {:error, atom()}
  def fetch_history(address, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    _offset = Keyword.get(opts, :offset, 0)

    if valid_address?(address) do
      # For demo purposes, return mock data since Etherscan requires API key
      # In production, this would call Etherscan API
      {:ok, mock_transactions(address, limit)}
    else
      {:error, :invalid_address}
    end
  end

  @doc """
  Fetch details for a specific transaction by hash.

  ## Examples

      iex> Droodotfoo.Web3.Transaction.fetch_transaction("0xabc...")
      {:ok, %{hash: "0xabc...", ...}}

  """
  @spec fetch_transaction(String.t()) :: {:ok, transaction()} | {:error, atom()}
  def fetch_transaction(tx_hash) do
    if valid_tx_hash?(tx_hash) do
      # Mock implementation
      {:ok, mock_transaction_detail(tx_hash)}
    else
      {:error, :invalid_tx_hash}
    end
  end

  @doc """
  Format transaction value from Wei to ETH.

  ## Examples

      iex> Droodotfoo.Web3.Transaction.wei_to_eth("1000000000000000000")
      1.0

  """
  @spec wei_to_eth(String.t()) :: float()
  def wei_to_eth(wei_string) do
    case Integer.parse(wei_string) do
      {wei, _} ->
        wei / 1_000_000_000_000_000_000

      :error ->
        0.0
    end
  end

  @doc """
  Format timestamp to human-readable date.

  ## Examples

      iex> Droodotfoo.Web3.Transaction.format_timestamp(1234567890)
      "2009-02-13 23:31:30 UTC"

  """
  @spec format_timestamp(integer()) :: String.t()
  def format_timestamp(unix_timestamp) do
    case DateTime.from_unix(unix_timestamp) do
      {:ok, datetime} ->
        datetime
        |> DateTime.truncate(:second)
        |> DateTime.to_string()
        |> String.replace("Z", " UTC")

      {:error, _} ->
        "Unknown"
    end
  end

  @doc """
  Shorten address or hash for display.

  ## Examples

      iex> Droodotfoo.Web3.Transaction.shorten("0x1234567890abcdef")
      "0x1234...cdef"

  """
  @spec shorten(String.t()) :: String.t()
  def shorten(hex_string) when is_binary(hex_string) and byte_size(hex_string) > 10 do
    prefix = String.slice(hex_string, 0..5)
    suffix = String.slice(hex_string, -4..-1)
    "#{prefix}...#{suffix}"
  end

  def shorten(hex_string), do: hex_string

  ## Private Functions

  defp mock_transactions(address, limit) do
    # Generate mock transaction data
    now = DateTime.utc_now() |> DateTime.to_unix()

    Enum.map(1..limit, fn i ->
      # Alternate between sent and received
      is_sent = rem(i, 2) == 0

      from_addr = if is_sent, do: address, else: "0x" <> random_hex(40)
      to_addr = if is_sent, do: "0x" <> random_hex(40), else: address

      value_eth = :rand.uniform() * 10
      gas_used = 21_000 + :rand.uniform(50_000)
      gas_price_gwei = 20 + :rand.uniform(100)
      gas_cost_eth = gas_used * gas_price_gwei / 1_000_000_000

      %{
        hash: "0x" <> random_hex(64),
        from: from_addr,
        to: to_addr,
        value: Float.to_string(value_eth * 1_000_000_000_000_000_000),
        value_eth: value_eth,
        gas_price: Integer.to_string(gas_price_gwei * 1_000_000_000),
        gas_used: Integer.to_string(gas_used),
        gas_cost_eth: gas_cost_eth,
        timestamp: now - i * 3600,
        status: "1",
        block_number: Integer.to_string(18_000_000 - i),
        method: if(rem(i, 3) == 0, do: "transfer", else: "")
      }
    end)
  end

  defp mock_transaction_detail(tx_hash) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    value_eth = :rand.uniform() * 5
    gas_used = 21_000 + :rand.uniform(30_000)
    gas_price_gwei = 25 + :rand.uniform(50)
    gas_cost_eth = gas_used * gas_price_gwei / 1_000_000_000

    %{
      hash: tx_hash,
      from: "0x" <> random_hex(40),
      to: "0x" <> random_hex(40),
      value: Float.to_string(value_eth * 1_000_000_000_000_000_000),
      value_eth: value_eth,
      gas_price: Integer.to_string(gas_price_gwei * 1_000_000_000),
      gas_used: Integer.to_string(gas_used),
      gas_cost_eth: gas_cost_eth,
      timestamp: now - 3600,
      status: "1",
      block_number: "18000000",
      method: "transfer"
    }
  end

  defp random_hex(length) do
    length
    |> div(2)
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
    |> String.slice(0, length)
  end

  defp valid_address?(address) when is_binary(address) do
    String.match?(address, ~r/^0x[a-fA-F0-9]{40}$/)
  end

  defp valid_address?(_), do: false

  defp valid_tx_hash?(tx_hash) when is_binary(tx_hash) do
    String.match?(tx_hash, ~r/^0x[a-fA-F0-9]{64}$/)
  end

  defp valid_tx_hash?(_), do: false
end
