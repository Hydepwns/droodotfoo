# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Phoenix LiveView droodotfoo application with Raxol terminal UI framework. The project creates a terminal-style interface in the browser using a three-layer architecture:
1. **Raxol Terminal** - Terminal rendering engine
2. **Phoenix LiveView** - Real-time web orchestration
3. **Web Browser** - Character-perfect monospace grid display

## Development Commands

```bash
# Setup and run
mix setup              # Install dependencies and build assets
./bin/dev              # Start server with 1Password secrets (recommended)
mix phx.server         # Start Phoenix server (port 4000)
iex -S mix phx.server  # Start with interactive shell

# Testing and quality
mix test               # Run tests
mix test test/path/to/specific_test.exs  # Run single test file
mix format             # Format code
mix compile --warning-as-errors  # Check for compilation warnings

# Precommit (runs all checks)
mix precommit          # Compile with warnings as errors, check unused deps, format, and test

# Assets
mix assets.build       # Build CSS and JS
mix assets.deploy      # Build minified production assets
```

## Secret Management

### Local Development (1Password CLI)

Secrets are managed via 1Password CLI for secure local development:

```bash
# Install 1Password CLI
brew install --cask 1password-cli

# Sign in
op signin

# Create secrets item
op item create --category=login --title="droodotfoo-dev" \
  SPOTIFY_CLIENT_ID="your_value" \
  SPOTIFY_CLIENT_SECRET="your_value"

# Run with secrets loaded
./bin/dev
```

The `bin/dev` script automatically loads secrets from `op://Private/droodotfoo-dev/`.

### Production (Fly.io Secrets)

Production secrets are managed via Fly.io:

```bash
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
fly secrets set PHX_HOST="your-app.fly.dev"
fly secrets set SPOTIFY_CLIENT_ID="prod_value"
fly secrets set SPOTIFY_CLIENT_SECRET="prod_value"
fly secrets set CDN_HOST="your-project.pages.dev"  # Optional CDN
```

## Architecture

### Key Modules

- **Droodotfoo.RaxolApp** (`lib/droodotfoo/raxol_app.ex`) - GenServer managing terminal UI state, handles keyboard navigation and content rendering
- **Droodotfoo.TerminalBridge** (`lib/droodotfoo/terminal_bridge.ex`) - Converts Raxol buffer cells to HTML while preserving 1ch grid alignment
- **DroodotfooWeb.DroodotfooLive** (`lib/droodotfoo_web/live/droodotfoo_live.ex`) - LiveView module handling real-time updates and keyboard events

### Frontend Architecture

- **Grid System**: CSS uses 1ch units for character-perfect alignment
- **JavaScript**: `assets/js/terminal_grid.ts` enforces grid on resize, `assets/js/hooks.ts` handles LiveView integration
- **Styling**: Monospace-web aesthetic with Monaspace Argon font

### Routing

- `/` - Main LiveView terminal interface
- `/static` - Static HTML fallback page
- `/dev/dashboard` - Phoenix LiveDashboard (dev only)

## Code Patterns

### Functional Elixir Patterns
- Use pipe operators for data transformations
- Pattern match in function heads over conditionals
- Keep state immutable except in GenServers
- Avoid imperative patterns; use functional approaches

### Command Architecture

**Single Source of Truth**: Command metadata is centralized in `Droodotfoo.Terminal.CommandRegistry`.

**Pattern**:
- `CommandRegistry` (`lib/droodotfoo/terminal/command_registry.ex`) - Central registry with all command definitions (names, aliases, descriptions, categories, usage, examples)
- `CommandBase` (`lib/droodotfoo/terminal/command_base.ex`) - Behavior providing execution patterns (validation, error handling, result normalization)
- Command modules (`lib/droodotfoo/terminal/commands/*.ex`) - Implement only execution logic via `execute/3` callback

**Adding a new command**:
1. Add command metadata to `@commands` list in `CommandRegistry`
2. Implement `execute/3` in the appropriate command module
3. Add command routing in `lib/droodotfoo/terminal/commands.ex`

Example:
```elixir
# In CommandRegistry
%{
  name: "mycommand",
  aliases: ["mc"],
  description: "Does something useful",
  category: :utility
}

# In Commands.MyModule
@impl true
def execute("mycommand", args, state) do
  {:ok, "Result", state}
end
```

### Terminal Rendering
- Each character occupies exactly 1ch width
- Use ASCII art only (no emojis)
- Maintain 80-column terminal width
- Box-drawing characters for UI elements

### LiveView Events
```elixir
# Keyboard handling pattern
def handle_event("keydown", %{"key" => key}, socket) do
  # Send to Raxol GenServer
  # Update assigns with new buffer
  {:noreply, socket}
end
```

## Rendering Architecture

### When to Use Pure LiveView
Use pure Phoenix LiveView for:
- **Content pages**: Blog posts, resume, contact forms
- **Terminal UI**: Raxol-based interfaces (DroodotfooLive)
- **Simple forms**: User input with server-side validation
- **Real-time updates**: LiveView excels at server-pushed updates

Examples: `ContactLive`, `ResumeLive`, `PostLive`, `DroodotfooLive`

### When to Use Astro Components + LiveView
Use Astro components embedded in LiveView for:
- **Complex client-side interactions**: 3D rendering, audio players
- **Heavy JavaScript libraries**: Three.js (STL viewer), Spotify Web Playback SDK
- **Progressive enhancement**: Features that degrade gracefully
- **Static content islands**: Pre-rendered components in dynamic pages

Examples: `SpotifyLive`, `STLViewerLive`, `PWALive`

**Integration Pattern**:
```elixir
# LiveView template
<div id="astro-component" phx-hook="AstroComponentHook" />
```

```javascript
// JavaScript hook (assets/js/hooks/)
Hooks.AstroComponentHook = {
  mounted() {
    // Load and initialize Astro component
    // Set up bidirectional communication with LiveView
  }
}
```

### Layout Consistency
All LiveViews use the same root layout (`DroodotfooWeb.Layouts.root`). No intermediate app layout - keep the monospace aesthetic consistent across all pages.

## Dependencies

Main dependencies managed in `mix.exs`:
- Phoenix 1.8.1 with LiveView 1.1.12
- Raxol 1.4.1 (terminal UI framework)
- Bandit web server (1.5+)
- Tailwind CSS and esbuild for assets
- Swoosh 1.15+ for email functionality
- ChromicPDF 1.0+ for PDF generation

## Testing Approach

- Unit tests for Raxol terminal logic
- LiveView tests for interaction handling
- Grid alignment verification in browser
- Use `{:lazy_html, ">= 0.1.0"}` for HTML testing

## Important Notes

- No database (Ecto not included)
- 60fps update cycle via LiveView
- Terminal size fixed at 110x45 characters (110 columns × 45 rows)
- Font files should be in `/priv/static/fonts/`
- Responsive design snaps to character widths

## Deployment

### Fly.io Configuration

The app is configured to deploy to Fly.io with the following features:

- **Secrets Management**: All sensitive values stored in Fly.io secrets
- **CDN Support**: Optional Cloudflare Pages integration via `CDN_HOST` env var
- **Static Assets**: Can be offloaded to CDN or served from Fly.io
- **Environment Variables**: Loaded at runtime via `config/runtime.exs`

### Required Environment Variables

Production requires these environment variables (set via `fly secrets set`):

- `SECRET_KEY_BASE` - Phoenix session encryption key
- `PHX_HOST` - Production domain name
- `SPOTIFY_CLIENT_ID` - Spotify API credentials (optional)
- `SPOTIFY_CLIENT_SECRET` - Spotify API credentials (optional)
- `CDN_HOST` - Cloudflare Pages domain (optional)

### Static Asset CDN (Cloudflare Pages)

When `CDN_HOST` is set, the endpoint's `static_url` is configured to serve assets from the CDN:

```elixir
static_url: [host: cdn_host, scheme: "https"]
```

This offloads static file delivery to Cloudflare's edge network for improved performance.