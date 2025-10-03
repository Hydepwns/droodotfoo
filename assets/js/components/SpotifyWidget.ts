/**
 * Spotify Web Component with TEA/Elm architecture
 * Standalone widget for non-terminal pages with Shadow DOM encapsulation
 */

// Model
interface SpotifyModel {
  state: 'idle' | 'loading' | 'ready' | 'playing' | 'error';
  player: Spotify.Player | null;
  deviceId: string | null;
  currentTrack: Spotify.Track | null;
  isPaused: boolean;
  position: number;
  duration: number;
  volume: number;
  playlist: any | null;
  error: string | null;
}

// Messages
type SpotifyMsg =
  | { type: 'INIT' }
  | { type: 'PLAYER_READY'; deviceId: string }
  | { type: 'STATE_CHANGED'; state: Spotify.PlaybackState }
  | { type: 'PLAY' }
  | { type: 'PAUSE' }
  | { type: 'NEXT' }
  | { type: 'PREVIOUS' }
  | { type: 'SEEK'; position: number }
  | { type: 'VOLUME'; level: number }
  | { type: 'LOAD_PLAYLIST'; id: string }
  | { type: 'ERROR'; message: string };

export class SpotifyWidget extends HTMLElement {
  private shadow: ShadowRoot;
  private model: SpotifyModel = {
    state: 'idle',
    player: null,
    deviceId: null,
    currentTrack: null,
    isPaused: true,
    position: 0,
    duration: 0,
    volume: 50,
    playlist: null,
    error: null
  };

  constructor() {
    super();
    this.shadow = this.attachShadow({ mode: 'open' });
  }

  connectedCallback() {
    this.dispatch({ type: 'INIT' });
  }

  disconnectedCallback() {
    this.model.player?.disconnect();
  }

  // Update function (TEA pattern)
  private dispatch(msg: SpotifyMsg): void {
    const [newModel, cmd] = this.update(this.model, msg);
    this.model = newModel;
    this.render();
    this.executeCmd(cmd);
  }

  private update(model: SpotifyModel, msg: SpotifyMsg): [SpotifyModel, (() => void) | null] {
    switch (msg.type) {
      case 'INIT':
        return [{ ...model, state: 'loading' }, () => this.initPlayer()];

      case 'PLAYER_READY':
        return [{ ...model, state: 'ready', deviceId: msg.deviceId }, null];

      case 'STATE_CHANGED':
        if (!msg.state) return [model, null];
        return [{
          ...model,
          state: 'playing',
          currentTrack: msg.state.track_window.current_track,
          isPaused: msg.state.paused,
          position: msg.state.position,
          duration: msg.state.duration
        }, null];

      case 'PLAY':
        return [model, () => this.model.player?.resume()];

      case 'PAUSE':
        return [model, () => this.model.player?.pause()];

      case 'NEXT':
        return [model, () => this.model.player?.nextTrack()];

      case 'PREVIOUS':
        return [model, () => this.model.player?.previousTrack()];

      case 'SEEK':
        return [{ ...model, position: msg.position }, () => this.model.player?.seek(msg.position)];

      case 'VOLUME':
        return [{ ...model, volume: msg.level }, () => this.model.player?.setVolume(msg.level / 100)];

      case 'ERROR':
        return [{ ...model, state: 'error', error: msg.message }, null];

      default:
        return [model, null];
    }
  }

  private executeCmd(cmd: (() => void) | null): void {
    cmd?.();
  }

  // View
  private render(): void {
    this.shadow.innerHTML = `
      <style>
        :host {
          display: block;
          font-family: system-ui, -apple-system, sans-serif;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border-radius: 12px;
          padding: 20px;
          color: white;
          box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
          max-width: 400px;
        }

        .widget-container {
          display: flex;
          flex-direction: column;
          gap: 15px;
        }

        .track-info {
          text-align: center;
        }

        .track-name {
          font-size: 18px;
          font-weight: 600;
          margin-bottom: 5px;
        }

        .artist-name {
          font-size: 14px;
          opacity: 0.9;
        }

        .controls {
          display: flex;
          justify-content: center;
          align-items: center;
          gap: 15px;
        }

        button {
          background: rgba(255, 255, 255, 0.2);
          border: none;
          color: white;
          width: 40px;
          height: 40px;
          border-radius: 50%;
          cursor: pointer;
          transition: background 0.2s;
          font-size: 16px;
        }

        button:hover {
          background: rgba(255, 255, 255, 0.3);
        }

        button.play-pause {
          width: 50px;
          height: 50px;
          font-size: 20px;
        }

        .progress-bar {
          width: 100%;
          height: 4px;
          background: rgba(255, 255, 255, 0.2);
          border-radius: 2px;
          overflow: hidden;
          cursor: pointer;
        }

        .progress-fill {
          height: 100%;
          background: white;
          transition: width 0.1s linear;
        }

        .time-info {
          display: flex;
          justify-content: space-between;
          font-size: 12px;
          opacity: 0.8;
        }

        .volume-control {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        input[type="range"] {
          flex: 1;
          -webkit-appearance: none;
          appearance: none;
          height: 4px;
          background: rgba(255, 255, 255, 0.2);
          border-radius: 2px;
          outline: none;
        }

        input[type="range"]::-webkit-slider-thumb {
          -webkit-appearance: none;
          appearance: none;
          width: 12px;
          height: 12px;
          background: white;
          border-radius: 50%;
          cursor: pointer;
        }

        .error {
          text-align: center;
          color: #ff6b6b;
          padding: 10px;
          background: rgba(255, 255, 255, 0.1);
          border-radius: 6px;
        }

        .loading {
          text-align: center;
          padding: 20px;
        }
      </style>

      <div class="widget-container">
        ${this.renderContent()}
      </div>
    `;
  }

  private renderContent(): string {
    const { state, currentTrack, isPaused, position, duration, volume, error } = this.model;

    switch (state) {
      case 'loading':
        return '<div class="loading">Initializing Spotify Player...</div>';

      case 'error':
        return `<div class="error">Error: ${error}</div>`;

      case 'ready':
      case 'playing':
        return `
          ${currentTrack ? `
            <div class="track-info">
              <div class="track-name">${currentTrack.name}</div>
              <div class="artist-name">${currentTrack.artists.map(a => a.name).join(', ')}</div>
            </div>
          ` : '<div class="track-info">No track selected</div>'}

          <div class="controls">
            <button onclick="this.getRootNode().host.dispatch({type: 'PREVIOUS'})">⏮</button>
            <button class="play-pause" onclick="this.getRootNode().host.dispatch({type: '${isPaused ? 'PLAY' : 'PAUSE'}'})">
              ${isPaused ? '▶' : '⏸'}
            </button>
            <button onclick="this.getRootNode().host.dispatch({type: 'NEXT'})">⏭</button>
          </div>

          ${currentTrack ? `
            <div class="progress-container">
              <div class="progress-bar" onclick="this.getRootNode().host.handleSeek(event)">
                <div class="progress-fill" style="width: ${(position / duration) * 100}%"></div>
              </div>
              <div class="time-info">
                <span>${this.formatTime(position)}</span>
                <span>${this.formatTime(duration)}</span>
              </div>
            </div>
          ` : ''}

          <div class="volume-control">
            <span>🔊</span>
            <input type="range" min="0" max="100" value="${volume}"
                   oninput="this.getRootNode().host.dispatch({type: 'VOLUME', level: parseInt(this.value)})">
          </div>
        `;

      default:
        return '<div>Widget not initialized</div>';
    }
  }

  // Effects
  private async initPlayer(): Promise<void> {
    if (!window.Spotify) {
      await this.loadSpotifySDK();
    }

    const token = await this.getAccessToken();
    if (!token) {
      this.dispatch({ type: 'ERROR', message: 'No access token available' });
      return;
    }

    const player = new Spotify.Player({
      name: 'Droo.foo Spotify Widget',
      getOAuthToken: (cb: (token: string) => void) => cb(token),
      volume: 0.5
    });

    player.addListener('ready', ({ device_id }) => {
      this.dispatch({ type: 'PLAYER_READY', deviceId: device_id });
    });

    player.addListener('player_state_changed', (state) => {
      if (state) this.dispatch({ type: 'STATE_CHANGED', state });
    });

    player.addListener('initialization_error', ({ message }) => {
      this.dispatch({ type: 'ERROR', message });
    });

    await player.connect();
    this.model.player = player;
  }

  private loadSpotifySDK(): Promise<void> {
    return new Promise((resolve) => {
      const script = document.createElement('script');
      script.src = 'https://sdk.scdn.co/spotify-player.js';
      script.async = true;

      window.onSpotifyWebPlaybackSDKReady = () => resolve();
      document.body.appendChild(script);
    });
  }

  private async getAccessToken(): Promise<string | null> {
    // Get token from Phoenix channel or backend
    const response = await fetch('/api/spotify/token');
    const data = await response.json();
    return data.token;
  }

  private handleSeek(event: MouseEvent): void {
    const target = event.currentTarget as HTMLElement;
    const rect = target.getBoundingClientRect();
    const percent = (event.clientX - rect.left) / rect.width;
    const position = Math.round(percent * this.model.duration);
    this.dispatch({ type: 'SEEK', position });
  }

  private formatTime(ms: number): string {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  }

  // Attributes
  static get observedAttributes() {
    return ['playlist-id', 'theme', 'auto-play'];
  }

  attributeChangedCallback(name: string, oldValue: string, newValue: string) {
    switch (name) {
      case 'playlist-id':
        if (newValue) this.dispatch({ type: 'LOAD_PLAYLIST', id: newValue });
        break;
    }
  }
}

// Register the component
customElements.define('spotify-widget', SpotifyWidget);

// TypeScript declarations for Spotify Web Playback SDK
declare global {
  interface Window {
    onSpotifyWebPlaybackSDKReady: () => void;
    Spotify: typeof Spotify;
  }

  namespace Spotify {
    interface Player {
      connect(): Promise<boolean>;
      disconnect(): void;
      addListener(event: string, callback: Function): void;
      removeListener(event: string, callback?: Function): void;
      getCurrentState(): Promise<PlaybackState | null>;
      setName(name: string): Promise<void>;
      getVolume(): Promise<number>;
      setVolume(volume: number): Promise<void>;
      pause(): Promise<void>;
      resume(): Promise<void>;
      togglePlay(): Promise<void>;
      seek(position: number): Promise<void>;
      previousTrack(): Promise<void>;
      nextTrack(): Promise<void>;
    }

    interface PlaybackState {
      context: {
        uri: string;
        metadata: any;
      };
      disallows: {
        [key: string]: boolean;
      };
      paused: boolean;
      position: number;
      duration: number;
      repeat_mode: number;
      shuffle: boolean;
      track_window: {
        current_track: Track;
        previous_tracks: Track[];
        next_tracks: Track[];
      };
    }

    interface Track {
      uri: string;
      id: string;
      type: string;
      media_type: string;
      name: string;
      is_playable: boolean;
      album: {
        uri: string;
        name: string;
        images: Array<{ url: string }>;
      };
      artists: Array<{ uri: string; name: string }>;
    }
  }
}