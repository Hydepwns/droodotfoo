```sh
DROO.FOO
========
```

👋Hi I'm Drew. co-founder at [axol.io](https://axol.io) & [xochi.fi](https://xochi.fi).

Building private execution infrastructure on Ethereum: solvers, sequencers, ZK compliance.
Complex Defense & Marine systems before that.

**[DROO.foo](https://DROO.foo)** | [x](https://x.com/DROOdotFOO) | [linkedin](https://linkedin.com/in/droodotfoo) | [telegram](https://t.me/DROOdotFOO)

## Other repos

- [**dotfiles**](https://github.com/DROOdotFOO/dotfiles) - chezmoi-managed cross-platform dotfiles, Synthwave84 theme, ~386ms shell startup
- [**agent-skills**](https://github.com/DROOdotFOO/agent-skills) - 47 Claude Code skills and 7 autonomous agents for polyglot dev, web3, ZK
- [**raxol**](https://github.com/DROOdotFOO/raxol) - OTP-native terminal framework for TUI apps and AI agents, x402/MPP payment rails
- [**mana**](https://github.com/axol-io/mana) - Ethereum client in Elixir

### DROO.foo Personal Site Stack

Elixir 1.17, Phoenix 1.8, LiveView, Tailwind v4, Monaspace fonts, PostgreSQL + pgvector. Rust NIFs for Web3 crypto and markdown parsing. ETS caching. Deployed on Fly.io.

```bash
# First Clone the repo then...
mix setup
./bin/dev  # loads secrets from 1Password
# Without 1Password:
mix phx.server   # localhost:4000
# Test
mix test
mix precommit  # compile + format + test
# Deploy
fly deploy
./scripts/deploy-cdn.sh
```

Rust NIFs compile from source in the Dockerfile. See [docs/guides/deployment.md](docs/guides/deployment.md).
