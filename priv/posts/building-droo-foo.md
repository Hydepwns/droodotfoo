---
title: "DROO.FOO: Architecture & Publishing"
date: "2025-01-18"
description: "How droo.foo is built: Phoenix LiveView, file-based content, and Obsidian publishing"
author: "DROO AMOR"
tags: ["elixir", "phoenix", "liveview", "obsidian", "architecture"]
slug: "building-droo-foo"
---

# Building droo.foo

A minimalist portfolio built with Phoenix LiveView, emphasizing functional patterns and content-first design.

## Stack

- **Elixir + Phoenix 1.8 + LiveView**: Server-side rendering with real-time updates
- **MDEx**: Fast markdown rendering
- **File-based content**: Posts in `priv/posts/`, resume in `priv/resume.json`
- **Monaspace Argon**: Monospace typography

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Browser                           │
│  ┌──────────────────────────────────────────────┐  │
│  │         Phoenix LiveView                     │  │
│  │  - Real-time rendering                       │  │
│  │  - WebSocket connection                      │  │
│  │  - Server-side state                         │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│              Phoenix Application                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  │
│  │  LiveViews   │  │  Components  │  │   API    │  │
│  │              │  │              │  │          │  │
│  │ - Home       │  │ - Layout     │  │ - Posts  │  │
│  │ - About      │  │ - Tech Tags  │  │          │  │
│  │ - Projects   │  │ - Details    │  │          │  │
│  │ - Posts      │  │              │  │          │  │
│  └──────────────┘  └──────────────┘  └──────────┘  │
│                        │                             │
│                        ▼                             │
│  ┌──────────────────────────────────────────────┐  │
│  │           Data Layer                         │  │
│  │  - priv/resume.json   (resume data)          │  │
│  │  - priv/posts/*.md    (blog posts)           │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### Key LiveViews
- `DroodotfooLive` - Homepage
- `AboutLive` - Resume/experience
- `ProjectsLive` - Portfolio projects
- `PostLive` - Blog posts

## Obsidian Publishing Workflow

Write posts in Obsidian, publish via API:

```
┌──────────────────────────────────────────────────┐
│  Obsidian Vault                                  │
│  ┌────────────────────────────────────┐          │
│  │  Post.md                           │          │
│  │  ---                               │          │
│  │  title: "My Post"                  │          │
│  │  date: "2025-01-18"                │          │
│  │  ---                               │          │
│  │  # Content here                    │          │
│  └────────────────────────────────────┘          │
└──────────────────────────────────────────────────┘
                  │
                  │ POST /api/posts
                  ▼
┌──────────────────────────────────────────────────┐
│  Phoenix API Endpoint                            │
│  ┌────────────────────────────────────┐          │
│  │  POST /api/posts                   │          │
│  │  - Validates frontmatter           │          │
│  │  - Generates slug                  │          │
│  │  - Writes to priv/posts/           │          │
│  └────────────────────────────────────┘          │
└──────────────────────────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────────┐
│  File System                                     │
│  priv/posts/my-post.md                           │
└──────────────────────────────────────────────────┘
```

Posts are immediately available at `/posts/slug` via LiveView.

## Data Model

```elixir
# Single source of truth
priv/resume.json
  ├─ personal_info
  ├─ experience[]
  ├─ education[]
  ├─ certifications[]
  ├─ defense_projects[]
  └─ portfolio
      └─ projects[]
          ├─ mana (Ethereum client)
          ├─ riddler (Cross-chain solver)
          └─ ...

# Blog posts
priv/posts/*.md
  └─ Frontmatter + Markdown
```

Projects dynamically load from resume data:

```elixir
def all do
  resume = ResumeData.get_resume_data()
  defense = convert_defense_projects(resume[:defense_projects])
  portfolio = convert_portfolio_projects(resume[:portfolio][:projects])
  portfolio ++ defense
end
```

## Key Patterns

**Pattern Matching for Type-Specific Logic:**
```elixir
defp extract_tech_stack_for(:defense, raw_project),
  do: extract_tech_stack(raw_project[:technologies])

defp extract_tech_stack_for(:portfolio, raw_project),
  do: [raw_project[:language]]
```

**Progressive Disclosure with `<details>`:**
```heex
<details class="project-details">
  <summary class="project-summary">Details</summary>
  <div>{project.description}</div>
</details>
```

**GitHub Integration:**
GitHub repository topics automatically fetched and displayed as tags.

## Why This Stack?

- **Phoenix LiveView**: Real-time without JavaScript complexity
- **File-based content**: Simple, versionable, no database needed
- **Obsidian publishing**: Write in your editor, publish via API
- **Functional Elixir**: Pattern matching, immutable state, pipe operators
- **Monospace aesthetic**: Clean, fast, content-focused

## Links

- [Mana Ethereum Client](https://github.com/axol-io/mana)
- [Riddler Cross-chain Solver](https://github.com/axol-io/riddler)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
