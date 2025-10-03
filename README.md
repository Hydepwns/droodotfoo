# droo.foo

Interactive terminal portfolio built with Phoenix LiveView and Raxol terminal UI framework.

## Features

- **Terminal Interface**: Full Unix-like terminal experience in the browser
- **Vim Navigation**: hjkl movement, search with `/`, command mode
- **Plugin System**: Extensible architecture with games and utilities
- **Spotify Integration**: Music player with playlist browsing and playback control
- **Real-time Updates**: 60fps rendering via Phoenix LiveView
- **PWA Support**: Installable progressive web app with offline capabilities

## Quick Start

```bash
# Install dependencies
mix setup

# Set Spotify credentials (optional)
export SPOTIFY_CLIENT_ID="your_client_id"
export SPOTIFY_CLIENT_SECRET="your_client_secret"

# Start server
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000)

## Terminal Commands

- `help` - Show available commands
- `ls` - List directory contents
- `cat <file>` - Display file contents
- `spotify` - Launch Spotify player
- `snake` - Play Snake game
- `calc` - Calculator
- `matrix` - Matrix rain effect
- `themes` - Switch color themes
- `clear` - Clear terminal

## Architecture

- **Phoenix LiveView**: Real-time web framework
- **Raxol**: Terminal rendering engine
- **TEA/Elm Pattern**: Functional state management
- **ETS Caching**: Performance optimization
- **Plugin System**: Modular extensions

## Development

```bash
# Run tests
mix test

# Format code
mix format

# Compile with warnings
mix compile --warning-as-errors

# Full precommit check
mix precommit
```

## Documentation

- [Spotify Architecture](docs/SPOTIFY_ARCHITECTURE.md)
- [TODO List](TODO.md)
- [Claude Instructions](CLAUDE.md)
