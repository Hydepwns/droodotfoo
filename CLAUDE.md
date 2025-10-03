# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Phoenix LiveView droodotfoo application with Raxol terminal UI framework. The project creates a terminal-style interface in the browser using a three-layer architecture:
1. **Raxol Terminal** - Terminal rendering engine
2. **Phoenix LiveView** - Real-time web orchestration
3. **Web Browser** - Character-perfect monospace grid display

## Development Commands

```bash
# Setup and run
mix setup              # Install dependencies and build assets
mix phx.server         # Start Phoenix server (port 4000)
iex -S mix phx.server  # Start with interactive shell

# Testing and quality
mix test               # Run tests
mix test test/path/to/specific_test.exs  # Run single test file
mix format             # Format code
mix compile --warning-as-errors  # Check for compilation warnings

# Precommit (runs all checks)
mix precommit          # Compile with warnings as errors, check unused deps, format, and test

# Assets
mix assets.build       # Build CSS and JS
mix assets.deploy      # Build minified production assets
```

## Architecture

### Key Modules

- **Droodotfoo.RaxolApp** (`lib/droodotfoo/raxol_app.ex`) - GenServer managing terminal UI state, handles keyboard navigation and content rendering
- **Droodotfoo.TerminalBridge** (`lib/droodotfoo/terminal_bridge.ex`) - Converts Raxol buffer cells to HTML while preserving 1ch grid alignment
- **DroodotfooWeb.DroodotfooLive** (`lib/droodotfoo_web/live/droodotfoo_live.ex`) - LiveView module handling real-time updates and keyboard events

### Frontend Architecture

- **Grid System**: CSS uses 1ch units for character-perfect alignment
- **JavaScript**: `assets/js/terminal_grid.js` enforces grid on resize, `assets/js/hooks.js` handles LiveView integration
- **Styling**: Monospace-web aesthetic with Monaspace Argon font

### Routing

- `/` - Main LiveView terminal interface
- `/static` - Static HTML fallback page
- `/dev/dashboard` - Phoenix LiveDashboard (dev only)

## Code Patterns

### Functional Elixir Patterns
- Use pipe operators for data transformations
- Pattern match in function heads over conditionals
- Keep state immutable except in GenServers
- Avoid imperative patterns; use functional approaches

### Terminal Rendering
- Each character occupies exactly 1ch width
- Use ASCII art only (no emojis)
- Maintain 80-column terminal width
- Box-drawing characters for UI elements

### LiveView Events
```elixir
# Keyboard handling pattern
def handle_event("keydown", %{"key" => key}, socket) do
  # Send to Raxol GenServer
  # Update assigns with new buffer
  {:noreply, socket}
end
```

## Dependencies

Main dependencies managed in `mix.exs`:
- Phoenix 1.7.21 with LiveView 1.0.17
- Raxol 1.0.1 (terminal UI framework)
- Bandit web server
- Tailwind CSS and esbuild for assets

## Testing Approach

- Unit tests for Raxol terminal logic
- LiveView tests for interaction handling
- Grid alignment verification in browser
- Use `{:lazy_html, ">= 0.1.0"}` for HTML testing

## Important Notes

- No database (Ecto not included)
- 60fps update cycle via LiveView
- Terminal size fixed at 80x24 characters
- Font files should be in `/priv/static/fonts/`
- Responsive design snaps to character widths