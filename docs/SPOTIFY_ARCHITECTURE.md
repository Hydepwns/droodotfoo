# Spotify Plugin Architecture

## Overview
The Spotify integration provides two distinct modes:
1. **Terminal Plugin** - Interactive music experience within the terminal
2. **Web Component** - Standalone widget for non-terminal pages

Both modes share the same backend infrastructure while providing different user experiences.

## Architecture Diagram

```bash
┌────────────────────────────────────────────────────────────┐
│                      Frontend Layer                        │
├──────────────────────────┬─────────────────────────────────┤
│    Terminal Plugin       │       Web Component             │
│  ┌─────────────────┐     │    ┌─────────────────┐          │
│  │ ASCII Renderer  │     │    │ Spotify Widget  │          │
│  │ Terminal UI     │     │    │ (TypeScript)    │          │
│  │ Commands        │     │    │ Shadow DOM      │          │
│  └────────┬────────┘     │    └────────┬────────┘          │
│           │              │             │                   │
│           └──────────────┴─────────────┘                   │
│                          │                                 │
├──────────────────────────▼─────────────────────────────────┤
│                    Phoenix LiveView                        │
│                  ┌──────────────┐                          │
│                  │ SpotifyLive  │                          │
│                  └──────┬───────┘                          │
├─────────────────────────▼──────────────────────────────────┤
│                   Backend Services                         │
│  ┌─────────────────────────────────────────────────┐       │
│  │          Droodotfoo.Spotify.Manager             │       │
│  ├─────────────────────────────────────────────────┤       │
│  │ • OAuth2 Flow                                   │       │
│  │ • Token Management                              │       │
│  │ • API Rate Limiting                             │       │
│  │ • Caching Layer                                 │       │
│  └─────────────┬───────────────────────────────────┘       │
│                │                                           │
│  ┌─────────────▼───────────────┐  ┌──────────────────┐     │
│  │   Spotify.API               │  │  Spotify.Cache   │     │
│  │ • Playlists                 │  │ • ETS Storage    │     │
│  │ • Tracks                    │  │ • TTL Management │     │
│  │ • Search                    │  │ • Invalidation   │     │
│  │ • Player Control            │  └──────────────────┘     │
│  └─────────────┬───────────────┘                           │
│                │                                           │
├────────────────▼───────────────────────────────────────────┤
│              External Services                             │
│  ┌────────────────────┐  ┌────────────────────────┐        │
│  │  Spotify Web API   │  │ Spotify Web Playback   │        │
│  │                    │  │      SDK (Browser)     │        │
│  └────────────────────┘  └────────────────────────┘        │
└────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Backend Services

#### Spotify.Manager (GenServer)
```elixir
defmodule Droodotfoo.Spotify.Manager do
  use GenServer

  # State management for:
  # - User authentication tokens
  # - Current playback state
  # - Active sessions
  # - Rate limiting counters
end
```

#### Spotify.API
```elixir
defmodule Droodotfoo.Spotify.API do
  # Core API functions:
  # - get_playlists/1
  # - get_playlist_tracks/2
  # - search/2
  # - play_track/2
  # - control_playback/2
end
```

#### Spotify.Cache
```elixir
defmodule Droodotfoo.Spotify.Cache do
  # ETS-based caching:
  # - Playlist metadata (TTL: 1 hour)
  # - Track information (TTL: 24 hours)
  # - Search results (TTL: 5 minutes)
  # - Album art ASCII (TTL: 7 days)
end
```

#### Spotify.Auth
```elixir
defmodule Droodotfoo.Spotify.Auth do
  # OAuth2 implementation:
  # - Authorization code flow
  # - Token refresh logic
  # - Secure token storage
end
```

### 2. Terminal Plugin

#### Plugin Implementation
```elixir
defmodule Droodotfoo.Plugins.Spotify do
  @behaviour Droodotfoo.PluginSystem.Plugin

  # Terminal-specific features:
  # - ASCII art album covers
  # - Text-based UI navigation
  # - Keyboard controls
  # - Playlist browsing
end
```

#### ASCII Art Converter
```elixir
defmodule Droodotfoo.Spotify.AsciiArt do
  # Convert album artwork to ASCII:
  # - Fetch image from URL
  # - Resize to terminal dimensions
  # - Convert to ASCII characters
  # - Cache results
end
```

### 3. Web Component

#### TypeScript Web Component
```typescript
// assets/js/components/SpotifyWidget.ts
export class SpotifyWidget extends HTMLElement {
  private shadow: ShadowRoot;
  private player: Spotify.Player;

  connectedCallback() {
    // Initialize Spotify Web Playback SDK
    // Set up Phoenix channel connection
    // Render UI
  }

  // Playlist display
  // Playback controls
  // Real-time updates
}
```

#### Phoenix Hook
```typescript
// assets/js/hooks/spotify.ts
export const SpotifyHook = {
  mounted() {
    // Load Spotify Web Playback SDK
    // Initialize player
    // Handle events
  },

  handlePlaylistClick(playlistId: string) {
    // Load playlist
    // Update UI
  }
}
```

### 4. LiveView Integration

```elixir
defmodule DroodotfooWeb.SpotifyLive do
  use DroodotfooWeb, :live_view

  def mount(_params, session, socket) do
    # Initialize Spotify connection
    # Load user preferences
  end

  def handle_event("play_track", %{"id" => track_id}, socket) do
    # Play selected track
    # Update playback state
  end

  def handle_info({:spotify, :track_changed}, socket) do
    # Broadcast track changes
    # Update UI
  end
end
```

## Data Flow

### Authentication Flow
1. User initiates auth via `spotify auth` command
2. Generate OAuth2 authorization URL
3. Open browser for user consent
4. Handle callback with authorization code
5. Exchange code for access/refresh tokens
6. Store tokens securely
7. Initialize player session

### Playback Flow
1. User selects track/playlist
2. Terminal/Web component sends request to LiveView
3. LiveView validates and forwards to Spotify.Manager
4. Manager checks cache, falls back to API
5. Initiate playback via Web Playback SDK
6. Update UI with playback state
7. Broadcast state to all connected clients

### Caching Strategy
- **Aggressive caching** for static content (playlists, tracks)
- **Short TTL** for dynamic content (playback state)
- **Invalidation** on user actions (add/remove tracks)
- **Background refresh** for frequently accessed items

## Security Considerations

1. **Token Storage**
   - Encrypt refresh tokens at rest
   - Use Phoenix session for access tokens
   - Implement token rotation

2. **API Keys**
   - Store in environment variables
   - Never expose client secret
   - Use server-side proxy for all API calls

3. **Rate Limiting**
   - Implement exponential backoff
   - Track API usage per user
   - Cache aggressively to reduce API calls

## Performance Optimizations

1. **Lazy Loading**
   - Load playlists on demand
   - Paginate track lists
   - Defer album art conversion

2. **Connection Pooling**
   - Reuse HTTP connections
   - Implement circuit breaker pattern

3. **WebSocket Efficiency**
   - Batch updates
   - Compress payloads
   - Debounce rapid changes

## Error Handling

1. **API Failures**
   - Graceful degradation
   - Offline mode with cached data
   - User-friendly error messages

2. **Playback Issues**
   - Automatic reconnection
   - Fallback to web player
   - State recovery after disconnect

## Testing Strategy

1. **Unit Tests**
   - API client functions
   - Cache operations
   - ASCII art conversion

2. **Integration Tests**
   - OAuth flow
   - LiveView interactions
   - Plugin commands

3. **E2E Tests**
   - Complete playback flow
   - Multi-client synchronization
   - Error scenarios

## Implementation Status

### Completed Components

- [x] **Backend Services**
  - OAuth2 authentication (`Droodotfoo.Spotify.Auth`)
  - API wrapper (`Droodotfoo.Spotify.API`)
  - Manager GenServer (`Droodotfoo.Spotify.Manager`)
  - ETS caching (`Droodotfoo.Spotify.Cache`)
  - ASCII art converter (`Droodotfoo.Spotify.AsciiArt`)

- [x] **Terminal Plugin**
  - Full plugin implementation (`Droodotfoo.Plugins.Spotify`)
  - Menu navigation and playlist browsing
  - Playback controls
  - Search functionality

- [x] **Web Integration**
  - LiveView module (`DroodotfooWeb.SpotifyLive`)
  - TypeScript web component (`SpotifyWidget`)
  - TEA/Elm architecture
  - Shadow DOM encapsulation

- [x] **Configuration**
  - Environment variable support
  - Development configuration
  - Supervision tree integration

## Deployment Checklist

- [ ] Register Spotify App at https://developer.spotify.com
- [ ] Configure redirect URIs in Spotify dashboard
- [ ] Set environment variables:
  ```bash
  export SPOTIFY_CLIENT_ID="your_client_id"
  export SPOTIFY_CLIENT_SECRET="your_client_secret"
  export SPOTIFY_REDIRECT_URI="your_callback_url"
  ```
- [ ] Test OAuth flow in production
- [ ] Monitor API rate limits
- [ ] Configure CORS for web component

## Future Enhancements

1. **Collaborative Playlists**
   - Real-time collaborative editing
   - Shared listening sessions
   - Vote on next track

2. **Advanced Features**
   - Lyrics display in terminal
   - Music recommendations
   - Mood-based playlists
   - Integration with terminal themes

3. **Analytics**
   - Listening statistics
   - Most played tracks
   - Discovery metrics
