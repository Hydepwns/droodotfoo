defmodule Droodotfoo.Raxol.Renderer.Web3 do
  @moduledoc """
  Web3 wallet UI rendering components for the terminal.
  Handles wallet connection prompts and connected wallet displays.
  """

  alias Droodotfoo.Raxol.BoxBuilder
  alias Droodotfoo.Raxol.Renderer.Helpers

  @doc """
  Draw the Web3 wallet connection prompt when wallet is not connected.
  """
  def draw_connect_prompt(state) do
    connecting = state.web3_connecting
    status = if connecting, do: "[CONNECTING...]", else: "[NOT CONNECTED]"

    wallet_info =
      BoxBuilder.inner_box("Supported Wallets", [
        "[>] MetaMask",
        "[>] WalletConnect (coming soon)",
        "[>] Coinbase Wallet (coming soon)"
      ])

    content =
      [
        "",
        "Status: #{status}",
        "",
        "Connect your wallet to access Web3 features:",
        ""
      ] ++
        wallet_info ++
        [
          "",
          "Commands:",
          "  :web3 connect   - Connect MetaMask wallet",
          "  :wallet         - Alias for :web3 connect",
          "  :w3             - Short alias",
          "",
          "Features available after connection:",
          "  [>] ENS Name Resolution (vitalik.eth)",
          "  [>] NFT Gallery Viewer",
          "  [>] Token Balances (ERC-20)",
          "  [>] Transaction History",
          "  [>] Smart Contract Interaction",
          ""
        ]

    BoxBuilder.build("Web3 Wallet", content)
  end

  @doc """
  Draw the connected Web3 wallet display with wallet info and available actions.
  """
  def draw_connected(state) do
    address = state.web3_wallet_address || "Unknown"
    chain_id = state.web3_chain_id || 1

    # Abbreviate address (0x1234...5678)
    abbreviated_address = Helpers.abbreviate_address(address)

    # Get network name
    network_name = Helpers.get_network_name(chain_id)

    # Build wallet details content
    wallet_details = [
      BoxBuilder.info_line("Wallet Address", abbreviated_address, label_width: 10)
    ]

    # Try to resolve ENS name (if on mainnet)
    wallet_details =
      if chain_id == 1 and address != "Unknown" do
        case Droodotfoo.Web3.resolve_ens(address) do
          {:ok, ens_name} when ens_name != address ->
            wallet_details ++
              [
                "",
                BoxBuilder.info_line("ENS Name", ens_name, label_width: 10)
              ]

          _ ->
            wallet_details
        end
      else
        wallet_details
      end

    wallet_details =
      wallet_details ++
        [
          "",
          BoxBuilder.info_line("Network", network_name, label_width: 10)
        ]

    wallet_box = BoxBuilder.inner_box("", wallet_details)

    content =
      [
        "",
        "Status: [CONNECTED]",
        ""
      ] ++
        wallet_box ++
        [
          "",
          "Available Commands:",
          "  :web3 disconnect   - Disconnect wallet",
          "  :ens <name>        - Resolve ENS name",
          "  :nft list          - View your NFTs",
          "  :tokens            - View token balances",
          "  :tx history        - View transaction history",
          "",
          "Quick Actions:",
          "  [D]isconnect  [E]NS  [N]FTs  [T]okens  [H]istory",
          ""
        ]

    BoxBuilder.build("Web3 Wallet", content)
  end
end
