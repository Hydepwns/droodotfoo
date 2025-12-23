# Security Guide

This document covers security features, authentication, and rate limiting for droo.foo.

## Authentication

### OAuth 2.0 (Spotify)

Spotify integration uses OAuth 2.0 with PKCE:

- **CSRF Protection**: State parameter validation prevents cross-site request forgery
- **Token Storage**: Tokens stored in ETS cache (memory-only, not persisted)
- **Redirect URI**: Must be registered in Spotify Developer Dashboard
- **Scopes**: Minimum required scopes for playback and user data

### Bearer Token (Blog API)

The `/api/posts` endpoint uses bearer token authentication:

```bash
# Generate token
BLOG_API_TOKEN=$(mix phx.gen.secret)

# Set in production
fly secrets set BLOG_API_TOKEN="$BLOG_API_TOKEN"

# Use in requests
curl -X POST https://droo.foo/api/posts \
  -H "Authorization: Bearer $BLOG_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "# Title\n\nContent", "metadata": {"title": "Post"}}'
```

**Security Features**:
- Constant-time comparison prevents timing attacks
- No token bypass - endpoint returns 401 if token not configured
- Token required in production (optional in development)

## Rate Limiting

All rate limiters use ETS-based in-memory tracking with automatic cleanup.

### Blog API (`/api/posts`)

| Window | Limit | Purpose |
|--------|-------|---------|
| Per hour | 10 posts | Prevents spam bursts |
| Per day | 50 posts | Limits daily abuse |

### Contact Form

| Window | Limit |
|--------|-------|
| Per hour | 3 submissions |
| Per day | 10 submissions |

### Pattern Generation

| Window | Limit |
|--------|-------|
| Per minute | 30 requests |
| Per hour | 300 requests |

Prevents CPU exhaustion from excessive SVG pattern generation.

## Input Validation

### Content Size Limits

- **Blog posts**: 1MB maximum
- **Contact form**: Standard form size limits

### Path Traversal Prevention

Slug validation rejects dangerous patterns:

```elixir
# Rejected: ../../../etc/passwd, /absolute/path, ..\windows
# Allowed: my-blog-post, post-2025-01-18
```

### Slug Sanitization

- Only alphanumeric characters and hyphens allowed
- Leading/trailing hyphens stripped
- Multiple consecutive hyphens collapsed

### XSS Protection

- Phoenix HTML escaping by default
- Content Security Policy headers
- No inline scripts without nonce

## Production Security

### HTTPS Enforcement

```elixir
# config/prod.exs
config :droodotfoo, DroodotfooWeb.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto]]
```

### Secure Cookies

- `SECRET_KEY_BASE` required for session encryption
- Cookies marked as secure and HTTP-only
- SameSite attribute set to Lax

### Content Security Policy

CSP headers configured in `lib/droodotfoo_web/plugs/content_security_policy.ex`:

- `default-src 'self'`
- `script-src` with nonce for inline scripts
- `img-src` allows data URIs for SVG patterns
- `connect-src` for WebSocket and API connections

### HSTS

HTTP Strict Transport Security enabled via Fly.io and force_ssl configuration.

## Environment Variables

See [deployment.md](deployment.md) for complete environment variable reference.

**Required for security:**

| Variable | Purpose |
|----------|---------|
| `SECRET_KEY_BASE` | Session encryption (generate with `mix phx.gen.secret`) |
| `BLOG_API_TOKEN` | Blog API authentication |

## Security Checklist

Before deploying to production:

- [ ] Generate unique `SECRET_KEY_BASE`
- [ ] Generate unique `BLOG_API_TOKEN`
- [ ] Verify HTTPS enforcement
- [ ] Check CSP headers with browser dev tools
- [ ] Test rate limiting with multiple requests
- [ ] Verify OAuth redirect URIs are registered
