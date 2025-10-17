defmodule Droodotfoo.Web3.Contract do
  @moduledoc """
  Smart contract interaction utilities.

  Fetches contract ABIs, displays functions/events, and enables read-only calls.
  """

  require Logger

  @type contract_info :: %{
          address: String.t(),
          name: String.t(),
          compiler_version: String.t(),
          optimization_used: boolean(),
          runs: integer(),
          constructor_arguments: String.t(),
          evm_version: String.t(),
          library: String.t(),
          license_type: String.t(),
          proxy: boolean(),
          implementation: String.t() | nil,
          verified: boolean()
        }

  @type abi_function :: %{
          type: String.t(),
          name: String.t(),
          inputs: [abi_param()],
          outputs: [abi_param()],
          state_mutability: String.t(),
          constant: boolean()
        }

  @type abi_event :: %{
          type: String.t(),
          name: String.t(),
          inputs: [abi_param()],
          anonymous: boolean()
        }

  @type abi_param :: %{
          name: String.t(),
          type: String.t(),
          indexed: boolean() | nil
        }

  # Etherscan API for contract verification and ABI
  # Reserved for future Etherscan API integration
  # @etherscan_api_base "https://api.etherscan.io/api"

  @doc """
  Fetch contract information and ABI from Etherscan.

  ## Parameters

  - `address`: Contract address (0x-prefixed)

  ## Examples

      iex> Droodotfoo.Web3.Contract.fetch_contract("0x1234...")
      {:ok, %{address: "0x1234...", verified: true, abi: [...]}}

  """
  @spec fetch_contract(String.t()) :: {:ok, contract_info()} | {:error, atom()}
  def fetch_contract(address) do
    if valid_address?(address) do
      # For demo purposes, return mock data
      # Production would call Etherscan API with API key
      {:ok, mock_contract_info(address)}
    else
      {:error, :invalid_address}
    end
  end

  @doc """
  Parse contract ABI and extract functions.

  ## Examples

      iex> Droodotfoo.Web3.Contract.parse_abi(abi_json)
      {:ok, %{functions: [...], events: [...]}}

  """
  @spec parse_abi(String.t()) ::
          {:ok, %{functions: [abi_function()], events: [abi_event()]}} | {:error, atom()}
  def parse_abi(abi_json) when is_binary(abi_json) do
    case Jason.decode(abi_json) do
      {:ok, abi} when is_list(abi) ->
        functions = Enum.filter(abi, &(&1["type"] == "function"))
        events = Enum.filter(abi, &(&1["type"] == "event"))

        parsed_functions = Enum.map(functions, &parse_function/1)
        parsed_events = Enum.map(events, &parse_event/1)

        {:ok, %{functions: parsed_functions, events: parsed_events}}

      {:ok, _} ->
        {:error, :invalid_abi}

      {:error, _} ->
        {:error, :json_parse_error}
    end
  end

  def parse_abi(_), do: {:error, :invalid_input}

  @doc """
  Call a read-only contract function.

  ## Examples

      iex> Droodotfoo.Web3.Contract.call_function("0x1234...", "totalSupply", [])
      {:ok, "1000000000000000000000000"}

  """
  @spec call_function(String.t(), String.t(), [any()]) :: {:ok, any()} | {:error, atom()}
  def call_function(address, function_name, args \\ []) do
    if valid_address?(address) do
      # Mock implementation - production would use Ethereumex/Ethers
      {:ok, mock_function_result(function_name, args)}
    else
      {:error, :invalid_address}
    end
  end

  @doc """
  Format function signature for display.

  ## Examples

      iex> Droodotfoo.Web3.Contract.format_function_signature(func)
      "balanceOf(address) view returns (uint256)"

  """
  @spec format_function_signature(abi_function()) :: String.t()
  def format_function_signature(func) do
    inputs = format_params(func.inputs)

    outputs =
      if Enum.empty?(func.outputs), do: "", else: " returns (#{format_params(func.outputs)})"

    mutability =
      if func.state_mutability != "nonpayable", do: " #{func.state_mutability}", else: ""

    "#{func.name}(#{inputs})#{mutability}#{outputs}"
  end

  @doc """
  Format event signature for display.

  ## Examples

      iex> Droodotfoo.Web3.Contract.format_event_signature(event)
      "Transfer(address indexed from, address indexed to, uint256 value)"

  """
  @spec format_event_signature(abi_event()) :: String.t()
  def format_event_signature(event) do
    inputs = format_event_params(event.inputs)
    "#{event.name}(#{inputs})"
  end

  @doc """
  Check if contract is a proxy and get implementation address.

  ## Examples

      iex> Droodotfoo.Web3.Contract.check_proxy("0x1234...")
      {:ok, "0x5678..."}

  """
  @spec check_proxy(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def check_proxy(address) do
    if valid_address?(address) do
      # Mock implementation
      # Production would check EIP-1967 storage slots or call implementation()
      {:error, :not_proxy}
    else
      {:error, :invalid_address}
    end
  end

  ## Private Functions

  defp mock_contract_info(address) do
    # Return mock ERC-20 token contract
    %{
      address: address,
      name: "MockToken",
      compiler_version: "v0.8.20+commit.a1b79de6",
      optimization_used: true,
      runs: 200,
      constructor_arguments: "",
      evm_version: "Default",
      library: "",
      license_type: "MIT",
      proxy: false,
      implementation: nil,
      verified: true,
      abi: mock_erc20_abi()
    }
  end

  defp mock_erc20_abi do
    """
    [
      {
        "type": "function",
        "name": "name",
        "inputs": [],
        "outputs": [{"name": "", "type": "string"}],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "symbol",
        "inputs": [],
        "outputs": [{"name": "", "type": "string"}],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "decimals",
        "inputs": [],
        "outputs": [{"name": "", "type": "uint8"}],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "totalSupply",
        "inputs": [],
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "balanceOf",
        "inputs": [{"name": "account", "type": "address"}],
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "transfer",
        "inputs": [{"name": "to", "type": "address"}, {"name": "amount", "type": "uint256"}],
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "nonpayable"
      },
      {
        "type": "function",
        "name": "allowance",
        "inputs": [{"name": "owner", "type": "address"}, {"name": "spender", "type": "address"}],
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "approve",
        "inputs": [{"name": "spender", "type": "address"}, {"name": "amount", "type": "uint256"}],
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "nonpayable"
      },
      {
        "type": "event",
        "name": "Transfer",
        "inputs": [
          {"name": "from", "type": "address", "indexed": true},
          {"name": "to", "type": "address", "indexed": true},
          {"name": "value", "type": "uint256", "indexed": false}
        ],
        "anonymous": false
      },
      {
        "type": "event",
        "name": "Approval",
        "inputs": [
          {"name": "owner", "type": "address", "indexed": true},
          {"name": "spender", "type": "address", "indexed": true},
          {"name": "value", "type": "uint256", "indexed": false}
        ],
        "anonymous": false
      }
    ]
    """
  end

  defp parse_function(func_map) do
    %{
      type: func_map["type"],
      name: func_map["name"],
      inputs: parse_params(func_map["inputs"] || []),
      outputs: parse_params(func_map["outputs"] || []),
      state_mutability: func_map["stateMutability"] || "nonpayable",
      constant: func_map["constant"] || false
    }
  end

  defp parse_event(event_map) do
    %{
      type: event_map["type"],
      name: event_map["name"],
      inputs: parse_params(event_map["inputs"] || []),
      anonymous: event_map["anonymous"] || false
    }
  end

  defp parse_params(params) when is_list(params) do
    Enum.map(params, fn param ->
      %{
        name: param["name"] || "",
        type: param["type"],
        indexed: param["indexed"]
      }
    end)
  end

  defp format_params(params) do
    Enum.map_join(params, ", ", fn param ->
      if param.name != "", do: "#{param.type} #{param.name}", else: param.type
    end)
  end

  defp format_event_params(params) do
    Enum.map_join(params, ", ", fn param ->
      indexed = if param.indexed, do: "indexed ", else: ""
      name = if param.name != "", do: " #{param.name}", else: ""
      "#{param.type} #{indexed}#{name}"
    end)
  end

  defp mock_function_result(function_name, _args) do
    case function_name do
      "name" -> "Mock Token"
      "symbol" -> "MOCK"
      "decimals" -> 18
      "totalSupply" -> "1000000000000000000000000"
      "balanceOf" -> "100000000000000000000"
      "allowance" -> "0"
      _ -> "0"
    end
  end

  defp valid_address?(address) when is_binary(address) do
    String.match?(address, ~r/^0x[a-fA-F0-9]{40}$/)
  end

  defp valid_address?(_), do: false
end
