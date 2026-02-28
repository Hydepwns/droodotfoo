# Git Subdomain Setup

> git.droo.foo - Unified repository browser for GitHub and Forgejo

## Overview

The git subdomain aggregates repositories from multiple sources:
- **GitHub** - Public repos from configured owner
- **Forgejo** - Self-hosted repos (Tailnet)

## Configuration

Environment variables (via 1Password or `.env`):

```bash
# GitHub (optional - works without token, but rate-limited)
GITHUB_OWNER=hydepwns
GITHUB_TOKEN=ghp_xxx

# Forgejo (requires token for API access)
FORGEJO_URL=http://mini-axol:3000
FORGEJO_OWNER=droo
FORGEJO_TOKEN=xxx
```

## Forgejo Token Setup

1. Open Forgejo: `http://mini-axol:3000/user/settings/applications`
2. Generate token with scope: `read:repository`
3. Add to 1Password vault as `FORGEJO_TOKEN`

## Routes

| Path | Description |
|------|-------------|
| `/` | Repository list (all sources) |
| `/:source/:owner/:repo` | Repo detail |
| `/:source/:owner/:repo/tree/:branch` | File browser |
| `/:source/:owner/:repo/blob/:branch/*path` | File viewer |
| `/:source/:owner/:repo/commits/:branch` | Commit history |

## Testing

```bash
# Start server
./bin/dev

# Test endpoints
curl http://git.localhost:4000/
curl http://git.localhost:4000/github/hydepwns/raxol
```

## Disabling Forgejo

To run GitHub-only, unset `FORGEJO_URL` or set it empty:

```bash
FORGEJO_URL= ./bin/dev
```
