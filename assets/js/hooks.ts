/**
 * Phoenix LiveView hooks for portfolio functionality
 * Terminal hooks archived to .archived_terminal/
 * PWA hooks archived to .archived_pwa/
 */
import { STLViewerHook } from './hooks/stl_viewer';
import { AstroSTLViewerHook } from './hooks/astro_stl_viewer.js';
import { AstroSpotifyWidgetHook } from './hooks/astro_spotify_widget.js';
import { Web3WalletHook } from './hooks/web3_wallet.js';
import { PortalWebRTCHook } from './hooks/portal_webrtc.js';

export default {
  STLViewerHook,
  AstroSTLViewerHook,
  AstroSpotifyWidgetHook,
  Web3WalletHook,
  PortalWebRTCHook
};
