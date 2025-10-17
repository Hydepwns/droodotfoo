/**
 * LiveView Bridge for Astro Spotify Widget
 * Handles communication between Phoenix LiveView and Astro Spotify Widget component
 */

import React from 'react';
import { createRoot } from 'react-dom/client';
import SpotifyWidget from '../components/SpotifyWidget.tsx';

interface SpotifyBridgeOptions {
  containerId: string;
  onTrackChange?: (track: any) => void;
  onStateChange?: (state: any) => void;
  onError?: (error: string) => void;
}

export class SpotifyBridge {
  private container: HTMLElement | null = null;
  private root: any = null;
  private options: SpotifyBridgeOptions;
  private eventListeners: Map<string, Function> = new Map();

  constructor(options: SpotifyBridgeOptions) {
    this.options = options;
    this.setupEventListeners();
  }

  private setupEventListeners() {
    // Listen for LiveView events
    document.addEventListener('phx:spotify_command', (event: CustomEvent) => {
      this.handleSpotifyCommand(event.detail);
    });

    // Listen for authentication events
    document.addEventListener('phx:spotify_auth', (event: CustomEvent) => {
      this.handleAuthEvent(event.detail);
    });
  }

  private handleSpotifyCommand(payload: { command: { type: string; [key: string]: any } }) {
    const { command } = payload;

    switch (command.type) {
      case 'play':
        this.dispatchToWidget('play');
        break;
      case 'pause':
        this.dispatchToWidget('pause');
        break;
      case 'next':
        this.dispatchToWidget('next');
        break;
      case 'previous':
        this.dispatchToWidget('previous');
        break;
      case 'seek':
        this.dispatchToWidget('seek', { position: command.position });
        break;
      case 'volume':
        this.dispatchToWidget('volume', { level: command.level });
        break;
      case 'load_playlist':
        this.dispatchToWidget('loadPlaylist', { id: command.playlistId });
        break;
      default:
        console.warn('Unknown Spotify command:', command.type);
    }
  }

  private handleAuthEvent(payload: { action: string; [key: string]: any }) {
    const { action } = payload;

    switch (action) {
      case 'authenticate':
        this.handleAuthentication();
        break;
      case 'logout':
        this.handleLogout();
        break;
      default:
        console.warn('Unknown auth action:', action);
    }
  }

  private dispatchToWidget(action: string, data?: any) {
    const event = new CustomEvent(`spotify-${action}`, { detail: data });
    document.dispatchEvent(event);
  }

  private handleAuthentication() {
    // Redirect to Spotify OAuth
    window.location.href = '/auth/spotify';
  }

  private handleLogout() {
    // Clear tokens and reset widget
    localStorage.removeItem('spotify_token');
    this.dispatchToWidget('logout');
  }

  public initializeWidget(container: HTMLElement, props: any = {}) {
    this.container = container;
    
    // Create React root
    this.root = createRoot(container);
    
    // Render React component
    this.root.render(
      React.createElement(SpotifyWidget, {
        ...props,
        onTrackChange: (track) => {
          this.handleTrackChange(track);
        },
        onStateChange: (state) => {
          this.handleStateChange(state);
        }
      })
    );

    // Set up widget event listeners
    this.setupWidgetEventListeners();
  }

  private setupWidgetEventListeners() {
    // Listen for widget events
    document.addEventListener('spotify-play', () => {
      this.sendToLiveView('play');
    });

    document.addEventListener('spotify-pause', () => {
      this.sendToLiveView('pause');
    });

    document.addEventListener('spotify-next', () => {
      this.sendToLiveView('next');
    });

    document.addEventListener('spotify-previous', () => {
      this.sendToLiveView('previous');
    });

    document.addEventListener('spotify-seek', (event: CustomEvent) => {
      this.sendToLiveView('seek', { position: event.detail.position });
    });

    document.addEventListener('spotify-volume', (event: CustomEvent) => {
      this.sendToLiveView('volume', { level: event.detail.level });
    });
  }

  private handleTrackChange(track: any) {
    if (this.options.onTrackChange) {
      this.options.onTrackChange(track);
    }

    // Send to LiveView
    this.sendToLiveView('track_changed', { track });
  }

  private handleStateChange(state: any) {
    if (this.options.onStateChange) {
      this.options.onStateChange(state);
    }

    // Send to LiveView
    this.sendToLiveView('state_changed', { state });
  }

  private sendToLiveView(event: string, payload?: any) {
    const eventData = new CustomEvent(`phx:${event}`, {
      detail: payload
    });
    document.dispatchEvent(eventData);
  }

  public destroy() {
    if (this.root) {
      this.root.unmount();
      this.root = null;
    }
    
    // Clean up event listeners
    this.eventListeners.forEach((handler, event) => {
      document.removeEventListener(event, handler as EventListener);
    });
    this.eventListeners.clear();
  }
}

export default SpotifyBridge;
