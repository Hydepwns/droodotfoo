// Development tools - only loaded in development mode
export function setupDevTools(window, liveSocket) {
  // Enable debug features
  window.liveSocket = liveSocket;

  // Phoenix Live Reload development features
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    // Enable server log streaming to client
    reloader.enableServerLogs();

    // Setup editor integration
    let keyDown;
    window.addEventListener("keydown", (e) => (keyDown = e.key));
    window.addEventListener("keyup", () => (keyDown = null));

    window.addEventListener(
      "click",
      (e) => {
        if (keyDown === "c") {
          e.preventDefault();
          e.stopImmediatePropagation();
          reloader.openEditorAtCaller(e.target);
        } else if (keyDown === "d") {
          e.preventDefault();
          e.stopImmediatePropagation();
          reloader.openEditorAtDef(e.target);
        }
      },
      true
    );

    window.liveReloader = reloader;
  });

  // Add performance monitoring in development
  if (window.performance && window.performance.mark) {
    window.addEventListener("phx:page-loading-start", () => {
      window.performance.mark("phx-page-start");
    });

    window.addEventListener("phx:page-loading-stop", () => {
      window.performance.mark("phx-page-end");
      window.performance.measure("phx-page-load", "phx-page-start", "phx-page-end");

      const measure = window.performance.getEntriesByName("phx-page-load")[0];
      if (measure) {
        console.log(`Page load time: ${measure.duration.toFixed(2)}ms`);
      }
    });
  }

  // Add bundle size warning in development
  if (window.performance && window.performance.getEntriesByType) {
    const resources = window.performance.getEntriesByType("resource");
    const jsResources = resources.filter((r) => r.name.includes(".js"));
    const totalSize = jsResources.reduce((acc, r) => acc + (r.transferSize || 0), 0);

    if (totalSize > 500000) {
      // 500KB warning threshold
      console.warn(
        `[WARNING] Bundle size warning: ${(totalSize / 1024).toFixed(2)}KB of JavaScript loaded`
      );
    }
  }

  console.log("[DEV] Development tools loaded");
}