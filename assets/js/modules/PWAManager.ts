/**
 * PWA Manager - Handles service worker registration and install prompts
 */

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

export class PWAManager {
  private deferredPrompt: BeforeInstallPromptEvent | null = null;
  private isInstalled = false;
  private serviceWorkerRegistration: ServiceWorkerRegistration | null = null;

  constructor() {
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

      console.log('[PWA] Manager initialized');
    } catch (error) {
      console.error('[PWA] Initialization failed:', error);
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
      this.serviceWorkerRegistration = await navigator.serviceWorker.register('/sw.js', {
        scope: '/'
      });

      console.log('[PWA] Service Worker registered:', this.serviceWorkerRegistration);

      // Check for updates periodically
      setInterval(() => {
        this.serviceWorkerRegistration?.update();
      }, 60 * 60 * 1000); // Check every hour

      // Handle updates
      this.handleServiceWorkerUpdates();
    } catch (error) {
      console.error('[PWA] Service Worker registration failed:', error);
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
    const updateBanner = document.createElement('div');
    updateBanner.className = 'pwa-update-banner';
    updateBanner.innerHTML = `
      <span>A new version is available!</span>
      <button id="pwa-update-btn" class="pwa-update-btn">Update</button>
    `;

    document.body.appendChild(updateBanner);

    document.getElementById('pwa-update-btn')?.addEventListener('click', () => {
      this.applyUpdate();
    });
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

      // Show install button if not already installed
      if (!this.isInstalled) {
        this.showInstallButton();
      }

      console.log('[PWA] Install prompt captured');
    });

    // Listen for app installed event
    window.addEventListener('appinstalled', () => {
      console.log('[PWA] App installed');
      this.isInstalled = true;
      this.hideInstallButton();
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
        this.hideInstallButton();
        console.log('[PWA] Changed to standalone mode');
      }
    });
  }

  /**
   * Show install button in UI
   */
  private showInstallButton(): void {
    // Check if button already exists
    if (document.getElementById('pwa-install-btn')) return;

    const installButton = document.createElement('button');
    installButton.id = 'pwa-install-btn';
    installButton.className = 'pwa-install-btn';
    installButton.innerHTML = '+ Install App';
    installButton.setAttribute('aria-label', 'Install droo.foo as an app');

    installButton.addEventListener('click', () => {
      this.promptInstall();
    });

    // Add to appropriate location in UI
    const container = document.querySelector('.terminal-header') || document.body;
    container.appendChild(installButton);

    console.log('[PWA] Install button shown');
  }

  /**
   * Hide install button from UI
   */
  private hideInstallButton(): void {
    const button = document.getElementById('pwa-install-btn');
    if (button) {
      button.remove();
      console.log('[PWA] Install button hidden');
    }
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

      navigator.serviceWorker.controller.postMessage(
        { type: 'CLEAR_CACHE' },
        [messageChannel.port2]
      );
    });
  }

  /**
   * Get PWA status information
   */
  getStatus(): {
    isInstalled: boolean;
    hasServiceWorker: boolean;
    canInstall: boolean;
  } {
    return {
      isInstalled: this.isInstalled,
      hasServiceWorker: !!this.serviceWorkerRegistration,
      canInstall: !!this.deferredPrompt
    };
  }
}

// Declare gtag for TypeScript
declare function gtag(...args: any[]): void;

export default PWAManager;