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
  # Reserved for future Alchemy API integration
  # @alchemy_api_base "https://eth-mainnet.g.alchemy.com/v2"

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
    if valid_address?(address) do
      case fetch_from_opensea(address, limit, chain) do
        {:ok, nfts} -> {:ok, nfts}
        {:error, _reason} -> {:error, :api_error}
      end
    else
      {:error, :invalid_address}
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
    if valid_address?(contract_address) do
      case fetch_nft_from_opensea(contract_address, token_id) do
        {:ok, nft} -> {:ok, nft}
        {:error, _reason} -> {:error, :api_error}
      end
    else
      {:error, :invalid_contract_address}
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
      contract_address: extract_contract_address(nft_data),
      token_id: extract_token_id(nft_data),
      name: extract_name(nft_data),
      description: extract_description(nft_data),
      image_url: extract_image_url(nft_data),
      collection_name: extract_collection_name(nft_data),
      token_standard: extract_token_standard(nft_data),
      properties: extract_properties(nft_data)
    }
  end

  defp extract_contract_address(data), do: get_in(data, ["contract"]) || "Unknown"
  defp extract_token_id(data), do: get_in(data, ["identifier"]) || "Unknown"
  defp extract_name(data), do: get_in(data, ["name"]) || "Unnamed NFT"
  defp extract_description(data), do: get_in(data, ["description"]) || ""

  defp extract_image_url(data) do
    get_in(data, ["image_url"]) || get_in(data, ["display_image_url"]) || ""
  end

  defp extract_collection_name(data), do: get_in(data, ["collection"]) || "Unknown Collection"
  defp extract_token_standard(data), do: get_in(data, ["token_standard"]) || "unknown"
  defp extract_properties(data), do: get_in(data, ["traits"]) || []

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
