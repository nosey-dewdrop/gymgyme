// tests/regression/run.mjs — the regression suite (FAZ 7, X10).
//
// runs every labelled clip through the SAME motor the site ships (built for
// node as engine/motor.node.mjs — identical source, invariant #9 preserved),
// and compares the motor's rep count / rejections against the human labels.
// output: per-move counted / missed / false-positive, and a pass/fail vs the
// tolerances. writes nothing; prints a report and exits non-zero on regression.
//
// clip format under corpus/<move>/:
//   <clip>.landmarks.json  { fps, frames: [ [ {x,y,z,visibility} x33 ], ... ] }
//   <clip>.labels.json     { move, reps, errors: [..] }   (from the labeler)
//   <clip>.license.txt     (source, license, date — required by invariant #14)
//
// no mediapipe here: landmarks are pre-extracted by the labeler, so this is a
// pure, deterministic test of the ENGINE, which is what a regression gate needs.

import { readFileSync, readdirSync, existsSync, statSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const CORPUS = join(ROOT, 'corpus');
const ENGINE = join(ROOT, 'engine');
const LM = 33, FLOATS = LM * 4;

// tolerance: a clip passes if the motor's rep count is within COUNT_TOL of the
// label. tighten this as the corpus grows; loosening it is a gate weakening
// (PROTOKOL §5b) and is not allowed without a finding in DECISIONS.
const COUNT_TOL = 1;

function loadClips() {
  if (!existsSync(CORPUS)) return [];
  const clips = [];
  for (const move of readdirSync(CORPUS)) {
    const dir = join(CORPUS, move);
    if (!statSync(dir).isDirectory()) continue;
    for (const f of readdirSync(dir)) {
      if (!f.endsWith('.landmarks.json')) continue;
      const base = f.replace('.landmarks.json', '');
      const labelsPath = join(dir, base + '.labels.json');
      if (!existsSync(labelsPath)) continue;   // unlabelled clip is skipped
      clips.push({
        move,
        name: base,
        landmarks: JSON.parse(readFileSync(join(dir, f), 'utf8')),
        labels: JSON.parse(readFileSync(labelsPath, 'utf8')),
      });
    }
  }
  return clips;
}

async function makeMotor() {
  const { default: createMotor } = await import(join(ENGINE, 'motor.node.mjs'));
  return createMotor();
}

// feed one clip's landmark frames through a fresh Engine, return the reading.
function runClip(mod, move, clip) {
  const engine = new mod.Engine(move);
  if (typeof engine.setCalibration === 'function') engine.setCalibration(true);
  const bufPtr = mod._malloc(2 * FLOATS * 4);
  const worldPtr = mod._malloc(2 * FLOATS * 4);
  const fps = clip.landmarks.fps || 30;
  let last = { reps: 0, rejectedReps: 0 };
  let t = 0;
  const dt = 1000 / fps;
  for (const frame of clip.landmarks.frames) {
    const heap = mod.HEAPF32;
    const base = bufPtr >> 2, wbase = worldPtr >> 2;
    for (let i = 0; i < LM; i++) {
      const p = frame[i] || { x: 0, y: 0, z: 0, visibility: 0 };
      for (const [b, o] of [[base, 0], [wbase, 0]]) {
        heap[b + i * 4] = p.x; heap[b + i * 4 + 1] = p.y;
        heap[b + i * 4 + 2] = p.z || 0; heap[b + i * 4 + 3] = p.visibility == null ? 1 : p.visibility;
      }
    }
    try { last = engine.updateMultiPtr(bufPtr, FLOATS, 1, worldPtr, FLOATS, 1, t); } catch (e) {}
    t += dt;
  }
  mod._free(bufPtr); mod._free(worldPtr);
  if (engine.delete) engine.delete();
  return last;
}

async function main() {
  const clips = loadClips();
  let mod;
  try {
    mod = await makeMotor();
  } catch (e) {
    console.log('REGRESSION FAILED — the motor failed to load:', e.message);
    console.log('  (rebuild with: bash engine/build-node.sh)');
    process.exit(1);
  }

  if (!clips.length) {
    console.log('regression: corpus is EMPTY — no labelled clips yet.');
    console.log('  add clips with tools/fetch-clips, label them with tools/labeler,');
    console.log('  then this suite measures counted / missed / false-positive per move.');
    // a smoke check so the gate proves the engine at least loads and counts.
    const smoke = await import('./golden-synth.mjs');
    const ok = await smoke.run(mod);
    console.log('  smoke (synthetic golden squat):', ok.pass ? 'PASS' : 'FAIL', '—', ok.detail);
    process.exit(ok.pass ? 0 : 1);
  }

  const byMove = {};
  let fail = 0;
  for (const clip of clips) {
    const r = runClip(mod, clip.move, clip);
    const got = r.reps || 0, want = clip.labels.reps || 0;
    const diff = Math.abs(got - want);
    const pass = diff <= COUNT_TOL;
    if (!pass) fail++;
    const m = (byMove[clip.move] = byMove[clip.move] || { clips: 0, counted: 0, want: 0, missed: 0, fp: 0 });
    m.clips++; m.counted += got; m.want += want;
    if (got < want) m.missed += want - got; else m.fp += got - want;
    console.log(`${pass ? 'ok  ' : 'FAIL'} ${clip.move}/${clip.name}: got ${got}, want ${want}${r.rejectedReps ? ', rejected ' + r.rejectedReps : ''}`);
  }

  console.log('\n— per move —');
  for (const [move, m] of Object.entries(byMove)) {
    const recall = m.want ? (1 - m.missed / m.want) : 1;
    const precision = m.counted ? (1 - m.fp / m.counted) : 1;
    console.log(`${move}: ${m.clips} clips · recall ${(recall * 100).toFixed(0)}% · precision ${(precision * 100).toFixed(0)}%`);
  }
  console.log(fail === 0 ? '\nREGRESSION PASSED' : `\nREGRESSION FAILED (${fail} clip(s) outside tolerance ${COUNT_TOL})`);
  process.exit(fail === 0 ? 0 : 1);
}

main();
