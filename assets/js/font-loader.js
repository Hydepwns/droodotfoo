/**
 * Progressive Font Loading Strategy
 * Loads fonts efficiently with minimal impact on performance
 */

class FontLoader {
  constructor() {
    this.fonts = [
      {
        family: "Monaspace Argon",
        url: "/fonts/monaspace-argon-subset.woff2",
        weight: "400",
        style: "normal",
        priority: "critical", // Load immediately
      },
      {
        family: "Monaspace Argon",
        url: "/fonts/monaspace-argon.woff2",
        weight: "400",
        style: "normal",
        priority: "high", // Load after critical
      },
      {
        family: "Monaspace Argon Variable",
        url: "/fonts/monaspace-argon-var.woff2",
        weight: "300 700",
        style: "normal",
        priority: "low", // Load when idle
      },
    ];

    this.loadedFonts = new Set();
  }

  /**
   * Initialize font loading based on priority
   */
  async init() {
    // Check if fonts are already in cache
    if (this.checkCache()) {
      this.applyLoadedClass();
      return;
    }

    // Load critical fonts immediately
    await this.loadCriticalFonts();

    // Load high priority fonts after initial render
    requestIdleCallback(() => this.loadHighPriorityFonts());

    // Load low priority fonts when idle
    if ("requestIdleCallback" in window) {
      requestIdleCallback(() => this.loadLowPriorityFonts(), { timeout: 3000 });
    }
  }

  /**
   * Check if fonts are cached
   */
  checkCache() {
    if (!("fonts" in document)) return false;

    try {
      return document.fonts.check("14px Monaspace Argon");
    } catch (e) {
      return false;
    }
  }

  /**
   * Load critical fonts for immediate display
   */
  async loadCriticalFonts() {
    const criticalFonts = this.fonts.filter((f) => f.priority === "critical");

    try {
      await Promise.all(criticalFonts.map((font) => this.loadFont(font)));
      this.applyLoadedClass();
    } catch (e) {
      console.warn("Critical fonts failed to load, using fallback", e);
    }
  }

  /**
   * Load high priority fonts
   */
  async loadHighPriorityFonts() {
    const highPriorityFonts = this.fonts.filter((f) => f.priority === "high");

    for (const font of highPriorityFonts) {
      try {
        await this.loadFont(font);
      } catch (e) {
        console.warn(`Font ${font.family} failed to load`, e);
      }
    }
  }

  /**
   * Load low priority fonts when browser is idle
   */
  async loadLowPriorityFonts() {
    const lowPriorityFonts = this.fonts.filter((f) => f.priority === "low");

    for (const font of lowPriorityFonts) {
      // Check if user has preference for reduced data
      if (this.shouldReduceData()) {
        break;
      }

      try {
        await this.loadFont(font);
      } catch (e) {
        // Silently fail for low priority fonts
      }
    }
  }

  /**
   * Load individual font with FontFace API
   */
  async loadFont(fontConfig) {
    const { family, url, weight, style } = fontConfig;

    // Skip if already loaded
    const fontId = `${family}-${weight}-${style}`;
    if (this.loadedFonts.has(fontId)) {
      return;
    }

    // Use FontFace API if available
    if ("FontFace" in window) {
      const font = new FontFace(family, `url(${url})`, {
        weight,
        style,
        display: "swap",
      });

      await font.load();
      document.fonts.add(font);
      this.loadedFonts.add(fontId);
    } else {
      // Fallback: inject @font-face rule
      this.injectFontFace(fontConfig);
    }
  }

  /**
   * Inject @font-face rule for older browsers
   */
  injectFontFace(fontConfig) {
    const { family, url, weight, style } = fontConfig;
    const style = document.createElement("style");
    style.textContent = `
      @font-face {
        font-family: '${family}';
        src: url('${url}') format('woff2');
        font-weight: ${weight};
        font-style: ${style};
        font-display: swap;
      }
    `;
    document.head.appendChild(style);
  }

  /**
   * Apply loaded class when fonts are ready
   */
  applyLoadedClass() {
    document.documentElement.classList.remove("font-loading");
    document.documentElement.classList.add("font-loaded");

    // Store in session storage for faster subsequent loads
    try {
      sessionStorage.setItem("fonts-loaded", "true");
    } catch (e) {
      // Ignore storage errors
    }
  }

  /**
   * Check if user prefers reduced data
   */
  shouldReduceData() {
    // Check for Save-Data header hint
    if ("connection" in navigator && navigator.connection.saveData) {
      return true;
    }

    // Check for slow connection
    if ("connection" in navigator && navigator.connection.effectiveType) {
      return ["slow-2g", "2g"].includes(navigator.connection.effectiveType);
    }

    // Check media query
    const mediaQuery = window.matchMedia("(prefers-reduced-data: reduce)");
    return mediaQuery.matches;
  }

  /**
   * Preload font files for faster loading
   */
  static preloadFonts() {
    const preloadLinks = [
      {
        href: "/fonts/monaspace-argon-subset.woff2",
        type: "font/woff2",
        crossorigin: "anonymous",
      },
    ];

    preloadLinks.forEach(({ href, type, crossorigin }) => {
      const link = document.createElement("link");
      link.rel = "preload";
      link.as = "font";
      link.href = href;
      link.type = type;
      link.crossOrigin = crossorigin;
      document.head.appendChild(link);
    });
  }
}

// Check if fonts were loaded in previous session
if (sessionStorage.getItem("fonts-loaded") === "true") {
  document.documentElement.classList.add("font-loaded");
} else {
  document.documentElement.classList.add("font-loading");
}

// Initialize font loader
const fontLoader = new FontLoader();

// Start loading fonts
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () => fontLoader.init());
} else {
  fontLoader.init();
}

// Export for use in other modules
export default fontLoader;