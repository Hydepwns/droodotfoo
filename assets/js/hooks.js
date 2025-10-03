// MonospaceGrid is not used in this simplified hook
// import MonospaceGrid from './terminal_grid';

const TerminalHook = {
  el: null,

  mounted() {
    console.log('Terminal hook mounted on:', this.el.id);

    // Store reference to el
    this.el = this.el || document.getElementById('terminal-wrapper');

    // Focus on the terminal wrapper to capture keyboard events
    this.el.setAttribute('tabindex', '0');
    this.el.focus();

    // Prevent default behavior for j/k and other navigation keys
    this.handleKeydown = (e) => {
      const navKeys = ['j', 'k', 'h', 'l', '/', 'Enter', 'Escape',
                       'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'];

      if (navKeys.includes(e.key)) {
        e.preventDefault();
        console.log('Key prevented:', e.key);
      }
    };

    // Add keydown listener with preventDefault
    this.el.addEventListener('keydown', this.handleKeydown);

    // Keep terminal focused when clicking anywhere on it
    this.el.addEventListener('click', () => {
      this.el.focus();
      console.log('Terminal focused');
    });

    // Debug: log when terminal loses focus
    this.el.addEventListener('blur', () => {
      console.log('Terminal lost focus');
    });

    // Verify grid alignment after each update
    this.handleEvent('terminal_updated', () => {
      requestAnimationFrame(() => {
        // Grid alignment check can go here if needed
        console.log('Terminal updated');
      });
    });
  },

  destroyed() {
    // Cleanup event listeners
    if (this.handleKeydown) {
      this.el.removeEventListener('keydown', this.handleKeydown);
    }
    console.log('Terminal hook destroyed');
  }
};

// Export all hooks
export default {
  TerminalHook
};