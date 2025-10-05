# RaxolWeb - Web Terminal Rendering for Phoenix LiveView

**Status:** Prototype/Proof of Concept for contribution to Raxol framework

This directory contains extracted and generalized terminal rendering components from the droodotfoo project, designed to be contributed back to the Raxol framework for web-based terminal UI rendering.

## Overview

RaxolWeb provides high-performance terminal buffer rendering in web browsers via Phoenix LiveView. It's extracted from the proven `TerminalBridge` implementation in droodotfoo and designed as reusable components.

## Architecture

```
raxol_web_prototype/
├── renderer.ex              # Core buffer→HTML rendering engine
├── themes.ex                # Theme system with 7 built-in themes
└── liveview/
    └── terminal_component.ex # Phoenix LiveComponent wrapper
```

## Features

- **60fps Rendering** - Optimized for smooth real-time updates
- **Virtual DOM Diffing** - Only re-renders changed lines for performance
- **Smart Caching** - Pre-computed HTML for common characters and styles
- **Character-Perfect Grid** - 1ch monospace alignment for terminal accuracy
- **7 Built-in Themes** - Synthwave84, Nord, Dracula, Monokai, Gruvbox, Solarized, Tokyo Night
- **Keyboard & Mouse Events** - Full interaction support
- **Accessibility** - ARIA attributes, screen reader support
- **CRT Mode** - Optional retro scanline effects
- **High Contrast Mode** - Accessibility enhancement

## Usage

### Basic Example

```elixir
defmodule MyAppWeb.TerminalLive do
  use MyAppWeb, :live_view
  alias RaxolWeb.LiveView.TerminalComponent

  def mount(_params, _session, socket) do
    buffer = create_buffer()
    {:ok, assign(socket, :buffer, buffer)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={TerminalComponent}
      id="terminal"
      buffer={@buffer}
      theme={:synthwave84}
    />
    """
  end
end
```

### Full Configuration

```elixir
<.live_component
  module={RaxolWeb.LiveView.TerminalComponent}
  id="my-terminal"
  buffer={@buffer}
  theme={:synthwave84}
  width={80}
  height={24}
  crt_mode={false}
  high_contrast={false}
  aria_label="Interactive terminal"
  on_keypress="handle_key"
  on_cell_click="handle_click"
/>
```

## Buffer Format

The component expects buffers in this format:

```elixir
%{
  lines: [
    %{
      cells: [
        %{
          char: "H",
          style: %{
            fg_color: :green,    # or nil
            bg_color: nil,
            bold: true,
            italic: false,
            underline: false,
            reverse: false
          }
        }
      ]
    }
  ],
  width: 80,
  height: 24
}
```

## Modules

### RaxolWeb.Renderer

Core rendering engine that converts terminal buffers to HTML.

```elixir
{:ok, renderer} = RaxolWeb.Renderer.new()
{html, new_renderer} = RaxolWeb.Renderer.render(renderer, buffer)

# Get performance stats
stats = RaxolWeb.Renderer.stats(renderer)
# => %{render_count: 42, cache_hits: 1024, cache_misses: 15, hit_ratio: 0.985}
```

**Features:**
- Virtual DOM-style diffing
- Smart caching for common chars
- Efficient iodata-based string building
- Performance statistics

### RaxolWeb.Themes

Theme system providing terminal color schemes.

```elixir
# Get a built-in theme
theme = RaxolWeb.Themes.get(:nord)

# List all themes
themes = RaxolWeb.Themes.list()
# => [:synthwave84, :nord, :dracula, :monokai, :gruvbox, :solarized_dark, :tokyo_night]

# Generate CSS
css = RaxolWeb.Themes.to_css(theme, ".my-terminal")
```

**Built-in Themes:**
- `:synthwave84` - Retro synthwave colors (default)
- `:nord` - Nordic-inspired theme
- `:dracula` - Popular dark theme
- `:monokai` - Classic editor theme
- `:gruvbox` - Retro groove theme
- `:solarized_dark` - Solarized dark variant
- `:tokyo_night` - Modern dark theme

**Custom Themes:**

```elixir
custom_theme = %{
  background: "#1a1a1a",
  foreground: "#ffffff",
  cursor: "#00ff00",
  selection: "#333333",
  colors: %{
    black: "#000000",
    red: "#ff0000",
    green: "#00ff00",
    yellow: "#ffff00",
    blue: "#0000ff",
    magenta: "#ff00ff",
    cyan: "#00ffff",
    white: "#ffffff",
    bright_black: "#666666",
    bright_red: "#ff6666",
    # ... etc
  }
}
```

### RaxolWeb.LiveView.TerminalComponent

Phoenix LiveComponent wrapper for easy integration.

**Assigns:**
- `buffer` (required) - Terminal buffer map
- `theme` - Theme atom or custom theme map (default: `:synthwave84`)
- `width` - Terminal width in chars (default: 80)
- `height` - Terminal height in chars (default: 24)
- `crt_mode` - Enable CRT scanline effect (default: false)
- `high_contrast` - High contrast mode (default: false)
- `aria_label` - ARIA label for screen readers
- `on_keypress` - Event name for keyboard input
- `on_cell_click` - Event name for cell clicks

**Events:**

The component sends these messages to the parent LiveView:

```elixir
def handle_info({:terminal_keypress, terminal_id, key}, socket) do
  # Handle keyboard input
  {:noreply, socket}
end

def handle_info({:terminal_cell_click, terminal_id, row, col}, socket) do
  # Handle cell clicks
  {:noreply, socket}
end
```

## Demo

A working demo is available at: `http://localhost:4000/dev/raxol-demo`

The demo showcases:
- Theme switching
- CRT mode toggle
- High contrast mode
- Dynamic buffer updates
- Event logging
- All 7 built-in themes

## Performance

Based on droodotfoo's TerminalBridge implementation:

- **Rendering:** ~1-2ms average (target: <16ms for 60fps)
- **Cache Hit Ratio:** ~98% for typical terminal content
- **Virtual DOM Diffing:** Only changed lines re-rendered
- **Memory:** Efficient iodata, minimal allocations

## Integration into Raxol

This prototype demonstrates how droodotfoo's proven web rendering can be integrated into Raxol. Proposed integration structure:

```
raxol/
├── lib/
│   ├── raxol/
│   │   └── web/
│   │       ├── renderer.ex
│   │       ├── themes.ex
│   │       └── cache.ex
│   └── raxol_web/
│       └── live/
│           └── terminal_component.ex
```

## Next Steps

1. **Testing** - Add comprehensive test suite
2. **Documentation** - Full API documentation with ExDoc
3. **Examples** - More complex integration examples
4. **Performance Benchmarks** - Formal benchmarking suite
5. **Contribution Guide** - PR preparation for Raxol repo

## Design Principles

- **Minimal Dependencies** - Only Phoenix LiveView required
- **Framework Agnostic Core** - Renderer works standalone
- **Performance First** - Every optimization from droodotfoo preserved
- **Accessibility** - ARIA, keyboard nav, screen readers
- **Developer Experience** - Simple API, clear documentation

## Extraction Notes

Extracted from droodotfoo's `Droodotfoo.TerminalBridge` (lib/droodotfoo/terminal_bridge.ex):

**What was kept:**
- Core rendering algorithm
- Caching strategy
- Virtual DOM diffing
- Style to CSS conversion
- Buffer format (proven in production)

**What was improved:**
- Module organization (separated concerns)
- Theme system (externalized from CSS)
- API design (more LiveView-idiomatic)
- Documentation (comprehensive)

**What was removed:**
- droodotfoo-specific code
- Legacy compatibility layers
- Monolithic structure

## License

MIT (to match Raxol's license)

## Author

Extracted from droodotfoo by Drew (Hydepwns)
Based on production terminal rendering in droodotfoo.foo

---

**Status:** Ready for testing and refinement before contribution to Raxol.
