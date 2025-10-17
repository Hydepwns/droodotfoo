// Service Worker for droo.foo PWA
const CACHE_VERSION = 'v1.0.0';
const CACHE_NAME = `droodotfoo-${CACHE_VERSION}`;

// Assets to cache on install
const STATIC_ASSETS = [
  '/',
  '/manifest.json',
  '/assets/css/app.css',
  '/assets/js/app.js',
  '/images/icon-192x192.png',
  '/images/icon-512x512.png'
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('[Service Worker] Installing...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[Service Worker] Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      })
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Activating...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name.startsWith('droodotfoo-') && name !== CACHE_NAME)
          .map((name) => {
            console.log('[Service Worker] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - network first, fallback to cache
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }

  // Skip WebSocket connections
  if (url.protocol === 'ws:' || url.protocol === 'wss:') {
    return;
  }

  // Skip Phoenix LiveView sockets
  if (url.pathname.startsWith('/live/websocket')) {
    return;
  }

  // Network-first strategy for same-origin requests
  if (url.origin === location.origin) {
    event.respondWith(
      fetch(request)
        .then((response) => {
          // Clone the response before caching
          const responseClone = response.clone();

          // Cache successful responses
          if (response.status === 200) {
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(request, responseClone);
            });
          }

          return response;
        })
        .catch(() => {
          // Fallback to cache on network failure
          return caches.match(request).then((cachedResponse) => {
            if (cachedResponse) {
              console.log('[Service Worker] Serving from cache:', request.url);
              return cachedResponse;
            }

            // Return offline page for HTML requests
            if (request.headers.get('accept')?.includes('text/html')) {
              return new Response(
                `<!DOCTYPE html>
                <html>
                  <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <title>Offline - droo.foo</title>
                    <style>
                      body {
                        font-family: monospace;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        height: 100vh;
                        margin: 0;
                        background: #000;
                        color: #0f0;
                        text-align: center;
                      }
                      .container {
                        border: 2px solid #0f0;
                        padding: 2rem;
                        max-width: 400px;
                      }
                      h1 { margin: 0 0 1rem 0; }
                      p { margin: 0.5rem 0; }
                    </style>
                  </head>
                  <body>
                    <div class="container">
                      <h1>OFFLINE</h1>
                      <p>No network connection detected.</p>
                      <p>Please check your connection and try again.</p>
                    </div>
                  </body>
                </html>`,
                {
                  headers: { 'Content-Type': 'text/html' }
                }
              );
            }

            return new Response('Offline', { status: 503 });
          });
        })
    );
  }
});

// Handle messages from the client
self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
  }
});
