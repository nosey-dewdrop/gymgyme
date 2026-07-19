// tools/auto-label.mjs — headless pre-labeling (YOL-HARITASI: fetching AND
// pre-labeling clips is the agent's job; only ambiguous ones go to the human).
//
// for each corpus/<move>/*.mp4 without a .labels.json, this drives a headless
// chromium that runs the SAME mediapipe pose + wasm motor the site uses
// (via js/engine-core.js), extracts the landmark series, and records the
// motor's rep prediction. it writes:
//   <clip>.landmarks.json   (the extracted pose series — feeds the regression)
//   <clip>.labels.json      { move, reps, enginePredicted, confidence, review }
// high-confidence clips are accepted (review:false); low-confidence ones are
// flagged review:true for the human to confirm in tools/labeler.html.
//
// run:  node tools/auto-label.mjs [move]
// needs: npx playwright install chromium (done once).

import { chromium } from 'playwright';
import { createServer } from 'http';
import { readFileSync, existsSync, writeFileSync, readdirSync, statSync } from 'fs';
import { join, dirname, extname } from 'path';
import { fileURLToPath } from 'url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const CORPUS = join(ROOT, 'corpus');
const ENGINE = join(ROOT, 'engine');
const onlyMove = process.argv[2] || null;

// minimal static server rooted at the repo so ../vendor and ../engine resolve.
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.wasm': 'application/wasm', '.json': 'application/json', '.task': 'application/octet-stream', '.mp4': 'video/mp4', '.css': 'text/css' };
function serve() {
  return new Promise((resolve) => {
    const srv = createServer((req, res) => {
      try {
        const p = join(ROOT, decodeURIComponent(req.url.split('?')[0]));
        if (!existsSync(p) || statSync(p).isDirectory()) { res.writeHead(404); return res.end(); }
        res.writeHead(200, { 'Content-Type': MIME[extname(p)] || 'application/octet-stream', 'Cross-Origin-Opener-Policy': 'same-origin', 'Cross-Origin-Embedder-Policy': 'credentialless' });
        res.end(readFileSync(p));
      } catch { res.writeHead(500); res.end(); }
    });
    srv.listen(0, '127.0.0.1', () => resolve(srv));
  });
}

// the browser does ONLY landmark extraction (mediapipe). the motor's rep count
// is computed on the node side with motor.node.mjs — this avoids a TextDecoder/
// resizable-ArrayBuffer incompatibility between the web motor build and headless
// chromium, and keeps a single motor of record (the node target) for labels.
const PAGE = `<!doctype html><meta charset=utf8><body><video id=v muted playsinline></video><script type=module>
import { loadPoseLandmarker } from '/js/engine-core.js';
let pose;
window.__ready = (async () => { const p = await loadPoseLandmarker({numPoses:1,wantSeg:false}); pose=p.pose; return true; })();
// sample the clip by PLAYING it and grabbing a landmark set on each rendered
// frame (via requestVideoFrameCallback) — no per-frame seek, which hangs on
// long clips. we throttle to ~10 samples/sec, enough to count reps.
window.extractClip = async (url) => {
  await window.__ready;
  const v = document.getElementById('v'); v.src = url;
  await new Promise((r, rej) => { v.onloadeddata = r; v.onerror = () => rej(new Error('video load error')); setTimeout(() => rej(new Error('video load timeout')), 20000); });
  const frames = []; const SAMPLE_MS = 100; let lastSample = -1;
  await new Promise((resolve) => {
    const done = () => { v.pause(); resolve(); };
    v.onended = done;
    const onFrame = (now, meta) => {
      const tms = (meta ? meta.mediaTime : v.currentTime) * 1000;
      if (tms - lastSample >= SAMPLE_MS) {
        lastSample = tms;
        let res = null; try { res = pose.detectForVideo(v, performance.now()); } catch (e) {}
        const lm = res && res.landmarks && res.landmarks[0];
        if (lm) frames.push(lm.map(p => ({ x: +p.x.toFixed(5), y: +p.y.toFixed(5), z: +(p.z || 0).toFixed(5), visibility: +(p.visibility ?? 1).toFixed(3) })));
      }
      if (!v.paused && !v.ended) { if (v.requestVideoFrameCallback) v.requestVideoFrameCallback(onFrame); }
      else done();
    };
    v.play().then(() => { if (v.requestVideoFrameCallback) v.requestVideoFrameCallback(onFrame); else { const iv = setInterval(() => { onFrame(0, null); if (v.paused || v.ended) clearInterval(iv); }, SAMPLE_MS); } })
      .catch(() => resolve());
    setTimeout(done, 40000);   // hard cap per clip
  });
  return { frames, fps: 10, w: v.videoWidth, h: v.videoHeight };
};
</script>`;

function clipsToDo() {
  const out = [];
  if (!existsSync(CORPUS)) return out;
  for (const move of readdirSync(CORPUS)) {
    if (onlyMove && move !== onlyMove) continue;
    const dir = join(CORPUS, move);
    if (!statSync(dir).isDirectory()) continue;
    for (const f of readdirSync(dir)) {
      if (!f.endsWith('.mp4')) continue;
      const base = f.replace('.mp4', '');
      if (existsSync(join(dir, base + '.labels.json'))) continue;   // already labelled
      out.push({ move, dir, base, file: f });
    }
  }
  return out;
}

async function main() {
  const todo = clipsToDo();
  if (!todo.length) { console.log('nothing to label (all clips already have labels).'); return; }
  const srv = await serve();
  const port = srv.address().port;
  const base = `http://127.0.0.1:${port}`;
  // write a temp page under tools/ so module imports of /js/engine-core.js
  // resolve against the served repo root. removed at the end.
  const tmpPage = join(ROOT, '_autopage.html');
  writeFileSync(tmpPage, PAGE);
  const browser = await chromium.launch({ args: ['--use-fake-ui-for-media-stream', '--autoplay-policy=no-user-gesture-required'] });
  const page = await browser.newPage();
  page.on('console', (m) => { if (m.type() === 'error') console.log('  [page]', m.text()); });
  await page.goto(base + '/_autopage.html');
  await page.waitForFunction(() => window.__ready !== undefined, { timeout: 60000 });
  await page.evaluate(async () => await window.__ready);

  // node-side motor of record
  const { default: createMotor } = await import(join(ENGINE, 'motor.node.mjs'));
  const motor = await createMotor();
  const moves = (motor.coachableMoves ? motor.coachableMoves() : []).map((x) => x.name);
  console.log('motor coachable moves:', moves.length);
  const LM = 33, FLOATS = LM * 4;

  function countReps(frames, moveId, w, h) {
    const engine = new motor.Engine(moveId);
    if (engine.setCalibration) engine.setCalibration(true);
    const buf = motor._malloc(2 * FLOATS * 4), wbuf = motor._malloc(2 * FLOATS * 4);
    const aspect = (w || 4) / (h || 3);
    let t = 0; const dt = 1000 / 10; let last = { reps: 0, confidence: 0 };
    for (const fr of frames) {
      const heap = motor.HEAPF32, b = buf >> 2, wb = wbuf >> 2;
      for (let i = 0; i < LM; i++) {
        const p = fr[i] || { x: 0, y: 0, z: 0, visibility: 0 };
        heap[b + i * 4] = p.x * aspect; heap[b + i * 4 + 1] = p.y; heap[b + i * 4 + 2] = p.z || 0; heap[b + i * 4 + 3] = p.visibility == null ? 1 : p.visibility;
        heap[wb + i * 4] = p.x * aspect; heap[wb + i * 4 + 1] = p.y; heap[wb + i * 4 + 2] = p.z || 0; heap[wb + i * 4 + 3] = p.visibility == null ? 1 : p.visibility;
      }
      try { last = engine.updateMultiPtr(buf, FLOATS, 1, wbuf, FLOATS, 1, t); } catch (e) {}
      t += dt;
    }
    motor._free(buf); motor._free(wbuf); if (engine.delete) engine.delete();
    return { reps: last.reps || 0, confidence: +(last.confidence || 0).toFixed(2) };
  }

  let done = 0, review = 0;
  const CONF_MIN = 0.55;
  for (const c of todo) {
    const moveId = moves.includes(c.move) ? c.move : (moves.find((m) => m.startsWith(c.move.split('-')[0])) || c.move.replace(/-/g, ''));
    const url = `${base}/corpus/${c.move}/${c.file}`;
    try {
      const ex = await page.evaluate(async (u) => window.extractClip(u), url);
      const r = countReps(ex.frames, moveId, ex.w, ex.h);
      const needsReview = r.confidence < CONF_MIN || ex.frames.length < 20;
      writeFileSync(join(c.dir, c.base + '.landmarks.json'), JSON.stringify({ fps: ex.fps, frames: ex.frames }));
      writeFileSync(join(c.dir, c.base + '.labels.json'), JSON.stringify({
        move: moveId, reps: r.reps, enginePredicted: r.reps, confidence: r.confidence,
        errors: [], review: needsReview, source: 'auto', labeledAt: '2026-07-19',
      }));
      done++; if (needsReview) review++;
      console.log(`  ${needsReview ? 'REVIEW' : 'ok    '} ${c.move}/${c.base}: ${r.reps} reps, conf ${r.confidence}, ${ex.frames.length} frames`);
    } catch (e) {
      console.log(`  fail  ${c.move}/${c.base}:`, e.message.split('\n')[0]);
    }
  }
  await browser.close(); srv.close();
  try { const { unlinkSync } = await import('fs'); unlinkSync(tmpPage); } catch {}
  console.log(`\n${done} clip(s) pre-labelled, ${review} flagged for human review (open tools/labeler.html to confirm).`);
}

main().catch((e) => { console.error(e); process.exit(1); });
