// golden-synth.mjs — a synthetic golden squat, so the regression gate can prove
// the engine counts even before the real corpus exists, AND so a broken engine
// turns the gate red (negative test). NOT a substitute for real clips: it only
// guards "the engine still counts a clean squat". real accuracy comes from the
// labelled corpus.
//
// builds N clean squat cycles as mediapipe-style normalized landmarks (33 pts),
// driving the knee angle from ~172° (standing) to ~90° (bottom) and back, then
// feeds them through the motor and checks the rep count.

const LM = 33, FLOATS = LM * 4;

// a minimal side-on skeleton: only the joints the squat spec reads move.
// coords in mediapipe's 0..1 image space (y grows downward).
function squatFrame(d) {
  // d: 0 standing, 1 bottom. hip drops and moves back, knee bends forward.
  const pts = new Array(LM).fill(0).map(() => ({ x: 0.5, y: 0.5, z: 0, visibility: 1 }));
  const ankleY = 0.92, ankleX = 0.5;
  const kneeX = 0.5 + 0.05 * d, kneeY = 0.72 - 0.02 * d;
  const hipX = 0.5 - 0.06 * d, hipY = 0.52 + 0.14 * d;
  const shoX = hipX + 0.03 * Math.sin(0.4 * d), shoY = hipY - 0.22 + 0.02 * d;
  const set = (i, x, y) => { pts[i] = { x, y, z: 0, visibility: 1 }; };
  // left + right mirrored to the same profile (side view)
  set(23, hipX, hipY); set(24, hipX, hipY);       // hips
  set(25, kneeX, kneeY); set(26, kneeX, kneeY);   // knees
  set(27, ankleX, ankleY); set(28, ankleX, ankleY); // ankles
  set(11, shoX, shoY); set(12, shoX, shoY);       // shoulders
  set(0, shoX, shoY - 0.08);                       // nose/head
  set(31, ankleX + 0.04, ankleY + 0.01); set(32, ankleX + 0.04, ankleY + 0.01); // foot index
  return pts;
}

function buildClip(nReps, fps = 30, framesPerRep = 40) {
  const frames = [];
  const smoothstep = (t) => t * t * (3 - 2 * t);
  // a few standing frames first so calibration settles
  for (let i = 0; i < 20; i++) frames.push(squatFrame(0));
  for (let r = 0; r < nReps; r++) {
    for (let f = 0; f < framesPerRep; f++) {
      const ph = f / framesPerRep;
      const tri = ph < 0.5 ? ph * 2 : (1 - ph) * 2;
      frames.push(squatFrame(smoothstep(tri)));
    }
  }
  for (let i = 0; i < 10; i++) frames.push(squatFrame(0));
  return { fps, frames };
}

export async function run(mod) {
  const N = 5;
  const clip = buildClip(N);
  const engine = new mod.Engine('squat');
  if (typeof engine.setCalibration === 'function') engine.setCalibration(true);
  const bufPtr = mod._malloc(2 * FLOATS * 4);
  const worldPtr = mod._malloc(2 * FLOATS * 4);
  let last = { reps: 0 };
  let t = 0; const dt = 1000 / clip.fps;
  for (const frame of clip.frames) {
    const heap = mod.HEAPF32, base = bufPtr >> 2, wbase = worldPtr >> 2;
    for (let i = 0; i < LM; i++) {
      const p = frame[i];
      heap[base + i * 4] = p.x; heap[base + i * 4 + 1] = p.y; heap[base + i * 4 + 2] = 0; heap[base + i * 4 + 3] = p.visibility;
      heap[wbase + i * 4] = p.x; heap[wbase + i * 4 + 1] = p.y; heap[wbase + i * 4 + 2] = 0; heap[wbase + i * 4 + 3] = p.visibility;
    }
    try { last = engine.updateMultiPtr(bufPtr, FLOATS, 1, worldPtr, FLOATS, 1, t); } catch (e) {}
    t += dt;
  }
  mod._free(bufPtr); mod._free(worldPtr);
  if (engine.delete) engine.delete();
  const got = last.reps || 0;
  // this is a LIVENESS + negative-test guard, not an accuracy measure. the
  // synthetic drive is idealized (real squat landmarks differ), so we don't
  // assert exact N — we assert the engine still counts a clean repeated squat
  // (>0 and not wildly over). a broken engine counts 0 (or nothing), turning
  // the gate red. real accuracy is measured on the labelled corpus, not here.
  const pass = got >= Math.ceil(N / 2) && got <= N + 1;
  return { pass, detail: `synthetic ${N} squats → engine counted ${got} (liveness: engine counts a clean squat)` };
}
