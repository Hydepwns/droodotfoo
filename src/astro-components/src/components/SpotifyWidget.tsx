/**
 * Spotify Widget React Component for Astro
 * Converts the Web Component to React with hooks and modern patterns
 */

import React, { useState, useEffect, useCallback, useRef } from 'react';

// Types
interface SpotifyTrack {
  uri: string;
  id: string;
  name: string;
  artists: Array<{ name: string; uri: string }>;
  album: {
    name: string;
    images: Array<{ url: string }>;
  };
}

interface SpotifyPlaybackState {
  paused: boolean;
  position: number;
  duration: number;
  track_window: {
    current_track: SpotifyTrack;
  };
}

interface SpotifyWidgetProps {
  playlistId?: string;
  theme?: 'dark' | 'light' | 'gradient';
  autoPlay?: boolean;
  showVolume?: boolean;
  showProgress?: boolean;
  onTrackChange?: (track: SpotifyTrack | null) => void;
  onStateChange?: (state: SpotifyPlaybackState | null) => void;
}

interface SpotifyModel {
  state: 'idle' | 'loading' | 'ready' | 'playing' | 'error';
  player: any | null;
  deviceId: string | null;
  currentTrack: SpotifyTrack | null;
  isPaused: boolean;
  position: number;
  duration: number;
  volume: number;
  error: string | null;
}

// Spotify Web Playback SDK types
declare global {
  interface Window {
    onSpotifyWebPlaybackSDKReady: () => void;
    Spotify: {
      Player: new (config: any) => any;
    };
  }
}

export default function SpotifyWidget({
  playlistId = '',
  theme = 'gradient',
  autoPlay = false,
  showVolume = true,
  showProgress = true,
  onTrackChange,
  onStateChange
}: SpotifyWidgetProps) {
  const [model, setModel] = useState<SpotifyModel>({
    state: 'idle',
    player: null,
    deviceId: null,
    currentTrack: null,
    isPaused: true,
    position: 0,
    duration: 0,
    volume: 50,
    error: null
  });

  const playerRef = useRef<any>(null);

  // Initialize Spotify player
  const initPlayer = useCallback(async () => {
    if (!window.Spotify) {
      await loadSpotifySDK();
    }

    const token = await getAccessToken();
    if (!token) {
      setModel(prev => ({ ...prev, state: 'error', error: 'No access token available' }));
      return;
    }

    const player = new window.Spotify.Player({
      name: 'Droo.foo Spotify Widget',
      getOAuthToken: (cb: (token: string) => void) => cb(token),
      volume: 0.5
    });

    player.addListener('ready', ({ device_id }: { device_id: string }) => {
      setModel(prev => ({ ...prev, state: 'ready', deviceId: device_id }));
    });

    player.addListener('player_state_changed', (state: SpotifyPlaybackState) => {
      if (state) {
        setModel(prev => ({
          ...prev,
          state: 'playing',
          currentTrack: state.track_window.current_track,
          isPaused: state.paused,
          position: state.position,
          duration: state.duration
        }));
        
        onTrackChange?.(state.track_window.current_track);
        onStateChange?.(state);
      }
    });

    player.addListener('initialization_error', ({ message }: { message: string }) => {
      setModel(prev => ({ ...prev, state: 'error', error: message }));
    });

    await player.connect();
    playerRef.current = player;
    setModel(prev => ({ ...prev, player }));
  }, [onTrackChange, onStateChange]);

  // Load Spotify SDK
  const loadSpotifySDK = (): Promise<void> => {
    return new Promise((resolve) => {
      if (window.Spotify) {
        resolve();
        return;
      }

      const script = document.createElement('script');
      script.src = 'https://sdk.scdn.co/spotify-player.js';
      script.async = true;

      window.onSpotifyWebPlaybackSDKReady = () => resolve();
      document.body.appendChild(script);
    });
  };

  // Get access token from backend
  const getAccessToken = async (): Promise<string | null> => {
    try {
      const response = await fetch('/api/spotify/token');
      const data = await response.json();
      return data.token;
    } catch (error) {
      console.error('Failed to get access token:', error);
      return null;
    }
  };

  // Player controls
  const play = useCallback(() => {
    if (playerRef.current) {
      playerRef.current.resume();
    }
  }, []);

  const pause = useCallback(() => {
    if (playerRef.current) {
      playerRef.current.pause();
    }
  }, []);

  const nextTrack = useCallback(() => {
    if (playerRef.current) {
      playerRef.current.nextTrack();
    }
  }, []);

  const previousTrack = useCallback(() => {
    if (playerRef.current) {
      playerRef.current.previousTrack();
    }
  }, []);

  const seek = useCallback((position: number) => {
    if (playerRef.current) {
      playerRef.current.seek(position);
    }
  }, []);

  const setVolume = useCallback((volume: number) => {
    if (playerRef.current) {
      playerRef.current.setVolume(volume / 100);
      setModel(prev => ({ ...prev, volume }));
    }
  }, []);

  // Handle seek on progress bar click
  const handleSeek = useCallback((event: React.MouseEvent<HTMLDivElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();
    const percent = (event.clientX - rect.left) / rect.width;
    const position = Math.round(percent * model.duration);
    seek(position);
  }, [model.duration, seek]);

  // Format time helper
  const formatTime = (ms: number): string => {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  // Initialize on mount
  useEffect(() => {
    setModel(prev => ({ ...prev, state: 'loading' }));
    initPlayer();
  }, [initPlayer]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (playerRef.current) {
        playerRef.current.disconnect();
      }
    };
  }, []);

  // Render content based on state
  const renderContent = () => {
    switch (model.state) {
      case 'loading':
        return (
          <div className="spotify-widget__loading">
            Initializing Spotify Player...
          </div>
        );

      case 'error':
        return (
          <div className="spotify-widget__error">
            Error: {model.error}
          </div>
        );

      case 'ready':
      case 'playing':
        return (
          <>
            {model.currentTrack ? (
              <div className="spotify-widget__track-info">
                <div className="spotify-widget__track-name">
                  {model.currentTrack.name}
                </div>
                <div className="spotify-widget__artist-name">
                  {model.currentTrack.artists.map(a => a.name).join(', ')}
                </div>
              </div>
            ) : (
              <div className="spotify-widget__track-info">
                No track selected
              </div>
            )}

            <div className="spotify-widget__controls">
              <button 
                className="spotify-widget__button"
                onClick={previousTrack}
                aria-label="Previous track"
              >
                ⏮
              </button>
              <button 
                className="spotify-widget__button spotify-widget__button--play-pause"
                onClick={model.isPaused ? play : pause}
                aria-label={model.isPaused ? 'Play' : 'Pause'}
              >
                {model.isPaused ? '▶' : '⏸'}
              </button>
              <button 
                className="spotify-widget__button"
                onClick={nextTrack}
                aria-label="Next track"
              >
                ⏭
              </button>
            </div>

            {showProgress && model.currentTrack && (
              <div className="spotify-widget__progress-container">
                <div 
                  className="spotify-widget__progress-bar" 
                  onClick={handleSeek}
                >
                  <div 
                    className="spotify-widget__progress-fill" 
                    style={{ width: `${(model.position / model.duration) * 100}%` }}
                  />
                </div>
                <div className="spotify-widget__time-info">
                  <span>{formatTime(model.position)}</span>
                  <span>{formatTime(model.duration)}</span>
                </div>
              </div>
            )}

            {showVolume && (
              <div className="spotify-widget__volume-control">
                <span>🔊</span>
                <input
                  type="range"
                  min="0"
                  max="100"
                  value={model.volume}
                  onChange={(e) => setVolume(parseInt(e.target.value))}
                  className="spotify-widget__volume-slider"
                />
              </div>
            )}
          </>
        );

      default:
        return <div>Widget not initialized</div>;
    }
  };

  return (
    <div className="spotify-widget__container">
      {renderContent()}
    </div>
  );
}
