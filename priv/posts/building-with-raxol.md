---
title: "Building Terminal UIs with Raxol"
date: "2025-01-18"
description: "A deep dive into creating terminal interfaces in Elixir"
author: "Drew Hiro"
tags: ["elixir", "raxol", "terminal", "tutorial"]
slug: "building-with-raxol"
---

# Building Terminal UIs with Raxol

Raxol is a terminal UI framework for Elixir that makes it easy to build interactive, full-screen terminal applications. In this post, we'll explore how to create beautiful terminal interfaces.

## Why Terminal UIs?

Terminal UIs offer several advantages:

- **Performance**: Lightweight and fast
- **Accessibility**: Works over SSH and low-bandwidth connections
- **Aesthetics**: That retro computing feel
- **Efficiency**: Keyboard-first navigation

## Getting Started

Add Raxol to your `mix.exs`:

```elixir
def deps do
  [
    {:raxol, "~> 1.0"}
  ]
end
```

## Basic Example

Here's a simple Raxol application:

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

## Advanced Patterns

### State Management

Keep your state immutable and use pattern matching:

```elixir
def handle_key(:arrow_down, %{cursor: cursor, max: max} = state) do
  new_cursor = min(cursor + 1, max)
  {:ok, %{state | cursor: new_cursor}}
end
```

### Box Drawing

Use Unicode box-drawing characters for beautiful layouts:

```
┌─────────────────┐
│ Title          │
├─────────────────┤
│ Content here   │
└─────────────────┘
```

## Next Steps

Check out the [Raxol documentation](https://hexdocs.pm/raxol) for more advanced features like:

- Custom renderers
- Event handling
- Color themes
- Animations

Happy terminal hacking!
