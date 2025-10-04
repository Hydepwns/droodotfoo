# Raxol Framework Feedback

**Project:** droo.foo Terminal Portfolio
**Raxol Version:** 1.4.1 (not actively used at runtime)
**Integration:** Custom implementation inspired by Raxol concepts
**Date:** October 2025

## Executive Summary

While building a Phoenix LiveView terminal portfolio, we included Raxol as a dependency but ultimately **built our own terminal rendering system** without using Raxol's framework features. This document explains why and provides actionable feedback for improving Raxol adoption.

## Current State

### What We Built (Without Using Raxol)

```elixir
# Our custom implementation
lib/droodotfoo/
  raxol/
    state.ex          # Custom state management
    renderer.ex       # Custom buffer-to-content renderer
    navigation.ex     # Vim-style navigation
    command.ex        # Command mode handling
  raxol_app.ex        # GenServer orchestrator
  terminal_bridge.ex  # Buffer-to-HTML conversion
```

### Raxol Usage in mix.exs

```elixir
{:raxol, "~> 1.4.1", runtime: false}
```

**Key Finding:** Raxol is a **compile-time dependency only** - we don't use any Raxol modules at runtime.

## Why We Didn't Use Raxol's Features

### 1. **Phoenix LiveView Integration Gap**

**Problem:** Raxol's examples focus on native terminal apps, not LiveView integration.

**What We Needed:**
- Direct buffer-to-HTML rendering (no terminal emulator)
- LiveView event handling (keyboard, mouse, resize)
- Stateless server-side rendering with client updates via WebSocket

**What Raxol Provides:**
- Component-based terminal UI (React/Svelte/LiveView-style)
- VT100/ANSI terminal emulation
- Native terminal rendering (not web rendering)

**Suggestion:**
- Add first-class Phoenix LiveView integration guide
- Provide `Raxol.LiveView` helpers for buffer-to-HTML
- Document stateless vs stateful rendering patterns
- Show how to handle LiveView events → Raxol state updates

### 2. **Complexity vs Simplicity**

**Problem:** For our use case, Raxol's full framework was overkill.

**Our Approach:**
```elixir
# Simple buffer structure
%{
  lines: [
    %{cells: [%{char: "H", style: %{fg_color: :green}}]},
    %{cells: [%{char: "i", style: %{}}]}
  ],
  width: 80,
  height: 24
}
```

**Raxol's Approach:**
```elixir
# Component-based with lifecycle, state management, etc.
use Raxol.Component
def render(assigns) do
  ~H"""
  <Box><Text>Hello</Text></Box>
  """
end
```

**Suggestion:**
- Provide a "Raxol.Simple" or "Raxol.Core" subset
- Export just the buffer/renderer without components
- Make framework features opt-in, not all-or-nothing

### 3. **Documentation Focus**

**Problem:** Raxol docs emphasize enterprise features, not basics.

**What We Found in README:**
- Enterprise audit logging, SAML/OIDC, compliance
- Sixel graphics, GPU acceleration
- Multi-framework support (React/Svelte/LiveView)

**What We Needed:**
- "Buffer format and rendering 101"
- "Phoenix LiveView + Raxol quickstart"
- "Character-perfect grid layout guide"
- "Performance: caching and diffing strategies"

**Suggestion:**
- Add "Core Concepts" section before enterprise features
- Create minimal examples (20 lines, not full apps)
- Document buffer format as the foundational primitive
- Show performance optimization patterns upfront

### 4. **Missing Incremental Adoption Path**

**Problem:** No clear path from "simple buffer" → "full framework".

**Our Journey:**
1. Started with basic buffer rendering ✅
2. Added state management (custom) ✅
3. Added navigation (custom Vim bindings) ✅
4. Added command mode (custom parser) ✅
5. Never found a reason to integrate Raxol components ❌

**Suggestion:**
- Create migration guides: "From DIY to Raxol Components"
- Show how to wrap existing buffer code in Raxol
- Provide adapters for custom state → Raxol state
- Make each Raxol feature independently adoptable

## What We Liked (Conceptually)

Even though we didn't use Raxol, the **concepts** influenced our design:

1. **Buffer-based architecture** - Clean separation of state and rendering
2. **Cell structure** - `%{char: "", style: %{}}` is perfect
3. **Reducer pattern** - Functional state updates
4. **Performance focus** - Caching, diffing, optimization built-in

These are solid foundations. The issue is **accessibility**, not the architecture.

## Concrete Improvements for Raxol

### Priority 1: Phoenix LiveView Integration

**Add to Raxol v1.5+:**

```elixir
# New module: Raxol.LiveView
defmodule MyAppLive do
  use Phoenix.LiveView
  use Raxol.LiveView  # <-- New helper

  def mount(_params, _session, socket) do
    buffer = Raxol.Buffer.new(80, 24)
    {:ok, assign(socket, buffer: buffer)}
  end

  def handle_event("key", %{"key" => key}, socket) do
    buffer = Raxol.Input.handle_key(socket.assigns.buffer, key)
    {:noreply, assign(socket, buffer: buffer)}
  end

  def render(assigns) do
    ~H"""
    <div phx-window-keydown="key">
      <%= Raxol.LiveView.render_buffer(@buffer) %>
    </div>
    """
  end
end
```

**Benefits:**
- Developers can use Raxol buffers without adopting the full framework
- Clear integration point with Phoenix
- Instant value for LiveView users

### Priority 2: Simplify Entry Point

**Current (complex):**
```elixir
use Raxol.UI, framework: :react
use Raxol.Component
def render(assigns), do: ~H"""..."""
```

**Proposed (simple):**
```elixir
# Option A: Just buffers
alias Raxol.Buffer
buffer = Buffer.new(80, 24)
buffer = Buffer.write(buffer, 0, 0, "Hello", fg: :green)

# Option B: Functional helpers
import Raxol.Helpers
buffer |> clear() |> write_line(0, "Hello") |> box(10, 5, 30, 10)
```

**Then graduate to components when ready:**
```elixir
use Raxol.Component  # Opt-in to component system
```

### Priority 3: Restructure Documentation

**Proposed doc structure:**

```markdown
# Raxol Documentation

## Getting Started
1. Core Concepts (Buffer, Cell, Style)
2. Basic Rendering (20-line examples)
3. Phoenix LiveView Integration
4. State Management Patterns

## Framework Features (Opt-In)
1. Components (React/Svelte/LiveView patterns)
2. Advanced Rendering (Sixel, GPU)
3. Input Handling & Events

## Enterprise Features
1. Audit Logging
2. Security (SAML/OIDC)
3. Compliance & Regulations
```

### Priority 4: Performance Cookbook

**We implemented these ourselves - should be in Raxol:**

1. **Buffer Diffing:**
   ```elixir
   # Only re-render changed lines
   Raxol.Diff.patch(old_buffer, new_buffer)
   ```

2. **Cell Caching:**
   ```elixir
   # Cache common char + style combinations
   Raxol.Cache.cell({char, style})
   ```

3. **Escape Pooling:**
   ```elixir
   # Pre-escaped HTML entities
   Raxol.HTML.escape("&") # => "&amp;" (cached)
   ```

4. **Adaptive Rendering:**
   ```elixir
   # Skip render if buffer unchanged
   if Raxol.Buffer.dirty?(buffer), do: render()
   ```

**Add these as `Raxol.Performance.*` modules with examples.**

### Priority 5: Framework Agnostic Core

**Extract core from frameworks:**

```elixir
# Current (all frameworks included)
{:raxol, "~> 1.4.1"}

# Proposed (modular)
{:raxol_core, "~> 1.5"}       # Buffer, rendering only
{:raxol_components, "~> 1.5"}  # Component system
{:raxol_liveview, "~> 1.5"}    # Phoenix integration
{:raxol_enterprise, "~> 1.5"}  # Audit, compliance, etc.
```

Or use compile-time config:
```elixir
{:raxol, "~> 1.5", only: [:core, :liveview]}
```

## What We'd Pay For

If Raxol offered these improvements, we'd **actively use it** instead of maintaining custom code:

### Must-Have
- [x] `Raxol.Buffer` module (simple buffer create/write/read)
- [x] `Raxol.LiveView` helper (buffer → HTML, keyboard events)
- [x] Clear docs on Phoenix integration
- [x] Performance helpers (diff, cache, escape)

### Nice-to-Have
- [ ] Pre-built components (Box, Text, List, Table)
- [ ] Vim navigation helpers (hjkl, gg, G, etc.)
- [ ] Command palette / search
- [ ] Theme system

### Future
- [ ] Collaborative terminal sessions
- [ ] Time-travel debugging
- [ ] Terminal recording/replay

## Test Coverage & Reliability

**Our Experience:**
- Built 433 tests for our custom implementation
- 100% test pass rate
- Zero compilation warnings
- No Raxol bugs (because we didn't use it!)

**Raxol's Claims:**
- 4,361 tests
- 98.7% coverage
- 3.3μs parser performance

**Gap:** Great framework quality, but adoption barriers prevent us from experiencing it.

## Conclusion

**Raxol is impressive**, but its enterprise-first positioning and component-heavy approach created friction for our use case. We needed:

1. Simple buffer primitives
2. Phoenix LiveView helpers
3. Incremental adoption path

Instead, we found:

1. Full framework commitment
2. Native terminal focus (not web)
3. Enterprise features upfront

### Recommendation for Raxol Team

**Ship Raxol v1.5 with "Raxol.Core":**
- Minimal buffer/rendering library
- Phoenix LiveView integration
- Clear upgrade path to full framework
- "Getting Started" docs rewritten for simplicity

This would make Raxol **the default choice** for terminal UIs in Elixir, rather than a niche solution for enterprise terminal apps.

---

## Our Offer

We've built a production-ready terminal system with:
- Custom buffer rendering
- Phoenix LiveView integration
- Performance optimizations (caching, diffing)
- 433 passing tests

**We're happy to:**
1. Contribute our Phoenix LiveView integration to Raxol
2. Help design `Raxol.Core` minimal API
3. Write "Phoenix + Raxol" getting started guide
4. Provide real-world use case feedback

If interested, contact: drew@droo.foo

---

**Bottom Line:** Raxol has the right architecture but needs simpler on-ramps. Make the core primitives easy to adopt, and the framework features will follow naturally.
