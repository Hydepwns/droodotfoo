# droo.foo Terminal - User Guide

Welcome to the interactive terminal droo.foo system! This guide will help you navigate and use all available features.

## Getting Started

When you first visit the droo.foo, you'll see a terminal interface with an ASCII logo and navigation menu. The interface is designed to feel like a real terminal environment.

## Navigation

### Basic Navigation
- **j** / **↓** - Move cursor down
- **k** / **↑** - Move cursor up
- **Enter** - Select highlighted item

### Vim-style Navigation
- **h** - Move left (previous section)
- **l** - Move right (next section)
- **g** - Jump to first item
- **G** - Jump to last item

### Advanced Navigation
- **PageUp** - Move up 3 items
- **PageDown** - Move down 3 items
- **Home** - Go to first item
- **End** - Go to last item

## Command Mode

Press **:** to enter command mode. A prompt will appear at the bottom of the screen.

### Available Commands

#### Basic Commands
- `:help` - Display help information
- `:ls` - List available sections
- `:cat <section>` - Display specific section (e.g., `:cat projects`)
- `:clear` - Clear screen and return to home

#### Fun Commands
- `:matrix` - Enter the Matrix (easter egg)
- `:theme <name>` - Change color theme
- `:export <format>` - Export resume (markdown, json, text)

#### SSH Simulation
- Type `ssh droo@droo.foo` to simulate SSH connection
- Use any password (demo mode)
- Once connected, use standard Unix commands

### Tab Completion
Press **Tab** while typing a command to auto-complete it.

## Search Mode

Press **/** to enter search mode. Type your search query and press Enter to search through all droo.foo content.

## Themes

The droo.foo supports multiple color themes:

1. **Default** - Clean monospace aesthetic
2. **Classic Green** - Traditional terminal green
3. **Amber** - Warm amber monochrome
4. **High Contrast** - Maximum readability
5. **Cyberpunk** - Neon purple and cyan
6. **Matrix** - Matrix-style green
7. **Phosphor Blue** - Cool blue glow

Themes are automatically saved to your browser.

## Terminal Multiplexing

The droo.foo supports split-screen views:

- **Horizontal Split** - View two sections side by side
- **Vertical Split** - Stack sections vertically
- **Quad View** - Four sections at once

Use `Ctrl+W` followed by:
- **s** - Horizontal split
- **v** - Vertical split
- **q** - Quad view
- **w** - Cycle between panes
- **c** - Close current pane

## Export Options

Export your resume in various formats:

- `:export markdown` - Markdown format (.md)
- `:export json` - JSON data structure
- `:export text` - Plain text format
- `:export pdf` - PDF document (coming soon)

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `:` | Enter command mode |
| `/` | Enter search mode |
| `Escape` | Exit current mode |
| `Tab` | Command completion |
| `j/k` | Navigate up/down |
| `h/l` | Navigate left/right |
| `g/G` | Jump to top/bottom |
| `Enter` | Select item |

## Command History

While in command mode:
- **↑** - Previous command
- **↓** - Next command

Command history is maintained for your session.

## Easter Eggs

Discover hidden features:
- Matrix rain animation
- Konami code support
- ASCII art surprises
- Hidden commands

## Tips & Tricks

1. **Quick Navigation**: Use `g` and `G` to quickly jump to top/bottom
2. **Fast Search**: Press `/` followed by your search term
3. **Theme Cycling**: Keep executing `:theme` to cycle through all themes
4. **Command Shortcuts**: Tab completion works for partial commands
5. **SSH Demo**: Try the SSH simulation for a realistic terminal experience

## Browser Compatibility

Works best on:
- Chrome/Chromium (recommended)
- Firefox
- Safari
- Edge

Requires JavaScript enabled and supports modern browsers with ES6+.

## Performance

The terminal runs at 60fps with:
- Character-perfect grid alignment
- Monospace font rendering (Monaspace Argon)
- Optimized WebSocket communication
- Efficient DOM updates via LiveView

## Accessibility

- Full keyboard navigation
- High contrast theme available
- Screen reader compatible
- No mouse required

## Troubleshooting

**Q: Text appears misaligned**
A: Ensure Monaspace Argon font is loaded. Try refreshing the page.

**Q: Commands aren't working**
A: Make sure you're in command mode (press `:` first)

**Q: Theme isn't saving**
A: Check that localStorage is enabled in your browser

**Q: Can't see cursor**
A: The cursor blinks. Try moving with j/k to see current position.

## Contact

For issues or suggestions:
- Email: drew@axol.io
- GitHub: github.com/hydepwns
- Twitter: @MF_DROO

---

*Built with Elixir, Phoenix LiveView, and Raxol Terminal UI Framework*