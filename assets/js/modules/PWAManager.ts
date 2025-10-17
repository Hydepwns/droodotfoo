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

      // For testing: always show uninstall button
      // In production, this should only show when installed
      this.showUninstallButton();

      console.log('[PWA] Manager initialized');
      console.log('[PWA] Install status:', {
        isInstalled: this.isInstalled,
        hasServiceWorker: !!this.serviceWorkerRegistration,
        canInstall: !!this.deferredPrompt
      });
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
      this.showUninstallButton();
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
        this.showUninstallButton();
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

    const footer = document.getElementById('site-footer');
    if (!footer) return;

    // Add separator if footer has content
    if (footer.textContent && footer.textContent.trim().length > 0) {
      footer.appendChild(document.createTextNode(' • '));
    }

    const installButton = document.createElement('a');
    installButton.id = 'pwa-install-btn';
    installButton.className = 'pwa-install-link';
    installButton.innerHTML = 'Install app';
    installButton.setAttribute('href', '#');
    installButton.setAttribute('aria-label', 'Install droo.foo as an app');
    installButton.setAttribute('data-tooltip', '+ Works offline\n+ Faster loading\n+ Desktop app\n+ Auto updates');

    installButton.addEventListener('click', (e) => {
      e.preventDefault();
      this.promptInstall();
    });

    footer.appendChild(installButton);

    console.log('[PWA] Install link shown in footer');
  }

  /**
   * Hide install button from UI
   */
  private hideInstallButton(): void {
    const button = document.getElementById('pwa-install-btn');
    if (button) {
      // Remove the separator before it too
      const previousNode = button.previousSibling;
      if (previousNode && previousNode.nodeType === Node.TEXT_NODE && previousNode.textContent === ' • ') {
        previousNode.remove();
      }
      button.remove();
      console.log('[PWA] Install button hidden');
    }
  }

  /**
   * Show uninstall button in UI
   */
  private showUninstallButton(): void {
    // Check if button already exists
    if (document.getElementById('pwa-uninstall-btn')) return;

    const footer = document.getElementById('site-footer');
    if (!footer) return;

    // Add separator if footer has content
    if (footer.textContent && footer.textContent.trim().length > 0) {
      footer.appendChild(document.createTextNode(' • '));
    }

    const uninstallButton = document.createElement('a');
    uninstallButton.id = 'pwa-uninstall-btn';
    uninstallButton.className = 'pwa-install-link';
    uninstallButton.innerHTML = 'Uninstall app';
    uninstallButton.setAttribute('href', '#');
    uninstallButton.setAttribute('aria-label', 'Uninstall droo.foo app');
    uninstallButton.setAttribute('data-tooltip', 'Clear caches\nReset app state\nFor testing');

    uninstallButton.addEventListener('click', (e) => {
      e.preventDefault();
      this.uninstall();
    });

    footer.appendChild(uninstallButton);

    console.log('[PWA] Uninstall link shown in footer');
  }

  /**
   * Hide uninstall button from UI
   */
  private hideUninstallButton(): void {
    const button = document.getElementById('pwa-uninstall-btn');
    if (button) {
      // Remove the separator before it too
      const previousNode = button.previousSibling;
      if (previousNode && previousNode.nodeType === Node.TEXT_NODE && previousNode.textContent === ' • ') {
        previousNode.remove();
      }
      button.remove();
      console.log('[PWA] Uninstall button hidden');
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
   * Uninstall PWA - clears caches and unregisters service worker
   */
  async uninstall(): Promise<void> {
    try {
      console.log('[PWA] Starting uninstall process...');

      // Clear all caches
      try {
        await this.clearCaches();
      } catch (error) {
        console.log('[PWA] Cache clearing failed (may not be registered):', error);
      }

      // Unregister all service workers
      if ('serviceWorker' in navigator) {
        const registrations = await navigator.serviceWorker.getRegistrations();
        for (const registration of registrations) {
          await registration.unregister();
          console.log('[PWA] Service worker unregistered');
        }
      }

      // Clear service worker registration reference
      this.serviceWorkerRegistration = null;

      // Reset install state
      this.isInstalled = false;

      // Update UI
      this.hideUninstallButton();

      console.log('[PWA] Uninstall complete. Reloading...');

      // Show brief message before reload
      alert('PWA uninstalled! Caches cleared and service worker removed.\n\nTo complete removal from your system:\n- Chrome: chrome://apps, right-click droo.foo, Remove\n- Edge: edge://apps\n- Safari: Delete from Applications folder');

      // Reload to reset state
      window.location.reload();
    } catch (error) {
      console.error('[PWA] Uninstall failed:', error);
      alert('Uninstall failed. Check console for details.');
    }
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