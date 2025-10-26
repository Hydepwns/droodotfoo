---
title: "Building DROO.FOO: Module 1"
date: "2025-01-18"
description: "Infrastructure for content. Building a gundam slowly, one module at a time."
author: "DROO AMOR"
tags: ["elixir", "phoenix", "architecture", "systems"]
slug: "building-droo-foo"
---

<div class="post-pattern-header">
  <object data="/patterns/building-droo-foo?animate=true" type="image/svg+xml" style="width: 100%; height: 300px; display: block;">
    <img src="/patterns/building-droo-foo" alt="Generative pattern for building-droo-foo" style="width: 100%; height: 300px; object-fit: cover;" />
  </object>
</div>

# Module 1

I'm building blockchain infrastructure at [axol.io](https://axol.io). The stack has three parts:
- **[mana](/projects#mana)**: Ethereum client in Elixir
- **[raxol](/projects#raxol)**: Terminal UI framework
- **[riddler](/projects#riddler)**: Cross-chain solver

This site is the first module. It proves the architecture works. If the content system isn't modular, the larger system won't work. If the monospace grid breaks here, it'll break in raxol. If patterns can't handle blog posts, they can't handle validator dashboards.

**Stack:** Phoenix 1.8 + LiveView, Elixir, MDEx, Monaspace Argon
**Source:** File-based (priv/posts/, priv/resume.json)
**Patterns:** 8 styles, deterministic SVG generation
**Workflow:** Obsidian/Zed → API → Live

## The Constraints

- Monospace terminal interface.
- Character-perfect grid.
- Ideally no layout shifts, no font surprises.
- Must be highly portable
- Accessibility is a first-class feature (WCAG, ARIA, Lemmy, etc)
- [Raxol](/projects#raxol) (the terminal UI framework) must use this same rendering

Additionally, it must pass the 'squint test', meaning the visible monospace grid, character spacing and font display but must highly optimized for legibility and visual rhythm.

We addressed the font display constraint quickly by using the [monaspace font family](https://monaspace.githubnext.com/). *A personal favorite.*

**That character-perfect grid became the first problem.**
CSS handles 1ch units differently across browsers. Safari rendered 1ch at ~0.1ch wider than Chrome, which was enough to break alignment after _80 characters_.

## Pattern Generation: Reproducible Art

Every post needs a visual; the site looked too boring and manual design doesn't scale.

Deterministic pattern generation: hash the slug, seed the RNG, generate SVG. Reproducible, cacheable, zero manual work.

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

We will start with eight pattern styles for now. The slug hash determines which one. No database or storage, just math. (See all at [/patterns](/patterns).)

This gives us reusable infrastructure. Any content—posts, projects, validator dashboards—gets deterministic artwork. See all patterns at [/patterns](/patterns).

## Phoenix LiveView: The Runtime

Phoenix LiveView: server-side rendering, real-time updates, no JavaScript bloat. Components are functions. Purely data in, UI out.

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

We have no database, instead we use Git for version control, `resume.json` is the selected source. We can change to another file type but json is simple enough.
Posts are markdown.
Files version naturally, backup becomes trivial and allows us to migrate easily.

Projects pull from resume data:

```elixir
def all do
  resume = ResumeData.get_resume_data()
  # defense projects are handled slightly differently
  defense = convert_defense_projects(resume[:defense_projects])
  portfolio = convert_portfolio_projects(resume[:portfolio][:projects])
  portfolio ++ defense
end
```

Pattern matching is then made in to data shapes. Defense and portfolio projects become the same struct. No if/else, no type checking.

## Obsidian → Web: Terminal Workflow

I tend to write in [Obsidian](https://obsidian.md/) or in [Zed](https://zed.dev/).
So we made an API endpoint that accepts markdown, then writes file(s):`/posts/slug`.

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

No GUI. The endpoint extends to any content type.

### Security Implementation

The endpoint has three layers of defense:

```elixir
# 1. Rate limiting (per IP)
def create(conn, params) do
  ip_address = get_ip_address(conn)

  with {:ok, :allowed} <- PostRateLimiter.check_rate_limit(ip_address),
       :ok <- verify_api_token(conn),
       {:ok, validated_content, validated_metadata} <-
         PostValidator.validate(content, metadata) do
    # Write our wonderful post
  end
end

# 2. Content validation
defp validate_slug(%{"slug" => slug}) do
  cond do
    String.contains?(slug, "..") -> {:error, "path traversal"}
    String.contains?(slug, "/") -> {:error, "slashes not allowed"}
    not Regex.match?(~r/^[a-z0-9-]+$/, slug) -> {:error, "invalid chars"}
    true -> {:ok, metadata}
  end
end

# Rate limits: 10 posts/hour, 50/day. Content max: 1MB.
# Token required (no bypass)
```


## What Broke On Contact (And Why That Matters)

**CSS precision with 1ch units.** Safari rendered *1ch at ~0.1ch wider* than Chrome—enough to misalign the grid after 80 characters. Firefox had different quirks with font-feature-settings.

**Why this mattered**: The monospace grid isn't *aesthetic*—it's _architectural_. If the grid breaks, Raxol breaks. The terminal framework depends on character-perfect alignment.

The fix:
1. `font-feature-settings: 'liga' 0, 'calt' 0` to disable ligatures
2. CSS cascade control—no inherited text transforms or letter spacing
3. JavaScript validation on resize to lock the grid

Not sexy, but necessary. The monospace grid is the foundation. Our Agalma even, at least it is for Raxol.
But for now this is fine, we reached an optimal learning outcome and can circle back to write more tests for more browsers (e.g. [Ladybird](https://ladybird.org/) browser, ~disgusting~ Edge, iterm browser) and observe how rendering is executed.

That now finally leaves:
### GitHub API rate limiting.
The API allows 60 requests/hour without authentication. With 10+ projects, each page load hit the limit after one visitor.

Built a caching layer with ETS (Erlang's in-memory key-value store). One GenServer fetches data on startup, caches it, refreshes hourly. Cache hit rate after warmup: 98%.
Pros: No external dependencies, no token management, instant response times.
Cons: We still may want to build a better solution. Because of reasons.

### Pattern generation went through three iterations. (at *least*)

For brevity our third version was a complete refactor:
1. Each pattern type became its own module.
2. Pattern selection used pattern matching on hash ranges.
3. The SVG builder became a pure function—same input, meaning same output, every time.

Result: Pattern generation dropped from ~15ms to <5ms.
*yay*, this takes us to:

## Accessibility Challenges

**ARIA roles conflicting with semantic HTML.** Terminal grids don't map cleanly to standard web semantics. The terminal is a grid of cells, but also a dynamic application. Screen readers expected one thing, the DOM provided another.

**Why this mattered**: Claiming accessibility as a first-class constraint means nothing if screen readers can't navigate the interface or if keyboard users get trapped in the grid.

The problem had two parts:

1. **Structure**: Terminal cells needed proper ARIA roles without breaking semantic HTML. The grid needed to be navigable but not chatty.
2. **Updates**: LiveView pushes updates constantly. Screen readers needed to know *when* content changed without announcing every single cell modification.

The fix:
1. Roving tabindex for keyboard navigation - only one focusable element at a time, arrow keys move focus
2. `aria-live="polite"` regions for terminal output - screen readers announce new content without interrupting
3. Semantic grouping with proper role hierarchy - terminal as application, grid structure underneath

Not perfect yet. Still testing with NVDA, VoiceOver, and JAWS. But navigable and usable, which is the baseline.

## The Final Numbers

**Pattern generation:** <5ms per SVG. 2000 lines total.
**GitHub cache:** 98% hit rate. <1ms cached responses.
**Page load:** <200ms first paint. 50ms LiveView connection. Zero layout shift.
**Build:** 8s full, <1s incremental.

## What It Enables

The pieces helped compose:
- Pattern generator is a library
- Components are a design system
- Files are the data layer
- LiveView enables real-time features

This proves the architecture. Next: applying these same patterns to validator dashboards, blockchain monitoring, and real-time terminal interfaces.

## What's Next

**Module 2**: [Raxol](/projects#raxol) - Terminal UI framework using these same patterns
**Module 3+**: [mana](/projects#mana) (Ethereum client), [riddler](/projects#riddler) (cross-chain solver)

The pattern system works for blog posts. Next: validator dashboards, blockchain monitoring, real-time terminal interfaces.

See all projects at [/projects](/projects). Track progress at [/now](/now).

---

Pattern for this post: [animated](/patterns/building-droo-foo?animate=true) | [static](/patterns/building-droo-foo)
