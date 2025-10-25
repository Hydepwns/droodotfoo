# Archived PWA Functionality

This directory contains PWA (Progressive Web App) installation and management features that were archived on 2025-10-21.

## What Was Archived

- **Backend**: `lib/droodotfoo_web/live/pwa_live.ex` - PWA management LiveView
- **Frontend**:
  - `assets/css/pwa.css` - PWA styling
  - `assets/js/hooks/astro_pwa_hook.js` - PWA hook integration
- **Astro Components**: PWA-related Astro components remain in `src/astro-components/` but are no longer integrated

## Why Archived

PWA functionality was not essential for the core portfolio website and added complexity without providing significant value for this use case.

## Restoration Instructions

To restore PWA functionality:

1. **Move Files Back**:
   ```bash
   mv .archived_pwa/lib/droodotfoo_web/live/pwa_live.ex lib/droodotfoo_web/live/
   mv .archived_pwa/assets/css/pwa.css assets/css/
   mv .archived_pwa/assets/js/hooks/astro_pwa_hook.js assets/js/hooks/
   ```

2. **Update Router** (`lib/droodotfoo_web/router.ex`):
   ```elixir
   # Uncomment this line:
   live "/pwa", PWALive
   ```

3. **Update CSS** (`assets/css/app.css`):
   ```css
   @import "./pwa.css";  /* Uncomment this line */
   ```

4. **Update Hooks** (`assets/js/hooks.ts`):
   ```typescript
   import { AstroPWAHook } from './hooks/astro_pwa_hook.js';

   export default {
     // ... other hooks
     AstroPWAHook,  // Add this back
   };
   ```

5. **Recompile**:
   ```bash
   mix clean
   mix compile
   mix assets.build
   ```

6. **Restart Server**:
   ```bash
   mix phx.server
   ```
