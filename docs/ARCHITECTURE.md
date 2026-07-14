# gymgyme architecture

How the on-device personal trainer works, layer by layer, and why it is built this way.
Everything below runs in the browser; the camera image never leaves the device.

## Layer map

```
camera frame
  → MediaPipe pose landmarker (vendored, on-device, GPU)   33 points × 2 poses, screen + world
  → C++ engine core (engine/coach_engine.hpp/.cpp)         the brain: filter, rig, FSM, scoring
  → wasm bindings (engine/bindings.cpp, emscripten)        pointer-based translation layer
  → JS glue (js/coach.js)                                  camera, drawing, sound, program flow
  → product pages (coach.html, moves.html, my-program…)    the site around the engine
```

### 1. MediaPipe pose (the eyes)

Google's pose landmarker gives 33 body points per frame, in two coordinate sets:
screen space (normalized pixels, used for framing/visibility) and world space
(hip-centered, metric, camera-independent — used for angle geometry). The library,
its wasm and the model are vendored under `vendor/` — no runtime CDN, tight CSP,
works offline. The detector is asked for up to 2 poses; deciding *whose* body to
coach is the engine's job, not the detector's.

### 2. C++ core (the brain)

`engine/coach_engine.hpp/.cpp` is pure, framework-free C++17. It knows nothing about
the web; it knows movement analysis. Per frame it runs this pipeline:

- **Multi-person selection.** With several candidate bodies, `candidateScore` picks
  the tracked one (2.0× temporal similarity to the last accepted pose + 1.5×
  calibrated-ratio error + 0.3× visibility). On top of that sits a **hard veto**: a
  body whose calibrated-proportion mismatch fails the check is disqualified outright,
  and the veto uses the **worst** single bone ratio, not the mean. If only strangers
  are in frame, the engine waits instead of coaching them.
- **Bone lock (the rig).** Calibration (~2 s, opt-in) learns the user's limb *ratios*
  (scale-free, for person lock) and *absolute bone lengths* in metric world space
  (both sides pooled — the body is symmetric, so samples double). With the lock on,
  every frame the skeleton is re-fit hierarchically from hip/shoulder anchors: the
  detector supplies the bone's **direction**, the lock supplies its **length**. All
  angles are then measured from the locked skeleton — bones cannot stretch, joints
  cannot slide.
- **One Euro filtering in joint-angle space.** The tracked angle (not raw landmarks)
  goes through a time-aware One Euro filter: `minCutoff` 2.5 Hz, `beta` 0.005 —
  parameters chosen by the bench's grid sweep, not by feel. An EMA path is kept for
  measurement comparison (`useOneEuro = false`).
- **Exercise-prior speed gate.** Single-frame teleports are swallowed by a time-aware
  angular-speed ceiling derived from each move's own spec (baseline 700°/s): a squat
  physically cannot sweep 90° in one frame, a jumping jack can. Squat physics apply
  *during* a squat.
- **Rep FSM.** Two phases (Top/Bottom) with hysteresis — separate down and up
  thresholds, so noise at the boundary cannot double-count. Descents that pass the
  half-rep depth but never reach bottom are reported as half reps ("not counted"),
  small fidgets are ignored entirely. Each counted rep gets a 0–100 score
  (depth / tempo / eccentric control) and a one-sentence `repComment` (form first,
  depth second, tempo third). Sets, rest countdowns and the session summary also
  live in the core — the browser only renders.

Moves are pure data (`MoveSpec`): joint chain, thresholds, framing points, form
rules, tempo bounds. Adding a move is adding data, not code.

### 3. wasm bindings (the border)

`engine/bindings.cpp` is translation only, no logic. Landmarks cross the JS↔wasm
border by **pointer**: JS writes them once into the wasm heap, the engine reads them
in place — one call per frame, zero per-landmark crossings, no allocations.
Key exports: `updatePtr` (single pose), `updateMultiPtr` (all candidate poses as
consecutive heap blocks, screen + world buffers), `smoothPosePtr`/`smoothPoseOk`
(the engine's own smoothed drawing skeleton). Built by `engine/build.sh` into
`motor.js` + `motor.wasm`, both committed — the site stays build-step-free.

### 4. JS glue (the stage)

`js/coach.js` owns the camera, the wasm module and the canvas. Per frame it fills
**two heap buffers** — screen coordinates (aspect-corrected) and MediaPipe world
coordinates — and calls the engine. What it draws is the **engine's** smoothed
skeleton (per-landmark One Euro), falling back to raw only when not tracking: the
screen shows what the engine believes. Drawing is **depth-coded**: far segments are
painted first, thin and faded; near ones land on top. A segmentation-mask
**silhouette** plus optional face-mesh and hand-skeleton layers (separate vendored
models) are purely visual — they feed nothing into coaching. **Timed acts** (moves
the engine cannot yet judge) deliberately bypass the engine: the camera stays on,
JS keeps a countdown, and nothing is counted or scored.

### 5. Product pages

`coach.html` (the trainer), `moves.html` (188-move library with hearts),
`my-program.html`/`my-moves.html` (programs, residency calendar), plus the
directory. Accounts are Supabase (RLS-guarded); only workout **numbers** sync —
never video, which the architecture makes impossible rather than merely promised.

## Measurement infrastructure

The rule since the precision phases: **no tuning without a ruler.**

- `engine/bench.sh` compiles and runs `engine/bench.cpp`, a synthetic squat world
  where the true knee angle is *known* — every wobble we measure is noise we added.
  Modes: `synth` (raw / EMA / One Euro race), `synthcal` (same, calibration on),
  `sweep` (One Euro parameter grid search), `bones` (bone-length variance with and
  without the lock), `twoperson` (stranger-in-frame scenarios), `clip <file.ggclip>`
  (metrics on a real recorded clip).
- Metrics: hold jitter (deg), motion RMSE after alignment (deg), lag (ms, best
  alignment shift), rep accuracy, dropouts, per-frame bone-length variance (%) —
  the "joint slide" number.
- `coach.html?rec=1` enables a hidden recorder that captures exactly the landmark
  stream the engine sees and downloads it as a `.ggclip` for offline evaluation.
- Measured results (same seed, same noise): bad-light hold jitter 5.01° raw →
  2.82° EMA → 2.32° One Euro, lag unchanged at 33 ms; with bone lock on, bad-light
  RMSE 3.54° → 2.70° and jitter 2.32° → 2.14°; bone-length variance 1.3–5.7% raw →
  0.00% locked in all three noise scenarios; two-person benchmark: naive path spent
  360 frames coaching the wrong body and lost reps (6/8), engine pick: 0 wrong
  frames, 8/8; stranger-alone window: naive 420 frames coaching them, hard lock 0.
- 112 native tests green at last count (`engine/test.sh`, plain clang++, no browser).

## Design decisions and why

- **Why filter in angle space, not landmark space.** The coaching signal *is* the
  joint angle — phase, depth, reps all derive from it. Filtering the thing you
  measure keeps one filter state per tracked quantity and lets the bench score it
  directly against known ground truth. (Landmarks get their own light per-point
  smoothing, but only for drawing.)
- **Why direction-from-detector, length-from-lock.** The detector is good at *where
  a limb points* and noisy about *how long it is* — yet bone length is a physical
  constant of the user. So calibration measures it once in metric space and the rig
  re-fits every frame to it. That is why variance drops to 0.00% and why angle
  metrics improve rather than degrade.
- **Why the veto uses the worst ratio, not the mean.** Averaging lets a stranger's
  short legs hide behind normal-looking arms. One sufficiently wrong bone is enough
  evidence that this is not the calibrated body.
- **Why the sweep has a lag penalty.** The first sweep quietly optimized calm by
  buying it with ~100 ms of lag — exactly the earlier "not responsive" complaint.
  Lag now costs points in the sweep score; calm may not be purchased with delay.
- **Why timed acts exist.** The engine has no hold/timed judgment capability yet.
  Rather than pretend (fake counts, invented scores), those moves get an honest
  camera-on timer with no coaching claims. An engine that stays silent when unsure
  beats one that makes things up — the same principle behind the confidence gate,
  the dropped rep window on tracking loss, and view-aware form rules.

## Known limits

- No hold detection yet: plank / wall-sit style moves run as timed acts only.
- The pose model has no finger joints; the hand overlay is visual (a separate ~10 MB
  Hand Landmarker would be needed for real finger data — deliberately parked).
- Person lock and bone lock require calibration; without world (3D) data those
  frames are skipped rather than guessed.
- Detector is capped at 2 candidate poses by design (speed; two-person *coaching*
  was explicitly rejected as not-the-product).
- Real-clip golden recordings are never committed; the synthetic bench is the
  in-repo ground truth.

## Roadmap pointer

Planned, not built: the Phase 3 kinematic solver (the exercise-prior gate above is
its first brick) and a Phase 5 recorded-clip dataset for regression evaluation.
The long-term direction is the engine as a reusable body-motion motor with the
same core behind other movement domains.
