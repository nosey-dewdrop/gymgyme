// dots.js — the one visual motif: a point cloud that breathes into a squatting
// figure. no lines, no skeleton. ~230 landmarks scattered across limb volume,
// the knee lit in rose with its live angle. same cloud idea reused at every
// scale across the page (see .dotmini clusters, button hover, loader).
(function () {
  const cv = document.getElementById('cloud');
  if (!cv) return;
  const ctx = cv.getContext('2d');
  const kneeEl = document.getElementById('kneeAngle');

  // palette (kept in sync with :root, read at runtime so dark mode flips)
  const css = getComputedStyle(document.documentElement);
  const PAPER = (css.getPropertyValue('--dot-color') || '#FAF3EE').trim();
  const ROSE = (css.getPropertyValue('--rose') || '#C2477A').trim();

  const DPR = Math.min(window.devicePixelRatio || 1, 2);
  let W = 0, H = 0;
  function size() {
    const r = cv.getBoundingClientRect();
    W = r.width; H = r.height;
    cv.width = Math.round(W * DPR);
    cv.height = Math.round(H * DPR);
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  }
  size();
  window.addEventListener('resize', size);

  // seeded rng so the scatter is stable frame-to-frame (no jitter jumps)
  let s = 20260719;
  const rand = () => (s = (s * 16807) % 2147483647) / 2147483647;

  // --- figure skeleton in a unit box, side view, facing right ---
  // depth d: 0 standing, 1 bottom of squat
  function joints(d) {
    const ankle = { x: 0.50, y: 0.94 };
    const knee = { x: 0.50 + 0.11 * d, y: 0.70 - 0.02 * d };
    const hip = { x: 0.50 - 0.12 * d, y: 0.50 + 0.20 * d };
    const lean = 0.42 * d;
    const t = 0.30;
    const sho = { x: hip.x + t * Math.sin(lean), y: hip.y - t * Math.cos(lean) };
    const head = { x: sho.x + 0.09 * Math.sin(lean), y: sho.y - 0.11 * Math.cos(lean) };
    const aAng = -0.4 + (Math.PI / 2 + 0.4) * d;
    const elb = { x: sho.x + 0.14 * Math.sin(aAng), y: sho.y + 0.14 * Math.cos(aAng) };
    const wri = { x: elb.x + 0.13 * Math.sin(aAng + 0.3), y: elb.y + 0.13 * Math.cos(aAng + 0.3) };
    const toe = { x: ankle.x + 0.08, y: 0.955 };
    return { ankle, knee, hip, sho, head, elb, wri, toe };
  }

  // segments with a thickness (limb volume): body wide, wrist narrow
  const SEGS = [
    ['ankle', 'knee', 0.045],
    ['knee', 'hip', 0.05],
    ['hip', 'sho', 0.075],   // torso, widest
    ['sho', 'elb', 0.036],
    ['elb', 'wri', 0.026],   // forearm, narrow
    ['ankle', 'toe', 0.03],
  ];

  // pre-assign each dot to a segment + parametric position + offset, once
  const N = 230;
  const dots = [];
  for (let i = 0; i < N; i++) {
    let seg;
    const roll = rand();
    // head gets its own cluster
    if (roll < 0.12) { seg = 'head'; }
    else {
      // weight by segment thickness so volume reads right
      let acc = 0; const total = SEGS.reduce((a, s) => a + s[2], 0);
      const pick = rand() * total;
      for (const sg of SEGS) { acc += sg[2]; if (pick <= acc) { seg = sg; break; } }
    }
    dots.push({
      seg,
      t: rand(),
      off: (rand() - 0.5) * 2,      // -1..1 across the limb width
      along: (rand() - 0.5) * 0.2,  // slight length spread
      r: 1 + rand() * 1.5,
      a: 0.25 + rand() * 0.55,
      ph: rand() * Math.PI * 2,     // vibration phase
    });
  }

  function lerp(p, q, t) { return { x: p.x + (q.x - p.x) * t, y: p.y + (q.y - p.y) * t }; }
  function normal(p, q) {
    const dx = q.x - p.x, dy = q.y - p.y, L = Math.hypot(dx, dy) || 1;
    return { x: -dy / L, y: dx / L };
  }
  function angleAt(b, a, c) {
    const v1 = { x: a.x - b.x, y: a.y - b.y }, v2 = { x: c.x - b.x, y: c.y - b.y };
    const dot = v1.x * v2.x + v1.y * v2.y;
    return Math.round(Math.acos(dot / (Math.hypot(v1.x, v1.y) * Math.hypot(v2.x, v2.y))) * 180 / Math.PI);
  }

  const smoothstep = (t) => t * t * (3 - 2 * t);
  const CYCLE = 5500;
  let t0 = null;

  function draw(now) {
    const pad = 0.12;
    const S = Math.min(W, H) * (1 - pad * 2);
    const ox = (W - S) / 2, oy = (H - S) / 2;
    const px = (p) => ({ x: ox + p.x * S, y: oy + p.y * S });

    if (t0 === null) t0 = now;
    const ph = ((now - t0) % CYCLE) / CYCLE;
    const tri = ph < 0.5 ? ph * 2 : (1 - ph) * 2;
    const d = smoothstep(tri);

    const J = joints(d);
    ctx.clearRect(0, 0, W, H);

    for (const dt of dots) {
      let base;
      if (dt.seg === 'head') {
        const h = px(J.head);
        const ang = dt.t * Math.PI * 2;
        const rr = (0.02 + dt.off * 0.015) * S;
        base = { x: h.x + Math.cos(ang) * rr, y: h.y + Math.sin(ang) * rr };
      } else {
        const [a, b, w] = dt.seg;
        const P = J[a], Q = J[b];
        const tt = Math.min(1, Math.max(0, dt.t + dt.along));
        const mid = lerp(P, Q, tt);
        const nrm = normal(P, Q);
        const wpx = w * S * dt.off;
        base = px({ x: mid.x + nrm.x * wpx / S, y: mid.y + nrm.y * wpx / S });
      }
      // gentle organic vibration
      const vx = Math.sin(now / 900 + dt.ph) * 0.9;
      const vy = Math.cos(now / 1050 + dt.ph) * 0.9;
      ctx.globalAlpha = dt.a;
      ctx.fillStyle = PAPER;
      ctx.beginPath();
      ctx.arc(base.x + vx, base.y + vy, dt.r, 0, Math.PI * 2);
      ctx.fill();
    }

    // knee: the tracked joint, rose, filled + breathing ring
    const k = px(J.knee);
    ctx.globalAlpha = 1;
    ctx.fillStyle = ROSE;
    ctx.beginPath();
    ctx.arc(k.x, k.y, 4.5, 0, Math.PI * 2);
    ctx.fill();
    const ring = 11 + 2.2 * Math.sin(now / 480);
    ctx.strokeStyle = ROSE;
    ctx.globalAlpha = 0.55;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(k.x, k.y, ring, 0, Math.PI * 2);
    ctx.stroke();
    ctx.globalAlpha = 1;

    if (kneeEl) kneeEl.textContent = angleAt(J.knee, J.hip, J.ankle) + '°';

    raf = requestAnimationFrame(draw);
  }

  let raf = null;
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    // static bottom-of-squat pose
    requestAnimationFrame((t) => { t0 = t - CYCLE * 0.5; draw(t); cancelAnimationFrame(raf); });
  } else {
    raf = requestAnimationFrame(draw);
  }
})();
