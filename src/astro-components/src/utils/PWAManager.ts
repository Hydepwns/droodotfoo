/**
 * PWA Manager for Astro Components
 * Handles service worker registration and install prompts with Astro integration
 */

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

interface PWAStatus {
  isInstalled: boolean;
  hasServiceWorker: boolean;
  canInstall: boolean;
}

interface PWAManagerOptions {
  serviceWorkerPath?: string;
  scope?: string;
  updateCheckInterval?: number;
  onInstall?: () => void;
  onUpdate?: () => void;
  onError?: (error: Error) => void;
}

export class PWAManager {
  private deferredPrompt: BeforeInstallPromptEvent | null = null;
  private isInstalled = false;
  private serviceWorkerRegistration: ServiceWorkerRegistration | null = null;
  private options: PWAManagerOptions;
  private updateCheckInterval: NodeJS.Timeout | null = null;

  constructor(options: PWAManagerOptions = {}) {
    this.options = {
      serviceWorkerPath: '/sw.js',
      scope: '/',
      updateCheckInterval: 60 * 60 * 1000, // 1 hour
      ...options
    };
    
    this.checkIfInstalled();
  }

  /**
   * Initialize PWA functionality
   */
  async init(): Promise<void> {
    try {
      // Register service worker
      await this.registerServiceWorker();

      // Set up install prompt handling
      this.setupInstallPrompt();

      // Monitor installation status
      this.monitorInstallStatus();

      console.log('[PWA] Astro Manager initialized');
    } catch (error) {
      console.error('[PWA] Initialization failed:', error);
      this.options.onError?.(error as Error);
    }
  }

  /**
   * Register the service worker
   */
  private async registerServiceWorker(): Promise<void> {
    if (!('serviceWorker' in navigator)) {
      console.log('[PWA] Service Workers not supported');
      return;
    }

    try {
      this.serviceWorkerRegistration = await navigator.serviceWorker.register(
        this.options.serviceWorkerPath!,
        { scope: this.options.scope }
      );

      console.log('[PWA] Service Worker registered:', this.serviceWorkerRegistration);

      // Check for updates periodically
      this.updateCheckInterval = setInterval(() => {
        this.serviceWorkerRegistration?.update();
      }, this.options.updateCheckInterval);

      // Handle updates
      this.handleServiceWorkerUpdates();
    } catch (error) {
      console.error('[PWA] Service Worker registration failed:', error);
      this.options.onError?.(error as Error);
    }
  }

  /**
   * Handle service worker updates
   */
  private handleServiceWorkerUpdates(): void {
    if (!this.serviceWorkerRegistration) return;

    this.serviceWorkerRegistration.addEventListener('updatefound', () => {
      const newWorker = this.serviceWorkerRegistration!.installing;

      if (!newWorker) return;

      newWorker.addEventListener('statechange', () => {
        if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
          // New service worker available
          this.notifyUpdateAvailable();
        }
      });
    });
  }

  /**
   * Notify user that an update is available
   */
  private notifyUpdateAvailable(): void {
    // Dispatch custom event for Astro components to handle
    const updateEvent = new CustomEvent('pwa-update-available', {
      detail: { 
        registration: this.serviceWorkerRegistration,
        onUpdate: () => this.applyUpdate()
      }
    });
    document.dispatchEvent(updateEvent);

    this.options.onUpdate?.();
  }

  /**
   * Apply service worker update
   */
  private async applyUpdate(): Promise<void> {
    if (!this.serviceWorkerRegistration?.waiting) return;

    // Tell waiting service worker to take control
    this.serviceWorkerRegistration.waiting.postMessage({ type: 'SKIP_WAITING' });

    // Reload once the new service worker takes control
    navigator.serviceWorker.addEventListener('controllerchange', () => {
      window.location.reload();
    });
  }

  /**
   * Set up install prompt handling
   */
  private setupInstallPrompt(): void {
    // Listen for beforeinstallprompt event
    window.addEventListener('beforeinstallprompt', (event: Event) => {
      event.preventDefault();
      this.deferredPrompt = event as BeforeInstallPromptEvent;

      // Dispatch custom event for Astro components
      const installEvent = new CustomEvent('pwa-install-available', {
        detail: { 
          prompt: () => this.promptInstall(),
          canInstall: true
        }
      });
      document.dispatchEvent(installEvent);

      console.log('[PWA] Install prompt captured');
    });

    // Listen for app installed event
    window.addEventListener('appinstalled', () => {
      console.log('[PWA] App installed');
      this.isInstalled = true;
      
      // Dispatch custom event for Astro components
      const installedEvent = new CustomEvent('pwa-installed', {
        detail: { isInstalled: true }
      });
      document.dispatchEvent(installedEvent);

      this.options.onInstall?.();
      this.deferredPrompt = null;
    });
  }

  /**
   * Check if PWA is already installed
   */
  private checkIfInstalled(): void {
    // Check if running in standalone mode
    if (window.matchMedia('(display-mode: standalone)').matches) {
      this.isInstalled = true;
      console.log('[PWA] Already running in standalone mode');
      return;
    }

    // Check if launched from home screen (iOS)
    if ((navigator as any).standalone) {
      this.isInstalled = true;
      console.log('[PWA] Already running as iOS standalone');
      return;
    }

    // Check URL parameters
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('mode') === 'standalone') {
      this.isInstalled = true;
      console.log('[PWA] Launched in standalone mode');
    }
  }

  /**
   * Monitor installation status changes
   */
  private monitorInstallStatus(): void {
    // Monitor display mode changes
    const displayModeQuery = window.matchMedia('(display-mode: standalone)');

    displayModeQuery.addEventListener('change', (event) => {
      if (event.matches) {
        this.isInstalled = true;
        
        // Dispatch custom event for Astro components
        const statusEvent = new CustomEvent('pwa-status-changed', {
          detail: { isInstalled: true }
        });
        document.dispatchEvent(statusEvent);

        console.log('[PWA] Changed to standalone mode');
      }
    });
  }

  /**
   * Prompt user to install the PWA
   */
  async promptInstall(): Promise<void> {
    if (!this.deferredPrompt) {
      console.log('[PWA] No install prompt available');
      return;
    }

    try {
      // Show the install prompt
      await this.deferredPrompt.prompt();

      // Wait for user choice
      const { outcome } = await this.deferredPrompt.userChoice;

      console.log(`[PWA] User ${outcome} the install prompt`);

      if (outcome === 'accepted') {
        // Track installation
        this.trackInstallation();
      }

      // Clear the deferred prompt
      this.deferredPrompt = null;
    } catch (error) {
      console.error('[PWA] Install prompt error:', error);
      this.options.onError?.(error as Error);
    }
  }

  /**
   * Track PWA installation for analytics
   */
  private trackInstallation(): void {
    // Send installation event to analytics if available
    if (typeof gtag !== 'undefined') {
      gtag('event', 'pwa_install', {
        event_category: 'PWA',
        event_label: 'Installation'
      });
    }

    console.log('[PWA] Installation tracked');
  }

  /**
   * Clear all caches (useful for debugging)
   */
  async clearCaches(): Promise<void> {
    if (!navigator.serviceWorker.controller) {
      console.log('[PWA] No active service worker');
      return;
    }

    const messageChannel = new MessageChannel();

    return new Promise((resolve, reject) => {
      messageChannel.port1.onmessage = (event) => {
        if (event.data.success) {
          console.log('[PWA] Caches cleared');
          resolve();
        } else {
          reject(new Error(event.data.error));
        }
      };

      navigator.serviceWorker.controller?.postMessage(
        { type: 'CLEAR_CACHE' },
        [messageChannel.port2]
      );
    });
  }

  /**
   * Get PWA status information
   */
  getStatus(): PWAStatus {
    return {
      isInstalled: this.isInstalled,
      hasServiceWorker: !!this.serviceWorkerRegistration,
      canInstall: !!this.deferredPrompt
    };
  }

  /**
   * Clean up resources
   */
  destroy(): void {
    if (this.updateCheckInterval) {
      clearInterval(this.updateCheckInterval);
      this.updateCheckInterval = null;
    }
    
    console.log('[PWA] Manager destroyed');
  }
}

// Declare gtag for TypeScript
declare function gtag(...args: any[]): void;

export default PWAManager;
