# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Phoenix LiveView web application with monospace web design. The project creates a character-perfect grid display using Wickstrom's monospace web technique with 1ch horizontal units and rem-based line-height.

## Development Commands

```bash
# Setup and run
mix setup              # Install dependencies and build assets
./bin/dev              # Start server with 1Password secrets (recommended)
mix phx.server         # Start Phoenix server (port 4000)
iex -S mix phx.server  # Start with interactive shell

# Testing and quality
mix test               # Run all tests
mix test test/path_test.exs       # Run single file
mix test test/path_test.exs:42    # Run specific test at line
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

# Wiki Management (wiki.droo.foo)
mix wiki.status              # Check article counts, MinIO, Ollama status
mix wiki.sync --full         # Initial sync of all sources (OSRS, nLab, machines)
mix wiki.sync osrs           # Sync specific source
mix wiki.import "Category theory"  # Import Wikipedia article

# Documentation
mix docs               # Generate ExDoc documentation

# Usage Rules (sync LLM guidelines from dependencies)
mix usage_rules.sync AGENTS.md --all --link-to-folder deps --yes

# Tidewave MCP (AI-assisted dev)
# 1. Start Phoenix server first
./bin/dev              # or mix phx.server
# 2. Restart Claude Code to connect (config in .mcp.json)
# 3. Verify with /mcp command - tidewave should show green checkmark
```

## Architecture

### Module Organization

```
lib/droodotfoo/
  content/           # Blog system: posts, patterns, formatters
  github/            # GitHub API integration and caching
  git/               # Multi-source git browser (GitHub, Forgejo)
  spotify/           # Spotify OAuth and playback
  web3/              # Ethereum: ENS, NFT, tokens, contracts
  fileverse/         # P2P file sharing with WebRTC
  plugins/           # Games: wordle, tetris, snake, conway, etc.
  resume/            # Resume data, filtering, PDF generation
  features/          # Analytics, SSH content, resume export
  wiki/              # Multi-source wiki aggregator (see Wiki Subsystem below)

lib/droodotfoo_web/
  live/              # LiveView modules (main site)
  controllers/       # Traditional controllers (API, auth)
  components/        # Reusable UI components
  git/               # Git subdomain (git.droo.foo)
    live/            # Repo browser, file viewer, commits
    components/      # Git-specific layouts and components
  wiki/              # Wiki subdomain (wiki.droo.foo, lib.droo.foo)
    live/            # Wiki LiveViews
    controllers/     # OSRS REST API (osrs/v1/)
    components/      # Wiki-specific components
```

### Key Modules

- **Droodotfoo.Content.Posts** (`lib/droodotfoo/content/posts.ex`) - Blog post loading, parsing, and ETS caching
- **Droodotfoo.Content.PatternCache** - SVG pattern generation with 568x speedup via ETS caching
- **Droodotfoo.GitHub** - GitHub API integration with 1-hour TTL cache
- **Droodotfoo.Git.Source** - Multi-provider git abstraction (GitHub, Forgejo)
- **Droodotfoo.Spotify** - OAuth integration with playback controls
- **Droodotfoo.Wiki.Search** - Full-text and semantic search with pgvector
- **Droodotfoo.Wiki.OSRS** - OSRS game data context (items, monsters)

### Wiki Subsystem

Multi-source wiki aggregator at `wiki.droo.foo` with semantic search:

```
lib/droodotfoo/wiki/
  content/           # Article, Revision, PendingEdit schemas
  ingestion/         # Source-specific sync workers and pipelines
    osrs_*           # OSRS Wiki (MediaWiki API)
    nlab_*           # nLab (git-based math wiki)
    wikipedia_*      # Wikipedia (REST API, curated pages)
    vintage_machinery_* # VintageMachinery.org (wget mirror)
  osrs/              # Item, Monster schemas for GEX API
  parts/             # Auto parts catalog (Part, Vehicle, Fitment)
  library/           # Document management (lib.droo.foo)
  backup/            # PostgresWorker for daily DB backups
  notifications/     # Email notifications for edit submissions
```

**Oban Workers** (background jobs):
- `OSRSSyncWorker` - every 15 min
- `NLabSyncWorker` - daily 4am
- `WikipediaSyncWorker` - weekly Saturday 2am
- `VintageMachinerySyncWorker` - weekly Sunday 2am
- `CrossLinkWorker` - daily 5am (cross-source linking)
- `PostgresWorker` - daily 3am (backup to MinIO)
- `EmbeddingWorker` - daily 6am (pgvector embeddings via Ollama)

**Storage**: MinIO (S3-compatible) for HTML/raw content, PostgreSQL with pgvector for semantic search.

### Git Subsystem

Multi-source git browser at `git.droo.foo`:

```
lib/droodotfoo/git/
  source.ex          # Behaviour for git providers
  github.ex          # GitHub API client
  forgejo.ex         # Forgejo/Gitea API client
```

Sources are dynamically discovered via `Droodotfoo.Git.Source` behaviour. Add new providers by implementing `list_repos/1`, `get_repo/2`, `list_contents/3`, `get_file/3`, and `list_commits/3`.

### Caching Architecture

All caches use ETS for performance:

- **Pattern Cache** - 24-hour TTL, deterministic SVG patterns per post
- **GitHub Cache** - 1-hour TTL for repository data
- **Spotify Cache** - Currently playing data
- **Posts Cache** - Blog post metadata
- **Wiki Cache** - Article content with invalidation on sync

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

**Main site (droo.foo)**:
- `/` - Home page
- `/posts`, `/posts/:slug` - Blog
- `/projects` - GitHub projects showcase
- `/resume` - Resume page
- `/contact` - Contact form
- `/dev/dashboard` - Phoenix LiveDashboard (dev only)

**Wiki subdomain (wiki.droo.foo)**:
- `/` - Landing page
- `/search` - Full-text and semantic search
- `/osrs/:slug`, `/nlab/:slug`, `/wikipedia/:slug` - Articles by source
- `/parts` - Auto parts catalog
- `/admin/sync`, `/admin/pending`, `/admin/art` - Admin (Tailnet-only)
- `/osrs/api/v1/items`, `/osrs/api/v1/monsters` - REST API

**Library subdomain (lib.droo.foo)** - Tailnet-only:
- `/` - Document index
- `/upload` - Upload new documents
- `/doc/:slug` - Document reader

**Git subdomain (git.droo.foo)**:
- `/` - Repository list (all sources)
- `/:source/:owner/:repo` - Repository detail
- `/:source/:owner/:repo/tree/:branch/*path` - File browser
- `/:source/:owner/:repo/blob/:branch/*path` - File viewer
- `/:source/:owner/:repo/commits/:branch` - Commit history

## Database

PostgreSQL with pgvector extension for semantic search:

```bash
# Create/migrate database
mix ecto.setup        # Create, migrate, seed
mix ecto.migrate      # Run pending migrations
mix ecto.reset        # Drop, create, migrate

# Generate migration
mix ecto.gen.migration create_foo
```

Key tables: `articles`, `revisions`, `osrs_items`, `osrs_monsters`, `documents`, `parts`, `pending_edits`, `oban_jobs`.

Repo is `Droodotfoo.Repo` with custom types in `Droodotfoo.PostgresTypes` (includes pgvector).

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

### RateLimiter Macro

Reusable rate limiting via `use Droodotfoo.RateLimiter`:

```elixir
defmodule MyApp.ContactRateLimiter do
  use Droodotfoo.RateLimiter,
    table_name: :contact_rate_limit,
    windows: [
      {:hourly, 3_600, 3},
      {:daily, 86_400, 10}
    ],
    log_prefix: "Contact form"
end
```

Provides `check_rate_limit/1`, `record/1`, and `get_status/1` callbacks. Used by contact form, pattern generation, post API, and wiki search.

## Content System

Blog posts are file-based in `priv/posts/` with YAML frontmatter:

```yaml
---
title: "Post Title"
date: "2025-01-18"
description: "Description for SEO"
tags: ["elixir", "phoenix"]
slug: "post-slug"
series: "Series Name" # Optional: groups related posts
series_order: 1 # Optional: position in series
---
```

Posts in a series display navigation with all related posts.

## Frontend Architecture

- **Grid System**: CSS uses 1ch units for character-perfect alignment
- **JavaScript**: `assets/js/hooks.ts` with lazy-loaded heavy libraries
- **Styling**: Tailwind CSS v4 with Monaspace Argon font

Heavy libraries (THREE.js, ethers.js) are dynamically imported only when needed.

## Testing

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

### Rust NIFs

The project uses Rust-based NIFs (ex_keccak, ex_secp256k1, autumn, mdex) for Web3 and markdown parsing. The Dockerfile forces source compilation via environment variables because GitHub release assets are often blocked from CI builders:

```dockerfile
ENV EX_KECCAK_BUILD="1"
ENV RUSTLER_BUILD="1"
ENV AUTUMN_BUILD="1"
ENV MDEX_BUILD="1"
```

If deployment fails with NIF download errors, verify these env vars are set in the Dockerfile.

See [docs/guides/deployment.md](docs/guides/deployment.md) for full setup.

## Phoenix v1.8 Notes

Key conventions from [AGENTS.md](AGENTS.md):

- **Always** begin LiveView templates with `<Layouts.app flash={@flash}>`
- Use `<.input>` from core_components.ex for forms (not raw HTML inputs)
- Use `<.icon name="hero-x-mark">` for icons (not Heroicons modules)
- `<.flash_group>` only in layouts.ex, never in templates
- Use `Req` for HTTP requests (already included), avoid HTTPoison/Tesla
- Tailwind v4: no tailwind.config.js, uses `@import "tailwindcss"` syntax
- Never use `@apply` in CSS, never inline `<script>` tags in templates

## Markdown in Posts

Blog post markdown is processed by MDEx. Inline styles in HTML elements may be stripped - use HTML attributes (`width`, `height`) instead of CSS properties (`aspect-ratio`, `z-index`) for embedded iframes.
