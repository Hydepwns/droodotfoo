/**
 * Phoenix LiveView hooks for terminal functionality
 */
import MonospaceGrid from './terminal_grid';
import { PhoenixLiveViewHook, PhoenixHookElement, TerminalHookConfig, KeyboardHandlerConfig } from './types/hooks';
import { MobileTerminal } from './modules/MobileTerminal';
import { isMobileDevice } from './modules/TouchGestures';
import { TerminalInputHandler } from './modules/TerminalInput';

interface TerminalHookInstance extends PhoenixLiveViewHook {
  terminal: HTMLElement | null;
  grid: MonospaceGrid | null;
  mobileTerminal: MobileTerminal | null;
  inputHandler: TerminalInputHandler | null;
  config: TerminalHookConfig;
  keyboardConfig: KeyboardHandlerConfig;
  eventListeners: Map<EventTarget, Map<string, EventListener>>;
  setupKeyboardHandlers: () => void;
  isTerminalKey: (key: string) => boolean;
  verifyAlignment: () => void;
  addEventListener: (target: EventTarget, event: string, handler: EventListener) => void;
  removeAllEventListeners: () => void;
}

export const TerminalHook: Partial<TerminalHookInstance> = {
  terminal: null,
  grid: null,
  mobileTerminal: null,
  inputHandler: null,
  config: {
    enableDebug: process.env.NODE_ENV === 'development',
    focusOnClick: true,
    verifyAlignment: true
  },
  keyboardConfig: {
    terminalKeys: ['/', 'Enter', 'Escape', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'],
    preventDefault: true,
    stopPropagation: false
  },
  eventListeners: new Map(),

  mounted() {
    try {
      this.terminal = this.el.querySelector('.terminal-container');

      if (!this.terminal) {
        console.log('Terminal container not found yet (boot sequence), will initialize on update');
        // Don't return - continue to set up other hooks
      } else {
        // Initialize the monospace grid
        this.grid = new MonospaceGrid(this.terminal);
        console.log('Terminal grid initialized');
      }

      // Initialize mobile terminal support if on mobile device
      if (isMobileDevice()) {
        this.mobileTerminal = new MobileTerminal({
          container: this.el,
          onCommand: (command) => {
            console.log('Mobile command:', command);
          },
          pushEvent: this.pushEvent ? (event, payload) => {
            this.pushEvent!(event, payload);
          } : undefined
        });
        console.log('Mobile terminal initialized');
      }

      // Set up enhanced input handler
      const input = document.getElementById('terminal-input') as HTMLInputElement;
      const terminalWrapper = this.el.querySelector('.terminal-wrapper') as HTMLElement;

      console.log('Looking for terminal input element...');
      console.log('Input element found:', !!input);
      console.log('Terminal wrapper found:', !!terminalWrapper);
      console.log('pushEvent available:', !!this.pushEvent);

      if (input) {
        this.inputHandler = new TerminalInputHandler({
          element: input,
          terminalWrapper: terminalWrapper,
          onKeyPress: (key: string) => {
            // Send key to LiveView - using arrow function preserves 'this' context
            if (this.pushEvent && typeof this.pushEvent === 'function') {
              this.pushEvent('key_press', { key });
            }
          }
        });
        console.log('Terminal input handler initialized successfully');
      } else {
        console.error('Terminal input element not found! Check if #terminal-input exists in DOM');
      }

      // Set up keyboard handlers (for backward compatibility)
      this.setupKeyboardHandlers();

      // Handle terminal updates
      if (this.handleEvent) {
        this.handleEvent('terminal_updated', () => {
          requestAnimationFrame(() => {
            if (this.grid) {
              try {
                this.grid.enforceGrid();
                if (this.config.verifyAlignment) {
                  this.verifyAlignment();
                }
              } catch (error) {
                console.error('Error updating grid:', error);
              }
            }
          });
        });
      }

      // Subscribe to grid events
      if (this.grid) {
        this.grid.on('gridResized', () => {
          console.log('Grid resized');
        });

        this.grid.on('fontLoaded', () => {
          console.log('Font loaded, grid updated');
        });
      }

      // Add click handler for cell selection
      this.addEventListener(this.el, 'click', (e: Event) => {
        if (!(e instanceof MouseEvent)) return;

        const lines = this.el.querySelectorAll('.terminal-line');
        if (lines.length === 0) {
          console.log('No terminal lines found for click');
          return;
        }

        // Calculate which row was clicked
        let clickedRow = -1;
        lines.forEach((line, index) => {
          const rect = line.getBoundingClientRect();
          if (e.clientY >= rect.top && e.clientY <= rect.bottom) {
            clickedRow = index;
          }
        });

        if (clickedRow === -1) return;

        // Calculate character width
        const firstLine = lines[0] as HTMLElement;
        const style = window.getComputedStyle(firstLine);
        const temp = document.createElement('span');
        temp.style.font = style.font;
        temp.style.fontSize = style.fontSize;
        temp.style.fontFamily = style.fontFamily;
        temp.style.visibility = 'hidden';
        temp.style.position = 'absolute';
        temp.textContent = '0';
        document.body.appendChild(temp);
        const charWidth = temp.getBoundingClientRect().width;
        document.body.removeChild(temp);

        const clickedLine = lines[clickedRow] as HTMLElement;
        const lineRect = clickedLine.getBoundingClientRect();
        const col = Math.floor((e.clientX - lineRect.left) / charWidth);

        console.log('Cell clicked:', { row: clickedRow, col, charWidth });

        if (this.pushEvent) {
          this.pushEvent('cell_click', { row: clickedRow, col });
        }
      });
    } catch (error) {
      console.error('Failed to mount TerminalHook:', error);
    }
  },

  setupKeyboardHandlers() {
    if (!this.config.focusOnClick || !this.el) {
      return;
    }

    // Focus on the hidden input when clicking the terminal
    const clickHandler = () => {
      const input = document.getElementById('terminal-input');
      if (input && input instanceof HTMLInputElement) {
        input.focus();
      }
    };

    this.addEventListener(this.el, 'click', clickHandler);

    // Handle keyboard events on the hidden input
    const input = document.getElementById('terminal-input');
    if (!input) {
      console.warn('Terminal input element not found');
      return;
    }

    // Prevent default behavior for terminal keys
    const keydownHandler = (e: Event) => {
      if (e instanceof KeyboardEvent && this.isTerminalKey(e.key)) {
        if (this.keyboardConfig.preventDefault) {
          e.preventDefault();
        }
        if (this.keyboardConfig.stopPropagation) {
          e.stopPropagation();
        }
      }
    };

    this.addEventListener(input, 'keydown', keydownHandler);
  },

  isTerminalKey(key: string): boolean {
    return this.keyboardConfig.terminalKeys?.includes(key) ?? false;
  },

  verifyAlignment() {
    if (!this.terminal || !this.grid) {
      return;
    }

    try {
      const cells = this.terminal.querySelectorAll('.cell');
      let misaligned = 0;

      cells.forEach((cell) => {
        if (cell instanceof HTMLElement && !this.grid!.isAligned(cell)) {
          misaligned++;
          if (this.config.enableDebug) {
            cell.classList.add('misaligned');
          }
        } else if (cell instanceof HTMLElement && this.config.enableDebug) {
          cell.classList.remove('misaligned');
        }
      });

      if (misaligned > 0) {
        console.warn(`${misaligned} cells are misaligned!`);
      }
    } catch (error) {
      console.error('Failed to verify alignment:', error);
    }
  },

  addEventListener(target: EventTarget, event: string, handler: EventListener) {
    if (!this.eventListeners.has(target)) {
      this.eventListeners.set(target, new Map());
    }

    const targetListeners = this.eventListeners.get(target)!;

    // Remove existing listener if present
    if (targetListeners.has(event)) {
      target.removeEventListener(event, targetListeners.get(event)!);
    }

    target.addEventListener(event, handler);
    targetListeners.set(event, handler);
  },

  removeAllEventListeners() {
    this.eventListeners.forEach((listeners, target) => {
      listeners.forEach((handler, event) => {
        target.removeEventListener(event, handler);
      });
    });
    this.eventListeners.clear();
  },

  updated() {
    // Initialize grid if terminal container appeared after boot sequence
    if (!this.terminal || !this.grid) {
      const container = this.el.querySelector('.terminal-container');
      if (container instanceof HTMLElement) {
        this.terminal = container;
        this.grid = new MonospaceGrid(this.terminal);
        console.log('Terminal grid initialized on update');
      }
    }
  },

  destroyed() {
    try {
      // Clean up grid
      if (this.grid) {
        this.grid.destroy();
        this.grid = null;
      }

      // Clean up mobile terminal
      if (this.mobileTerminal) {
        this.mobileTerminal.destroy();
        this.mobileTerminal = null;
      }

      // Clean up input handler
      if (this.inputHandler) {
        this.inputHandler.destroy();
        this.inputHandler = null;
      }

      // Remove all event listeners
      this.removeAllEventListeners();

      // Clear references
      this.terminal = null;

      console.log('TerminalHook cleaned up');
    } catch (error) {
      console.error('Error during cleanup:', error);
    }
  },

  disconnected() {
    console.log('TerminalHook disconnected');
  },

  reconnected() {
    console.log('TerminalHook reconnected');

    // Re-initialize grid if needed
    if (this.terminal && !this.grid) {
      try {
        this.grid = new MonospaceGrid(this.terminal);
        console.log('Grid re-initialized after reconnection');
      } catch (error) {
        console.error('Failed to re-initialize grid:', error);
      }
    }
  }
};

import { STLViewerHook } from './hooks/stl_viewer';

// Export all hooks
export default {
  TerminalHook,
  STLViewerHook
};