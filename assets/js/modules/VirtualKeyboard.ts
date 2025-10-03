/**
 * Virtual keyboard support for mobile terminals
 */

export interface KeyboardKey {
  label: string;
  value: string;
  width?: number; // in grid units
  action?: 'input' | 'special' | 'modifier';
  icon?: string; // ASCII icon
}

export interface KeyboardLayout {
  name: string;
  rows: KeyboardKey[][];
}

export class VirtualKeyboard {
  private container: HTMLElement;
  private inputCallback: ((key: string) => void) | null = null;
  private currentLayout: string = 'default';
  private isVisible: boolean = false;
  private capsLock: boolean = false;
  private shiftPressed: boolean = false;

  private readonly layouts: Map<string, KeyboardLayout> = new Map();

  constructor(container: HTMLElement) {
    this.container = container;
    this.initializeLayouts();
    this.render();
  }

  private initializeLayouts(): void {
    // Default QWERTY layout
    this.layouts.set('default', {
      name: 'default',
      rows: [
        [
          { label: '1', value: '1' },
          { label: '2', value: '2' },
          { label: '3', value: '3' },
          { label: '4', value: '4' },
          { label: '5', value: '5' },
          { label: '6', value: '6' },
          { label: '7', value: '7' },
          { label: '8', value: '8' },
          { label: '9', value: '9' },
          { label: '0', value: '0' },
          { label: '<-', value: 'Backspace', width: 2, action: 'special', icon: '⌫' }
        ],
        [
          { label: 'q', value: 'q' },
          { label: 'w', value: 'w' },
          { label: 'e', value: 'e' },
          { label: 'r', value: 'r' },
          { label: 't', value: 't' },
          { label: 'y', value: 'y' },
          { label: 'u', value: 'u' },
          { label: 'i', value: 'i' },
          { label: 'o', value: 'o' },
          { label: 'p', value: 'p' }
        ],
        [
          { label: 'a', value: 'a' },
          { label: 's', value: 's' },
          { label: 'd', value: 'd' },
          { label: 'f', value: 'f' },
          { label: 'g', value: 'g' },
          { label: 'h', value: 'h' },
          { label: 'j', value: 'j' },
          { label: 'k', value: 'k' },
          { label: 'l', value: 'l' },
          { label: 'Enter', value: 'Enter', width: 2, action: 'special', icon: '↵' }
        ],
        [
          { label: 'Shift', value: 'Shift', width: 2, action: 'modifier', icon: '⇧' },
          { label: 'z', value: 'z' },
          { label: 'x', value: 'x' },
          { label: 'c', value: 'c' },
          { label: 'v', value: 'v' },
          { label: 'b', value: 'b' },
          { label: 'n', value: 'n' },
          { label: 'm', value: 'm' },
          { label: '/', value: '/' }
        ],
        [
          { label: 'Ctrl', value: 'Control', width: 1.5, action: 'modifier' },
          { label: 'Cmd', value: 'Meta', width: 1.5, action: 'modifier' },
          { label: 'Space', value: ' ', width: 4, icon: '␣' },
          { label: '←', value: 'ArrowLeft', action: 'special' },
          { label: '↑', value: 'ArrowUp', action: 'special' },
          { label: '↓', value: 'ArrowDown', action: 'special' },
          { label: '→', value: 'ArrowRight', action: 'special' }
        ]
      ]
    });

    // Symbol layout
    this.layouts.set('symbols', {
      name: 'symbols',
      rows: [
        [
          { label: '!', value: '!' },
          { label: '@', value: '@' },
          { label: '#', value: '#' },
          { label: '$', value: '$' },
          { label: '%', value: '%' },
          { label: '^', value: '^' },
          { label: '&', value: '&' },
          { label: '*', value: '*' },
          { label: '(', value: '(' },
          { label: ')', value: ')' },
          { label: '<-', value: 'Backspace', width: 2, action: 'special', icon: '⌫' }
        ],
        [
          { label: '-', value: '-' },
          { label: '_', value: '_' },
          { label: '=', value: '=' },
          { label: '+', value: '+' },
          { label: '[', value: '[' },
          { label: ']', value: ']' },
          { label: '{', value: '{' },
          { label: '}', value: '}' },
          { label: '\\', value: '\\' },
          { label: '|', value: '|' }
        ],
        [
          { label: ';', value: ';' },
          { label: ':', value: ':' },
          { label: "'", value: "'" },
          { label: '"', value: '"' },
          { label: '<', value: '<' },
          { label: '>', value: '>' },
          { label: ',', value: ',' },
          { label: '.', value: '.' },
          { label: '?', value: '?' },
          { label: 'Enter', value: 'Enter', width: 2, action: 'special', icon: '↵' }
        ],
        [
          { label: 'ABC', value: 'layout:default', width: 2, action: 'special' },
          { label: '`', value: '`' },
          { label: '~', value: '~' },
          { label: 'Tab', value: 'Tab', width: 2, action: 'special', icon: '⇥' },
          { label: 'Esc', value: 'Escape', width: 2, action: 'special' }
        ],
        [
          { label: 'Hide', value: 'hide', width: 2, action: 'special', icon: '⌨' },
          { label: 'Space', value: ' ', width: 6, icon: '␣' },
          { label: 'Clear', value: 'clear', width: 2, action: 'special' }
        ]
      ]
    });
  }

  private render(): void {
    const keyboard = document.createElement('div');
    keyboard.className = 'virtual-keyboard';
    keyboard.id = 'virtual-keyboard';
    keyboard.style.cssText = `
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      background: var(--background-color, #1a1a1a);
      border-top: 2px solid var(--border-color, #333);
      padding: 8px;
      display: ${this.isVisible ? 'block' : 'none'};
      z-index: 1000;
      font-family: var(--font-family, monospace);
      user-select: none;
      -webkit-user-select: none;
      touch-action: manipulation;
    `;

    const layout = this.layouts.get(this.currentLayout);
    if (!layout) return;

    layout.rows.forEach(row => {
      const rowDiv = document.createElement('div');
      rowDiv.className = 'keyboard-row';
      rowDiv.style.cssText = `
        display: flex;
        gap: 4px;
        margin-bottom: 4px;
        justify-content: center;
      `;

      row.forEach(key => {
        const keyButton = this.createKey(key);
        rowDiv.appendChild(keyButton);
      });

      keyboard.appendChild(rowDiv);
    });

    // Add toggle button for mobile
    const toggleButton = document.createElement('button');
    toggleButton.className = 'keyboard-toggle';
    toggleButton.textContent = '⌨';
    toggleButton.style.cssText = `
      position: fixed;
      bottom: 10px;
      right: 10px;
      width: 48px;
      height: 48px;
      border-radius: 50%;
      background: var(--primary-color, #007bff);
      color: white;
      border: none;
      font-size: 24px;
      z-index: 999;
      display: ${this.isMobileDevice() ? 'block' : 'none'};
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    `;
    toggleButton.addEventListener('click', () => this.toggle());

    // Replace existing keyboard if present
    const existingKeyboard = document.getElementById('virtual-keyboard');
    if (existingKeyboard) {
      existingKeyboard.remove();
    }

    const existingToggle = document.querySelector('.keyboard-toggle');
    if (existingToggle) {
      existingToggle.remove();
    }

    this.container.appendChild(keyboard);
    document.body.appendChild(toggleButton);
  }

  private createKey(key: KeyboardKey): HTMLButtonElement {
    const button = document.createElement('button');
    button.className = 'keyboard-key';
    button.textContent = key.icon || key.label;

    const width = key.width || 1;
    button.style.cssText = `
      flex: ${width};
      min-width: ${width * 32}px;
      height: 40px;
      background: var(--background-color-alt, #2a2a2a);
      color: var(--text-color, #ffffff);
      border: 1px solid var(--border-color, #444);
      border-radius: 4px;
      font-size: 16px;
      font-family: inherit;
      cursor: pointer;
      touch-action: manipulation;
      -webkit-tap-highlight-color: transparent;
      transition: background-color 0.1s;
    `;

    // Add active state styles
    button.addEventListener('touchstart', () => {
      button.style.background = 'var(--primary-color, #007bff)';
    });

    button.addEventListener('touchend', () => {
      button.style.background = 'var(--background-color-alt, #2a2a2a)';
    });

    button.addEventListener('click', (e) => {
      e.preventDefault();
      this.handleKeyPress(key);
    });

    return button;
  }

  private handleKeyPress(key: KeyboardKey): void {
    if (key.action === 'special') {
      switch (key.value) {
        case 'hide':
          this.hide();
          break;
        case 'clear':
          if (this.inputCallback) {
            // Send clear command
            this.inputCallback('Clear');
          }
          break;
        default:
          if (key.value.startsWith('layout:')) {
            const layoutName = key.value.substring(7);
            this.switchLayout(layoutName);
          } else if (this.inputCallback) {
            this.inputCallback(key.value);
          }
      }
    } else if (key.action === 'modifier') {
      this.handleModifier(key.value);
    } else {
      let value = key.value;

      // Apply shift/caps lock
      if (this.shiftPressed || this.capsLock) {
        value = value.toUpperCase();
      }

      if (this.inputCallback) {
        this.inputCallback(value);
      }

      // Reset shift after key press
      if (this.shiftPressed) {
        this.shiftPressed = false;
        this.render();
      }
    }
  }

  private handleModifier(modifier: string): void {
    switch (modifier) {
      case 'Shift':
        this.shiftPressed = !this.shiftPressed;
        this.render();
        break;
      case 'CapsLock':
        this.capsLock = !this.capsLock;
        this.render();
        break;
      default:
        if (this.inputCallback) {
          this.inputCallback(modifier);
        }
    }
  }

  private switchLayout(layoutName: string): void {
    if (this.layouts.has(layoutName)) {
      this.currentLayout = layoutName;
      this.render();
    }
  }

  private isMobileDevice(): boolean {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ||
      (window.matchMedia && window.matchMedia('(max-width: 768px)').matches);
  }

  public show(): void {
    this.isVisible = true;
    const keyboard = document.getElementById('virtual-keyboard');
    if (keyboard) {
      keyboard.style.display = 'block';
      // Adjust viewport to prevent keyboard overlay
      this.adjustViewport();
    }
  }

  public hide(): void {
    this.isVisible = false;
    const keyboard = document.getElementById('virtual-keyboard');
    if (keyboard) {
      keyboard.style.display = 'none';
      // Reset viewport
      this.resetViewport();
    }
  }

  public toggle(): void {
    if (this.isVisible) {
      this.hide();
    } else {
      this.show();
    }
  }

  public setInputCallback(callback: (key: string) => void): void {
    this.inputCallback = callback;
  }

  private adjustViewport(): void {
    // Scroll terminal into view when keyboard opens
    const terminal = document.querySelector('.terminal-wrapper');
    if (terminal) {
      terminal.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    // Add padding to body to account for keyboard height
    document.body.style.paddingBottom = '250px';
  }

  private resetViewport(): void {
    document.body.style.paddingBottom = '';
  }

  public destroy(): void {
    const keyboard = document.getElementById('virtual-keyboard');
    if (keyboard) {
      keyboard.remove();
    }

    const toggle = document.querySelector('.keyboard-toggle');
    if (toggle) {
      toggle.remove();
    }
  }
}