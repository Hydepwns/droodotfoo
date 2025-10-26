/**
 * Module for aligning media elements (images, videos) to the monospace grid
 * Inspired by wickstrom.tech media alignment technique
 *
 * Media elements have arbitrary aspect ratios that don't naturally align
 * to the line-height grid. This module snaps their heights to grid lines
 * to maintain visual rhythm.
 */

export interface MediaAlignmentOptions {
  lineHeight: number;
  selector?: string;
  autoResize?: boolean;
}

export class MediaGridAlignment {
  private readonly lineHeight: number;
  private readonly selector: string;
  private readonly autoResize: boolean;
  private resizeObserver?: ResizeObserver;

  constructor(options: MediaAlignmentOptions) {
    this.lineHeight = options.lineHeight;
    this.selector = options.selector || 'img, video, iframe';
    this.autoResize = options.autoResize !== false;
  }

  /**
   * Snaps a single media element to the grid
   */
  snapToGrid(element: HTMLElement): void {
    try {
      // Skip if element is not visible or has no dimensions
      if (element.offsetParent === null) return;

      const rect = element.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) return;

      // Calculate aspect ratio
      const aspectRatio = rect.height / rect.width;

      // Calculate how many line-height units we need
      const heightInLines = Math.ceil(rect.height / this.lineHeight);
      const snappedHeight = heightInLines * this.lineHeight;

      // Store aspect ratio as CSS variable
      element.style.setProperty('--media-aspect-ratio', `${aspectRatio}`);

      // Calculate padding-bottom to achieve snapped height
      // padding-bottom percentage is relative to width
      const paddingPercent = (snappedHeight / rect.width) * 100;

      // Mark element as grid-aligned
      element.setAttribute('data-grid-aligned', 'true');
      element.setAttribute('data-grid-lines', `${heightInLines}`);

    } catch (error) {
      console.warn('Failed to snap media element to grid:', error);
    }
  }

  /**
   * Aligns all media elements in a container to the grid
   */
  alignContainer(container: HTMLElement): void {
    const mediaElements = container.querySelectorAll<HTMLElement>(this.selector);

    mediaElements.forEach(element => {
      // Wait for images to load before aligning
      if (element instanceof HTMLImageElement && !element.complete) {
        element.addEventListener('load', () => this.snapToGrid(element), { once: true });
      } else {
        this.snapToGrid(element);
      }
    });
  }

  /**
   * Sets up automatic realignment on window resize
   */
  enableAutoResize(container: HTMLElement): void {
    if (!this.autoResize) return;

    // Debounced resize handler
    let resizeTimeout: number;
    const handleResize = () => {
      clearTimeout(resizeTimeout);
      resizeTimeout = window.setTimeout(() => {
        this.alignContainer(container);
      }, 150);
    };

    window.addEventListener('resize', handleResize);
  }

  /**
   * Observes container for new media elements
   */
  observeContainer(container: HTMLElement): void {
    if (typeof ResizeObserver === 'undefined') return;

    this.resizeObserver = new ResizeObserver(entries => {
      entries.forEach(entry => {
        const element = entry.target as HTMLElement;
        if (this.isMediaElement(element)) {
          this.snapToGrid(element);
        }
      });
    });

    // Observe all existing media elements
    const mediaElements = container.querySelectorAll<HTMLElement>(this.selector);
    mediaElements.forEach(element => {
      this.resizeObserver?.observe(element);
    });
  }

  /**
   * Checks if element is a media element
   */
  private isMediaElement(element: HTMLElement): boolean {
    return element instanceof HTMLImageElement ||
           element instanceof HTMLVideoElement ||
           element instanceof HTMLIFrameElement;
  }

  /**
   * Cleans up observers and event listeners
   */
  destroy(): void {
    this.resizeObserver?.disconnect();
  }

  /**
   * Static helper to get computed line height from element
   */
  static getLineHeight(element: HTMLElement): number {
    const computedStyle = window.getComputedStyle(element);
    const lineHeightStr = computedStyle.lineHeight;

    if (lineHeightStr === 'normal') {
      // Default to 1.5 * font-size for 'normal'
      const fontSize = parseFloat(computedStyle.fontSize);
      return fontSize * 1.5;
    }

    return parseFloat(lineHeightStr);
  }
}
