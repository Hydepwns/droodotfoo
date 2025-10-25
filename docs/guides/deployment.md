# Deployment Guide

Production deployment to Fly.io with optional CDN.

> **Note:** See [`CLAUDE.md`](../../CLAUDE.md) for local development setup.

## Prerequisites

- Fly.io account (signup at fly.io)
- Fly CLI installed (`brew install flyctl`)
- Git repository
- 1Password CLI (for local secrets)

## Initial Setup

### 1. Install Fly CLI

```bash
brew install flyctl
fly auth login
```

### 2. Create Fly App

```bash
# From project root
fly launch

# Follow prompts:
# - App name: droodotfoo (or your choice)
# - Region: Choose closest to your users
# - PostgreSQL: No (we don't use a database)
# - Redis: No
```

This creates `fly.toml` configuration.

### 3. Set Secrets

```bash
# Required secrets
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
fly secrets set PHX_HOST="your-app.fly.dev"

# Optional: GitHub token (for higher API rate limits)
fly secrets set GITHUB_TOKEN="ghp_your_token_here"

# Optional: Spotify integration
fly secrets set SPOTIFY_CLIENT_ID="your_client_id"
fly secrets set SPOTIFY_CLIENT_SECRET="your_client_secret"

# Optional: CDN
fly secrets set CDN_HOST="your-project.pages.dev"
```

### 4. Deploy

```bash
fly deploy
```

## Configuration

### fly.toml

```toml
app = "droodotfoo"
primary_region = "sea"

[build]

[env]
  PHX_SERVER = "true"

[http_service]
  internal_port = 4000
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0
  processes = ["app"]

[[vm]]
  cpu_kind = "shared"
  cpus = 1
  memory_mb = 256
```

### Custom Domain

```bash
# Add custom domain
fly certs add droo.foo

# Check certificate status
fly certs show droo.foo

# DNS configuration (add these records):
# A    @     <fly-ip-address>
# AAAA @     <fly-ipv6-address>
```

## CDN Setup (Optional)

### Cloudflare Pages

**1. Build Static Assets Locally**
```bash
mix assets.deploy
```

**2. Deploy to Cloudflare Pages**
```bash
# Install Wrangler
npm install -g wrangler

# Deploy
cd priv/static
wrangler pages publish . --project-name=droodotfoo
```

**3. Configure Fly.io**
```bash
fly secrets set CDN_HOST="droodotfoo.pages.dev"
```

**Benefits:**
- Edge caching worldwide
- Automatic asset optimization
- DDoS protection
- No bandwidth charges from Fly.io

## Monitoring

### Health Checks

Fly.io automatically monitors your app:
```toml
# In fly.toml
[[services.http_checks]]
  interval = 10000
  grace_period = "5s"
  method = "get"
  path = "/"
  protocol = "http"
  timeout = 2000
```

### Logs

```bash
# Stream logs
fly logs

# Recent logs
fly logs --tail=100
```

### Metrics

```bash
# View app status
fly status

# View metrics
fly dashboard
```

## Scaling

### Vertical Scaling
```bash
# Increase memory
fly scale memory 512

# Increase CPUs
fly scale count 2
```

### Horizontal Scaling
```bash
# Add machines in multiple regions
fly scale count 2 --region sea,ord
```

### Auto-scaling
```toml
# In fly.toml
[http_service]
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1
  max_machines_running = 3
```

## Troubleshooting

### Common Issues

**1. App Won't Start**
```bash
# Check logs
fly logs

# SSH into machine
fly ssh console

# Check secrets
fly secrets list
```

**2. 502 Bad Gateway**
- Check if app is running: `fly status`
- Verify `PHX_SERVER=true` in environment
- Check internal port matches (4000)

**3. Slow Deployment**
```bash
# Clear build cache
fly deploy --no-cache
```

**4. Certificate Issues**
```bash
# Renew certificate
fly certs renew droo.foo

# Check DNS propagation
dig droo.foo
```

## Rollback

```bash
# List releases
fly releases

# Rollback to previous
fly releases rollback
```

## CI/CD (Optional)

### GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Fly.io

on:
  push:
    branches: [main]

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

**Setup:**
```bash
# Get API token
fly auth token

# Add to GitHub secrets:
# Settings → Secrets → Actions → New secret
# Name: FLY_API_TOKEN
# Value: <your-token>
```

## Cost Optimization

**Free Tier:**
- 3 shared-cpu-1x VMs (256MB)
- 160GB bandwidth/month
- Auto-stop machines when idle

**Tips:**
- Use `auto_stop_machines = true` (stops when idle)
- Minimize memory (256MB sufficient)
- Use CDN for static assets
- Cache aggressively

## Security

**Best Practices:**
- Use secrets for all sensitive data
- Enable force_https
- Keep dependencies updated
- Monitor security advisories
- Rotate secrets periodically

**Headers:**
```elixir
# In content_security_policy.ex
plug :put_secure_browser_headers, %{
  "content-security-policy" => "...",
  "x-frame-options" => "DENY",
  "x-content-type-options" => "nosniff"
}
```

## Backup Strategy

**No database = simpler backups:**
- Content in Git (`priv/posts/*.md`)
- Resume data in Git (`priv/resume.json`)
- Configuration in Git
- Secrets in 1Password + Fly.io Secrets
- No runtime state to backup

**Disaster Recovery:**
```bash
# Redeploy from scratch
fly launch
fly secrets set ...  # Restore secrets
fly deploy           # Deploy from Git
```

## Resources

- [Fly.io Docs](https://fly.io/docs/)
- [Phoenix on Fly.io](https://fly.io/docs/elixir/)
- [Fly.io Community](https://community.fly.io/)
