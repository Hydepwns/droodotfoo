---
title: "Building DROO.FOO: Module 1 Content Infrastructure."
date: "2025-01-18"
description: "I am building my gundam slowly, one module at a time."
author: "DROO AMOR"
tags: ["elixir", "phoenix", "architecture", "systems"]
slug: "building-droo-foo"
---

<div class="post-pattern-header">
  <object data="/patterns/building-droo-foo?animate=true" type="image/svg+xml" style="width: 100%; height: 300px; display: block;">
    <img src="/patterns/building-droo-foo" alt="Generative pattern for building-droo-foo" style="width: 100%; height: 300px; object-fit: cover;" />
  </object>
</div>

# Module 1: Proof of Architecture

Like building a gundam—one module at a time, each proving the system before the next ships.

This site is Module 1. If the content system isn't modular, [mana](/projects#mana) won't be. If the monospace grid breaks here, it breaks in [raxol](/projects#raxol). If patterns can't handle blog posts, they can't handle validator dashboards.

**The stack:** Phoenix 1.8 + LiveView, MDEx, file-based content, deterministic SVG generation
**The test:** Character-perfect terminal grid across browsers
**The workflow:** Obsidian/Zed → API → Live

---

## The Constraints

The architecture must satisfy:

- **Monospace terminal interface** with character-perfect grid alignment
- **No layout shifts** or font rendering surprises across browsers
- **Highly portable** — minimal dependencies, file-based data
- **Accessibility first** — WCAG compliance, proper ARIA, screen reader support
- **[Raxol](/projects#raxol) compatibility** — terminal framework uses same rendering

Additionally, it must pass the "squint test": visible monospace grid with precise character spacing, highly optimized for legibility and visual rhythm.

We addressed font constraints quickly using the [monaspace font family](https://monaspace.githubnext.com/). Monaspace provides texture healing—a feature that adjusts letter spacing dynamically to create visually even text density while maintaining strict monospace alignment. Perfect for our character-perfect grid requirements.

**Character-perfect grid alignment became the first real problem.**

CSS handles 1ch units differently across browsers. Safari rendered 1ch at ~0.1ch wider than Chrome—enough to break alignment after 80 characters.

---

## Pattern Generation: Reproducible Art

Every post needs a visual. Manual design doesn't scale, and the site looked too stark without imagery.

Solution: deterministic pattern generation. Hash the slug, seed the RNG, generate SVG. Reproducible, cacheable, zero manual work.

We chose to use functional programming patterns idiomatic to the Elixir language. Partially because writing dynamic programs and using imperative patterns gives me existential dread.

```elixir
def generate_svg(slug, opts \\ []) do
  # Hash the slug to get a deterministic seed
  seed = :erlang.phash2(slug)
  :rand.seed(:exsplus, {seed, seed, seed})

  # Choose style based on slug hash
  style = choose_style(slug)
  generate_pattern(style, opts)
end
```

Eight basic pattern styles for now— the slug hash determines which one. No database, no storage, just deterministic math. See all at [/patterns](/patterns).

This infrastructure now is reusable. Any content—posts, projects, validator dashboards—gets deterministic artwork with the same code. Moving along...

## Phoenix LiveView: The Runtime

Phoenix LiveView handles server-side rendering and real-time updates without JavaScript bloat. Components are pure functions: data in, UI out.

```elixir
def render(assigns) do
  ~H"""
  <.page_layout title={@post.title}>
    <.pattern slug={@post.slug} />
    <.content markdown={@post.content} />
  </.page_layout>
  """
end
```

## File-Based Content: Data as Files

No database. Git for version control, `resume.json` as the data source. Posts are markdown with YAML frontmatter. Files version naturally, backups are trivial, migration is straightforward.

Projects pull from resume data:

```elixir
def all do
  resume = ResumeData.get_resume_data()

  # Defense and portfolio projects handled uniformly
  defense = convert_defense_projects(resume[:defense_projects])
  portfolio = convert_portfolio_projects(resume[:portfolio][:projects])

  portfolio ++ defense
end
```

Pattern matching transforms data shapes. Defense and portfolio projects become the same struct. No if/else, no type checking—just data transformation.

## Obsidian → Web: Terminal Workflow

I write in [Obsidian](https://obsidian.md/) or [Zed](https://zed.dev/). The API endpoint accepts markdown and writes to `priv/posts/slug.md`:

```bash
# From Obsidian, run via plugin or script:
curl -X POST https://droo.foo/api/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -d '{
    "content": "# My Post\n\nContent here",
    "metadata": {
      "title": "My Post",
      "description": "Post description",
      "tags": ["elixir"]
    }
  }'
```

No GUI, no admin panel. The endpoint extends to any content type.

### Security Implementation

Three layers of defense: bearer token authentication, IP-based rate limiting (10/hour, 50/day), and content validation (path traversal prevention, slug sanitization, 1MB max). No token bypass—endpoint returns 401 if unconfigured.

See [`CLAUDE.md`](/CLAUDE.md#blog-post-api-security) for implementation details and usage examples.

---

## What Broke (And How We Fixed It)

Implementation collides with reality. Here's what broke, ordered by severity:

### CSS Precision Crisis

**Safari** rendered 1ch at *~0.1ch* wider than **Chrome**—enough to misalign the grid after 80 characters.
**Firefox** had different quirks with `font-feature-settings`.

**Why this mattered:** The monospace grid isn't aesthetic—it's __architectural__. If the grid breaks here, Raxol breaks. The terminal framework depends on character-perfect alignment.

The fix:
1. `font-feature-settings: 'liga' 0, 'calt' 0` to disable ligatures
2. CSS cascade control—no inherited text transforms or letter spacing
3. JavaScript validation on resize to lock the grid

Not sexy, but necessary. The monospace grid became our agalma—not just aesthetic preference, but the idealized constraint that drives every architectural decision. If this foundation breaks, everything built on it collapses.

Next step: write tests for more browsers (Ladybird, Edge, terminal browsers) and observe rendering execution.

### GitHub API Rate Limiting

The API allows 60 requests/hour without authentication. With 10+ projects, each page load exhausted the limit after one visitor.

Built a caching layer with ETS (Erlang's in-memory key-value store). One GenServer fetches data on startup, caches it, refreshes hourly. Cache hit rate after warmup: 98%.

**Pros:** No external dependencies, no token management, instant response times.
**Cons:** Single-server state. Future: distributed cache or authenticated API calls.

### Pattern Generation Iterations

Pattern generation went through three iterations. Version three was a complete refactor:
1. Each pattern type became its own module
2. Pattern selection used pattern matching on hash ranges
3. SVG builder became a pure function—same input, same output, every time

**Result:** Pattern generation dropped from ~15ms to <5ms.

### Accessibility: The Hidden Complexity

**ARIA roles conflicting with semantic HTML.** Terminal grids don't map cleanly to web semantics. The terminal is a grid of cells *and* a dynamic application. Screen readers expected one thing, the DOM provided another.

**Why this mattered:** Claiming accessibility as a first-class constraint means nothing if screen readers can't navigate the interface or keyboard users get trapped in the grid.

Two-part problem:

1. **Structure:** Terminal cells needed proper ARIA roles without breaking semantic HTML. Grid must be navigable but not chatty.
2. **Updates:** LiveView pushes updates constantly. Screen readers needed to know *when* content changed without announcing every cell modification.

The fix:
1. **Roving tabindex** for keyboard navigation—only one focusable element at a time, arrow keys move focus
2. **`aria-live="polite"`** regions for terminal output—screen readers announce new content without interrupting
3. **Semantic grouping** with proper role hierarchy—terminal as application, grid structure underneath

Not perfect yet. Still testing with NVDA, VoiceOver, and JAWS. But navigable and usable—the baseline is met.

## The Final Numbers

**Pattern generation:** <5ms per SVG (2000 lines total)
**GitHub cache:** 98% hit rate (<1ms cached responses)
**Page load:** <200ms first paint, 50ms LiveView connection, zero layout shift
**Build:** 8s full, <1s incremental

## What It Enables

The pieces compose:
- Pattern generator → reusable library
- Components → design system
- Files → data layer
- LiveView → real-time features

This proves the architecture. Next: applying these patterns to validator dashboards, blockchain monitoring, and real-time terminal interfaces.

---

## What This Unlocks

The architecture holds. The same patterns that render blog posts will render validator dashboards, blockchain monitoring, real-time terminal interfaces.

**Next:** [Raxol](/projects#raxol) applies this grid system to terminal UIs. Same constraints, different problem space. Then [mana](/projects#mana) (Ethereum client) and [riddler](/projects#riddler) (cross-chain solver) build on the proven foundation.

Module 1 proves the system works. Each subsequent module inherits these patterns—monospace precision, deterministic generation, composable components, accessibility first.

See all projects at [/projects](/projects). Track progress at [/now](/now).

---

This post's pattern: [animated](/patterns/building-droo-foo?animate=true) | [static](/patterns/building-droo-foo)
