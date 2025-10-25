/**
 * Astro PWA Hook
 * Phoenix LiveView hook that integrates with Astro PWA components
 */

export const AstroPWAHook = {
  mounted() {
    console.log('Astro PWA hook mounted');
    
    // Wait for Astro component to be ready
    this.waitForAstroComponent();
  },

  waitForAstroComponent() {
    const checkInterval = setInterval(() => {
      const astroComponent = this.el.querySelector('#pwa-install-container');
      if (astroComponent) {
        clearInterval(checkInterval);
        this.initializeAstroIntegration();
      }
    }, 100);

    // Timeout after 5 seconds
    setTimeout(() => {
      clearInterval(checkInterval);
      console.warn('Astro PWA component not found after timeout');
    }, 5000);
  },

  initializeAstroIntegration() {
    // Listen for events from Astro component
    window.addEventListener('pwa-install-available', (event) => {
      this.handleInstallAvailable(event.detail);
    });

    window.addEventListener('pwa-installed', (event) => {
      this.handleInstalled(event.detail);
    });

    window.addEventListener('pwa-update-available', (event) => {
      this.handleUpdateAvailable(event.detail);
    });

    window.addEventListener('pwa-status-changed', (event) => {
      this.handleStatusChanged(event.detail);
    });

    // Listen for LiveView events to send to Astro component
    this.handleEvent('pwa_command', (payload) => {
      this.sendCommandToAstro(payload);
    });

    console.log('Astro PWA integration initialized');
  },

  handleInstallAvailable(detail) {
    console.log('PWA install available in Astro component:', detail);
    
    // Send install available info back to LiveView
    if (this.pushEvent) {
      this.pushEvent('pwa_install_available', {
        canInstall: detail.canInstall
      });
    }
  },

  handleInstalled(detail) {
    console.log('PWA installed in Astro component:', detail);
    
    // Send installed info back to LiveView
    if (this.pushEvent) {
      this.pushEvent('pwa_installed', {
        isInstalled: detail.isInstalled
      });
    }
  },

  handleUpdateAvailable(detail) {
    console.log('PWA update available in Astro component:', detail);
    
    // Send update available info back to LiveView
    if (this.pushEvent) {
      this.pushEvent('pwa_update_available', {
        hasUpdate: true
      });
    }
  },

  handleStatusChanged(detail) {
    console.log('PWA status changed in Astro component:', detail);
    
    // Send status change back to LiveView
    if (this.pushEvent) {
      this.pushEvent('pwa_status_changed', detail);
    }
  },

  sendCommandToAstro(payload) {
    // Dispatch command to Astro component
    const event = new CustomEvent('phx:pwa_command', {
      detail: payload
    });
    document.dispatchEvent(event);
  },

  destroyed() {
    console.log('Astro PWA hook destroyed');
    
    // Clean up event listeners
    window.removeEventListener('pwa-install-available', this.handleInstallAvailable);
    window.removeEventListener('pwa-installed', this.handleInstalled);
    window.removeEventListener('pwa-update-available', this.handleUpdateAvailable);
    window.removeEventListener('pwa-status-changed', this.handleStatusChanged);
  }
};

export default {
  AstroPWAHook
};
