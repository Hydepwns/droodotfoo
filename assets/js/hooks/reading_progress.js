/**
 * Reading Progress Hook
 * Displays a progress bar at the top of blog posts showing scroll progress
 */
export const ReadingProgressHook = {
  mounted() {
    this.progressBar = this.el.querySelector('.reading-progress-bar');

    if (!this.progressBar) {
      console.error('Reading progress bar element not found');
      return;
    }

    // Update progress on scroll
    this.handleScroll = () => {
      const windowHeight = window.innerHeight;
      const documentHeight = document.documentElement.scrollHeight;
      const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

      // Calculate progress percentage
      const scrollableHeight = documentHeight - windowHeight;
      const progress = scrollableHeight > 0 ? (scrollTop / scrollableHeight) * 100 : 0;

      // Update progress bar width
      this.progressBar.style.width = `${Math.min(100, Math.max(0, progress))}%`;
    };

    // Attach scroll listener with throttling for performance
    let ticking = false;
    this.throttledScroll = () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          this.handleScroll();
          ticking = false;
        });
        ticking = true;
      }
    };

    window.addEventListener('scroll', this.throttledScroll, { passive: true });

    // Initialize on mount
    this.handleScroll();
  },

  destroyed() {
    if (this.throttledScroll) {
      window.removeEventListener('scroll', this.throttledScroll);
    }
  }
};
