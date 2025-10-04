# TODO - droo.foo Terminal

**Current Status:** Production-ready terminal portfolio with 433/433 tests passing

---

## [COMPLETED] Recently Completed

### 1. STL 3D Viewer (COMPLETED)
**Status:** [DONE] Fully implemented with hybrid Three.js + ASCII HUD

**Completed tasks:**
- [x] Created Three.js WebGL component (`assets/js/hooks/stl_viewer.ts`)
- [x] Added LiveView hook for STL viewer mounting
- [x] Implemented keyboard controls (j/k rotate, h/l zoom, r reset, m cycle modes, q quit)
- [x] Added render mode switching (solid/wireframe/points)
- [x] Tested with sample STL files (cube.stl included)
- [x] Added loading states and error handling
- [x] Added to navigation menu (6th item)
- [x] Added command completions for `:stl` commands

**Files:**
- `lib/droodotfoo/stl_viewer_state.ex` - State management
- `lib/droodotfoo/terminal/commands/stl.ex` - Command interface
- `assets/js/hooks/stl_viewer.ts` - Three.js viewer with OrbitControls
- `lib/droodotfoo_web/live/droodotfoo_live.ex` - LiveView event handlers
- `lib/droodotfoo/raxol/renderer.ex` - ASCII HUD overlay
- `lib/droodotfoo/raxol/navigation.ex` - Keyboard control integration
- `priv/static/models/cube.stl` - Sample model

**Usage:**
- Navigate: Arrow keys to "STL Viewer" then Enter
- Commands: `:stl load /models/cube.stl`, `:stl mode wireframe`, `:stl info`
- Keyboard: j/k (rotate), h/l (zoom), m (mode), r (reset), q (quit)

---

### 2. Command Mode Shortcuts (COMPLETED)
**Status:** [DONE] Vim-style colon commands implemented

**Completed tasks:**
- [x] `:theme <name>` - Instant theme switching (8 themes available)
- [x] `:perf` / `:dashboard` / `:metrics` - Performance dashboard
- [x] `:clear` - Clear terminal screen
- [x] `:matrix` - Matrix rain plugin activation
- [x] `:help [cmd]` - Command help system
- [x] `:history` - Command history display

**Files:**
- `lib/droodotfoo/terminal/command_parser.ex` - Command parsing and routing
- `lib/droodotfoo/raxol/command.ex` - Command execution with state handling
- `lib/droodotfoo/terminal/commands.ex` - Command implementations

**Implementation details:**
- Theme changes properly propagate from terminal_state to main Raxol state
- Section changes handled via :section_change marker
- Plugin activation via :plugin tuple
- All commands added to tab completion

---

### 3. Performance Dashboard (COMPLETED)
**Status:** [DONE] ASCII charts with real-time metrics visualization

**Completed tasks:**
- [x] Created ASCII sparkline utility module
- [x] Real-time render time sparkline chart
- [x] Real-time memory usage sparkline chart
- [x] Display request rate, uptime, errors
- [x] Performance indicator bars
- [x] Live updates via PerformanceMonitor integration
- [x] Commands: `:perf`, `:dashboard`, `:metrics`

**Files:**
- `lib/droodotfoo/ascii_chart.ex` - Chart rendering utilities (NEW)
- `test/droodotfoo/ascii_chart_test.exs` - Full test coverage (NEW)
- `lib/droodotfoo/raxol/renderer.ex` - Enhanced dashboard rendering
- `lib/droodotfoo/performance_monitor.ex` - Existing metrics collection

**Features:**
- Sparklines using block characters (▁▂▃▄▅▆▇█)
- Horizontal bar charts with filled/empty blocks
- Percentage bars with labels
- Threshold indicators
- 14 unit tests, all passing

---

### 4. Status Bar (COMPLETED)
**Status:** [DONE] Bottom status bar with context awareness

**Completed tasks:**
- [x] Current section/breadcrumb display (left side)
- [x] Vim mode indicator (when active)
- [x] Command mode indicator (CMD/SEARCH)
- [x] Current time display (HH:MM:SS)
- [x] Connection status (LIVE indicator)
- [x] CSS styling with subtle background

**Files:**
- `lib/droodotfoo/raxol/renderer.ex` - Status bar rendering function
- `assets/css/terminal_grid.css` - Status bar styling (line 34)

**Features:**
- Dynamic section name formatting
- Mode indicators centered
- Time and status on right
- Full terminal width (110 chars)
- Subtle visual distinction with background and borders

---

### 5. Enhanced Search (COMPLETED)
**Status:** [DONE] Advanced search with fuzzy matching and navigation

**Completed tasks:**
- [x] Match counter display ("3/12 matches" format)
- [x] n/N keys to jump between matches
- [x] Current match indicator (arrow marker)
- [x] Search history with up/down arrows
- [x] Multiple search modes (fuzzy, exact, regex)
- [x] Match position tracking and scoring

**Files:**
- `lib/droodotfoo/advanced_search.ex` - Core search engine
- `lib/droodotfoo/raxol/navigation.ex` - n/N key handlers
- `lib/droodotfoo/raxol/command.ex` - Search history navigation
- `lib/droodotfoo/raxol/renderer.ex` - Search results display

**Features:**
- Fuzzy matching with position-based scoring
- Exact substring search
- Regex pattern matching
- Real-time match counter updates
- Circular navigation (n wraps to first, N wraps to last)
- Search mode switching (--fuzzy, --exact, --regex)
- Up to 50 stored search queries in history

---

### 6. Conway's Game of Life (COMPLETED)
**Status:** [DONE] Classic cellular automaton simulation

**Completed tasks:**
- [x] Core game logic with Conway's rules (60x20 grid)
- [x] Play/pause, step, speed controls
- [x] 5 preset patterns (glider, blinker, toad, beacon, pulsar)
- [x] Random pattern generation
- [x] ASCII rendering with █ for live cells
- [x] Toroidal topology (wraparound edges)
- [x] Commands: `:conway`, `:life`
- [x] 20 unit tests, all passing

**Files:**
- `lib/droodotfoo/plugins/conway.ex` - Plugin implementation (NEW)
- `test/droodotfoo/plugins/conway_test.exs` - Test coverage (NEW)
- `lib/droodotfoo/plugin_system/manager.ex` - Registered plugin
- `lib/droodotfoo/terminal/commands.ex` - Command shortcuts

**Features:**
- Auto-play with adjustable speed (50ms-2000ms)
- Manual stepping through generations
- Clear grid and random seeding
- Pattern library with classic configurations
- Generation counter and status display

**Controls:**
- SPACE: Play/Pause
- s: Step one generation
- c: Clear grid
- r: Random pattern
- +/-: Speed adjustment
- 1-5: Load patterns
- q: Quit

---

## [ACTIVE] Current Work

### 7. Spotify Integration (COMPLETED - 100%)
**Status:** [✓ COMPLETE] OAuth routes added, plugin fully implemented, 75 unit tests passing

### 8. GitHub Integration (COMPLETED & TESTED - 100%)
**Status:** [✓ TESTED] Full public API integration verified with real data

**Completed:**
- [x] GitHub API client with public endpoints (`lib/droodotfoo/github/api.ex`)
- [x] ASCII art rendering for repos, commits, activity (`lib/droodotfoo/github/ascii_art.ex`)
- [x] Full GitHub plugin with 10 modes (`lib/droodotfoo/plugins/github.ex`)
- [x] Command mode shortcuts (`:github`, `:github trending`, `:gh`)
- [x] Terminal commands (`github`, `gh`)
- [x] Plugin registered in PluginSystem.Manager
- [x] Tab completion for GitHub commands

**Features:**
- User profile browsing with stats
- Repository listing and details
- Recent activity feed (commits, PRs, issues)
- Trending repositories (last 7 days)
- Repository search with filters
- Commit history viewing
- Issues and pull requests display
- No authentication required (public API)

**Usage:**
- Terminal: `github` or `gh` - Opens GitHub plugin
- Command mode: `:github` - Opens plugin, `:github trending` - Shows trending repos
- Interactive modes: input, user, repos, activity, repo details, commits, issues, PRs, search, trending

**Test Results (All Passed ✓):**
- ✓ User profile: octocat (19,978 followers, 8 repos)
- ✓ Repository listing: 5 repos with stars/forks
- ✓ Activity feed: torvalds (recent Linux commits)
- ✓ Search: "language:elixir stars:>1000" (found Anoma, Elixir, Plausible)
- ✓ Trending: Last 7 days (1.9K-783 stars)
- ✓ Repo details: phoenixframework/phoenix (22.5K stars)
- ✓ Commit history: Recent Phoenix commits with authors

**Files:**
- `lib/droodotfoo/github/api.ex` - GitHub public API client
- `lib/droodotfoo/github/ascii_art.ex` - ASCII rendering
- `lib/droodotfoo/plugins/github.ex` - Interactive plugin

---

**Spotify Integration:**

**Completed:**
- [x] Full Spotify plugin implementation (`lib/droodotfoo/plugins/spotify.ex`)
- [x] OAuth2 authentication module (`lib/droodotfoo/spotify/auth.ex`)
- [x] Spotify API client with Req (`lib/droodotfoo/spotify/api.ex`)
- [x] GenServer state manager (`lib/droodotfoo/spotify/manager.ex`)
- [x] Caching layer (`lib/droodotfoo/spotify/cache.ex`)
- [x] ASCII art rendering (`lib/droodotfoo/spotify/ascii_art.ex`)
- [x] OAuth callback routes (`/auth/spotify`, `/auth/spotify/callback`, `/auth/spotify/logout`)
- [x] Command mode shortcuts (`:spotify`, `:spotify auth`, `:spotify now-playing`)
- [x] Terminal commands (`spotify`, `music`)
- [x] Started in application supervision tree
- [x] Plugin registered in PluginSystem.Manager
- [x] Comprehensive unit tests (75 tests, all passing)
  - `test/droodotfoo/spotify/auth_test.exs` - OAuth authentication tests
  - `test/droodotfoo/spotify/api_test.exs` - API client tests
  - `test/droodotfoo/spotify/manager_test.exs` - GenServer state tests
  - `test/droodotfoo/plugins/spotify_test.exs` - Plugin behavior tests

**OAuth Testing Notes:**
- Unit tests: ✓ Complete (75/75 passing)
- End-to-end OAuth: Requires Spotify API credentials in 1Password
- To test OAuth flow:
  1. Add credentials to 1Password: `op item create --category=login --title="droodotfoo-dev" SPOTIFY_CLIENT_ID="<id>" SPOTIFY_CLIENT_SECRET="<secret>"`
  2. Run: `./bin/dev` (loads secrets automatically)
  3. Visit: http://localhost:4000/auth/spotify
  4. Authorize and test playback controls

**Usage:**
- Terminal: `spotify` or `music` - Opens Spotify plugin
- Command mode: `:spotify` - Opens plugin, `:spotify auth` - Shows auth URL
- OAuth flow: Visit http://localhost:4000/auth/spotify to authenticate
- Credentials: Set SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET via 1Password CLI

---

## [NEXT] Phase 2: Real-time Showcases

Phase 1 is complete! Moving to Phase 2 with real-time features.

### 7. Spotify Integration (High Priority) - 100% COMPLETE ✓
**Test Coverage:** 75/75 tests passing

- [x] OAuth flow for user authentication
- [x] Now playing display with progress bar
- [x] Search tracks/artists/playlists
- [x] Playback controls (play/pause/skip)
- [x] Live updates for current track (5-second polling)
- [x] Commands: `:spotify`, `:spotify auth`, `spotify`, `music`
- [x] Comprehensive unit test coverage (75 tests)
- [x] OAuth authentication tests
- [x] API client tests
- [x] GenServer state management tests
- [x] Plugin behavior tests

**Files:**
- ✓ `lib/droodotfoo/plugins/spotify.ex` - Full plugin with 7 modes
- ✓ `lib/droodotfoo/spotify/auth.ex` - OAuth2 with token refresh
- ✓ `lib/droodotfoo/spotify/api.ex` - Complete API client
- ✓ `lib/droodotfoo/spotify/manager.ex` - GenServer with periodic updates
- ✓ `lib/droodotfoo/spotify/cache.ex` - TTL-based caching
- ✓ `lib/droodotfoo/spotify/ascii_art.ex` - ASCII rendering
- ✓ `lib/droodotfoo_web/controllers/spotify_auth_controller.ex` - OAuth callbacks
- ✓ `test/droodotfoo/spotify/auth_test.exs` - Auth tests
- ✓ `test/droodotfoo/spotify/api_test.exs` - API tests
- ✓ `test/droodotfoo/spotify/manager_test.exs` - Manager tests
- ✓ `test/droodotfoo/plugins/spotify_test.exs` - Plugin tests

---

### 9. GitHub Activity Feed (High Priority) - COMPLETED & TESTED ✓
**Credentials needed:** None (uses public API)

- [x] User profile and stats display ✓ Tested with octocat
- [x] Repository browsing and details ✓ Tested with 5 repos
- [x] Recent activity feed ✓ Tested with torvalds activity
- [x] Trending repositories (last 7 days) ✓ Tested with real trending data
- [x] Repository search with filters ✓ Tested with Elixir repos >1000 stars
- [x] Commit history viewing ✓ Tested with Phoenix commits
- [x] Issues and pull requests display ✓ API verified
- [x] Commands: `:github`, `:gh`, `github`, `gh` ✓ All registered

**Real-World Test Results:**
- ✓ Fetched octocat profile: 19,978 followers, 8 public repos
- ✓ Retrieved torvalds recent Linux commits
- ✓ Found top Elixir repos: Anoma (34K stars), Elixir (26K), Plausible (23K)
- ✓ Trending repos from last week with 1.9K-783 stars
- ✓ Phoenix framework details: 22.5K stars, 3K forks

**Files:**
- ✓ `lib/droodotfoo/github/api.ex` - Public API client with Req
- ✓ `lib/droodotfoo/github/ascii_art.ex` - ASCII rendering utilities
- ✓ `lib/droodotfoo/plugins/github.ex` - Full interactive plugin with 10 modes
- ✓ Commands and shortcuts added
- ✓ Plugin registered and tested

---

### 10. More Terminal Games

- [x] **Conway's Game of Life** - Cellular automaton (COMPLETED)
- [ ] **Tetris** - Classic block puzzle
- [ ] **2048** - Sliding tile game
- [ ] **Wordle** - Daily word puzzle
- [ ] **Typing Speed Test** - WPM and accuracy tracking

---

## [POLISH] Polish & UX

### 9. Visual Enhancements

- [ ] Boot sequence animation on page load
- [ ] CRT effects toggle (scanlines, phosphor glow)
- [ ] Command autocomplete UI
- [ ] Better click detection (data attributes)

---

### 10. Accessibility

- [ ] Screen reader support (ARIA labels)
- [ ] High contrast mode toggle
- [ ] Keyboard navigation announcements
- [ ] Focus management improvements
- [ ] Reduced motion mode

---

### 11. Portfolio-Specific

- [ ] PDF resume export (ex_pdf or chromic)
- [ ] Interactive resume filtering
- [ ] Project showcase with live demos
- [ ] Skill proficiency visualizations
- [ ] Contact form with validation

---

## [DEV-EXP] Developer Experience

### 12. Documentation & Tooling

- [ ] ExDoc integration with typespecs
- [ ] API documentation examples
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Coverage reporting
- [ ] Performance benchmarks

---

## [REF] Reference

**Documentation:**
- **README.md** - Setup, features, deployment
- **DEVELOPMENT.md** - Architecture, integrations, testing best practices
- **docs/FEATURES.md** - Complete feature roadmap (29 features, 5-phase plan)
- **CLAUDE.md** - AI assistant instructions
- **AGENTS.md** - Phoenix/Elixir guidelines

**Key Commands:**
```bash
mix phx.server              # Start server (port 4000)
./bin/dev                   # Start with 1Password secrets
mix test                    # Run tests (433/433 passing)
mix precommit              # Full check (compile, format, test)
```

**Production Status:**
- [x] 508/508 tests passing (100% pass rate - includes 75 new Spotify tests)
- [x] Zero compilation warnings
- [x] Synthwave84 theme with 8 variants
- [x] Error handling with ASCII box UI
- [x] Advanced search with fuzzy matching and navigation
- [x] Session persistence & breadcrumbs
- [x] Performance monitoring with live charts
- [x] Plugin system (Snake, Calculator, Matrix, Spotify, Conway, GitHub)
- [x] STL 3D viewer with Three.js integration
- [x] Command mode shortcuts (theme, perf, clear, spotify, github, etc.)
- [x] Status bar with context awareness
- [x] Conway's Game of Life with 5 preset patterns
- [x] Spotify integration with OAuth (100% complete - 75 unit tests)
- [x] GitHub integration - fully tested with real data

---

## [ROADMAP] Immediate Next Steps

**Phase 1 Progress:** 6 of 6 complete ✓

1. [DONE] Complete STL viewer
2. [DONE] Add command mode (`:theme`, `:perf`, `:clear`)
3. [DONE] Build performance dashboard (visualize existing metrics)
4. [DONE] Add status bar (context awareness)
5. [DONE] Enhance search (highlighting, match navigation)
6. [DONE] Conway's Game of Life

**Phase 1 Goal:** ✓ COMPLETE - Showcased terminal's real-time capabilities and visual polish

**Phase 2 Progress:** 2 of 4 complete ✓ (Spotify 100%, GitHub 100%)

**Latest Features:**
- **Spotify Integration** [100% COMPLETE] - Full OAuth2 music controller with 75 unit tests. Commands: `spotify`, `music`, `:spotify`
  - OAuth2 flow with automatic token refresh
  - Now playing display with progress bar
  - Playback controls (play/pause/skip/volume)
  - Search tracks, artists, albums, playlists
  - Live updates every 5 seconds
  - 75 comprehensive unit tests covering all functionality
- **GitHub Integration** [100% COMPLETE] - Browse users, repos, trending, search. Commands: `github`, `gh`, `:github`
  - User profiles with stats (tested: octocat - 19K followers)
  - Repository browsing and search (tested: Elixir repos >1K stars)
  - Activity feed (tested: torvalds Linux commits)
  - Trending repos (tested: last 7 days, 1.9K-783 stars)
  - Commit history, issues, PRs
- Conway's Game of Life - Classic cellular automaton with 5 patterns, use `:conway` or `:life`
- Enhanced search - Fuzzy/exact/regex modes, n/N navigation, match counter, history
- Status bar - Shows current section, mode indicators, time, and connection status
- Performance dashboard - Live sparklines with `:perf` command
- Command shortcuts - Use `:theme matrix`, `:perf`, `:clear`, `:github`, `:spotify`
- STL 3D Viewer - Navigate from menu or use `:stl load /models/cube.stl`

---

**Last Updated:** October 4, 2025
**Version:** 1.2.0
**Test Coverage:** 508/508 passing (100%)
**Phase 1:** Complete ✓
**Phase 2:** 50% complete (Spotify ✓, GitHub ✓)
