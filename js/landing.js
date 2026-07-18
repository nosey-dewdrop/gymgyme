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

  function pose(d) {
    // side view, facing right. d = squat depth 0..1
    const ankle = { x: 250, y: 470 };
    const knee = { x: 250 + 46 * d, y: 388 + 14 * d };
    const hip = { x: 250 - 52 * d, y: 300 + 92 * d };
    const lean = 0.42 * d; // torso lean, radians
    const tor = 128;
    const sho = { x: hip.x + tor * Math.sin(lean), y: hip.y - tor * Math.cos(lean) };
    const head = { x: sho.x + 34 * Math.sin(lean), y: sho.y - 42 * Math.cos(lean) };
    // arms swing forward as depth grows
    const aAng = -0.45 + (Math.PI / 2 + 0.35) * d; // from hanging to forward
    const upper = 62, fore = 58;
    const elb = { x: sho.x + upper * Math.sin(aAng) * 0.4 + upper * Math.cos(aAng) * 0.4, y: sho.y + upper * Math.cos(aAng) };
    const wri = { x: elb.x + fore * (0.3 + 0.7 * d), y: elb.y + fore * (1 - d) * 0.5 - 10 * d };
    return { ankle, knee, hip, sho, head, elb, wri };
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

  function bone(a, b) {
    ctx.beginPath();
    ctx.moveTo(a.x, a.y);
    ctx.lineTo(b.x, b.y);
    ctx.strokeStyle = BONE;
    ctx.lineWidth = 2;
    ctx.stroke();
  }

  function frame(ts) {
    if (t0 === null) t0 = ts;
    const phase = ((ts - t0) % T) / T;
    const d = (1 - Math.cos(phase * Math.PI * 2)) / 2; // smooth 0->1->0
    if (d > 0.85) wasDown = true;
    if (wasDown && d < 0.08) { wasDown = false; reps++; repsEl.textContent = reps; onRep(ts); }

    const p = pose(d);
    ctx.clearRect(0, 0, cv.width, cv.height);

    // floor dots
    ctx.fillStyle = BONE;
    for (let x = 90; x <= 430; x += 34) { ctx.beginPath(); ctx.arc(x, 486, 1.6, 0, Math.PI * 2); ctx.fill(); }

    bone(p.ankle, p.knee); bone(p.knee, p.hip); bone(p.hip, p.sho); bone(p.sho, p.head);
    bone(p.sho, p.elb); bone(p.elb, p.wri);

    joint(p.head, 15, INK);
    joint(p.sho, 6, INK); joint(p.hip, 6, INK); joint(p.ankle, 6, INK);
    joint(p.elb, 5, INK); joint(p.wri, 5, INK);
    // tracked joint: the knee, in lila, with a ring
    joint(p.knee, 7, LILA);
    ctx.beginPath();
    ctx.arc(p.knee.x, p.knee.y, 13 + 2 * Math.sin(ts / 200), 0, Math.PI * 2);
    ctx.strokeStyle = LILA;
    ctx.lineWidth = 1.5;
    ctx.stroke();

    const kneeAngle = angleAt(p.knee, p.hip, p.ankle);
    kneeEl.textContent = kneeAngle;
    ctx.fillStyle = LILA;
    ctx.font = '13px Helvetica, Arial, sans-serif';
    ctx.fillText(kneeAngle + '°', p.knee.x + 20, p.knee.y + 4);

    // celebration ring radiating from the hip on each completed rep
    if (ringT >= 0 && ts - ringT < 700) {
      const k = (ts - ringT) / 700;
      ctx.beginPath();
      ctx.arc(p.hip.x, p.hip.y, 20 + 70 * k, 0, Math.PI * 2);
      ctx.strokeStyle = 'rgba(142, 111, 216, ' + (0.5 * (1 - k)) + ')';
      ctx.lineWidth = 2;
      ctx.stroke();
    }

    requestAnimationFrame(frame);
  }

  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    const p = pose(0.6);
    [[p.ankle,p.knee],[p.knee,p.hip],[p.hip,p.sho],[p.sho,p.head],[p.sho,p.elb],[p.elb,p.wri]].forEach(([a,b])=>bone(a,b));
    joint(p.head, 15, INK); joint(p.sho,6,INK); joint(p.hip,6,INK); joint(p.ankle,6,INK); joint(p.elb,5,INK); joint(p.wri,5,INK); joint(p.knee,7,LILA);
    kneeEl.textContent = angleAt(p.knee, p.hip, p.ankle);
  } else {
    requestAnimationFrame(frame);
  }
})();
