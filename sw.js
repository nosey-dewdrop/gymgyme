// gymgyme service worker: ana ekrana kurulan personal trainer offline da açılsın.
// kamera + motor zaten cihazda çalışıyor; burada sadece dosyaları önbelleğe alıyoruz.
// vendor/ ya da engine/ değişirse CACHE sürümünü artır — eski önbellek silinir.
const CACHE = "gg-pwa-v83";  // v83: loop narrow heading col (no dead space), close max720 row acts, sections content-height

const CORE = [
  "coach.html",
  "my-moves.html",
  "my-program.html",
  "css/site.css",
  "js/coach.js",
  "js/mesh.js",
  "js/topbar.js",
  "data/moves-db.js",
  "js/config.js",
  "js/auth.js",
  "js/auth-pages.js",
  "js/coach-onboarding.js",
  "signup.html",
  "signin.html",
  "account.html",
  "engine/motor.js",
  "engine/motor.wasm",
  "vendor/supabase/supabase.js",
  "vendor/mediapipe/vision_bundle.mjs",
  "vendor/mediapipe/wasm/vision_wasm_internal.js",
  "vendor/mediapipe/wasm/vision_wasm_internal.wasm",
  "vendor/mediapipe/wasm/vision_wasm_nosimd_internal.js",
  "vendor/mediapipe/wasm/vision_wasm_nosimd_internal.wasm",
  "vendor/models/pose_landmarker_full.task",
  "vendor/models/face_landmarker.task",
  "vendor/models/hand_landmarker.task",
  "manifest.webmanifest",
  "icons/icon-192.png",
  "icons/icon-512.png",
  "gizlilik.html"
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(CORE)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;                      // auth/DB istekleri karışmaz
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;       // supabase vb. dışarıda kalır

  // vendor MediaPipe (3. taraf, hiç değişmez): önce önbellek (hız + offline).
  if (url.pathname.includes("/vendor/")) {
    e.respondWith(caches.match(req).then((hit) => hit || fetch(req)));
    return;
  }
  // MOTOR (engine/): ARTIK ÖNCE AĞ — motor.wasm/js sık değişiyordu ve önbellek
  // eski motoru veriyordu (Damla: değişiklik gelmiyor). güncellik şart, offline
  // fallback yeter. HTML/JS/CSS zaten aşağıda önce-ağ.

  // geri kalan HER ŞEY (html/js/css/engine): önce AĞ (daima güncel),
  // düşerse önbellek (offline). değişiklikler artık ANINDA gelir.
  e.respondWith(
    fetch(req)
      .then((res) => {
        if (res.ok) {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put(req, copy));
        }
        return res;
      })
      .catch(() => caches.match(req, { ignoreSearch: url.pathname.endsWith("coach.html") }))
  );
});
