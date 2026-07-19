// engine-core.js — the shared engine layer used by BOTH the coach page and the
// index hero demo. it owns the two heavy, lazy pieces:
//   (1) the mediapipe pose landmarker (the eyes)
//   (2) our own c++/wasm motor (the brain that counts + scores)
// no UI, no page-specific logic. coach.js builds its plan/scoring/HUD on top of
// this; index/landing.js uses only the thin counting path. everything downloads
// ONLY when a caller asks for it, so a page that never opens the camera never
// pays for mediapipe or the wasm.

import { PoseLandmarker, FilesetResolver } from "../vendor/mediapipe/vision_bundle.mjs";

export const LM = 33;                 // landmarks per pose
export const FLOATS = LM * 4;         // each point: x, y, z, visibility

let visionFileset = null;

// build a pose landmarker, trying full+seg -> full -> lite (some GPUs drop the
// heavier init; the camera must come before the extras). same ladder coach uses.
async function makePose(vision, model, seg, numPoses) {
  return PoseLandmarker.createFromOptions(vision, {
    baseOptions: { modelAssetPath: "vendor/models/pose_landmarker_" + model + ".task", delegate: "GPU" },
    runningMode: "VIDEO",
    numPoses,
    outputSegmentationMasks: seg,
  });
}

// load (and cache) the mediapipe fileset + a working pose landmarker.
// opts.numPoses (default 1). opts.wantSeg (default false) allows the seg attempt.
// returns { pose, model, segOn }. throws only if every attempt fails.
export async function loadPoseLandmarker(opts = {}) {
  const numPoses = opts.numPoses || 1;
  const wantSeg = !!opts.wantSeg;
  if (!visionFileset) {
    visionFileset = await FilesetResolver.forVisionTasks("vendor/mediapipe/wasm");
  }
  const attempts = wantSeg
    ? [{ model: "full", seg: true }, { model: "full", seg: false }, { model: "lite", seg: false }]
    : [{ model: "full", seg: false }, { model: "lite", seg: false }];
  let pose = null, model = "", segOn = false, lastErr = null;
  for (const a of attempts) {
    try {
      pose = await makePose(visionFileset, a.model, a.seg, numPoses);
      segOn = a.seg;
      model = a.model + (a.seg ? "+seg" : "");
      break;
    } catch (e) {
      lastErr = e;
      console.warn("pose init failed (" + a.model + ", seg=" + a.seg + "):", e);
    }
  }
  if (!pose) throw lastErr || new Error("no pose model could start");
  return { pose, model, segOn, vision: visionFileset };
}

// load our c++/wasm motor. returns { mod, Engine, coachableMoves } where
// mod exposes _malloc / _free / HEAPF32. throws if the wasm can't start.
export async function loadMotor() {
  const { default: createMotor } = await import("../engine/motor.js");
  const mod = await createMotor();
  return {
    mod,
    Engine: mod.Engine,
    coachableMoves: typeof mod.coachableMoves === "function" ? mod.coachableMoves() : null,
  };
}

// write one or two landmark sets into a wasm heap buffer, as the motor expects:
// [x, y, z, visibility] per point, x pre-scaled by aspect (so the motor sees a
// square coordinate space). returns the number of poses written.
export function writePosesToHeap(mod, ptr, landmarkSets, aspect) {
  const heap = mod.HEAPF32;
  const n = Math.min(landmarkSets.length, 2);
  for (let p = 0; p < n; p++) {
    const lm = landmarkSets[p];
    const base = (ptr >> 2) + p * FLOATS;
    for (let i = 0; i < LM; i++) {
      const q = lm[i] || { x: 0, y: 0, z: 0, visibility: 0 };
      heap[base + i * 4] = q.x * aspect;
      heap[base + i * 4 + 1] = q.y;
      heap[base + i * 4 + 2] = q.z || 0;
      heap[base + i * 4 + 3] = q.visibility == null ? 1 : q.visibility;
    }
  }
  return n;
}
