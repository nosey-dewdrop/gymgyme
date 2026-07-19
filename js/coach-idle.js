// coach-idle.js — the RESTING camera panel.
//
// before the camera opens, #camera used to be a dark box. this draws a small
// looping POINT-CLOUD squat figure inside it instead (the same dot language as
// the index hero, js/landing.js — joints() + cloud + drawCloudFig — but
// standalone: no camera, no engine, no wasm). a mono caption reads
// "this is what the engine sees". when coach.js opens the real camera it adds
// body.running and CSS hides this canvas; the real video takes over.
//
// it never touches coach.js or any id coach.js reads. it only owns the two
// nodes it injects into #camera: .coach-idle (canvas) + .coach-idle-cap.
// reduced-motion -> a single static frame.
(function () {
  const host = document.getElementById('camera');
  if (!host) return;
  if (document.querySelector('.coach-idle')) return;   // idempotent

  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const INK = '#191320', LILA = '#8E6BA8';

  // caption above the figure
  const cap = document.createElement('span');
  cap.className = 'coach-idle-cap';
  cap.textContent = 'this is what the engine sees';

  const cv = document.createElement('canvas');
  cv.className = 'coach-idle';
  const ctx = cv.getContext('2d');

  // sit the dot figure behind the existing text/button so the copy stays
  // readable; the panel is light now (see css), text is ink.
  host.prepend(cv);
  host.prepend(cap);

  let CW = 480, CH = 360, DPR = 1;
  function resize() {
    const r = host.getBoundingClientRect();
    CW = Math.max(200, Math.round(r.width));
    CH = Math.max(200, Math.round(r.height));
    DPR = Math.min(window.devicePixelRatio || 1, 2);
    cv.width = CW * DPR; cv.height = CH * DPR;
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  }
  resize();
  window.addEventListener('resize', resize);

  // seeded rng so the scatter is stable frame to frame
  let s = 20260719;
  const rand = () => (s = (s * 16807) % 2147483647) / 2147483647;

  // side-view figure. d: 0 standing, 1 bottom of squat. (copied approach from
  // landing.js joints(), tuned smaller to sit inside the coach panel.)
  function joints(d) {
    const H = CH, W = CW;
    const figH = H * 0.72;
    const cx = W * 0.5;
    const footY = H * 0.5 + figH * 0.5;
    const u = figH / 560;
    const ankle = { x: cx, y: footY };
    const knee = { x: cx + 46 * d * u, y: footY - (82 - 14 * d) * u };
    const hip = { x: cx - 52 * d * u, y: footY - (170 - 92 * d) * u };
    const lean = 0.42 * d, tor = 128 * u;
    const sho = { x: hip.x + tor * Math.sin(lean), y: hip.y - tor * Math.cos(lean) };
    const head = { x: sho.x + 34 * u * Math.sin(lean), y: sho.y - 42 * u * Math.cos(lean) };
    const aAng = -0.45 + (Math.PI / 2 + 0.35) * d;
    const elb = { x: sho.x + 62 * u * Math.sin(aAng) * 0.55, y: sho.y + 62 * u * Math.cos(aAng) };
    const wri = { x: elb.x + 58 * u * (0.3 + 0.7 * d), y: elb.y + 58 * u * (1 - d) * 0.5 - 10 * u * d };
    const toe = { x: ankle.x + 34 * u, y: footY + 6 * u };
    const gap = 26 * u;
    const hip2 = { x: hip.x - gap * 0.5, y: hip.y };
    const knee2 = { x: knee.x - gap, y: knee.y + 4 * u };
    const ankle2 = { x: ankle.x - gap * 0.7, y: footY };
    return { ankle, knee, hip, sho, head, elb, wri, toe, hip2, knee2, ankle2, u };
  }

  const SEGS = [
    ['hip', 'sho', 0.055, 90],
    ['hip', 'knee', 0.038, 52],
    ['knee', 'ankle', 0.028, 38],
    ['hip2', 'knee2', 0.038, 42],
    ['knee2', 'ankle2', 0.028, 30],
    ['sho', 'elb', 0.022, 28],
    ['elb', 'wri', 0.022, 22],
    ['ankle', 'toe', 0.024, 14],
  ];
  const HEAD_N = 44;

  const cloud = [];
  for (const [a, b, spread, count] of SEGS) {
    for (let i = 0; i < count; i++) {
      cloud.push({
        kind: 'seg', a, b, spread,
        t: rand(), off: (rand() - 0.5) * 2, along: (rand() - 0.5) * 0.16,
        r: 1 + rand() * 1, aBase: 0.34 + rand() * 0.5, ph: rand() * Math.PI * 2,
      });
    }
  }
  for (let i = 0; i < HEAD_N; i++) {
    cloud.push({ kind: 'head', ang: rand() * Math.PI * 2, rr: rand(), r: 1 + rand() * 1.4, aBase: 0.34 + rand() * 0.5, ph: rand() * Math.PI * 2 });
  }

  const lerp = (p, q, t) => ({ x: p.x + (q.x - p.x) * t, y: p.y + (q.y - p.y) * t });
  function normal(p, q) { const dx = q.x - p.x, dy = q.y - p.y, L = Math.hypot(dx, dy) || 1; return { x: -dy / L, y: dx / L }; }
  function angleAt(b, a, c) {
    const v1 = { x: a.x - b.x, y: a.y - b.y }, v2 = { x: c.x - b.x, y: c.y - b.y };
    const den = Math.hypot(v1.x, v1.y) * Math.hypot(v2.x, v2.y) || 1;
    return Math.round(Math.acos(Math.max(-1, Math.min(1, (v1.x * v2.x + v1.y * v2.y) / den))) * 180 / Math.PI);
  }
  const smoothstep = (t) => t * t * (3 - 2 * t);

  function floorDots() {
    ctx.fillStyle = 'rgba(142,107,168,.16)';
    const y = CH * 0.5 + CH * 0.72 * 0.5 + 12;
    for (let x = CW * 0.2; x <= CW * 0.8; x += CW * 0.06) {
      ctx.beginPath(); ctx.arc(x, Math.min(y, CH - 6), 1.3, 0, Math.PI * 2); ctx.fill();
    }
  }
  function litKnee(knee, ts, angle) {
    ctx.globalAlpha = 1;
    ctx.fillStyle = LILA;
    ctx.beginPath(); ctx.arc(knee.x, knee.y, 4, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = LILA; ctx.globalAlpha = 0.5; ctx.lineWidth = 1;
    const br = reduce ? 11 : 11 + 2 * Math.sin(ts / 480);
    ctx.beginPath(); ctx.arc(knee.x, knee.y, br, 0, Math.PI * 2); ctx.stroke();
    ctx.globalAlpha = 1;
    if (angle != null) {
      ctx.fillStyle = LILA;
      ctx.font = '600 12px "JetBrains Mono", ui-monospace, monospace';
      ctx.fillText(angle + '°', knee.x + 15, knee.y + 3);
    }
  }
  function draw(J, ts, kneeAngle) {
    ctx.clearRect(0, 0, CW, CH);
    floorDots();
    for (const dt of cloud) {
      let base;
      if (dt.kind === 'head') {
        const rr = (14 + dt.rr * 13) * J.u;
        base = { x: J.head.x + Math.cos(dt.ang) * rr, y: J.head.y + Math.sin(dt.ang) * rr * 0.94 };
      } else {
        const tt = Math.min(1, Math.max(0, dt.t + dt.along));
        const mid = lerp(J[dt.a], J[dt.b], tt), nrm = normal(J[dt.a], J[dt.b]);
        const w = dt.spread * CH * 1.0;
        base = { x: mid.x + nrm.x * w * dt.off, y: mid.y + nrm.y * w * dt.off };
      }
      const jit = reduce ? 0 : 1;
      const vx = Math.sin(ts / 900 + dt.ph) * 0.7 * jit, vy = Math.cos(ts / 1050 + dt.ph) * 0.7 * jit;
      ctx.globalAlpha = dt.aBase;
      ctx.fillStyle = INK;
      ctx.beginPath(); ctx.arc(base.x + vx, base.y + vy, Math.min(2, dt.r), 0, Math.PI * 2); ctx.fill();
    }
    litKnee(J.knee, ts, kneeAngle);
    ctx.globalAlpha = 1;
  }

  const CYCLE = 5200;
  let t0 = null, raf = 0;
  function frame(ts) {
    // stop drawing while the real camera runs (canvas hidden by css anyway)
    if (document.body.classList.contains('running')) { raf = 0; return; }
    if (t0 === null) t0 = ts;
    const ph = ((ts - t0) % CYCLE) / CYCLE;
    const tri = ph < 0.5 ? ph * 2 : (1 - ph) * 2;
    const d = smoothstep(tri);
    const J = joints(d);
    draw(J, ts, angleAt(J.knee, J.hip, J.ankle));
    raf = requestAnimationFrame(frame);
  }

  function start() {
    if (reduce) { const J = joints(0.6); draw(J, 0, angleAt(J.knee, J.hip, J.ankle)); return; }
    if (raf) return;
    t0 = null;
    raf = requestAnimationFrame(frame);
  }

  // pause when the panel is offscreen / tab hidden; resume when it returns and
  // the real camera is not running.
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) { cancelAnimationFrame(raf); raf = 0; }
    else if (!document.body.classList.contains('running')) start();
  });

  // if the camera stops and #camera comes back, resume the idle figure.
  const mo = new MutationObserver(() => {
    if (!document.body.classList.contains('running') && !host.hidden) start();
  });
  mo.observe(document.body, { attributes: true, attributeFilter: ['class'] });
  mo.observe(host, { attributes: true, attributeFilter: ['hidden'] });

  start();
})();
