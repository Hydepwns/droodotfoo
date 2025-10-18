---
title: "DROO.FOO: a raxol terminal portfolio"
date: "2025-01-18"
description: "A deep dive into building DROO.FOO - a terminal-powered portfolio with Phoenix LiveView and Raxol"
author: "DROO AMOR"
tags: ["elixir", "raxol", "terminal", "phoenix", "liveview", "meta"]
slug: "building-droo-foo"
---

# Welcome to droo.foo

This is droo.foo - a terminal-powered portfolio that brings the aesthetic of retro computing to the modern web. Built with Phoenix LiveView and Raxol, it delivers a full Unix-like terminal experience running at 60fps in your browser.

## The Stack

The site combines several interesting technologies:

- **Elixir + Phoenix 1.8**: Robust backend framework
- **Phoenix LiveView**: Real-time updates without JavaScript complexity
- **Raxol**: Terminal UI framework for Elixir
- **MDEx**: Fast markdown rendering
- **Monaspace Argon**: Crisp monospace typography
- **File-based Blog**: Markdown posts in `priv/posts/`
- **Obsidian Publishing**: Write locally, publish via API

## Why Terminal UIs?

Terminal UIs offer several compelling advantages:

- **Performance**: Lightweight and blazingly fast
- **Accessibility**: Works over SSH and low-bandwidth connections
- **Aesthetics**: That authentic retro computing feel
- **Efficiency**: Keyboard-first navigation
- **Portability**: Character-perfect rendering across platforms

## Building Terminal UIs with Raxol

At the heart of droo.foo is Raxol, a terminal UI framework for Elixir. Here's how to build your own terminal interfaces.

### Getting Started

Add Raxol to your `mix.exs`:

```elixir
def deps do
  [
    {:raxol, "~> 1.0"}
  ]
end
```

### Basic Example

Here's a simple counter application:

```elixir
defmodule MyApp do
  use Raxol.App

  def init(_opts) do
    {:ok, %{counter: 0}}
  end

  def handle_key(?j, state) do
    {:ok, %{state | counter: state.counter + 1}}
  end

  def render(state) do
    "Counter: #{state.counter}"
  end
end
```

### Advanced Patterns

#### State Management

Keep your state immutable and use pattern matching:

```elixir
def handle_key(:arrow_down, %{cursor: cursor, max: max} = state) do
  new_cursor = min(cursor + 1, max)
  {:ok, %{state | cursor: new_cursor}}
end
```

#### Box Drawing

Use Unicode box-drawing characters for beautiful layouts:

```bash
┌─────────────────┐
│ Title           │
├─────────────────┤
│ Content         │
└─────────────────┘
```

### Integration with Phoenix LiveView

The magic happens when you combine Raxol with LiveView. The architecture:

1. **Raxol Terminal** - Terminal rendering engine
2. **Phoenix LiveView** - Real-time web orchestration
3. **Web Browser** - Character-perfect monospace grid display

This gives you server-side terminal logic with real-time updates in the browser.

## Features of droo.foo

- **Terminal Interface**: Full Unix-like terminal with navigation
- **60fps Updates**: Smooth LiveView-powered interactions
- **Monospace Aesthetic**: Character-perfect grid alignment
- **Multiple Themes**: Synthwave84, Matrix, Cyberpunk, and more
- **Responsive Design**: Adapts to mobile and desktop
- **File-based Content**: Simple markdown-based blog system

## Quick Start Guide

Press `` ` `` to toggle the terminal view anywhere on the site. Once in the terminal, use:

- Arrow keys to navigate
- Enter to select
- `t` to cycle themes
- `` ` `` to exit terminal

## What's Next?

I'll be writing about:
- Phoenix LiveView architectural patterns
- Advanced Raxol techniques
- File-based content management systems
- Web3 integration with Elixir
- Building PWAs with Phoenix

## Learn More

Check out these resources:
- [Raxol Documentation](https://hexdocs.pm/raxol)
- [Phoenix LiveView Guide](https://hexdocs.pm/phoenix_live_view)
- [Source Code](https://github.com/droo/droodotfoo)

Happy terminal hacking!
