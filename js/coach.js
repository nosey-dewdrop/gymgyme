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
const startBtn = $("start");
const stopBtn = $("stop");
const stage = $("stage");
const video = $("cam");
const canvas = $("overlay");
const ctx = canvas.getContext("2d");
const readEl = $("read");
const repCountEl = $("repCount");
const halfNoteEl = $("halfNote");
const scoreLineEl = $("scoreLine");
const phaseWord = $("phaseWord");
const subEl = $("sub");
const depthFill = $("depthFill");
const confFill = $("confFill");
const framingFill = $("framingFill");
const anglesEl = $("angles");
const fpsEl = $("fps");
const msgEl = $("msg");
const privateNote = $("private");

const LM = 33;                 // MediaPipe pose nokta sayısı
const FLOATS = LM * 4;         // her nokta [x, y, z, visibility]

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
    engine = new motorMod.Engine("squat");
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
    ["tracked knee", "tracked"],
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
  if (engine) engine.reset();
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

// motorun fazı + yönünü tek bir insana dönük kelimeye çevir.
function phraseFor(r) {
  if (!r.tracking) return "...";
  const mid = r.depth > 0.12 && r.depth < 0.9;
  if (r.motion === "down" && mid) return "going down";
  if (r.motion === "up" && mid) return "coming up";
  if (r.phase === "bottom") return "deep";
  return "standing";
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

let cueUntil = 0;   // takip sürerken gelen koç mesajı (örn. "yarım kaldı") kısa süre ekranda kalsın

function render(r) {
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
      "knee " + Math.round(r.smoothAngle) + "°   ·   moving " + r.motion + "   ·   phase " + r.phase +
      (r.view !== "unknown" ? "   ·   view " + r.view : "");
    if (r.message) { msgEl.textContent = r.message; cueUntil = performance.now() + 1800; }
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

startBtn.addEventListener("click", start);
stopBtn.addEventListener("click", stop);
window.addEventListener("resize", () => { if (running) sizeCanvas(); });
