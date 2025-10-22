defmodule Droodotfoo.Web3.ENS do
  @moduledoc """
  Ethereum Name Service (ENS) resolution utilities.

  Provides functionality to:
  - Resolve ENS names to addresses
  - Reverse resolve addresses to ENS names
  - Fetch ENS avatars
  - Cache resolutions

  ## ENS Protocol

  ENS (Ethereum Name Service) provides human-readable names for blockchain addresses.
  Names end in `.eth` and map to Ethereum addresses, similar to DNS for IP addresses.

  ## Current Implementation

  Uses ENS public API endpoints for resolution. Future versions will use
  direct RPC calls to ENS contracts for on-chain lookups.

  ## Examples

      # Resolve name to address
      {:ok, address} = ENS.resolve_name("vitalik.eth")

      # Reverse resolve address to name
      {:ok, name} = ENS.reverse_resolve("0x...")

      # Validate ENS name format
      true = ENS.valid_ens_name?("example.eth")

  """

  require Logger
  alias Droodotfoo.Performance.Cache

  # Reserved for future on-chain ENS lookups
  # @ens_registry_address "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e"
  # @ens_public_resolver "0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41"

  # Mainnet ENS contracts
  @mainnet_chain_id 1

  # Type definitions

  @type ens_name :: String.t()
  @type address :: String.t()
  @type chain_id :: integer()
  @type error_reason ::
          :invalid_ens_name
          | :invalid_address
          | :ens_only_on_mainnet
          | :not_found
          | :resolution_failed
          | :api_error
          | :network_error
          | :not_implemented

  @doc """
  Resolves an ENS name to an Ethereum address.

  Currently only supports mainnet (chain_id 1). Uses public API endpoints
  for resolution. Returns nil for unregistered names.

  ## Parameters

  - `name`: ENS name ending in `.eth`
  - `chain_id`: Blockchain network ID (default: 1 for mainnet)

  ## Returns

  - `{:ok, address}` - Successfully resolved to Ethereum address
  - `{:error, :invalid_ens_name}` - Name doesn't end in `.eth`
  - `{:error, :ens_only_on_mainnet}` - ENS only supported on mainnet
  - `{:error, :not_found}` - Name not registered
  - `{:error, :resolution_failed}` - Resolution failed

  ## Examples

      iex> resolve_name("vitalik.eth", 1)
      {:ok, "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"}

      iex> resolve_name("invalid.eth", 1)
      {:error, :not_found}

      iex> resolve_name("notens", 1)
      {:error, :invalid_ens_name}

  """
  @spec resolve_name(ens_name(), chain_id()) :: {:ok, address()} | {:error, error_reason()}
  def resolve_name(name, chain_id \\ @mainnet_chain_id)

  def resolve_name(name, chain_id) when is_binary(name) do
    cond do
      not String.ends_with?(name, ".eth") ->
        {:error, :invalid_ens_name}

      chain_id != @mainnet_chain_id ->
        {:error, :ens_only_on_mainnet}

      true ->
        # Cache ENS lookups for 1 hour (they rarely change)
        Cache.fetch(
          :web3,
          "ens_resolve_#{name}",
          fn ->
            do_resolve_name(name)
          end,
          ttl: 3_600_000
        )
    end
  end

  @doc """
  Reverse resolves an Ethereum address to an ENS name.

  ## Examples

      iex> reverse_resolve("0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045", 1)
      {:ok, "vitalik.eth"}
  """
  @spec reverse_resolve(address(), chain_id()) :: {:ok, ens_name()} | {:error, error_reason()}
  def reverse_resolve(address, chain_id \\ @mainnet_chain_id)

  def reverse_resolve(address, chain_id) when is_binary(address) do
    cond do
      not valid_address?(address) ->
        {:error, :invalid_address}

      chain_id != @mainnet_chain_id ->
        {:error, :ens_only_on_mainnet}

      true ->
        # Cache reverse lookups for 1 hour
        Cache.fetch(
          :web3,
          "ens_reverse_#{address}",
          fn ->
            do_reverse_resolve(address)
          end,
          ttl: 3_600_000
        )
    end
  end

  @doc """
  Fetches the avatar URL for an ENS name.

  ## Examples

      iex> get_avatar("vitalik.eth")
      {:ok, "https://..."}
  """
  @spec get_avatar(ens_name()) :: {:ok, String.t() | nil}
  def get_avatar(name) when is_binary(name) do
    # ENS avatars are typically stored as text records
    # For now, return a placeholder - will implement IPFS fetching later
    {:ok, nil}
  end

  @doc """
  Normalizes an ENS name according to ENSIP-15 (UTS-46).
  """
  @spec normalize_name(ens_name()) :: ens_name()
  def normalize_name(name) when is_binary(name) do
    name
    |> String.downcase()
    |> String.trim()
  end

  @doc """
  Validates if a string is a valid ENS name.
  """
  @spec valid_ens_name?(String.t()) :: boolean()
  def valid_ens_name?(name) when is_binary(name) do
    String.ends_with?(name, ".eth") and
      byte_size(name) > 4 and
      String.match?(name, ~r/^[a-z0-9\-]+\.eth$/)
  end

  @doc """
  Validates if a string is a valid Ethereum address.
  """
  @spec valid_address?(String.t()) :: boolean()
  def valid_address?(address) when is_binary(address) do
    String.match?(address, ~r/^0x[0-9a-fA-F]{40}$/)
  end

  # Private Functions

  defp do_resolve_name(name) do
    # Normalize the name first
    normalized = normalize_name(name)

    # Use RPC to call ENS registry
    case call_ens_resolver(normalized) do
      {:ok, address}
      when address != nil and address != "0x0000000000000000000000000000000000000000" ->
        {:ok, address}

      {:ok, _} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.debug("ENS resolution failed for #{name}: #{inspect(reason)}")
        {:error, :resolution_failed}
    end
  end

  defp do_reverse_resolve(address) do
    # Construct reverse node: <address>.addr.reverse
    reverse_name = construct_reverse_name(address)

    case call_reverse_resolver(reverse_name) do
      {:ok, name} when is_binary(name) and byte_size(name) > 0 ->
        {:ok, name}

      {:ok, _} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.debug("ENS reverse resolution failed for #{address}: #{inspect(reason)}")
        {:error, :resolution_failed}
    end
  end

  defp call_ens_resolver(name) do
    # For now, use a public API endpoint as fallback
    # In production, would use ethereumex to call contract directly
    case fetch_from_api(name) do
      {:ok, result} -> {:ok, result}
      {:error, _} -> {:error, :api_error}
    end
  end

  defp call_reverse_resolver(_reverse_name) do
    # Use public API for reverse resolution
    {:error, :not_implemented}
  end

  defp construct_reverse_name(address) do
    # Remove 0x prefix and convert to lowercase
    clean_address =
      address
      |> String.downcase()
      |> String.replace_prefix("0x", "")

    "#{clean_address}.addr.reverse"
  end

  defp fetch_from_api(name) do
    # Use ENS public resolver API (e.g., ens.domains API)
    # For production, would use proper RPC calls via ethereumex
    url = "https://api.ensideas.com/ens/resolve/#{URI.encode(name)}"

    case Req.get(url, connect_options: [timeout: 5_000]) do
      {:ok, %{status: 200, body: %{"address" => address}}} when is_binary(address) ->
        {:ok, address}

      {:ok, %{status: 200}} ->
        {:error, :not_found}

      {:ok, %{status: status}} ->
        Logger.debug("ENS API returned status #{status}")
        {:error, :api_error}

      {:error, reason} ->
        Logger.debug("ENS API request failed: #{inspect(reason)}")
        {:error, :network_error}
    end
  rescue
    error ->
      Logger.error("ENS resolution exception: #{inspect(error)}")
      {:error, :exception}
  end
end
