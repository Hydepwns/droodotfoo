/**
 * Astro PWA Integration for Phoenix
 * Initializes and manages Astro PWA components within Phoenix LiveView
 */

// Import the PWA Install component
import PWAInstall from '../astro/PWAInstall.astro_astro_type_script_index_0_lang.H55kpqIP.js';

class AstroPWAIntegration {
  constructor() {
    this.initialized = false;
    this.components = new Map();
    this.setupEventListeners();
  }

  setupEventListeners() {
    // Listen for LiveView mount events
    document.addEventListener('phx:mount', (event) => {
      this.handleLiveViewMount(event);
    });

    // Listen for PWA-specific events
    document.addEventListener('phx:pwa_command', (event) => {
      this.handlePWACommand(event.detail);
    });

    // Listen for Astro component events
    document.addEventListener('pwa-install-available', (event) => {
      this.handleInstallAvailable(event.detail);
    });

    document.addEventListener('pwa-installed', (event) => {
      this.handleInstalled(event.detail);
    });

    document.addEventListener('pwa-update-available', (event) => {
      this.handleUpdateAvailable(event.detail);
    });
  }

  handleLiveViewMount(event) {
    const target = event.target;
    const pwaContainer = target.querySelector('#astro-pwa-install');
    
    if (pwaContainer && !this.components.has(pwaContainer.id)) {
      this.initializePWAComponent(pwaContainer);
    }
  }

  initializePWAComponent(container) {
    try {
      // Create PWA Install component instance
      const pwaComponent = new PWAInstall({
        target: container,
        props: {
          theme: 'default',
          position: 'top-right',
          autoShow: true
        }
      });

      // Store component reference
      this.components.set(container.id, pwaComponent);

      console.log('Astro PWA component initialized:', container.id);
    } catch (error) {
      console.error('Failed to initialize Astro PWA component:', error);
    }
  }

  handlePWACommand(payload) {
    const { command } = payload;
    
    // Dispatch command to all PWA components
    this.components.forEach((component, id) => {
      try {
        switch (command.type) {
          case 'install':
            component.promptInstall();
            break;
          case 'update':
            component.applyUpdate();
            break;
          case 'clear_cache':
            component.clearCaches();
            break;
          case 'get_status':
            this.sendStatusToLiveView(component.getStatus());
            break;
        }
      } catch (error) {
        console.error(`Error executing PWA command on component ${id}:`, error);
      }
    });
  }

  handleInstallAvailable(detail) {
    console.log('PWA install available:', detail);
    
    // Notify LiveView
    this.sendToLiveView('pwa_install_available', detail);
  }

  handleInstalled(detail) {
    console.log('PWA installed:', detail);
    
    // Notify LiveView
    this.sendToLiveView('pwa_installed', detail);
  }

  handleUpdateAvailable(detail) {
    console.log('PWA update available:', detail);
    
    // Notify LiveView
    this.sendToLiveView('pwa_update_available', detail);
  }

  sendStatusToLiveView(status) {
    this.sendToLiveView('pwa_status', status);
  }

  sendToLiveView(event, payload) {
    const eventData = new CustomEvent(`phx:${event}`, {
      detail: payload
    });
    document.dispatchEvent(eventData);
  }

  destroy() {
    // Clean up all components
    this.components.forEach((component, id) => {
      try {
        if (component.destroy) {
          component.destroy();
        }
      } catch (error) {
        console.error(`Error destroying PWA component ${id}:`, error);
      }
    });
    
    this.components.clear();
    this.initialized = false;
  }
}

// Initialize PWA integration
const astroPWAIntegration = new AstroPWAIntegration();

// Export for global access
window.AstroPWAIntegration = astroPWAIntegration;

console.log('Astro PWA integration loaded');
