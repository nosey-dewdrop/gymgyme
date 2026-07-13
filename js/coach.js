// coach.js — SADECE tutkal. Kamerayı açar, MediaPipe'ın verdiği noktaları C++
// motora (engine/motor.wasm) uzatır, motorun döndürdüğü okumayı ekrana yazar.
// Hiç analiz yok burada — açı, yumuşatma, faz hepsi C++'ta.
//
// Hız: landmark'ları her kare wasm heap'ine bir kez yazıp motora POINTER geçiyoruz
// (kare başına yüzlerce JS↔wasm sınır geçişi yerine tek çağrı).

// mediapipe VENDOR'lanmış — üçüncü taraf CDN'e runtime bağımlılık yok, offline çalışır.
import { PoseLandmarker, FilesetResolver, DrawingUtils } from "../vendor/mediapipe/vision_bundle.mjs";

const $ = (id) => document.getElementById(id);
const statusEl = $("status");
const moveSel = $("moveSel");
const startBtn = $("start");
const stopBtn = $("stop");
const stage = $("stage");
const video = $("cam");
const canvas = $("overlay");
const ctx = canvas.getContext("2d");
const readEl = $("read");
const repCountEl = $("repCount");
const repRowEl = repCountEl.parentElement;
const halfNoteEl = $("halfNote");
const scoreLineEl = $("scoreLine");
const phaseWord = $("phaseWord");
const subEl = $("sub");
const setLineEl = $("setLine");
const restEl = $("rest");
const restCountEl = $("restCount");
const restSubEl = $("restSub");
const skipRestBtn = $("skipRest");
const planReps = $("planReps");
const planSets = $("planSets");
const planRest = $("planRest");
const summaryEl = $("summary");
const sumTitle = $("sumTitle");
const sumBody = $("sumBody");
const depthFill = $("depthFill");
const confFill = $("confFill");
const framingFill = $("framingFill");
const anglesEl = $("angles");
const fpsEl = $("fps");
const msgEl = $("msg");
const privateNote = $("private");

const LM = 33;                 // MediaPipe pose nokta sayısı
const FLOATS = LM * 4;         // her nokta [x, y, z, visibility]

// plan giriş alanlarını oku, motora ver. reps=0 → plan yok (serbest say).
// motora setPlan çağrısı ilerlemeyi sıfırlar, o yüzden başlarken ve plan
// alanları değişince çağrılır.
function applyPlan() {
  if (!engine) return;
  const reps = Math.max(0, Math.min(99, parseInt(planReps.value, 10) || 0));
  const sets = Math.max(1, Math.min(20, parseInt(planSets.value, 10) || 1));
  const rest = Math.max(0, Math.min(600, parseInt(planRest.value, 10) || 0));
  engine.setPlan(reps, sets, rest);
}

// hareketlerin insana dönük dili. hangi eklemin izlendiği, fazların ve gidişin
// kelimeleri — motorun id'leriyle (engine/coach_engine.cpp kütüphanesi) birebir.
const MOVES = {
  squat:       { joint: "knee",  top: "standing", bottom: "deep",   down: "going down",  up: "coming up" },
  pushup:      { joint: "elbow", top: "up",       bottom: "down",   down: "going down",  up: "pushing up" },
  lunge:       { joint: "knee",  top: "standing", bottom: "low",    down: "stepping down", up: "coming up" },
  glutebridge: { joint: "hip",   top: "bridged",  bottom: "down",   down: "lowering",    up: "lifting" },
  situp:       { joint: "hip",   top: "lying",    bottom: "up",     down: "sitting up",  up: "lying back" },
  press:       { joint: "elbow", top: "locked",   bottom: "racked", down: "lowering",    up: "pressing" },
};
let move = MOVES.squat;

let poseLandmarker = null;
let motorMod = null;           // wasm modülü (_malloc / HEAPF32 için)
let engine = null;             // C++ motor örneği
let bufPtr = 0;                // heap'te ayrılmış landmark buffer'ı (ekran)
let worldBufPtr = 0;           // ... ve dünya koordinatları (metrik 3B) için ikincisi
let running = false;
let lastVideoTime = -1;
let drawer = null;
let aspect = 1;
let frames = 0, fps = 0, fpsClock = 0;
let angleRows = null;          // textContent ile güncellenen satırlar

const setStatus = (m) => { statusEl.textContent = m; };

// gören model: MediaPipe pose (kendisi de c++/wasm, gpu'da, cihazda).
async function loadPose() {
  setStatus("loading the pose model (first time only, then cached)...");
  const vision = await FilesetResolver.forVisionTasks("vendor/mediapipe/wasm");
  poseLandmarker = await PoseLandmarker.createFromOptions(vision, {
    baseOptions: {
      modelAssetPath: "vendor/models/pose_landmarker_lite.task",
      delegate: "GPU"
    },
    runningMode: "VIDEO",
    numPoses: 1
  });
  drawer = new DrawingUtils(ctx);
}

// düşünen beyin: bizim c++ motorumuz, wasm'a derli. yoksa iskelet yine görünür.
async function loadEngine() {
  try {
    const { default: createMotor } = await import("../engine/motor.js");
    motorMod = await createMotor();
    engine = new motorMod.Engine(moveSel.value);
    bufPtr = motorMod._malloc(FLOATS * 4);        // 4 byte/float
    worldBufPtr = motorMod._malloc(FLOATS * 4);
    buildAngleRows();
    readEl.hidden = false;
  } catch (e) {
    console.warn("engine not loaded (skeleton still works):", e);
  }
}

// açı panelini bir kez kur; sonra her kare sadece değerleri (textContent) güncelle.
function buildAngleRows() {
  const defs = [
    ["tracked " + move.joint, "tracked"],
    ["left knee / right", "knee"],
    ["left hip / right", "hip"],
    ["left elbow / right", "elbow"],
  ];
  anglesEl.innerHTML = "";
  angleRows = {};
  for (const [label, key] of defs) {
    const row = document.createElement("div");
    const k = document.createElement("span");
    k.className = "k";
    k.textContent = label;
    const v = document.createElement("span");
    row.appendChild(k);
    row.appendChild(v);
    anglesEl.appendChild(row);
    angleRows[key] = v;
  }
}

async function start() {
  startBtn.disabled = true;
  try {
    if (!poseLandmarker) await loadPose();
    if (!engine) await loadEngine();
    applyPlan();                               // plan alanlarını motora ver
    summaryEl.hidden = true;                   // yeni seans, eski özet gitsin
    setStatus("asking for the camera...");
    const stream = await navigator.mediaDevices.getUserMedia({ video: { width: 640, height: 480 } });
    video.srcObject = stream;
    await video.play();
    stage.hidden = false;
    privateNote.hidden = false;
    stopBtn.hidden = false;
    sizeCanvas();
    setStatus("i can see you. stand back so your whole body fits.");
    running = true;
    frames = 0; fps = 0; fpsClock = performance.now();
    requestAnimationFrame(loop);
  } catch (e) {
    setStatus("could not start the camera: " + (e && e.message ? e.message : e));
    startBtn.disabled = false;
  }
}

function stop() {
  running = false;
  const s = video.srcObject;
  if (s) s.getTracks().forEach((t) => t.stop());
  video.srcObject = null;
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  showSummary();                 // reset'ten ÖNCE: özet bu seansın verisinden
  if (engine) engine.reset();
  restEl.hidden = true;
  setLineEl.hidden = true;
  repRowEl.style.display = "";
  phaseWord.style.display = "";
  subEl.style.display = "";
  wasComplete = false;
  stage.hidden = true;
  stopBtn.hidden = true;
  startBtn.disabled = false;
  setStatus("stopped. the camera is off.");
}

function sizeCanvas() {
  canvas.width = video.videoWidth || 640;
  canvas.height = video.videoHeight || 480;
  aspect = canvas.width / canvas.height;
}

// motorun fazı + yönünü, SEÇİLİ hareketin insana dönük kelimesine çevir.
function phraseFor(r) {
  if (!r.tracking) return "...";
  const mid = r.depth > 0.12 && r.depth < 0.9;
  if (r.motion === "down" && mid) return move.down;
  if (r.motion === "up" && mid) return move.up;
  if (r.phase === "bottom") return move.bottom;
  return move.top;
}

const deg = (v) => (v >= 0 ? Math.round(v) + "°" : "–");

// tekrar "tık"ı: kısa bir bip (WebAudio, dosya yok) + telefonda küçük titreşim.
// AudioContext start'taki kullanıcı jestiyle açılır; açılamazsa sessizce vazgeç.
let audioCtx = null;
function beep(freq, dur, vol) {
  try {
    audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
    const o = audioCtx.createOscillator();
    const g = audioCtx.createGain();
    o.frequency.value = freq;
    g.gain.setValueAtTime(vol, audioCtx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + dur);
    o.connect(g);
    g.connect(audioCtx.destination);
    o.start();
    o.stop(audioCtx.currentTime + dur + 0.01);
  } catch (_) { /* ses yoksa sayaç yine çalışır */ }
}
function repTick() {
  beep(880, 0.12, 0.09);                     // tiz "tık": saydım
  if (navigator.vibrate) navigator.vibrate(35);
  repCountEl.classList.remove("ticked");
  void repCountEl.offsetWidth;               // animasyonu yeniden tetikle
  repCountEl.classList.add("ticked");
}
function halfBuzz() {
  beep(220, 0.18, 0.07);                     // pes "bzz": o sayılmadı
  if (navigator.vibrate) navigator.vibrate([50, 40, 50]);
}
function setChime() {
  beep(660, 0.14, 0.08);                     // iki notalı "set bitti" sesi
  setTimeout(() => beep(990, 0.18, 0.08), 130);
  if (navigator.vibrate) navigator.vibrate([40, 60, 40]);
}
function doneChime() {
  beep(523, 0.16, 0.08);                     // üç notalı "antrenman bitti"
  setTimeout(() => beep(659, 0.16, 0.08), 150);
  setTimeout(() => beep(784, 0.26, 0.08), 300);
  if (navigator.vibrate) navigator.vibrate([50, 60, 50, 60, 90]);
}

let cueUntil = 0;   // takip sürerken gelen koç mesajı (örn. "yarım kaldı") kısa süre ekranda kalsın
let wasComplete = false;   // antrenman-bitti sesini bir kez çalmak için

// planlı akışın görünümü: set satırı, dinlenme bloğu, bitti hali. serbest modda
// (targetReps=0) hiçbiri görünmez, sayfa bugünküyle aynı kalır.
function renderPlan(r) {
  if (r.setTick && !r.workoutComplete) setChime();
  if (r.workoutComplete && !wasComplete) { doneChime(); showSummary(); }
  wasComplete = r.workoutComplete;

  const planned = r.targetReps > 0;
  restEl.hidden = !r.resting;

  // dinlenme sırasında canlı okumaları sustur; dinlenme bloğu sahnede.
  const live = !r.resting;
  repRowEl.style.display = live ? "" : "none";
  phaseWord.style.display = live ? "" : "none";
  subEl.style.display = live ? "" : "none";

  if (r.resting) {
    restCountEl.textContent = Math.ceil(r.restRemaining);
    restSubEl.textContent = "set " + (r.currentSet + 1) + " of " + r.totalSets + " coming up";
  }

  if (!planned) { setLineEl.hidden = true; return; }
  setLineEl.hidden = false;
  if (r.workoutComplete) {
    setLineEl.textContent = "workout complete - " + r.reps + " reps in " + r.totalSets + " sets";
  } else if (r.resting) {
    setLineEl.textContent = "set " + r.currentSet + " of " + r.totalSets + " done";
  } else {
    setLineEl.textContent = "set " + r.currentSet + " of " + r.totalSets +
      "   ·   " + r.repsInSet + " of " + r.targetReps;
  }
}

// seans özeti: motordan al, sıcak cümlelere çevir. reps=0 ise gösterme.
function showSummary() {
  if (!engine) return;
  const s = engine.summary();
  if (!s || s.reps === 0) { summaryEl.hidden = true; return; }
  const mins = Math.floor(s.durationSec / 60), secs = Math.round(s.durationSec % 60);
  const time = mins > 0 ? mins + " min " + secs + "s" : secs + "s";
  const lines = [];
  lines.push(s.reps + " reps" + (s.setsCompleted > 0 ? " across " + s.setsCompleted + " sets" : "") + ", in " + time + ".");
  if (s.avgScore >= 0) lines.push("they averaged " + s.avgScore + " out of 100, your best was " + s.bestScore + ".");
  if (s.cleanReps > 0) lines.push(s.cleanReps + " came with clean form.");
  if (s.halfReps > 0) lines.push(s.halfReps + " did not count - go all the way down next time.");
  sumTitle.textContent = s.workoutComplete ? "that's a workout" : "nice work";
  sumBody.innerHTML = "";
  lines.forEach((l) => { const d = document.createElement("div"); d.textContent = l; sumBody.appendChild(d); });
  summaryEl.hidden = false;
}

function render(r) {
  renderPlan(r);
  phaseWord.textContent = phraseFor(r);
  repCountEl.textContent = r.reps;
  if (r.repTick) repTick();
  if (r.halfTick) halfBuzz();
  halfNoteEl.textContent = r.halfReps > 0 ? "not counted: " + r.halfReps + " (too shallow)" : "";

  if (r.lastRepScore >= 0) {
    scoreLineEl.innerHTML = "";
    const b = document.createElement("span");
    b.className = "big";
    b.textContent = "last rep " + r.lastRepScore;
    scoreLineEl.appendChild(b);
    scoreLineEl.appendChild(document.createTextNode(
      "   ·   " + r.lastRepSeconds.toFixed(1) + "s   ·   session avg " + r.avgRepScore));
  } else {
    scoreLineEl.textContent = "";
  }

  if (r.tracking) {
    subEl.textContent =
      move.joint + " " + Math.round(r.smoothAngle) + "°   ·   moving " + r.motion + "   ·   phase " + r.phase +
      (r.view !== "unknown" ? "   ·   view " + r.view : "");
    const cue = r.message || r.formCue;      // yarım uyarısı > form düzeltmesi
    if (cue) { msgEl.textContent = cue; cueUntil = performance.now() + 1800; }
    else if (performance.now() > cueUntil) msgEl.textContent = "";
  } else {
    subEl.textContent = "";
    msgEl.textContent = r.message || "";
  }

  depthFill.style.width = Math.round((r.depth || 0) * 100) + "%";
  confFill.style.width = Math.round((r.confidence || 0) * 100) + "%";
  framingFill.style.width = Math.round((r.framing || 0) * 100) + "%";

  if (angleRows) {
    angleRows.tracked.textContent = r.tracking
      ? Math.round(r.smoothAngle) + "° (raw " + deg(r.rawAngle) + ")"
      : "–";
    angleRows.knee.textContent = deg(r.leftKnee) + "  /  " + deg(r.rightKnee);
    angleRows.hip.textContent = deg(r.leftHip) + "  /  " + deg(r.rightHip);
    angleRows.elbow.textContent = deg(r.leftElbow) + "  /  " + deg(r.rightElbow);
  }
}

function loop() {
  if (!running) return;
  if (video.currentTime !== lastVideoTime && video.readyState >= 2) {
    lastVideoTime = video.currentTime;
    if (canvas.width !== (video.videoWidth || canvas.width)) sizeCanvas();

    const result = poseLandmarker.detectForVideo(video, performance.now());
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    let skeletonColor = "#33000E";
    if (result && result.landmarks && result.landmarks.length) {
      const lm = result.landmarks[0];

      if (engine) {
        // landmark'ları wasm heap'ine yaz (x aspect ile ölçekli ki açı bozulmasın),
        // sonra motora pointer geç. HEAPF32'yi her kare tazeliyoruz (bellek büyürse
        // eski görünüm geçersiz olabilir). İkinci buffer: MediaPipe'ın DÜNYA
        // koordinatları (metrik 3B) — motor açıları onlardan ölçer, kameraya
        // dönük bükülmeler kaybolmaz.
        const heap = motorMod.HEAPF32;
        const base = bufPtr >> 2;
        const count = Math.min(lm.length, LM);
        for (let i = 0; i < count; i++) {
          const p = lm[i];
          heap[base + i * 4]     = p.x * aspect;
          heap[base + i * 4 + 1] = p.y;
          heap[base + i * 4 + 2] = 0;
          heap[base + i * 4 + 3] = p.visibility ?? 1;
        }
        const wl = result.worldLandmarks && result.worldLandmarks[0];
        let wcount = 0;
        if (wl) {
          const wbase = worldBufPtr >> 2;
          wcount = Math.min(wl.length, LM);
          for (let i = 0; i < wcount; i++) {
            const p = wl[i];
            heap[wbase + i * 4]     = p.x;
            heap[wbase + i * 4 + 1] = p.y;
            heap[wbase + i * 4 + 2] = p.z ?? 0;
            heap[wbase + i * 4 + 3] = p.visibility ?? 1;
          }
        }
        const r = engine.updatePtr(bufPtr, count * 4, worldBufPtr, wcount * 4, performance.now());
        if (r.tracking) skeletonColor = r.phase === "bottom" ? "#A61B42" : "#33000E";
        render(r);
      }

      drawer.drawConnectors(lm, PoseLandmarker.POSE_CONNECTIONS, { color: skeletonColor, lineWidth: 4 });
      drawer.drawLandmarks(lm, { color: "#FFFFFF", fillColor: skeletonColor, radius: 5, lineWidth: 2 });
    }

    frames++;
    const now = performance.now();
    if (now - fpsClock >= 500) {
      fps = Math.round((frames * 1000) / (now - fpsClock));
      frames = 0; fpsClock = now;
      fpsEl.textContent = fps + " fps  ·  all math on your device";
    }
  }
  requestAnimationFrame(loop);
}

// hareket değişimi: motor sıfırdan başlar (setMove reset'i içerir), sayaç ekranı temizlenir.
moveSel.addEventListener("change", () => {
  move = MOVES[moveSel.value] || MOVES.squat;
  if (engine) {
    engine.setMove(moveSel.value);
    applyPlan();                     // hareket değişince plan yeniden uygulanır (ilerleme sıfırlanır)
    buildAngleRows();
    repCountEl.textContent = "0";
    halfNoteEl.textContent = "";
    scoreLineEl.textContent = "";
    msgEl.textContent = "";
    setLineEl.hidden = true;
    restEl.hidden = true;
    summaryEl.hidden = true;
    wasComplete = false;
  }
});

// plan alanları değişince motora anında yansı (ilerlemeyi sıfırlar).
[planReps, planSets, planRest].forEach((el) => el.addEventListener("change", () => {
  applyPlan();
  wasComplete = false;
}));

// "hazırım": molayı erken bitir, sıradaki sete geç.
skipRestBtn.addEventListener("click", () => { if (engine) engine.skipRest(); });

startBtn.addEventListener("click", start);
stopBtn.addEventListener("click", stop);
window.addEventListener("resize", () => { if (running) sizeCanvas(); });
