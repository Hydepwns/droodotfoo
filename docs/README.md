# droo.foo Documentation

Personal portfolio and blog built with Phoenix LiveView, featuring generative art patterns and monospace aesthetics.

## Quick Start

See [`CLAUDE.md`](../CLAUDE.md) in the project root for:
- Development commands (`mix setup`, `./bin/dev`)
- Architecture overview
- Code patterns and conventions
- Deployment basics

## Documentation

### Core Guides

- **[TODO.md](TODO.md)** - Active tasks and roadmap
- **[guides/deployment.md](guides/deployment.md)** - Production deployment to Fly.io
- **[guides/seo.md](guides/seo.md)** - SEO optimization (JSON-LD, performance)
- **[guides/assets.md](guides/assets.md)** - Images, fonts, and asset optimization

### Key Features

**Content System**
- File-based blog with markdown + YAML frontmatter
- Series support for multi-part posts
- Deterministic SVG pattern generation per post
- Syntax highlighting with MDEx

**Stack**
- Phoenix 1.8.1 + LiveView 1.1.12
- Elixir 1.17 on Erlang/OTP 27
- Bandit web server
- Tailwind CSS + Monaspace Argon font
- No database (file-based)

**Integrations**
- GitHub API (project stats with caching)
- Optional: Spotify, Web3 wallet
- 1Password CLI for secrets (local dev)
- Fly.io secrets (production)

## Project Structure

```
droodotfoo/
├── lib/
│   ├── droodotfoo/              # Core business logic
│   │   ├── content/             # Blog posts, patterns
│   │   ├── github/              # GitHub API integration
│   │   ├── projects.ex          # Portfolio projects
│   │   └── resume/              # Resume data management
│   └── droodotfoo_web/          # Web layer
│       ├── live/                # LiveView pages
│       ├── components/          # Reusable components
│       └── seo/                 # JSON-LD schemas
├── assets/
│   ├── css/                     # Tailwind + custom CSS
│   └── js/                      # TypeScript hooks
├── priv/
│   ├── posts/                   # Markdown blog posts
│   ├── resume.json              # Structured resume data
│   └── static/                  # Static assets
└── docs/                        # This directory
    ├── README.md                # You are here
    ├── TODO.md                  # Active tasks
    └── guides/                  # Detailed guides
```

## Development Workflow

```bash
# Setup
mix setup

# Local development (with 1Password secrets)
./bin/dev

# Tests
mix test
mix test test/path/to/specific_test.exs

# Code quality
mix format
mix compile --warnings-as-errors

# Pre-commit check
mix precommit
```

## Architecture Highlights

**Three-Layer Design:**
1. **Business Logic** (`Droodotfoo`) - GenServers, caching, data management
2. **Web Layer** (`DroodotfooWeb`) - LiveView pages, components
3. **Frontend** - Monospace-web aesthetic with terminal inspiration

**Key Patterns:**
- Functional architecture (pipes, pattern matching, immutability)
- GenServer supervision trees for state management
- File-based content (no database complexity)
- Real-time updates via LiveView
- Character-perfect monospace grid alignment

## Deployment

Production hosted on Fly.io with optional Cloudflare CDN:

```bash
# Deploy to production
fly deploy

# Set secrets
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
fly secrets set PHX_HOST="droo.foo"
```

See [guides/deployment.md](guides/deployment.md) for full instructions.

## Contributing

This is a personal project, but contributions are welcome:

1. Follow functional Elixir patterns (avoid imperative code)
2. No emojis in code (use ASCII art instead)
3. Maintain monospace aesthetic and 80-column width
4. Run `mix precommit` before submitting changes
5. Update tests for new features

## License

See LICENSE file in project root.
