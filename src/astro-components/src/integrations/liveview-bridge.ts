/**
 * LiveView Bridge for Astro STL Viewer
 * Handles communication between Phoenix LiveView and Astro STL Viewer component
 */

import STLViewerClient from '../components/STLViewer';

interface LiveViewBridgeOptions {
  componentId: string;
  onModelLoaded?: (info: any) => void;
  onModelError?: (error: string) => void;
}

export class LiveViewBridge {
  private stlViewer: STLViewerClient | null = null;
  private options: LiveViewBridgeOptions;
  private eventListeners: Map<string, Function> = new Map();

  constructor(options: LiveViewBridgeOptions) {
    this.options = options;
    this.setupEventListeners();
  }

  private setupEventListeners() {
    // Listen for LiveView events
    document.addEventListener('phx:stl_command', (event: CustomEvent) => {
      this.handleSTLCommand(event.detail);
    });

    // Listen for keyboard events
    document.addEventListener('keydown', (event: KeyboardEvent) => {
      this.handleKeyboardEvent(event);
    });
  }

  private handleSTLCommand(payload: { command: { type: string; [key: string]: any } }) {
    if (!this.stlViewer) return;

    const { command } = payload;

    switch (command.type) {
      case 'load':
        this.stlViewer.loadModel(command.url);
        break;
      case 'mode':
        this.stlViewer.setRenderMode(command.mode);
        break;
      case 'rotate':
        this.stlViewer.rotateCamera(command.axis, command.angle);
        break;
      case 'reset':
        this.stlViewer.resetCamera();
        break;
      case 'zoom':
        this.stlViewer.zoom(command.distance);
        break;
      default:
        console.warn('Unknown STL command:', command.type);
    }
  }

  private handleKeyboardEvent(event: KeyboardEvent) {
    if (!this.stlViewer) return;

    // STL Viewer keyboard controls
    switch (event.key) {
      case 'j':
        this.stlViewer.rotateCamera('y', 0.1);
        break;
      case 'k':
        this.stlViewer.rotateCamera('y', -0.1);
        break;
      case 'h':
        this.stlViewer.rotateCamera('x', 0.1);
        break;
      case 'l':
        this.stlViewer.rotateCamera('x', -0.1);
        break;
      case '+':
      case '=':
        this.stlViewer.zoom(-0.5);
        break;
      case '-':
        this.stlViewer.zoom(0.5);
        break;
      case 'r':
        this.stlViewer.resetCamera();
        break;
      case 'm':
        this.stlViewer.cycleRenderMode();
        break;
    }
  }

  public initializeSTLViewer(container: HTMLElement) {
    this.stlViewer = new STLViewerClient(container, {
      componentId: this.options.componentId,
      onModelLoaded: (info) => {
        // Send model info back to LiveView
        this.dispatchEvent('model_loaded', info);
        if (this.options.onModelLoaded) {
          this.options.onModelLoaded(info);
        }
      },
      onModelError: (error) => {
        // Send error back to LiveView
        this.dispatchEvent('model_error', { error });
        if (this.options.onModelError) {
          this.options.onModelError(error);
        }
      }
    });
  }

  private dispatchEvent(eventName: string, payload: any) {
    // Dispatch custom event that LiveView can listen to
    const event = new CustomEvent(`phx:${eventName}`, {
      detail: payload
    });
    document.dispatchEvent(event);
  }

  public destroy() {
    if (this.stlViewer) {
      this.stlViewer.destroy();
      this.stlViewer = null;
    }
  }
}

export default LiveViewBridge;
