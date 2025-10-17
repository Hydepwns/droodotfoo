/**
 * Astro STL Viewer Integration for Phoenix LiveView
 * This file integrates the built Astro STL viewer component with Phoenix LiveView
 */

// Import the built Astro client code
// Note: The exact filename may change with builds, so we'll try to load it dynamically
try {
  // Try to load the Astro client code if it exists
  const astroClientScript = document.createElement('script');
  astroClientScript.src = '/astro/client.CJO0MmSH.js';
  astroClientScript.onerror = () => {
    console.log('[STL Viewer] Astro client not found, using fallback mode');
  };
  document.head.appendChild(astroClientScript);
} catch (error) {
  console.log('[STL Viewer] Could not load Astro client:', error);
}

// STL Viewer integration class
class AstroSTLViewerIntegration {
  constructor() {
    this.viewers = new Map();
    this.setupEventListeners();
  }

  setupEventListeners() {
    // Listen for LiveView events
    document.addEventListener('phx:stl_command', (event) => {
      this.handleSTLCommand(event.detail);
    });

    // Listen for model loaded events
    document.addEventListener('stl-model-loaded', (event) => {
      this.handleModelLoaded(event.detail);
    });

    // Listen for model error events
    document.addEventListener('stl-model-error', (event) => {
      this.handleModelError(event.detail);
    });
  }

  handleSTLCommand(payload) {
    const { command } = payload;
    
    // Dispatch to all active viewers
    this.viewers.forEach((viewer, id) => {
      this.sendCommandToViewer(id, command);
    });
  }

  sendCommandToViewer(viewerId, command) {
    const event = new CustomEvent(`stl-command-${viewerId}`, {
      detail: { command }
    });
    document.dispatchEvent(event);
  }

  handleModelLoaded(modelInfo) {
    // Dispatch to LiveView
    const event = new CustomEvent('phx:model_loaded', {
      detail: modelInfo
    });
    document.dispatchEvent(event);
  }

  handleModelError(errorInfo) {
    // Dispatch to LiveView
    const event = new CustomEvent('phx:model_error', {
      detail: errorInfo
    });
    document.dispatchEvent(event);
  }

  registerViewer(id, viewer) {
    this.viewers.set(id, viewer);
  }

  unregisterViewer(id) {
    this.viewers.delete(id);
  }
}

// Global instance
window.astroSTLViewerIntegration = new AstroSTLViewerIntegration();

// Export for use in other modules
export default AstroSTLViewerIntegration;
