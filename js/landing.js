// landing.js — the hero panel.
//
// two modes in the SAME panel:
//   (1) demo: a POINT CLOUD figure (no lines, no skeleton) squatting. ~450 dots
//       spread across limb volume; the knee is lit lila with its live angle; the
//       rep counter counts THIS figure's completed cycles, so every number on
//       screen is real. this is what a visitor sees on arrival.
//   (2) live: press "open the camera" and the same panel loads the shared engine
//       (js/engine-core.js — mediapipe pose + our wasm motor), tracks the
//       visitor's OWN body as dots, counts their real squats. press again = stop,
//       the camera track is released, we drop silently back to the demo.
//
// nothing heavy loads on arrival. mediapipe + wasm download ONLY on first press.
// permission denied / model failed / no camera -> silent fallback to the demo,
// no red error, no message. reduced-motion -> a single static frame.
(function () {
  const cv = document.getElementById('rig');
  if (!cv) return;
  const ctx = cv.getContext('2d');
  const repsEl = document.getElementById('reps');
  const kneeEl = document.getElementById('knee');
  const plusEl = document.getElementById('plus');
  const camBtn = document.getElementById('heroCam');
  const video = document.getElementById('heroVideo');
  const panel = document.getElementById('heroPanel');
  const brandDot = document.querySelector('.brand i');
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const INK = '#191320', LILA = '#8E6BA8';

  // logical drawing size; the canvas backing store is resized to the panel.
  let CW = 520, CH = 560, DPR = 1;
  function resize() {
    const r = (panel || cv).getBoundingClientRect();
    CW = Math.max(240, Math.round(r.width));
    CH = Math.max(240, Math.round(r.height));
    DPR = Math.min(window.devicePixelRatio || 1, 2);
    cv.width = CW * DPR; cv.height = CH * DPR;
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  }
  resize();
  window.addEventListener('resize', resize);

  // ---- seeded rng so the demo scatter is stable frame to frame ----
  let s = 20260719;
  const rand = () => (s = (s * 16807) % 2147483647) / 2147483647;

  // ---- demo figure geometry (side view). d: 0 standing, 1 bottom of squat.
  // the figure's head-to-heel span IS ~84% of the drawing height. anatomical
  // proportions so head, torso, arm and the TWO legs each read separately, with
  // a real gap between the legs. ----
  const FIG = 0.84;
  function joints(d) {
    const H = CH, W = CW;
    const figH = H * FIG;                 // full head-to-heel height
    const cx = W * 0.5;
    const topY = H * (1 - FIG) / 2;       // crown of the head
    const footY = topY + figH;            // heel line
    // vertical anatomy as fractions of figH (standing): head .13, torso to hip
    // .40, thigh .26, shin .27 → sums to full height.
    const headR = figH * 0.065;           // head radius
    const headC = { x: cx, y: topY + headR };            // head centre
    const sho = { x: cx, y: topY + figH * 0.20 };        // shoulders
    // hip sinks and shifts back as the squat deepens; knees push forward.
    const hipStand = topY + figH * 0.52;
    const hip = { x: cx - figH * 0.10 * d, y: hipStand + figH * 0.14 * d };
    // torso leans forward into the squat
    const lean = 0.40 * d;
    const shoLean = { x: hip.x + (sho.y - hip.y) * Math.sin(-lean) * 0.0 + figH * 0.10 * Math.sin(lean),
                      y: hip.y - figH * 0.32 * Math.cos(lean) };
    const shoulder = { x: shoLean.x, y: shoLean.y };
    const head = { x: shoulder.x + figH * 0.05 * Math.sin(lean), y: shoulder.y - figH * 0.09 * Math.cos(lean) };
    // arm hangs, swings slightly forward at the bottom
    const aAng = -0.35 + (Math.PI / 2 + 0.3) * d;
    const elb = { x: shoulder.x + figH * 0.16 * Math.sin(aAng) * 0.6, y: shoulder.y + figH * 0.16 * Math.cos(aAng) };
    const wri = { x: elb.x + figH * 0.15 * (0.3 + 0.6 * d), y: elb.y + figH * 0.15 * (1 - d) * 0.5 };
    // FRONT leg (nearer camera): knee pushes forward, ankle stays under.
    const spread = figH * 0.085;          // horizontal gap between the two legs
    const kneeF = { x: cx + spread * 0.6 + figH * 0.06 * d, y: hip.y + figH * 0.24 };
    const ankF = { x: cx + spread * 0.6, y: footY };
    // BACK leg: offset behind, its own knee + ankle, so a gap reads.
    const kneeB = { x: cx - spread * 0.6 + figH * 0.04 * d, y: hip.y + figH * 0.25 };
    const ankB = { x: cx - spread * 0.6, y: footY };
    const toe = { x: ankF.x + figH * 0.06, y: footY + figH * 0.005 };
    // knee = front knee (the tracked joint)
    return {
      head, headC, headR, sho: shoulder, hip, elb, wri, toe,
      knee: kneeF, ankle: ankF, hip2: { x: hip.x - spread * 0.5, y: hip.y },
      knee2: kneeB, ankle2: ankB, figH,
    };
  }

  // dot budget: 450 total, allocated in PROPORTION to each segment's length so a
  // long limb gets more dots and nothing clumps. widths (spread as a fraction of
  // figH) give each limb its volume; the two legs stay separate.
  const SEG_DEFS = [
    ['hip', 'sho', 0.052, 2.6],   // torso — widest
    ['sho', 'elb', 0.020, 1.0],   // upper arm
    ['elb', 'wri', 0.018, 0.9],   // forearm
    ['hip', 'knee', 0.034, 1.5],  // front thigh
    ['knee', 'ankle', 0.026, 1.5],// front shin
    ['hip2', 'knee2', 0.034, 1.4],// back thigh
    ['knee2', 'ankle2', 0.026, 1.4],// back shin
    ['ankle', 'toe', 0.022, 0.5], // foot
  ];
  const HEAD_WEIGHT = 1.4, HEAD_SPREAD = 0.06;
  const TOTAL_DOTS = 450;
  const cloud = [];
  // build once at a reference figure to measure segment lengths for the split
  (function buildCloud() {
    const ref = joints(0);
    let totalW = HEAD_WEIGHT;
    const segLens = SEG_DEFS.map(([a, b, spread, weight]) => {
      const L = Math.hypot(ref[b].x - ref[a].x, ref[b].y - ref[a].y) * weight;
      totalW += L / ref.figH;
      return L / ref.figH;
    });
    const headN = Math.round(TOTAL_DOTS * (HEAD_WEIGHT / totalW));
    for (let i = 0; i < headN; i++) {
      cloud.push({ kind: 'head', ang: rand() * Math.PI * 2, rr: Math.sqrt(rand()),
        r: 1 + rand(), aBase: 0.4 + rand() * 0.5, ph: rand() * Math.PI * 2 });
    }
    SEG_DEFS.forEach(([a, b, spread], i) => {
      const n = Math.round(TOTAL_DOTS * (segLens[i] / totalW));
      for (let j = 0; j < n; j++) {
        cloud.push({ kind: 'seg', a, b, spread,
          t: rand(), off: (rand() - 0.5) * 2, along: (rand() - 0.5) * 0.06,
          r: 1 + rand(), aBase: 0.4 + rand() * 0.5, ph: rand() * Math.PI * 2 });
      }
    });
  })();

  const lerp = (p, q, t) => ({ x: p.x + (q.x - p.x) * t, y: p.y + (q.y - p.y) * t });
  function normal(p, q) { const dx = q.x - p.x, dy = q.y - p.y, L = Math.hypot(dx, dy) || 1; return { x: -dy / L, y: dx / L }; }
  function angleAt(b, a, c) {
    const v1 = { x: a.x - b.x, y: a.y - b.y }, v2 = { x: c.x - b.x, y: c.y - b.y };
    const den = Math.hypot(v1.x, v1.y) * Math.hypot(v2.x, v2.y) || 1;
    return Math.round(Math.acos(Math.max(-1, Math.min(1, (v1.x * v2.x + v1.y * v2.y) / den))) * 180 / Math.PI);
  }
  const smoothstep = (t) => t * t * (3 - 2 * t);

  // ---- shared counter ui ----
  let reps = 0;
  function onRep(ts) {
    ringT = ts;
    if (plusEl) { plusEl.classList.remove('fly'); void plusEl.offsetWidth; plusEl.classList.add('fly'); }
    if (brandDot) { brandDot.classList.remove('hop'); void brandDot.offsetWidth; brandDot.classList.add('hop'); }
  }
  function setReps(n) {
    if (!repsEl) return;
    if (repsEl.firstChild && repsEl.firstChild.nodeType === 3) repsEl.firstChild.textContent = n;
    else repsEl.insertBefore(document.createTextNode(n), repsEl.firstChild);
  }
  function setKnee(a) { if (kneeEl) kneeEl.textContent = a; }

  // ---- drawing helpers ----
  let ringT = -1;
  // the floor line sits AT the ankle/heel, so feet touch the ground dots.
  function floorDots(J) {
    ctx.fillStyle = 'rgba(142,107,168,.18)';
    const y = (J ? J.ankle.y : CH * 0.92) + 2;
    for (let x = CW * 0.14; x <= CW * 0.86; x += CW * 0.06) {
      ctx.beginPath(); ctx.arc(x, Math.min(y, CH - 3), 1.4, 0, Math.PI * 2); ctx.fill();
    }
  }
  // draw a cloud from a joints() map (demo) with a lit knee + angle.
  function drawCloudFig(J, ts, kneeAngle) {
    ctx.clearRect(0, 0, CW, CH);
    floorDots(J);
    for (const dt of cloud) {
      let base;
      if (dt.kind === 'head') {
        const rr = J.headR * (0.6 + dt.rr * 0.9);
        base = { x: J.headC.x + Math.cos(dt.ang) * rr, y: J.headC.y + Math.sin(dt.ang) * rr };
      } else {
        const tt = Math.min(1, Math.max(0, dt.t + dt.along));
        const mid = lerp(J[dt.a], J[dt.b], tt), nrm = normal(J[dt.a], J[dt.b]);
        const w = dt.spread * J.figH;
        base = { x: mid.x + nrm.x * w * dt.off, y: mid.y + nrm.y * w * dt.off };
      }
      const jit = reduce ? 0 : 1;
      const vx = Math.sin(ts / 900 + dt.ph) * 0.8 * jit, vy = Math.cos(ts / 1050 + dt.ph) * 0.8 * jit;
      ctx.globalAlpha = dt.aBase;
      ctx.fillStyle = INK;
      ctx.beginPath(); ctx.arc(base.x + vx, base.y + vy, Math.min(2, dt.r), 0, Math.PI * 2); ctx.fill();
    }
    litKnee(J.knee, ts, kneeAngle);
    if (ringT >= 0 && ts - ringT < 700) {
      const k = (ts - ringT) / 700;
      ctx.beginPath(); ctx.arc(J.hip.x, J.hip.y, 20 + 70 * k, 0, Math.PI * 2);
      ctx.strokeStyle = 'rgba(142,107,168,' + (0.5 * (1 - k)) + ')'; ctx.lineWidth = 2; ctx.stroke();
    }
    ctx.globalAlpha = 1;
  }
  // the tracked joint: lila filled dot + breathing ring + live angle. no bone line.
  function litKnee(knee, ts, angle) {
    ctx.globalAlpha = 1;
    ctx.fillStyle = LILA;
    ctx.beginPath(); ctx.arc(knee.x, knee.y, 4.5, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = LILA; ctx.globalAlpha = 0.55; ctx.lineWidth = 1;
    const br = reduce ? 12 : 12 + 2 * Math.sin(ts / 480);
    ctx.beginPath(); ctx.arc(knee.x, knee.y, br, 0, Math.PI * 2); ctx.stroke();
    ctx.globalAlpha = 1;
    if (angle != null) {
      ctx.fillStyle = LILA;
      ctx.font = '600 13px "JetBrains Mono", ui-monospace, monospace';
      ctx.fillText(angle + '°', knee.x + 18, knee.y + 4);
    }
  }

  // draw the visitor's OWN landmarks as the same dot language (live mode).
  // lm = array of {x,y} in 0..1. mirror to match the mirrored video.
  function drawLiveCloud(lm, ts, kneeAngle, kneePt) {
    ctx.clearRect(0, 0, CW, CH);
    for (let i = 0; i < lm.length; i++) {
      const p = lm[i]; if (!p || (p.visibility != null && p.visibility < 0.3)) continue;
      const x = (1 - p.x) * CW, y = p.y * CH;
      ctx.globalAlpha = 0.5 + 0.4 * (p.visibility == null ? 1 : p.visibility);
      ctx.fillStyle = INK;
      ctx.beginPath(); ctx.arc(x, y, 2, 0, Math.PI * 2); ctx.fill();
    }
    if (kneePt) litKnee({ x: (1 - kneePt.x) * CW, y: kneePt.y * CH }, ts, kneeAngle);
    ctx.globalAlpha = 1;
  }

  // ---- demo loop ----
  const CYCLE = 5200;
  let t0 = null, demoRAF = 0, mode = 'demo';
  function demoFrame(ts) {
    if (mode !== 'demo') return;
    if (t0 === null) t0 = ts;
    const ph = ((ts - t0) % CYCLE) / CYCLE;
    const tri = ph < 0.5 ? ph * 2 : (1 - ph) * 2;
    const d = smoothstep(tri);
    // motor's own rule: a rep closes after going deep (d>0.86) then back up (d<0.12)
    if (d > 0.86) wasDown = true;
    if (wasDown && d < 0.12) { wasDown = false; reps++; setReps(reps); onRep(ts); }
    const J = joints(d);
    const ka = angleAt(J.knee, J.hip, J.ankle);
    setKnee(ka);
    drawCloudFig(J, ts, ka);
    demoRAF = requestAnimationFrame(demoFrame);
  }
  let wasDown = false;
  function startDemo() {
    mode = 'demo';
    if (reduce) { const J = joints(0.62); drawCloudFig(J, 0, angleAt(J.knee, J.hip, J.ankle)); setKnee(angleAt(J.knee, J.hip, J.ankle)); return; }
    cancelAnimationFrame(demoRAF);
    t0 = null;
    demoRAF = requestAnimationFrame(demoFrame);
  }

  // ================= live camera mode (lazy, silent-fallback) =================
  let live = null;   // { pose, mod, engine, bufPtr, worldBufPtr, stream, raf, core }
  let loadingCam = false;

  function setBtn(label) { if (camBtn) camBtn.textContent = label; }

  async function startCamera() {
    if (loadingCam) return;
    loadingCam = true;
    setBtn('starting the camera...');
    let stream = null;
    try {
      stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user', width: 640, height: 480 }, audio: false });
    } catch (e) {
      loadingCam = false; setBtn('open the camera'); return;   // denied -> silent
    }
    try {
      const core = await import('./engine-core.js');
      const { pose } = await core.loadPoseLandmarker({ numPoses: 1, wantSeg: false });
      const { mod, Engine } = await core.loadMotor();
      const engine = new Engine('squat');
      if (typeof engine.setCalibration === 'function') engine.setCalibration(true);
      const bufPtr = mod._malloc(2 * core.FLOATS * 4);
      const worldBufPtr = mod._malloc(2 * core.FLOATS * 4);

      video.srcObject = stream;
      video.hidden = false;
      await video.play();

      live = { pose, mod, engine, bufPtr, worldBufPtr, stream, core, raf: 0, lastT: -1 };
      mode = 'live';
      cancelAnimationFrame(demoRAF);
      reps = 0; setReps(0);
      setBtn('stop');
      loadingCam = false;
      liveFrame();
    } catch (e) {
      console.warn('hero camera engine failed, staying in demo:', e);
      if (stream) stream.getTracks().forEach((t) => t.stop());
      video.hidden = true; video.srcObject = null;
      live = null; loadingCam = false; setBtn('open the camera');
      startDemo();   // silent fallback
    }
  }

  function liveFrame() {
    if (!live || mode !== 'live') return;
    const now = performance.now();
    if (video.currentTime !== live.lastT && video.videoWidth) {
      live.lastT = video.currentTime;
      let result = null;
      try { result = live.pose.detectForVideo(video, now); } catch (e) { result = null; }
      if (result && result.landmarks && result.landmarks.length) {
        const aspect = (video.videoWidth || 4) / (video.videoHeight || 3);
        const lm = result.landmarks[0];
        const wl = (result.worldLandmarks && result.worldLandmarks[0]) || lm;
        live.core.writePosesToHeap(live.mod, live.bufPtr, [lm], aspect);
        live.core.writePosesToHeap(live.mod, live.worldBufPtr, [wl], aspect);
        let r = null;
        try { r = live.engine.updateMultiPtr(live.bufPtr, live.core.FLOATS, 1, live.worldBufPtr, live.core.FLOATS, 1, now); } catch (e) { r = null; }
        // knee angle from the visitor's own landmarks (25/27 = left knee/ankle, 23 = hip)
        const hip = lm[23], knee = lm[25], ankle = lm[27];
        let ka = null;
        if (hip && knee && ankle) ka = angleAt({ x: knee.x * aspect, y: knee.y }, { x: hip.x * aspect, y: hip.y }, { x: ankle.x * aspect, y: ankle.y });
        if (ka != null) setKnee(ka);
        if (r && typeof r.reps === 'number' && r.reps !== reps) {
          const up = r.reps > reps; reps = r.reps; setReps(reps); if (up) onRep(now);
        }
        drawLiveCloud(lm, now, ka, knee);
      }
    }
    live.raf = requestAnimationFrame(liveFrame);
  }

  function stopCamera() {
    if (live) {
      cancelAnimationFrame(live.raf);
      if (live.stream) live.stream.getTracks().forEach((t) => t.stop());
      try { live.mod._free(live.bufPtr); live.mod._free(live.worldBufPtr); } catch (e) {}
      try { if (live.engine && live.engine.delete) live.engine.delete(); } catch (e) {}
      live = null;
    }
    video.hidden = true; video.srcObject = null;
    reps = 0; setReps(0);
    setBtn('open the camera');
    startDemo();
  }

  if (camBtn) {
    camBtn.addEventListener('click', () => {
      if (mode === 'live') stopCamera();
      else if (!loadingCam) startCamera();
    });
  }

  // release the camera if the tab is hidden or the user leaves
  document.addEventListener('visibilitychange', () => { if (document.hidden && mode === 'live') stopCamera(); });
  window.addEventListener('pagehide', () => { if (mode === 'live') stopCamera(); });

  startDemo();
})();
