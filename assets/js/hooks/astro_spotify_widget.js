/**
 * Astro Spotify Widget Hook
 * Phoenix LiveView hook that integrates with Astro Spotify Widget component
 */

export const AstroSpotifyWidgetHook = {
  mounted() {
    console.log('Astro Spotify Widget hook mounted');
    
    // Wait for Astro component to be ready
    this.waitForAstroComponent();
  },

  waitForAstroComponent() {
    const checkInterval = setInterval(() => {
      const astroComponent = this.el.querySelector('#spotify-widget-container');
      if (astroComponent) {
        clearInterval(checkInterval);
        this.initializeAstroIntegration();
      }
    }, 100);

    // Timeout after 5 seconds
    setTimeout(() => {
      clearInterval(checkInterval);
      console.warn('Astro Spotify Widget component not found after timeout');
    }, 5000);
  },

  initializeAstroIntegration() {
    // Listen for events from Astro component
    window.addEventListener('spotify-track-changed', (event) => {
      this.handleTrackChanged(event.detail);
    });

    window.addEventListener('spotify-state-changed', (event) => {
      this.handleStateChanged(event.detail);
    });

    window.addEventListener('spotify-error', (event) => {
      this.handleError(event.detail);
    });

    // Listen for LiveView events to send to Astro component
    this.handleEvent('spotify_command', (payload) => {
      this.sendCommandToAstro(payload);
    });

    // Listen for authentication events
    this.handleEvent('spotify_auth', (payload) => {
      this.handleAuthEvent(payload);
    });

    console.log('Astro Spotify Widget integration initialized');
  },

  handleTrackChanged(track) {
    console.log('Track changed in Astro component:', track);
    
    // Send track info back to LiveView
    if (this.pushEvent) {
      this.pushEvent('track_changed', {
        track: track
      });
    }
  },

  handleStateChanged(state) {
    console.log('State changed in Astro component:', state);
    
    // Send state back to LiveView
    if (this.pushEvent) {
      this.pushEvent('state_changed', {
        state: state
      });
    }
  },

  handleError(errorInfo) {
    console.error('Error in Astro component:', errorInfo);
    
    // Send error back to LiveView
    if (this.pushEvent) {
      this.pushEvent('spotify_error', { error: errorInfo.error });
    }
  },

  sendCommandToAstro(payload) {
    // Dispatch command to Astro component
    const event = new CustomEvent('phx:spotify_command', {
      detail: payload
    });
    document.dispatchEvent(event);
  },

  handleAuthEvent(payload) {
    // Handle authentication events
    const { action } = payload;
    
    switch (action) {
      case 'authenticate':
        // Redirect to Spotify OAuth
        window.location.href = '/auth/spotify';
        break;
      case 'logout':
        // Clear tokens and reset widget
        localStorage.removeItem('spotify_token');
        this.sendCommandToAstro({ command: { type: 'logout' } });
        break;
      default:
        console.warn('Unknown auth action:', action);
    }
  },

  destroyed() {
    console.log('Astro Spotify Widget hook destroyed');
    
    // Clean up event listeners
    window.removeEventListener('spotify-track-changed', this.handleTrackChanged);
    window.removeEventListener('spotify-state-changed', this.handleStateChanged);
    window.removeEventListener('spotify-error', this.handleError);
  }
};

export default {
  AstroSpotifyWidgetHook
};
