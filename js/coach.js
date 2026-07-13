// coach.js — SADECE tutkal. Kamerayı açar, MediaPipe'ın verdiği noktaları C++
// motora (engine/motor.wasm) uzatır, motorun döndürdüğü okumayı ekrana yazar.
// Hiç analiz yok burada — açı, yumuşatma, faz hepsi C++'ta.
//
// Hız: landmark'ları her kare wasm heap'ine bir kez yazıp motora POINTER geçiyoruz
// (kare başına yüzlerce JS↔wasm sınır geçişi yerine tek çağrı).

// mediapipe VENDOR'lanmış — üçüncü taraf CDN'e runtime bağımlılık yok, offline çalışır.
import { PoseLandmarker, FilesetResolver, DrawingUtils } from "../vendor/mediapipe/vision_bundle.mjs";
// ortak hesap: giriş yapılıysa seanslar DB'ye de gider (cihazlar arası).
import { sb, currentUser, onAuth } from "./auth.js";

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

// ── program: hareket KUYRUĞU (Damla: seans değil program). cihazda saklanır,
// kamera sırayla oynatır — biten hareket kaydedilir, sıradaki 5 sn geri sayımla gelir. ──
const PROG_KEY = "gg_program";
const progListEl = $("progList"), addMoveBtn = $("addMove");
const introCard = $("intro"), progCard = $("progCard"), backProg = $("backProg");
let program = { items: [], rest: 45 };
try {
  const p = JSON.parse(localStorage.getItem(PROG_KEY));
  if (p && Array.isArray(p.items)) program = { items: p.items, rest: p.rest ?? 45 };
} catch (_) { /* kayıt yoksa boş programla başlanır */ }
let progIdx = 0;
let switching = false;     // hareketler arası geri sayım — motor o karelerde dinlenir
let doneSummaries = [];    // her hareketin özeti; sonda toplanıp tek özet gösterilir

function saveProgram() { try { localStorage.setItem(PROG_KEY, JSON.stringify(program)); } catch (_) {} }
function moveLabel(v) { const o = [...moveSel.options].find((x) => x.value === v); return o ? o.textContent : v; }
function readPlanInputs() {
  const reps = Math.max(0, Math.min(99, parseInt(planReps.value, 10) || 0));
  const sets = Math.max(1, Math.min(20, parseInt(planSets.value, 10) || 1));
  return { move: moveSel.value, reps, sets };
}
function readRestInput() { return Math.max(0, Math.min(600, parseInt(planRest.value, 10) || 0)); }
function renderProgram() {
  progListEl.innerHTML = "";
  if (!program.items.length) {
    const e = document.createElement("div");
    e.className = "prog-empty";
    e.textContent = "no moves yet - pick one below and add it.";
    progListEl.appendChild(e);
    return;
  }
  program.items.forEach((it, i) => {
    const d = document.createElement("div");
    d.className = "prog-item";
    d.textContent = (i + 1) + ". " + moveLabel(it.move) + " - " +
      (it.reps > 0 ? it.reps + " reps × " + it.sets + " sets" : "free count");
    const rm = document.createElement("button");
    rm.type = "button"; rm.className = "mini"; rm.textContent = "remove";
    rm.onclick = () => { program.items.splice(i, 1); saveProgram(); renderProgram(); };
    d.append("  "); d.appendChild(rm);
    progListEl.appendChild(d);
  });
}

// sıradaki hareketin planını motora ver (setPlan ilerlemeyi sıfırlar).
function applyPlan() {
  if (!engine) return;
  const it = program.items[progIdx] || readPlanInputs();
  engine.setPlan(it.reps, it.sets, program.rest);
}

// hareketlerin insana dönük dili. hangi eklemin izlendiği, fazların ve gidişin
// kelimeleri — motorun id'leriyle (engine/coach_engine.cpp kütüphanesi) birebir.
const MOVES = {
  squat:          { joint: "knee",     top: "standing",  bottom: "deep",     down: "going down",    up: "coming up" },
  sumosquat:      { joint: "knee",     top: "standing",  bottom: "deep",     down: "going down",    up: "coming up" },
  sidelunge:      { joint: "knee",     top: "standing",  bottom: "low",      down: "sitting side",  up: "coming up" },
  pushup:         { joint: "elbow",    top: "up",        bottom: "down",     down: "going down",    up: "pushing up" },
  kneelingpushup: { joint: "elbow",    top: "up",        bottom: "down",     down: "going down",    up: "pushing up" },
  lunge:          { joint: "knee",     top: "standing",  bottom: "low",      down: "stepping down", up: "coming up" },
  glutebridge:    { joint: "hip",      top: "bridged",   bottom: "down",     down: "lowering",      up: "lifting" },
  situp:          { joint: "hip",      top: "lying",     bottom: "up",       down: "sitting up",    up: "lying back" },
  press:          { joint: "elbow",    top: "locked",    bottom: "racked",   down: "lowering",      up: "pressing" },
  kickback:       { joint: "hip",      top: "extended",  bottom: "folded",   down: "folding back",  up: "kicking back" },
  birddog:        { joint: "hip",      top: "extended",  bottom: "folded",   down: "coming back",   up: "reaching out" },
  calfraise:      { joint: "ankle",    top: "on toes",   bottom: "flat",     down: "lowering",      up: "rising" },
  jumpingjack:    { joint: "shoulder", top: "arms up",   bottom: "arms down", down: "coming down",  up: "jumping" },
  armraise:       { joint: "shoulder", top: "raised",    bottom: "down",     down: "lowering",      up: "raising" },
};
let move = MOVES.squat;

// derin bağlantı: coach.html?move=squat → o hareketle açıl (11).
const wantMove = new URLSearchParams(location.search).get("move");
if (wantMove && MOVES[wantMove]) { moveSel.value = wantMove; move = MOVES[wantMove]; }

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
    engine.setCalibration(true);   // önce vücudu öğren, sonra ona kilitlen
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

// kuyruğun i. hareketini yükle: motor sıfırdan o hareketle başlar, ekran temizlenir.
function loadItem(i) {
  progIdx = i;
  const it = program.items[i];
  moveSel.value = it.move;
  move = MOVES[it.move] || MOVES.squat;
  if (engine) { engine.setMove(it.move); applyPlan(); buildAngleRows(); }
  sessionLogged = false; wasComplete = false;
  repCountEl.textContent = "0"; halfNoteEl.textContent = ""; scoreLineEl.textContent = ""; msgEl.textContent = "";
  setLineEl.hidden = true; restEl.hidden = true;
  setStatus("move " + (i + 1) + " of " + program.items.length + ": " + moveLabel(it.move));
}

// biten hareketten sıradakine: 5 sn "next up" arası, motor o sırada dinlenir.
function advanceMove() {
  switching = true;
  const next = program.items[progIdx + 1];
  let n = 5;
  phaseWord.textContent = "next: " + moveLabel(next.move);
  subEl.textContent = "get in position - starting in " + n + "...";
  const iv = setInterval(() => {
    if (!running) { clearInterval(iv); switching = false; return; }
    n--;
    if (n <= 0) { clearInterval(iv); loadItem(progIdx + 1); switching = false; }
    else subEl.textContent = "get in position - starting in " + n + "...";
  }, 1000);
}

async function start() {
  startBtn.disabled = true;
  try {
    if (!poseLandmarker) await loadPose();
    if (!engine) await loadEngine();
    doneSummaries = [];
    summaryEl.hidden = true;                   // yeni seans, eski özet gitsin
    syncState = "none"; syncLineDiv = null;    // senkron satırı da sıfırdan
    setStatus("asking for the camera...");
    // ön kamera, esnek çözünürlük — telefon dikey de verse motor kadraja uyar.
    const stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: "user", width: { ideal: 640 }, height: { ideal: 480 } }
    });
    video.srcObject = stream;
    await video.play();
    stage.hidden = false;
    privateNote.hidden = false;
    stopBtn.hidden = false;
    sizeCanvas();
    loadItem(0);
    setStatus("i can see you - move 1 of " + program.items.length + ": " +
      moveLabel(program.items[0].move) + ". stand back so your whole body fits.");
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
  switching = false;
  const s = video.srcObject;
  if (s) s.getTracks().forEach((t) => t.stop());
  video.srcObject = null;
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  // yarıda durdurulan hareketin sayılmış tekrarları da kaybolmasın
  if (engine && !sessionLogged) {
    const cur = engine.summary();
    if (cur && cur.reps > 0) { doneSummaries.push({ move: moveSel.value, s: cur }); logSession(cur); }
  }
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
  if (r.workoutComplete && !wasComplete) {
    doneChime();
    wasComplete = true;
    const s = engine ? engine.summary() : null;
    if (s && s.reps > 0) { doneSummaries.push({ move: moveSel.value, s }); logSession(s); }
    if (progIdx < program.items.length - 1) { advanceMove(); return; }  // sıradaki hareket
    showSummary();
  }
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

// seansı gymgyme'ye işle (15): geçmişe yaz + takvimde bugünü işaretle. aynı
// origin, aynı localStorage — dizindeki "programım" takvimi bugünü yanar.
const SESS_KEY = "hl_coach_sessions", DAYS_KEY = "hl_days";
function isoToday() {
  const d = new Date();
  return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
}
let sessionLogged = false;

// ── dürüst senkron: özet "hesabına kaydedildi" demeden önce insert'in sonucunu
// bekler. başarısız olan satır kuyruğa düşer, bağlantı gelince (online olayı,
// giriş) yeniden denenir. kullanıcıya hiçbir zaman olmamış bir kayıt söylenmez. ──
const QUEUE_KEY = "hl_sync_queue";
let syncState = "none";      // local | pending | ok | queued
let syncLineDiv = null;      // özet kartındaki senkron satırı (varsa canlı güncellenir)

function syncText() {
  if (syncState === "pending") return "saving to your account...";
  if (syncState === "ok") return "saved to your account and lit up today on your gymgyme calendar.";
  if (syncState === "queued") return "saved on this device - it will sync to your account when the connection is back.";
  return "saved on this device and lit up today on your calendar - sign in to keep your workouts across devices.";
}
function setSyncState(s) { syncState = s; if (syncLineDiv) syncLineDiv.textContent = syncText(); }

function queuePush(row) {
  try {
    const q = JSON.parse(localStorage.getItem(QUEUE_KEY)) || [];
    q.push(row);
    localStorage.setItem(QUEUE_KEY, JSON.stringify(q.slice(-20)));
  } catch (_) { /* kuyruk tutulamazsa cihaz kaydı yine durur */ }
}

// kuyruğu boşalt: yalnız o an girişli kullanıcının satırları gönderilir,
// başkasının bekleyenleri kendi girişini bekler (hesaplar karışmaz).
async function flushQueue() {
  const u = currentUser();
  if (!sb || !u) return;
  let q = [];
  try { q = JSON.parse(localStorage.getItem(QUEUE_KEY)) || []; } catch (_) { return; }
  const mine = q.filter((r) => r.uid === u.id);
  if (!mine.length) return;
  const { error } = await sb.from("gg_coach_sessions").insert(mine.map(({ uid, ...row }) => row));
  if (error) return;                 // hâlâ offline olabiliriz — kuyruk yerinde kalır
  try { localStorage.setItem(QUEUE_KEY, JSON.stringify(q.filter((r) => r.uid !== u.id))); } catch (_) {}
  loadHistory();
}

function logSession(s) {
  if (sessionLogged || !s || s.reps === 0) return;
  sessionLogged = true;
  // her zaman cihaza yaz: offline çalışsın + dizin takvimi bugünü yansıtsın.
  try {
    const list = JSON.parse(localStorage.getItem(SESS_KEY)) || [];
    list.push({ move: moveSel.value, reps: s.reps, sets: s.setsCompleted, avg: s.avgScore, date: isoToday(), t: Date.now() });
    localStorage.setItem(SESS_KEY, JSON.stringify(list.slice(-50)));
    const days = JSON.parse(localStorage.getItem(DAYS_KEY)) || [];
    if (!days.includes(isoToday())) { days.push(isoToday()); localStorage.setItem(DAYS_KEY, JSON.stringify(days)); }
  } catch (_) { /* localStorage yoksa seans yine görünür, sadece kaydedilmez */ }
  const u = currentUser();
  if (!sb || !u) { setSyncState("local"); return; }
  // created_at'i biz koyuyoruz: satır kuyruğa düşüp yarın gönderilse bile
  // seansın gerçek zamanı korunur.
  const row = {
    move: moveSel.value, reps: s.reps, sets: s.setsCompleted,
    avg_score: s.avgScore, best_score: s.bestScore, clean_reps: s.cleanReps,
    half_reps: s.halfReps, duration_sec: s.durationSec, workout_complete: s.workoutComplete,
    created_at: new Date().toISOString()
  };
  setSyncState("pending");
  sb.from("gg_coach_sessions").insert(row).then(({ error }) => {
    if (error) { queuePush({ uid: u.id, ...row }); setSyncState("queued"); }
    else { setSyncState("ok"); loadHistory(); }
  });
}

// program özeti: biten HER hareketin özeti doneSummaries'te birikir (kayıt da
// hareket başına yapıldı) — burada toplanıp tek sıcak özet gösterilir.
function showSummary() {
  if (!doneSummaries.length) { summaryEl.hidden = true; return; }
  let reps = 0, sets = 0, half = 0, clean = 0, dur = 0, wsum = 0, wn = 0, best = -1, complete = true;
  const perMove = [];
  for (const d of doneSummaries) {
    const s = d.s;
    reps += s.reps; sets += s.setsCompleted; half += s.halfReps; clean += s.cleanReps; dur += s.durationSec;
    if (s.avgScore >= 0) { wsum += s.avgScore * s.reps; wn += s.reps; }
    if (s.bestScore > best) best = s.bestScore;
    complete = complete && s.workoutComplete;
    perMove.push(moveLabel(d.move) + " - " + s.reps + " reps" + (s.avgScore >= 0 ? ", avg " + s.avgScore : ""));
  }
  const mins = Math.floor(dur / 60), secs = Math.round(dur % 60);
  const time = mins > 0 ? mins + " min " + secs + "s" : secs + "s";
  const lines = [];
  lines.push(reps + " reps" + (sets > 0 ? " across " + sets + " sets" : "") + ", in " + time + ".");
  if (doneSummaries.length > 1) perMove.forEach((l) => lines.push(l));
  if (wn > 0) lines.push("they averaged " + Math.round(wsum / wn) + " out of 100, your best was " + best + ".");
  if (clean > 0) lines.push(clean + " came with clean form.");
  if (half > 0) lines.push(half + " did not count - go all the way down next time.");
  sumTitle.textContent = complete && doneSummaries.length === program.items.length ? "that's a workout" : "nice work";
  sumBody.innerHTML = "";
  lines.forEach((l) => { const d = document.createElement("div"); d.textContent = l; sumBody.appendChild(d); });
  // senkron satırı ayrı bir div: insert'in sonucu gelince yerinde güncellenir.
  syncLineDiv = document.createElement("div");
  syncLineDiv.textContent = syncText();
  sumBody.appendChild(syncLineDiv);
  summaryEl.hidden = false;
}

// ── geçmiş: yazılan veri artık okunuyor da. girişliyse hesaptaki son seanslar,
// değilse (ya da DB'ye ulaşılamıyorsa) bu cihazdakiler. ──
const histEl = $("history"), histList = $("histList");
let histSeq = 0;   // yarışan yüklemelerden yalnız sonuncusu çizer

function histRow(when, mv, reps, sets, avg) {
  const div = document.createElement("div");
  div.className = "hist-row";
  const d = new Date(when);
  const day = isNaN(d.getTime()) ? "" : d.toLocaleDateString("en-US", { month: "short", day: "numeric" }).toLowerCase();
  div.textContent = day + "   ·   " + mv + "   ·   " + reps + " reps" +
    (sets > 0 ? " in " + sets + " sets" : "") +
    (avg != null && avg >= 0 ? "   ·   avg " + avg : "");
  return div;
}

async function loadHistory() {
  if (!histEl) return;
  const seq = ++histSeq;
  let rows = [];
  if (sb && currentUser()) {
    const { data, error } = await sb.from("gg_coach_sessions")
      .select("move,reps,sets,avg_score,created_at")
      .order("created_at", { ascending: false }).limit(30);
    if (!error && data) rows = data.map((r) => [r.created_at, r.move, r.reps, r.sets, r.avg_score]);
  }
  if (!rows.length) {
    try {
      const list = JSON.parse(localStorage.getItem(SESS_KEY)) || [];
      rows = list.slice(-30).reverse().map((r) => [r.t || r.date, r.move, r.reps, r.sets, r.avg]);
    } catch (_) { /* cihaz kaydı da yoksa boş hal gösterilir */ }
  }
  if (seq !== histSeq) return;
  histList.innerHTML = "";
  if (!rows.length) {
    const d = document.createElement("div");
    d.className = "hist-empty";
    d.textContent = "no workouts yet - finish a session and it will appear here.";
    histList.appendChild(d);
  } else {
    rows.forEach((r) => histList.appendChild(histRow(r[0], r[1], r[2], r[3], r[4])));
  }
  histEl.hidden = false;
}

function render(r) {
  renderPlan(r);
  if (switching) return;   // hareket-arası geri sayım yazısını bu karenin geri kalanı ezmesin
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
    if (cue) {
      msgEl.textContent = cue;
      // yarım tekrar uyarısı = koç sesi: kocaman ve kırmızı, 1.8 sn ekranda.
      msgEl.classList.toggle("loud", r.halfTick || /go all the way down/.test(cue));
      cueUntil = performance.now() + 1800;
    } else if (performance.now() > cueUntil) { msgEl.textContent = ""; msgEl.classList.remove("loud"); }
  } else {
    subEl.textContent = "";
    msgEl.textContent = r.message || "";
    msgEl.classList.remove("loud");
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
  // sekme arkadayken ağır pose işini atla — pil ve ısı için. kamera açık kalır.
  if (document.hidden) { requestAnimationFrame(loop); return; }
  if (video.currentTime !== lastVideoTime && video.readyState >= 2) {
    lastVideoTime = video.currentTime;
    if (canvas.width !== (video.videoWidth || canvas.width)) sizeCanvas();

    const result = poseLandmarker.detectForVideo(video, performance.now());
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    let skeletonColor = "#33000E";
    if (result && result.landmarks && result.landmarks.length) {
      const lm = result.landmarks[0];

      if (engine && !switching) {
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

// seçici artık aday hareketi tutar (programa "add" ile girer); motorunkini kuyruk yönetir.
moveSel.addEventListener("change", () => { move = MOVES[moveSel.value] || MOVES.squat; });

// dinlenme süresi programın ortak ayarı — değişince kaydedilir.
planRest.addEventListener("change", () => { program.rest = readRestInput(); saveProgram(); });

// "hazırım": molayı erken bitir, sıradaki sete geç.
skipRestBtn.addEventListener("click", () => { if (engine) engine.skipRest(); });

// ── sihirbaz: 1. program kur → next → 2. kamera. geri dönüş her an var. ──
const readyBtn = $("ready"), startWrap = $("startWrap");
addMoveBtn.addEventListener("click", () => {
  program.items.push(readPlanInputs());
  program.rest = readRestInput();
  saveProgram(); renderProgram();
});
readyBtn.addEventListener("click", () => {
  if (!program.items.length) program.items.push(readPlanInputs());  // tek hareket de bir programdır
  program.rest = readRestInput();
  saveProgram(); renderProgram();
  introCard.hidden = true; progCard.hidden = true;
  startWrap.hidden = false;
  startBtn.focus();
});
backProg.addEventListener("click", () => {
  if (running) stop();
  startWrap.hidden = true;
  introCard.hidden = false; progCard.hidden = false;
});
planRest.value = program.rest;
renderProgram();

// ilk kullanım onayı (KVKK): kamera izninden ÖNCE bir kez, açık cümlelerle.
// localStorage yoksa her seferinde gösterilir — kimse habersiz kamera açmaz.
const consentEl = $("consent"), consentGo = $("consentGo");
const CONSENT_KEY = "gg_consent_v1";
function consentGiven() {
  try { return localStorage.getItem(CONSENT_KEY) === "yes"; } catch (_) { return false; }
}
startBtn.addEventListener("click", () => {
  if (!consentGiven()) { consentEl.hidden = false; consentGo.focus(); return; }
  start();
});
consentGo.addEventListener("click", () => {
  try { localStorage.setItem(CONSENT_KEY, "yes"); } catch (_) { /* yine başlar, bir daha sorulur */ }
  consentEl.hidden = true;
  start();
});
stopBtn.addEventListener("click", stop);
window.addEventListener("resize", () => { if (running) sizeCanvas(); });

// giriş değişince: bekleyen kuyruğu gönder, geçmişi o hesaptan yeniden çiz.
onAuth(() => { flushQueue(); loadHistory(); });
window.addEventListener("online", flushQueue);
window.addEventListener("gg-sessions-changed", loadHistory);   // "delete my synced workouts" sonrası

// pwa: ana ekrana kurulunca offline da açılır (sw.js dosyaları önbelleğe alır).
if ("serviceWorker" in navigator) navigator.serviceWorker.register("sw.js").catch(() => {});
