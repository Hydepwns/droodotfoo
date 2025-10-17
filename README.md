# droo.foo

Interactive terminal portfolio built with Phoenix LiveView and Raxol terminal UI framework.

**Live Demo**: [droo.foo](https://droo.foo)

> Note: Spotify and Web3 features require additional OAuth/wallet setup (optional). Core terminal, games, and utilities work without configuration.

## Features

### Core Terminal
- **Terminal Interface**: Full Unix-like terminal experience in the browser with 80x24 character grid
- **Vim Navigation**: hjkl movement, search with `/`, command mode with `:` prefix
- **Real-time Updates**: 60fps rendering via Phoenix LiveView with optimized diffing
- **PWA Support**: Installable progressive web app with offline capabilities

### Integrations
- **Web3 Wallet**: Connect MetaMask for wallet authentication, ENS resolution, NFT/token viewing
- **Spotify Player**: OAuth integration with playback controls, playlist browsing, and real-time progress
- **GitHub Stats**: Repository visualization and contribution graphs
- **STL Viewer**: 3D model viewer with Three.js integration

### Fileverse P2P Collaboration
- **Portal**: WebRTC-based P2P file sharing with real-time peer presence
- **dDocs**: Decentralized documents with end-to-end encryption (Signal Protocol)
- **dSheets**: Onchain data visualization with CSV/JSON export
- **E2E Encryption**: AES-256-GCM encryption for all transfers with wallet-derived keys

### Plugin System (10 Built-in)
- **Games**: Snake, Tetris, 2048, Wordle, Conway's Game of Life
- **Utilities**: Calculator (RPN/standard), Typing Test (WPM tracking)
- **Effects**: Matrix Rain animation
- **Integrations**: Spotify player, GitHub browser

## Quick Start

### Local Development with 1Password CLI

```bash
# Install dependencies
mix setup

# Install 1Password CLI
# Install the desktop app
# https://1password.com/downloads
# https://developer.1password.com/docs/cli/app-integration/
brew install --cask 1password-cli

# Sign in to 1Password
op signin

# Create secrets in 1Password.
op item create --category=login --title="droodotfoo-dev" \
  SPOTIFY_CLIENT_ID="your_client_id" \
  SPOTIFY_CLIENT_SECRET="your_client_secret"

# Start server with secrets loaded from 1Password
./bin/dev
```

### Alternative: Manual Environment Variables

```bash
# Set Spotify credentials (optional)
export SPOTIFY_CLIENT_ID="your_client_id"
export SPOTIFY_CLIENT_SECRET="your_client_secret"

# Start server
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000)

## Terminal Commands

### Navigation
- `:help` - Show available commands and keyboard shortcuts
- `:ls` - List directory contents
- `:cat <section>` - Display section content

### Games & Utilities
- `:snake` - Classic Snake game (WASD/arrows)
- `:tetris` - Tetris with scoring system
- `:2048` - 2048 sliding puzzle with undo
- `:wordle` - Word guessing game
- `:conway` - Conway's Game of Life
- `:calc` - Calculator (RPN and standard modes)
- `:typing` - Typing speed test with WPM tracking
- `:matrix` - Matrix rain animation

### Integrations
- `:spotify` - Launch Spotify player (requires OAuth)
- `:github` - Browse GitHub repositories
- `:web3` - Connect Web3 wallet
- `:ens <name>` - Resolve ENS names (requires Web3)
- `:portal` - P2P file sharing portal

### System
- `:perf` - Performance dashboard with metrics
- `:themes` - Switch color themes
- `:clear` - Clear terminal output
- `?` - Toggle help modal
- `v` - Toggle vim mode

## Architecture

- **Phoenix LiveView**: Real-time web framework with WebSocket connections
- **Raxol Terminal**: Character-perfect monospace rendering (1ch CSS grid)
- **TEA/Elm Pattern**: Functional state management with immutable state
- **GenServers**: RaxolApp, PluginSystem, Spotify, Content.Posts orchestration
- **Plugin System**: Behavior-based extensible architecture (10 built-in plugins)
- **Performance**: 60fps rendering, ETS caching, optimized LiveView diffing
- **WebRTC P2P**: Real-time peer connections for Portal file sharing
- **E2E Encryption**: Signal Protocol (X3DH + Double Ratchet) for secure transfers

**Test Coverage**: 801/836 tests passing (96%)

## Tech Stack

- **Backend**: Elixir 1.18+, Phoenix 1.8, LiveView 1.0
- **Terminal**: Raxol 1.4.1 (character-perfect rendering)
- **Frontend**: TypeScript, esbuild, Tailwind CSS
- **Web3**: ethers.js (wallet integration, ENS resolution)
- **P2P**: WebRTC (data channels for file sharing)
- **Encryption**: libsignal-protocol-nif (Signal Protocol), AES-256-GCM
- **3D Rendering**: Three.js (STL viewer)
- **Testing**: ExUnit (801/836 tests passing)
- **Server**: Bandit 1.5+ (HTTP/2 support)

## Development

```bash
# Run tests
mix test

# Run specific test file
mix test test/droodotfoo/raxol_app_test.exs

# Format code
mix format

# Compile with warnings
mix compile --warning-as-errors

# Full precommit check (compile, deps, format, test)
mix precommit

# Generate ExDoc documentation
mix docs
```

## Deployment

### Fly.io Production Deployment

```bash
# Install Fly CLI
brew install flyctl

# Login to Fly.io
fly auth login

# Set production secrets
fly secrets set \
  SECRET_KEY_BASE=$(mix phx.gen.secret) \
  SPOTIFY_CLIENT_ID="prod_client_id" \
  SPOTIFY_CLIENT_SECRET="prod_client_secret" \
  SPOTIFY_REDIRECT_URI="https://your-app.fly.dev/auth/spotify/callback" \
  PHX_HOST="your-app.fly.dev"

# Optional: Configure Cloudflare Pages CDN for static assets
fly secrets set CDN_HOST="your-project.pages.dev"

# Deploy
fly deploy
```

### Environment Variables

**Required for production:**
- `SECRET_KEY_BASE` - Phoenix secret key (generate with `mix phx.gen.secret`)
- `PHX_HOST` - Your production domain

**Optional:**
- `SPOTIFY_CLIENT_ID` - Spotify API client ID
- `SPOTIFY_CLIENT_SECRET` - Spotify API client secret
- `SPOTIFY_REDIRECT_URI` - OAuth callback URL
- `CDN_HOST` - Cloudflare Pages domain for static asset CDN
- `BLOG_API_TOKEN` - API token for Obsidian publishing
- `PORT` - Server port (default: 4000)

## Obsidian Publishing

Publish posts directly from Obsidian via API:

```bash
# Set API token
export BLOG_API_TOKEN="your_secure_token"

# POST to /api/posts with:
# - Authorization: Bearer <token>
# - Body: {"content": "markdown...", "metadata": {"title": "...", "description": "...", "tags": [...]}}
```

Posts saved to `priv/posts/` and served at `/posts/:slug`

## Documentation

### Project Documentation
- **[CLAUDE.md](CLAUDE.md)** - Project overview and AI assistant instructions
- **[AGENTS.md](AGENTS.md)** - Phoenix/Elixir development guidelines

### Technical Documentation (docs/)
- **[architecture.md](docs/architecture.md)** - Complete system architecture (5 layers, data flow, concurrency)
- **[api_reference.md](docs/api_reference.md)** - API index (113 HTML pages, 120+ @spec, 60+ types)
- **[DEVELOPMENT.md](docs/DEVELOPMENT.md)** - Development guide and integrations
- **[TODO.md](docs/TODO.md)** - Current work and next steps
- **[FEATURES.md](docs/FEATURES.md)** - Feature roadmap (29 features, 5-phase plan)
- **[MODULE_INVENTORY.md](docs/MODULE_INVENTORY.md)** - Complete module catalog (108 active modules)
- **[TEST_STATUS.md](docs/TEST_STATUS.md)** - Test coverage and status
- **[WEB3_ARCHITECTURE.md](docs/WEB3_ARCHITECTURE.md)** - Web3 integration details

### API Documentation (ExDoc)
Generated comprehensive documentation with typespecs:

```bash
# Generate HTML documentation (113 pages)
mix docs

# View in browser
open doc/index.html
```

**Documentation includes:**
- 120+ function signatures with @spec annotations
- 60+ custom type definitions
- Module organization into 8 logical groups
- Usage examples and parameter descriptions
- Searchable interface with dark/light themes
