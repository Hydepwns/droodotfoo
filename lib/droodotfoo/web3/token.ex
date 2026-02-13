defmodule Droodotfoo.Web3.Token do
  @moduledoc """
  ERC-20 token balance and pricing utilities.

  Fetches token balances, USD prices, and price changes.
  """

  require Logger

  @type token_balance :: %{
          contract_address: String.t(),
          symbol: String.t(),
          name: String.t(),
          balance: String.t(),
          decimals: integer(),
          balance_formatted: float(),
          usd_price: float() | nil,
          usd_value: float() | nil,
          price_change_24h: float() | nil
        }

  @type price_data :: %{
          usd: float(),
          usd_24h_change: float()
        }

  # Reserved for future Alchemy API integration
  # @alchemy_api_base "https://eth-mainnet.g.alchemy.com/v2"

  # CoinGecko API for pricing (free tier, no auth required)
  @coingecko_api_base "https://api.coingecko.com/api/v3"

  # Reserved for future token balance lookups
  # @popular_tokens %{
  #   "0xdac17f958d2ee523a2206206994597c13d831ec7" => "USDT",
  #   "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48" => "USDC",
  #   "0x6b175474e89094c44da98b954eedeac495271d0f" => "DAI",
  #   "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599" => "WBTC",
  #   "0x514910771af9ca656af840dff83e8264ecf986ca" => "LINK",
  #   "0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0" => "MATIC",
  #   "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984" => "UNI",
  #   "0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9" => "AAVE"
  # }

  # CoinGecko token ID mapping
  @coingecko_ids %{
    "USDT" => "tether",
    "USDC" => "usd-coin",
    "DAI" => "dai",
    "WBTC" => "wrapped-bitcoin",
    "LINK" => "chainlink",
    "MATIC" => "matic-network",
    "UNI" => "uniswap",
    "AAVE" => "aave",
    "ETH" => "ethereum"
  }

  @doc """
  Fetch ERC-20 token balances for an address.

  ## Parameters

  - `address`: Ethereum wallet address (0x-prefixed)
  - `opts`: Keyword list of options
    - `:include_native` - Include ETH balance (default: true)

  ## Examples

      iex> Droodotfoo.Web3.Token.fetch_balances("0x1234...")
      {:ok, [%{symbol: "ETH", balance_formatted: 1.5, ...}, ...]}

  """
  @spec fetch_balances(String.t(), keyword()) :: {:ok, [token_balance()]} | {:error, atom()}
  def fetch_balances(address, opts \\ []) do
    include_native = Keyword.get(opts, :include_native, true)

    if valid_address?(address) do
      # For now, return popular tokens with mock balances
      # In production, this would call Alchemy or Etherscan API
      balances = get_popular_token_balances(address, include_native)

      # Enrich with pricing data
      enriched_balances = Enum.map(balances, &enrich_token_with_price/1)

      {:ok, enriched_balances}
    else
      {:error, :invalid_address}
    end
  end

  defp enrich_token_with_price(token) do
    case get_token_price(token.symbol) do
      {:ok, price_data} ->
        Map.merge(token, %{
          usd_price: price_data.usd,
          usd_value: token.balance_formatted * price_data.usd,
          price_change_24h: price_data.usd_24h_change
        })

      {:error, _} ->
        token
    end
  end

  @doc """
  Get USD price and 24h change for a token.

  ## Examples

      iex> Droodotfoo.Web3.Token.get_token_price("ETH")
      {:ok, %{usd: 2500.0, usd_24h_change: 2.5}}

  """
  @spec get_token_price(String.t()) :: {:ok, price_data()} | {:error, atom()}
  def get_token_price(symbol) do
    case Map.get(@coingecko_ids, String.upcase(symbol)) do
      nil ->
        {:error, :token_not_found}

      coingecko_id ->
        fetch_price_from_coingecko(coingecko_id)
    end
  end

  @doc """
  Get historical price data for ASCII chart.

  Returns last 7 days of prices.
  """
  @spec get_price_history(String.t(), integer()) :: {:ok, [float()]} | {:error, atom()}
  def get_price_history(symbol, days \\ 7) do
    case Map.get(@coingecko_ids, String.upcase(symbol)) do
      nil ->
        {:error, :token_not_found}

      coingecko_id ->
        fetch_price_history_from_coingecko(coingecko_id, days)
    end
  end

  @doc """
  Generate ASCII sparkline chart from price data.

  ## Examples

      iex> Droodotfoo.Web3.Token.price_chart([100, 110, 105, 115, 120])
      "▁▄▃▆█"

  """
  @spec price_chart([float()]) :: String.t()
  def price_chart(prices) when is_list(prices) and prices != [] do
    min_price = Enum.min(prices)
    max_price = Enum.max(prices)
    range = max_price - min_price

    if range == 0 do
      String.duplicate("▄", length(prices))
    else
      chars = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]

      Enum.map_join(prices, "", fn price ->
        normalized = (price - min_price) / range
        index = min(trunc(normalized * (length(chars) - 1)), length(chars) - 1)
        Enum.at(chars, index)
      end)
    end
  end

  def price_chart(_), do: "No data"

  ## Private Functions

  defp get_popular_token_balances(_address, include_native) do
    # Mock implementation - in production, fetch from Alchemy/Etherscan
    # For now, return empty list to indicate we'd need API keys
    tokens = []

    if include_native do
      [
        %{
          contract_address: "0x0000000000000000000000000000000000000000",
          symbol: "ETH",
          name: "Ethereum",
          balance: "0",
          decimals: 18,
          balance_formatted: 0.0,
          usd_price: nil,
          usd_value: nil,
          price_change_24h: nil
        }
        | tokens
      ]
    else
      tokens
    end
  end

  defp fetch_price_from_coingecko(coingecko_id) do
    url =
      "#{@coingecko_api_base}/simple/price?ids=#{coingecko_id}&vs_currencies=usd&include_24hr_change=true"

    case http_get(url) do
      {:ok, response} ->
        case get_in(response, [coingecko_id]) do
          nil ->
            {:error, :price_not_found}

          price_data ->
            {:ok,
             %{
               usd: Map.get(price_data, "usd", 0.0),
               usd_24h_change: Map.get(price_data, "usd_24h_change", 0.0)
             }}
        end

      {:error, reason} ->
        Logger.error("Failed to fetch price from CoinGecko: #{inspect(reason)}")
        {:error, :api_error}
    end
  end

  defp fetch_price_history_from_coingecko(coingecko_id, days) do
    url = "#{@coingecko_api_base}/coins/#{coingecko_id}/market_chart?vs_currency=usd&days=#{days}"

    case http_get(url) do
      {:ok, %{"prices" => prices}} when is_list(prices) ->
        # Prices come as [[timestamp, price], ...]
        price_values = Enum.map(prices, fn [_timestamp, price] -> price end)
        {:ok, price_values}

      {:ok, _response} ->
        {:error, :invalid_response}

      {:error, reason} ->
        Logger.error("Failed to fetch price history from CoinGecko: #{inspect(reason)}")
        {:error, :api_error}
    end
  end

  defp http_get(url) do
    # Use consolidated HttpClient for consistent error handling
    client = Droodotfoo.HttpClient.new(url, [{"Accept", "application/json"}])

    case Droodotfoo.HttpClient.get(client, "") do
      {:ok, %{body: json}} ->
        {:ok, json}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp valid_address?(address) when is_binary(address) do
    String.match?(address, ~r/^0x[a-fA-F0-9]{40}$/)
  end

  defp valid_address?(_), do: false
end
