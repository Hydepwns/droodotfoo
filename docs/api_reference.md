# API Reference

Comprehensive API documentation is available via ExDoc. This page provides a high-level index of the main modules.

**View full documentation:** Open `doc/index.html` in your browser or run `mix docs`

**Documentation includes:**
- 113 HTML pages with full module documentation
- 120+ function signatures with @spec annotations
- 60+ custom type definitions
- Usage examples and parameter descriptions
- Searchable interface with module grouping

## Core Infrastructure

### Terminal Orchestration
- **`Droodotfoo.RaxolApp`** — GenServer managing terminal UI state, keyboard navigation, content rendering
  - 12 @spec annotations, handles 60fps updates
- **`Droodotfoo.Raxol.State`** — State management with TEA pattern
  - 52-field state type, 5 @spec annotations
- **`Droodotfoo.TerminalBridge`** — Converts Raxol buffer cells to HTML
  - 6 @spec annotations, optimized caching/diffing

### Plugin System
- **`Droodotfoo.PluginSystem`** — Plugin lifecycle manager (GenServer)
  - 8 @spec annotations, auto-registers 10 built-in plugins
- **`Droodotfoo.Plugins.GameBase`** — Shared utilities for game plugins
  - 18 utility functions with comprehensive @spec

## Terminal Commands

- **`Droodotfoo.Terminal.Commands`** — Command implementations
- **`Droodotfoo.Terminal.CommandParser`** — Input parsing
- **`Droodotfoo.Terminal.CommandRegistry`** — Command registration

## Web3 Integration

All Web3 modules have comprehensive @spec coverage:

- **`Droodotfoo.Web3`** — Main coordinator with wallet authentication
- **`Droodotfoo.Web3.Auth`** — Signature verification, session management
- **`Droodotfoo.Web3.ENS`** — ENS resolution (7 functions documented)
  - Forward/reverse resolution, avatar fetching, name validation
- **`Droodotfoo.Web3.NFT`** — ERC-721/1155 fetching via OpenSea/Alchemy
- **`Droodotfoo.Web3.Token`** — ERC-20 balances, pricing, charts
- **`Droodotfoo.Web3.Transaction`** — Transaction building and broadcasting
- **`Droodotfoo.Web3.Contract`** — Smart contract interaction
- **`Droodotfoo.Web3.IPFS`** — IPFS storage and retrieval

## Fileverse Integration

Comprehensive P2P collaboration with 15 documented modules:

### Main Modules
- **`Droodotfoo.Fileverse.Portal`** — P2P file sharing via WebRTC
  - 17 functions, create/join portals, share files, manage peers
- **`Droodotfoo.Fileverse.DDoc`** — Decentralized documents with encryption
- **`Droodotfoo.Fileverse.DSheet`** — Onchain data visualization
- **`Droodotfoo.Fileverse.Storage`** — IPFS storage integration
- **`Droodotfoo.Fileverse.Encryption`** — E2E encryption with Signal Protocol
- **`Droodotfoo.Fileverse.Heartbit`** — Health monitoring
- **`Droodotfoo.Fileverse.Agent`** — AI agent integration

### Portal Sub-modules (8 modules)
- **`Portal.Presence`** — Real-time peer presence tracking (15 functions)
- **`Portal.PresenceServer`** — GenServer for presence state
- **`Portal.WebRTC`** — WebRTC connection handling
- **`Portal.Transfer`** — File transfer orchestration
- **`Portal.Chunker`** — File chunking for P2P transfers
- **`Portal.Notifications`** — Real-time event notifications
- **`Portal.ActivityTracker`** — Activity feed management
- **`Portal.TransferProgress`** — Progress tracking for transfers

## Integrations

### Spotify
- **`Droodotfoo.Spotify`** — OAuth integration (GenServer)
  - 14 @spec annotations, playback control, playlist management
- **`Droodotfoo.Spotify.Auth`** — OAuth flow implementation
- **`Droodotfoo.Spotify.API`** — Spotify Web API client

### GitHub
- **`Droodotfoo.GitHub`** — GitHub API integration
- **`Droodotfoo.GitHub.Client`** — HTTP client wrapper
- **`Droodotfoo.GitHub.ASCIIArt`** — Chart rendering

## Game Plugins

Seven documented game plugins with full @spec coverage:

- **`Droodotfoo.Plugins.Calculator`** — RPN & standard calculator modes
- **`Droodotfoo.Plugins.TypingTest`** — WPM tracking with real-time metrics
- **`Droodotfoo.Plugins.MatrixRain`** — Digital rain animation effect
- **`Droodotfoo.Plugins.SnakeGame`** — Classic snake with collision detection
- **`Droodotfoo.Plugins.Tetris`** — Full tetromino game with scoring system
- **`Droodotfoo.Plugins.TwentyFortyEight`** — 2048 puzzle with undo system
- **`Droodotfoo.Plugins.Wordle`** — Word guessing game (to be documented)
- **`Droodotfoo.Plugins.Conway`** — Game of Life simulation (to be documented)

## LiveView Components

- **`DroodotfooWeb.DroodotfooLive`** — Main terminal interface
- **`DroodotfooWeb.PortalLive`** — Portal collaboration UI
- **`DroodotfooWeb.ContactLive`** — Contact form
- **`DroodotfooWeb.ResumeLive`** — Resume page
- **`DroodotfooWeb.SpotifyLive`** — Spotify widget
- **`DroodotfooWeb.PostLive`** — Blog post display

## Content Management

- **`Droodotfoo.Content.Posts`** — Blog post manager (GenServer)
- **`Droodotfoo.Content.PostFormatter`** — Markdown rendering with syntax highlighting

## Documentation Usage

Generate and view documentation:

```bash
# Generate HTML docs
mix docs

# Open in browser
open doc/index.html

# Generate EPUB for offline reading
# (automatically generated with HTML)
```

Documentation features:
- Searchable module and function index
- Type definitions with cross-references
- Usage examples in @doc blocks
- Module grouping by feature area
- Dark/light theme support
