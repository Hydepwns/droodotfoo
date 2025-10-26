# droo.foo

Personal portfolio and blog built with Phoenix LiveView, featuring generative art patterns and monospace web aesthetics. Optional terminal interface with games and plugins available for interactive experiences.

![Test Coverage](https://img.shields.io/badge/coverage-41.2%25-orange)
![Tests](https://img.shields.io/badge/tests-1149%20passing-brightgreen)
![Elixir](https://img.shields.io/badge/elixir-1.17-purple)
![Phoenix](https://img.shields.io/badge/phoenix-1.8.1-orange)

**Live Demo**: [droo.foo](https://droo.foo)

> Optional integrations: Spotify player, Web3 wallet, terminal interface with games.
> All require setup but are not needed for core functionality.

## Features

### Core Portfolio & Blog
- **Monospace Web Design**: Character-perfect grid using 1ch units and rem-based line-height
- **Blog System**: File-based markdown posts with YAML frontmatter and series support
- **Generative Patterns**: Unique SVG patterns per post with 8 animation styles
- **Real-time Updates**: Phoenix LiveView for instant page updates
- **Projects Showcase**: GitHub integration with stats and contribution visualization
- **Resume System**: Structured JSON-based resume with filtering and search

### Optional Terminal Interface (110x45 grid)
- **Terminal UI**: Browser-based character grid with Unix-style commands
- **Vim Navigation**: hjkl movement, search with `/`, command mode with `:`
- **Real-time Rendering**: LiveView WebSocket connection for 60fps updates
- **PWA Support**: Installable as progressive web app

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

## Monospace Web Design

The site implements Wickström's monospace web technique for character-perfect grid alignment:

**Horizontal Grid (1ch units):**
- Each character occupies exactly 1ch width
- Container widths snap to character boundaries: `calc(round(down, 80ch, 1ch))`
- Table columns use character-based widths (8ch, 12ch, 20ch, etc.)

**Vertical Grid (rem-based line-height):**
- Fixed `--line-height: 1.5rem` for predictable calculations
- Prevents line-height compounding in nested elements
- Scales proportionally: 24px at 16px base, 21px at 14px mobile

**Visual Refinements:**
- Double-line horizontal rules with layered pseudo-elements
- Precision table padding compensates for border thickness
- Media element grid alignment (images/videos snap to line-height)
- All spacing uses multiples of 1ch or line-height

**Benefits:**
- Zero layout shift (every character positioned exactly)
- Maintainable vertical rhythm throughout content
- Professional terminal-inspired aesthetic
- Consistent across all themes and screen sizes

See [wickstrom.tech](https://wickstrom.tech/2024-09-26-how-i-built-the-monospace-web.html) for the original technique.

## Architecture

Built with modular Phoenix LiveView architecture:

**Monospace Web Design**: Character-perfect grid using Wickström's monospace web technique with 1ch horizontal units and rem-based line-height for predictable vertical rhythm. Double-line dividers, precision table padding, and media element grid alignment maintain visual consistency.

**Rendering**: Phoenix LiveView handles real-time updates over WebSockets. Optional Raxol terminal UI available for interactive experiences.

**State Management**: GenServers orchestrate content loading, GitHub API integration, and optional terminal/plugin state. Functional patterns with immutable state throughout.

**Performance**: ETS caching for GitHub API data, blog post metadata, and SVG patterns. Pattern cache provides 568x speedup (26ms → 47µs). Page loads under 200ms.

**Content System**: File-based blog posts with markdown + YAML frontmatter. Deterministic SVG pattern generation per post with 8 animation styles. No database required.

**Optional Features**: Terminal interface with 10 plugins (games, utilities), Web3 wallet integration, P2P file sharing with E2E encryption.

**Test Coverage**: 1,149/1,170 tests passing (98.2% pass rate, 41.2% code coverage)

## Tech Stack

- **Backend**: Elixir 1.17+, Phoenix 1.8.1, LiveView 1.1.12, Bandit web server
- **Styling**: Tailwind CSS v4, Monaspace font family (Argon, Neon, Xenon, Radon, Krypton)
- **Monospace Grid**: 1ch units + rem-based line-height for character-perfect alignment
- **Frontend**: TypeScript, esbuild for bundling, lazy-loaded hooks
- **Content**: MDEx for markdown parsing with syntax highlighting
- **Caching**: ETS for GitHub API, posts, patterns (568x speedup for patterns)
- **Optional**: Raxol 1.4.1 (terminal), ethers.js (Web3), Three.js (STL viewer)
- **Testing**: ExUnit with 1,149/1,170 tests passing (98.2%)

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

# Create fly.toml and guides through setup
# Fly.io will handle the routing from external ports (80/443) to your app's internal port 8080 (default)
# Even though our config/runtime.exs specifies poft 4000
fly launch
# Or if you want to create the app manually:
fly apps create droodotfoo

# Set production secrets (required)
# once successfully set with fly secrets set, they're stored encrypted in Fly.io's infra
# and injected into your app as environment variables at runtime
fly secrets set \
  SECRET_KEY_BASE=$(mix phx.gen.secret) \
  PHX_HOST="droodotfoo.fly.dev"

# Set blog API token (required for Obsidian publishing)
fly secrets set BLOG_API_TOKEN=$(mix phx.gen.secret)

# Optional: Spotify integration
# obtain secrets from https://developer.spotify.com/dashboard
fly secrets set \
  SPOTIFY_CLIENT_ID="prod_client_id" \
  SPOTIFY_CLIENT_SECRET="prod_client_secret"

# Then register https://droo.foo/auth/spotify/callback in Spotify Dashboard
# https://developer.spotify.com/dashboard
# add redirect URI and the website link (i.e. `PHX_HOST`)
SPOTIFY_REDIRECT_URI="https://your-app.fly.dev/auth/spotify/callback"

# Optional: GitHub API token for higher rate limits (5000/hr vs 60/hr)
fly secrets set GITHUB_TOKEN="ghp_xxxxx"

# Optional: Configure Cloudflare Pages CDN for static assets
fly secrets set CDN_HOST="your-project.pages.dev"

# Deploy
fly deploy
```

### Environment Variables

**Required for production:**
- `SECRET_KEY_BASE` - Phoenix secret key (generate with `mix phx.gen.secret`)
- `PHX_HOST` - Your production domain

**Required for blog API:**
- `BLOG_API_TOKEN` - API token for Obsidian publishing (generate with `mix phx.gen.secret`)

**Optional:**
- `SPOTIFY_CLIENT_ID` - Spotify API client ID
- `SPOTIFY_CLIENT_SECRET` - Spotify API client secret
- `SPOTIFY_REDIRECT_URI` - OAuth callback URL
- `GITHUB_TOKEN` - GitHub personal access token (5000/hr rate limit vs 60/hr without)
- `CDN_HOST` - Cloudflare Pages domain for static asset CDN
- `PORT` - Server port (default: 4000)

## Obsidian Publishing

Publish posts directly from Obsidian via API with built-in security:

```bash
# Generate and set API token
export BLOG_API_TOKEN=$(mix phx.gen.secret)

# POST to /api/posts with:
curl -X POST https://droo.foo/api/posts \
  -H "Authorization: Bearer $BLOG_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "# My Post\n\nContent here",
    "metadata": {
      "title": "My Post",
      "description": "Post description",
      "tags": ["elixir"]
    }
  }'
```

**Security Features:**
- Rate limiting: 10 posts/hour, 50 posts/day per IP
- Bearer token authentication (constant-time comparison)
- Content validation: 1MB size limit, path traversal prevention
- Slug validation: alphanumeric and hyphens only

Posts are saved to `priv/posts/` and served at `/posts/:slug`

## Security

The application implements multiple security layers:

**Authentication & Authorization:**
- OAuth 2.0 with CSRF protection (state parameter validation) for Spotify
- Bearer token authentication for blog API with constant-time comparison
- No token bypass - all endpoints require proper authentication

**Rate Limiting:**
- Blog API: 10 posts/hour, 50 posts/day per IP
- Contact form: Rate limited per IP
- ETS-based in-memory tracking with automatic cleanup

**Input Validation:**
- Content size limits (1MB max for blog posts)
- Path traversal prevention (no `..`, `/`, `\` in slugs)
- Slug sanitization (alphanumeric and hyphens only)
- XSS protection via Phoenix HTML escaping

**Production Deployment:**
- HTTPS enforcement via `force_ssl` (see config/prod.exs)
- Secure session cookies with SECRET_KEY_BASE
- Content Security Policy headers
- HSTS support for HTTPS-only access

## Documentation

### Project Documentation
- **[CLAUDE.md](CLAUDE.md)** - Project overview, patterns, and AI assistant context
- **[AGENTS.md](AGENTS.md)** - Phoenix/Elixir development guidelines

### Guides (docs/)
- **[docs/README.md](docs/README.md)** - Documentation index and quick start
- **[docs/TODO.md](docs/TODO.md)** - Active tasks, priorities, and roadmap
- **[docs/guides/deployment.md](docs/guides/deployment.md)** - Fly.io production deployment
- **[docs/guides/seo.md](docs/guides/seo.md)** - SEO optimization with JSON-LD
- **[docs/guides/assets.md](docs/guides/assets.md)** - Image and asset optimization

### API Documentation (ExDoc)
Generate comprehensive documentation with typespecs:

```bash
# Generate HTML documentation
mix docs

# View in browser
open doc/index.html
```

**Includes:**
- Module documentation with examples
- Function signatures with @spec annotations
- Type definitions and behaviors
- Searchable interface

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
