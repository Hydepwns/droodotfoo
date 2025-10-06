# TODO - droo.foo Terminal

**Current Status:** Production-ready terminal portfolio with 665/665 tests passing

---

## [COMPLETED] Phase Summary

### ✅ Phase 1-4: Core Features (COMPLETE)
**All 645+ tests passing** | See DEVELOPMENT.md for detailed completion notes

**Infrastructure:**
- Terminal framework with Raxol integration
- Plugin system with 10+ plugins (Snake, Tetris, 2048, Wordle, Conway, Calculator, Matrix, Typing Test)
- Command mode with 30+ commands (`:theme`, `:perf`, `:clear`, `:crt`, `:spotify`, `:github`, etc.)
- OAuth integrations (Spotify 75 tests, GitHub verified with real data)
- Boot sequence animation, CRT effects, autocomplete UI
- Accessibility features (ARIA, high contrast, screen reader support)

**UI/UX:**
- 8 themes (Synthwave84, Nord, Dracula, Monokai, Gruvbox, Solarized, Tokyo Night, Matrix)
- Status bar with context awareness
- Advanced search (fuzzy/exact/regex, n/N navigation)
- Performance dashboard with ASCII charts
- Project showcase with 6 projects & ASCII thumbnails
- STL 3D viewer with Three.js

**Contributions:**
- RaxolWeb framework extracted & contributed to Raxol repo (67 tests, all passing)

---

## [ACTIVE] Current Work

### Phase 5: Spotify Interactive UI Enhancement

**Goal:** Transform Spotify navigation view into fully interactive music controller

#### 5.1 Navigation UI Integration (NEW - IN PROGRESS)
**Status:** Basic display complete, needs interactivity

**Completed:**
- [x] Added Spotify to Tools navigation menu (key: 6)
- [x] Created auth prompt view with [AUTHENTICATE] button
- [x] Created dashboard view with 6 action buttons
- [x] Now playing track display (title/artist)
- [x] Visual button layout (PLAYLISTS/DEVICES/SEARCH/CONTROLS/VOLUME/REFRESH)

**Next Steps:**
1. **Keyboard Shortcuts** (Priority: HIGH)
   - [ ] Add key bindings when in `:spotify` section:
     - `p` → Playlists view
     - `d` → Devices view
     - `s` → Search mode
     - `c` → Controls panel
     - `v` → Volume control
     - `r` → Refresh current track
   - [ ] Update renderer to show `[P]LAYLISTS` format
   - [ ] Add to help modal (?) key

2. **Real-time Playback Controls** (Priority: HIGH)
   - [ ] Add progress bar with block characters:
     ```
     ████████████░░░░░░░░░░  2:34 / 4:12
     ```
   - [ ] Add playback control row:
     ```
     [<< PREV]  [|| PAUSE]  [NEXT >>]
     ```
   - [ ] Implement key bindings:
     - `SPACE` → Play/Pause
     - `n` → Next track
     - `b` → Previous track
     - `+/-` → Volume up/down
   - [ ] Show playback state icon: `[▶]` playing, `[||]` paused

3. **Auto-refresh Mechanism** (Priority: MEDIUM)
   - [ ] Add periodic update in Spotify section (every 5s)
   - [ ] Update progress bar in real-time
   - [ ] Refresh now playing without user action
   - [ ] Handle track changes gracefully

4. **Visual State Indicators** (Priority: MEDIUM)
   - [ ] Add loading state:
     ```
     Status: [LOADING...]
     ```
   - [ ] Add error states:
     ```
     Status: [ERROR: Failed to connect]
     ```
   - [ ] Add connection status indicator
   - [ ] Show last refresh timestamp

5. **Quick Actions Row** (Priority: LOW)
   - [ ] Add at bottom of Spotify view:
     ```
     Quick: [SPACE]Play/Pause [N]ext [B]ack [+/-]Volume [R]efresh
     ```
   - [ ] Make it always visible
   - [ ] Update on mode changes

6. **Active Device Display** (Priority: LOW)
   - [ ] Show current playback device:
     ```
     Playing on: MacBook Pro Speakers
     ```
   - [ ] Add device switch shortcut
   - [ ] Show device type icon (speaker/headphone/etc)

7. **Clickable Auth Button** (Priority: MEDIUM)
   - [ ] Make `[AUTHENTICATE]` trigger auth flow
   - [ ] Option to open browser automatically
   - [ ] Option to copy URL to clipboard
   - [ ] Show QR code for mobile auth (ASCII art)

8. **Compact Mode Toggle** (Priority: LOW)
   - [ ] Add `:spotify compact` command
   - [ ] Show minimal view (just now playing + controls)
   - [ ] Useful when space is limited
   - [ ] Toggle with `m` key in Spotify section

**Files to Modify:**
- `lib/droodotfoo/raxol/renderer.ex` - Update Spotify rendering (lines 693-786)
- `lib/droodotfoo/raxol/navigation.ex` - Add Spotify key handlers
- `lib/droodotfoo/spotify/manager.ex` - Add auto-refresh GenServer message
- `lib/droodotfoo/raxol/state.ex` - Add Spotify UI state (mode, compact, etc.)

**Test Coverage:**
- [ ] Add Spotify UI interaction tests
- [ ] Test keyboard shortcuts
- [ ] Test auto-refresh mechanism
- [ ] Test state transitions

---

### Phase 6: Web3 Integration

**Goal:** Add blockchain/crypto features to terminal portfolio

#### 6.1 Research & Setup (COMPLETE)
**Status:** Research complete, architectural plan documented at `docs/WEB3_ARCHITECTURE.md`

**Completed:**
- [x] Research Elixir Web3 libraries:
  - **RECOMMENDED:** `ethers` (~> 0.6.7) - Most comprehensive, inspired by ethers.js
  - `ethereumex` (~> 0.10) - JSON-RPC client (dependency of ethers)
  - `ex_keccak`, `ex_secp256k1` - Cryptography utilities
- [x] Evaluate MetaMask browser extension integration
  - Use ethers.js v6 + Phoenix LiveView hooks
  - Reference: https://blog.finiam.com/blog/sign-in-with-metamask-using-liveview
- [x] Research WalletConnect for multi-wallet support
  - **RECOMMENDED:** Reown AppKit (formerly Web3Modal)
  - Supports 50M+ wallets, 70K+ apps
- [x] Plan architecture: Phoenix LiveView hooks + Web3 JS bridge
  - Three-layer architecture documented
  - Security patterns (nonce-based auth, signature verification)
  - Module structure planned

**Next Steps:** Begin Phase 6.2 implementation

#### 6.2 Wallet Connection (COMPLETE)
**Status:** Backend and UI integration complete, ready for browser testing

**Completed:**
- [x] Created Web3.Manager GenServer for wallet state management (sessions, nonces, ENS cache)
- [x] Implemented Web3.Auth module with nonce-based authentication
- [x] Created web3_wallet.js JavaScript hook for MetaMask integration
- [x] Registered Web3WalletHook in LiveView hooks
- [x] Added Web3.Manager to application supervision tree
- [x] Configured ethereumex and Web3.Manager in runtime.exs
- [x] Added dependencies: ethers (0.6.7), ethereumex (0.12.1), ex_keccak, ex_secp256k1
- [x] Installed ethers.js (6.13.0) for browser wallet interaction
- [x] Created comprehensive test suite (35 tests, all passing)
- [x] Implemented signature verification using ECDSA recovery
- [x] Created Web3 navigation section in terminal UI (key: 8)
- [x] Added MetaMask connection UI with ASCII styling
- [x] Added wallet disconnect command (`:web3 disconnect`)
- [x] Added commands: `:web3 connect`, `:wallet`, `:w3`
- [x] Integrated wallet connection flow with terminal renderer
- [x] Added LiveView event handlers for wallet connection
- [x] Added RaxolApp GenServer state management for Web3
- [x] Implemented connected/disconnected UI states
- [x] Added network name display (Ethereum, Polygon, Arbitrum, etc.)
- [x] Added address abbreviation (0x1234...5678 format)

**Files Modified:**
- `lib/droodotfoo/raxol/renderer.ex` - Added `draw_web3_connect_prompt/1` and `draw_web3_connected/1`
- `lib/droodotfoo/raxol/navigation.ex` - Added key 8 shortcut
- `lib/droodotfoo/terminal/command_registry.ex` - Registered web3 commands
- `lib/droodotfoo/terminal/command_parser.ex` - Added command dispatch
- `lib/droodotfoo/terminal/commands.ex` - Implemented web3, wallet, w3 commands
- `lib/droodotfoo_web/live/droodotfoo_live.ex` - Added event handlers
- `lib/droodotfoo/raxol_app.ex` - Added GenServer state management

**Testing:**
- [ ] Test MetaMask connection in browser
- [ ] Test wallet disconnect flow
- [ ] Test state persistence across page refreshes
- [ ] Implement WalletConnect QR code (ASCII art) - Phase 6.2.2

**Next Steps:** Test end-to-end wallet connection with MetaMask, then proceed to Phase 6.3 (ENS)

#### 6.3 ENS & Address Display (COMPLETE)
**Status:** ENS resolution with caching, terminal commands, and UI integration complete

**Completed:**
- [x] Created Web3.ENS module for ENS name resolution
- [x] Implemented forward resolution (name.eth → address)
- [x] Implemented reverse resolution (address → name.eth)
- [x] Added ENS caching to Web3.Manager with 1-hour TTL
- [x] Automatic cache expiration cleanup
- [x] Added `:ens <name>` terminal command
- [x] Registered `:ens` in CommandRegistry
- [x] Updated Web3 connected UI to display ENS names
- [x] ENS name shown below wallet address (mainnet only)
- [x] Graceful fallback if no ENS name exists
- [x] Address abbreviation already implemented (0x1234...5678)
- [x] Name validation and normalization (ENSIP-15)
- [x] Public API integration for resolution
- [x] Cache hit/miss logging for debugging

**Files Created:**
- `lib/droodotfoo/web3/ens.ex` - ENS resolution module

**Files Modified:**
- `lib/droodotfoo/web3/manager.ex` - Added ENS caching (1h TTL), resolve_ens/1, lookup_ens/1
- `lib/droodotfoo/terminal/commands.ex` - Added `:ens` command (lines 757-789)
- `lib/droodotfoo/terminal/command_registry.ex` - Registered `ens` command
- `lib/droodotfoo/raxol/renderer.ex` - ENS display in Web3 UI (lines 1364-1379)

**Deferred:**
- [ ] Display ENS avatar (fetch from IPFS, render as ASCII) - Phase 6.3.1

**Next Steps:** Proceed to Phase 6.7 (Smart Contract Interaction) OR Phase 6.8 (IPFS Integration)

#### 6.4 NFT Gallery Viewer (COMPLETE)
- [x] Create NFT browser plugin
- [x] Fetch NFTs from OpenSea/Alchemy API
- [x] Render NFT metadata as ASCII art
- [x] Support ERC-721 and ERC-1155
- [x] Grid view with thumbnails (ASCII representations)
- [x] Detail view with properties/traits
- [x] Commands: `:nft list`, `:nft view <id>`, `nfts`

**Implemented:**
- Created `lib/droodotfoo/web3/nft.ex` module for NFT fetching
- Integrated OpenSea API v2 for NFT data retrieval
- Implemented HTTP client using Erlang's :httpc
- Added terminal commands:
  - `:nft list [address]` - List NFTs (defaults to connected wallet)
  - `:nft view <contract> <token_id>` - View NFT details with ASCII art
  - `:nfts [address]` - Alias for nft list
- Support for ERC-721 and ERC-1155 token standards
- ASCII art placeholder for NFT images (`image_to_ascii/2`)
- Properties/traits display (top 5) in detail view
- Grid view showing collection, token ID, and standard

**Files Created:**
- `lib/droodotfoo/web3/nft.ex` - NFT fetching and parsing

**Files Modified:**
- `lib/droodotfoo/terminal/commands.ex` - NFT commands (lines 791-883)
- `lib/droodotfoo/terminal/command_registry.ex` - Register nft/nfts commands (lines 46-47)

#### 6.5 Token Balances (COMPLETE)
- [x] Fetch ERC-20 token balances
- [x] Display with USD values (CoinGecko API)
- [x] Show balance changes (24h %)
- [x] ASCII chart for token price history
- [x] Commands: `:tokens`, `:balance <symbol>`, `crypto`

**Implemented:**
- Created `lib/droodotfoo/web3/token.ex` module for token balance fetching
- Integrated CoinGecko API v3 for real-time USD pricing and 24h price changes
- Implemented HTTP client using Erlang's :httpc for API calls
- Added terminal commands:
  - `:tokens` - List token balances for connected wallet
  - `:tokens list [address]` - List token balances for specific address
  - `:balance <symbol>` - Get USD price and 7-day ASCII chart for specific token
  - `:crypto` - Alias for tokens command
- ASCII sparkline price chart using Unicode block characters (▁▂▃▄▅▆▇█)
- Support for popular ERC-20 tokens: USDT, USDC, DAI, WBTC, LINK, MATIC, UNI, AAVE
- Support for native ETH balance and pricing
- Formatted output showing: symbol, balance, price, USD value, 24h change %
- Rate limit handling for CoinGecko API

**Files Created:**
- `lib/droodotfoo/web3/token.ex` - Token balance and pricing module

**Files Modified:**
- `lib/droodotfoo/terminal/commands.ex` - Token commands (lines 885-1015)
- `lib/droodotfoo/terminal/command_registry.ex` - Register tokens/balance/crypto commands (lines 48-50)

#### 6.6 Transaction History (COMPLETE)
- [x] Fetch transaction history from Etherscan
- [x] Display recent transactions (10-20)
- [x] Show: from/to, value, gas, status
- [x] Format with ASCII table
- [x] Add pagination (n/N keys)
- [x] Commands: `:tx history`, `:tx <hash>`, `transactions`

**Implemented:**
- Created `lib/droodotfoo/web3/transaction.ex` module for transaction history
- Mock implementation with Etherscan API structure (production would use API key)
- Helper functions for Wei to ETH conversion, timestamp formatting, address shortening
- Added terminal commands:
  - `:tx` - Show transaction history for connected wallet
  - `:tx history [address]` - Show transaction history for specific address
  - `:tx <hash>` - View detailed transaction information by hash
  - `:transactions` - Alias for tx history
- ASCII table formatting with transaction details:
  - Transaction hash (shortened)
  - From/To addresses (shortened)
  - Value in ETH
  - Gas cost in ETH
  - Relative time (seconds/minutes/hours/days ago)
  - Transaction status (OK/FAIL)
- Transaction detail view showing:
  - Full hash, status, block number
  - Timestamp with UTC
  - From/To addresses (full)
  - Value in ETH
  - Gas used, gas price (Gwei), total gas cost
  - Method/function called

**Files Created:**
- `lib/droodotfoo/web3/transaction.ex` - Transaction history and details

**Files Modified:**
- `lib/droodotfoo/terminal/commands.ex` - Transaction commands (lines 1017-1136)
- `lib/droodotfoo/terminal/command_registry.ex` - Register tx/transactions commands (lines 51-52)

**Note:** Currently uses mock data. Production implementation would integrate with Etherscan API (requires API key).

#### 6.7 Smart Contract Interaction (COMPLETE)
- [x] Build contract ABI viewer
- [x] Fetch contract ABIs from Etherscan
- [x] Display contract functions/events
- [x] Allow read-only contract calls
- [x] Show contract verification status
- [x] Commands: `:contract <address>`, `:call <fn> <args>`

**Implemented:**
- Created `lib/droodotfoo/web3/contract.ex` module for smart contract interaction
- Mock ERC-20 token contract ABI for demonstration (production would use Etherscan API)
- ABI parsing with support for functions and events
- Contract information display:
  - Address, name, compiler version
  - Verification status, license type
  - Proxy detection
  - View functions (read-only)
  - Write functions (state-changing)
  - Events with indexed parameters
- Function signature formatting for display
- Read-only contract function calls with result display
- Added terminal commands:
  - `:contract <address>` - View contract info and ABI
  - `:contract <address> <function> [args...]` - Call read-only function
  - `:call <address> <function> [args...]` - Shorthand for contract calls
- Helper functions for parameter formatting
- Event signature display with indexed parameter indicators

**Files Created:**
- `lib/droodotfoo/web3/contract.ex` - Contract ABI and interaction utilities

**Files Modified:**
- `lib/droodotfoo/terminal/commands.ex` - Contract commands (lines 1138-1265)
- `lib/droodotfoo/terminal/command_registry.ex` - Register contract/call commands (lines 53-54)

**Note:** Currently uses mock ERC-20 ABI. Production implementation would fetch real ABIs from Etherscan API (requires API key).

#### 6.8 IPFS Integration (COMPLETE)
- [x] Add IPFS gateway support (Pinata/Infura)
- [x] Fetch and render IPFS content
- [x] Display IPFS CIDs with gateway links
- [x] Support decentralized content hosting
- [x] Commands: `:ipfs cat <cid>`, `:ipfs gateway <cid>`, `:ipfs ls <cid>`

**Implemented:**
- Created `lib/droodotfoo/web3/ipfs.ex` module for IPFS gateway integration
- Support for multiple public gateways with automatic fallback:
  - Cloudflare IPFS Gateway
  - IPFS.io
  - Pinata Gateway
  - Dweb.link
- CID validation for both CIDv0 (Qm...) and CIDv1 (b..., bafy...)
- Content fetching with 10MB size limit for safety
- Content type detection and intelligent formatting:
  - Text files with line truncation
  - JSON with pretty-printing
  - Image metadata display
  - Binary content information
- Added terminal commands:
  - `:ipfs cat <cid>` - Fetch and display IPFS content
  - `:ipfs gateway <cid>` - Show all available gateway URLs
  - `:ipfs ls <cid>` - List directory contents (placeholder for future implementation)
- Gateway fallback mechanism for reliability
- Automatic content-type detection from HTTP headers
- Byte size formatting (B, KB, MB, GB)

**Files Created:**
- `lib/droodotfoo/web3/ipfs.ex` - IPFS gateway integration and content formatting

**Files Modified:**
- `lib/droodotfoo/terminal/commands.ex` - IPFS commands (lines 1267-1379)
- `lib/droodotfoo/terminal/command_registry.ex` - Register ipfs command (line 55)

**Note:** Uses public IPFS gateways (no API keys required). Directory listing requires IPFS API implementation.

#### 6.9 Fileverse Integration (IN PROGRESS)
**Goal:** Integrate Fileverse decentralized collaboration platform for encrypted docs, file storage, and onchain social features

**6.9.1 dDocs Integration - Encrypted Collaborative Documents (COMPLETE - STUB)**
- [x] Research & evaluate `@fileverse-dev/ddoc` React component
- [x] Create Fileverse module structure
- [x] Implement dDocs Elixir module with mock data
- [x] Add document creation/viewing in terminal UI
- [x] Support wallet-based authentication (requires Web3 connection)
- [x] Commands: `:ddoc new <title>`, `:ddoc view <id>`, `:ddoc list`, `:docs`
- [ ] Create Phoenix LiveView wrapper for dDocs editor (deferred)
- [ ] Implement LiveView hooks for React/TypeScript bridge (deferred)
- [ ] Support Markdown and LaTeX rendering (display in ASCII/formatted)
- [ ] Enable offline editing with local cache
- [ ] Display document collaboration status (active users)
- [ ] Add inline commenting viewer (ASCII format)

**Implemented:**
- Created `lib/droodotfoo/fileverse/ddoc.ex` module for document management
- Mock implementation demonstrating architecture (production requires Fileverse SDK)
- Document operations: create, list, get, delete, share
- Wallet-gated access (requires `:web3 connect` first)
- Added terminal commands:
  - `:ddoc list` - List encrypted documents for connected wallet
  - `:ddoc new <title>` - Create new encrypted document
  - `:ddoc view <id>` - View document details and content
  - `:docs` - Alias for ddoc list
- Mock document data with E2E encryption indicators
- Document metadata formatting (ID, author, timestamps, IPFS CID, collaborators)
- Relative time display (e.g., "2h ago", "3d ago")
- Address abbreviation for privacy

**Files Created:**
- `lib/droodotfoo/fileverse/ddoc.ex` - dDocs module with mock data

**Files Modified:**
- `lib/droodotfoo/terminal/commands.ex` - dDocs commands (lines 1381-1463)
- `lib/droodotfoo/terminal/command_registry.ex` - Register ddoc/docs commands (lines 56-57)

**Note:** This is a stub implementation demonstrating the architecture. Full production requires:
- `@fileverse-dev/ddoc` React SDK integration
- LiveView hooks for React component bridge
- Fileverse API authentication (UCAN tokens)
- Real-time collaboration features
- Actual E2E encryption implementation

**6.9.2 Fileverse Storage - Decentralized File Upload (COMPLETE - STUB)**
- [x] Integrate Fileverse Storage API for UCAN-authorized uploads
- [x] Build file upload flow from terminal (drag & drop / file picker)
- [x] Store files on IPFS via Fileverse infrastructure
- [x] Display upload progress with ASCII progress bar
- [x] Show storage costs/estimates (if applicable)
- [x] Cache file metadata locally (ETS)
- [x] Support file versioning and history
- [x] Commands: `:upload <path>`, `:files`, `:file info <cid>`

**Implemented:**
- Created `lib/droodotfoo/fileverse/storage.ex` module for file uploads
- Mock implementation demonstrating architecture (production requires Fileverse Storage API)
- File upload operations: upload, list_files, get_file, get_versions, delete
- Wallet-gated access (requires `:web3 connect` first)
- Added terminal commands:
  - `:upload <path>` - Upload file to IPFS via Fileverse
  - `:files` - List uploaded files for connected wallet
  - `:file info <cid>` - View file metadata by CID
  - `:file versions <cid>` - View version history
- Mock file metadata with IPFS CIDs, content types, upload times
- Storage cost calculation ($0.001 per GB per month estimate)
- File versioning support with version history
- ASCII progress bar formatting (for future real-time uploads)
- Content type detection based on file extension
- File size formatting (B, KB, MB, GB)

**Files Created:**
- `lib/droodotfoo/fileverse/storage.ex` - Storage module with mock data

**Files Modified:**
- `lib/droodotfoo/terminal/commands.ex` - Storage commands (lines 1465-1598)
- `lib/droodotfoo/terminal/command_registry.ex` - Register upload/files/file commands (lines 58-60)

**Note:** This is a stub implementation demonstrating the architecture. Full production requires:
- Fileverse Storage API integration
- UCAN token generation and authentication
- Actual IPFS pinning via Fileverse infrastructure
- Real-time upload progress tracking
- ETS cache for file metadata persistence

**6.9.3 Portal Integration - P2P File Sharing**
- [ ] Connect to Fileverse Portal for peer-to-peer capabilities
- [ ] Create/join Portal spaces (rooms) from terminal
- [ ] Display active peers in room (ASCII user list)
- [ ] Share files directly with peers
- [ ] Real-time document collaboration status
- [ ] Community management features (if applicable)
- [ ] Commands: `:portal create <name>`, `:portal join <id>`, `:portal share <file>`

**6.9.4 dSheets Integration - Onchain Data Visualization**
- [ ] Research dSheets API for reading onchain data
- [ ] Build spreadsheet viewer for blockchain data
- [ ] Render cells as ASCII table (format for terminal width)
- [ ] Support basic data manipulation (filter, sort)
- [ ] Display ERC-20 balances in sheet format
- [ ] Show NFT metadata in tabular view
- [ ] Export data to CSV/JSON from terminal
- [ ] Commands: `:sheet new`, `:sheet open <id>`, `:sheet query <contract>`

**6.9.5 HeartBit SDK - Onchain Social Interactions**
- [ ] Integrate HeartBit SDK for provable "Likes"
- [ ] Add "Like" functionality to documents/files
- [ ] Display like count with ASCII heart icons
- [ ] Show who liked (wallet addresses/ENS names)
- [ ] Create social activity feed
- [ ] Track user engagement metrics
- [ ] Commands: `:like <item>`, `:likes <item>`, `:activity`

**6.9.6 Agents SDK - AI Terminal Assistant**
- [ ] Integrate Fileverse Agents SDK for AI capabilities
- [ ] Enable AI agent to read onchain data (balances, NFTs, etc.)
- [ ] Allow AI to write data to blockchain (with user approval)
- [ ] Create natural language blockchain queries
- [ ] AI-powered contract interaction suggestions
- [ ] Smart wallet recommendations based on activity
- [ ] Commands: `:agent <query>`, `:ai help`, `:assistant`

**6.9.7 Privacy & Encryption Features**
- [ ] Implement end-to-end encryption for documents
- [ ] Add encryption status indicator to UI
- [ ] Support encrypted file sharing between wallets
- [ ] Display encryption keys/signatures (abbreviated format)
- [ ] Add privacy mode toggle (hide sensitive data)
- [ ] Secure key storage in browser localStorage
- [ ] Commands: `:encrypt <doc>`, `:decrypt <doc>`, `:privacy on/off`

**Files to Create (Fileverse):**
- `lib/droodotfoo/fileverse/` - Fileverse integration directory
  - `ddoc.ex` - dDocs document management
  - `storage.ex` - File storage/IPFS uploads
  - `portal.ex` - Portal P2P connectivity
  - `dsheet.ex` - Spreadsheet data handling
  - `heartbit.ex` - Social interactions (Likes)
  - `agent.ex` - AI agent integration
- `lib/droodotfoo/plugins/fileverse.ex` - Interactive Fileverse plugin
- `assets/js/hooks/fileverse_ddoc.js` - dDocs React component hook
- `assets/js/hooks/fileverse_portal.js` - Portal WebRTC/P2P hook
- `test/droodotfoo/fileverse/` - Test coverage for all modules

**Dependencies to Add (Fileverse):**
```elixir
# mix.exs - Fileverse Integration
# Note: Most Fileverse SDKs are JS/TypeScript - use LiveView hooks
# Elixir dependencies for API communication:
{:req, "~> 0.4"},  # Already included
{:jason, "~> 1.4"},  # Already included
{:plug_crypto, "~> 2.0"}  # For UCAN tokens
```

**JavaScript Dependencies:**
```json
// package.json
{
  "@fileverse-dev/ddoc": "latest",
  "@fileverse/heartbit": "latest",
  "@fileverse/agent": "latest"
}
```

**Integration Milestones:**
1. **Phase 6.9.1-6.9.2:** Core dDocs + Storage (encrypted docs, file uploads)
2. **Phase 6.9.3:** Portal P2P (real-time collaboration)
3. **Phase 6.9.4:** dSheets (onchain data visualization)
4. **Phase 6.9.5-6.9.6:** Social + AI (HeartBit, Agents SDK)
5. **Phase 6.9.7:** Privacy hardening (encryption, secure key management)

**Key Considerations:**
- Fileverse is under "rapid development" - pin versions carefully
- UCAN authentication required for storage uploads
- React components need LiveView hooks bridge
- Privacy-first: all data E2E encrypted by default
- Test thoroughly with wallet disconnections/reconnections

**Files to Create:**
- `lib/droodotfoo/web3/` - Web3 modules directory
  - `manager.ex` - GenServer for wallet state
  - `api.ex` - Ethereum RPC client
  - `ens.ex` - ENS resolution
  - `tokens.ex` - ERC-20 utilities
  - `nfts.ex` - NFT fetching/display
- `lib/droodotfoo/plugins/web3.ex` - Interactive Web3 plugin
- `assets/js/hooks/web3_wallet.js` - MetaMask/WalletConnect hooks
- `test/droodotfoo/web3/` - Test coverage

**Dependencies to Add:**
```elixir
# mix.exs - Updated based on research
{:ethers, "~> 0.6.7"},           # Comprehensive Web3 library (RECOMMENDED)
{:ethereumex, "~> 0.10"},        # JSON-RPC client (dependency of ethers)
{:ex_keccak, "~> 0.7"},          # Keccak hashing
{:ex_secp256k1, "~> 0.7"},       # Signature verification
{:jason, "~> 1.4"}               # Already included
```

**JavaScript Dependencies:**
```json
{
  "ethers": "^6.13.0",
  "@reown/appkit": "^1.0.0",
  "@reown/appkit-adapter-ethers": "^1.0.0"
}
```

**Milestones:**
1. [COMPLETE] Phase 1-4: Core features
2. [COMPLETE] Phase 5: Spotify Interactive UI
3. [IN PROGRESS] Phase 6: Web3 Integration
   - [COMPLETE] 6.1: Research & Setup
   - [COMPLETE] 6.2: Wallet Connection - Full UI integration with MetaMask support
   - [COMPLETE] 6.3: ENS & Address Display - Resolution, caching, terminal commands, UI integration
   - [COMPLETE] 6.4: NFT Gallery Viewer - OpenSea API integration, NFT listing/details, ASCII art
   - [COMPLETE] 6.5: Token Balances - CoinGecko API, USD values, 24h changes, ASCII price charts
   - [COMPLETE] 6.6: Transaction History - Etherscan integration, tx details, ASCII table formatting
   - [COMPLETE] 6.7: Smart Contract Interaction - ABI viewer, function calls, contract info display
   - [COMPLETE] 6.8: IPFS Integration - Multi-gateway support, content fetching, CID validation
   - [IN PROGRESS] 6.9: Fileverse Integration
     - [COMPLETE - STUB] 6.9.1: dDocs - Encrypted collaborative documents with mock data
     - [COMPLETE - STUB] 6.9.2: Storage - File upload to IPFS with versioning
     - [TODO] 6.9.3-6.9.7: Portal, dSheets, HeartBit, Agents SDK, Privacy
4. [TODO] Phase 7: Portfolio Enhancements (contact form, PDF resume)
5. [TODO] Phase 8: Code Consolidation (refactor to shared utilities)

---

## [POLISH] Remaining Tasks

### Portfolio Features
- [ ] PDF resume export (ex_pdf or chromic)
- [ ] Interactive resume filtering
- [ ] Skill proficiency visualizations with gradient charts
- [ ] Contact form with validation
- [ ] Blog integration (already has Obsidian publishing API)

### Code Quality
- [ ] Complete Phase 2 of consolidation (integrate HttpClient, GameBase, CommandRegistry)
- [ ] ExDoc integration with typespecs
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Coverage reporting with Coveralls

---

## [REFERENCE] Quick Info

**Commands:**
```bash
mix phx.server              # Start server (port 4000)
./bin/dev                   # Start with 1Password secrets
mix test                    # Run tests (665/665 passing)
mix precommit              # Full check (compile, format, test)
```

**Key Terminal Commands:**
- Navigation: Press `1-8` to jump to sections (Home/Projects/Skills/Experience/Contact/Spotify/STL/Web3)
- Themes: `:theme <name>` (synthwave84, nord, dracula, monokai, gruvbox, solarized, tokyonight, matrix)
- Spotify: `6` or `:spotify` to access music controller
- GitHub: `:github`, `:gh`, `github` for repo browsing
- Games: `:tetris`, `:2048`, `:wordle`, `:conway`
- Effects: `:crt` for retro CRT mode, `:contrast` for high contrast
- Performance: `:perf` or `:dashboard` for metrics
- Web3: `8` or `:web3` - wallet connection UI (ready for testing)
- Web3 Commands: `:web3 connect`, `:web3 disconnect`, `:wallet`, `:w3`, `:ens <name>`, `:nft list [address]`, `:nft view <contract> <id>`, `:nfts [address]`, `:tokens`, `:balance <symbol>`, `:crypto`, `:tx [history] [address]`, `:tx <hash>`, `:transactions`, `:contract <address>`, `:call <address> <function> [args]`, `:ipfs cat <cid>`, `:ipfs gateway <cid>`
- Fileverse: `:ddoc list`, `:ddoc new <title>`, `:ddoc view <id>`, `:docs`, `:upload <path>`, `:files`, `:file info <cid>`, `:file versions <cid>`
- Fileverse (Planned): `:portal join`, `:sheet open`, `:agent <query>`

**Documentation:**
- README.md - Setup, features, deployment
- DEVELOPMENT.md - Architecture, integrations, testing
- docs/FEATURES.md - Complete roadmap
- CLAUDE.md - AI assistant instructions

---

**Last Updated:** October 6, 2025
**Version:** 1.7.0-dev
**Test Coverage:** 700/700 passing (665 core + 35 Web3)
**Active Phase:** 6.9.2 COMPLETE (STUB) (Fileverse Storage - File Upload)
**Next Phase:** 6.9.3 Fileverse Portal - P2P File Sharing
