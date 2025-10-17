/**
 * Mobile terminal integration - combines touch, keyboard, and navigation
 */

import { TouchGestureManager, isMobileDevice, getCellFromCoordinates } from './TouchGestures';
import { VirtualKeyboard } from './VirtualKeyboard';

export interface MobileTerminalConfig {
  container: HTMLElement;
  onCommand: (command: string) => void;
  pushEvent?: (event: string, payload: any) => void;
}

export class MobileTerminal {
  private container: HTMLElement;
  private touchManager: TouchGestureManager | null = null;
  private virtualKeyboard: VirtualKeyboard | null = null;
  private navigationUI: HTMLElement | null = null;
  private swipeIndicator: HTMLElement | null = null;
  private onCommand: (command: string) => void;
  private pushEvent?: (event: string, payload: any) => void;
  private isInitialized: boolean = false;

  constructor(config: MobileTerminalConfig) {
    this.container = config.container;
    this.onCommand = config.onCommand;
    this.pushEvent = config.pushEvent;

    if (isMobileDevice()) {
      this.initialize();
    }

    // Listen for orientation changes
    window.addEventListener('orientationchange', () => this.handleOrientationChange());
  }

  private initialize(): void {
    if (this.isInitialized) return;

    this.setupTouchGestures();
    this.setupVirtualKeyboard();
    this.setupNavigationUI();
    this.setupSwipeIndicator();
    this.addViewportMeta();

    this.isInitialized = true;
  }

  private setupTouchGestures(): void {
    const terminalWrapper = this.container.querySelector('.terminal-wrapper') as HTMLElement;
    if (!terminalWrapper) return;

    this.touchManager = new TouchGestureManager(terminalWrapper);

    // Swipe handlers for navigation
    this.touchManager.setSwipeHandler((event) => {
      this.showSwipeIndicator(event.direction);

      switch (event.direction) {
        case 'up':
          this.sendKey('k'); // Scroll up
          break;
        case 'down':
          this.sendKey('j'); // Scroll down
          break;
        case 'left':
          this.sendKey('h'); // Previous
          break;
        case 'right':
          this.sendKey('l'); // Next
          break;
      }
    });

    // Tap handler for selection
    this.touchManager.setTapHandler((event) => {
      if (event.isDoubleTap) {
        // Double tap to enter/select
        this.sendKey('Enter');
      } else {
        // Single tap to focus on cell
        const cell = getCellFromCoordinates(event.x, event.y, terminalWrapper);
        if (cell && this.pushEvent) {
          this.pushEvent('cell_click', { row: cell.row, col: cell.col });
        }
      }
    });

    // Pinch handler for zoom
    this.touchManager.setPinchHandler((event) => {
      if (event.scale > 1.2) {
        this.increaseFontSize();
      } else if (event.scale < 0.8) {
        this.decreaseFontSize();
      }
    });

    // Long press for context menu
    this.touchManager.setLongPressHandler((point) => {
      this.showContextMenu(point.x, point.y);
    });
  }

  private setupVirtualKeyboard(): void {
    this.virtualKeyboard = new VirtualKeyboard(document.body);

    this.virtualKeyboard.setInputCallback((key: string) => {
      this.sendKey(key);
    });
  }

  private setupNavigationUI(): void {
    const nav = document.createElement('div');
    nav.className = 'mobile-nav';
    nav.innerHTML = `
      <button data-key="h" aria-label="Left" title="Navigate Left">←</button>
      <button data-key="k" aria-label="Up" title="Navigate Up">↑</button>
      <button data-key="j" aria-label="Down" title="Navigate Down">↓</button>
      <button data-key="l" aria-label="Right" title="Navigate Right">→</button>
      <button data-key="Enter" aria-label="Select" title="Enter/Select">⏎</button>
      <button data-key="/" aria-label="Search" title="Search">/</button>
      <button data-key="Escape" aria-label="Back" title="Back/Escape">⌫</button>
      <button data-key="toggle_keyboard" aria-label="Keyboard" title="Toggle Virtual Keyboard">⌨</button>
    `;

    nav.querySelectorAll('button').forEach(button => {
      button.addEventListener('click', (e) => {
        e.preventDefault();
        const key = (e.target as HTMLElement).getAttribute('data-key');
        if (key === 'toggle_keyboard') {
          this.toggleKeyboard();
        } else if (key) {
          this.sendKey(key);
        }
      });

      // Add haptic feedback for supported devices
      button.addEventListener('touchstart', () => {
        if ('vibrate' in navigator) {
          navigator.vibrate(10);
        }
      });
    });

    document.body.appendChild(nav);
    this.navigationUI = nav;
  }

  private setupSwipeIndicator(): void {
    const indicator = document.createElement('div');
    indicator.className = 'swipe-indicator';
    document.body.appendChild(indicator);
    this.swipeIndicator = indicator;
  }

  private showSwipeIndicator(direction: string): void {
    if (!this.swipeIndicator) return;

    const arrows: { [key: string]: string } = {
      up: '↑',
      down: '↓',
      left: '←',
      right: '→'
    };

    this.swipeIndicator.textContent = arrows[direction] || '';
    this.swipeIndicator.classList.add('show');

    setTimeout(() => {
      this.swipeIndicator?.classList.remove('show');
    }, 300);
  }

  private sendKey(key: string): void {
    if (this.pushEvent) {
      this.pushEvent('key_press', { key });
    } else {
      this.onCommand(key);
    }
  }

  private increaseFontSize(): void {
    const terminal = this.container.querySelector('.terminal-container') as HTMLElement;
    if (!terminal) return;

    const currentSize = parseInt(window.getComputedStyle(terminal).fontSize);
    const newSize = Math.min(currentSize + 2, 24); // Increased max size for mobile
    terminal.style.fontSize = `${newSize}px`;

    // Store font size preference
    localStorage.setItem('terminal-font-size', newSize.toString());
    
    this.recalculateGrid();
    this.showFontSizeNotification(newSize);
  }

  private decreaseFontSize(): void {
    const terminal = this.container.querySelector('.terminal-container') as HTMLElement;
    if (!terminal) return;

    const currentSize = parseInt(window.getComputedStyle(terminal).fontSize);
    const newSize = Math.max(currentSize - 2, 8); // Decreased min size for mobile
    terminal.style.fontSize = `${newSize}px`;

    // Store font size preference
    localStorage.setItem('terminal-font-size', newSize.toString());
    
    this.recalculateGrid();
    this.showFontSizeNotification(newSize);
  }

  private showFontSizeNotification(size: number): void {
    const notification = document.createElement('div');
    notification.style.cssText = `
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background: var(--background-color-alt, #2a2a2a);
      color: var(--text-color, #ffffff);
      padding: 8px 16px;
      border-radius: 8px;
      font-size: 14px;
      z-index: 2000;
      opacity: 0;
      transition: opacity 0.3s ease;
    `;
    notification.textContent = `Font size: ${size}px`;
    document.body.appendChild(notification);

    // Fade in
    setTimeout(() => notification.style.opacity = '1', 10);
    
    // Fade out and remove
    setTimeout(() => {
      notification.style.opacity = '0';
      setTimeout(() => notification.remove(), 300);
    }, 1500);
  }

  private recalculateGrid(): void {
    // Trigger grid recalculation
    if (this.pushEvent) {
      this.pushEvent('recalculate_grid', {});
    }
  }

  private showContextMenu(x: number, y: number): void {
    const menu = document.createElement('div');
    menu.style.cssText = `
      position: fixed;
      left: ${x}px;
      top: ${y}px;
      background: var(--background-color-alt, #2a2a2a);
      border: 1px solid var(--border-color, #444);
      border-radius: 4px;
      padding: 8px;
      z-index: 1002;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    `;

    const options = [
      { label: 'Copy', action: () => this.copySelection() },
      { label: 'Paste', action: () => this.paste() },
      { label: 'Clear', action: () => this.sendKey('Clear') },
      { label: 'Help', action: () => this.sendKey('help') },
      { label: 'Cancel', action: () => menu.remove() }
    ];

    options.forEach(option => {
      const button = document.createElement('button');
      button.textContent = option.label;
      button.style.cssText = `
        display: block;
        width: 100%;
        padding: 8px;
        margin: 4px 0;
        background: var(--background-color, #1a1a1a);
        color: var(--text-color, #fff);
        border: 1px solid var(--border-color, #444);
        border-radius: 4px;
        font-family: inherit;
        font-size: 14px;
      `;
      button.addEventListener('click', () => {
        option.action();
        menu.remove();
      });
      menu.appendChild(button);
    });

    document.body.appendChild(menu);

    // Remove menu when clicking outside
    setTimeout(() => {
      document.addEventListener('click', () => menu.remove(), { once: true });
    }, 100);
  }

  private copySelection(): void {
    // Get selected text from terminal
    const selection = window.getSelection();
    if (selection && selection.toString()) {
      navigator.clipboard.writeText(selection.toString());
    }
  }

  private paste(): void {
    navigator.clipboard.readText().then(text => {
      if (text) {
        this.sendKey(text);
      }
    });
  }

  private handleOrientationChange(): void {
    // Adjust layout for orientation
    setTimeout(() => {
      this.recalculateGrid();

      // Hide keyboard on orientation change
      if (this.virtualKeyboard) {
        this.virtualKeyboard.hide();
      }
    }, 100);
  }

  private addViewportMeta(): void {
    let viewport = document.querySelector('meta[name="viewport"]');
    if (!viewport) {
      viewport = document.createElement('meta');
      viewport.setAttribute('name', 'viewport');
      document.head.appendChild(viewport);
    }

    viewport.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover');
  }

  public toggleKeyboard(): void {
    this.virtualKeyboard?.toggle();
  }

  public destroy(): void {
    this.touchManager?.destroy();
    this.virtualKeyboard?.destroy();
    this.navigationUI?.remove();
    this.swipeIndicator?.remove();
    window.removeEventListener('orientationchange', () => this.handleOrientationChange());
  }
}

// Export a hook for Phoenix LiveView integration
import type { PhoenixLiveViewHook } from '../types/hooks';

export const MobileTerminalHook = {
  mounted(this: PhoenixLiveViewHook) {
    const container = this.el as HTMLElement;

    const mobileTerminal = new MobileTerminal({
      container,
      onCommand: (command) => {
        console.log('Mobile command:', command);
      },
      pushEvent: (event, payload) => {
        this.pushEvent?.(event, payload);
      }
    });

    // Store reference for cleanup
    (this.el as any).__mobileTerminal = mobileTerminal;
  },

  destroyed(this: PhoenixLiveViewHook) {
    const mobileTerminal = (this.el as any).__mobileTerminal;
    if (mobileTerminal) {
      mobileTerminal.destroy();
    }
  }
};