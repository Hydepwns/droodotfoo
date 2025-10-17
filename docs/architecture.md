# System Architecture

This document provides a high-level overview of the `droo.foo` terminal application architecture.

**For detailed API documentation:** See `docs/api_reference.md` or run `mix docs`

## Overview

Phoenix LiveView application with terminal UI, Web3 integration, and P2P collaboration:

- **Phoenix v1.8** with LiveView for real-time updates
- **Raxol terminal framework** for character-perfect monospace rendering
- **Web3 integration** (wallet auth, ENS, NFTs, tokens, contracts, IPFS)
- **Fileverse P2P** (Portal file sharing, dDocs, dSheets, E2E encryption)
- **Plugin system** (10 built-in plugins: games, utilities, integrations)
- **60fps rendering** via optimized LiveView updates

## Architecture Layers

### 1. Presentation Layer (`DroodotfooWeb`)

**LiveView Components:**
- `DroodotfooLive` — Main terminal interface with keyboard handling
- `PortalLive` — P2P collaboration UI
- `ContactLive`, `ResumeLive`, `PostLive` — Content pages
- `SpotifyLive`, `STLViewerLive` — Integration widgets

**Key Responsibilities:**
- WebSocket connections via LiveView
- Keyboard event capture and routing
- Real-time buffer updates
- Mobile responsive layout

### 2. Terminal Layer (`Droodotfoo.Raxol*`)

**Core Components:**
- `RaxolApp` (GenServer) — Terminal state orchestrator
  - Manages 60fps update cycle
  - Routes keyboard input to active plugins
  - Handles section navigation
- `Raxol.State` — TEA pattern state management
  - 52-field immutable state structure
  - Pure reducer functions
- `Raxol.Renderer` — Content-specific rendering
- `TerminalBridge` — Raxol buffer → HTML conversion
  - Optimized diffing and caching
  - 1ch grid alignment preservation

**Data Flow:**
```
Keyboard Event → LiveView
  ↓
RaxolApp.send_input/2
  ↓
Raxol.Command.handle_input/2
  ↓
State.reduce/2 (pure function)
  ↓
Renderer.render/1
  ↓
TerminalBridge.terminal_to_html/1
  ↓
LiveView assigns update
  ↓
Browser DOM update
```

### 3. Plugin System (`Droodotfoo.PluginSystem`)

**Architecture:**
- GenServer-based plugin manager
- Behaviour-based plugin interface
- Hot-swappable plugin activation
- Lifecycle hooks: `init/1`, `handle_input/3`, `render/2`, `cleanup/1`

**Built-in Plugins (10):**
1. **Games** (5): Snake, Tetris, 2048, Wordle, Conway
2. **Utilities** (2): Calculator (RPN/standard), TypingTest (WPM)
3. **Integrations** (2): Spotify player, GitHub stats
4. **Effects** (1): MatrixRain animation

**Plugin Lifecycle:**
```
PluginSystem.start_plugin/2
  ↓
Plugin.init/1 → {:ok, state}
  ↓
Plugin.render/2 → initial output
  ↓
[Active: receives input events]
  ↓
Plugin.handle_input/3 → {:continue | :exit, state, output}
  ↓
Plugin.cleanup/1 → :ok
```

### 4. Domain Layer (`Droodotfoo.*`)

#### Terminal Commands
- `Terminal.Commands` — Command implementations (100+ commands)
- `Terminal.CommandParser` — Parse `:command arg1 arg2`
- `Terminal.CommandRegistry` — Command registration and dispatch

#### Web3 Integration (7 modules)
- `Web3` — Main coordinator with wallet authentication
- `Web3.Auth` — Signature verification, session management
- `Web3.ENS` — Forward/reverse ENS resolution
- `Web3.NFT` — ERC-721/1155 via OpenSea/Alchemy
- `Web3.Token` — ERC-20 balances, pricing, charts
- `Web3.Contract` — Smart contract read/write
- `Web3.IPFS` — IPFS storage and retrieval

#### Fileverse Integration (15 modules)

**Main Modules (7):**
- `Fileverse.Portal` — P2P file sharing coordinator
- `Fileverse.DDoc` — Decentralized documents
- `Fileverse.DSheet` — Onchain data visualization
- `Fileverse.Storage` — IPFS integration
- `Fileverse.Encryption` — Signal Protocol E2E encryption
- `Fileverse.Heartbit` — Health monitoring
- `Fileverse.Agent` — AI agent integration

**Portal Sub-system (8 modules):**
- `Portal.Presence` (GenServer) — Real-time peer tracking
- `Portal.PresenceServer` — Presence state management
- `Portal.WebRTC` — WebRTC connection handling
- `Portal.Transfer` — File transfer orchestration
- `Portal.Chunker` — File chunking for P2P
- `Portal.Notifications` — Real-time events
- `Portal.ActivityTracker` — Activity feed
- `Portal.TransferProgress` — Progress tracking

#### Integrations
- `Spotify` (GenServer) — OAuth, playback control, 5s refresh
- `Spotify.Auth` — OAuth 2.0 flow
- `Spotify.API` — Web API client
- `GitHub` — Repository stats, contribution graphs
- `Content.Posts` (GenServer) — Blog post management

### 5. Infrastructure Layer

**HTTP Client:**
- Unified `Req`-based client
- Automatic retries and timeouts
- Request/response logging

**Storage:**
- IPFS via Fileverse integration
- Local file storage for static assets
- No database (stateless design)

**Concurrency:**
- **GenServers:** RaxolApp, PluginSystem, Spotify, Content.Posts, Portal.PresenceServer
- **Tasks:** Async HTTP requests, file uploads
- **PubSub:** Phoenix.PubSub for Portal presence broadcasting

## Data Flow Patterns

### Terminal Command Execution
```
User types ":help" → LiveView captures
  ↓
RaxolApp receives input
  ↓
CommandParser.parse(":help") → {:ok, {:help, []}}
  ↓
CommandRegistry.execute(:help)
  ↓
Commands.help/1 → formatted output
  ↓
State.reduce(state, {:output, text})
  ↓
Renderer.render(state) → buffer
  ↓
TerminalBridge → HTML
  ↓
LiveView push_event
```

### Plugin Activation
```
User types ":snake" → Command execution
  ↓
PluginSystem.start_plugin("snake", terminal_state)
  ↓
SnakeGame.init(terminal_state) → {:ok, game_state}
  ↓
SnakeGame.render(game_state) → ASCII board
  ↓
RaxolApp updates mode to :plugin
  ↓
[All input routed to plugin until exit]
```

### Portal P2P Transfer
```
User: ":portal share file.pdf"
  ↓
Portal.share_file(portal_id, path, opts)
  ↓
Chunker.chunk_file(path) → [chunks]
  ↓
Transfer.initiate(portal_id, chunks)
  ↓
WebRTC establishes data channels to peers
  ↓
Transfer.send_chunks(chunks, peers)
  ↓
TransferProgress broadcasts updates
  ↓
LiveView updates progress bars
```

## Concurrency Model

### GenServers (Stateful)
- **RaxolApp** — Terminal state (1 per LiveView)
- **PluginSystem** — Plugin registry (singleton)
- **Spotify** — OAuth tokens, playback state (singleton)
- **Content.Posts** — Blog post cache (singleton)
- **Portal.PresenceServer** — Peer presence (1 per portal)

### Tasks (Stateless)
- HTTP API calls (Spotify, GitHub, OpenSea, etc.)
- File I/O operations
- IPFS uploads/downloads
- WebRTC connection establishment

### PubSub Topics
- `"portal:#{portal_id}"` — Portal peer events
- `"spotify:playback"` — Spotify state updates
- `"terminal:#{session_id}"` — Terminal command results

## Security Architecture

### Authentication
- **Web3 Wallet Auth** — Sign message to prove wallet ownership
- **Session Management** — Phoenix sessions with wallet address
- **No Passwords** — Passwordless authentication via signatures

### Encryption
- **E2E Encryption** — Signal Protocol (libsignal-protocol)
  - X3DH key agreement
  - Double Ratchet algorithm
  - Forward secrecy
- **Transport Encryption** — HTTPS + WebSocket TLS
- **Storage Encryption** — AES-256-GCM for local storage

### Data Privacy
- **No Database** — No user data persistence
- **Client-side Encryption** — Encrypt before IPFS upload
- **P2P Transfer** — Direct peer-to-peer, no server storage

## Performance Characteristics

### Rendering Performance
- **60fps Target** — 16ms render budget
- **Diffing Optimization** — Only update changed cells
- **Buffer Caching** — Reuse unchanged buffer sections
- **Grid Snapping** — CSS 1ch units for alignment

### Memory Usage
- **Terminal Buffer** — 80×24 = 1,920 cells (~20KB)
- **Plugin State** — Varies (Snake: ~2KB, Tetris: ~5KB)
- **Presence Tracking** — ~1KB per peer
- **File Chunks** — 64KB chunks for P2P transfer

### Network Optimization
- **WebSocket** — Persistent connection for real-time updates
- **HTTP/2** — Multiplexed API requests
- **Caching** — HTTP caching for static assets
- **Chunking** — Progressive transfer for large files

## Testing Strategy

### Unit Tests
- Pure functions (State.reduce, Parser, Renderer)
- GenServer callbacks (handle_call, handle_cast)
- Utility modules (GameBase, ASCII helpers)

### Integration Tests
- Plugin lifecycle (init → input → render → cleanup)
- Command execution (parse → execute → output)
- Web3 API mocking (ENS, NFT, Token)

### LiveView Tests
- Event handling (keyboard, mouse, WebSocket)
- Assigns updates (buffer, mode, state)
- Hook integration (JavaScript interop)

### Property-Based Tests
- Command parser invariants
- State reducer properties
- Grid manipulation functions

**Current Coverage:** 801/836 tests passing (96%)

## Deployment Architecture

### Development
```
iex -S mix phx.server
  ↓
Bandit web server (port 4000)
  ↓
Phoenix.Endpoint
  ↓
[LiveView WebSocket connections]
```

### Production (Fly.io)
```
Fly.io Load Balancer
  ↓
Bandit (1+ instances)
  ↓
Phoenix.Endpoint
  ↓
LiveView (sticky sessions)
  ↓
[CDN for static assets]
```

**Environment Variables:**
- `SECRET_KEY_BASE` — Phoenix session encryption
- `PHX_HOST` — Production domain
- `SPOTIFY_CLIENT_ID` / `SECRET` — OAuth credentials
- `CDN_HOST` — Cloudflare Pages (optional)

## Module Organization

Modules organized into 8 groups for ExDoc:

1. **Core** — RaxolApp, State, TerminalBridge, Application
2. **Plugin System** — PluginSystem, Plugin behaviour, GameBase
3. **Integrations** — Spotify, GitHub (OAuth, APIs)
4. **Web3** — Auth, ENS, NFT, Token, Contract, Transaction, IPFS
5. **Fileverse** — Portal, DDoc, DSheet, Storage, Encryption
6. **Terminal** — Commands, Parser, Registry
7. **Content & Blog** — Posts, PostFormatter
8. **Web** — LiveViews, Components, Router, Endpoint

**Total Modules:** 40+ core modules with comprehensive documentation

## Documentation

**ExDoc Generated:** 113 HTML pages
- **@spec annotations:** 120+ function signatures
- **@type definitions:** 60+ custom types
- **@moduledoc:** Comprehensive module descriptions
- **Examples:** Usage patterns in @doc blocks

**Generate docs:** `mix docs`
**View docs:** `open doc/index.html`
