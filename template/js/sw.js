let CACHE = "__CACHE_PREFIX__-v__VERSION__";
let CORE = __CORE__;
let PRODUCTS = __PRODUCTS__;
let PAGES = __PAGES__;

let PREFETCH_SENTINEL = "/__prefetch_done__";
let CORE_TIMEOUT_MS = 2500;

self.addEventListener("install", function(e) {
  e.waitUntil(
    caches.open(CACHE).then(function(c) { return c.addAll(CORE); })
      .then(function() { return self.skipWaiting(); })
  );
});

self.addEventListener("activate", function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(k) { return k !== CACHE; })
            .map(function(k) { return caches.delete(k); })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener("message", function(e) {
  if (e.data === "cache-all") {
    e.waitUntil(
      caches.open(CACHE).then(function(c) {
        return c.match(PREFETCH_SENTINEL).then(function(done) {
          if (done) { return; }
          return c.addAll(PRODUCTS)
            .catch(function() {})
            .then(function() { return c.addAll(PAGES); })
            .catch(function() {})
            .then(function() {
              return c.put(PREFETCH_SENTINEL, new Response("", { status: 200 }));
            });
        });
      })
    );
  }
});

function shouldCache(req, res) {
  if (!res || !res.ok) return false;
  if (res.type === "opaque" || res.type === "opaqueredirect") return false;
  if (req.method !== "GET") return false;
  let url = new URL(req.url);
  if (url.origin !== self.location.origin) return false;
  return true;
}

function fetchWithTimeout(req, ms) {
  return new Promise(function(resolve, reject) {
    let timedOut = false;
    let timer = setTimeout(function() { timedOut = true; reject(new Error("timeout")); }, ms);
    fetch(req).then(function(res) {
      clearTimeout(timer);
      if (!timedOut) resolve(res);
    }, function(err) {
      clearTimeout(timer);
      if (!timedOut) reject(err);
    });
  });
}

self.addEventListener("fetch", function(e) {
  if (e.request.method !== "GET") return;

  let url = new URL(e.request.url);
  if (url.origin !== self.location.origin) return;

  let isCore = CORE.indexOf(url.pathname) !== -1;

  if (isCore) {
    e.respondWith(
      fetchWithTimeout(e.request, CORE_TIMEOUT_MS).then(function(res) {
        if (shouldCache(e.request, res)) {
          let clone = res.clone();
          caches.open(CACHE).then(function(c) { c.put(e.request, clone); });
        }
        return res;
      }).catch(function() {
        return caches.match(e.request).then(function(cached) {
          return cached || fetch(e.request);
        });
      })
    );
    return;
  }

  e.respondWith(
    caches.match(e.request).then(function(cached) {
      let fetched = fetch(e.request).then(function(res) {
        if (shouldCache(e.request, res)) {
          let clone = res.clone();
          caches.open(CACHE).then(function(c) { c.put(e.request, clone); });
        }
        return res;
      }).catch(function() {
        return cached;
      });
      return cached || fetched;
    })
  );
});
