# Web3 Integration Architecture

## Overview

This document outlines the architectural approach for integrating Web3 functionality into the droodotfoo terminal application. The integration follows a three-layer architecture matching our existing Raxol terminal framework.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│              Browser (JavaScript Layer)                  │
│  • Web3Modal/AppKit (multi-wallet support)              │
│  • ethers.js (wallet interaction)                       │
│  • LiveView Hooks (JS ↔ Elixir bridge)                 │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│           Phoenix LiveView (Orchestration)               │
│  • DroodotfooWeb.Web3Live (LiveView module)             │
│  • Event handling (wallet connect, sign, tx)            │
│  • State management (socket assigns)                    │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│              Elixir Backend (Business Logic)             │
│  • Droodotfoo.Web3.Manager (GenServer)                  │
│  • Ethers library (smart contract interaction)          │
│  • ENS, NFTs, Tokens, Transactions modules              │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│           Ethereum Network (External APIs)               │
│  • JSON-RPC endpoints (Infura, Alchemy, public nodes)   │
│  • OpenSea/Alchemy APIs (NFT data)                      │
│  • CoinGecko API (token prices)                         │
│  • Etherscan API (transaction history)                  │
└─────────────────────────────────────────────────────────┘
```

## Technology Stack

### Elixir Dependencies

```elixir
# mix.exs
defp deps do
  [
    # Web3 Integration
    {:ethers, "~> 0.6.7"},           # Comprehensive Web3 library
    {:ethereumex, "~> 0.10"},        # JSON-RPC client (dependency of ethers)
    {:ex_keccak, "~> 0.7"},          # Keccak hashing for Ethereum
    {:ex_secp256k1, "~> 0.7"},       # Signature verification

    # Existing dependencies
    {:phoenix, "~> 1.7.21"},
    {:phoenix_live_view, "~> 1.0.17"},
    {:jason, "~> 1.4"},
    {:req, "~> 0.4"}
  ]
end
```

### JavaScript Dependencies

```json
{
  "dependencies": {
    "ethers": "^6.13.0",
    "@reown/appkit": "^1.0.0",
    "@reown/appkit-adapter-ethers": "^1.0.0"
  }
}
```

### Configuration

```elixir
# config/runtime.exs
config :ethereumex,
  url: System.get_env("ETHEREUM_RPC_URL") || "https://eth.llamarpc.com",
  http_options: [timeout: 30_000, recv_timeout: 30_000]

config :droodotfoo, Droodotfoo.Web3.Manager,
  default_chain_id: String.to_integer(System.get_env("CHAIN_ID") || "1"),
  opensea_api_key: System.get_env("OPENSEA_API_KEY"),
  alchemy_api_key: System.get_env("ALCHEMY_API_KEY"),
  etherscan_api_key: System.get_env("ETHERSCAN_API_KEY"),
  walletconnect_project_id: System.get_env("WALLETCONNECT_PROJECT_ID")
```

## Module Structure

```
lib/droodotfoo/web3/
├── manager.ex              # GenServer managing Web3 state
├── api.ex                  # Ethereum RPC client wrapper
├── auth.ex                 # Wallet authentication (nonce, signature)
├── ens.ex                  # ENS resolution
├── tokens.ex               # ERC-20 token utilities
├── nfts.ex                 # NFT fetching/display
├── transactions.ex         # Transaction history
└── contracts.ex            # Smart contract interaction

lib/droodotfoo/plugins/
└── web3.ex                 # Interactive Web3 terminal plugin

lib/droodotfoo_web/live/
└── web3_live.ex            # LiveView for Web3 UI

assets/js/hooks/
├── web3_wallet.js          # Wallet connection hook
└── web3_transaction.js     # Transaction signing hook

test/droodotfoo/web3/
├── manager_test.exs
├── auth_test.exs
├── ens_test.exs
├── tokens_test.exs
├── nfts_test.exs
├── transactions_test.exs
└── contracts_test.exs
```

## Wallet Connection Flow

### 1. MetaMask Integration

```javascript
// assets/js/hooks/web3_wallet.js
export const Web3WalletHook = {
  async mounted() {
    this.provider = new ethers.BrowserProvider(window.ethereum);

    this.handleEvent("connect_wallet", async () => {
      try {
        const accounts = await this.provider.send("eth_requestAccounts", []);
        const address = accounts[0];
        const chainId = await this.provider.getNetwork().then(n => n.chainId);

        this.pushEvent("wallet_connected", { address, chainId });
      } catch (error) {
        this.pushEvent("wallet_error", { message: error.message });
      }
    });

    this.handleEvent("sign_message", async ({ message }) => {
      const signer = await this.provider.getSigner();
      const signature = await signer.signMessage(message);

      this.pushEvent("message_signed", { signature });
    });
  }
};
```

### 2. WalletConnect/Reown AppKit Integration

```javascript
// assets/js/hooks/web3_wallet.js (extended)
import { createAppKit } from '@reown/appkit';
import { EthersAdapter } from '@reown/appkit-adapter-ethers';

export const Web3WalletHook = {
  async mounted() {
    const projectId = this.el.dataset.projectId;

    // Configure supported chains
    const mainnet = { chainId: 1, name: 'Ethereum', ... };

    // Create Web3Modal instance
    this.modal = createAppKit({
      adapters: [new EthersAdapter()],
      networks: [mainnet],
      projectId,
      features: {
        analytics: false
      }
    });

    this.modal.subscribeProvider(({ provider, address, chainId }) => {
      if (address && chainId) {
        this.pushEvent("wallet_connected", { address, chainId });
      }
    });
  }
};
```

### 3. LiveView Event Handling

```elixir
# lib/droodotfoo_web/live/web3_live.ex
defmodule DroodotfooWeb.Web3Live do
  use DroodotfooWeb, :live_view
  alias Droodotfoo.Web3.{Manager, Auth}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:wallet_connected, false)
      |> assign(:wallet_address, nil)
      |> assign(:authenticated, false)
      |> assign(:nonce, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("wallet_connected", %{"address" => address, "chainId" => chain_id}, socket) do
    # Generate nonce for signature verification
    nonce = Auth.generate_nonce()
    message = Auth.format_auth_message(address, nonce)

    socket =
      socket
      |> assign(:wallet_address, address)
      |> assign(:wallet_connected, true)
      |> assign(:nonce, nonce)
      |> push_event("sign_message", %{message: message})

    {:noreply, socket}
  end

  @impl true
  def handle_event("message_signed", %{"signature" => signature}, socket) do
    address = socket.assigns.wallet_address
    nonce = socket.assigns.nonce

    case Auth.verify_signature(address, nonce, signature) do
      {:ok, verified_address} when verified_address == address ->
        # Start Web3 session
        Manager.start_session(address)

        socket =
          socket
          |> assign(:authenticated, true)
          |> put_flash(:info, "Wallet authenticated: #{String.slice(address, 0..9)}...")

        {:noreply, socket}

      {:error, reason} ->
        socket = put_flash(socket, :error, "Authentication failed: #{reason}")
        {:noreply, socket}
    end
  end
end
```

## Web3 Manager GenServer

```elixir
# lib/droodotfoo/web3/manager.ex
defmodule Droodotfoo.Web3.Manager do
  use GenServer
  require Logger

  @type state :: %{
    sessions: %{address() => session()},
    ens_cache: %{address() => String.t()},
    chain_id: integer()
  }

  @type address :: String.t()
  @type session :: %{
    address: address(),
    connected_at: DateTime.t(),
    last_activity: DateTime.t()
  }

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_session(address) do
    GenServer.call(__MODULE__, {:start_session, address})
  end

  def get_session(address) do
    GenServer.call(__MODULE__, {:get_session, address})
  end

  def resolve_ens(address) do
    GenServer.call(__MODULE__, {:resolve_ens, address})
  end

  ## Server Callbacks

  @impl true
  def init(opts) do
    state = %{
      sessions: %{},
      ens_cache: %{},
      chain_id: Keyword.get(opts, :default_chain_id, 1)
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:start_session, address}, _from, state) do
    session = %{
      address: address,
      connected_at: DateTime.utc_now(),
      last_activity: DateTime.utc_now()
    }

    state = put_in(state.sessions[address], session)
    Logger.info("Web3 session started for #{address}")

    {:reply, {:ok, session}, state}
  end

  @impl true
  def handle_call({:get_session, address}, _from, state) do
    session = Map.get(state.sessions, address)
    {:reply, {:ok, session}, state}
  end

  @impl true
  def handle_call({:resolve_ens, address}, _from, state) do
    case Map.get(state.ens_cache, address) do
      nil ->
        # Resolve ENS from blockchain
        case Droodotfoo.Web3.ENS.lookup(address) do
          {:ok, ens_name} ->
            state = put_in(state.ens_cache[address], ens_name)
            {:reply, {:ok, ens_name}, state}

          {:error, _} = error ->
            {:reply, error, state}
        end

      cached_name ->
        {:reply, {:ok, cached_name}, state}
    end
  end
end
```

## Authentication Module

```elixir
# lib/droodotfoo/web3/auth.ex
defmodule Droodotfoo.Web3.Auth do
  @moduledoc """
  Handles Web3 wallet authentication using message signing.
  Prevents replay attacks via nonces.
  """

  @doc """
  Generate a random nonce for signature verification.
  """
  def generate_nonce do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Format the authentication message to be signed.
  """
  def format_auth_message(address, nonce) do
    """
    Welcome to droo.foo!

    Sign this message to authenticate your wallet:
    #{address}

    Nonce: #{nonce}

    This request will not trigger a blockchain transaction or cost any gas fees.
    """
  end

  @doc """
  Verify the signature and recover the signing address.
  """
  def verify_signature(address, nonce, signature) do
    message = format_auth_message(address, nonce)

    # Use ExSecp256k1 or Ethers library for signature recovery
    case Ethers.Utils.recover_address(message, signature) do
      {:ok, recovered_address} ->
        if String.downcase(recovered_address) == String.downcase(address) do
          {:ok, recovered_address}
        else
          {:error, :address_mismatch}
        end

      {:error, _} = error ->
        error
    end
  end
end
```

## Security Considerations

1. **Nonce-based Authentication**
   - Generate unique nonce for each auth attempt
   - Store nonces in memory (GenServer or ETS) with TTL
   - Prevent replay attacks by invalidating used nonces

2. **Signature Verification**
   - Verify signatures server-side using ExSecp256k1
   - Ensure recovered address matches claimed address
   - Never trust client-side validation alone

3. **Session Management**
   - Store active sessions in Web3.Manager GenServer
   - Implement session timeout (e.g., 24 hours)
   - Clean up expired sessions periodically

4. **Rate Limiting**
   - Limit wallet connection attempts (prevent DoS)
   - Rate limit RPC calls to external APIs
   - Cache frequently accessed data (ENS, balances)

5. **Input Validation**
   - Validate Ethereum addresses (checksum, format)
   - Sanitize all user inputs
   - Validate chain IDs before operations

## Terminal UI Integration

The Web3 functionality will be accessible via:

1. **Navigation Key**: Press `8` or `:web3` to access Web3 section
2. **Commands**:
   - `:web3 connect` - Connect wallet
   - `:wallet` - Show wallet info
   - `:nft list` - Browse NFTs
   - `:tokens` - View token balances
   - `:tx history` - Transaction history
   - `:ens <name>` - Resolve ENS name

3. **ASCII Rendering**:
   - Wallet address: `0x1234...5678` (abbreviated)
   - Connection status: `[CONNECTED]` / `[DISCONNECTED]`
   - NFT thumbnails: ASCII art conversion
   - Token balances: Formatted tables

## Implementation Phases

### Phase 6.1: Foundation (Week 1)
- [ ] Add dependencies (ethers, ethereumex)
- [ ] Create Web3.Manager GenServer
- [ ] Implement Web3.Auth module
- [ ] Setup JavaScript hooks (web3_wallet.js)
- [ ] Basic wallet connection (MetaMask)

### Phase 6.2: Wallet Integration (Week 2)
- [ ] WalletConnect/Reown AppKit integration
- [ ] Multi-wallet support
- [ ] Session management
- [ ] Navigation UI integration

### Phase 6.3: ENS Support (Week 3)
- [ ] ENS resolution module
- [ ] ENS avatar fetching
- [ ] ASCII art rendering for avatars
- [ ] Caching with TTL

### Phase 6.4: NFT Gallery (Week 4)
- [ ] OpenSea/Alchemy API integration
- [ ] NFT metadata fetching
- [ ] ASCII thumbnail generation
- [ ] Grid view rendering
- [ ] Detail view with traits

### Phase 6.5: Token Balances (Week 5)
- [ ] ERC-20 token detection
- [ ] Balance fetching
- [ ] Price integration (CoinGecko)
- [ ] Portfolio visualization

### Phase 6.6: Transaction History (Week 6)
- [ ] Etherscan API integration
- [ ] Transaction parsing
- [ ] ASCII table rendering
- [ ] Pagination support

### Phase 6.7: Smart Contracts (Week 7)
- [ ] ABI viewer
- [ ] Read-only contract calls
- [ ] Function exploration
- [ ] Verification status

### Phase 6.8: IPFS (Week 8)
- [ ] IPFS gateway integration
- [ ] Content fetching
- [ ] CID handling
- [ ] Metadata resolution

## Testing Strategy

1. **Unit Tests**
   - Web3.Auth signature verification
   - Web3.Manager state management
   - ENS resolution logic
   - Token balance calculations

2. **Integration Tests**
   - LiveView event handling
   - JavaScript hook communication
   - RPC client interactions
   - API integrations

3. **E2E Tests**
   - Wallet connection flow
   - Authentication process
   - NFT browsing
   - Transaction viewing

4. **Mock Strategies**
   - Mock Ethereum RPC responses
   - Mock OpenSea/Alchemy APIs
   - Use testnet for real integration tests
   - Stub external API calls in CI

## Performance Optimization

1. **Caching**
   - ENS names (1 hour TTL)
   - Token metadata (24 hours)
   - NFT thumbnails (persistent)
   - API responses (5-15 minutes)

2. **Rate Limiting**
   - Implement exponential backoff for API calls
   - Queue RPC requests to prevent flooding
   - Batch multiple calls when possible

3. **Lazy Loading**
   - Load NFTs on-demand (pagination)
   - Stream large transaction histories
   - Progressive rendering in terminal

## Environment Variables

```bash
# Required
ETHEREUM_RPC_URL=https://eth.llamarpc.com
WALLETCONNECT_PROJECT_ID=your_project_id

# Optional (for enhanced features)
ALCHEMY_API_KEY=your_alchemy_key
OPENSEA_API_KEY=your_opensea_key
ETHERSCAN_API_KEY=your_etherscan_key
CHAIN_ID=1  # 1 for mainnet, 5 for Goerli, etc.
```

## Resources

- [Ethers Elixir Docs](https://hexdocs.pm/ethers)
- [WalletConnect Docs](https://docs.walletconnect.com)
- [MetaMask Integration Guide](https://blog.finiam.com/blog/sign-in-with-metamask-using-liveview)
- [Phoenix LiveView JS Interop](https://hexdocs.pm/phoenix_live_view/js-interop.html)
- [Ethereum JSON-RPC Spec](https://ethereum.github.io/execution-apis/api-documentation/)

---

**Last Updated:** October 6, 2025
**Status:** Planning Phase
**Next Steps:** Begin Phase 6.1 implementation
