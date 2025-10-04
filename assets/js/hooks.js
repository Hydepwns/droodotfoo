// MonospaceGrid is not used in this simplified hook
// import MonospaceGrid from './terminal_grid';

const TerminalHook = {
  mounted() {
    console.log('Terminal hook mounted on:', this.el.id);

    // Load vim mode preference from localStorage and send to server
    const storedVimMode = localStorage.getItem('vim_mode');
    if (storedVimMode !== null) {
      const vimModeEnabled = storedVimMode === 'true';
      console.log('Loaded vim mode from localStorage:', vimModeEnabled);
      // Send to server to initialize state
      this.pushEvent('set_vim_mode', { enabled: vimModeEnabled });
    }

    // Load current section from localStorage and send to server
    const storedSection = localStorage.getItem('current_section');
    if (storedSection) {
      console.log('Loaded current section from localStorage:', storedSection);
      // Send to server to restore state
      this.pushEvent('restore_section', { section: storedSection });
    }

    // Load theme from localStorage and apply
    const storedTheme = localStorage.getItem('terminal_theme') || 'theme-synthwave84';
    console.log('Loaded theme from localStorage:', storedTheme);
    this.applyTheme(storedTheme);
    // Send to server
    this.pushEvent('set_theme', { theme: storedTheme });

    // Focus on the terminal wrapper to capture keyboard events
    this.el.setAttribute('tabindex', '0');
    this.el.focus();

    // Prevent default behavior for j/k and other navigation keys
    this.handleKeydown = (e) => {
      const navKeys = ['j', 'k', 'h', 'l', '/', 'Enter', 'Escape',
                       'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', '?'];

      if (navKeys.includes(e.key)) {
        e.preventDefault();
        console.log('Key prevented:', e.key);
      }
    };

    // Add keydown listener with preventDefault
    this.el.addEventListener('keydown', this.handleKeydown);

    // Handle clicks on terminal cells
    this.handleClick = (e) => {
      console.log('Click handler fired!', e);
      this.el.focus();

      // Find terminal line elements to calculate position
      const lines = this.el.querySelectorAll('.terminal-line');
      console.log('Found terminal lines:', lines.length);
      if (lines.length === 0) {
        console.log('No terminal lines found, cannot process click');
        console.log('Terminal wrapper HTML:', this.el.innerHTML.substring(0, 500));
        return;
      }

      // Get first line to calculate character width
      const firstLine = lines[0];
      const lineStyle = window.getComputedStyle(firstLine);

      // Calculate character width by measuring the line
      const temp = document.createElement('span');
      temp.style.font = lineStyle.font;
      temp.style.fontSize = lineStyle.fontSize;
      temp.style.fontFamily = lineStyle.fontFamily;
      temp.style.visibility = 'hidden';
      temp.style.position = 'absolute';
      temp.textContent = '0';
      document.body.appendChild(temp);
      const charWidth = temp.getBoundingClientRect().width;
      document.body.removeChild(temp);

      // Calculate which row was clicked
      let clickedRow = -1;
      lines.forEach((line, index) => {
        const rect = line.getBoundingClientRect();
        if (e.clientY >= rect.top && e.clientY <= rect.bottom) {
          clickedRow = index;
        }
      });

      if (clickedRow === -1) {
        console.log('Click outside terminal lines');
        return;
      }

      // Calculate column based on x position
      const clickedLine = lines[clickedRow];
      const lineRect = clickedLine.getBoundingClientRect();
      const x = e.clientX - lineRect.left;
      const col = Math.floor(x / charWidth);

      console.log('Cell clicked:', { row: clickedRow, col, charWidth });

      // Send cell click event to server
      this.pushEvent('cell_click', { row: clickedRow, col });
    };

    this.el.addEventListener('click', this.handleClick);
    console.log('Click event listener attached to:', this.el);

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

    // Handle vim mode changes from server
    this.handleEvent('vim_mode_changed', ({ enabled }) => {
      console.log('Vim mode changed:', enabled);
      // Save to localStorage for next session
      localStorage.setItem('vim_mode', enabled);
    });

    // Handle section changes from server
    this.handleEvent('section_changed', ({ section }) => {
      console.log('Section changed:', section);
      // Save to localStorage for session persistence
      localStorage.setItem('current_section', section);
    });

    // Handle theme changes from server
    this.handleEvent('theme_changed', ({ theme }) => {
      console.log('Theme changed:', theme);
      this.applyTheme(theme);
      // Save to localStorage
      localStorage.setItem('terminal_theme', theme);
    });
  },

  // Apply theme to the terminal wrapper
  applyTheme(theme) {
    const wrapper = this.el;
    if (!wrapper) return;

    // Remove all theme classes
    const themeClasses = [
      'theme-green', 'theme-amber', 'theme-high-contrast', 'theme-cyberpunk',
      'theme-matrix', 'theme-phosphor', 'theme-synthwave84',
      'theme-synthwave84-soft', 'theme-synthwave84-high'
    ];

    themeClasses.forEach(cls => wrapper.classList.remove(cls));

    // Add new theme class
    wrapper.classList.add(theme);
    console.log('Applied theme:', theme);
  },

  destroyed() {
    // Cleanup event listeners
    if (this.handleKeydown) {
      this.el.removeEventListener('keydown', this.handleKeydown);
    }
    if (this.handleClick) {
      this.el.removeEventListener('click', this.handleClick);
    }
    console.log('Terminal hook destroyed');
  }
};

// Export all hooks
export default {
  TerminalHook
};