// coach-onboarding.js — a 4-step gate in FRONT of the existing coach flow.
// it never touches coach.js / the wasm motor. when the four steps are done it
// writes the chosen move + reps/sets into the hidden inputs coach.js already
// reads, then clicks #ready — coach.js takes it from there exactly as before.
//
// steps: (0) pick a move  (1) reps & sets  (2) camera permission  (3) framing.
// no X, no skip. answer required to advance. back is free. horizontal slide.
// dot progress: done = lila filled, active = breathing ring, waiting = empty.
// step 3 auto-confirms once a body is seen. reduced-motion: instant, no anim.
(function () {
  const onb = document.getElementById('onb');
  if (!onb) return;
  const track = document.getElementById('onbTrack');
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // the hidden controls coach.js reads
  const moveSel = document.getElementById('moveSel');
  const planReps = document.getElementById('planReps');
  const planSets = document.getElementById('planSets');
  const readyBtn = document.getElementById('ready');
  const camStage = document.getElementById('camera');
  const progList = document.getElementById('progList');

  // only show onboarding for a first-time visitor with an empty program.
  // if they already built a workout (came from my-program) skip straight to it.
  let seenBefore = false;
  try { seenBefore = localStorage.getItem('gg-onb-done') === '1'; } catch (e) {}
  const hasProgram = progList && progList.children.length > 0;
  if (seenBefore || hasProgram) return;   // existing flow untouched
  onb.hidden = false;
  if (camStage) camStage.hidden = true;   // hide the old warming card during onboarding

  const STEPS = 4;
  let step = 0;
  const answered = [false, false, false, false];

  // ---- step 0: moves (first 8 canonical, human labels from the select) ----
  const movesWrap = document.getElementById('onbMoves');
  const pool = moveSel ? [...moveSel.options].slice(0, 8) : [];
  let chosenMove = pool.length ? pool[1] ? pool[1].value : pool[0].value : 'squat'; // default squat
  pool.forEach((o) => {
    const b = document.createElement('button');
    b.type = 'button'; b.className = 'onb-opt'; b.textContent = o.textContent;
    b.addEventListener('click', () => {
      chosenMove = o.value;
      movesWrap.querySelectorAll('.onb-opt').forEach((x) => x.classList.remove('sel'));
      b.classList.add('sel');
      if (moveSel) moveSel.value = o.value;
      answered[0] = true;
      advance();
    });
    movesWrap.appendChild(b);
  });

  // ---- step 1: reps & sets presets ----
  const repsWrap = document.getElementById('onbReps');
  const PRESETS = [
    { label: '10 reps · 3 sets', reps: 10, sets: 3 },
    { label: '12 reps · 3 sets', reps: 12, sets: 3 },
    { label: '15 reps · 4 sets', reps: 15, sets: 4 },
    { label: 'count freely', reps: 0, sets: 1 },
  ];
  PRESETS.forEach((p) => {
    const b = document.createElement('button');
    b.type = 'button'; b.className = 'onb-opt'; b.textContent = p.label;
    b.addEventListener('click', () => {
      repsWrap.querySelectorAll('.onb-opt').forEach((x) => x.classList.remove('sel'));
      b.classList.add('sel');
      if (planReps) planReps.value = p.reps;
      if (planSets) planSets.value = p.sets;
      answered[1] = true;
      advance();
    });
    repsWrap.appendChild(b);
  });

  // ---- step 2: camera permission ----
  let permStream = null;
  const allowBtn = document.getElementById('onbAllow');
  if (allowBtn) allowBtn.addEventListener('click', async () => {
    allowBtn.textContent = 'starting the camera...';
    try {
      permStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user' }, audio: false });
      allowBtn.textContent = 'camera ready';
      allowBtn.classList.add('sel');
      answered[2] = true;
      advance();
    } catch (e) {
      allowBtn.textContent = 'camera blocked — allow it in your browser to continue';
      // no advance: answer required. permission denied keeps them on this step.
    }
  });

  // ---- step 3: framing — auto-confirm when a body is seen ----
  const panel = document.getElementById('onbPanel');
  const canvas = document.getElementById('onbCanvas');
  const hint = document.getElementById('onbHint');
  let framingStarted = false, framingRAF = 0, framingVideo = null, framingPose = null;
  async function startFraming() {
    if (framingStarted) return;
    framingStarted = true;
    const ctx = canvas.getContext('2d');
    try {
      const core = await import('./engine-core.js');
      const { pose } = await core.loadPoseLandmarker({ numPoses: 1, wantSeg: false });
      framingPose = pose;
      framingVideo = document.createElement('video');
      framingVideo.playsInline = true; framingVideo.muted = true;
      framingVideo.srcObject = permStream || await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user' }, audio: false });
      permStream = framingVideo.srcObject;
      await framingVideo.play();
      let stable = 0, lastT = -1;
      const loop = () => {
        if (!framingStarted) return;
        if (framingVideo.currentTime !== lastT && framingVideo.videoWidth) {
          lastT = framingVideo.currentTime;
          let res = null;
          try { res = framingPose.detectForVideo(framingVideo, performance.now()); } catch (e) {}
          ctx.clearRect(0, 0, canvas.width, canvas.height);
          const lm = res && res.landmarks && res.landmarks[0];
          if (lm) {
            let vis = 0;
            for (let i = 0; i < lm.length; i++) {
              const p = lm[i]; if (p.visibility != null && p.visibility < 0.4) continue;
              vis++;
              ctx.globalAlpha = 0.5 + 0.4 * (p.visibility || 1);
              ctx.fillStyle = '#EDE6F7';
              ctx.beginPath(); ctx.arc((1 - p.x) * canvas.width, p.y * canvas.height, 2, 0, Math.PI * 2); ctx.fill();
            }
            ctx.globalAlpha = 1;
            // whole body visible = enough landmarks with good visibility, for a few frames
            if (vis >= 24) { stable++; if (hint) hint.textContent = 'got you'; }
            else { stable = 0; if (hint) hint.textContent = 'step back so your whole body fits'; }
            if (stable >= 12) { confirmFraming(); return; }
          } else {
            stable = 0; if (hint) hint.textContent = 'this is what the engine sees';
          }
        }
        framingRAF = requestAnimationFrame(loop);
      };
      framingRAF = requestAnimationFrame(loop);
    } catch (e) {
      // model failed — let them confirm by standing there; fall back to a manual nudge
      if (hint) hint.textContent = 'this is what the engine sees';
    }
  }
  function stopFraming() {
    framingStarted = false;
    cancelAnimationFrame(framingRAF);
    if (permStream) { permStream.getTracks().forEach((t) => t.stop()); permStream = null; }
  }
  function confirmFraming() {
    if (panel) panel.classList.add('glow');
    answered[3] = true;
    stopFraming();
    finish();
  }

  // ---- navigation ----
  function renderDots() {
    for (let s = 0; s < STEPS; s++) {
      const holder = document.getElementById('onbDots' + s);
      if (!holder) continue;
      holder.innerHTML = '';
      for (let i = 0; i < STEPS; i++) {
        const d = document.createElement('i');
        if (i < step) d.className = 'done';
        else if (i === step) d.className = 'active';
        holder.appendChild(d);
      }
    }
  }
  function slide() {
    if (reduce) track.style.transition = 'none';
    track.style.transform = 'translateX(-' + (step * 25) + '%)';
    renderDots();
    // start framing detection when we land on step 3
    if (step === 3) startFraming();
    else stopFraming();
    // dot wave on the just-completed step
    if (!reduce) {
      const holder = document.getElementById('onbDots' + step);
      if (holder) { holder.classList.remove('onb-wave'); void holder.offsetWidth; holder.classList.add('onb-wave'); }
    }
  }
  function advance() {
    if (!answered[step]) return;       // answer required
    if (step < STEPS - 1) { step++; slide(); }
  }
  function back() {
    if (step > 0) { step--; slide(); }
  }
  for (let s = 0; s < STEPS; s++) {
    const b = document.getElementById('onbBack' + s);
    if (b) b.addEventListener('click', back);
  }

  function finish() {
    try { localStorage.setItem('gg-onb-done', '1'); } catch (e) {}
    onb.hidden = true;
    if (camStage) camStage.hidden = false;
    // hand off to the existing engine flow exactly as the old "start" button did
    if (readyBtn) readyBtn.click();
  }

  renderDots();
  slide();
})();
