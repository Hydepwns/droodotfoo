// Terminal-specific hook - critical for initial render
export const TerminalHook = {
  mounted() {
    this.handleResize = () => {
      const wrapper = document.getElementById("terminal-wrapper");
      if (wrapper) {
        const rect = wrapper.getBoundingClientRect();
        const charWidth = parseFloat(
          getComputedStyle(wrapper).getPropertyValue("--char-width") || "9.6"
        );
        const cols = Math.floor(rect.width / charWidth);

        // Push resize event to server if needed
        this.pushEvent("terminal-resize", { cols });
      }
    };

    // Initial setup
    this.handleResize();

    // Debounced resize handler
    let resizeTimeout;
    window.addEventListener("resize", () => {
      clearTimeout(resizeTimeout);
      resizeTimeout = setTimeout(() => this.handleResize(), 100);
    });

    // Focus terminal input on mount
    const input = document.getElementById("terminal-input");
    if (input) {
      input.focus();
    }
  },

  updated() {
    // Maintain focus on terminal input
    const input = document.getElementById("terminal-input");
    if (input && document.activeElement !== input) {
      input.focus();
    }
  },

  destroyed() {
    // Cleanup event listeners
    window.removeEventListener("resize", this.handleResize);
  },
};