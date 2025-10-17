/**
 * Astro STL Viewer Hook
 * Phoenix LiveView hook that integrates with Astro STL Viewer component
 */

export const AstroSTLViewerHook = {
  mounted() {
    console.log('Astro STL Viewer hook mounted');
    
    // Wait for Astro component to be ready
    this.waitForAstroComponent();
  },

  waitForAstroComponent() {
    const checkInterval = setInterval(() => {
      const astroComponent = this.el.querySelector('#stl-viewer-wrapper');
      if (astroComponent) {
        clearInterval(checkInterval);
        this.initializeAstroIntegration();
      }
    }, 100);

    // Timeout after 5 seconds
    setTimeout(() => {
      clearInterval(checkInterval);
      console.warn('Astro STL Viewer component not found after timeout');
    }, 5000);
  },

  initializeAstroIntegration() {
    // Listen for events from Astro component
    window.addEventListener('stl-model-loaded', (event) => {
      this.handleModelLoaded(event.detail);
    });

    window.addEventListener('stl-model-error', (event) => {
      this.handleModelError(event.detail);
    });

    // Listen for LiveView events to send to Astro component
    this.handleEvent('stl_command', (payload) => {
      this.sendCommandToAstro(payload);
    });

    console.log('Astro STL Viewer integration initialized');
  },

  handleModelLoaded(modelInfo) {
    console.log('Model loaded in Astro component:', modelInfo);
    
    // Send model info back to LiveView
    if (this.pushEvent) {
      this.pushEvent('model_loaded', {
        triangles: modelInfo.triangles,
        vertices: modelInfo.vertices,
        bounds: modelInfo.bounds
      });
    }
  },

  handleModelError(errorInfo) {
    console.error('Model error in Astro component:', errorInfo);
    
    // Send error back to LiveView
    if (this.pushEvent) {
      this.pushEvent('model_error', { error: errorInfo.error });
    }
  },

  sendCommandToAstro(payload) {
    // Dispatch command to Astro component
    const event = new CustomEvent('phx:stl_command', {
      detail: payload
    });
    document.dispatchEvent(event);
  },

  destroyed() {
    console.log('Astro STL Viewer hook destroyed');
    
    // Clean up event listeners
    window.removeEventListener('stl-model-loaded', this.handleModelLoaded);
    window.removeEventListener('stl-model-error', this.handleModelError);
  }
};

export default {
  AstroSTLViewerHook
};
