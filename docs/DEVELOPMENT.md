# Development Guide - droo.foo Terminal

Technical documentation for developers working on this project.

---

## Table of Contents

1. [Architecture](#architecture)
2. [GitHub Integration](#github-integration)
3. [Spotify Integration](#spotify-integration)
4. [Testing Best Practices](#testing-best-practices)
5. [Performance Optimizations](#performance-optimizations)
6. [Security](#security)

---

## Architecture

### Core Design Patterns

**1. Reducer Pattern (TEA/Elm)**
- Single state atom in GenServer
- Pure functions for state transitions
- Predictable, testable updates

**2. GenServer Supervision Tree**
```
Application
├── RaxolApp (main terminal orchestrator)
├── PerformanceMonitor (metrics collection)
├── PluginSystem.Manager (plugin lifecycle)
└── TerminalBridge (HTML generation)
```

**3. LiveView Real-time Architecture**
- 60fps terminal updates via WebSocket
- Automatic reconnection with exponential backoff
- Input rate limiting (token bucket algorithm)
- Adaptive refresh based on performance metrics

**4. Plugin System**
- Behavior-based plugin architecture
- Lifecycle hooks: `init`, `handle_input`, `render`, `cleanup`
- Isolated plugin state with shared terminal context

### Key Modules

**Core**
- `Droodotfoo.RaxolApp` - Main orchestrator, handles keyboard input, manages rendering
- `Droodotfoo.Raxol.State` - State management with reducer pattern
- `Droodotfoo.Raxol.Renderer` - ASCII buffer rendering
- `Droodotfoo.Raxol.Navigation` - Section navigation logic
- `DroodotfooWeb.DroodotfooLive` - LiveView module, WebSocket handler

**Performance**
- `Droodotfoo.TerminalBridge` - HTML generation with line-based patching
- `Droodotfoo.AdaptiveRefresh` - FPS adaptation system
- `Droodotfoo.InputRateLimiter` - Token bucket rate limiting
- `Droodotfoo.PerformanceMonitor` - Metrics collection (render time, memory, requests)

**Plugins**
- `Droodotfoo.PluginSystem.Manager` - Plugin registration and lifecycle
- `Droodotfoo.Plugins.SnakeGame` - Snake game implementation
- `Droodotfoo.Plugins.Calculator` - RPN calculator
- `Droodotfoo.Plugins.MatrixRain` - Matrix rain animation
- `Droodotfoo.Plugins.Spotify` - Music player integration

### File Structure

```
lib/droodotfoo/
├── raxol_app.ex              # Main GenServer
├── raxol/
│   ├── state.ex              # State management
│   ├── renderer.ex           # Rendering logic
│   ├── navigation.ex         # Menu navigation
│   └── command.ex            # Command execution
├── terminal/
│   ├── commands.ex           # Terminal command implementations
│   ├── command_parser.ex     # Command parsing
│   └── file_system.ex        # Virtual file system
├── github/
│   └── client.ex             # GitHub API client
├── plugin_system/
│   ├── manager.ex            # Plugin management
│   └── plugin.ex             # Plugin behaviour
└── plugins/
    ├── snake_game.ex
    ├── calculator.ex
    ├── matrix_rain.ex
    └── spotify.ex

lib/droodotfoo_web/
└── live/
    └── droodotfoo_live.ex    # LiveView module

assets/
├── css/
│   ├── app.css               # Main styles
│   ├── themes.css            # Color themes
│   ├── monospace.css         # Typography
│   └── terminal_grid.css     # Grid system
└── js/
    ├── app.ts                # Main JavaScript
    ├── hooks.ts              # LiveView hooks
    └── hooks/
        ├── terminal.js       # Terminal hooks
        └── stl_viewer.ts     # 3D viewer (Three.js)
```

---

## GitHub Integration

### Overview

The `projects` command dynamically fetches repositories from your GitHub profile with automatic caching and smart fallbacks.

### Features

- **Automatic Updates**: Syncs every 15 minutes
- **Smart Fallback**: Uses REST API without token, GraphQL with token
- **Error Handling**: Falls back to static list if GitHub is unavailable
- **ETS Caching**: In-memory cache with 15-minute TTL

### Implementation

**File**: `lib/droodotfoo/github/client.ex`

**Key Functions**:
- `fetch_pinned_repos/1` - Main entry point with caching
- `fetch_from_graphql/2` - GraphQL API (requires token, gets true pinned repos)
- `fetch_from_rest_api/1` - REST API (no token, gets top 6 by stars)
- `format_repos/1` - Terminal-friendly formatting

### API Endpoints

**GraphQL API** (with GITHUB_TOKEN):
```graphql
{
  user(login: "hydepwns") {
    pinnedItems(first: 6, types: REPOSITORY) {
      nodes {
        name, description, url
        stargazerCount, forkCount
        primaryLanguage { name, color }
        repositoryTopics { topic { name } }
      }
    }
  }
}
```

**REST API** (without token):
```
GET https://api.github.com/users/hydepwns/repos?sort=stars&per_page=6
```

### Caching Strategy

- **Cache Key**: GitHub username
- **TTL**: 15 minutes
- **Storage**: ETS table (`:github_cache`)
- **Concurrency**: `read_concurrency: true` for performance

### Rate Limits

- **Without token**: 60 requests/hour → cached = 4 requests/hour ✅
- **With token**: 5,000 requests/hour → plenty of headroom ✅

### Configuration

**Optional GitHub Token** (for true pinned repos):
```bash
# Create at: https://github.com/settings/tokens
# Scope: public_repo (read-only)

export GITHUB_TOKEN="ghp_your_token_here"
```

**Benefits with token**:
- Fetches actual pinned repositories (not just top-starred)
- Higher rate limit (5,000/hour vs 60/hour)
- Repository topics included
- Language color codes

### Error Handling

Graceful degradation with fallback:
```
Failed to fetch GitHub projects: [error]

Fallback projects:
- droo.foo (Elixir/Phoenix)
- axol-framework (Rust)
- terminal-ui (Elixir)
```

### Performance

- **First request**: 200-500ms (network + parse)
- **Cached request**: <1ms (ETS lookup)
- **Memory**: ~2-3KB per cached user

---

## Spotify Integration

### Architecture Overview

Dual-mode integration:
1. **Terminal Plugin** - ASCII art, terminal UI, keyboard controls
2. **Web Component** - Standalone widget with Spotify Web Playback SDK

Both modes share backend infrastructure.

### Architecture Diagram

```
Frontend Layer
├── Terminal Plugin (ASCII renderer, commands)
└── Web Component (TypeScript, Shadow DOM)
         │
Phoenix LiveView (SpotifyLive)
         │
Backend Services
├── Spotify.Manager (GenServer)
│   ├── OAuth2 Flow
│   ├── Token Management
│   ├── API Rate Limiting
│   └── Caching Layer
├── Spotify.API (HTTP client)
└── Spotify.Cache (ETS)
         │
External Services
├── Spotify Web API
└── Spotify Web Playback SDK
```

### Core Components

**Backend Services**:
- `Droodotfoo.Spotify.Manager` - GenServer managing auth, playback state, sessions
- `Droodotfoo.Spotify.API` - HTTP client for Spotify Web API
- `Droodotfoo.Spotify.Cache` - ETS caching (playlists, tracks, album art)
- `Droodotfoo.Spotify.Auth` - OAuth2 implementation

**Terminal Plugin**:
- `Droodotfoo.Plugins.Spotify` - Plugin implementation
- `Droodotfoo.Spotify.AsciiArt` - Album artwork → ASCII converter

**Web Component**:
- `assets/js/components/SpotifyWidget.ts` - Web component
- `assets/js/hooks/spotify.ts` - LiveView hooks
- `DroodotfooWeb.SpotifyLive` - LiveView module

### Data Flow

**Authentication**:
1. User runs `spotify auth` command
2. Generate OAuth2 authorization URL
3. Open browser for consent
4. Handle callback with authorization code
5. Exchange for access/refresh tokens
6. Store tokens securely
7. Initialize player session

**Playback**:
1. User selects track/playlist
2. Component sends request to LiveView
3. LiveView → Spotify.Manager
4. Manager checks cache → API if needed
5. Initiate playback via Web Playback SDK
6. Update UI, broadcast state to all clients

### Caching Strategy

- **Playlists**: 1 hour TTL
- **Tracks**: 24 hours TTL
- **Search results**: 5 minutes TTL
- **Album art ASCII**: 7 days TTL

### Security

**Token Storage**:
- Encrypt refresh tokens at rest
- Phoenix session for access tokens
- Token rotation on expiry

**API Keys**:
- Environment variables only
- Never expose client secret
- Server-side proxy for all API calls

**Rate Limiting**:
- Exponential backoff
- Track usage per user
- Aggressive caching

### Configuration

```bash
# Required for Spotify integration
export SPOTIFY_CLIENT_ID="your_client_id"
export SPOTIFY_CLIENT_SECRET="your_client_secret"
export SPOTIFY_REDIRECT_URI="https://yourapp.com/auth/spotify/callback"
```

### Implementation Status

✅ Completed:
- Backend services (Auth, API, Manager, Cache)
- Terminal plugin (navigation, controls, search)
- Web component (TypeScript, Shadow DOM)
- LiveView integration

🚧 Pending:
- Production OAuth callback
- Album art ASCII conversion
- Collaborative playlists

---

## Testing Best Practices

### Key Learnings

**Test Isolation**:
1. Never stop application-supervised GenServers in tests
2. Use `start_supervised` or check `Process.whereis` before starting
3. Use `async: false` for tests with shared GenServer state
4. Implement `reset_state/0` functions for stateful services

**State Management**:
- Create `StateResetHelper` module to reset shared state between tests
- Each test starts with clean, known state
- State reset is idempotent (safe to call multiple times)

**Performance Expectations**:
- 10k ops/sec is reasonable for Elixir
- 100k ops/sec requires optimization
- Adjust thresholds based on actual measurements

**Test Interference Indicators**:
- Tests pass individually but fail in suite
- Different failures with different seeds
- Non-deterministic assertion errors

### Test Infrastructure

**Current Stats**:
- 390 total tests (100% pass rate)
- Core modules: 129 tests
- Plugin unit tests: 85 tests
- Property tests: 9 properties
- Performance tests: AdaptiveRefresh, InputDebouncer, PerformanceMonitor
- Load tests: 100+ concurrent connections, 1000+ key sequences
- Execution time: <5 seconds for full suite

**Testing Approach**:
- Real implementations only (no mocks)
- Property-based testing for invariants
- Integration tests for LiveView interactions
- Load tests for concurrency and performance

### Example: StateResetHelper

```elixir
defmodule Droodotfoo.Test.StateResetHelper do
  def reset_all do
    reset_raxol_app()
    reset_plugin_manager()
    reset_performance_monitor()
  end

  defp reset_raxol_app do
    if Process.whereis(Droodotfoo.RaxolApp) do
      Droodotfoo.RaxolApp.reset_state()
    end
  end
end
```

### Common Pitfalls

❌ **Don't**:
```elixir
# Stops GenServer (won't restart!)
test "something" do
  GenServer.stop(MyApp.Manager)
  start_supervised(MyApp.Manager)
end
```

✅ **Do**:
```elixir
# Resets state instead
test "something" do
  MyApp.Manager.reset_state()
  # test continues...
end
```

---

## Performance Optimizations

### Current Metrics

- **Render time**: 2-3ms average
- **FPS**: 60fps sustained
- **Memory**: ~40-50MB
- **Request rate**: ~150-200 req/s
- **WebSocket latency**: ~10-15ms

### Optimization Techniques

**1. HTML Patching**
- Line-based diffing
- Only send changed lines to client
- Reduces payload by 80-95%

**2. Style Class Caching**
- ETS cache for common style combinations
- Pre-generate frequently used classes
- Avoid redundant string concatenation

**3. Adaptive Refresh**
- Monitor frame time
- Throttle updates when slow
- Maintain 60fps target

**4. Input Rate Limiting**
- Token bucket algorithm
- 100 events/second limit
- Prevents event flooding

**5. ETS Caching**
- GitHub repos: 15 minutes
- Spotify playlists: 1 hour
- Performance metrics: 1 minute

### Future Optimizations

- Differential rendering (only changed cells)
- Web Workers for heavy computation
- Binary protocols for WebSocket
- CDN for static assets

---

## Security

### Best Practices

**Environment Variables**:
- All secrets in env vars
- Never commit to git
- Use 1Password CLI for local dev
- Fly.io secrets for production

**API Tokens**:
- Server-side only (never exposed to client)
- Encrypted at rest
- Automatic rotation
- Scoped permissions (read-only when possible)

**Rate Limiting**:
- Input rate limiting (100 events/sec)
- API rate limiting (exponential backoff)
- WebSocket connection limits

**Caching**:
- No sensitive data in ETS cache
- Public data only
- TTL-based invalidation

### Security Checklist

- ✅ Secrets in environment variables
- ✅ GitHub token optional (degrades gracefully)
- ✅ Spotify tokens encrypted
- ✅ All HTTP requests over HTTPS
- ✅ Input validation on all commands
- ✅ Rate limiting on user input
- ✅ No sensitive data logged
- ✅ CORS configured for APIs

---

## Development Workflow

### Quick Commands

```bash
# Development
mix phx.server              # Start server (port 4000)
./bin/dev                   # Start with 1Password secrets
iex -S mix phx.server       # Interactive shell

# Testing
mix test                    # Run all tests (390 passing)
mix test --failed           # Run previously failed tests
mix test path/to/test.exs   # Run specific test
mix test --seed 123         # Run with specific seed

# Code Quality
mix format                  # Format code
mix compile --warnings-as-errors
mix precommit              # Full check (compile, format, test)

# Debugging
MIX_ENV=test iex -S mix    # Interactive test environment
mix run -e "Code.here()"   # Run one-off code
```

### Git Workflow

```bash
# Branch naming
feature/short-description
bugfix/issue-description
refactor/component-name

# Commit messages
type(scope): brief description

Types: feat, fix, refactor, test, docs, style, perf
Scope: component name (e.g., github, spotify, raxol)

Examples:
feat(github): add dynamic project fetching
fix(spotify): handle token expiry gracefully
refactor(raxol): extract renderer to separate module
```

### Debugging Tips

**LiveView**:
- Use `IO.inspect/2` with labels
- Check browser console for JS errors
- Monitor WebSocket frames in devtools
- Use Phoenix LiveDashboard

**GenServers**:
- `:sys.get_state(pid)` - Inspect current state
- `:sys.statistics(pid, :get)` - Get stats
- `Process.info(pid)` - Process details

**Performance**:
- Use `Droodotfoo.PerformanceMonitor` for metrics
- Check memory with `:observer.start()`
- Profile with `:fprof` or `:eprof`

---

## References

### External Documentation

- [Phoenix Framework](https://hexdocs.pm/phoenix)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Raxol Terminal UI](https://hexdocs.pm/raxol)
- [Spotify Web API](https://developer.spotify.com/documentation/web-api)
- [GitHub API](https://docs.github.com/en/rest)
- [Three.js](https://threejs.org/docs/)

### Internal Documentation

- **CLAUDE.md** - AI assistant instructions
- **README.md** - Setup and deployment
- **TODO.md** - Current work and roadmap
- **AGENTS.md** - Phoenix/Elixir guidelines

---

**Last Updated**: October 4, 2025
**Maintained by**: Drew (@Hydepwns)
