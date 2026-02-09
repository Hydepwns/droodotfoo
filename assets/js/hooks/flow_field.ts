/**
 * Flow Field Hook - Interactive generative art using Gleam
 *
 * Renders an interactive flow field visualization on a canvas element.
 * Particles follow vector fields derived from Perlin noise, with mouse interaction.
 *
 * Usage in LiveView:
 *   <canvas id="flow-field" phx-hook="FlowFieldHook" data-seed="my-post-slug"></canvas>
 */

// Import compiled Gleam modules
import * as FlowFieldApp from "../../gleam/build/dev/javascript/flow_field/flow_field_app.mjs";

interface FlowFieldHookState {
  app: any;
  animationId: number | null;
  canvas: HTMLCanvasElement;
  resizeObserver: ResizeObserver | null;
}

export const FlowFieldHook = {
  state: null as FlowFieldHookState | null,

  mounted() {
    const canvas = this.el as HTMLCanvasElement;
    const seed = canvas.dataset.seed || "default";

    // Set canvas size to match container
    this.resizeCanvas(canvas);

    // Create flow field app from Gleam
    const seedHash = this.hashString(seed);
    const app = FlowFieldApp.create(canvas, seedHash);

    this.state = {
      app,
      animationId: null,
      canvas,
      resizeObserver: null,
    };

    // Set up resize observer
    this.state.resizeObserver = new ResizeObserver(() => {
      this.handleResize();
    });
    this.state.resizeObserver.observe(canvas.parentElement || canvas);

    // Set up mouse events
    canvas.addEventListener("mousemove", this.handleMouseMove.bind(this));
    canvas.addEventListener("mouseleave", this.handleMouseLeave.bind(this));
    canvas.addEventListener("touchmove", this.handleTouchMove.bind(this));
    canvas.addEventListener("touchend", this.handleMouseLeave.bind(this));

    // Start animation loop
    this.startAnimation();

    // Handle LiveView events for configuration changes
    this.handleEvent("flow_field:set_color", ({ color }: { color: string }) => {
      if (this.state) {
        this.state.app = FlowFieldApp.set_color(this.state.app, color);
      }
    });

    this.handleEvent(
      "flow_field:set_particle_count",
      ({ count }: { count: number }) => {
        if (this.state) {
          this.state.app = FlowFieldApp.set_particle_count(this.state.app, count);
        }
      }
    );

    this.handleEvent(
      "flow_field:set_fade_speed",
      ({ speed }: { speed: number }) => {
        if (this.state) {
          this.state.app = FlowFieldApp.set_fade_speed(this.state.app, speed);
        }
      }
    );
  },

  destroyed() {
    if (this.state) {
      // Stop animation
      if (this.state.animationId !== null) {
        cancelAnimationFrame(this.state.animationId);
      }

      // Stop Gleam app
      FlowFieldApp.stop(this.state.app);

      // Clean up resize observer
      if (this.state.resizeObserver) {
        this.state.resizeObserver.disconnect();
      }

      // Remove event listeners
      this.state.canvas.removeEventListener("mousemove", this.handleMouseMove);
      this.state.canvas.removeEventListener("mouseleave", this.handleMouseLeave);
      this.state.canvas.removeEventListener("touchmove", this.handleTouchMove);
      this.state.canvas.removeEventListener("touchend", this.handleMouseLeave);
    }
  },

  startAnimation() {
    const animate = () => {
      if (this.state) {
        this.state.app = FlowFieldApp.tick(this.state.app);
        this.state.animationId = requestAnimationFrame(animate);
      }
    };
    this.state!.animationId = requestAnimationFrame(animate);
  },

  handleMouseMove(event: MouseEvent) {
    if (this.state) {
      const rect = this.state.canvas.getBoundingClientRect();
      const x = event.clientX - rect.left;
      const y = event.clientY - rect.top;

      // Scale coordinates if canvas is scaled
      const scaleX = this.state.canvas.width / rect.width;
      const scaleY = this.state.canvas.height / rect.height;

      this.state.app = FlowFieldApp.on_mouse_move(
        this.state.app,
        x * scaleX,
        y * scaleY
      );
    }
  },

  handleTouchMove(event: TouchEvent) {
    if (this.state && event.touches.length > 0) {
      const touch = event.touches[0];
      const rect = this.state.canvas.getBoundingClientRect();
      const x = touch.clientX - rect.left;
      const y = touch.clientY - rect.top;

      const scaleX = this.state.canvas.width / rect.width;
      const scaleY = this.state.canvas.height / rect.height;

      this.state.app = FlowFieldApp.on_mouse_move(
        this.state.app,
        x * scaleX,
        y * scaleY
      );
    }
  },

  handleMouseLeave() {
    if (this.state) {
      this.state.app = FlowFieldApp.on_mouse_leave(this.state.app);
    }
  },

  handleResize() {
    if (this.state) {
      this.resizeCanvas(this.state.canvas);
      // Recreate app with new dimensions
      const seed = this.state.canvas.dataset.seed || "default";
      const seedHash = this.hashString(seed);
      this.state.app = FlowFieldApp.create(this.state.canvas, seedHash);
    }
  },

  resizeCanvas(canvas: HTMLCanvasElement) {
    const parent = canvas.parentElement;
    if (parent) {
      // Use device pixel ratio for sharp rendering
      const dpr = window.devicePixelRatio || 1;
      const rect = parent.getBoundingClientRect();

      canvas.width = rect.width * dpr;
      canvas.height = rect.height * dpr;

      // Scale canvas back down with CSS
      canvas.style.width = `${rect.width}px`;
      canvas.style.height = `${rect.height}px`;
    }
  },

  // Simple string hash for deterministic seed
  hashString(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash);
  },
};

export default FlowFieldHook;
