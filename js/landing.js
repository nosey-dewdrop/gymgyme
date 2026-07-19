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

  // ---- demo figure geometry (side view), built limb by limb from joint
  // positions so head→shoulder→hip→knee→ankle reads as a clear side profile,
  // with a neck joining the head to the torso and the two legs kept apart.
  // the figure cycles through five moves; poseFor(move,d) returns the joints for
  // that move at phase d (0 = start/top, 1 = bottom/extended). ----
  const FIG = 0.84;
  // limb lengths as fractions of figure height
  const L = { neck: 0.05, torso: 0.30, upperArm: 0.15, foreArm: 0.14, thigh: 0.24, shin: 0.24, foot: 0.07 };
  // a joints frame from a few driving angles (radians, side view, x+ = forward)
  function frame(o) {
    const figH = CH * FIG, cx = CW * 0.5;
    const spread = figH * 0.09;                    // gap between the two legs
    // anchor: hips. torso rises from hips at torsoAng; head above shoulders.
    const hip = { x: cx + (o.hipX || 0) * figH, y: CH * (1 - FIG) / 2 + figH * (o.hipY != null ? o.hipY : 0.52) };
    const up = (len, ang) => ({ dx: Math.sin(ang) * len * figH, dy: -Math.cos(ang) * len * figH });
    const dn = (len, ang) => ({ dx: Math.sin(ang) * len * figH, dy: Math.cos(ang) * len * figH });
    let d1 = up(L.torso, o.torso);
    const sho = { x: hip.x + d1.dx, y: hip.y + d1.dy };
    let dn1 = up(L.neck, o.torso + o.neck);
    const neck = { x: sho.x + dn1.dx * 0.5, y: sho.y + dn1.dy * 0.5 };
    const headC = { x: sho.x + dn1.dx, y: sho.y + dn1.dy - figH * 0.045 };
    const headR = figH * 0.062;
    // arm: shoulder -> elbow -> wrist
    let a1 = dn(L.upperArm, o.arm);
    const elb = { x: sho.x + a1.dx, y: sho.y + a1.dy };
    let a2 = dn(L.foreArm, o.arm + o.foreArm);
    const wri = { x: elb.x + a2.dx, y: elb.y + a2.dy };
    // FRONT leg (tracked side): hip -> knee -> ankle
    const hipF = { x: hip.x + spread * 0.5, y: hip.y };
    let l1 = dn(L.thigh, o.thighF);
    const kneeF = { x: hipF.x + l1.dx, y: hipF.y + l1.dy };
    let l2 = dn(L.shin, o.thighF + o.shinF);
    const ankF = { x: kneeF.x + l2.dx, y: kneeF.y + l2.dy };
    const toe = { x: ankF.x + L.foot * figH, y: ankF.y + figH * 0.005 };
    // BACK leg
    const hipB = { x: hip.x - spread * 0.5, y: hip.y };
    let b1 = dn(L.thigh, o.thighB);
    const kneeB = { x: hipB.x + b1.dx, y: hipB.y + b1.dy };
    let b2 = dn(L.shin, o.thighB + o.shinB);
    const ankB = { x: kneeB.x + b2.dx, y: kneeB.y + b2.dy };
    return { headC, headR, neck, sho, hip: hipF, hip2: hipB, elb, wri,
             knee: kneeF, ankle: ankF, knee2: kneeB, ankle2: ankB, toe, figH };
  }
  const lrp = (a, b, t) => a + (b - a) * t;
  // the five moves. each maps phase d (0..1) to the driving angles for frame().
  // 'joint' = which joint the engine tracks for this move.
  const MOVES = {
    squat: { joint: 'knee', label: 'squat', pose: (d) => ({
      hipY: lrp(0.42, 0.60, d), hipX: lrp(0, -0.05, d),
      torso: lrp(0.02, 0.5, d), neck: -0.15, arm: lrp(0.1, 0.9, d), foreArm: 0.2,
      thighF: lrp(0.05, 0.95, d), shinF: lrp(-0.05, -1.5, d),
      thighB: lrp(-0.05, 0.85, d), shinB: lrp(0.05, -1.4, d) }) },
    plank: { joint: 'hip', label: 'plank', pose: (d) => ({
      hipY: 0.70, hipX: 0.0,
      torso: lrp(1.35, 1.45, d), neck: 0.1, arm: lrp(2.4, 2.5, d), foreArm: 0.7,
      thighF: lrp(1.65, 1.7, d), shinF: 0.05, thighB: 1.6, shinB: 0.05 }) },
    bridge: { joint: 'hip', label: 'glute bridge', pose: (d) => ({
      hipY: lrp(0.72, 0.6, d), hipX: 0,
      torso: lrp(2.1, 2.4, d), neck: -0.3, arm: lrp(2.7, 2.8, d), foreArm: 0.1,
      thighF: lrp(1.1, 0.7, d), shinF: lrp(-1.9, -2.2, d),
      thighB: lrp(1.15, 0.75, d), shinB: lrp(-1.9, -2.2, d) }) },
    lunge: { joint: 'knee', label: 'lunge', pose: (d) => ({
      hipY: lrp(0.44, 0.58, d), hipX: 0.02,
      torso: 0.05, neck: -0.15, arm: 0.15, foreArm: 0.15,
      thighF: lrp(0.15, 0.75, d), shinF: lrp(-0.15, -0.85, d),
      thighB: lrp(-0.35, -0.75, d), shinB: lrp(-0.1, 0.9, d) }) },
    raise: { joint: 'shoulder', label: 'arm raise', pose: (d) => ({
      hipY: 0.42, hipX: 0,
      torso: 0.02, neck: -0.12, arm: lrp(0.15, 1.9, d), foreArm: 0.05,
      thighF: 0.06, shinF: -0.06, thighB: -0.06, shinB: 0.06 }) },
  };
  const SEQ = ['squat', 'plank', 'bridge', 'lunge', 'raise'];
  function poseFor(move, d) { return frame(MOVES[move].pose(d)); }
  // the tracked joint's live angle, per move.
  function trackedAngle(move, J) {
    if (move === 'squat' || move === 'lunge') return angleAt(J.knee, J.hip, J.ankle);
    if (move === 'plank' || move === 'bridge') return angleAt(J.hip, J.sho, J.knee);
    if (move === 'raise') return angleAt(J.sho, J.hip, J.elb);
    return angleAt(J.knee, J.hip, J.ankle);
  }
  function trackedPoint(move, J) {
    if (move === 'plank' || move === 'bridge') return J.hip;
    if (move === 'raise') return J.sho;
    return J.knee;
  }

  // dot budget: 450 total, allocated in PROPORTION to each segment's length so a
  // long limb gets more dots and nothing clumps. widths (spread as a fraction of
  // figH) give each limb its volume; the two legs stay separate.
  const SEG_DEFS = [
    ['sho', 'neck', 0.020, 1.2], // neck — joins head to torso
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
    const ref = poseFor('squat', 0);
    let totalW = HEAD_WEIGHT;
    const segLens = SEG_DEFS.map(([a, b, spread, weight]) => {
      const len = Math.hypot(ref[b].x - ref[a].x, ref[b].y - ref[a].y) * weight;
      totalW += len / ref.figH;
      return len / ref.figH;
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
  // the floor line sits at the lowest foot; its dots are PEACH (user-data hue).
  function floorDots(J) {
    ctx.fillStyle = 'rgba(232,180,160,.5)';
    const y = Math.max(J.ankle.y, J.ankle2.y) + 4;
    for (let x = CW * 0.12; x <= CW * 0.88; x += CW * 0.055) {
      ctx.beginPath(); ctx.arc(x, Math.min(y, CH - 3), 1.4, 0, Math.PI * 2); ctx.fill();
    }
  }
  // draw the point-cloud figure with the tracked joint lit lila + its angle.
  function drawCloudFig(J, ts, angle, trackPt) {
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
    litJoint(trackPt || J.knee, ts, angle);
    if (ringT >= 0 && ts - ringT < 700) {
      const k = (ts - ringT) / 700;
      const rp = trackPt || J.hip;
      ctx.beginPath(); ctx.arc(rp.x, rp.y, 20 + 70 * k, 0, Math.PI * 2);
      ctx.strokeStyle = 'rgba(142,107,168,' + (0.5 * (1 - k)) + ')'; ctx.lineWidth = 2; ctx.stroke();
    }
    ctx.globalAlpha = 1;
  }
  // the tracked joint: lila filled dot + breathing ring + live angle. no bone line.
  function litJoint(knee, ts, angle) {
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
    if (kneePt) litJoint({ x: (1 - kneePt.x) * CW, y: kneePt.y * CH }, ts, kneeAngle);
    ctx.globalAlpha = 1;
  }

  // small mono label naming the current move, drawn beside the figure.
  function moveLabel(name) {
    ctx.globalAlpha = 1;
    ctx.fillStyle = INK;
    ctx.font = '600 12px "JetBrains Mono", ui-monospace, monospace';
    ctx.fillText(name, CW * 0.08, CH * 0.14);
  }

  // ---- demo loop: cycle squat → plank → glute bridge → lunge → arm raise.
  // each move runs REPS_PER reps, then a smooth MORPH into the next pose.
  const CYCLE = 2600;                 // one rep, ms
  const REPS_PER = 3;                 // reps before switching move
  const MORPH = 900;                  // transition time, ms
  let t0 = null, demoRAF = 0, mode = 'demo';
  let seqI = 0, repsInMove = 0, wasDown = false;
  let morphFrom = null, morphStart = -1;   // during a transition
  function currentMove() { return SEQ[seqI]; }
  function nextMove() { return SEQ[(seqI + 1) % SEQ.length]; }

  function demoFrame(ts) {
    if (mode !== 'demo') return;
    if (t0 === null) t0 = ts;
    const move = currentMove();
    // are we mid-morph into the next move?
    if (morphStart >= 0) {
      const k = Math.min(1, (ts - morphStart) / MORPH);
      const nm = nextMove();
      const A = morphFrom, B = poseFor(nm, 0);
      const e = smoothstep(k);
      const J = morphJoints(A, B, e);
      drawCloudFig(J, ts, null, trackedPoint(nm, J));
      moveLabel(MOVES[nm].label);
      if (k >= 1) { seqI = (seqI + 1) % SEQ.length; repsInMove = 0; wasDown = false; morphStart = -1; t0 = ts; }
      demoRAF = requestAnimationFrame(demoFrame);
      return;
    }
    const ph = ((ts - t0) % CYCLE) / CYCLE;
    const tri = ph < 0.5 ? ph * 2 : (1 - ph) * 2;
    const d = smoothstep(tri);
    if (d > 0.86) wasDown = true;
    if (wasDown && d < 0.12) {
      wasDown = false; reps++; setReps(reps); onRep(ts); repsInMove++;
      if (repsInMove >= REPS_PER) { morphFrom = poseFor(move, 0); morphStart = ts; }
    }
    const J = poseFor(move, d);
    const ang = trackedAngle(move, J);
    setKnee(ang);
    drawCloudFig(J, ts, ang, trackedPoint(move, J));
    moveLabel(MOVES[move].label);
    demoRAF = requestAnimationFrame(demoFrame);
  }
  // blend two joints frames (same keys) for a smooth pose-to-pose transition.
  function morphJoints(A, B, t) {
    const out = {};
    for (const k in A) {
      if (typeof A[k] === 'number') out[k] = lrp(A[k], B[k], t);
      else if (A[k] && A[k].x != null) out[k] = { x: lrp(A[k].x, B[k].x, t), y: lrp(A[k].y, B[k].y, t) };
      else out[k] = A[k];
    }
    return out;
  }
  function startDemo() {
    mode = 'demo';
    if (reduce) {
      const J = poseFor('squat', 0.6); const ang = trackedAngle('squat', J);
      drawCloudFig(J, 0, ang, trackedPoint('squat', J)); moveLabel('squat'); setKnee(ang); return;
    }
    cancelAnimationFrame(demoRAF);
    t0 = null; seqI = 0; repsInMove = 0; wasDown = false; morphStart = -1;
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
