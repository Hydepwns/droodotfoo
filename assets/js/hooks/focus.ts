/**
 * Focus management hook for form accessibility
 * Handles focus events from LiveView server
 */

export const FocusHook = {
  mounted() {
    this.handleEvent("focus", ({ target }: { target: string }) => {
      const element = document.getElementById(target);
      if (element) {
        // Small delay to ensure DOM is updated after LiveView patch
        requestAnimationFrame(() => {
          element.focus();
          // Scroll into view if needed
          element.scrollIntoView({ behavior: "smooth", block: "center" });
        });
      }
    });
  },
};
