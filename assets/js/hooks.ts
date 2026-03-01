/**
 * Phoenix LiveView hooks for portfolio functionality
 * Terminal hooks archived to .archived_terminal/
 *
 * PERFORMANCE: Heavy hooks are lazy-loaded to reduce initial bundle size
 */

// Always-loaded hooks (used on most pages)
import { ReadingProgressHook } from './hooks/reading_progress.js';
import { CodeCopyHook } from './hooks/code_copy.js';
import { MediaGridAlignHook } from './hooks/media_grid_align';
import { ContributionGraphHook } from './hooks/contribution_graph';
import { FocusHook } from './hooks/focus';

// Modal scroll lock - prevents body scroll when modal is open
const ModalScrollLock = {
  mounted() {
    document.body.style.overflow = 'hidden';
  },
  destroyed() {
    document.body.style.overflow = '';
  }
};

// Lazy-loaded hooks (loaded on-demand when phx-hook detected)
// These are ~35KB total and only used on specific pages:
// - STLViewerHook: ~10KB (only STL viewer page)
// - PortalWebRTCHook: ~13KB (only Portal page)
// - Web3WalletHook: ~6KB (only Web3 page)
// - AstroSpotifyWidgetHook: ~3KB (only Spotify page)
// - AstroSTLViewerHook: ~2KB (only STL viewer page)

const LazyHooks: Record<string, () => Promise<any>> = {
  STLViewerHook: () => import('./hooks/stl_viewer').then(m => m.STLViewerHook),
  AstroSTLViewerHook: () => import('./hooks/astro_stl_viewer.js').then(m => m.AstroSTLViewerHook),
  AstroSpotifyWidgetHook: () => import('./hooks/astro_spotify_widget.js').then(m => m.AstroSpotifyWidgetHook),
  Web3WalletHook: () => import('./hooks/web3_wallet.js').then(m => m.Web3WalletHook),
  PortalWebRTCHook: () => import('./hooks/portal_webrtc.js').then(m => m.PortalWebRTCHook),
  FlowFieldHook: () => import('./hooks/flow_field').then(m => m.FlowFieldHook),
};

// Create proxy hooks that load real implementation on mount
const createLazyHook = (hookName: string) => ({
  mounted(this: any) {
    const loader = LazyHooks[hookName];
    if (!loader) {
      console.error(`Unknown lazy hook: ${hookName}`);
      return;
    }

    loader()
      .then(HookClass => {
        const instance = new HookClass();
        // Replace this proxy with real hook
        Object.assign(this, instance);
        // Call real mounted if it exists
        if (instance.mounted) {
          instance.mounted.call(this);
        }
      })
      .catch(err => console.error(`Failed to load ${hookName}:`, err));
  }
});

export default {
  // Always loaded (lightweight, frequently used)
  ReadingProgressHook,
  CodeCopyHook,
  MediaGridAlignHook,
  ContributionGraphHook,
  FocusHook,
  ModalScrollLock,

  // Lazy loaded (heavy, rarely used)
  STLViewerHook: createLazyHook('STLViewerHook'),
  AstroSTLViewerHook: createLazyHook('AstroSTLViewerHook'),
  AstroSpotifyWidgetHook: createLazyHook('AstroSpotifyWidgetHook'),
  Web3WalletHook: createLazyHook('Web3WalletHook'),
  PortalWebRTCHook: createLazyHook('PortalWebRTCHook'),
  FlowFieldHook: createLazyHook('FlowFieldHook'),
};
