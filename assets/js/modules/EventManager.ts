/**
 * Module for managing grid-related events with proper cleanup
 */
import { EventCallback } from '../types';

export class EventManager {
  private listeners: Map<string, Set<EventCallback>>;
  private windowListeners: Map<string, EventListener>;
  private abortController: AbortController | null = null;

  constructor() {
    this.listeners = new Map();
    this.windowListeners = new Map();

    // Create AbortController if supported
    if (typeof AbortController !== 'undefined') {
      this.abortController = new AbortController();
    }
  }

  /**
   * Adds a window event listener with automatic cleanup
   * @param event - Event name
   * @param handler - Event handler
   * @param options - Event listener options
   */
  addWindowListener(event: string, handler: EventListener, options?: AddEventListenerOptions): void {
    try {
      const key = `${event}:${handler.toString()}`;

      // Remove existing listener if present
      if (this.windowListeners.has(key)) {
        this.removeWindowListener(event, this.windowListeners.get(key)!);
      }

      const listenerOptions = this.abortController
        ? { ...options, signal: this.abortController.signal }
        : options;

      window.addEventListener(event, handler, listenerOptions);
      this.windowListeners.set(key, handler);
    } catch (error) {
      console.error(`Failed to add window listener for ${event}:`, error);
    }
  }

  /**
   * Removes a window event listener
   * @param event - Event name
   * @param handler - Event handler
   */
  removeWindowListener(event: string, handler: EventListener): void {
    try {
      const key = `${event}:${handler.toString()}`;
      window.removeEventListener(event, handler);
      this.windowListeners.delete(key);
    } catch (error) {
      console.error(`Failed to remove window listener for ${event}:`, error);
    }
  }

  /**
   * Adds a custom event listener
   * @param event - Event name
   * @param callback - Event callback
   */
  on(event: string, callback: EventCallback): void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback);
  }

  /**
   * Removes a custom event listener
   * @param event - Event name
   * @param callback - Event callback
   */
  off(event: string, callback: EventCallback): void {
    const callbacks = this.listeners.get(event);
    if (callbacks) {
      callbacks.delete(callback);
      if (callbacks.size === 0) {
        this.listeners.delete(event);
      }
    }
  }

  /**
   * Emits a custom event
   * @param event - Event name
   */
  emit(event: string): void {
    const callbacks = this.listeners.get(event);
    if (callbacks) {
      callbacks.forEach(callback => {
        try {
          callback();
        } catch (error) {
          console.error(`Error in event listener for ${event}:`, error);
        }
      });
    }
  }

  /**
   * Monitors font loading with automatic cleanup
   * @param callback - Callback when fonts are ready
   */
  monitorFontLoad(callback: EventCallback): void {
    if (!document.fonts) {
      // Fallback for browsers without Font Loading API
      setTimeout(callback, 100);
      return;
    }

    document.fonts.ready
      .then(() => {
        try {
          callback();
        } catch (error) {
          console.error('Error in font load callback:', error);
        }
      })
      .catch(error => {
        console.error('Font loading failed:', error);
        // Still call the callback to ensure grid initialization
        callback();
      });
  }

  /**
   * Cleans up all event listeners
   */
  cleanup(): void {
    // Clear custom event listeners
    this.listeners.clear();

    // Remove all window event listeners
    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    } else {
      // Manual cleanup if AbortController is not supported
      this.windowListeners.forEach((handler, key) => {
        const [event] = key.split(':');
        window.removeEventListener(event, handler);
      });
    }

    this.windowListeners.clear();
    console.log('Event listeners cleaned up');
  }
}