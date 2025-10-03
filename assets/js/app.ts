/**
 * Main application entry point for Phoenix LiveView
 */

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";

// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import Hooks from "./hooks";
import PWAManager from "./modules/PWAManager";

// Type definitions

interface PhoenixLiveReloader {
  enableServerLogs: () => void;
  disableServerLogs: () => void;
  openEditorAtCaller: (element: EventTarget) => void;
  openEditorAtDef: (element: EventTarget) => void;
}

interface WindowWithLiveSocket extends Window {
  liveSocket?: typeof liveSocket;
  liveReloader?: PhoenixLiveReloader;
}

declare const window: WindowWithLiveSocket;

// Get CSRF token from meta tag
const getCsrfToken = (): string => {
  const metaTag = document.querySelector("meta[name='csrf-token']");
  if (!metaTag) {
    console.error("CSRF token meta tag not found");
    return "";
  }
  return metaTag.getAttribute("content") || "";
};

// Initialize LiveSocket
const csrfToken = getCsrfToken();
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Configure progress bar
topbar.config({
  barColors: { 0: "#29d" },
  shadowColor: "rgba(0, 0, 0, .3)"
});

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", (_info: Event) => {
  topbar.show(300);
});

window.addEventListener("phx:page-loading-stop", (_info: Event) => {
  topbar.hide();
});

// Connect if there are any LiveViews on the page
liveSocket.connect();

// Expose liveSocket on window for web console debug logs and latency simulation
window.liveSocket = liveSocket;

// Development-only features
if (process.env.NODE_ENV === "development") {
  // Enable debug mode
  // liveSocket.enableDebug();

  // Phoenix Live Reload integration
  window.addEventListener("phx:live_reload:attached", (event: Event) => {
    const customEvent = event as CustomEvent<PhoenixLiveReloader>;
    const reloader = customEvent.detail;

    if (!reloader) {
      console.warn("Live reloader not available");
      return;
    }

    // Store reloader reference
    window.liveReloader = reloader;

    // Enable server log streaming to client
    try {
      reloader.enableServerLogs();
      console.log("Server log streaming enabled");
    } catch (error) {
      console.error("Failed to enable server logs:", error);
    }

    // Set up editor integration
    setupEditorIntegration(reloader);
  });
}

/**
 * Sets up click-to-open editor integration for development
 * @param reloader - Phoenix live reloader instance
 */
function setupEditorIntegration(reloader: PhoenixLiveReloader): void {
  let keyDown: string | null = null;

  // Track key presses
  window.addEventListener("keydown", (e: KeyboardEvent) => {
    keyDown = e.key;
  });

  window.addEventListener("keyup", () => {
    keyDown = null;
  });

  // Handle clicks with modifier keys
  window.addEventListener(
    "click",
    (e: MouseEvent) => {
      if (!e.target || !(e.target instanceof Element)) {
        return;
      }

      try {
        if (keyDown === "c") {
          // Open at caller location
          e.preventDefault();
          e.stopImmediatePropagation();
          reloader.openEditorAtCaller(e.target);
        } else if (keyDown === "d") {
          // Open at function component definition location
          e.preventDefault();
          e.stopImmediatePropagation();
          reloader.openEditorAtDef(e.target);
        }
      } catch (error) {
        console.error("Failed to open editor:", error);
      }
    },
    true // Use capture phase
  );

  console.log("Editor integration enabled (use 'c' or 'd' + click)");
}

// Initialize PWA functionality
const pwaManager = new PWAManager();
pwaManager.init().catch((error) => {
  console.error("Failed to initialize PWA:", error);
});

// Log successful initialization
console.log("Phoenix LiveView application initialized");

// Export for debugging purposes
export { liveSocket, pwaManager };