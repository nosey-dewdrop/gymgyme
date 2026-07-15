# gymgyme 💪

a personal trainer that runs entirely in your browser. computer vision counts your reps on your own device, scores your form 0-100 and corrects your posture in 3d. not a single frame is uploaded anywhere. for everyone working out alone at home asking "am i doing this right?"

live: https://gymgyme.noseydewdrop.com

## how it works and what i used for it

the real work happens in the c++ engine in `engine/`, hand-written and compiled to webassembly. every frame, mediapipe's pose landmarker reads 33 body points on the gpu. my engine takes those noisy points and does the actual coaching:

- **one euro filter in joint-angle space**. i picked the parameters with a measurement bench, not by feel
- **bone-lock skeleton**: calibration learns your bone lengths in metric world coordinates, then refits the skeleton every frame
- **person lock**: if someone else walks into the frame, the engine refuses to coach them
- **motion-prior gating**: the physically possible angular velocity is derived from each move's own spec. squat physics while you squat
- **rep counting with hysteresis**, half-rep detection, 0-100 scoring (depth/tempo/control) and a one-line coach comment after every rep

around the engine there is a cinema-marquee world: a 188-move library, liked moves, one-tap programs, a streak calendar that fills in like a contribution graph, and a community-curated directory of home training links.

## measurement and accuracy, benchmark not claims 📏

- **bone length variance: raw ~5% → 0.00%** (bone-lock skeleton). joints can no longer drift.
- **jitter in bad light: 5.0° → 2.3°** (one euro filter, parameters chosen by sweep). the first sweep introduced 100 ms of latency, i caught it by adding a latency penalty.
- **120+ native unit tests** (`engine/test.sh`) plus a synthetic ground-truth measurement bench (`engine/bench.sh`: jitter, rmse, latency, bone variance, two-person scenarios).
- there is a hidden `?rec=1` recorder that captures the landmark stream for offline evaluation. i measure with recordings, not with feelings.

## tech

c++17 → webassembly (emscripten) engine plus static html/css/js (no build step) plus mediapipe tasks (vendored, on-device) plus supabase (accounts and workout counts, rls protected). hosted on vercel. pwa.

**free, no ads, no tracking. your workout counts (never video) sync only if you sign in.**

## why i built it 🌷

everyone trying to work out at home has the same problem: you do not know if you are doing it right, nobody counts, nobody corrects you. i wanted the gym coach in your pocket, but not something that sends your camera feed to the cloud. privacy should be enforced by physics, not by my promises. so the camera image never leaves the device and it cannot: the strictest privacy policy is the one physics imposes.

## contributing

use the suggestion form on the site. the name you submit is published next to your entry, use a nickname if you want.

## setup notes

- `supabase/migration.sql` tables, rls policies and seed rows. paste it once into the supabase sql editor.
- `config.js` supabase url plus anon key (intentionally public, rls protects everything).
- after the domain binds: update the canonical/og:url in `index.html`, add robots.txt plus sitemap.xml with the real domain.
