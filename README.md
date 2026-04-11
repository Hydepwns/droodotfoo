```
DROO.FOO
========
Personal site. Monospace web. Phoenix LiveView.
```

**Live** -- [droo.foo](https://droo.foo)

Portfolio, blog, resume, and project showcase built on a character-perfect grid. Every element aligns to 1ch horizontal units and rem-based vertical rhythm. The site follows [Wickstrom's monospace web technique](https://wickstrom.tech/2024-09-26-how-i-built-the-monospace-web.html) -- no layout shift, predictable spacing, terminal aesthetic.

## What's here

- `/about` -- experience, stack, background
- `/now` -- current focus ([nownownow.com](https://nownownow.com/about) style)
- `/projects` -- GitHub integration, contribution graphs, project cards
- `/posts` -- file-based markdown blog with series support and generative SVG patterns
- `/resume` -- structured resume with PDF export
- `wiki.droo.foo` -- multi-source wiki aggregator with semantic search
- `git.droo.foo` -- multi-provider git browser (GitHub + Forgejo)

## Stack

Elixir 1.17, Phoenix 1.8, LiveView, Tailwind v4, Monaspace fonts, PostgreSQL + pgvector. Rust NIFs for Web3 crypto and markdown parsing. ETS caching throughout. Deployed on Fly.io.

## Run it

```bash
mix setup
./bin/dev        # loads secrets from 1Password
```

Or without 1Password:

```bash
mix phx.server   # localhost:4000
```

## Test

```bash
mix test                    # full suite
mix precommit               # compile + format + test
mix compile --warnings-as-errors
```

## Deploy

```bash
fly deploy                  # Phoenix app to Fly.io
./scripts/deploy-cdn.sh     # static assets to CDN
```

Rust NIFs compile from source in the Dockerfile. See [docs/guides/deployment.md](docs/guides/deployment.md) for env vars and setup.

## Docs

- [CLAUDE.md](CLAUDE.md) -- project architecture and patterns
- [AGENTS.md](AGENTS.md) -- Phoenix/Elixir conventions
- [docs/](docs/) -- deployment, security, SEO, assets guides
