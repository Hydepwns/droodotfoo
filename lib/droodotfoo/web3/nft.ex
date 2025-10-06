defmodule Droodotfoo.Web3.NFT do
  @moduledoc """
  NFT fetching and metadata utilities.

  Supports ERC-721 and ERC-1155 tokens via OpenSea and Alchemy APIs.
  """

  require Logger

  @type nft :: %{
          contract_address: String.t(),
          token_id: String.t(),
          name: String.t(),
          description: String.t(),
          image_url: String.t(),
          collection_name: String.t(),
          token_standard: String.t(),
          properties: map()
        }

  @opensea_api_base "https://api.opensea.io/api/v2"
  @alchemy_api_base "https://eth-mainnet.g.alchemy.com/v2"

  # Alchemy API key should be in config or env
  # For now, using OpenSea's public API which doesn't require auth for basic queries

  @doc """
  Fetch NFTs owned by an address.

  ## Parameters

  - `address`: Ethereum wallet address (0x-prefixed)
  - `opts`: Keyword list of options
    - `:limit` - Max number of NFTs to return (default: 20)
    - `:chain` - Chain to query (default: "ethereum")

  ## Examples

      iex> Droodotfoo.Web3.NFT.fetch_nfts("0x1234...")
      {:ok, [%{name: "Cool NFT #1", ...}, ...]}

  """
  @spec fetch_nfts(String.t(), keyword()) :: {:ok, [nft()]} | {:error, atom()}
  def fetch_nfts(address, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    chain = Keyword.get(opts, :chain, "ethereum")

    # Validate address format
    if not valid_address?(address) do
      {:error, :invalid_address}
    else
      case fetch_from_opensea(address, limit, chain) do
        {:ok, nfts} -> {:ok, nfts}
        {:error, _reason} -> {:error, :api_error}
      end
    end
  end

  @doc """
  Fetch a single NFT by contract address and token ID.

  ## Examples

      iex> Droodotfoo.Web3.NFT.fetch_nft("0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d", "1")
      {:ok, %{name: "BoredApeYachtClub #1", ...}}

  """
  @spec fetch_nft(String.t(), String.t()) :: {:ok, nft()} | {:error, atom()}
  def fetch_nft(contract_address, token_id) do
    if not valid_address?(contract_address) do
      {:error, :invalid_contract_address}
    else
      case fetch_nft_from_opensea(contract_address, token_id) do
        {:ok, nft} -> {:ok, nft}
        {:error, _reason} -> {:error, :api_error}
      end
    end
  end

  @doc """
  Convert image URL to ASCII art representation.

  For now, returns a placeholder. Future implementation could:
  - Download image
  - Convert to grayscale
  - Map to ASCII characters
  - Return as multi-line string
  """
  @spec image_to_ascii(String.t(), keyword()) :: {:ok, String.t()} | {:error, atom()}
  def image_to_ascii(_image_url, _opts \\ []) do
    # Placeholder ASCII art for NFT thumbnail
    ascii_art = """
    ╔════════════╗
    ║            ║
    ║    NFT     ║
    ║   IMAGE    ║
    ║            ║
    ╚════════════╝
    """

    {:ok, String.trim(ascii_art)}
  end

  ## Private Functions

  defp fetch_from_opensea(address, limit, _chain) do
    # OpenSea API v2 endpoint for fetching NFTs by owner
    url = "#{@opensea_api_base}/chain/ethereum/account/#{address}/nfts?limit=#{limit}"

    case http_get(url) do
      {:ok, %{"nfts" => nfts}} when is_list(nfts) ->
        parsed_nfts = Enum.map(nfts, &parse_opensea_nft/1)
        {:ok, parsed_nfts}

      {:ok, _response} ->
        {:error, :invalid_response}

      {:error, reason} ->
        Logger.error("Failed to fetch NFTs from OpenSea: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp fetch_nft_from_opensea(contract_address, token_id) do
    url = "#{@opensea_api_base}/chain/ethereum/contract/#{contract_address}/nfts/#{token_id}"

    case http_get(url) do
      {:ok, %{"nft" => nft_data}} ->
        {:ok, parse_opensea_nft(nft_data)}

      {:ok, _response} ->
        {:error, :invalid_response}

      {:error, reason} ->
        Logger.error("Failed to fetch NFT from OpenSea: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_opensea_nft(nft_data) do
    %{
      contract_address: get_in(nft_data, ["contract"]) || "Unknown",
      token_id: get_in(nft_data, ["identifier"]) || "Unknown",
      name: get_in(nft_data, ["name"]) || "Unnamed NFT",
      description: get_in(nft_data, ["description"]) || "",
      image_url: get_in(nft_data, ["image_url"]) || get_in(nft_data, ["display_image_url"]) || "",
      collection_name: get_in(nft_data, ["collection"]) || "Unknown Collection",
      token_standard: get_in(nft_data, ["token_standard"]) || "unknown",
      properties: get_in(nft_data, ["traits"]) || []
    }
  end

  defp http_get(url) do
    # Use :httpc (built-in Erlang HTTP client)
    # Ensure :inets and :ssl applications are started
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    url_charlist = String.to_charlist(url)

    headers = [
      {'Accept', 'application/json'},
      {'X-API-KEY', ''}  # OpenSea public API doesn't require key for basic queries
    ]

    request = {url_charlist, headers}

    case :httpc.request(:get, request, [{:timeout, 10000}], []) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        case Jason.decode(body) do
          {:ok, json} -> {:ok, json}
          {:error, _} -> {:error, :invalid_json}
        end

      {:ok, {{_, status_code, _}, _headers, _body}} ->
        Logger.error("HTTP request failed with status: #{status_code}")
        {:error, :http_error}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp valid_address?(address) when is_binary(address) do
    String.match?(address, ~r/^0x[a-fA-F0-9]{40}$/)
  end

  defp valid_address?(_), do: false
end
