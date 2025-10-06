# droo.foo Terminal Features Roadmap

Comprehensive feature list showcasing terminal capabilities, organized by impact and effort.

**Legend:**
- Effort: `[Low]` `[Med]` `[High]`
- Impact: `*` (1-3 stars)
- Status: `[DONE]` `[WIP]` `[PLANNED]` `[IDEA]`

---

## [ROCKET] Currently Implementing

### 3D Model Viewer (Three.js WebGL) [WIP]
**Effort:** `[High]` | **Impact:** ***

Interactive 3D STL model viewer with terminal controls.

**Commands:**
```
:stl load <url>        Load 3D model
:stl mode <type>       solid|wireframe|points
:stl rotate [axis]     Auto-rotate on x|y|z|all
:stl ascii             ASCII wireframe preview
```

**Controls:**
- `h/j/k/l` - Rotate model
- `+/-` - Zoom in/out
- `r` - Reset view
- `m` - Cycle render modes

**Why impressive:** Demonstrates WebGL integration, real-time 3D in browser, terminal-controlled graphics

---

## [QUICK WIN] Quick Wins (High Impact, Low Effort)

### 1. Live Command Mode [DONE] (Partially Done)
**Effort:** `[Low]` | **Impact:** ***

Vim-style `:` commands for instant actions.

**Already implemented:**
- `:stl` - STL viewer commands
- Theme system exists (needs `:theme` shortcut)

**To add:**
```
:theme <name>      Switch themes instantly
:matrix            Matrix rain animation
:perf              Live performance dashboard
:clear             Clear terminal
:help [cmd]        Command help
:mode <mode>       Switch terminal modes
:history           Show command history
:export <format>   Export terminal content
```

**Implementation:** Add command parser in `lib/droodotfoo/terminal/command_parser.ex`

---

### 2. Enhanced Search System [PLANNED]
**Effort:** `[Low]` | **Impact:** **

Current: Basic `/` search exists
**Improvements:**
- Match highlighting with different colors
- Match counter (e.g., "3/12 matches")
- `n/N` to navigate between matches
- Current match indicator
- Regex pattern support
- Search history with `↑/↓`

**Files to modify:**
- `lib/droodotfoo/raxol/state.ex` - Add match tracking
- `lib/droodotfoo/raxol/renderer.ex` - Highlight matches
- `lib/droodotfoo_web/live/droodotfoo_live.ex` - Handle n/N keys

---

### 3. Interactive Demos [PLANNED]
**Effort:** `[Low-Med]` | **Impact:** ***

**Typing Test**
```
:typing-test [difficulty]    Measure WPM, accuracy
```
- Show live WPM counter
- Accuracy percentage
- Highlight errors in red
- Leaderboard (localStorage)

**ASCII Animations**
```
:starfield              Starfield animation
:rain                   Rain effect
:fire                   Fire simulation
:globe                  Spinning ASCII globe
```

**Mini Code Editor**
```
:edit <file>            Simple code editor
```
- Syntax highlighting (basic)
- Line numbers
- Save/cancel

**Terminal Games**
```
:snake          [DONE] Already exists
:tetris         Classic Tetris
:wordle         Terminal Wordle
:2048           2048 puzzle game
:conway         Conway's Game of Life
```

**Implementation:** Create plugin modules in `lib/droodotfoo/plugins/`

---

## [HOT] Real-time Features (Impressive Showcases)

### 4. Live Performance Dashboard [DONE] (Partially Done)
**Effort:** `[Low]` | **Impact:** ***

**Already exists:** PerformanceMonitor collecting metrics

**Command:** `:perf` or `:dashboard`

**Display:**
```
╔══════════════════════════════════════════════════════════════════════════════╗
║ PERFORMANCE DASHBOARD                                    [Updated: 00:00:01] ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  Render Time (ms)              Memory (MB)              Request Rate         ║
║  ┌─────────────────┐          ┌──────────────┐         ┌─────────────────┐   ║
║  │     ▄▄▄         │          │         ▄▄▄  │         │    ▄▄▄▄         │   ║
║  │  ▄▄▄   ▄▄▄      │          │      ▄▄▄   ▄ │         │ ▄▄▄    ▄▄▄      │   ║
║  │▄▄        ▄▄▄▄   │          │   ▄▄▄       ▄│         │▄       ▄  ▄▄    │   ║
║  └─────────────────┘          └──────────────┘         └─────────────────┘   ║
║    Avg: 2.3ms                   Current: 42.1           Avg: 156 req/s       ║
║                                                                              ║
║  Active Connections: 3          Buffer Updates: 1,247    Errors: 0           ║
║  Uptime: 2h 34m                 FPS: 60                  Latency: 12ms       ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

**Features:**
- ASCII charts (sparklines)
- Real-time updates (LiveView)
- Color-coded thresholds
- Export metrics as JSON/CSV

**Implementation:** Use existing `Droodotfoo.PerformanceMonitor`, create visualization plugin

---

### 5. Spotify Now Playing [PLANNED]
**Effort:** `[Med]` | **Impact:** ***

**Credentials available:** SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET

**Commands:**
```
:spotify                    Open Spotify dashboard
:spotify now-playing        Show current track
:spotify search <query>     Search tracks/artists
:spotify play <track>       Play track
:spotify pause              Pause playback
:spotify next/prev          Skip tracks
:spotify playlists          Browse playlists
```

**Live Display:**
```
╔════════════════════════════════════════════════════════════╗
║ NOW PLAYING                                                ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  Track:    Midnight City                                   ║
║  Artist:   M83                                             ║
║  Album:    Hurry Up, We're Dreaming                        ║
║                                                            ║
║  [████████████████░░░░░░░░░░]  2:34 / 4:05                 ║
║                                                            ║
║  <<  ||  >>     Shuffle: Off  Repeat: Off  Vol: 65%        ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

**Implementation:** Extend existing `lib/droodotfoo/plugins/spotify.ex`

---

### 6. Live Data Streams [PLANNED]
**Effort:** `[Med]` | **Impact:** **

**GitHub Activity Feed**
```
:github <user>              Recent commits, PRs, issues
:github stars               Trending repos
:github notifications       Your notifications
```

**Stock/Crypto Ticker**
```
:ticker BTC ETH AAPL        Live price updates
:chart BTC 1d               ASCII price chart
```

**Weather Dashboard**
```
:weather [city]             Current weather + forecast
```

**RSS Feed Reader**
```
:rss add <url>              Add feed
:rss list                   Show all feeds
:rss read <feed>            Read articles
```

**Implementation:** Create HTTP clients, use GenServer for polling, ASCII chart rendering

---

## [CODE] Developer Tools

### 7. Code Playground [PLANNED]
**Effort:** `[Med]` | **Impact:** ***

Execute code in the terminal with live output.

**Commands:**
```
:code                       Open code editor
:run                        Execute code
:lang <language>            Set language (js|elixir|python)
:share                      Generate shareable link
```

**Supported Languages:**
- **JavaScript** - Run in browser sandbox
- **Elixir** - Compile and execute via `Code.eval_string`
- **Python** - Via PyScript or sandboxed API

**Example:**
```
> :code
> :lang elixir

defmodule Math do
  def factorial(0), do: 1
  def factorial(n), do: n * factorial(n - 1)
end

Math.factorial(5)

> :run
Output: 120
```

**Safety:** Sandboxed execution, timeout limits, resource constraints

---

### 8. Git Visualizer [IDEA]
**Effort:** `[High]` | **Impact:** **

**Commands:**
```
:git tree                   ASCII commit tree
:git branches               Branch visualization
:git diff <hash>            Show diff in terminal
:git blame <file>           Annotated file view
```

**Example:**
```
* 5a7f9d2 (HEAD -> main) Add interactive terminal commands
│ Author: Drew Hiro <drew@axol.io>
│ Date: 2 hours ago
│
* 3c2e1a4 Implement performance optimizations
│ Author: Drew Hiro <drew@axol.io>
│ Date: 1 day ago
│
* 2b1c0f9 Initial commit
  Author: Drew Hiro <drew@axol.io>
  Date: 3 days ago
```

---

### 9. Package Manager Explorer [PLANNED]
**Effort:** `[Low]` | **Impact:** **

Already simulated: `npm`, `pip` commands exist in `terminal/commands.ex`

**Enhancements:**
```
:hex search <package>       Search Hex.pm
:hex info <package>         Package details
:npm trending               Trending packages
:mix deps.tree              Dependency tree ASCII
```

---

## [GAME] Interactive Experiences

### 10. Terminal Games [PLANNED]
**Effort:** `[Low-Med]` | **Impact:** ***

**Already exists:** Snake (`lib/droodotfoo/plugins/snake_game.ex`)

**New games:**

**Tetris**
- Classic Tetris mechanics
- High score tracking
- Progressive difficulty

**2048**
- Arrow key controls
- Smooth tile animations
- Undo feature

**Wordle**
- Daily word puzzle
- Color-coded feedback
- Share results

**Pong**
- Single player vs AI
- Two player mode (WebSocket)
- Difficulty levels

**Conway's Game of Life**
- Patterns library
- Step-by-step or auto-play
- Pattern editor

**Implementation:** Plugin system architecture already exists

---

### 11. Typing Speed Test [PLANNED]
**Effort:** `[Low]` | **Impact:** **

**Command:** `:typing-test [difficulty]`

**Features:**
- Live WPM counter
- Accuracy tracking
- Error highlighting
- Different difficulty levels
- Leaderboard (localStorage)
- Share results

**Display:**
```
╔════════════════════════════════════════════════════════════╗
║ TYPING TEST - Medium Difficulty                           ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  Type the following:                                       ║
║                                                            ║
║  The quick brown fox jumps over the lazy dog               ║
║  The quick brown fox_                                      ║
║                      ^                                     ║
║                                                            ║
║  WPM: 67    Accuracy: 98%    Time: 0:15                    ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

---

### 12. ASCII Art Generator [IDEA]
**Effort:** `[Med]` | **Impact:** **

**Commands:**
```
:ascii <text>               Generate ASCII art text
:ascii-image <url>          Convert image to ASCII
:figlet <text>              Figlet-style text
:banner <text>              Large banner text
```

**Implementation:** Use algorithms or external APIs

---

### 13. File Browser (Ranger-style) [IDEA]
**Effort:** `[Med]` | **Impact:** **

**Command:** `:ranger` or `:files`

**Features:**
- Three-column layout
- File preview
- Syntax highlighting
- Quick navigation
- Bulk operations
- Search within files

---

### 14. Markdown Live Preview [IDEA]
**Effort:** `[Med]` | **Impact:** **

**Commands:**
```
:md <file>                  Render markdown in terminal
:md-preview                 Live preview mode
```

**Features:**
- Terminal-friendly rendering
- Table of contents
- Syntax highlighting for code blocks
- Link handling

---

## [STAR] Advanced Features (Complex but Impressive)

### 15. Terminal Recording/Replay [IDEA]
**Effort:** `[High]` | **Impact:** ***

**Commands:**
```
:record start               Start recording
:record stop                Stop recording
:record save <name>         Save recording
:replay <name>              Replay session
:export <name> <format>     Export as gif/video
```

**Use cases:**
- Portfolio demos
- Tutorial creation
- Bug reproduction

**Implementation:** Store terminal state snapshots, replay with timing

---

### 16. Collaborative Terminal (Multiplayer) [IDEA]
**Effort:** `[High]` | **Impact:** ***

**Commands:**
```
:collab start               Create session
:collab join <id>           Join session
:collab invite <email>      Invite user
```

**Features:**
- Multiple cursors
- Real-time command sync
- User presence indicators
- Chat sidebar
- Session recording

**Implementation:** Phoenix Presence, PubSub, CRDT for state sync

---

### 17. AI Chat Integration [IDEA]
**Effort:** `[High]` | **Impact:** ***

**Commands:**
```
:ai                         Open AI chat
:ai ask <question>          Ask question
:ai code <description>      Generate code
:ai explain <command>       Explain command
```

**Integration options:**
- OpenAI API
- Anthropic Claude API
- Local LLM (Ollama)

---

### 18. WebAssembly Execution [IDEA]
**Effort:** `[High]` | **Impact:** **

**Commands:**
```
:wasm load <url>            Load WASM module
:wasm run <function>        Execute function
:wasm bench                 Benchmark performance
```

**Use cases:**
- Run compiled Rust/C++ in terminal
- High-performance computing
- Game engines

---

### 19. Network Diagnostics Visualizer [IDEA]
**Effort:** `[Med-High]` | **Impact:** **

**Commands:**
```
:trace <host>               Visual traceroute
:ping-graph <host>          Live ping graph
:port-scan <host>           Port scanner
:whois <domain>             Domain info
```

**Example:**
```
Traceroute to google.com (142.250.185.46)

 1  router.local        1.2ms   ▁▂▁▂▁
 2  10.0.0.1           5.4ms   ▂▃▂▃▂
 3  isp-gateway.net   12.8ms   ▃▄▃▄▃
 4  backbone1.net     23.1ms   ▅▆▅▆▅
 5  google.com        45.3ms   ▇█▇█▇
```

---

## [GRAPH] Portfolio-Specific Features

### 20. Interactive Resume [PLANNED]
**Effort:** `[Low]` | **Impact:** ***

**Enhancements to existing resume:**
```
:resume filter <keyword>    Filter by skill/experience
:resume skills [category]   Show skills with proficiency
:resume timeline            Career timeline
:resume export pdf          Generate PDF
```

**Visualizations:**
- Skill proficiency bars
- Experience timeline
- Project impact metrics

---

### 21. Project Showcase [PLANNED]
**Effort:** `[Med]` | **Impact:** ***

**Commands:**
```
:projects                   List all projects
:project <name>             Show project details
:project demo <name>        Live demo in terminal
:project stats              Project statistics
```

**Features:**
- Live GitHub stats
- Technology tags
- Screenshots/demos
- Links to repos

---

### 22. Skill Visualizations [PLANNED]
**Effort:** `[Low]` | **Impact:** **

**Commands:**
```
:skills                     Skill overview
:skills graph               Visual skill tree
:skills compare             Compare skills
```

**Example:**
```
╔════════════════════════════════════════════════════════════╗
║ TECHNICAL SKILLS                                           ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  Elixir       ████████████████████░  95%  ***              ║
║  JavaScript   ██████████████████░░  90%  ***              ║
║  Rust         ███████████████░░░░░  75%  **               ║
║  Python       ████████████████░░░░  80%  ***              ║
║  Go           ███████████░░░░░░░░░  55%  **               ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

---

### 23. Contact Form [PLANNED]
**Effort:** `[Low]` | **Impact:** **

**Command:** `:contact`

**Features:**
- Multi-step form
- Field validation
- Email sending via Phoenix Mailer
- Success/error feedback
- Anti-spam measures

---

## [ART] Visual Enhancements

### 24. Boot Sequence Animation [IDEA]
**Effort:** `[Low]` | **Impact:** **

Animated boot screen on page load:
```
RAXOL TERMINAL v1.0.0
[OK] Initializing kernel...
[OK] Loading modules...
[OK] Starting Phoenix LiveView...
[OK] Connecting WebSocket...
[OK] Ready.

droo.foo Terminal - Type 'help' for commands
>
```

---

### 25. CRT/Retro Effects [IDEA]
**Effort:** `[Low]` | **Impact:** **

Already has Synthwave84 theme, add:
- Scanline overlay
- Phosphor glow
- Screen curvature
- Chromatic aberration
- Flicker effect toggle

**Command:** `:effects [on|off]`

---

### 26. Status Bar [PLANNED]
**Effort:** `[Low]` | **Impact:** **

Bottom status bar showing:
- Current section
- Vim mode indicator
- Time
- Connection status
- Unread notifications
- Battery (if on mobile)

---

### 27. Command History UI [PLANNED]
**Effort:** `[Low]` | **Impact:** *

**Already partially exists:** History tracked in state

**Enhancements:**
- `↑/↓` to navigate (already works?)
- `:history` command to show full history
- Search history with `/`
- Clear history option

---

## [MOBILE] Mobile & Accessibility

### 28. Touch Gestures [PLANNED]
**Effort:** `[Med]` | **Impact:** **

- Swipe up/down for section navigation
- Pinch to zoom text
- Long press for context menu
- Double tap to execute

---

### 29. Accessibility Improvements [PLANNED]
**Effort:** `[Med]` | **Impact:** ***

- Screen reader support (ARIA labels)
- High contrast mode
- Keyboard navigation announcements
- Focus indicators
- Reduced motion mode
- Font size controls

---

## [TOOL] Implementation Priority

### Phase 1: Quick Wins (1-2 weeks)
1. Command mode shortcuts (`:theme`, `:perf`, `:clear`)
2. Enhanced search (highlighting, counters)
3. Performance dashboard
4. Typing test
5. Status bar

### Phase 2: Real-time Features (2-3 weeks)
1. Spotify integration
2. GitHub activity feed
3. Stock/crypto ticker
4. Weather dashboard
5. Code playground (JavaScript first)

### Phase 3: Interactive (3-4 weeks)
1. New terminal games (Tetris, 2048, Wordle)
2. ASCII art generator
3. Markdown preview
4. File browser
5. Boot animation

### Phase 4: Advanced (Ongoing)
1. Terminal recording
2. Collaborative mode
3. AI integration
4. WebAssembly support
5. Network diagnostics

### Phase 5: Portfolio Polish (1-2 weeks)
1. Interactive resume enhancements
2. Project showcase
3. Skill visualizations
4. Contact form
5. Accessibility improvements

---

## [CHART] Success Metrics

Track feature adoption and impact:

- **Engagement:** Time spent per session
- **Retention:** Return visitors
- **Interactivity:** Commands per session
- **Virality:** Social shares of demos
- **Technical:** Performance metrics (FPS, latency)

---

## [TARGET] Next Steps

1. **Review this document** - Prioritize features based on:
   - Portfolio goals (job hunting vs. showcase)
   - Time available
   - Technical complexity

2. **Create implementation tasks** - Break down selected features into:
   - Backend work (Elixir modules)
   - Frontend work (JavaScript/LiveView)
   - Testing requirements
   - Documentation

3. **Set milestones** - Define what "done" looks like for each feature

4. **Start building** - Begin with Phase 1 Quick Wins for immediate impact

---

**Remember:** Focus on features that demonstrate:
- Real-time capabilities (LiveView strength)
- Visual polish (terminal aesthetics)
- Technical sophistication (Elixir/Phoenix expertise)
- Performance (60fps terminal rendering)
- Interactivity (engaging user experience)
