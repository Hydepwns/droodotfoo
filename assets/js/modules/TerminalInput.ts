/**
 * Enhanced terminal input handling for proper keyboard capture
 */

export interface TerminalInputConfig {
  element: HTMLInputElement;
  onKeyPress: (key: string) => void;
  terminalWrapper?: HTMLElement;
}

export class TerminalInputHandler {
  private element: HTMLInputElement;
  private onKeyPress: (key: string) => void;
  private terminalWrapper?: HTMLElement;
  private isComposing: boolean = false;
  private lastValue: string = '';

  constructor(config: TerminalInputConfig) {
    this.element = config.element;
    this.onKeyPress = config.onKeyPress;
    this.terminalWrapper = config.terminalWrapper;

    this.attachEventListeners();
    this.ensureFocus();
  }

  private attachEventListeners(): void {
    // Handle keydown for special keys
    this.element.addEventListener('keydown', (e: KeyboardEvent) => {
      // Handle special keys that don't produce input
      const specialKeys = [
        'Enter', 'Escape', 'Tab', 'ArrowUp', 'ArrowDown',
        'ArrowLeft', 'ArrowRight', 'Home', 'End',
        'PageUp', 'PageDown', 'Delete'
      ];

      if (specialKeys.includes(e.key)) {
        e.preventDefault();
        this.onKeyPress(e.key);
        return;
      }

      // Handle Backspace
      if (e.key === 'Backspace') {
        e.preventDefault();
        this.onKeyPress('Backspace');
        return;
      }

      // Handle Ctrl/Cmd combinations
      if (e.ctrlKey || e.metaKey) {
        if (e.key === 'c') {
          e.preventDefault();
          this.onKeyPress('Control+c');
        } else if (e.key === 'v') {
          // Allow paste to go through
          return;
        } else if (e.key === 'a') {
          e.preventDefault();
          this.onKeyPress('Control+a');
        } else if (e.key === 'e') {
          e.preventDefault();
          this.onKeyPress('Control+e');
        } else if (e.key === 'u') {
          e.preventDefault();
          this.onKeyPress('Control+u');
        } else if (e.key === 'k') {
          e.preventDefault();
          this.onKeyPress('Control+k');
        } else if (e.key === 'l') {
          e.preventDefault();
          this.onKeyPress('Control+l');
        } else if (e.key === 'w') {
          e.preventDefault();
          this.onKeyPress('Control+w');
        }
        return;
      }
    });

    // Handle regular character input
    this.element.addEventListener('input', (e: Event) => {
      if (this.isComposing) return;

      const currentValue = this.element.value;

      // Detect what was typed
      if (currentValue.length > this.lastValue.length) {
        // Characters were added
        const newChars = currentValue.slice(this.lastValue.length);
        for (const char of newChars) {
          this.onKeyPress(char);
        }
      }

      // Clear the input field after processing
      this.element.value = '';
      this.lastValue = '';
    });

    // Handle paste events
    this.element.addEventListener('paste', (e: ClipboardEvent) => {
      e.preventDefault();
      const pastedText = e.clipboardData?.getData('text');
      if (pastedText) {
        // Send each character of pasted text
        for (const char of pastedText) {
          if (char === '\n') {
            this.onKeyPress('Enter');
          } else {
            this.onKeyPress(char);
          }
        }
      }
    });

    // Handle composition events for IME input
    this.element.addEventListener('compositionstart', () => {
      this.isComposing = true;
    });

    this.element.addEventListener('compositionend', (e: CompositionEvent) => {
      this.isComposing = false;
      // Process the composed text
      if (e.data) {
        for (const char of e.data) {
          this.onKeyPress(char);
        }
      }
      this.element.value = '';
      this.lastValue = '';
    });

    // Keep focus on the input
    this.element.addEventListener('blur', () => {
      // Re-focus after a short delay unless user clicked outside terminal
      setTimeout(() => {
        if (document.activeElement?.tagName !== 'INPUT' &&
            document.activeElement?.tagName !== 'TEXTAREA') {
          this.ensureFocus();
        }
      }, 100);
    });

    // Click on terminal should focus input
    if (this.terminalWrapper) {
      this.terminalWrapper.addEventListener('click', () => {
        this.ensureFocus();
      });
    }
  }

  public ensureFocus(): void {
    if (this.element && document.activeElement !== this.element) {
      this.element.focus();
      // Ensure cursor is at the end
      this.element.setSelectionRange(
        this.element.value.length,
        this.element.value.length
      );
    }
  }

  public destroy(): void {
    // Clean up event listeners if needed
    this.element.value = '';
  }
}

// Create a Phoenix LiveView hook
export const TerminalInputHook = {
  mounted() {
    const input = document.getElementById('terminal-input') as HTMLInputElement;
    const terminalWrapper = document.querySelector('.terminal-wrapper') as HTMLElement;

    if (!input) {
      console.error('Terminal input element not found');
      return;
    }

    const handler = new TerminalInputHandler({
      element: input,
      terminalWrapper: terminalWrapper,
      onKeyPress: (key: string) => {
        // Send key to LiveView
        this.pushEvent('key_press', { key });
      }
    });

    // Store handler for cleanup
    (this as any).__inputHandler = handler;
  },

  destroyed() {
    const handler = (this as any).__inputHandler;
    if (handler) {
      handler.destroy();
    }
  }
};