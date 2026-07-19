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

  // ---- demo figure: HAND-PLACED side-profile joint coordinates per move.
  // each joint is a normalized {x,y} in a 0..1 box (x right, y down). every move
  // has a START pose and an END pose; phase d interpolates between them. this
  // guarantees a readable skeleton (not a random blob) for each move. ----
  const lrp = (a, b, t) => a + (b - a) * t;
  // joints, hand-drawn as a stick side profile. keys:
  // head, neck, sho(ulder), elb(ow), wri(st), hip, kneeF/ankF (front leg),
  // kneeB/ankB (back leg), toe. coords chosen so the profile reads clearly.
  const POSES = {
    // STANDING squat: upright -> deep squat (hips back+down, knees forward)
    squat: { joint: 'knee', label: 'squat',
      a: { head:[.50,.06], neck:[.50,.13], sho:[.50,.17], elb:[.52,.34], wri:[.53,.50], hip:[.50,.50], kneeF:[.55,.72], ankF:[.55,.94], kneeB:[.45,.72], ankB:[.45,.94], toe:[.60,.96] },
      b: { head:[.44,.20], neck:[.45,.27], sho:[.46,.31], elb:[.56,.42], wri:[.66,.50], hip:[.40,.58], kneeF:[.60,.70], ankF:[.55,.94], kneeB:[.52,.70], ankB:[.45,.94], toe:[.60,.96] } },
    // PLANK: horizontal line, forearms + toes down. barely moves (a small dip).
    plank: { joint: 'hip', label: 'plank',
      a: { head:[.18,.52], neck:[.24,.53], sho:[.30,.54], elb:[.30,.70], wri:[.22,.84], hip:[.62,.54], kneeF:[.78,.66], ankF:[.90,.80], kneeB:[.78,.62], ankB:[.90,.78], toe:[.94,.82] },
      b: { head:[.18,.54], neck:[.24,.55], sho:[.30,.56], elb:[.30,.72], wri:[.22,.84], hip:[.62,.58], kneeF:[.78,.68], ankF:[.90,.80], kneeB:[.78,.64], ankB:[.90,.78], toe:[.94,.82] } },
    // GLUTE BRIDGE: lying on back, knees bent, hips lift up (b = hips high)
    bridge: { joint: 'hip', label: 'glute bridge',
      a: { head:[.14,.72], neck:[.20,.72], sho:[.28,.72], elb:[.24,.82], wri:[.18,.90], hip:[.62,.72], kneeF:[.80,.62], ankF:[.86,.86], kneeB:[.80,.66], ankB:[.86,.88], toe:[.90,.88] },
      b: { head:[.14,.72], neck:[.20,.71], sho:[.28,.70], elb:[.24,.80], wri:[.18,.90], hip:[.60,.54], kneeF:[.80,.60], ankF:[.86,.86], kneeB:[.80,.62], ankB:[.86,.88], toe:[.90,.88] } },
    // LUNGE: front leg bent forward, back leg extended behind, torso upright
    lunge: { joint: 'knee', label: 'lunge',
      a: { head:[.48,.08], neck:[.48,.15], sho:[.48,.19], elb:[.49,.36], wri:[.50,.52], hip:[.47,.50], kneeF:[.60,.70], ankF:[.62,.94], kneeB:[.36,.72], ankB:[.26,.94], toe:[.68,.96] },
      b: { head:[.46,.18], neck:[.46,.25], sho:[.46,.29], elb:[.47,.44], wri:[.48,.58], hip:[.45,.56], kneeF:[.66,.74], ankF:[.62,.94], kneeB:[.30,.80], ankB:[.22,.94], toe:[.68,.96] } },
    // ARM RAISE: standing, arms lift from sides up to shoulder height / overhead
    raise: { joint: 'shoulder', label: 'arm raise',
      a: { head:[.50,.07], neck:[.50,.14], sho:[.50,.18], elb:[.51,.35], wri:[.52,.52], hip:[.50,.50], kneeF:[.53,.72], ankF:[.53,.94], kneeB:[.47,.72], ankB:[.47,.94], toe:[.58,.96] },
      b: { head:[.50,.07], neck:[.50,.14], sho:[.50,.18], elb:[.62,.24], wri:[.74,.14], hip:[.50,.50], kneeF:[.53,.72], ankF:[.53,.94], kneeB:[.47,.72], ankB:[.47,.94], toe:[.58,.96] } },
  };
  const SEQ = ['squat', 'plank', 'bridge', 'lunge', 'raise'];
  // FIG = fraction of panel HEIGHT the figure's normalized box occupies (<=0.70
  // so it is not a tall column). PADX/box width give human proportions: the pose
  // y-coords already put legs at ~48% of the standing height. centered vertically.
  const FIG = 0.68, FIGW = 0.5, PADY = (1 - FIG) / 2, PADX = (1 - FIGW) / 2;
  // map a normalized pose to canvas coords (box centered in the panel).
  function place(pt) { return { x: (PADX + pt[0] * FIGW) * CW, y: (PADY + pt[1] * FIG) * CH }; }
  function poseFor(move, d) {
    const P = POSES[move], A = P.a, B = P.b, out = { figH: CH * FIG };
    for (const k in A) out[k] = { x: lrp(place(A[k]).x, place(B[k]).x, d), y: lrp(place(A[k]).y, place(B[k]).y, d) };
    // aliases the drawing code expects
    out.headC = out.head; out.headR = CH * 0.03;
    out.knee = out.kneeF; out.ankle = out.ankF; out.knee2 = out.kneeB; out.ankle2 = out.ankB;
    out.hip2 = out.hip;
    return out;
  }
  function trackedAngle(move, J) {
    if (move === 'plank' || move === 'bridge') return angleAt(J.hip, J.sho, J.kneeF);
    if (move === 'raise') return angleAt(J.sho, J.hip, J.elb);
    return angleAt(J.kneeF, J.hip, J.ankF);
  }
  function trackedPoint(move, J) {
    if (move === 'plank' || move === 'bridge') return J.hip;
    if (move === 'raise') return J.sho;
    return J.kneeF;
  }

  // dot budget: 450 total, allocated in PROPORTION to each segment's length so a
  // long limb gets more dots and nothing clumps. widths (spread as a fraction of
  // figH) give each limb its volume; the two legs stay separate.
  // segments follow the hand-placed skeleton. spread = HALF-thickness of the
  // limb as a fraction of figH — kept SMALL so dots hug the bone line and the
  // profile stays readable. torso a touch wider; arms/shins thin.
  const SEG_DEFS = [
    ['neck', 'sho', 0.012, 0.8],  // neck
    ['hip', 'sho', 0.030, 2.4],   // torso — widest
    ['sho', 'elb', 0.013, 1.0],   // upper arm
    ['elb', 'wri', 0.011, 0.9],   // forearm
    ['hip', 'kneeF', 0.020, 1.5], // front thigh
    ['kneeF', 'ankF', 0.015, 1.5],// front shin
    ['hip', 'kneeB', 0.020, 1.3], // back thigh
    ['kneeB', 'ankB', 0.015, 1.3],// back shin
    ['ankF', 'toe', 0.013, 0.5],  // foot
  ];
  const HEAD_WEIGHT = 1.1, HEAD_SPREAD = 0.06;
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
    ctx.fillStyle = 'rgba(217,107,160,.45)';   /* pink — user's ground line */
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
      const vx = Math.sin(ts / 900 + dt.ph) * 0.5 * jit, vy = Math.cos(ts / 1050 + dt.ph) * 0.5 * jit;
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
      moveLabel(POSES[nm].label);
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
    moveLabel(POSES[move].label);
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
