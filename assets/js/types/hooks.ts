/**
 * Type definitions for Phoenix LiveView hooks
 */

export interface PhoenixHookElement extends HTMLElement {
  phxHookId?: string;
}

export interface PhoenixLiveViewHook {
  el: PhoenixHookElement;
  viewName?: string;

  // Lifecycle callbacks
  mounted?: () => void;
  beforeUpdate?: () => void;
  updated?: () => void;
  destroyed?: () => void;
  disconnected?: () => void;
  reconnected?: () => void;

  // Phoenix LiveView methods
  pushEvent?: (event: string, payload?: any, callback?: (reply: any, ref: number) => void) => number;
  pushEventTo?: (selector: string, event: string, payload?: any, callback?: (reply: any, ref: number) => void) => void;
  handleEvent?: (event: string, callback: (payload: any) => void) => void;
  removeHandleEvent?: (event: string) => void;
  upload?: (name: string, files: File[]) => void;
  uploadTo?: (selector: string, name: string, files: File[]) => void;
}

export interface TerminalHookConfig {
  enableDebug?: boolean;
  focusOnClick?: boolean;
  verifyAlignment?: boolean;
}

export interface KeyboardHandlerConfig {
  terminalKeys?: string[];
  preventDefault?: boolean;
  stopPropagation?: boolean;
}