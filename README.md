```
DROO.FOO
========
```

I'm Drew. Protocol Director/BDFL at [axol.io](https://axol.io) and [xochi.fi](https://xochi.fi). Building private execution infrastructure on Ethereum: solvers, sequencers, ZK compliance. Defense systems before that.

This is my personal site. Monospace web, Phoenix LiveView, character-perfect grid.

**[droo.foo](https://droo.foo)** | [github](https://github.com/DROOdotFOO) | [x](https://x.com/DROOdotFOO) | [linkedin](https://linkedin.com/in/droodotfoo) | [telegram](https://t.me/DROOdotFOO)

## Pages

- `/about` - experience, stack, background
- `/now` - current focus ([nownownow.com](https://nownownow.com/about) style)
- `/projects` - GitHub integration, contribution graphs
- `/posts` - markdown blog with series support and generative SVG patterns
- `/resume` - structured resume with PDF export
- `wiki.droo.foo` - multi-source wiki aggregator with semantic search
- `git.droo.foo` - multi-provider git browser (GitHub + Forgejo)

## Other repos

- [**dotfiles**](https://github.com/DROOdotFOO/dotfiles) - chezmoi-managed cross-platform dotfiles, Synthwave84 theme, ~386ms shell startup
- [**agent-skills**](https://github.com/DROOdotFOO/agent-skills) - 47 Claude Code skills and 7 autonomous agents for polyglot dev, web3, ZK
- [**raxol**](https://github.com/DROOdotFOO/raxol) - OTP-native terminal framework for TUI apps and AI agents, x402/MPP payment rails
- [**mana**](https://github.com/mana-ethereum/mana) - Ethereum client in Elixir (contributor)

## Stack

Elixir 1.17, Phoenix 1.8, LiveView, Tailwind v4, Monaspace fonts, PostgreSQL + pgvector. Rust NIFs for Web3 crypto and markdown parsing. ETS caching. Deployed on Fly.io.

## Run

```bash
mix setup
./bin/dev        # loads secrets from 1Password
```

Without 1Password:

```bash
mix phx.server   # localhost:4000
```

## Test

```bash
mix test
mix precommit    # compile + format + test
```

## Deploy

```bash
fly deploy
./scripts/deploy-cdn.sh
```

Rust NIFs compile from source in the Dockerfile. See [docs/guides/deployment.md](docs/guides/deployment.md).

## Docs

- [CLAUDE.md](CLAUDE.md) - project architecture and patterns
- [AGENTS.md](AGENTS.md) - Phoenix/Elixir conventions
- [docs/](docs/) - deployment, security, SEO, assets guides
