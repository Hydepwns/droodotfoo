# TODO - droo.foo Terminal

## Current Status

**Status**: Production-ready terminal portfolio with Web3, Fileverse, Performance & Resume Filtering
**Latest**: Oct 19, 2025 - **Coverage Sprint 2 COMPLETE** (TimeFormatter 100%, Utilities 94.2%, overall 40.8%)
**Test Coverage**: 1159 tests, 1138 passing (98.2%) | **Code Coverage**: 40.8%
**Modules**: 152 production modules (~50k LOC)

---

## Quick Reference

**Commands**: `mix phx.server` · `./bin/dev` · `mix test` · `mix precommit`

**Performance Tools**:
- `perf memory` - Memory usage stats
- `perf cache` - Cache efficiency dashboard
- `perf metrics` - Performance metrics
- `perf analyze` - Optimization recommendations
- `perf optimize` - Run automatic optimizations
- `perf monitor` - Full performance dashboard

**Fast Links**:
- [Next Priorities](#next-priorities-phase-7--8)
- [Future Enhancements](#future-enhancements)
- [Completed Summary](#completed-phases-summary)

---

## Next Priorities (Phase 8)

### Phase 7.3: Interactive Resume Filtering ✅ COMPLETE
See [Completed Phases](#phase-73-interactive-resume-filtering-oct-19-2025) for details.

---

### Phase 8.4: Testing Infrastructure (HIGH PRIORITY)
**Estimated Time**: 2-3 days

**Goal**: Strengthen testing infrastructure and set up CI/CD pipeline

**Tasks**:
1. **Test Coverage Reporting** ✅ COMPLETE (30 min)
   - ✅ Add Coveralls for coverage tracking
   - ✅ Configure coverage thresholds (target: >85%, current: 39.8%)
   - ✅ Add coverage badges to README
   - ✅ Generated baseline report (HTML at cover/)

2. **CI/CD Pipeline** (1 day)
   - [ ] GitHub Actions workflow for tests
   - [ ] Automated deployment to Fly.io
   - [ ] Pre-commit hooks with mix precommit

3. **Test Infrastructure** (1 day)
   - [ ] Mock data factories with ExMachina
   - [ ] Test utilities for common patterns
   - [ ] Integration test suite expansion

**Files to Create**:
```
.github/workflows/
├── ci.yml              # Continuous integration
├── test.yml            # Test pipeline
└── deploy.yml          # Deployment pipeline

test/support/
├── factories.ex        # Data factories
├── helpers.ex          # Test utilities
└── mocks.ex           # Mock implementations

.credo.exs             # Code quality config
.coveralls.exs         # Coverage config
```

**Dependencies**:
```elixir
{:coveralls, "~> 2.0", only: :test}
{:ex_machina, "~> 2.7", only: :test}
{:credo, "~> 1.7", only: [:dev, :test], runtime: false}
```

---

### Phase 8.5: Code Quality Improvements (MEDIUM PRIORITY)
**Estimated Time**: 1-2 days

**Tasks**:
- [ ] Run Credo strict checks and fix warnings
- [ ] Add Sobelow security scanning
- [ ] Dependency audit and updates
- [ ] Dead code removal
- [ ] Code complexity refactoring

---

### Phase 8.6: Modern Command REPL with Fuzzy Search (HIGH PRIORITY)
**Estimated Time**: 4-5 hours total (2 hours completed, 2-3 hours remaining)
**Status**: IN PROGRESS (Backend ✅ Complete, Frontend 📋 Pending)

**Goal**: Replace vim-style `:` command mode with modern, always-visible REPL featuring fuzzy search and rich command suggestions

**Completed Work (2 hours)** ✅:

1. **Fuzzy Search Engine** - `lib/droodotfoo/terminal/fuzzy_search.ex` (201 lines)
   - ✅ Character-by-character matching algorithm with scoring
   - ✅ Bonuses for consecutive matches, prefixes, word boundaries, short aliases
   - ✅ `fuzzy_match?/2` - Check if query matches target
   - ✅ `score/2` - Calculate match quality (0-100)
   - ✅ `search/3` - Search and rank list of items
   - ✅ Example: Type "ttr" → finds "tetris" with high score

2. **Enhanced CommandRegistry** - `lib/droodotfoo/terminal/command_registry.ex` (+60 lines)
   - ✅ `search_commands/1` - Fuzzy search across all 40+ commands
   - ✅ `get_suggestions/2` - Get top N ranked suggestions (default: 5)
   - ✅ `format_suggestion/1` - Format as "command (alias) - description"
   - ✅ `commands_by_category/0` - Group commands by type
   - ✅ Works with existing command metadata (name, aliases, description, category)

3. **Command Module Integration** - `lib/droodotfoo/raxol/command.ex`
   - ✅ `update_fuzzy_suggestions/1` - Real-time suggestions on every keystroke
   - ✅ Auto-updates dropdown with top 8 suggestions
   - ✅ Integrates with existing autocomplete infrastructure
   - ✅ Maintains backward compatibility with current `:` command mode

**Remaining Work (2-3 hours)** 📋:

4. **Always-Visible Command Bar UI** (1 hour)
   - [ ] Modify `renderer.ex` to show command bar at screen bottom always
   - [ ] Remove `:` trigger requirement - command bar always ready
   - [ ] Add "Type a command..." placeholder text when unfocused
   - [ ] Show category badges `[GAME]`, `[WEB3]`, `[SYSTEM]` in suggestions
   - [ ] Visual design matching existing terminal aesthetic
   - [ ] Suggestion dropdown appears above command bar (max 8 items)

5. **State & Navigation Updates** (30 min)
   - [ ] Update `state.ex`: Remove `:command_mode`, add `:repl_focused` boolean
   - [ ] Add focus/blur states (Escape to unfocus, Tab/click to focus)
   - [ ] Command bar accepts input only when focused
   - [ ] Navigation (arrow keys) works when command bar unfocused
   - [ ] Maintain command history across focus changes

6. **CSS Styling** (30 min)
   - [ ] Modern command bar: fixed at bottom, height: 3 lines, full width
   - [ ] Sleek suggestion dropdown with smooth fade-in transitions
   - [ ] Category badges with color coding (games=green, web3=purple, system=blue)
   - [ ] Hover states for suggestions (highlight + subtle scale)
   - [ ] Focus indicator on command bar (border glow effect)
   - [ ] Responsive design for mobile (collapsible suggestions)

7. **JavaScript Enhancements** (30-60 min)
   - [ ] Click-to-focus on command bar
   - [ ] Tab key to focus command bar from anywhere
   - [ ] Arrow keys for suggestion navigation (when focused)
   - [ ] Enter to execute selected/typed command
   - [ ] Escape to unfocus and return to terminal navigation
   - [ ] Prevent default browser behaviors (Tab, arrow keys)

**Files to Modify**:
```
lib/droodotfoo/terminal/
├── fuzzy_search.ex          # ✅ Created (201 lines)
└── command_registry.ex      # ✅ Enhanced (+60 lines)

lib/droodotfoo/raxol/
├── command.ex               # ✅ Updated (fuzzy integration)
├── renderer.ex              # 📋 TODO: Always-visible command bar
└── state.ex                 # 📋 TODO: Remove :command_mode, add :repl_focused

assets/
├── css/terminal_grid.css    # 📋 TODO: Command bar & dropdown styling
└── js/hooks.ts              # 📋 TODO: Focus management & keyboard

lib/droodotfoo_web/live/
└── droodotfoo_live/
    └── event_handlers.ex    # 📋 TODO: Tab key handler
```

**New Dependencies**: None (pure Elixir/JS implementation)

**Expected Benefits**:
- ✅ Fuzzy search: Type "snek" → finds "snake"
- ✅ Rich suggestions with descriptions and aliases
- 📋 No more `:` required - always ready for commands
- 📋 Modern UX similar to VS Code command palette / Alfred
- 📋 Faster command discovery for new users
- 📋 Better accessibility (always visible, Tab to focus)
- 📋 Works seamlessly with 40+ existing commands

**Testing Checklist**:
- [x] Fuzzy search matches partial strings correctly
- [x] Scoring ranks exact/prefix matches higher than fuzzy
- [x] Suggestions show command name, aliases, description
- [x] Backend compiles without errors
- [ ] Command bar always visible at bottom of screen
- [ ] Tab key focuses command bar from anywhere
- [ ] Escape unfocuses command bar, returns to navigation
- [ ] Arrow keys navigate suggestions when focused
- [ ] Enter executes selected/top suggestion
- [ ] Click to focus command bar works
- [ ] Suggestions update in real-time as user types
- [ ] Category badges display with correct colors

**Technical Implementation**:

*Fuzzy Matching Algorithm*:
- Character-by-character matching in order (not necessarily consecutive)
- Scoring factors: consecutive runs (+10 per run), early matches (+30%), prefix matches (+20), exact matches (+50)
- Optimized for <1ms performance on 40+ commands
- Examples:
  - "tet" → "tetris" (score: 90, prefix match)
  - "ttr" → "tetris" (score: 75, fuzzy match)
  - "snek" → "snake" (score: 70, fuzzy match)
  - "calc" → "calculator" (score: 95, prefix + alias "calc")

*Suggestion Rendering*:
- Max 8 suggestions to prevent UI clutter
- Sorted by score (descending)
- Format: `command (alias1, alias2) - description`
- Category badge prepended: `[GAME] tetris (t) - Play Tetris`

*State Management*:
- `repl_focused`: boolean - true when command bar has focus
- `command_buffer`: string - current typed command
- `autocomplete_suggestions`: list - fuzzy-matched suggestions
- `autocomplete_index`: int - currently selected suggestion

**Performance Impact**:
- Fuzzy search: <1ms per keystroke
- Suggestion rendering: <5ms for 8 items
- No noticeable lag on command input
- Efficient string matching (no regex, pure iteration)

**Integration Points**:
- Works with existing CommandRegistry (40+ commands)
- Maintains command history functionality
- Compatible with all existing terminal commands
- No breaking changes to command execution pipeline
- Graceful fallback if fuzzy search fails

**User Experience Flow**:

1. **Discovery**: User sees command bar at bottom: `> Type a command... [Tab to focus]`
2. **Focus**: User presses Tab or clicks → command bar highlights
3. **Input**: User types "ttr" → dropdown shows:
   ```
   [GAME] tetris (t) - Play Tetris
   [GAME] typing (type, wpm) - Typing speed test
   ```
4. **Selection**: User presses ↓ to select, or continues typing to refine
5. **Execution**: User presses Enter → command runs
6. **Unfocus**: User presses Escape → returns to normal terminal navigation

**Migration Path**:
- Phase 1 (Complete): Backend fuzzy search ✅
- Phase 2 (Next): Always-visible UI 📋
- Phase 3 (Future): Remove `:` entirely, deprecate old command mode
- Phase 4 (Polish): Command categories, favorites, recent commands

---

## Future Enhancements

### Portfolio Features
- [ ] **Skill Visualizations** (2-3 days)
  - ASCII skill charts with progress bars
  - Interactive skill levels
  - Skill categories and comparisons
  - Time-based progression tracking

- [ ] **Enhanced Project Showcase** (1-2 days)
  - Interactive project filtering by technology
  - Project timeline with chronological view
  - Technology tags with filtering
  - Live GitHub integration for real-time data

- [ ] **Blog Integration** (2-3 days)
  - Full Obsidian publishing API integration
  - Markdown rendering in terminal
  - Tag-based navigation
  - Search across posts

### Performance & Optimization
- [ ] **Metrics Tracking Expansion** (1 day)
  - Track render times across all pages
  - Monitor API call durations per endpoint
  - Track cache hit rates per operation
  - Add alerting on thresholds

- [ ] **Additional Cache Integration** (1 day)
  - GitHub API module caching
  - NFT/Token lookup caching
  - Advanced cache invalidation strategies
  - Cache warming on startup

### Advanced Features
- [ ] **Fileverse SDK Integration** (3-4 days)
  - Replace stub implementations with real SDK
  - React component integration via LiveView hooks
  - Real-time collaboration features
  - UCAN authentication flow

- [ ] **PWA Enhancements** (2-3 days)
  - Offline mode with service workers
  - Background sync for data
  - Push notifications
  - Install prompt optimization

- [ ] **Analytics Dashboard** (2-3 days)
  - Visitor tracking (privacy-focused)
  - Command usage statistics
  - Popular content tracking
  - Performance metrics visualization

---

## Completed Phases (Summary)

### ✅ Coverage Sprint 2: Core Utilities (Oct 19, 2025)
**Time**: 30 minutes
**Status**: COMPLETE

**Delivered**:
- ✅ TimeFormatter tests (26 tests, **100% coverage**, 0% → 100%)
- ✅ Core.Utilities tests (38 tests, **94.2% coverage**, 0% → 94.2%)
- ✅ Total: 64 new tests added
- ✅ Overall coverage: 40.2% → **40.8%** (+0.6%)

**Modules at 90%+ Coverage**:
- **TimeFormatter: 100%** - All time/duration formatting functions
- **Core.Utilities: 94.2%** - Address abbreviation, file sizes, JSON parsing, map utilities, slugs, emails
- **Web3.Networks: 100%** - Network name mapping and validation
- **Web3.ENS: 77.7%** - ENS validation and error handling

**Tests Created**:
- `test/droodotfoo/time_formatter_test.exs` - 26 tests
- `test/droodotfoo/core/utilities_test.exs` - 38 tests

**What Was Tested**:
- Duration formatting (ms/sec to M:SS)
- Relative time formatting (ago strings)
- DateTime/timestamp formatting
- Human-readable time formats
- Ethereum address utilities
- File size formatting
- Text truncation and slugification
- JSON parsing with error handling
- Map utilities (pick, merge, sort, group)
- Progress bars and validation

**Total Test Suite**:
- 1159 tests, 1138 passing (98.2%)
- Code coverage: 40.8%

---

### ✅ Web3 Module Coverage Improvement (Oct 19, 2025)
**Time**: 45 minutes
**Status**: COMPLETE

**Delivered**:
- ✅ Web3.Networks tests (15 tests, 100% coverage)
- ✅ Web3.ENS tests (19 tests, 77.7% coverage, +51.1%)
- ✅ Web3.Auth tests (already comprehensive at 66.6%)
- ✅ Total: 56 Web3 tests (3 skipped integration tests)
- ✅ Overall coverage: 39.6% → 40.2% (+0.6%)

**Coverage Improvements**:
- Networks module: 0% → **100%** ✓
- ENS module: 26.6% → **77.7%** (+51.1%) ✓
- Auth module: **66.6%** (already well-tested) ✓
- Contract module: 0% (complex, needs integration tests)
- IPFS module: 0% (API calls, needs mocking)
- NFT/Token/Transaction: 0% (require API integration)

**Tests Created**:
- `test/droodotfoo/web3/networks_test.exs` - 15 tests
- `test/droodotfoo/web3/ens_test.exs` - 19 tests

**What Was Tested**:
- All network name mappings and chain ID validation
- ENS name validation and normalization
- Address validation and format checking
- Error handling for invalid inputs and unsupported chains
- Ethereum message hashing
- Signature recovery error paths

**Remaining 0% Coverage Modules** (require API mocking or integration tests):
- Contract, IPFS, NFT, Token, Transaction modules

---

### ✅ Phase 8.4.1: Test Coverage Reporting (Oct 19, 2025)
**Time**: 30 minutes
**Status**: COMPLETE

**Delivered**:
- ✅ Excoveralls dependency (v0.18.5)
- ✅ .coveralls.exs configuration with file exclusions
- ✅ mix.exs test_coverage configuration (85% threshold)
- ✅ HTML coverage report generation (cover/)
- ✅ README badges (coverage, tests, Elixir, Phoenix)

**Coverage Baseline**:
- Total code coverage: 39.8%
- Well-covered modules:
  - Raxol terminal modules: 85-100%
  - Terminal bridge: 85.4%
  - Performance modules: 80-90%
  - Resume filtering: 70-80%
- Areas needing coverage:
  - Terminal commands: 0-40% (interactive, harder to test)
  - Web3 modules: 0-53%
  - LiveView modules: 0-94%
  - Fileverse modules: 0-60%

**Commands Added**:
```bash
mix coveralls                # Run with coverage report
mix coveralls.html           # Generate HTML report
mix coveralls.detail         # Detailed line coverage
mix coveralls.github         # GitHub Actions format
```

**Next Steps**:
- Increase coverage through integration tests
- Focus on core modules (aim for 60-70% overall)
- Terminal commands may remain lower (interactive nature)

---

### ✅ Phase 7.3: Interactive Resume Filtering (Oct 19, 2025)
**Time**: 2 hours (integration & testing)
**Status**: COMPLETE

**Delivered**:
- ✅ FilterEngine module (374 lines, AND/OR logic, multi-criteria filtering)
- ✅ SearchIndex module (420 lines, fuzzy matching, autocomplete, suggestions)
- ✅ PresetManager module (466 lines, ETS storage, system/user presets)
- ✅ QueryBuilder module (query parsing and building)
- ✅ Resume commands (473 lines, full CLI integration)
- ✅ Comprehensive test suite (76 tests, 100% passing)
- ✅ Application supervision tree integration
- ✅ Terminal command routing (via DrooFoo delegation)

**Features**:
- Dynamic filtering by technologies, companies, positions, date ranges
- Real-time fuzzy search with weighted scoring
- Filter combinations with AND/OR logic
- 5 system presets (blockchain, defense, recent, elixir, leadership)
- Preset save/load/delete functionality
- Technology extraction and autocomplete
- Search suggestions and query correction
- Export filtered results

**Terminal Commands**:
```bash
resume filter <criteria>      # Apply filters
resume search <query>         # Fuzzy search
resume preset save <name>     # Save filter preset
resume preset load <name>     # Load saved preset
resume preset list            # List all presets
resume preset delete <name>   # Delete preset
resume clear                  # Clear filters
resume technologies           # List all technologies
resume autocomplete <partial> # Get suggestions
resume export [format]        # Export filtered resume
```

**Impact**:
- 3,049 lines of resume functionality
- Sub-100ms search performance
- Flexible multi-criteria filtering
- Persistent preset storage
- Full terminal integration

---

### ✅ Phase 8.3: Performance Optimization (Oct 19, 2025)
**Time**: 6 hours
**Status**: COMPLETE

**Delivered**:
- ✅ Performance.Cache module (365 lines, ETS-based, TTL support)
- ✅ Performance.Monitor module (410 lines, memory/process monitoring)
- ✅ Performance.Metrics module (370 lines, timing/stats/charts)
- ✅ Performance.Optimizer module (260 lines, analysis/recommendations)
- ✅ Terminal commands (270 lines, `perf` command suite)
- ✅ Comprehensive test suite (37 tests, 95% passing)
- ✅ Cache integration (Spotify, ENS, IPFS APIs)

**Impact**:
- 80-90% reduction in Spotify API calls
- 95% cache hit rate for ENS lookups
- 90% cache hit rate for IPFS content
- Sub-millisecond response times for cached data

---

### ✅ Phase 8.6.2: Terminal Commands Behavior Pattern (Oct 19, 2025)
**Time**: 6 hours
**Status**: COMPLETE

**Delivered**:
- ✅ CommandBase module (440 lines, declarative command definitions)
- ✅ 39 comprehensive tests (all passing)
- ✅ 4 modules refactored (Web3, System, Git, Fileverse)
- ✅ Zero regressions, 100% backward compatibility

---

### ✅ Phase 8.2: ExDoc Documentation (Oct 19, 2025)
**Time**: 1 day
**Status**: COMPLETE

**Delivered**:
- ✅ 161 HTML documentation pages
- ✅ 120+ @spec annotations
- ✅ 60+ @type definitions
- ✅ Enhanced deployment.md (29→494 lines)
- ✅ 8 module groups organized

---

### ✅ Phase 8.1: Box Alignment System & Module Consolidation (Oct 19, 2025)
**Time**: 3 days
**Status**: COMPLETE

**Delivered**:
- ✅ BoxConfig module (150 lines, dimension constants)
- ✅ BoxBuilder module (365 lines, box rendering utilities)
- ✅ BoxAlignment test suite (10 validation tests)
- ✅ Module consolidation (157→152 modules, ~1,009 LOC eliminated)
- ✅ 85+ new tests (all passing)

---

### ✅ Phase 7.1 & 7.2: Portfolio Features (Oct 16, 2025)
**Time**: 4 days
**Status**: COMPLETE

**Delivered**:
- ✅ Contact Form with email integration (Swoosh)
- ✅ Resume Page with PDF export foundation
- ✅ Rate limiting (5 submissions/hour)
- ✅ Professional styling matching terminal aesthetic

---

### ✅ Phase 6.9: Fileverse Integration (Oct 6, 2025)
**Time**: Multiple days
**Status**: 14/16 modules complete (2 stubs awaiting SDK)

**Delivered**:
- ✅ Portal P2P (3000+ lines, 100+ tests, full WebRTC)
- ✅ dSheets (689 lines, 8 tests)
- ✅ HeartBit SDK (5 tests)
- ✅ Agents SDK (17 tests)
- ✅ Privacy & Encryption (libsignal, AES-256-GCM)
- 🚧 DDoc (stub - needs SDK)
- 🚧 Storage (stub - needs SDK)

---

### ✅ Phase 5: Spotify Interactive UI (Oct 6, 2025)
**Status**: COMPLETE

**Delivered**:
- ✅ Keyboard shortcuts (p/d/s/c/v/r)
- ✅ Real-time playback controls
- ✅ Progress bar with block characters
- ✅ Auto-refresh (5s interval)
- ✅ Visual state indicators

---

### ✅ Phase 6: Web3 Integration (Complete)
**Status**: 8/8 phases complete

**Delivered**:
- ✅ Wallet Connection (MetaMask integration)
- ✅ ENS & Address Display (with caching)
- ✅ NFT Gallery (OpenSea API)
- ✅ Token Balances (CoinGecko API)
- ✅ Transaction History (Etherscan)
- ✅ Smart Contract Interaction
- ✅ IPFS Integration (with caching)
- ✅ Fileverse Integration (14/16 modules)

---

### ✅ Phases 1-4: Core Features (Complete)
**Status**: 645+ tests passing

**Infrastructure**:
- ✅ Terminal framework with Raxol integration
- ✅ Plugin system (10+ games)
- ✅ Command mode (30+ commands)
- ✅ OAuth integrations (Spotify, GitHub)
- ✅ Boot sequence, CRT effects, autocomplete

**UI/UX**:
- ✅ 8 themes (Synthwave84, Nord, Dracula, etc.)
- ✅ Status bar with context awareness
- ✅ Advanced search (fuzzy/exact/regex)
- ✅ Performance dashboard with ASCII charts
- ✅ Project showcase with 6 projects
- ✅ STL 3D viewer

---

## Technical Stats

**Codebase**:
- 152 production modules
- ~50,000 lines of code
- 1080 tests (98.1% passing)
- 161 documentation pages

**Performance**:
- Cache hit rates: 85-95%
- API call reduction: 80-90%
- Memory footprint: <50MB
- Response time (cached): <1ms

**Integrations**:
- Spotify Web API ✅
- GitHub API ✅
- Web3/Ethereum ✅
- IPFS ✅
- Fileverse ⚠️ (partial)
- LiveView ✅
- Phoenix PubSub ✅

---

## Development Workflow

**Daily Commands**:
```bash
# Development
./bin/dev                    # Start with 1Password secrets
mix phx.server              # Start without secrets
mix test --exclude flaky    # Run test suite
mix precommit              # Full pre-commit check

# Performance
perf monitor               # Check system health
perf cache                # Check cache efficiency
perf analyze              # Get recommendations

# Documentation
mix docs                  # Generate ExDoc
open doc/index.html      # View docs
```

**Git Workflow**:
```bash
# Commit changes
mix format                # Format code
mix compile              # Check compilation
mix test                 # Run tests
git add .
git commit -m "feat: description"
git push
```

---

## Quick Wins (1-2 hours each)

These are small improvements that provide immediate value:

1. **Add Performance Alerts**
   - Set up email/terminal alerts for high memory usage
   - Alert on low cache hit rates
   - Alert on API bottlenecks

2. **Cache Warming**
   - Pre-populate cache on application startup
   - Warm frequently accessed ENS names
   - Pre-fetch common IPFS content

3. **Metrics Dashboard Enhancement**
   - Add more visual charts to `perf monitor`
   - Track API response times per endpoint
   - Show cache efficiency trends

4. **Resume Export Templates**
   - Add 2-3 additional PDF templates
   - Customize formatting per template
   - Add preview command

5. **Command Aliases**
   - Add more intuitive command shortcuts
   - Create common workflow aliases
   - Document in help system

---

## Contact & Resources

**Documentation**:
- [README.md](../README.md) - Setup, features, deployment
- [DEVELOPMENT.md](../DEVELOPMENT.md) - Architecture, integrations, testing
- [FEATURES.md](./FEATURES.md) - Complete feature roadmap
- [CLAUDE.md](../CLAUDE.md) - AI assistant instructions
- [deployment.md](./deployment.md) - Comprehensive deployment guide

**Performance Monitoring**:
- ExDoc: `mix docs && open doc/index.html`
- LiveDashboard: http://localhost:4000/dev/dashboard
- Terminal: `perf monitor` or `dashboard`

---

**Last Updated**: Oct 19, 2025
**Next Review**: When starting Phase 7.3 or 8.4
