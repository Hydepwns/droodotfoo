/**
 * LiveView Bridge for Astro PWA Components
 * Handles communication between Phoenix LiveView and Astro PWA components
 */

import PWAManager from '../utils/PWAManager.ts';

interface PWABridgeOptions {
  onInstall?: () => void;
  onUpdate?: () => void;
  onError?: (error: Error) => void;
  onStatusChange?: (status: any) => void;
}

export class PWABridge {
  private pwaManager: PWAManager | null = null;
  private options: PWABridgeOptions;
  private eventListeners: Map<string, Function> = new Map();

  constructor(options: PWABridgeOptions = {}) {
    this.options = options;
    this.setupEventListeners();
  }

  private setupEventListeners() {
    // Listen for LiveView events
    document.addEventListener('phx:pwa_command', (event: CustomEvent) => {
      this.handlePWACommand(event.detail);
    });

    // Listen for PWA events from components
    document.addEventListener('pwa-install-available', (event: CustomEvent) => {
      this.handleInstallAvailable(event.detail);
    });

    document.addEventListener('pwa-installed', (event: CustomEvent) => {
      this.handleInstalled(event.detail);
    });

    document.addEventListener('pwa-update-available', (event: CustomEvent) => {
      this.handleUpdateAvailable(event.detail);
    });

    document.addEventListener('pwa-status-changed', (event: CustomEvent) => {
      this.handleStatusChanged(event.detail);
    });
  }

  private handlePWACommand(payload: { command: { type: string; [key: string]: any } }) {
    if (!this.pwaManager) return;

    const { command } = payload;

    switch (command.type) {
      case 'install':
        this.pwaManager.promptInstall();
        break;
      case 'update':
        this.pwaManager.applyUpdate();
        break;
      case 'clear_cache':
        this.pwaManager.clearCaches();
        break;
      case 'get_status':
        this.sendStatusToLiveView();
        break;
      default:
        console.warn('Unknown PWA command:', command.type);
    }
  }

  private handleInstallAvailable(detail: any) {
    // Notify LiveView that install is available
    this.sendToLiveView('pwa_install_available', { canInstall: true });
    
    if (this.options.onInstall) {
      this.options.onInstall();
    }
  }

  private handleInstalled(detail: any) {
    // Notify LiveView that app was installed
    this.sendToLiveView('pwa_installed', { isInstalled: true });
    
    if (this.options.onInstall) {
      this.options.onInstall();
    }
  }

  private handleUpdateAvailable(detail: any) {
    // Notify LiveView that update is available
    this.sendToLiveView('pwa_update_available', { hasUpdate: true });
    
    if (this.options.onUpdate) {
      this.options.onUpdate();
    }
  }

  private handleStatusChanged(detail: any) {
    // Notify LiveView of status change
    this.sendToLiveView('pwa_status_changed', detail);
    
    if (this.options.onStatusChange) {
      this.options.onStatusChange(detail);
    }
  }

  private sendStatusToLiveView() {
    if (!this.pwaManager) return;

    const status = this.pwaManager.getStatus();
    this.sendToLiveView('pwa_status', status);
  }

  private sendToLiveView(event: string, payload?: any) {
    const eventData = new CustomEvent(`phx:${event}`, {
      detail: payload
    });
    document.dispatchEvent(eventData);
  }

  public initializePWA(options: any = {}) {
    this.pwaManager = new PWAManager({
      onInstall: () => {
        this.handleInstalled({ isInstalled: true });
      },
      onUpdate: () => {
        this.handleUpdateAvailable({ hasUpdate: true });
      },
      onError: (error) => {
        this.handleError(error);
        if (this.options.onError) {
          this.options.onError(error);
        }
      },
      ...options
    });

    // Initialize PWA Manager
    this.pwaManager.init();
  }

  private handleError(error: Error) {
    this.sendToLiveView('pwa_error', { error: error.message });
  }

  public getStatus() {
    return this.pwaManager?.getStatus() || {
      isInstalled: false,
      hasServiceWorker: false,
      canInstall: false
    };
  }

  public destroy() {
    if (this.pwaManager) {
      this.pwaManager.destroy();
      this.pwaManager = null;
    }

    // Clean up event listeners
    this.eventListeners.forEach((handler, event) => {
      document.removeEventListener(event, handler as EventListener);
    });
    this.eventListeners.clear();
  }
}

export default PWABridge;
