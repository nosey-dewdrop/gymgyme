# gymgyme

A personal trainer that runs **entirely in your browser** — computer vision, on your device, no upload, ever.

The heart is a **hand-written C++ engine compiled to WebAssembly** (`engine/`). Each frame, MediaPipe's pose landmarker reads 33 body points on your GPU; our engine takes those noisy points and does the actual coaching:

- **One Euro filtering in joint-angle space** (parameters picked by a measurement bench, not by feel)
- **Bone-lock skeleton**: calibration learns YOUR bone lengths in metric world space, then re-fits the skeleton every frame — bone-length variance drops from ~5% raw to 0.00%, joints cannot slide
- **Person lock**: if someone else walks into the frame, the engine refuses to coach them (calibrated body proportions + temporal consistency veto)
- **Exercise-prior gating**: the physically possible angular speed is derived from each move's own spec — squat physics during a squat
- **Rep counting with hysteresis**, half-rep detection, 0-100 scoring (depth/tempo/control) and a one-line coach comment after every rep
- Face mesh + hand skeleton + segmentation silhouette as a visual layer; depth-coded drawing

120+ native unit tests (`engine/test.sh`), a measurement bench with synthetic ground truth (`engine/bench.sh`: jitter, RMSE, lag, bone variance, two-person scenarios), and a hidden `?rec=1` recorder that captures landmark streams for offline evaluation. The camera image never leaves the device — the strictest privacy policy is the one physics enforces.

Around the engine: a cinema-marquee world with a 188-move library, liked moves, one-tap programs, a residency calendar that paints like a contribution graph, and a community-curated directory of home training links.

**Free, no ads, no tracking. Workout numbers (never video) sync only if you sign in.**

## Stack
C++17 → WebAssembly (emscripten) engine + static HTML/CSS/JS (no build step) + MediaPipe Tasks (vendored, on-device) + Supabase (accounts + workout numbers, RLS-guarded). Hosted on Vercel.

## Contributing
Use the suggestion form on the site — that's the whole point. Your display name is published on the page with the entry; use a nickname if you prefer.

## Setup notes
- `supabase/migration.sql` — table, RLS policies and seed rows; paste into the Supabase SQL editor once.
- `config.js` — Supabase URL + anon key (public by design, RLS protects everything).
- After the domain is attached: update canonical/og:url in `index.html` and add robots.txt + sitemap.xml with the real domain.
