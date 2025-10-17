# Codebase Complexity Analysis Report

**Generated:** 2025-10-16 20:24:39.932128Z
**Threshold:** 600 lines per file
**Total Files:** 161
**Files Over Threshold:** 10

## Executive Summary

- **Total Lines of Code:** 49880
- **Average Lines per File:** 309
- **Total Functions:** 2213
- **Files Over 600 Lines:** 10 (6.2%)


## Files Requiring Refactoring (10)

| Priority | File | Lines | Functions | Sections | Over By |
|----------|------|-------|-----------|----------|----------|
| 🔴🔴🔴 1 | `lib/droodotfoo/terminal/commands.ex` | 3938 | 280 | 54 | +3338 |
| 🔴 2 | `lib/droodotfoo/raxol/renderer.ex` | 1760 | 87 | 13 | +1160 |
| 🟡 3 | `lib/droodotfoo_web/live/droodotfoo_live.ex` | 1006 | 85 | 11 | +406 |
| 🟢 4 | `lib/droodotfoo/plugins/wordle.ex` | 796 | 17 | 2 | +196 |
| 🟢 5 | `lib/droodotfoo/fileverse/portal/transfer.ex` | 714 | 19 | 1 | +114 |
| 🟢 6 | `lib/droodotfoo/fileverse/portal.ex` | 712 | 23 | 3 | +112 |
| 🟢 7 | `lib/droodotfoo/fileverse/dsheet.ex` | 667 | 31 | 1 | +67 |
| 🟢 8 | `lib/droodotfoo/spotify.ex` | 613 | 37 | 3 | +13 |
| 🟢 9 | `test/droodotfoo/plugin_system_test.exs` | 610 | 0 | 4 | +10 |
| 🟢 10 | `test/droodotfoo/raxol/renderer_test.exs` | 610 | 2 | 1 | +10 |

## Refactoring Recommendations

Focus on these high-priority files first:

### 1. commands.ex (3938 lines)

**Strategy:** Split by command categories (54 sections detected)
- Create `Commands.Navigation`, `Commands.FileOps`, `Commands.Web3`, etc.
- Each module should have < 300 lines
- Use `defdelegate` in main Commands module for backward compatibility


### 2. renderer.ex (1760 lines)

**Strategy:** Extract rendering concerns
- `Renderer.Core` - main render loop
- `Renderer.Sections` - section-specific renderers
- `Renderer.Components` - reusable UI components
- `Renderer.Formatting` - text formatting utilities


### 3. droodotfoo_live.ex (1006 lines)

**Strategy:** Extract LiveView concerns
- Move event handlers to separate module
- Extract state processing logic
- Create dedicated action modules (Web3, Spotify, STL)




## All Files Sorted by Complexity

| File | Lines | Functions | Status |
|------|-------|-----------|--------|
| `lib/droodotfoo/terminal/commands.ex` | 3938 | 280 | 🔴 Refactor |
| `lib/droodotfoo/raxol/renderer.ex` | 1760 | 87 | 🔴 Refactor |
| `lib/droodotfoo_web/live/droodotfoo_live.ex` | 1006 | 85 | 🔴 Refactor |
| `lib/droodotfoo/plugins/wordle.ex` | 796 | 17 | 🔴 Refactor |
| `lib/droodotfoo/fileverse/portal/transfer.ex` | 714 | 19 | 🔴 Refactor |
| `lib/droodotfoo/fileverse/portal.ex` | 712 | 23 | 🔴 Refactor |
| `lib/droodotfoo/fileverse/dsheet.ex` | 667 | 31 | 🔴 Refactor |
| `lib/droodotfoo/spotify.ex` | 613 | 37 | 🔴 Refactor |
| `test/droodotfoo/plugin_system_test.exs` | 610 | 0 | 🔴 Refactor |
| `test/droodotfoo/raxol/renderer_test.exs` | 610 | 2 | 🔴 Refactor |
| `lib/droodotfoo/terminal_bridge.ex` | 584 | 35 | ✅ OK |
| `lib/droodotfoo/plugins/github.ex` | 545 | 37 | ✅ OK |
| `lib/droodotfoo/resume/pdf_generator.ex` | 543 | 11 | ✅ OK |
| `lib/droodotfoo/fileverse/agent.ex` | 536 | 11 | ✅ OK |
| `lib/droodotfoo/fileverse/portal/encryption.ex` | 523 | 17 | ✅ OK |
| `lib/droodotfoo/plugin_system.ex` | 511 | 20 | ✅ OK |
| `test/droodotfoo_web/live/droodotfoo_live_test.exs` | 511 | 1 | ✅ OK |
| `lib/droodotfoo/ascii_chart.ex` | 509 | 49 | ✅ OK |
| `lib/droodotfoo/terminal/command_parser.ex` | 502 | 19 | ✅ OK |
| `test/droodotfoo/raxol_app_test.exs` | 502 | 1 | ✅ OK |

## Detailed File Analysis

### 1. commands.ex

**Path:** `lib/droodotfoo/terminal/commands.ex`
**Lines:** 3938
**Functions:** 280 (210 public, 70 private)
**Complexity Score:** 10078

**Detected Sections (54):**
- Navigation Commands
- File Operations
- System Info
- Help & Documentation
- Utility Commands
- Fun Commands
- droo.foo Specific Commands
- Git commands (simulated)
- Package managers
- Network commands
- File management
- Easter eggs
- Plugin commands
- Plugin launch commands (consolidated pattern)
- Web3 commands
- ENS resolution command
- NFT commands
- Alias for nft list
- Token balance commands
- Balance command for specific token price
- Alias for tokens list
- Transaction history commands
- Alias for tx history
- Contract commands
- call command - shorthand for contract function calls
- IPFS commands
- Fileverse dDocs commands
- docs command - alias for ddoc list
- Fileverse Storage commands
- files command - list uploaded files
- file command - file operations
- Fileverse Portal commands
- Enhanced Portal UI Helper Functions
- Project commands
- API commands
- Search command
- Helper functions
- Plugin launch helper (consolidates repetitive pattern)
- Theme Commands
- Performance & Monitoring Commands
- CRT Effects Command
- High Contrast Mode Command
- Accessibility alias
- Encryption Commands
- dSheets Commands
- Alias for sheet list
- Site Tree Visualizer
- HeartBit Commands
- Agent Commands
- Helper functions for Agent commands
- Helper functions for HeartBit commands
- Helper function for truncating strings
- Resume Export Commands
- Contact Form Commands

**Refactoring Strategy:**
This file has 54 logical sections that can be extracted into separate modules.


---

### 2. renderer.ex

**Path:** `lib/droodotfoo/raxol/renderer.ex`
**Lines:** 1760
**Functions:** 87 (1 public, 86 private)
**Complexity Score:** 3630

**Detected Sections (13):**
- Helper function to reduce repetition in drawing boxes
- Content drawing functions
- Helper function for building unified home display
- Spotify helper functions
- Project view helper functions
- Draw the project list view with thumbnails
- Draw a row of projects (up to 2 projects side by side)
- Draw a single project card with thumbnail
- Draw the detailed project view
- Build the detailed view lines for a project
- Terminal view helper functions
- Web3 helper functions
- Portal P2P Enhanced UI Functions

**Refactoring Strategy:**
This file has 13 logical sections that can be extracted into separate modules.


---

### 3. droodotfoo_live.ex

**Path:** `lib/droodotfoo_web/live/droodotfoo_live.ex`
**Lines:** 1006
**Functions:** 85 (22 public, 63 private)
**Complexity Score:** 2816

**Detected Sections (11):**
- Catch-all for unexpected messages to prevent crashes
- STL Viewer event handlers (from hook)
- Handle Web3 wallet connection success from JavaScript hook
- Schedule next tick based on adaptive refresh rate
- Helper to convert section atoms to breadcrumb paths
- Screen reader announcements for section changes
- Handle STL viewer actions from keyboard
- Handle Spotify actions from keyboard
- Handle Web3 actions
- Render boot sequence to HTML
- Configuration function for switching between terminal bridges

**Refactoring Strategy:**
This file has 11 logical sections that can be extracted into separate modules.


---

### 4. wordle.ex

**Path:** `lib/droodotfoo/plugins/wordle.ex`
**Lines:** 796
**Functions:** 17 (9 public, 8 private)
**Complexity Score:** 1156

**Detected Sections (2):**
- Common 5-letter words for the game
- Private helper functions

**Refactoring Strategy:**
This file has 2 logical sections that can be extracted into separate modules.


---

### 5. transfer.ex

**Path:** `lib/droodotfoo/fileverse/portal/transfer.ex`
**Lines:** 714
**Functions:** 19 (13 public, 6 private)
**Complexity Score:** 1104

**Detected Sections (1):**
- Private helper functions

**Refactoring Strategy:**
This file has 1 logical sections that can be extracted into separate modules.


---

### 6. portal.ex

**Path:** `lib/droodotfoo/fileverse/portal.ex`
**Lines:** 712
**Functions:** 23 (18 public, 5 private)
**Complexity Score:** 1202

**Detected Sections (3):**
- Private helpers
- Enhanced UI Integration Methods
- Private helper functions

**Refactoring Strategy:**
This file has 3 logical sections that can be extracted into separate modules.


---

### 7. dsheet.ex

**Path:** `lib/droodotfoo/fileverse/dsheet.ex`
**Lines:** 667
**Functions:** 31 (9 public, 22 private)
**Complexity Score:** 1297

**Detected Sections (1):**
- Private Functions

**Refactoring Strategy:**
This file has 1 logical sections that can be extracted into separate modules.


---

### 8. spotify.ex

**Path:** `lib/droodotfoo/spotify.ex`
**Lines:** 613
**Functions:** 37 (34 public, 3 private)
**Complexity Score:** 1383

**Detected Sections (3):**
- Type definitions
- Server Callbacks
- Private Functions

**Refactoring Strategy:**
This file has 3 logical sections that can be extracted into separate modules.


---

### 9. plugin_system_test.exs

**Path:** `test/droodotfoo/plugin_system_test.exs`
**Lines:** 610
**Functions:** 0 (0 public, 0 private)
**Complexity Score:** 650

**Detected Sections (4):**
- Test plugin module that properly implements the behaviour
- Plugin without optional handle_key callback
- Module that doesn't implement the behaviour
- Plugin that crashes on init

**Refactoring Strategy:**
This file has 4 logical sections that can be extracted into separate modules.


---

### 10. renderer_test.exs

**Path:** `test/droodotfoo/raxol/renderer_test.exs`
**Lines:** 610
**Functions:** 2 (0 public, 2 private)
**Complexity Score:** 660

**Detected Sections (1):**
- Helper functions

**Refactoring Strategy:**
This file has 1 logical sections that can be extracted into separate modules.


---

