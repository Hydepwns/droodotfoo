/**
 * Service Worker for droo.foo PWA
 * Handles offline support and caching
 */

const CACHE_NAME = 'droo-foo-v1';
const RUNTIME_CACHE = 'droo-foo-runtime';

// Static assets to cache for offline support
const STATIC_CACHE_URLS = [
  '/',
  '/assets/css/app.css',
  '/assets/js/app.js',
  '/fonts/MonaspaceArgon-Regular.woff2',
  '/manifest.json'
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('[ServiceWorker] Installing...');

  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[ServiceWorker] Caching static assets');
        return cache.addAll(STATIC_CACHE_URLS);
      })
      .then(() => {
        console.log('[ServiceWorker] Skip waiting');
        return self.skipWaiting();
      })
      .catch((error) => {
        console.error('[ServiceWorker] Installation failed:', error);
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[ServiceWorker] Activating...');

  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((cacheName) => {
              return cacheName !== CACHE_NAME && cacheName !== RUNTIME_CACHE;
            })
            .map((cacheName) => {
              console.log('[ServiceWorker] Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            })
        );
      })
      .then(() => {
        console.log('[ServiceWorker] Claiming clients');
        return self.clients.claim();
      })
  );
});

// Fetch event - serve from cache when possible
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }

  // Skip WebSocket requests
  if (url.protocol === 'ws:' || url.protocol === 'wss:') {
    return;
  }

  // Skip Phoenix LiveView requests
  if (url.pathname.includes('/live') || url.pathname.includes('/phoenix')) {
    return;
  }

  // Network-first strategy for HTML (for LiveView compatibility)
  if (request.headers.get('accept')?.includes('text/html')) {
    event.respondWith(
      fetch(request)
        .then((response) => {
          // Clone the response before caching
          const responseToCache = response.clone();

          caches.open(RUNTIME_CACHE)
            .then((cache) => {
              cache.put(request, responseToCache);
            });

          return response;
        })
        .catch(() => {
          // Fall back to cache if network fails
          return caches.match(request)
            .then((response) => {
              if (response) {
                console.log('[ServiceWorker] Serving HTML from cache:', request.url);
                return response;
              }
              // Return offline page if available
              return caches.match('/');
            });
        })
    );
    return;
  }

  // Cache-first strategy for static assets
  event.respondWith(
    caches.match(request)
      .then((cachedResponse) => {
        if (cachedResponse) {
          // Fetch in background to update cache
          fetch(request)
            .then((response) => {
              if (response.ok) {
                caches.open(RUNTIME_CACHE)
                  .then((cache) => {
                    cache.put(request, response.clone());
                  });
              }
            })
            .catch(() => {
              // Ignore network errors for background updates
            });

          return cachedResponse;
        }

        // Not in cache, fetch from network
        return fetch(request)
          .then((response) => {
            // Cache successful responses
            if (response.ok) {
              const responseToCache = response.clone();

              caches.open(RUNTIME_CACHE)
                .then((cache) => {
                  cache.put(request, responseToCache);
                });
            }

            return response;
          });
      })
      .catch((error) => {
        console.error('[ServiceWorker] Fetch failed:', error);
        // Return offline fallback if appropriate
        if (request.destination === 'image') {
          // Could return a placeholder image
        }
      })
  );
});

// Handle messages from clients
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    console.log('[ServiceWorker] Skip waiting on message');
    self.skipWaiting();
  }

  if (event.data && event.data.type === 'CLEAR_CACHE') {
    console.log('[ServiceWorker] Clearing caches');
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => caches.delete(cacheName))
        );
      })
      .then(() => {
        event.ports[0].postMessage({ success: true });
      })
      .catch((error) => {
        event.ports[0].postMessage({ success: false, error: error.message });
      });
  }
});