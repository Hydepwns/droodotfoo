# Deployment Guide

This guide provides comprehensive instructions for building and deploying the droo.foo terminal application.

## Prerequisites

### System Requirements
- **Elixir ~> 1.17** with Erlang/OTP 26+
- **Node.js 18+** for asset compilation
- **Git** for deployment via Fly.io
- **1Password CLI** (optional, for local development secrets)

### Required Accounts
- **Fly.io** account for production hosting
- **Spotify Developer** account (optional, for Spotify features)
- **Cloudflare** account (optional, for CDN)

## Local Development Setup

### 1. Install Dependencies

```bash
# Clone the repository
git clone https://github.com/hydepwns/droodotfoo.git
cd droodotfoo

# Install Elixir dependencies
mix deps.get

# Install Node.js dependencies and build assets
mix setup
```

### 2. Configure Secrets (1Password CLI)

The project uses 1Password CLI for secure local development secrets:

```bash
# Install 1Password CLI
brew install --cask 1password-cli

# Sign in
op signin

# Create secrets item in 1Password
op item create --category=login --title="droodotfoo-dev" \
  SPOTIFY_CLIENT_ID="your_client_id" \
  SPOTIFY_CLIENT_SECRET="your_client_secret" \
  SECRET_KEY_BASE="$(mix phx.gen.secret)"

# Run with secrets loaded
./bin/dev
```

Alternatively, use environment variables:

```bash
export SPOTIFY_CLIENT_ID="your_client_id"
export SPOTIFY_CLIENT_SECRET="your_client_secret"
export SECRET_KEY_BASE="$(mix phx.gen.secret)"

mix phx.server
```

### 3. Start Development Server

```bash
# With 1Password secrets (recommended)
./bin/dev

# Or standard Phoenix server
mix phx.server

# With interactive shell
iex -S mix phx.server
```

Visit: http://localhost:4000

## Production Deployment (Fly.io)

### 1. Initial Setup

```bash
# Install Fly CLI
brew install flyctl

# Login to Fly.io
fly auth login

# Initialize app (if not already configured)
fly launch --no-deploy
```

### 2. Configure Production Secrets

```bash
# Generate and set secret key
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)

# Set Phoenix host
fly secrets set PHX_HOST="your-app.fly.dev"

# Set Spotify credentials (optional)
fly secrets set SPOTIFY_CLIENT_ID="your_client_id"
fly secrets set SPOTIFY_CLIENT_SECRET="your_client_secret"

# Set CDN host (optional, for Cloudflare Pages)
fly secrets set CDN_HOST="your-project.pages.dev"

# Verify secrets
fly secrets list
```

### 3. Deploy to Production

```bash
# Deploy application
fly deploy

# Check deployment status
fly status

# View logs
fly logs

# Open app in browser
fly open
```

### 4. Scale Application

```bash
# Scale to multiple instances
fly scale count 2

# Scale VM size
fly scale vm shared-cpu-1x

# Check current scaling
fly scale show
```

## Asset Compilation

### Development Assets

```bash
# Build assets for development
mix assets.build

# Watch assets (auto-rebuild on changes)
mix assets.build --watch
```

### Production Assets

```bash
# Build and minify production assets
MIX_ENV=prod mix assets.deploy

# This runs:
# 1. Tailwind CSS compilation (minified)
# 2. esbuild JavaScript compilation (minified)
# 3. Astro component copying
# 4. Phoenix digest (cache busting)
```

## CDN Configuration (Cloudflare Pages)

### 1. Deploy Static Assets to Cloudflare

```bash
# Build production assets
MIX_ENV=prod mix assets.deploy

# Deploy to Cloudflare Pages
cd priv/static
wrangler pages publish . --project-name=droodotfoo-assets
```

### 2. Configure CDN in Fly.io

```bash
# Set CDN host
fly secrets set CDN_HOST="droodotfoo-assets.pages.dev"
```

The endpoint will automatically serve static assets from the CDN:

```elixir
# config/runtime.exs
static_url: [host: System.get_env("CDN_HOST"), scheme: "https"]
```

## Database-Free Architecture

This application is **database-free** by design:

- No Ecto dependency
- No database migrations
- All state managed in GenServers and LiveView sessions
- File storage via IPFS (Fileverse integration)
- User data never persisted on server

This simplifies deployment and enhances privacy.

## Environment Variables Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SECRET_KEY_BASE` | Phoenix session encryption key | Generate with `mix phx.gen.secret` |
| `PHX_HOST` | Production domain name | `droo.fly.dev` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SPOTIFY_CLIENT_ID` | Spotify OAuth client ID | None (Spotify features disabled) |
| `SPOTIFY_CLIENT_SECRET` | Spotify OAuth secret | None (Spotify features disabled) |
| `CDN_HOST` | Cloudflare Pages domain for static assets | Serve from Fly.io |
| `PORT` | HTTP server port | `4000` |

## Monitoring & Observability

### Telemetry Metrics

The application includes built-in telemetry:

```elixir
# Available metrics
- phoenix.endpoint.start
- phoenix.endpoint.stop
- phoenix.router_dispatch.start
- phoenix.router_dispatch.stop
- phoenix.live_view.mount
- phoenix.live_view.handle_event
```

### Log Aggregation

View logs in production:

```bash
# Real-time logs
fly logs

# Logs from specific instance
fly logs -i 01234567890abc

# Search logs
fly logs --search "error"
```

### Health Checks

Fly.io automatically performs HTTP health checks:

```toml
# fly.toml
[http_service]
  internal_port = 4000
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0

[[http_service.checks]]
  grace_period = "10s"
  interval = "30s"
  method = "GET"
  timeout = "5s"
  path = "/"
```

## Performance Optimization

### Production Configuration

```elixir
# config/prod.exs
config :droodotfoo, DroodotfooWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true

# Enable HTTP/2
config :bandit,
  http_2_options: [
    enabled: true
  ]
```

### Asset Optimization

- **Tailwind CSS purging** - Removes unused CSS classes
- **esbuild minification** - Minifies JavaScript bundles
- **Phoenix digests** - Cache busting with hashed filenames
- **Gzip compression** - Automatic via Bandit

### LiveView Optimizations

- **Diff-based updates** - Only changed assigns sent to client
- **Binary protocol** - Efficient WebSocket communication
- **Session compression** - Reduced cookie size

## Troubleshooting

### Common Issues

**1. Assets not loading**
```bash
# Rebuild assets
MIX_ENV=prod mix assets.deploy

# Clear asset cache
rm -rf _build/prod
rm -rf priv/static/cache_manifest.json
```

**2. Secret key errors**
```bash
# Generate new secret key
mix phx.gen.secret

# Set in Fly.io
fly secrets set SECRET_KEY_BASE="<generated_key>"
```

**3. Port binding errors**
```bash
# Kill process using port 4000
lsof -ti:4000 | xargs kill -9
```

**4. Fly deployment failures**
```bash
# Check Fly.io status
fly status

# View detailed logs
fly logs --verbose

# SSH into instance
fly ssh console
```

### Debug Mode

Enable debug logging in production (temporary):

```bash
fly secrets set LOG_LEVEL=debug
fly deploy
```

## Rollback Procedure

```bash
# List previous releases
fly releases

# Rollback to previous version
fly releases rollback

# Rollback to specific version
fly releases rollback --version 42
```

## Backup & Recovery

Since this is a database-free application:

- **Code backups** - Handled by Git
- **User data** - Stored on IPFS (Fileverse), not on server
- **Configuration** - Fly.io secrets (backup secrets manually)

```bash
# Backup Fly.io secrets
fly secrets list > secrets_backup.txt
```

## Security Considerations

### HTTPS Enforcement

Fly.io automatically provides HTTPS certificates:

```toml
# fly.toml
[http_service]
  force_https = true
```

### Secret Management

- Never commit secrets to Git
- Use Fly.io secrets for production
- Use 1Password CLI for local development
- Rotate secrets regularly

### Rate Limiting

Contact form includes built-in rate limiting:
- 5 submissions per hour per IP
- Configurable in `lib/droodotfoo/contact/rate_limiter.ex`

## CI/CD Integration

### GitHub Actions (Example)

```yaml
# .github/workflows/deploy.yml
name: Deploy to Fly.io

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

## Post-Deployment Verification

### 1. Smoke Tests

```bash
# Check HTTP status
curl -I https://your-app.fly.dev

# Check terminal loads
curl https://your-app.fly.dev | grep "droo.foo"

# Check WebSocket connection
wscat -c wss://your-app.fly.dev/live/websocket
```

### 2. Feature Verification

- Terminal renders correctly
- Keyboard navigation works
- Spotify integration (if configured)
- Web3 wallet connection
- Mobile responsive layout

### 3. Performance Checks

```bash
# Check response times
curl -w "@curl-format.txt" -o /dev/null -s https://your-app.fly.dev

# Monitor memory usage
fly ssh console -C "ps aux"
```

## Support & Documentation

- **Architecture:** [architecture.md](architecture.md)
- **Development:** [DEVELOPMENT.md](DEVELOPMENT.md)
- **API Reference:** `mix docs` → `doc/index.html`
- **Issue Tracker:** GitHub Issues

## Quick Reference

```bash
# Development
mix setup              # Install deps + build assets
./bin/dev              # Start with 1Password secrets
mix phx.server         # Start Phoenix server

# Testing
mix test               # Run tests
mix precommit          # Full check (compile, format, test)

# Production
fly deploy             # Deploy to Fly.io
fly logs               # View logs
fly ssh console        # SSH into instance
fly scale count 2      # Scale to 2 instances

# Assets
mix assets.build       # Build development assets
mix assets.deploy      # Build production assets
```
