# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Phoenix LiveView portfolio and blog application with monospace web design. The project creates a character-perfect grid display using Wickstrom's monospace web technique with 1ch horizontal units and rem-based line-height.

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

# Pattern Cache Management
mix pattern_cache stats      # Show cache statistics
mix pattern_cache clear      # Clear all cached patterns
mix pattern_cache benchmark  # Benchmark cache performance (568x speedup!)
mix pattern_cache warmup     # Pre-generate patterns for all posts
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
  SPOTIFY_CLIENT_SECRET="your_value" \
  GITHUB_TOKEN="your_github_token"  # Optional: for higher API rate limits

# Run with secrets loaded
./bin/dev
```

The `bin/dev` script automatically loads secrets from `op://Private/droodotfoo-dev/`.

**Optional: GitHub Token**
- Without token: 60 requests/hour (sufficient for development)
- With token: 5000 requests/hour (recommended for production)
- Create token at: https://github.com/settings/tokens (needs `public_repo` scope)

### Production (Fly.io Secrets)

Production secrets are managed via Fly.io:

```bash
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
fly secrets set PHX_HOST="your-app.fly.dev"
fly secrets set SPOTIFY_CLIENT_ID="prod_value"
fly secrets set SPOTIFY_CLIENT_SECRET="prod_value"
fly secrets set GITHUB_TOKEN="prod_github_token"  # Optional: recommended for production
fly secrets set BLOG_API_TOKEN=$(mix phx.gen.secret)  # REQUIRED: for /api/posts endpoint
fly secrets set CDN_HOST="your-project.pages.dev"  # Optional CDN
```

### Blog Post API

The `/api/posts` endpoint allows publishing posts from Obsidian/external tools.
Requires `BLOG_API_TOKEN` environment variable.

See [docs/guides/security.md](docs/guides/security.md) for authentication details and rate limits.

## Architecture

### Key Modules

- **Droodotfoo.Content.Posts** (`lib/droodotfoo/content/posts.ex`) - Blog post loading, parsing, and caching with ETS
- **Droodotfoo.Content.PatternCache** (`lib/droodotfoo/content/pattern_cache.ex`) - SVG pattern generation and caching
- **Droodotfoo.GitHub** (`lib/droodotfoo/github/`) - GitHub API integration for projects page
- **DroodotfooWeb.PostLive** (`lib/droodotfoo_web/live/post_live.ex`) - Blog post rendering with series navigation

### Frontend Architecture

- **Grid System**: CSS uses 1ch units for character-perfect alignment
- **JavaScript**: `assets/js/hooks.ts` handles LiveView integration
- **Styling**: Monospace-web aesthetic with Monaspace Argon font

### Performance & Caching

**JavaScript Bundle Optimization**:
- Main bundle: 273KB (with code splitting enabled)
- Heavy libraries (THREE.js, ethers.js) dynamically imported only when needed
- Lazy-loaded hooks reduce initial page load by 96.5%

**Server-Side Caching**:
- **Pattern Cache** (`lib/droodotfoo/content/pattern_cache.ex`) - ETS-based cache for SVG patterns
  - 568x speedup for cached patterns (26ms → 47µs)
  - 24-hour TTL (patterns are deterministic)
  - Automatic cleanup every 10 minutes
  - Management: `mix pattern_cache stats|clear|benchmark|warmup`

- **GitHub Cache** (`lib/droodotfoo/github/cache.ex`) - Repository data with 1-hour TTL
- **Spotify Cache** (`lib/droodotfoo/spotify/cache.ex`) - Currently playing data
- **Posts Cache** (`lib/droodotfoo/content/posts.ex`) - ETS-based blog post metadata

**Two-Phase Loading**:
- Projects page loads instantly, enriches with GitHub data asynchronously
- Pattern: `mount` renders immediately, `handle_info` updates with API data

### Routing

- `/` - Home page
- `/posts` - Blog posts listing
- `/posts/:slug` - Individual blog post
- `/projects` - GitHub projects showcase
- `/resume` - Resume page
- `/contact` - Contact form
- `/dev/dashboard` - Phoenix LiveDashboard (dev only)

## Code Patterns

### Functional Elixir Patterns
- Use pipe operators for data transformations
- Pattern match in function heads over conditionals
- Keep state immutable except in GenServers
- Avoid imperative patterns; use functional approaches

### Monospace Grid
- Each character occupies exactly 1ch width
- Use ASCII art only (no emojis)
- Box-drawing characters for UI elements

## Rendering Architecture

### When to Use Pure LiveView
Use pure Phoenix LiveView for:
- **Content pages**: Blog posts, resume, contact forms
- **Simple forms**: User input with server-side validation
- **Real-time updates**: LiveView excels at server-pushed updates

Examples: `ContactLive`, `ResumeLive`, `PostLive`, `ProjectsLive`

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

## Content System

### Blog Posts

The blog system is file-based with markdown posts stored in `priv/posts/`. Key features:

- **Markdown with YAML frontmatter**: Posts use MDEx for fast rendering with syntax highlighting
- **Series support**: Group related posts with `series` and `series_order` frontmatter fields
- **Social sharing**: Automatic Open Graph images via SVG pattern generation or custom images
- **Reading progress**: Client-side progress bar tracks scroll position
- **Enhanced metadata**: Article-specific OpenGraph tags for better link previews

Example frontmatter with series:
```yaml
---
title: "Phoenix LiveView Basics"
date: "2025-01-18"
description: "Introduction to Phoenix LiveView"
tags: ["elixir", "phoenix", "liveview"]
slug: "phoenix-liveview-basics"
series: "Phoenix LiveView Tutorial"
series_order: 1
---
```

Posts in a series automatically display series navigation showing all related posts with the current post highlighted.

## Dependencies

Main dependencies managed in `mix.exs`:
- Phoenix 1.8.1 with LiveView 1.1.12
- Bandit web server (1.5+)
- Tailwind CSS and esbuild for assets
- MDEx for markdown parsing
- Swoosh 1.15+ for email functionality
- ChromicPDF 1.0+ for PDF generation

## Testing Approach

- Unit tests for content and API modules
- LiveView tests for interaction handling
- Use `{:lazy_html, ">= 0.1.0"}` for HTML testing

## Important Notes

- No database (Ecto not included)
- Font files should be in `/priv/static/fonts/`
- Responsive design snaps to character widths

## Deployment

See [docs/guides/deployment.md](docs/guides/deployment.md) for Fly.io setup, environment variables, and CDN configuration.

**Quick reference:**
- Secrets: `fly secrets set SECRET_KEY_BASE=... PHX_HOST=...`
- Deploy: `fly deploy`
- CDN: Set `CDN_HOST` for Cloudflare Pages integration