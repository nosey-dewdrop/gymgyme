// coach-onboarding.js — a 4-step gate in FRONT of the existing coach flow.
// it never touches coach.js / the wasm motor. when the four steps are done it
// writes the chosen move + reps/sets into the hidden inputs coach.js already
// reads, then clicks #ready — coach.js takes it from there exactly as before.
//
// steps: (0) pick a move  (1) reps & sets  (2) camera permission  (3) framing.
// no X, no skip. answer required to advance. back is free. horizontal slide.
// dot progress: done = lila filled, active = breathing ring, waiting = empty.
// step 3 auto-confirms once a body is seen. reduced-motion: instant, no anim.
//
// SIGN-IN GATE (added with membership): before ANY workout starts, a signed-out
// visitor sees a calm gate. they get ONE free guest workout (localStorage flag
// "gg-guest-used"); after that only sign-in / create account remain. signed-in
// visitors never see the gate. the full engine runs during the guest trial —
// coach.js only syncs when signed in, so the guest result is simply not saved.
import { sb, onAuth, currentUser } from './auth.js';

const GUEST_KEY = 'gg-guest-used';
function guestUsed() { try { return localStorage.getItem(GUEST_KEY) === '1'; } catch (e) { return false; } }
function markGuestUsed() { try { localStorage.setItem(GUEST_KEY, '1'); } catch (e) {} }

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

  // ── sign-in gate wiring ──────────────────────────────────────────────
  // once the gate is passed (signed in, or "try one workout" chosen), #ready
  // clicks flow through untouched. until then, a signed-out visitor's start is
  // intercepted and the gate is shown. we learn the session state async via
  // auth.js; a synchronous supabase session (if present) also unlocks instantly.
  const gate = document.getElementById('coachGate');
  const gateOpts = document.getElementById('gateOpts');
  const gateTitle = document.getElementById('gateTitle');
  const gateBody = document.getElementById('gateBody');
  let signedIn = false;          // live session state (updated by onAuth)
  let authKnown = !sb;           // has the REAL session resolved yet?
  let gatePassed = !sb;          // no backend => let the workout run (guest-only site)

  // live updates: keeps signedIn current if the user signs in/out in another tab.
  // note: auth.js fires this immediately with null before the session resolves,
  // so we do NOT trust it for authKnown — the real resolution is getSession below.
  onAuth((u) => { signedIn = !!u; if (signedIn) { gatePassed = true; authKnown = true; } });

  function isGuest() { return sb && authKnown && !signedIn; }

  // build the gate for the current situation. hides onboarding + camera behind it.
  function showGate() {
    if (!gate) return;
    const used = guestUsed();
    if (used) {
      gateTitle.textContent = 'your free workout is done';
      gateBody.textContent = 'you have used your one guest workout on this device. create an account (or sign in) to keep training — your reps, scores and history then follow you across every device.';
    } else {
      gateTitle.textContent = 'before your workout';
      gateBody.textContent = 'sign in to save your reps and scores, or try one workout as a guest. either way the camera stays on this device.';
    }
    gateOpts.innerHTML = '';
    const signInBtn = mkGateBtn('sign in', 'ghost', () => { location.href = 'signin.html'; });
    const createBtn = mkGateBtn('create an account', 'primary', () => { location.href = 'signup.html'; });
    gateOpts.appendChild(createBtn);
    gateOpts.appendChild(signInBtn);
    if (!used) {
      const tryBtn = mkGateBtn('try one workout', 'ghost', () => {
        markGuestUsed();          // one workout per device — counted by number
        gatePassed = true;
        gate.hidden = true;
        startAfterGate();
      });
      gateOpts.appendChild(tryBtn);
    }
    if (onb) onb.hidden = true;
    if (camStage) camStage.hidden = true;
    gate.hidden = false;
  }
  function mkGateBtn(label, kind, on) {
    const b = document.createElement('button');
    b.type = 'button'; b.className = 'gate-opt ' + kind; b.textContent = label;
    b.addEventListener('click', on);
    return b;
  }

  // guest passed the gate — resume the normal first-run experience: onboarding
  // for a fresh visitor, or straight to the engine if they already have a program.
  function startAfterGate() {
    if (shouldOnboard()) beginOnboarding();
    else { if (camStage) camStage.hidden = false; if (readyBtn) readyBtn.click(); }
  }

  // intercept the workout start for signed-out visitors who have not passed the
  // gate. capture phase so we run before coach.js's own #ready handler.
  if (readyBtn) {
    readyBtn.addEventListener('click', (e) => {
      if (gatePassed || !isGuest()) return;   // signed in, no backend, or already allowed
      e.stopImmediatePropagation();
      e.preventDefault();
      showGate();
    }, true);
  }

  // ── first-run decision ───────────────────────────────────────────────
  // only onboard a first-time visitor with an empty program.
  let seenBefore = false;
  try { seenBefore = localStorage.getItem('gg-onb-done') === '1'; } catch (e) {}
  const hasProgram = progList && progList.children.length > 0;
  function shouldOnboard() { return !seenBefore && !hasProgram; }

  // gate decision on load. resolve the REAL session first (getSession), then:
  // signed in -> onboarding (or straight to program). signed out -> gate.
  function decideOnLoad() {
    if (signedIn || !sb) { if (shouldOnboard()) beginOnboarding(); return; }
    showGate();
  }
  if (!sb) {
    decideOnLoad();
  } else {
    sb.auth.getSession().then(({ data }) => {
      signedIn = !!(data && data.session);
      if (signedIn) gatePassed = true;
      authKnown = true;
      decideOnLoad();
    }).catch(() => { authKnown = true; decideOnLoad(); });
  }

  // if we are not onboarding right now (already seen / has program), leave the
  // existing flow untouched — the #ready interceptor above still guards guests.
  if (!shouldOnboard()) return;

  function beginOnboarding() {
    onb.hidden = false;
    if (camStage) camStage.hidden = true;   // hide the old warming card during onboarding
    renderDots();
    slide();
  }

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

  // onboarding is started by beginOnboarding() (from the load decision or after
  // the guest passes the gate) — never eagerly, so the gate can come first.
})();

// when a GUEST finishes their one workout, invite them to make an account so it
// gets saved. we watch the summary card (coach.js un-hides it on completion) and
// re-show the gate copy — calm, never blocking what they just did.
(function () {
  const summary = document.getElementById('summary');
  const gate = document.getElementById('coachGate');
  if (!summary || !gate || !sb) return;
  let shown = false;
  const obs = new MutationObserver(() => {
    if (shown || summary.hidden) return;
    if (currentUser()) return;          // signed in — coach.js already saved it
    shown = true;
    const title = document.getElementById('gateTitle');
    const body = document.getElementById('gateBody');
    const opts = document.getElementById('gateOpts');
    if (title) title.textContent = 'nice — want to keep this?';
    if (body) body.textContent = 'that was your free guest workout, counted live on this device but not saved. create an account to keep it and let your history follow you across devices.';
    if (opts) {
      opts.innerHTML = '';
      const create = document.createElement('button');
      create.type = 'button'; create.className = 'gate-opt primary'; create.textContent = 'create an account';
      create.addEventListener('click', () => { location.href = 'signup.html'; });
      const signin = document.createElement('button');
      signin.type = 'button'; signin.className = 'gate-opt ghost'; signin.textContent = 'sign in';
      signin.addEventListener('click', () => { location.href = 'signin.html'; });
      opts.appendChild(create); opts.appendChild(signin);
    }
    gate.hidden = false;
    gate.scrollIntoView({ behavior: 'smooth', block: 'center' });
  });
  obs.observe(summary, { attributes: true, attributeFilter: ['hidden'] });
})();
