defmodule Droodotfoo.Terminal.Commands.Web3 do
  @moduledoc """
  Web3 command implementations for the terminal.

  Provides commands for:
  - Wallet connection: web3, wallet, w3
  - ENS resolution: ens
  - NFT viewing: nft, nfts
  - Token balances: tokens, balance, crypto
  - Transaction history: tx, transactions
  - Smart contracts: contract, call
  """

  use Droodotfoo.Terminal.CommandBase

  alias Droodotfoo.Web3
  alias Droodotfoo.Web3.{Contract, NFT, Token, Transaction}

  @impl true
  def execute("web3", args, state), do: web3(args, state)
  def execute("wallet", args, state), do: wallet(args, state)
  def execute("w3", args, state), do: w3(args, state)
  def execute("ens", args, state), do: ens(args, state)
  def execute("nft", args, state), do: nft(args, state)
  def execute("nfts", args, state), do: nfts(args, state)
  def execute("tokens", args, state), do: tokens(args, state)
  def execute("crypto", args, state), do: crypto(args, state)
  def execute("balance", args, state), do: balance(args, state)
  def execute("tx", args, state), do: tx(args, state)
  def execute("transactions", args, state), do: transactions(args, state)
  def execute("contract", args, state), do: contract(args, state)
  def execute("call", args, state), do: call(args, state)

  def execute(command, _args, state) do
    {:error, "Unknown Web3 command: #{command}", state}
  end

  # Wallet Connection

  @doc """
  Navigate to Web3 wallet interface or perform wallet operations.
  """
  def web3([], state) do
    new_state = Map.put(state, :section_change, :web3)
    {:ok, "Opening Web3 wallet interface...", new_state}
  end

  def web3(["connect" | _], state) do
    new_state =
      state
      |> Map.put(:section_change, :web3)
      |> Map.put(:web3_action, :connect)

    {:ok, "Initiating wallet connection...", new_state}
  end

  def web3(["disconnect" | _], state) do
    new_state = Map.put(state, :web3_action, :disconnect)
    {:ok, "Disconnecting wallet...", new_state}
  end

  def web3([subcommand | _], _state) do
    {:error,
     "Unknown web3 subcommand: #{subcommand}\n\nUsage:\n  web3         - Open Web3 interface\n  web3 connect - Connect wallet\n  web3 disconnect - Disconnect wallet"}
  end

  def wallet(args, state), do: web3(["connect" | args], state)
  def w3(args, state), do: web3(args, state)

  # ENS Resolution

  @doc """
  Resolve ENS names to Ethereum addresses.
  """
  def ens([], _state) do
    {:error, "Usage: ens <name.eth> - Resolve ENS name to address"}
  end

  def ens([name | _], _state) do
    if String.ends_with?(name, ".eth") do
      case Web3.lookup_ens(name) do
        {:ok, address} ->
          output = """
          ENS Resolution:
            Name:    #{name}
            Address: #{address}
          """

          {:ok, String.trim(output)}

        {:error, :invalid_ens_name} ->
          {:error, "Invalid ENS name: #{name}"}

        {:error, :ens_only_on_mainnet} ->
          {:error, "ENS is only available on Ethereum mainnet"}

        {:error, :not_found} ->
          {:error, "ENS name not found: #{name}"}

        {:error, reason} ->
          {:error, "Failed to resolve ENS: #{reason}"}
      end
    else
      {:error, "ENS names must end with .eth (e.g., vitalik.eth)"}
    end
  end

  # NFT Commands

  @doc """
  List or view NFTs.
  """
  def nft([], _state) do
    {:error,
     "Usage:\n  nft list [address]     - List NFTs for an address\n  nft view <contract> <id> - View NFT details"}
  end

  def nft(["list"], state) do
    case Map.get(state, :web3_wallet_address) do
      nil ->
        {:error, "No wallet connected. Use 'web3 connect' first."}

      address ->
        nft(["list", address], state)
    end
  end

  def nft(["list", address], _state) do
    case NFT.fetch_nfts(address, limit: 10) do
      {:ok, []} ->
        {:ok, "No NFTs found for address: #{address}"}

      {:ok, nfts} ->
        output =
          nfts
          |> Enum.with_index(1)
          |> Enum.map_join("\n\n", fn {nft, idx} ->
            "#{idx}. #{nft.name}\n   Collection: #{nft.collection_name}\n   Token ID: #{nft.token_id}\n   Standard: #{nft.token_standard}"
          end)

        header = "NFTs owned by #{address}:\n\n"
        {:ok, header <> output}

      {:error, :invalid_address} ->
        {:error, "Invalid Ethereum address"}

      {:error, _reason} ->
        {:error, "Failed to fetch NFTs. Check network connection."}
    end
  end

  def nft(["view", contract_address, token_id], _state) do
    case NFT.fetch_nft(contract_address, token_id) do
      {:ok, nft} ->
        {:ok, ascii_art} = NFT.image_to_ascii(nft.image_url)

        properties_text = format_nft_properties(nft.properties)

        output = """
        #{ascii_art}

        Name: #{nft.name}
        Collection: #{nft.collection_name}
        Token ID: #{nft.token_id}
        Standard: #{nft.token_standard}
        Contract: #{nft.contract_address}

        Description:
        #{String.slice(nft.description, 0..200)}#{if String.length(nft.description) > 200, do: "...", else: ""}#{properties_text}
        """

        {:ok, String.trim(output)}

      {:error, :invalid_contract_address} ->
        {:error, "Invalid contract address"}

      {:error, _reason} ->
        {:error, "Failed to fetch NFT. Check contract address and token ID."}
    end
  end

  def nft([subcommand | _], _state) do
    {:error, "Unknown nft subcommand: #{subcommand}"}
  end

  def nfts([], state), do: nft(["list"], state)
  def nfts([address], state), do: nft(["list", address], state)

  # Token Balance Commands

  @doc """
  List token balances for connected wallet or address.
  """
  def tokens([], state) do
    case Map.get(state, :web3_wallet_address) do
      nil ->
        {:error, "No wallet connected. Use 'web3 connect' first."}

      address ->
        tokens(["list", address], state)
    end
  end

  def tokens(["list"], state) do
    case Map.get(state, :web3_wallet_address) do
      nil ->
        {:error, "No wallet connected. Use 'web3 connect' first."}

      address ->
        tokens(["list", address], state)
    end
  end

  def tokens(["list", address], _state) do
    case Token.fetch_balances(address) do
      {:ok, []} ->
        {:ok, "No token balances found for address: #{address}"}

      {:ok, balances} ->
        non_zero = Enum.filter(balances, fn t -> t.balance_formatted > 0 end)

        if Enum.empty?(non_zero) do
          {:ok, "No token balances found (all balances are zero)"}
        else
          header =
            "Token Balances for #{String.slice(address, 0..9)}...#{String.slice(address, -4..-1)}\n\n"

          rows = Enum.map_join(non_zero, "\n", &format_token_balance_row/1)

          {:ok, header <> rows}
        end

      {:error, :invalid_address} ->
        {:error, "Invalid Ethereum address"}

      {:error, _reason} ->
        {:error, "Failed to fetch token balances. Check network connection."}
    end
  end

  def tokens([subcommand | _], _state) do
    {:error,
     "Unknown tokens subcommand: #{subcommand}\n\nUsage:\n  tokens          - List token balances\n  tokens list     - List token balances\n  balance <symbol> - Get price for a specific token"}
  end

  @doc """
  Get USD price and chart for a specific token.
  """
  def balance([], _state) do
    {:error, "Usage: balance <symbol> - Get USD price and chart for a token (e.g., balance ETH)"}
  end

  def balance([symbol | _], _state) do
    symbol_upper = String.upcase(symbol)

    with {:ok, price_data} <- Token.get_token_price(symbol_upper),
         {:ok, history} <- Token.get_price_history(symbol_upper, 7) do
      chart = Token.price_chart(history)

      change_str =
        if price_data.usd_24h_change >= 0 do
          "+#{:erlang.float_to_binary(price_data.usd_24h_change, decimals: 2)}%"
        else
          "#{:erlang.float_to_binary(price_data.usd_24h_change, decimals: 2)}%"
        end

      output = """
      #{symbol_upper} Price Information

      Current Price: $#{:erlang.float_to_binary(price_data.usd, decimals: 2)}
      24h Change:    #{change_str}

      7-Day Price Chart:
      #{chart}
      """

      {:ok, String.trim(output)}
    else
      {:error, :token_not_found} ->
        {:error,
         "Token not found: #{symbol}. Supported tokens: ETH, USDT, USDC, DAI, WBTC, LINK, MATIC, UNI, AAVE"}

      {:error, :rate_limit} ->
        {:error, "CoinGecko API rate limit reached. Please try again later."}

      {:error, _reason} ->
        {:error, "Failed to fetch price for #{symbol}. Check network connection."}
    end
  end

  def crypto(args, state), do: tokens(args, state)

  # Transaction History

  @doc """
  View transaction history or details.
  """
  def tx([], state) do
    case Map.get(state, :web3_wallet_address) do
      nil ->
        {:error, "No wallet connected. Use 'web3 connect' first."}

      address ->
        tx(["history", address], state)
    end
  end

  def tx(["history"], state) do
    case Map.get(state, :web3_wallet_address) do
      nil ->
        {:error, "No wallet connected. Use 'web3 connect' first."}

      address ->
        tx(["history", address], state)
    end
  end

  def tx(["history", address], _state) do
    case Transaction.fetch_history(address, limit: 10) do
      {:ok, []} ->
        {:ok, "No transactions found for address: #{address}"}

      {:ok, transactions} ->
        header = """
        Transaction History for #{Transaction.shorten(address)}

        """

        rows =
          transactions
          |> Enum.with_index(1)
          |> Enum.map_join("\n", fn {tx, idx} ->
            format_transaction_row(tx, idx)
          end)

        {:ok, header <> rows}

      {:error, :invalid_address} ->
        {:error, "Invalid Ethereum address"}

      {:error, _reason} ->
        {:error, "Failed to fetch transaction history"}
    end
  end

  def tx([tx_hash], _state) when byte_size(tx_hash) > 60 do
    case Transaction.fetch_transaction(tx_hash) do
      {:ok, tx} ->
        time = Transaction.format_timestamp(tx.timestamp)
        value = :erlang.float_to_binary(tx.value_eth, decimals: 6)
        gas_price_gwei = String.to_integer(tx.gas_price) / 1_000_000_000
        gas_cost = :erlang.float_to_binary(tx.gas_cost_eth, decimals: 6)
        status = if tx.status == "1", do: "Success", else: "Failed"

        output = """
        Transaction Details

        Hash:        #{tx.hash}
        Status:      #{status}
        Block:       #{tx.block_number}
        Timestamp:   #{time}

        From:        #{tx.from}
        To:          #{tx.to}
        Value:       #{value} ETH

        Gas Used:    #{tx.gas_used}
        Gas Price:   #{:erlang.float_to_binary(gas_price_gwei, decimals: 2)} Gwei
        Gas Cost:    #{gas_cost} ETH

        Method:      #{if tx.method == "", do: "Transfer", else: tx.method}
        """

        {:ok, String.trim(output)}

      {:error, :invalid_tx_hash} ->
        {:error, "Invalid transaction hash"}

      {:error, _reason} ->
        {:error, "Failed to fetch transaction details"}
    end
  end

  def tx([subcommand | _], _state) do
    {:error,
     "Unknown tx subcommand: #{subcommand}\n\nUsage:\n  tx                   - Show transaction history\n  tx history [address] - Show transaction history\n  tx <hash>            - View transaction details"}
  end

  def transactions(args, state), do: tx(["history" | args], state)

  # Smart Contract Interaction

  @doc """
  View contract information or call contract functions.
  """
  def contract([], _state) do
    {:error,
     "Usage:\n  contract <address>         - View contract info and ABI\n  contract <address> <function> [args...] - Call read-only function"}
  end

  def contract([address], _state) do
    case Contract.fetch_contract(address) do
      {:ok, contract_info} ->
        case Contract.parse_abi(contract_info.abi) do
          {:ok, %{functions: functions, events: events}} ->
            output = """
            Contract Information
            #{String.duplicate("=", 78)}

            Address:     #{contract_info.address}
            Name:        #{contract_info.name}
            Verified:    #{format_yes_no(contract_info.verified)}
            Compiler:    #{contract_info.compiler_version}
            License:     #{contract_info.license_type}
            Proxy:       #{format_yes_no(contract_info.proxy)}

            #{String.duplicate("-", 78)}
            VIEW FUNCTIONS (Read-only)
            #{String.duplicate("-", 78)}

            #{format_functions_list(functions, :view)}

            #{String.duplicate("-", 78)}
            WRITE FUNCTIONS (State-changing)
            #{String.duplicate("-", 78)}

            #{format_functions_list(functions, :write)}

            #{String.duplicate("-", 78)}
            EVENTS
            #{String.duplicate("-", 78)}

            #{format_events_list(events)}

            Usage: contract #{Transaction.shorten(address)} <function> [args...]
            """

            {:ok, output}

          {:error, reason} ->
            {:error, "Failed to parse ABI: #{reason}"}
        end

      {:error, :invalid_address} ->
        {:error, "Invalid contract address"}

      {:error, reason} ->
        {:error, "Failed to fetch contract: #{reason}"}
    end
  end

  def contract([address, function_name | args], _state) do
    case Contract.call_function(address, function_name, args) do
      {:ok, result} ->
        output = """
        Contract Call Result
        #{String.duplicate("=", 78)}

        Contract:  #{Transaction.shorten(address)}
        Function:  #{function_name}
        Arguments: #{if Enum.empty?(args), do: "(none)", else: inspect(args)}

        Result:    #{inspect(result)}
        """

        {:ok, output}

      {:error, :invalid_address} ->
        {:error, "Invalid contract address"}

      {:error, reason} ->
        {:error, "Function call failed: #{reason}"}
    end
  end

  def call([address, function_name | args], state) do
    contract([address, function_name | args], state)
  end

  def call(_args, _state) do
    {:error, "Usage: call <contract_address> <function> [args...]"}
  end

  # Helper Functions

  @doc false
  defp format_functions_list(functions, type) do
    filtered =
      case type do
        :view ->
          Enum.filter(functions, fn f ->
            f.state_mutability in ["view", "pure"]
          end)

        :write ->
          Enum.filter(functions, fn f ->
            f.state_mutability not in ["view", "pure"]
          end)
      end

    if Enum.empty?(filtered) do
      "  (none)"
    else
      Enum.map_join(filtered, "\n", fn func ->
        "  #{Contract.format_function_signature(func)}"
      end)
    end
  end

  @doc false
  defp format_events_list(events) do
    if Enum.empty?(events) do
      "  (none)"
    else
      Enum.map_join(events, "\n", fn event ->
        "  #{Contract.format_event_signature(event)}"
      end)
    end
  end

  defp format_nft_properties(properties) do
    if is_list(properties) and length(properties) > 0 do
      props =
        properties
        |> Enum.take(5)
        |> Enum.map_join("\n", fn prop ->
          trait_type = Map.get(prop, "trait_type", "Unknown")
          value = Map.get(prop, "value", "Unknown")
          "  - #{trait_type}: #{value}"
        end)

      "\n\nProperties:\n" <> props
    else
      ""
    end
  end

  defp format_token_balance_row(token) do
    balance_str = :erlang.float_to_binary(token.balance_formatted, decimals: 4)
    price_str = format_token_price(token.usd_price)
    value_str = format_token_value(token.usd_value)
    change_str = format_price_change(token.price_change_24h)

    "#{String.pad_trailing(token.symbol, 6)} #{String.pad_leading(balance_str, 12)} @ #{String.pad_leading(price_str, 10)} = #{String.pad_leading(value_str, 12)}  (#{change_str})"
  end

  defp format_token_price(nil), do: "N/A"
  defp format_token_price(price), do: "$#{:erlang.float_to_binary(price, decimals: 2)}"

  defp format_token_value(nil), do: "N/A"
  defp format_token_value(value), do: "$#{:erlang.float_to_binary(value, decimals: 2)}"

  defp format_price_change(nil), do: "N/A"

  defp format_price_change(change) do
    change_str = :erlang.float_to_binary(change, decimals: 2)

    if change >= 0 do
      "+#{change_str}%"
    else
      "#{change_str}%"
    end
  end

  defp format_transaction_row(tx, idx) do
    tx_hash = Transaction.shorten(tx.hash)
    from = Transaction.shorten(tx.from)
    to = Transaction.shorten(tx.to)
    value = :erlang.float_to_binary(tx.value_eth, decimals: 4)
    gas = :erlang.float_to_binary(tx.gas_cost_eth, decimals: 6)
    time_ago = format_time_ago(tx.timestamp)
    status = if tx.status == "1", do: "OK", else: "FAIL"

    "#{String.pad_leading(Integer.to_string(idx), 2)}. #{tx_hash} #{String.pad_trailing(from, 14)} -> #{String.pad_trailing(to, 14)} #{String.pad_leading(value, 10)} ETH  Gas: #{String.pad_leading(gas, 8)} ETH  #{String.pad_trailing(time_ago, 8)} [#{status}]"
  end

  defp format_time_ago(timestamp) do
    case DateTime.from_unix(timestamp) do
      {:ok, dt} ->
        diff = DateTime.diff(DateTime.utc_now(), dt)
        format_time_diff(diff)

      _ ->
        "Unknown"
    end
  end

  defp format_time_diff(diff) when diff < 60, do: "#{diff}s ago"
  defp format_time_diff(diff) when diff < 3600, do: "#{div(diff, 60)}m ago"
  defp format_time_diff(diff) when diff < 86_400, do: "#{div(diff, 3600)}h ago"
  defp format_time_diff(diff), do: "#{div(diff, 86_400)}d ago"

  defp format_yes_no(true), do: "YES"
  defp format_yes_no(_), do: "NO"
end
