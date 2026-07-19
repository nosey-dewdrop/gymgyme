// live demo: a 2d joint rig doing squats. the counter counts THIS figure's
// completed cycles and the knee angle is computed from the drawn geometry,
// so every number on screen is real.
(function () {
  const cv = document.getElementById('rig');
  const plusEl = document.getElementById('plus');
  const brandDot = document.querySelector('.brand i');
  let ringT = -1;
  function onRep(ts) {
    ringT = ts;
    plusEl.classList.remove('fly'); void plusEl.offsetWidth; plusEl.classList.add('fly');
    if (brandDot) { brandDot.classList.remove('hop'); void brandDot.offsetWidth; brandDot.classList.add('hop'); }
  }
  const ctx = cv.getContext('2d');
  const repsEl = document.getElementById('reps');
  const kneeEl = document.getElementById('knee');
  const LILA = '#8e6fd8', INK = '#111', BONE = '#d8d4de';
  let reps = 0, wasDown = false;
  const T = 2600; // ms per squat cycle
  let t0 = null;

  const R = (v, a) => ({ x: v.x * Math.cos(a) - v.y * Math.sin(a), y: v.x * Math.sin(a) + v.y * Math.cos(a) });
  const rad = (deg) => deg * Math.PI / 180;

  function limbs(d, ax) {
    // one side of the body, built from real joint angles
    const L2 = 88, L1 = 96, TOR = 130;
    const ankle = { x: ax, y: 470 };
    const phi = rad(8 + 30 * d);                 // shank lean
    const K = rad(172 - 82 * d);                 // interior knee angle
    const knee = { x: ankle.x + L2 * Math.sin(phi), y: ankle.y - L2 * Math.cos(phi) };
    const ka = { x: ankle.x - knee.x, y: ankle.y - knee.y };
    const kh = R({ x: ka.x / L2, y: ka.y / L2 }, K);
    const hip = { x: knee.x + L1 * kh.x, y: knee.y + L1 * kh.y };
    const tau = rad(5 + 38 * d);                 // torso lean
    const sho = { x: hip.x + TOR * Math.sin(tau), y: hip.y - TOR * Math.cos(tau) };
    const alpha = rad(15 + 75 * d);              // arms swing forward as counterweight
    const elb = { x: sho.x + 58 * Math.sin(alpha), y: sho.y + 58 * Math.cos(alpha) };
    const wri = { x: elb.x + 52 * Math.sin(alpha + rad(18)), y: elb.y + 52 * Math.cos(alpha + rad(18)) };
    const toe = { x: ankle.x + 36, y: 476 };
    return { ankle, knee, hip, sho, elb, wri, toe };
  }

  function pose(d) {
    const near = limbs(d, 262);
    const far = limbs(d, 248);
    const tau = rad(5 + 38 * d);
    const head = { x: near.sho.x + 46 * Math.sin(tau), y: near.sho.y - 46 * Math.cos(tau) };
    return { near, far, head };
  }

  function angleAt(b, a, c) {
    const v1 = { x: a.x - b.x, y: a.y - b.y }, v2 = { x: c.x - b.x, y: c.y - b.y };
    const dot = v1.x * v2.x + v1.y * v2.y;
    return Math.round(Math.acos(dot / (Math.hypot(v1.x, v1.y) * Math.hypot(v2.x, v2.y))) * 180 / Math.PI);
  }

  function joint(p, r, color) {
    ctx.beginPath();
    ctx.arc(p.x, p.y, r, 0, Math.PI * 2);
    ctx.fillStyle = color;
    ctx.fill();
  }

  function bone(a, b, color, w) {
    ctx.beginPath();
    ctx.moveTo(a.x, a.y);
    ctx.lineTo(b.x, b.y);
    ctx.strokeStyle = color;
    ctx.lineWidth = w;
    ctx.lineCap = 'round';
    ctx.stroke();
  }

  function drawSide(s, boneC, jointC, w, jr) {
    bone(s.ankle, s.toe, boneC, w);
    bone(s.ankle, s.knee, boneC, w);
    bone(s.knee, s.hip, boneC, w);
    bone(s.hip, s.sho, boneC, w);
    bone(s.sho, s.elb, boneC, w);
    bone(s.elb, s.wri, boneC, w);
    [s.ankle, s.hip, s.sho, s.elb, s.wri].forEach(p => joint(p, jr, jointC));
  }

  function draw(d, ts) {
    const p = pose(d);
    ctx.clearRect(0, 0, cv.width, cv.height);

    // floor dots
    ctx.fillStyle = '#d8d4de';
    for (let x = 110; x <= 430; x += 34) { ctx.beginPath(); ctx.arc(x, 488, 1.6, 0, Math.PI * 2); ctx.fill(); }

    // far side first, lighter; near side on top, ink
    drawSide(p.far, '#ddd9e5', '#c9c3d6', 5, 4);
    drawSide(p.near, '#8f889d', '#111', 5.5, 5.5);
    joint(p.head, 14, '#111');

    // tracked joint: the near knee, lila, ringed, with its real angle
    joint(p.near.knee, 7, LILA);
    ctx.beginPath();
    ctx.arc(p.near.knee.x, p.near.knee.y, 13 + 2 * Math.sin((ts || 0) / 200), 0, Math.PI * 2);
    ctx.strokeStyle = LILA;
    ctx.lineWidth = 1.5;
    ctx.stroke();

    const kneeAngle = angleAt(p.near.knee, p.near.hip, p.near.ankle);
    kneeEl.textContent = kneeAngle;
    ctx.fillStyle = LILA;
    ctx.font = 'bold 13px Helvetica, Arial, sans-serif';
    ctx.fillText(kneeAngle + '\u00b0', p.near.knee.x + 22, p.near.knee.y + 4);
    return p;
  }

  function frame(ts) {
    if (t0 === null) t0 = ts;
    const phase = ((ts - t0) % T) / T;
    const d = (1 - Math.cos(phase * Math.PI * 2)) / 2;
    if (d > 0.85) wasDown = true;
    if (wasDown && d < 0.08) { wasDown = false; reps++; repsEl.textContent = reps; onRep(ts); }

    const p = draw(d, ts);

    if (ringT >= 0 && ts - ringT < 700) {
      const k = (ts - ringT) / 700;
      ctx.beginPath();
      ctx.arc(p.near.hip.x, p.near.hip.y, 20 + 70 * k, 0, Math.PI * 2);
      ctx.strokeStyle = 'rgba(142, 111, 216, ' + (0.5 * (1 - k)) + ')';
      ctx.lineWidth = 2;
      ctx.stroke();
    }

    requestAnimationFrame(frame);
  }

  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    draw(0.6, 0);
  } else {
    requestAnimationFrame(frame);
  }
})();
