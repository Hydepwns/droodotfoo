/**
 * LiveView hook for media grid alignment
 * Aligns images and videos to the monospace grid for visual consistency
 */
import { MediaGridAlignment } from '../modules/MediaGridAlignment';

export const MediaGridAlignHook = {
  mounted(this: any) {
    try {
      // Get line height from CSS variable or compute it
      const lineHeight = MediaGridAlignment.getLineHeight(this.el);

      // Initialize grid alignment
      this.gridAlignment = new MediaGridAlignment({
        lineHeight,
        selector: 'img, video, iframe',
        autoResize: true,
      });

      // Align all media in container
      this.gridAlignment.alignContainer(this.el);

      // Enable auto-resize on window changes
      this.gridAlignment.enableAutoResize(this.el);

      // Observe for new media elements (e.g., lazy-loaded images)
      this.gridAlignment.observeContainer(this.el);

    } catch (error) {
      console.warn('MediaGridAlign hook failed to initialize:', error);
    }
  },

  updated(this: any) {
    try {
      // Realign media after LiveView updates
      if (this.gridAlignment) {
        this.gridAlignment.alignContainer(this.el);
      }
    } catch (error) {
      console.warn('MediaGridAlign hook failed to update:', error);
    }
  },

  destroyed(this: any) {
    try {
      // Clean up observers and event listeners
      if (this.gridAlignment) {
        this.gridAlignment.destroy();
      }
    } catch (error) {
      console.warn('MediaGridAlign hook failed to destroy:', error);
    }
  }
};
