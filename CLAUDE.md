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
mix test --failed      # Re-run previously failed tests
mix format             # Format code
mix compile --warning-as-errors  # Check for compilation warnings

# Precommit (runs all checks)
mix precommit          # Compile with warnings as errors, check unused deps, format, and test

# Quick checks
mix check.quick        # Compile, format check, credo --strict
mix check.full         # Full ex_check + unused deps

# Assets
mix assets.build       # Build CSS and JS
mix assets.deploy      # Build minified production assets with Brotli compression

# Pattern Cache Management
mix pattern_cache stats      # Show cache statistics
mix pattern_cache clear      # Clear all cached patterns
mix pattern_cache benchmark  # Benchmark cache performance
mix pattern_cache warmup     # Pre-generate patterns for all posts

# Documentation
mix docs               # Generate ExDoc documentation

# Usage Rules (sync LLM guidelines from dependencies)
mix usage_rules.sync AGENTS.md --all --link-to-folder deps --yes
```

## Architecture

### Module Organization

```
lib/droodotfoo/
  content/           # Blog system: posts, patterns, formatters
  github/            # GitHub API integration and caching
  spotify/           # Spotify OAuth and playback
  web3/              # Ethereum: ENS, NFT, tokens, contracts
  fileverse/         # P2P file sharing with WebRTC
  plugins/           # Games: wordle, tetris, snake, conway, etc.
  resume/            # Resume data, filtering, PDF generation
  features/          # Analytics, SSH content, resume export

lib/droodotfoo_web/
  live/              # LiveView modules
  controllers/       # Traditional controllers (API, auth)
  components/        # Reusable UI components
```

### Key Modules

- **Droodotfoo.Content.Posts** (`lib/droodotfoo/content/posts.ex`) - Blog post loading, parsing, and ETS caching
- **Droodotfoo.Content.PatternCache** - SVG pattern generation with 568x speedup via ETS caching
- **Droodotfoo.GitHub** - GitHub API integration with 1-hour TTL cache
- **Droodotfoo.Spotify** - OAuth integration with playback controls

### Caching Architecture

All caches use ETS for performance:
- **Pattern Cache** - 24-hour TTL, deterministic SVG patterns per post
- **GitHub Cache** - 1-hour TTL for repository data
- **Spotify Cache** - Currently playing data
- **Posts Cache** - Blog post metadata

### Two-Phase Loading Pattern

Pages load instantly, then enrich with API data asynchronously:
```elixir
def mount(_params, _session, socket) do
  if connected?(socket), do: send(self(), :load_data)
  {:ok, assign(socket, data: nil, loading: true)}
end

def handle_info(:load_data, socket) do
  {:noreply, assign(socket, data: fetch_data(), loading: false)}
end
```

### Routing

- `/` - Home page
- `/posts` - Blog posts listing
- `/posts/:slug` - Individual blog post
- `/projects` - GitHub projects showcase
- `/resume` - Resume page
- `/contact` - Contact form
- `/dev/dashboard` - Phoenix LiveDashboard (dev only)

## Usage Rules

[AGENTS.md](AGENTS.md) contains LLM usage rules synced from dependencies via the `usage_rules` package. These provide authoritative guidelines for Phoenix, LiveView, Ecto, HEEx templates, and Elixir patterns.

After adding new dependencies, re-sync rules:
```bash
mix usage_rules.sync AGENTS.md --all --link-to-folder deps --yes
```

Linked rule files are stored in `deps/*/usage-rules/`.

## Code Patterns

### Functional Elixir

- Use pipe operators for data transformations
- Pattern match in function heads over conditionals
- Keep state immutable except in GenServers
- Use `Req` for HTTP requests (already included)

### Monospace Grid

- Each character occupies exactly 1ch width
- Use ASCII art only (no emojis)
- Box-drawing characters for UI elements

### Phoenix LiveView

- Wrap templates with `<Layouts.app flash={@flash}>`
- Use `<.input>` component from core_components.ex for forms
- Use streams for collections to avoid memory issues
- Always assign forms via `to_form/2`, never access changesets in templates
- Add unique DOM IDs to key elements for testing

See [AGENTS.md](AGENTS.md) for comprehensive Phoenix/Elixir/LiveView guidelines synced from dependencies via `usage_rules`.

## Content System

Blog posts are file-based in `priv/posts/` with YAML frontmatter:

```yaml
---
title: "Post Title"
date: "2025-01-18"
description: "Description for SEO"
tags: ["elixir", "phoenix"]
slug: "post-slug"
series: "Series Name"       # Optional: groups related posts
series_order: 1             # Optional: position in series
---
```

Posts in a series display navigation with all related posts.

## Frontend Architecture

- **Grid System**: CSS uses 1ch units for character-perfect alignment
- **JavaScript**: `assets/js/hooks.ts` with lazy-loaded heavy libraries
- **Styling**: Tailwind CSS v4 with Monaspace Argon font

Heavy libraries (THREE.js, ethers.js) are dynamically imported only when needed.

## Testing

```bash
mix test                              # Run all tests
mix test test/specific_test.exs       # Single file
mix test --failed                     # Re-run failed tests
```

- Use `LazyHTML` for HTML assertions in LiveView tests
- Reference element IDs in tests: `assert has_element?(view, "#my-form")`

## Secrets

- **Local dev**: `./bin/dev` loads secrets from 1Password
- **Production**: `fly secrets set KEY=value`
- See [docs/guides/security.md](docs/guides/security.md) for API authentication

## Deployment

```bash
fly deploy                    # Deploy to Fly.io
./scripts/deploy-cdn.sh       # Deploy assets to CDN
```

See [docs/guides/deployment.md](docs/guides/deployment.md) for full setup.
