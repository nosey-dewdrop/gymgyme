// landing.js — the hero figure as a POINT CLOUD (no lines, no skeleton).
// ~230 ink dots scattered across limb volume, squatting. the knee is lit lila
// with its live angle. the rep counter counts THIS figure's completed cycles,
// so every number on screen is real. drives the +1 float, brand-dot hop and ring.
(function () {
  const cv = document.getElementById('rig');
  if (!cv) return;
  const ctx = cv.getContext('2d');
  const repsEl = document.getElementById('reps');
  const kneeEl = document.getElementById('knee');
  const plusEl = document.getElementById('plus');
  const brandDot = document.querySelector('.brand i');

  const INK = '#111111', LILA = '#8e6fd8';
  let reps = 0, wasDown = false, ringT = -1;
  const CYCLE = 5200;
  let t0 = null;

  // dpr-scaled canvas
  const DPR = Math.min(window.devicePixelRatio || 1, 2);
  const CW = cv.width, CH = cv.height;
  cv.width = CW * DPR; cv.height = CH * DPR;
  ctx.scale(DPR, DPR);

  // seeded rng so the scatter is stable frame-to-frame
  let s = 20260719;
  const rand = () => (s = (s * 16807) % 2147483647) / 2147483647;

  // joints in canvas coords, side view facing right. d: 0 standing, 1 bottom
  function joints(d) {
    const ankle = { x: 250, y: 470 };
    const knee = { x: 250 + 46 * d, y: 388 + 14 * d };
    const hip = { x: 250 - 52 * d, y: 300 + 92 * d };
    const lean = 0.42 * d, tor = 128;
    const sho = { x: hip.x + tor * Math.sin(lean), y: hip.y - tor * Math.cos(lean) };
    const head = { x: sho.x + 34 * Math.sin(lean), y: sho.y - 42 * Math.cos(lean) };
    const aAng = -0.45 + (Math.PI / 2 + 0.35) * d;
    const elb = { x: sho.x + 62 * Math.sin(aAng) * 0.55, y: sho.y + 62 * Math.cos(aAng) };
    const wri = { x: elb.x + 58 * (0.3 + 0.7 * d), y: elb.y + 58 * (1 - d) * 0.5 - 10 * d };
    const toe = { x: ankle.x + 34, y: 476 };
    return { ankle, knee, hip, sho, head, elb, wri, toe };
  }

  // segments with a width (limb volume): torso widest, forearm narrow
  const SEGS = [
    ['ankle', 'knee', 22],
    ['knee', 'hip', 24],
    ['hip', 'sho', 34],
    ['sho', 'elb', 17],
    ['elb', 'wri', 12],
    ['ankle', 'toe', 14],
  ];

  const N = 230;
  const cloud = [];
  for (let i = 0; i < N; i++) {
    let seg;
    if (rand() < 0.12) seg = 'head';
    else {
      const total = SEGS.reduce((a, x) => a + x[2], 0);
      let acc = 0; const pick = rand() * total;
      for (const sg of SEGS) { acc += sg[2]; if (pick <= acc) { seg = sg; break; } }
    }
    cloud.push({
      seg, t: rand(), off: (rand() - 0.5) * 2, along: (rand() - 0.5) * 0.18,
      r: 1 + rand() * 1.5, a: 0.25 + rand() * 0.55, ph: rand() * Math.PI * 2,
    });
  }

  const lerp = (p, q, t) => ({ x: p.x + (q.x - p.x) * t, y: p.y + (q.y - p.y) * t });
  function normal(p, q) { const dx = q.x - p.x, dy = q.y - p.y, L = Math.hypot(dx, dy) || 1; return { x: -dy / L, y: dx / L }; }
  function angleAt(b, a, c) {
    const v1 = { x: a.x - b.x, y: a.y - b.y }, v2 = { x: c.x - b.x, y: c.y - b.y };
    const dot = v1.x * v2.x + v1.y * v2.y;
    return Math.round(Math.acos(dot / (Math.hypot(v1.x, v1.y) * Math.hypot(v2.x, v2.y))) * 180 / Math.PI);
  }
  const smoothstep = (t) => t * t * (3 - 2 * t);

  function onRep(ts) {
    ringT = ts;
    if (plusEl) { plusEl.classList.remove('fly'); void plusEl.offsetWidth; plusEl.classList.add('fly'); }
    if (brandDot) { brandDot.classList.remove('hop'); void brandDot.offsetWidth; brandDot.classList.add('hop'); }
  }

  function setReps(n) {
    if (!repsEl) return;
    // keep the .plus span; only update the leading text node
    if (repsEl.firstChild && repsEl.firstChild.nodeType === 3) repsEl.firstChild.textContent = n;
    else repsEl.insertBefore(document.createTextNode(n), repsEl.firstChild);
  }

  function draw(d, ts) {
    const J = joints(d);
    ctx.clearRect(0, 0, CW, CH);

    // floor dots
    ctx.fillStyle = '#d8d4de';
    for (let x = 110; x <= 430; x += 34) { ctx.beginPath(); ctx.arc(x, 488, 1.6, 0, Math.PI * 2); ctx.fill(); }

    for (const dt of cloud) {
      let base;
      if (dt.seg === 'head') {
        const ang = dt.t * Math.PI * 2, rr = 20 + dt.off * 14;
        base = { x: J.head.x + Math.cos(ang) * rr, y: J.head.y + Math.sin(ang) * rr };
      } else {
        const [a, b, w] = dt.seg;
        const tt = Math.min(1, Math.max(0, dt.t + dt.along));
        const mid = lerp(J[a], J[b], tt), nrm = normal(J[a], J[b]);
        base = { x: mid.x + nrm.x * w * dt.off, y: mid.y + nrm.y * w * dt.off };
      }
      const vx = Math.sin(ts / 900 + dt.ph) * 0.9, vy = Math.cos(ts / 1050 + dt.ph) * 0.9;
      ctx.globalAlpha = dt.a;
      ctx.fillStyle = INK;
      ctx.beginPath();
      ctx.arc(base.x + vx, base.y + vy, dt.r, 0, Math.PI * 2);
      ctx.fill();
    }

    // knee: tracked joint, lila, filled + breathing ring + live angle
    ctx.globalAlpha = 1;
    ctx.fillStyle = LILA;
    ctx.beginPath(); ctx.arc(J.knee.x, J.knee.y, 4.5, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = LILA; ctx.globalAlpha = 0.55; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.arc(J.knee.x, J.knee.y, 12 + 2 * Math.sin(ts / 480), 0, Math.PI * 2); ctx.stroke();
    ctx.globalAlpha = 1;

    const ka = angleAt(J.knee, J.hip, J.ankle);
    if (kneeEl) kneeEl.textContent = ka;
    ctx.fillStyle = LILA;
    ctx.font = 'bold 13px Helvetica, Arial, sans-serif';
    ctx.fillText(ka + '°', J.knee.x + 20, J.knee.y + 4);

    // celebration ring on each completed rep
    if (ringT >= 0 && ts - ringT < 700) {
      const k = (ts - ringT) / 700;
      ctx.beginPath(); ctx.arc(J.hip.x, J.hip.y, 20 + 70 * k, 0, Math.PI * 2);
      ctx.strokeStyle = 'rgba(142,111,216,' + (0.5 * (1 - k)) + ')'; ctx.lineWidth = 2; ctx.stroke();
    }
  }

  function frame(ts) {
    if (t0 === null) t0 = ts;
    const ph = ((ts - t0) % CYCLE) / CYCLE;
    const tri = ph < 0.5 ? ph * 2 : (1 - ph) * 2;
    const d = smoothstep(tri);
    if (d > 0.85) wasDown = true;
    if (wasDown && d < 0.08) { wasDown = false; reps++; setReps(reps); onRep(ts); }
    draw(d, ts);
    requestAnimationFrame(frame);
  }

  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    draw(0.6, 0);
  } else {
    requestAnimationFrame(frame);
  }
})();
