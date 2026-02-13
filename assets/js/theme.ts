/**
 * Theme cycling, debug mode, hamburger menu, and music player functionality
 * Extracted from root.html.heex for better caching
 */

const themes = [
  "theme-synthwave84",
  "theme-hotline",
  "theme-matrix",
  "theme-cyberpunk",
  "theme-phosphor",
  "theme-amber",
  "theme-high-contrast",
];

const themeNames = [
  "Synthwave84",
  "Hotline",
  "Matrix",
  "Cyberpunk",
  "Phosphor",
  "Amber",
  "High Contrast",
];

let currentThemeIndex = 0;
let themeIndicatorTimeout: ReturnType<typeof setTimeout> | null = null;

/**
 * Show theme name indicator briefly
 */
function showThemeIndicator(themeName: string): void {
  const indicator = document.getElementById("theme-indicator");
  if (!indicator) return;

  indicator.textContent = `THEME: ${themeName}`;
  indicator.classList.add("show");

  if (themeIndicatorTimeout) {
    clearTimeout(themeIndicatorTimeout);
  }

  themeIndicatorTimeout = setTimeout(() => {
    indicator.classList.remove("show");
  }, 2000);
}

/**
 * Get current theme index from CSS classes on html element
 */
function getCurrentThemeIndex(): number {
  const classList = document.documentElement.classList;
  for (let i = 0; i < themes.length; i++) {
    if (classList.contains(themes[i])) {
      return i;
    }
  }
  return 0;
}

/**
 * Cycle to next theme
 */
function cycleTheme(): void {
  currentThemeIndex = (currentThemeIndex + 1) % themes.length;
  const newTheme = themes[currentThemeIndex];

  themes.forEach((t) => document.documentElement.classList.remove(t));
  document.documentElement.classList.add(newTheme);
  localStorage.setItem("phx:theme", newTheme);
  showThemeIndicator(themeNames[currentThemeIndex]);
}

/**
 * Load saved theme on page load
 */
function initializeTheme(): void {
  const savedTheme = localStorage.getItem("phx:theme");
  if (savedTheme && themes.includes(savedTheme)) {
    themes.forEach((t) => document.documentElement.classList.remove(t));
    document.documentElement.classList.add(savedTheme);
    currentThemeIndex = themes.indexOf(savedTheme);
  } else {
    // Set default theme if none saved (High Contrast - black and white)
    document.documentElement.classList.add(themes[6]);
    localStorage.setItem("phx:theme", themes[6]);
    currentThemeIndex = 6;
  }
}

// Debug mode functionality
function getDebugMode(): boolean {
  return localStorage.getItem("phx:debug") === "true";
}

function setDebugMode(value: boolean): void {
  localStorage.setItem("phx:debug", String(value));
}

function applyDebugMode(): void {
  if (getDebugMode()) {
    document.documentElement.classList.add("debug-mode");
  } else {
    document.documentElement.classList.remove("debug-mode");
  }
}

function toggleDebugMode(): void {
  setDebugMode(!getDebugMode());
  applyDebugMode();
}

/**
 * Toggle music player expanded/minimized state
 */
function toggleMusicPlayer(): void {
  const musicPlayer = document.getElementById("music-player-widget");
  if (musicPlayer) {
    musicPlayer.classList.toggle("music-player-minimized");
    musicPlayer.classList.toggle("music-player-expanded");
  }
}

/**
 * Initialize all UI controls on DOMContentLoaded
 */
function initializeControls(): void {
  const hamburgerToggle = document.getElementById("hamburger-toggle");
  const hamburgerMenu = document.getElementById("hamburger-menu");
  const menuClose = document.getElementById("menu-close");
  const menuThemeToggle = document.getElementById("menu-theme-toggle");
  const menuDebugToggle = document.getElementById("menu-debug-toggle");
  const menuMusicToggle = document.getElementById("menu-music-toggle");
  const musicPlayer = document.getElementById("music-player-widget");
  const debugToggle = document.getElementById("debug-toggle");
  const themeToggle = document.getElementById("theme-toggle");
  const musicToggleDesktop = document.getElementById("music-toggle-desktop");

  // Theme toggle button click handler
  if (themeToggle) {
    themeToggle.addEventListener("click", cycleTheme);
  }

  // Open hamburger menu
  if (hamburgerToggle && hamburgerMenu) {
    hamburgerToggle.addEventListener("click", () => {
      hamburgerMenu.classList.add("menu-open");
    });
  }

  // Close hamburger menu
  if (menuClose && hamburgerMenu) {
    menuClose.addEventListener("click", () => {
      hamburgerMenu.classList.remove("menu-open");
    });
  }

  // Close menu when clicking outside
  if (hamburgerMenu) {
    hamburgerMenu.addEventListener("click", (e: Event) => {
      if (e.target === hamburgerMenu) {
        hamburgerMenu.classList.remove("menu-open");
      }
    });
  }

  // Theme toggle from menu
  if (menuThemeToggle && hamburgerMenu) {
    menuThemeToggle.addEventListener("click", () => {
      cycleTheme();
      hamburgerMenu.classList.remove("menu-open");
    });
  }

  // Debug toggle from desktop button
  if (debugToggle) {
    debugToggle.addEventListener("click", toggleDebugMode);
  }

  // Debug toggle from menu
  if (menuDebugToggle && hamburgerMenu) {
    menuDebugToggle.addEventListener("click", () => {
      toggleDebugMode();
      hamburgerMenu.classList.remove("menu-open");
    });
  }

  // Music player minimize/maximize toggle (desktop button)
  if (musicToggleDesktop && musicPlayer) {
    musicToggleDesktop.addEventListener("click", toggleMusicPlayer);
  }

  // Music player minimize/maximize toggle (mobile hamburger menu)
  if (menuMusicToggle && musicPlayer && hamburgerMenu) {
    menuMusicToggle.addEventListener("click", () => {
      toggleMusicPlayer();
      hamburgerMenu.classList.remove("menu-open");
    });
  }

  // Click minimized player pill to expand
  if (musicPlayer) {
    musicPlayer.addEventListener("click", (e: Event) => {
      if (
        musicPlayer.classList.contains("music-player-minimized") &&
        e.target === musicPlayer
      ) {
        toggleMusicPlayer();
      }
    });
  }
}

/**
 * Set up keyboard shortcuts
 */
function initializeKeyboardShortcuts(): void {
  let lastThemeChange = 0;
  const themeChangeDelay = 100;

  document.addEventListener(
    "keydown",
    (e: KeyboardEvent) => {
      const isRegularInput =
        (e.target as HTMLElement).matches("input, textarea, select") &&
        (e.target as HTMLElement).id !== "terminal-input";

      // Uppercase 'T' for theme toggle
      if (e.key === "T" && !isRegularInput && !e.repeat) {
        const now = Date.now();
        if (now - lastThemeChange >= themeChangeDelay) {
          lastThemeChange = now;
          e.preventDefault();
          e.stopPropagation();
          cycleTheme();
        }
      }

      // Uppercase 'D' for debug toggle
      if (e.key === "D" && !isRegularInput && !e.repeat) {
        e.preventDefault();
        e.stopPropagation();
        toggleDebugMode();
      }
    },
    true
  );
}

// Initialize theme immediately (before DOMContentLoaded)
initializeTheme();
applyDebugMode();

// Initialize controls after DOM is ready
document.addEventListener("DOMContentLoaded", initializeControls);

// Reapply debug mode after LiveView navigation
window.addEventListener("phx:page-loading-stop", applyDebugMode);

// Set up keyboard shortcuts
initializeKeyboardShortcuts();
