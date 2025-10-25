# Terminal Archive

This directory contains the archived terminal functionality from droo.foo.

## What Was Archived

### Backend Code (lib/droodotfoo/)
- `raxol_app.ex` - Main Raxol terminal GenServer
- `terminal_bridge.ex` - Terminal HTML bridge
- `terminal/` - All terminal command modules
- `raxol/` - All Raxol rendering modules

### Frontend Code (assets/)
- `css/terminal_grid.css` - Terminal grid styling
- `css/mobile.css` - Mobile-specific terminal styles
- `js/terminal_grid.ts` - Terminal grid JavaScript

## Why It Was Archived

The terminal was causing issues and adding complexity. The decision was made to focus on the portfolio website (About, Projects, Web3, Contact, Resume pages) and archive the terminal for potential future restoration.

## How to Restore

If you want to restore the terminal functionality:

1. **Move code back:**
   ```bash
   mv .archived_terminal/lib/droodotfoo/* lib/droodotfoo/
   mv .archived_terminal/assets/css/* assets/css/
   mv .archived_terminal/assets/js/* assets/js/
   ```

2. **Restore supervision tree** (lib/droodotfoo/application.ex):
   - Add back `Droodotfoo.TerminalBridge` to children list
   - Add back `Droodotfoo.RaxolApp` to children list

3. **Restore DroodotfooLive** (lib/droodotfoo_web/live/droodotfoo_live.ex):
   - Add back terminal-related assigns in mount
   - Add back terminal overlay HTML in render
   - Add back terminal toggle button
   - Add back terminal event handlers

4. **Restore navigation hints** (lib/droodotfoo_web/components/content_components.ex):
   - Add back "Press ` (backtick) to toggle terminal" hint

5. **Recompile:**
   ```bash
   mix clean
   mix compile
   ```

## Archived Date
2025-10-21
