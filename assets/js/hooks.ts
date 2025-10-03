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

export const TerminalHook: TerminalHookInstance = {
  el: document.createElement('div') as PhoenixHookElement,
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
    terminalKeys: ['j', 'k', 'h', 'l', '/', 'Enter', 'Escape', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'],
    preventDefault: true,
    stopPropagation: false
  },
  eventListeners: new Map(),

  mounted() {
    try {
      this.terminal = this.el.querySelector('.terminal-container');

      if (!this.terminal) {
        console.error('Terminal container not found');
        return;
      }

      // Initialize the monospace grid
      this.grid = new MonospaceGrid(this.terminal);
      console.log('Terminal grid initialized');

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

// Export all hooks
export default {
  TerminalHook
};