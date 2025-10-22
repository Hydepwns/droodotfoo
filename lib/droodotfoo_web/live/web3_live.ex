defmodule DroodotfooWeb.Web3Live do
  @moduledoc """
  Web3 demos and capabilities showcase.
  Simple page demonstrating ENS resolution, wallet integration, and blockchain features.
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.Web3.ENS
  import DroodotfooWeb.ContentComponents

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "Web3")
    |> assign(:ens_query, "")
    |> assign(:ens_result, nil)
    |> assign(:ens_loading, false)
    |> assign(:wallet_connected, false)
    |> assign(:wallet_address, nil)
    |> assign(:chain_id, 1)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("resolve_ens", %{"ens" => ens_name}, socket) do
    socket
    |> assign(:ens_query, ens_name)
    |> assign(:ens_loading, true)
    |> assign(:ens_result, nil)
    |> then(fn socket ->
      # Attempt ENS resolution
      case ENS.resolve_name(ens_name) do
        {:ok, address} ->
          socket
          |> assign(:ens_result, {:success, address})
          |> assign(:ens_loading, false)

        {:error, reason} ->
          socket
          |> assign(:ens_result, {:error, reason})
          |> assign(:ens_loading, false)
      end
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("clear_ens", _params, socket) do
    socket
    |> assign(:ens_query, "")
    |> assign(:ens_result, nil)
    |> then(&{:noreply, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout
      page_title="Web3 Capabilities"
      page_description="Blockchain integration and decentralized features"
    >
      <section>
        <h2 class="section-title">ENS Name Resolution</h2>
        <p>
          Resolve Ethereum Name Service (ENS) names to addresses. Try entering
          an ENS name like "vitalik.eth" or "droo.eth".
        </p>

        <form phx-submit="resolve_ens" class="mt-2">
          <div class="box-single">
            <label for="ens">ENS Name:</label>
            <div class="input-with-button">
              <input
                type="text"
                id="ens"
                name="ens"
                value={@ens_query}
                placeholder="vitalik.eth"
              />
              <button type="submit" disabled={@ens_loading}>
                {if @ens_loading, do: "RESOLVING...", else: "RESOLVE"}
              </button>
              <%= if @ens_query != "" do %>
                <button type="button" phx-click="clear_ens">CLEAR</button>
              <% end %>
            </div>
          </div>
        </form>

        <%= if @ens_result do %>
          <div class="terminal-output mt-1">
            <%= case @ens_result do %>
              <% {:success, address} -> %>
                <pre>Successfully resolved:
                  ENS Name: <%= @ens_query %>
                  Address:  <%= address %>
                </pre>
              <% {:error, reason} -> %>
                <pre>Error: <%= reason %></pre>
            <% end %>
          </div>
        <% end %>
      </section>

      <hr class="section-divider" />

      <section>
        <h2 class="section-title">Supported Networks</h2>
        <p>Multi-chain support across major Ethereum networks.</p>

        <table class="mt-2">
          <thead>
            <tr>
              <th>Network</th>
              <th>Chain ID</th>
              <th>Type</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Ethereum Mainnet</td>
              <td>1</td>
              <td>Production</td>
            </tr>
            <tr>
              <td>Sepolia</td>
              <td>11155111</td>
              <td>Testnet</td>
            </tr>
            <tr>
              <td>Polygon</td>
              <td>137</td>
              <td>L2 Scaling</td>
            </tr>
            <tr>
              <td>Arbitrum</td>
              <td>42161</td>
              <td>L2 Scaling</td>
            </tr>
            <tr>
              <td>Optimism</td>
              <td>10</td>
              <td>L2 Scaling</td>
            </tr>
            <tr>
              <td>Base</td>
              <td>8453</td>
              <td>L2 Scaling</td>
            </tr>
          </tbody>
        </table>
      </section>

      <hr class="section-divider" />

      <section>
        <h2 class="section-title">Features</h2>

        <dl class="mt-2">
          <dt>Wallet Integration</dt>
          <dd>
            Connect with MetaMask to sign transactions and interact with smart contracts.
            Full support for wallet authentication and message signing.
          </dd>

          <dt>ENS Integration</dt>
          <dd>
            Resolve ENS names to Ethereum addresses and vice versa. Supports both forward
            and reverse resolution on Ethereum mainnet.
          </dd>

          <dt>Multi-Chain Support</dt>
          <dd>
            Works across Ethereum mainnet, L2 networks (Polygon, Arbitrum, Optimism, Base),
            and testnets (Sepolia). Automatic network detection and switching.
          </dd>

          <dt>NFT Gallery (Coming Soon)</dt>
          <dd>
            View NFTs from any wallet address. Support for ERC-721 and ERC-1155 standards
            with IPFS metadata resolution.
          </dd>

          <dt>Token Balances (Coming Soon)</dt>
          <dd>
            Check ERC-20 token balances for any address. Real-time price feeds and
            portfolio valuation.
          </dd>

          <dt>Transaction History (Coming Soon)</dt>
          <dd>
            Browse transaction history with decoded contract interactions and
            human-readable function calls.
          </dd>
        </dl>
      </section>
    </.page_layout>
    """
  end
end
