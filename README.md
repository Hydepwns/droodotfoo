# droo.foo

Interactive terminal portfolio built with Phoenix LiveView and Raxol terminal UI framework.

## Features

- **Terminal Interface**: Full Unix-like terminal experience in the browser
- **Vim Navigation**: hjkl movement, search with `/`, command mode
- **Plugin System**: Extensible architecture with games and utilities
- **Spotify Integration**: Music player with playlist browsing and playback control
- **Real-time Updates**: 60fps rendering via Phoenix LiveView
- **PWA Support**: Installable progressive web app with offline capabilities

## Quick Start

### Local Development with 1Password CLI

```bash
# Install dependencies
mix setup

# Install 1Password CLI
brew install --cask 1password-cli

# Sign in to 1Password
op signin

# Create secrets in 1Password (optional for Spotify)
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

- `help` - Show available commands
- `ls` - List directory contents
- `cat <file>` - Display file contents
- `spotify` - Launch Spotify player
- `snake` - Play Snake game
- `calc` - Calculator
- `matrix` - Matrix rain effect
- `themes` - Switch color themes
- `clear` - Clear terminal

## Architecture

- **Phoenix LiveView**: Real-time web framework
- **Raxol**: Terminal rendering engine
- **TEA/Elm Pattern**: Functional state management
- **ETS Caching**: Performance optimization
- **Plugin System**: Modular extensions

## Development

```bash
# Run tests
mix test

# Format code
mix format

# Compile with warnings
mix compile --warning-as-errors

# Full precommit check
mix precommit
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

- **[TODO.md](TODO.md)** - Current work and next steps
- **[DEVELOPMENT.md](docs/DEVELOPMENT.md)** - Technical documentation, architecture, integrations
- **[FEATURES.md](docs/FEATURES.md)** - Feature roadmap (29 features, 5-phase plan)
- **[CLAUDE.md](CLAUDE.md)** - AI assistant instructions
- **[AGENTS.md](AGENTS.md)** - Phoenix/Elixir guidelines
