# TODO - droo.foo

> Personal portfolio and blog with Phoenix LiveView

## Current Status

**Last Updated**: Dec 23, 2025
**Version**: v1.0.0
**Test Coverage**: 41.2% (963 tests passing, 335 skipped)
**Focus**: Blog system with generative art patterns and monospace web design

---

## Quick Commands

```bash
mix phx.server              # Start development server
./bin/dev                   # Start with 1Password secrets
mix test                    # Run test suite
mix test --exclude flaky    # Stable tests only
mix docs                    # Generate documentation
mix precommit               # Format, compile, test
```

---

## Active Priorities

### High
| Area | Task |
|------|------|
| Blog | Add more blog posts, create tutorial series, write about Elixir/Phoenix |
| Projects | Add descriptions, link live demos, add screenshots |
| Performance | Monitor Lighthouse (90+), optimize SVG patterns, CSS bundle |
| DevOps | GitHub Actions CI/CD (tests on PR, deploy on merge, coverage) |

### Medium
| Area | Task |
|------|------|
| Blog | Image optimization, code copy button, TOC, reading time |
| Performance | Service worker, PWA manifest, progressive images |
| DevOps | Error tracking (Sentry), uptime/performance monitoring |

### Low
| Area | Task |
|------|------|
| Blog | Tag filtering, search, related posts, excerpts |
| Projects | Tech filter, contribution timeline, detail pages |
| Performance | Dark mode, font loading, JS bundle size |
| DevOps | Post backup, blue/green deploys, staging env |
| Code | Dependency updates, remove unused code, 50%+ coverage, docs |

---

## Completed

| Date | Category | Summary |
|------|----------|---------|
| Dec 2025 | Security | OAuth token encryption, state expiry, error sanitization, body limits |
| Oct 2025 | Code Quality | Credo setup, 64 issues fixed, test cleanup |
| Oct 2025 | Design | Monospace web (Wickstrom technique), double-line HRs, grid alignment |
| Oct 2025 | Blog | Series navigation, reading progress, OpenGraph metadata |
| Oct 2025 | Patterns | Modular generator, 8 styles with animations, pattern gallery |
| Oct 2025 | Content | Now page, sitemap, RSS feed, contact form, projects page |

---

## Ideas (Someday/Maybe)

- Newsletter, comments (Giscus), webmentions, post drafts
- LiveView Native mobile app, real-time collaboration
- Privacy analytics (Plausible), reading stats, popular posts dashboard

---

## Archived Features

| Feature | Description | Location |
|---------|-------------|----------|
| Terminal | Raxol framework, vim navigation, 10 plugins, 40+ commands | `.unused_modules_backup/` |
| Web3 | MetaMask, ENS, NFT viewing, IPFS | Code exists, not routed |
| Fileverse P2P | Portal file sharing, E2E encryption, dDocs/dSheets | Code exists, not routed |

---

## Resources

| Doc | Purpose |
|-----|---------|
| `README.md` | Project overview and quick start |
| `CLAUDE.md` | Development commands, architecture, patterns |
| `docs/guides/*.md` | Deployment, assets, SEO guides |
| `mix docs` | Generate ExDoc API documentation |

**Live:** [droo.foo](https://droo.foo) | **Deploy:** Fly.io | **CDN:** Cloudflare Pages
