// coach.js — SADECE tutkal. Kamerayı açar, MediaPipe'ın verdiği noktaları C++
// motora (engine/motor.wasm) uzatır, motorun döndürdüğü okumayı ekrana yazar.
// Hiç analiz yok burada — açı, yumuşatma, faz hepsi C++'ta.
//
// Hız: landmark'ları her kare wasm heap'ine bir kez yazıp motora POINTER geçiyoruz
// (kare başına yüzlerce JS↔wasm sınır geçişi yerine tek çağrı).

// mediapipe VENDOR'lanmış — üçüncü taraf CDN'e runtime bağımlılık yok, offline çalışır.
import { PoseLandmarker, FaceLandmarker, HandLandmarker, FilesetResolver } from "../vendor/mediapipe/vision_bundle.mjs";
// ortak hesap: giriş yapılıysa seanslar DB'ye de gider (cihazlar arası).
import { sb, currentUser, onAuth } from "./auth.js";
// CGI görsel katmanı: dolgulu gövde/yüz/el (SADECE çizim, motora girmez).
import { drawBody, drawFace, drawHand } from "./mesh.js";

const $ = (id) => document.getElementById(id);
const statusEl = $("status");
const moveSel = $("moveSel");
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
const repCommentEl = $("repComment");   // faz 3: motorun tekrar yorumu
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

// ── ölçüm bandı kaydedicisi (hassas motor Faz 0): ?rec=1 ile açılır, normal
// kullanıcı hiç görmez. Motorun gördüğü landmark akışını aynen tutar; seans
// durunca .ggclip olarak iner, engine/bench.sh clip <dosya> ile metriklenir.
// Tek hareketli seans kaydet — başlık ilk hareketle yazılır.
const recOn = new URLSearchParams(location.search).get("rec") === "1";
let recLines = null;
function recFrame(t, lm, wl) {
  if (!recLines) return;
  const parts = [Math.round(t)];
  for (let i = 0; i < LM; i++) {
    const p = lm[i];
    if (p) parts.push((p.x * aspect).toFixed(5), p.y.toFixed(5), "0", (p.visibility ?? 1).toFixed(3));
    else parts.push("0", "0", "0", "0");
  }
  if (wl) {
    for (let i = 0; i < LM; i++) {
      const p = wl[i];
      if (p) parts.push(p.x.toFixed(5), p.y.toFixed(5), (p.z ?? 0).toFixed(5), (p.visibility ?? 1).toFixed(3));
      else parts.push("0", "0", "0", "0");
    }
  } else parts.push("-");
  recLines.push(parts.join(" "));
}
function recDownload() {
  if (!recLines || recLines.length < 2) { recLines = null; return; }
  const blob = new Blob([recLines.join("\n") + "\n"], { type: "text/plain" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = "gymgyme-" + (recLines[0].split(" ")[2] || "clip") + "-" + Date.now() + ".ggclip";
  a.click();
  URL.revokeObjectURL(a.href);
  recLines = null;
}

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
let timedAct = null;       // süreli hareket (motor saymaz, kamera izler, süre tutulur)
let timedIv = null;
let doneSummaries = [];    // her hareketin özeti; sonda toplanıp tek özet gösterilir

function saveProgram() { try { localStorage.setItem(PROG_KEY, JSON.stringify(program)); } catch (_) {} }
function moveLabel(v) { const o = [...moveSel.options].find((x) => x.value === v); return o ? o.textContent : v; }
function readPlanInputs() {
  const reps = Math.max(0, Math.min(99, parseInt(planReps.value, 10) || 0));
  const sets = Math.max(1, Math.min(20, parseInt(planSets.value, 10) || 1));
  return { move: moveSel.value, reps, sets };
}
function readRestInput() { return Math.max(0, Math.min(600, parseInt(planRest.value, 10) || 0)); }
// program artık FİŞ: her satır kendini basar, satıra dokunmak keser (Damla:
// seçilen program fiş gibi ekranda durur, sürüklenir, kapatılır).
const receiptEl = $("setReceipt"), rtabEl = $("rtab"), rtotEl = $("rtot");
function renderProgram() {
  progListEl.innerHTML = "";
  receiptEl.hidden = false;
  if (!program.items.length) {
    const e = document.createElement("p");
    e.className = "rempty";
    e.textContent = "empty - pick moves on the sign above.";
    progListEl.appendChild(e);
  } else {
    program.items.forEach((it, i) => {
      const d = document.createElement("div");
      d.className = "rline" + (running && i === progIdx ? " nowplaying" : "");
      const name = document.createElement("span");
      name.textContent = (i + 1) + ". " + (it.timed ? it.timed : moveLabel(it.move));
      const dots = document.createElement("span");
      dots.className = "dots"; dots.textContent = "................";
      const plan = document.createElement("span");
      plan.textContent = it.timed ? (it.seconds || 45) + "s" : (it.reps > 0 ? it.reps + "×" + it.sets : "free");
      d.append(name, dots, plan);
      d.title = "tap to cut this line";
      d.onclick = () => {
        if (running) return;                      // seans sırasında kuyruk sabit
        program.items.splice(i, 1); saveProgram(); renderProgram();
      };
      progListEl.appendChild(d);
      requestAnimationFrame(() => d.classList.add("printed"));
    });
  }
  rtotEl.textContent = program.items.reduce((a, it) => a + (it.timed ? 0 : (it.reps || 0) * (it.sets || 1)), 0);
}

// fiş sürüklenir (pointer), × ile kapanır, köşedeki sekmeyle geri gelir.
let rdrag = null;
receiptEl.addEventListener("pointerdown", (e) => {
  if (e.target.closest(".rline") || e.target.closest(".rclose")) return;
  rdrag = { x: e.clientX, y: e.clientY, left: receiptEl.offsetLeft, top: receiptEl.offsetTop };
  receiptEl.classList.add("dragging");
  receiptEl.setPointerCapture(e.pointerId);
});
receiptEl.addEventListener("pointermove", (e) => {
  if (!rdrag) return;
  receiptEl.style.left = rdrag.left + e.clientX - rdrag.x + "px";
  receiptEl.style.top = rdrag.top + e.clientY - rdrag.y + "px";
  receiptEl.style.right = "auto";
});
receiptEl.addEventListener("pointerup", () => { rdrag = null; receiptEl.classList.remove("dragging"); });
$("rclose").addEventListener("click", () => { receiptEl.hidden = true; rtabEl.hidden = false; });
rtabEl.addEventListener("click", () => { receiptEl.hidden = false; rtabEl.hidden = true; });

// hazır programlar: tek dokunuş, fiş komple basılır.
const PRESETS = {
  "honest beginner": ["squat", "kneelingpushup", "glutebridge", "situp"],
  "leg day, no gym": ["squat", "sumosquat", "lunge", "sidelunge", "calfraise"],
  "push day": ["pushup", "kneelingpushup", "press", "armraise"],
  "quiet apartment set": ["squat", "glutebridge", "birddog", "situp"],
  "wake the neighbors": ["jumpingjack", "squat", "pushup", "kickback"],
};
// chipler tabelanin icinde (mockup birebir): hazir programlar + SENIN playlistlerin.
// playlist = my moves'tan kaydedilen isimli set (gg_playlists, cihazda).
const PLAYLIST_KEY = "gg_playlists";
function getPlaylists() {
  try { return JSON.parse(localStorage.getItem(PLAYLIST_KEY)) || []; } catch (_) { return []; }
}
// motorun izleyebildigi hareketler: gorunmez select'teki 14 etiket -> anahtar
const ENGINE_BY_NAME = {};
for (const o of moveSel.options) ENGINE_BY_NAME[o.textContent.trim().toLowerCase()] = o.value;
function printItems(items) {
  program.items = items;
  saveProgram(); renderProgram();
}
function renderChips() {
  const wrap = $("progBtns");
  if (!wrap) return;
  wrap.innerHTML = "";
  for (const [name, moves] of Object.entries(PRESETS)) {
    const b = document.createElement("button");
    b.type = "button"; b.textContent = name;
    b.onclick = () => printItems(moves.map((m) => ({ move: m, reps: 10, sets: 3 })));
    wrap.appendChild(b);
  }
  for (const pl of getPlaylists()) {
    const b = document.createElement("button");
    b.type = "button"; b.className = "plchip"; b.textContent = "\u2661 " + pl.name;
    b.onclick = () => {
      printItems((pl.moves || []).map((m) => {
        const key = ENGINE_BY_NAME[String(m).trim().toLowerCase()];
        return key ? { move: key, reps: 10, sets: 3 } : { timed: m, seconds: 45 };
      }));
    };
    wrap.appendChild(b);
  }
}
renderChips();
window.addEventListener("gg-playlists-changed", renderChips);
window.addEventListener("storage", renderChips);

// arama: SECILI programin ustune ek hareket - fise direkt basar (mockup birebir).
// durustluk siniri: sadece motorun izleyebildigi hareketler onerilir.
const trainSearch = $("trainSearch"), trainSuggest = $("trainSuggest");
if (trainSearch && trainSuggest) {
  trainSearch.addEventListener("input", () => {
    const v = trainSearch.value.trim().toLowerCase();
    trainSuggest.innerHTML = "";
    if (v) {
      const add = (label, note, item) => {
        const d = document.createElement("div");
        d.className = "tr";
        const nm = document.createElement("span"); nm.textContent = label;
        const sm = document.createElement("small"); sm.textContent = note;
        d.append(nm, sm);
        d.addEventListener("click", () => {
          program.items.push(item);
          saveProgram(); renderProgram();
          trainSearch.value = ""; trainSuggest.classList.remove("open");
        });
        trainSuggest.appendChild(d);
      };
      // once motorun izledigi hareketler: rep-based sayar, hold-based sure tutar
      // (durustluk: her biri kendi dogru etiketiyle gelir).
      for (const o of [...moveSel.options].filter((o) => o.textContent.toLowerCase().includes(v)).slice(0, 5)) {
        const isHold = HOLD_MOVES.has(o.value);
        add(o.textContent, isHold ? "coached hold · add" : "counts reps · add",
          isHold ? { move: o.value, reps: 30, sets: 1 } : { move: o.value, reps: 10, sets: 3 });
      }
      // sonra kutuphanenin tamami: kamera izler, SURE tutar — sayiyorum numarasi yok
      if (typeof MOVE_DB !== "undefined") {
        const engineNames = new Set([...moveSel.options].map((o) => o.textContent.toLowerCase()));
        for (const [cat, list] of Object.entries(MOVE_DB)) {
          for (const m of list) {
            if (trainSuggest.children.length >= 9) break;
            if (!m.includes(v) || engineNames.has(m)) continue;
            add(m, cat + " · timed · add", { timed: m, seconds: 45 });
          }
        }
      }
    }
    trainSuggest.classList.toggle("open", trainSuggest.children.length > 0);
  });
  document.addEventListener("click", (e) => {
    if (!e.target.closest(".tsw")) trainSuggest.classList.remove("open");
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
  // ── HOLD (izometrik) hareketler: faz kelimesi yok, "tutuyorsun" dili. motor
  // rep saymaz, hedef bantta geçen SÜRE + kararlılık ölçer. ──
  plank:          { joint: "body line", hold: true },
  sideplank:      { joint: "body line", hold: true },
  wallsit:        { joint: "knee",      hold: true },
  hollowhold:     { joint: "body line", hold: true },
  superman:       { joint: "back line", hold: true },
};
// hangi hareketler HOLD (süre-tabanlı): search etiketi + plan dili buna bakar.
const HOLD_MOVES = new Set(Object.keys(MOVES).filter((k) => MOVES[k].hold));
// kuralı olan hold'lar gerçek "kalite" ölçer (form kapısı var); kuralsızlar
// (superman) yalnız pozisyonda-kalma ölçer — dürüstlük: ölçemediğin formu
// "kalite" diye satma (Pilates Princess jüri dersi). Bu son grup "in position".
const HOLD_POSITION_ONLY = new Set(["superman"]);
// bel yükleyen hareketler: kötü bel için modifiye/atla uyarısı (Pilates güvenlik jüri).
const LUMBAR_LOAD = new Set(["situp", "superman", "hollowhold", "glutebridge"]);
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
let aspect = 1;
let faceLandmarker = null, handLandmarker = null;   // görsel ağ katmanı
// ── CGI KATMANI (15 tem gece, Damla: "beni adet iskelet gibi gösteriyor,
// parmaklarım 3 dallı ağaç, dudağım bir çizgi — cgi gibi olsun"). İki parça:
//   (1) GÖVDE dolgusu (mesh.js drawBody): poz noktalarından türer, EKSTRA MODEL
//       YOK, bedava — çöp-adamı hacimli figüre çevirir. Hep açık.
//   (2) YÜZ + EL mesh (ekstra iki model): kavisli dudak/göz + dolgulu parmaklar.
//       fps'i koruyoruz — düşük fps ölçülürse otomatik uykuya alınır (Damla'nın
//       telefon fps dersi). MESH_FACE_HANDS=false yaparsan hiç yüklenmez. ──
const MESH_FACE_HANDS = true;
let meshFaceHandsSleep = false;   // fps düşükse yüz/el mesh'i geçici kapat (gövde kalır)
let rebuildingPose = false;   // canlı kurtarma sürerken ikinci kez kurma
let lastFace = null, lastHands = null;              // atlanan karede son sonuç çizilir
let meshFrame = 0;                                  // yüz/el her 2 karede bir koşar (fps)
let frames = 0, fps = 0, fpsClock = 0;
let angleRows = null;          // textContent ile güncellenen satırlar

const stageStatusEl = $("stageStatus");
const setStatus = (m) => {
  statusEl.textContent = m;
  if (stageStatusEl) stageStatusEl.textContent = m;   // sahne kutusu da konuşur
};

// gören model: MediaPipe pose (kendisi de c++/wasm, gpu'da, cihazda).
let visionFileset = null;
let segOn = false;   // siluet maskesi aktif mi (kurulumda karar verilir)
async function makePose(vision, model, seg) {
  return PoseLandmarker.createFromOptions(vision, {
    baseOptions: { modelAssetPath: "vendor/models/pose_landmarker_" + model + ".task", delegate: "GPU" },
    runningMode: "VIDEO",
    numPoses: 2,   // Faz 2: kadraja ikinci kişi girerse motor KİMİ izleyeceğini kendi seçer
    outputSegmentationMasks: seg
  });
}
async function loadPose() {
  setStatus("loading the pose model (first time only, then cached)...");
  const vision = await FilesetResolver.forVisionTasks("vendor/mediapipe/wasm");
  visionFileset = vision;
  // ── KADEMELİ AÇILIŞ (15 tem "kamera açılmıyor" dersi): siluet ya da full
  // model bazı GPU'larda kurulumu düşürebiliyor — kamera SÜSTEN önce gelir.
  // full+siluet → full → lite sırasıyla dener; hangisi tutarsa onunla açılır. ──
  const attempts = [
    { model: "full", seg: true },
    { model: "full", seg: false },
    { model: "lite", seg: false },
  ];
  let lastErr = null;
  poseLandmarker = null;
  for (const a of attempts) {
    try {
      poseLandmarker = await makePose(vision, a.model, a.seg);
      segOn = a.seg;
      break;
    } catch (e) {
      lastErr = e;
      console.warn("pose init failed (" + a.model + ", seg=" + a.seg + "):", e);
    }
  }
  if (!poseLandmarker) throw lastErr;
  // ── yüz/el mesh katmanı: kavisli dudak/göz + dolgulu parmaklar. gövde dolgusu
  // (mesh.js drawBody) buna gerek duymaz, pozdan bedava gelir — bu iki model
  // sadece yüz+el detayı için. fps düşükse çizim döngüsü bunları uykuya alır. ──
  if (MESH_FACE_HANDS) {
    try {
      faceLandmarker = await FaceLandmarker.createFromOptions(vision, {
        baseOptions: { modelAssetPath: "vendor/models/face_landmarker.task", delegate: "GPU" },
        runningMode: "VIDEO",
        numFaces: 1
      });
      handLandmarker = await HandLandmarker.createFromOptions(vision, {
        baseOptions: { modelAssetPath: "vendor/models/hand_landmarker.task", delegate: "GPU" },
        runningMode: "VIDEO",
        numHands: 2
      });
    } catch (e) {
      console.warn("mesh layer not loaded (skeleton still works):", e);
      faceLandmarker = null; handLandmarker = null;
    }
  }
}

// düşünen beyin: bizim c++ motorumuz, wasm'a derli. yoksa iskelet yine görünür.
async function loadEngine() {
  try {
    const { default: createMotor } = await import("../engine/motor.js");
    motorMod = await createMotor();
    engine = new motorMod.Engine(moveSel.value);
    engine.setCalibration(true);   // önce vücudu öğren, sonra ona kilitlen
    bufPtr = motorMod._malloc(2 * FLOATS * 4);        // 4 byte/float, 2 poz (Faz 2)
    worldBufPtr = motorMod._malloc(2 * FLOATS * 4);
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
function clearTimedAct() {
  timedAct = null;
  if (timedIv) { clearInterval(timedIv); timedIv = null; }
}
function loadItem(i) {
  progIdx = i;
  const it = program.items[i];
  clearTimedAct();
  sessionLogged = false; wasComplete = false; nudgeShownFor = "";
  repCountEl.textContent = "0"; halfNoteEl.textContent = ""; scoreLineEl.textContent = ""; msgEl.textContent = "";
  if (repCommentEl) { repCommentEl.textContent = ""; commentUntil = 0; }
  setLineEl.hidden = true; restEl.hidden = true;

  if (it.timed) {
    // ── süreli hareket: motorun spec'i yok — kamera seni izler, süreyi BEN tutarım.
    // dürüstlük: sayamadığım şeyi sayıyormuş gibi yapmam; iskelet/siluet çizilir. ──
    timedAct = { name: it.timed, remaining: it.seconds || 45 };
    phaseWord.textContent = it.timed;
    subEl.textContent = "you do it - i keep the time: " + timedAct.remaining + "s";
    setStatus("act " + (i + 1) + " of " + program.items.length + ": " + it.timed + " (timed)");
    renderProgram();
    timedIv = setInterval(() => {
      if (!running || !timedAct) { clearTimedAct(); return; }
      timedAct.remaining--;
      if (timedAct.remaining > 0) {
        subEl.textContent = "you do it - i keep the time: " + timedAct.remaining + "s";
      } else {
        clearTimedAct();
        beep(880, 0.12, 0.09);
        if (progIdx < program.items.length - 1) advanceMove();
        else { setStatus("that was the last act - take a bow."); stop(); }
      }
    }, 1000);
    return;
  }

  moveSel.value = it.move;
  move = MOVES[it.move] || MOVES.squat;
  if (engine) { engine.setMove(it.move); applyPlan(); buildAngleRows(); }
  setStatus("move " + (i + 1) + " of " + program.items.length + ": " + moveLabel(it.move));
  // bel yükleyen harekette bir kez güvenlik notu (Pilates jüri: fragile back).
  if (LUMBAR_LOAD.has(it.move) && msgEl) {
    msgEl.textContent = "this move loads your lower back - skip or keep it small if you have back pain";
    msgEl.classList.remove("loud");
    cueUntil = performance.now() + 4000;
  }
  renderProgram();   // fişte sıradaki satır işaretlenir
}

// biten hareketten sıradakine: 5 sn "next up" arası, motor o sırada dinlenir.
function advanceMove() {
  switching = true;
  const next = program.items[progIdx + 1];
  let n = 5;
  phaseWord.textContent = "next: " + (next.timed || moveLabel(next.move));
  subEl.textContent = "get in position - starting in " + n + "...";
  const iv = setInterval(() => {
    if (!running) { clearInterval(iv); switching = false; return; }
    n--;
    if (n <= 0) { clearInterval(iv); loadItem(progIdx + 1); switching = false; }
    else subEl.textContent = "get in position - starting in " + n + "...";
  }, 1000);
}

async function start() {
  // kurulum çekilir; sahne kutusu GİZLENMEZ, ısınma moduna geçer (15 tem dersi:
  // modeller inerken ekran ölü görünüyordu, "açılmıyor" hissi veriyordu).
  introCard.hidden = true; progCard.hidden = true; consentEl.hidden = true;
  if (camstageEl) {
    camstageEl.hidden = false;
    camstageEl.classList.add("warming");
    const b = camstageEl.querySelector("b");
    if (b) b.textContent = "warming up the stage...";
  }
  startWrap.hidden = false;
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
    if (camstageEl) { camstageEl.hidden = true; camstageEl.classList.remove("warming"); }
    stage.hidden = false;
    privateNote.hidden = false;
    stopBtn.hidden = false;
    sizeCanvas();
    document.body.classList.add("running");   // kamera sahnesi: video ortada ve kocaman, kurulum çekilir
    loadItem(0);
    setStatus("i can see you - move 1 of " + program.items.length + ": " +
      moveLabel(program.items[0].move) + ". stand back so your whole body fits.");
    if (recOn) recLines = ["ggclip 1 " + (program.items[0] ? program.items[0].move : moveSel.value)];
    running = true;
    frames = 0; fps = 0; fpsClock = performance.now();
    requestAnimationFrame(loop);
  } catch (e) {
    setStatus("could not start the camera: " + (e && e.message ? e.message : e));
    document.body.classList.remove("running");
    startWrap.hidden = true;
    introCard.hidden = false; progCard.hidden = false;   // kurulum geri gelsin, tekrar denesin
    if (camstageEl) {
      camstageEl.hidden = false;
      camstageEl.classList.remove("warming");
      const b = camstageEl.querySelector("b");
      if (b) b.textContent = "that did not work - tap to try again";
    }
  }
}

function stop() {
  running = false;
  switching = false;
  clearTimedAct();
  recDownload();   // kayıt açıksa klibi indir (Faz 0 ölçüm bandı)
  document.body.classList.remove("running");
  const s = video.srcObject;
  if (s) s.getTracks().forEach((t) => t.stop());
  video.srcObject = null;
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  // yarıda durdurulan hareketin sayılmış tekrarları (ya da tutulan süresi) kaybolmasın
  if (engine && !sessionLogged) {
    const cur = engine.summary();
    if (cur && (cur.reps > 0 || (cur.isHold && cur.heldSeconds > 0))) {
      doneSummaries.push({ move: moveSel.value, s: cur }); logSession(cur);
    }
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
  // kurulum geri gelsin: özet üstte, altında yeni workout kurabilir
  startWrap.hidden = true;
  introCard.hidden = false; progCard.hidden = false;
  if (camstageEl) {
    camstageEl.hidden = false;
    camstageEl.classList.remove("warming");
    const b = camstageEl.querySelector("b");
    if (b) b.textContent = "the stage goes here";
  }
  setStatus("stopped. the camera is off.");
  renderProgram();   // vurgu söner, satır kesme geri açılır
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

// ── motorun sesi VİDEONUN ÜSTÜNE (15 tem, Damla: "uyarmıyor bile"): neden
// saymadığını artık sahnede görürsün — mesajlar alttaki panelde saklanmaz. ──
function drawBanner(text) {
  if (!text) return;
  const W = canvas.width;
  ctx.save();
  let size = Math.max(16, Math.round(W / 28));
  ctx.font = "bold " + size + "px Arial";
  while (ctx.measureText(text).width > W - 60 && size > 12) {
    size -= 2;
    ctx.font = "bold " + size + "px Arial";
  }
  const tw = ctx.measureText(text).width;
  const pad = 14, h = size + pad * 1.4, x = (W - tw) / 2 - pad, y = 18;
  ctx.fillStyle = "rgba(110, 0, 48, 0.82)";
  ctx.beginPath();
  ctx.roundRect(x, y, tw + pad * 2, h, 12);
  ctx.fill();
  ctx.fillStyle = "#FFDCE9";
  ctx.textBaseline = "middle";
  ctx.fillText(text, x + pad, y + h / 2 + 1);
  ctx.restore();
}

// ── "iskelet değil vücut" (Damla, 15 tem): poz modelinin siluet maskesi vücudun
// GERÇEK konturunu verir — omuz, kol, bel kavisleri. İskeletin altına yumuşak
// vişne ışıltısı olarak çizilir; motoru hiç ilgilendirmez, çizilemezse atlanır. ──
let silCanvas = null, silCtx = null;
function drawSilhouette(mask) {
  try {
    const src = mask.canvas || null;
    if (!src) return;
    if (!silCanvas) { silCanvas = document.createElement("canvas"); silCtx = silCanvas.getContext("2d"); }
    if (silCanvas.width !== canvas.width || silCanvas.height !== canvas.height) {
      silCanvas.width = canvas.width; silCanvas.height = canvas.height;
    }
    silCtx.clearRect(0, 0, silCanvas.width, silCanvas.height);
    silCtx.drawImage(src, 0, 0, silCanvas.width, silCanvas.height);
    silCtx.globalCompositeOperation = "source-in";
    silCtx.fillStyle = "rgba(166, 27, 66, 0.18)";
    silCtx.fillRect(0, 0, silCanvas.width, silCanvas.height);
    silCtx.globalCompositeOperation = "source-over";
    ctx.drawImage(silCanvas, 0, 0);
  } catch (_) { /* siluet süs — düşerse iskelet ve sayaç yaşar */ }
}

// ── CGI hissi (Damla, 15 tem): iskelet düz 2D değil, derinlik-kodlu çizilir.
// Dedektör her noktanın z'sini zaten tahmin ediyor; yakın uzuv KALIN ve DOLGUN,
// arkadaki İNCE ve SOLUK. Uzak segmentler önce çizilir, yakınlar üstüne biner —
// kolun gövdenin önünde mi arkasında mı olduğu artık ekranda okunur. ──
function drawSkeleton3D(lm, zsrc, color) {
  const zs = zsrc || lm;
  const W = canvas.width, H = canvas.height;
  const depth = (i) => {
    const z = zs[i] ? (zs[i].z ?? 0) : 0;
    return Math.max(0, Math.min(1, 0.5 - z));   // z ~ [-0.5..0.5] → 0 uzak, 1 yakın
  };
  const segs = [];
  for (const c of PoseLandmarker.POSE_CONNECTIONS) {
    const a = lm[c.start], b = lm[c.end];
    if (!a || !b || (a.visibility ?? 1) < 0.4 || (b.visibility ?? 1) < 0.4) continue;
    segs.push({ a, b, t: (depth(c.start) + depth(c.end)) / 2 });
  }
  segs.sort((s1, s2) => s1.t - s2.t);   // uzak önce: yakın uzuv üstte kalır
  ctx.lineCap = "round";
  for (const s of segs) {
    ctx.globalAlpha = 0.35 + 0.65 * s.t;
    ctx.strokeStyle = color;
    ctx.lineWidth = 2 + 5 * s.t;
    ctx.beginPath();
    ctx.moveTo(s.a.x * W, s.a.y * H);
    ctx.lineTo(s.b.x * W, s.b.y * H);
    ctx.stroke();
  }
  for (let i = 0; i < lm.length; i++) {
    const p = lm[i];
    if (!p || (p.visibility ?? 1) < 0.4) continue;
    const t = depth(i);
    ctx.globalAlpha = 0.4 + 0.6 * t;
    ctx.fillStyle = color;
    ctx.strokeStyle = "#FFFFFF";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(p.x * W, p.y * H, 3 + 3.5 * t, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
  }
  ctx.globalAlpha = 1;
}

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
// ── count-up: sayılar anlık zıplamaz, hedefe doğru YUMUŞAK sayar (Damla'nın
// premium-akıcı standardı; Pilatess: hard-swap gym-timer hissi). Gösterilen
// değeri her karede hedefe biraz yaklaştırır. ──
const counters = {};   // el -> {shown, target}
function countTo(el, target) {
  if (!el) return;
  let c = counters[el.id];
  if (!c) { c = counters[el.id] = { shown: target, target }; el.textContent = String(target); return; }
  c.target = target;
  // ani büyük düşüş (reset) anında otur; artışta yumuşak say
  if (target < c.shown) { c.shown = target; el.textContent = String(target); return; }
  const step = Math.max(1, (c.target - c.shown) * 0.28);
  c.shown = Math.min(c.target, c.shown + step);
  const disp = Math.round(c.shown);
  if (el.textContent !== String(disp)) el.textContent = String(disp);
}
// ── did-you-mean nudge: motor kendi tahmin ettiği hareket (detectedMove) seçili
// olandan farklı ve güvenliyse, kullanıcıya BİR KEZ nazikçe önerir. Motor izliyor
// ve anlıyor — ama karar kullanıcının, o yüzden dayatmaz, sadece nudge. ──
let nudgeShownFor = "";   // hangi hareket seçiliyken nudge gösterildi (tekrar etmesin)
let nudgeUntil = 0;       // nudge'ın subEl'de kalma süresi (form cue'dan ayrı slot)
// motorun kısa adlarını insan diline çevir (öneri cümlesi için).
const MOVE_HUMAN = {
  squat: "a squat", lunge: "a lunge", pushup: "a push-up", press: "a press",
  glutebridge: "a glute bridge", situp: "a sit-up", jumpingjack: "jumping jacks",
  armraise: "arm raises", plank: "a plank", wallsit: "a wall sit", superman: "a superman",
};
let commentUntil = 0;   // faz 3: tekrar yorumunun ekranda kalma süresi
let wasComplete = false;   // antrenman-bitti sesini bir kez çalmak için

// planlı akışın görünümü: set satırı, dinlenme bloğu, bitti hali. serbest modda
// (targetReps=0) hiçbiri görünmez, sayfa bugünküyle aynı kalır.
function renderPlan(r) {
  if (r.setTick && !r.workoutComplete) setChime();
  if (r.workoutComplete && !wasComplete) {
    doneChime();
    wasComplete = true;
    const s = engine ? engine.summary() : null;
    // rep hareketinde reps, hold hareketinde tutulan süre "yapıldı" sayılır.
    if (s && (s.reps > 0 || (s.isHold && s.heldSeconds > 0))) {
      doneSummaries.push({ move: moveSel.value, s }); logSession(s);
    }
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
  // HOLD planında hedef SANİYE (rep değil): set satırı süre bazlı yazılır,
  // yoksa "0 of 30 reps" gibi kırık görünürdü (motor hold'da rep saymaz).
  if (r.isHold) {
    const held = Math.floor(r.heldSeconds || 0);
    if (r.workoutComplete) {
      setLineEl.textContent = "hold complete - " + r.totalSets + " set" + (r.totalSets > 1 ? "s" : "") + " of " + r.targetReps + "s";
    } else if (r.resting) {
      setLineEl.textContent = "set " + r.currentSet + " of " + r.totalSets + " held";
    } else {
      setLineEl.textContent = "set " + r.currentSet + " of " + r.totalSets +
        "   ·   " + held + "s of " + r.targetReps + "s";
    }
    return;
  }
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
  // rep hareketi reps>0 ise, hold hareketi süre tutulduysa kaydedilir.
  if (sessionLogged || !s || (s.reps === 0 && !(s.isHold && s.heldSeconds > 0))) return;
  sessionLogged = true;
  // her zaman cihaza yaz: offline çalışsın + dizin takvimi bugünü yansıtsın.
  try {
    const list = JSON.parse(localStorage.getItem(SESS_KEY)) || [];
    // hold seansında "reps" yerine tutulan saniyeyi yaz (geçmişte anlamlı görünsün).
    const repsVal = s.isHold ? Math.round(s.heldSeconds || 0) : s.reps;
    list.push({ move: moveSel.value, reps: repsVal, sets: s.setsCompleted, avg: s.isHold ? s.holdQualityPct : s.avgScore, hold: !!s.isHold, date: isoToday(), t: Date.now() });
    localStorage.setItem(SESS_KEY, JSON.stringify(list.slice(-50)));
    const days = JSON.parse(localStorage.getItem(DAYS_KEY)) || [];
    if (!days.includes(isoToday())) { days.push(isoToday()); localStorage.setItem(DAYS_KEY, JSON.stringify(days)); }
  } catch (_) { /* localStorage yoksa seans yine görünür, sadece kaydedilmez */ }
  const u = currentUser();
  if (!sb || !u) { setSyncState("local"); return; }
  // created_at'i biz koyuyoruz: satır kuyruğa düşüp yarın gönderilse bile
  // seansın gerçek zamanı korunur.
  // hold seansı mevcut şemaya sığar: reps = tutulan saniye, avg_score = hold
  // kalitesi. yeni kolon eklemeden geçmiş/istatistik anlamlı kalır.
  const row = {
    move: moveSel.value, reps: s.isHold ? Math.round(s.heldSeconds || 0) : s.reps, sets: s.setsCompleted,
    avg_score: s.isHold ? s.holdQualityPct : s.avgScore, best_score: s.bestScore, clean_reps: s.cleanReps,
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
    // HOLD hareketi: "reps" değil tutulan SÜRE (motor süreyi ölçtü).
    if (s.isHold) {
      const held = Math.round(s.heldSeconds || 0), bestHold = Math.round(s.bestHoldSeconds || 0);
      perMove.push(moveLabel(d.move) + " - held " + held + "s" +
        (bestHold > 0 ? " (best streak " + bestHold + "s)" : "") +
        (s.holdQualityPct >= 0 ? ", quality " + s.holdQualityPct : ""));
    } else {
      perMove.push(moveLabel(d.move) + " - " + s.reps + " reps" + (s.avgScore >= 0 ? ", avg " + s.avgScore : ""));
    }
  }
  const mins = Math.floor(dur / 60), secs = Math.round(dur % 60);
  const time = mins > 0 ? mins + " min " + secs + "s" : secs + "s";
  const lines = [];
  const allHold = doneSummaries.every((d) => d.s.isHold);
  if (allHold) {
    // hold-only seans: baş satır süre der, tek hareket olsa da dökümü göster.
    const totalHeld = Math.round(doneSummaries.reduce((a, d) => a + (d.s.heldSeconds || 0), 0));
    lines.push("held for " + totalHeld + "s total, in " + time + ".");
    perMove.forEach((l) => lines.push(l));
  } else {
    lines.push(reps + " reps" + (sets > 0 ? " across " + sets + " sets" : "") + ", in " + time + ".");
    if (doneSummaries.length > 1) perMove.forEach((l) => lines.push(l));
  }
  if (wn > 0) lines.push("they averaged " + Math.round(wsum / wn) + " out of 100, your best was " + best + ".");
  if (clean > 0) lines.push(clean + " came with clean form.");
  if (half > 0) lines.push(half + " did not count - go all the way down next time.");
  // sol-sağ denge (fizyo/klinik değer): belirgin telafi varsa raporla.
  {
    let asymSum = 0, asymN = 0;
    for (const d of doneSummaries) if (d.s.avgAsymmetry >= 0) { asymSum += d.s.avgAsymmetry; asymN++; }
    if (asymN > 0) {
      const a = Math.round(asymSum / asymN);
      if (a > 12) lines.push("your left and right sides differed by about " + a + "° on average - one side is compensating.");
      else lines.push("your left and right sides stayed balanced (within " + a + "°).");
    }
  }
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

  // ── HOLD modu: rep sayısı yerine TUTULAN SÜRE + kararlılık. motor izometrik
  // tutuşu gerçekten koçluyor (aptal kronometre değil): bantta mısın, ne kadar
  // tuttun, ne kadar temiz. ──
  if (r.isHold) {
    const secs = Math.floor(r.heldSeconds || 0);
    countTo(repCountEl, secs);   // saniye yumuşak sayar
    halfNoteEl.textContent = "seconds held";
    if (r.inHold) {
      // nefes hatırlatması (Pilates jüri / güvenlik): tutuşta Valsalva = tansiyon
      // fırlar, tehlikeli. ~her 6 sn'de "keep breathing" rotasyonu.
      const held = Math.floor(r.heldSeconds || 0);
      phaseWord.textContent = (held > 0 && held % 6 < 3) ? "keep breathing - don't hold your breath" : "holding - steady";
      if (r.repTick) { repTick(); }   // banda ilk girişte tık
    } else {
      phaseWord.textContent = r.heldSeconds > 0 ? "get back into the hold" : "get into position";
    }
    const q = Math.round((r.holdQuality || 0) * 100);
    scoreLineEl.innerHTML = "";
    if (r.heldSeconds > 0.5) {
      const b = document.createElement("span");
      // kuralsız hold (superman): "in position" — ölçemediğimiz formu kalite diye
      // satmayız; kurallı hold'larda gerçek "hold quality".
      b.className = "big";
      b.textContent = (HOLD_POSITION_ONLY.has(moveSel.value) ? "in position " : "hold quality ") + q;
      scoreLineEl.appendChild(b);
    }
    if (r.formCue) { msgEl.textContent = r.formCue; msgEl.classList.add("loud"); }
    else if (r.message) { msgEl.textContent = r.message; msgEl.classList.remove("loud"); }
    else { msgEl.textContent = ""; msgEl.classList.remove("loud"); }
    depthFill.style.width = Math.round((r.holdQuality || 0) * 100) + "%";
    confFill.style.width = Math.round((r.confidence || 0) * 100) + "%";
    framingFill.style.width = Math.round((r.framing || 0) * 100) + "%";
    if (angleRows) {
      angleRows.tracked.textContent = r.tracking ? Math.round(r.smoothAngle) + "°" : "–";
      angleRows.knee.textContent = deg(r.leftKnee) + "  /  " + deg(r.rightKnee);
      angleRows.hip.textContent = deg(r.leftHip) + "  /  " + deg(r.rightHip);
      angleRows.elbow.textContent = deg(r.leftElbow) + "  /  " + deg(r.rightElbow);
    }
    return;
  }

  phaseWord.textContent = phraseFor(r);
  countTo(repCountEl, r.reps);   // rep sayısı yumuşak sayar (premium akıcı his)
  if (r.repTick) {
    repTick();
    // faz 3: koç her tekrardan sonra cümle kurar; ~4 sn ekranda kalır
    if (r.repComment && repCommentEl) {
      repCommentEl.textContent = r.repComment;
      commentUntil = performance.now() + 4000;
    }
  }
  if (repCommentEl && performance.now() > commentUntil) repCommentEl.textContent = "";
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

  // ── did-you-mean nudge: motor başka bir hareket görüyorsa (yüksek güven,
  // henüz tekrar sayılmadı) bir kez nazikçe sor. Dayatmaz — karar kullanıcının. ──
  // did-you-mean nudge: motor başka hareket görüyorsa (reps<=1, yüksek güven)
  // bir kez öner. AYRI SLOT (subEl) — form cue'yu (msgEl) ezmez, çakışmaz
  // (Pilatess jüri dersi). reps<=1: ilk tekrar sayıldıysa da hâlâ yakalar.
  const sel = moveSel.value;
  let nudgeActive = false;
  if (r.tracking && r.reps <= 1 && !r.isHold &&
      r.detectedMove && r.detectedMove !== sel && r.detectedConfidence > 0.72 &&
      MOVE_HUMAN[r.detectedMove] && nudgeShownFor !== sel) {
    nudgeShownFor = sel;
    nudgeUntil = performance.now() + 3500;
  }
  nudgeActive = performance.now() < nudgeUntil && !r.isHold;

  if (r.tracking) {
    if (nudgeActive) {
      subEl.textContent = "that looks like " + (MOVE_HUMAN[r.detectedMove] || "another move") + " - switch? tap the move above";
    } else {
      subEl.textContent =
        move.joint + " " + Math.round(r.smoothAngle) + "°   ·   moving " + r.motion + "   ·   phase " + r.phase +
        (r.view !== "unknown" ? "   ·   view " + r.view : "");
    }
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

    let result = null;
    try {
      result = poseLandmarker.detectForVideo(video, performance.now());
    } catch (err) {
      // canli kurtarma: siluet aciksa onsuz, degilse lite modelle yeniden kur
      console.warn("pose detect failed, rebuilding:", err);
      if (!rebuildingPose && visionFileset) {
        rebuildingPose = true;
        const nextSeg = false, nextModel = segOn ? "full" : "lite";
        makePose(visionFileset, nextModel, nextSeg).then((p) => {
          poseLandmarker = p; segOn = nextSeg; rebuildingPose = false;
        }).catch(() => { rebuildingPose = false; });
      }
      requestAnimationFrame(loop);
      return;
    }
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    if (result && result.segmentationMasks && result.segmentationMasks.length) {
      drawSilhouette(result.segmentationMasks[0]);
      for (const m of result.segmentationMasks) { try { m.close(); } catch (_) {} }
    }

    let skeletonColor = "#33000E";
    let stageBanner = "";
    if (!result || !result.landmarks || !result.landmarks.length) {
      stageBanner = "i can't see anyone - step back and check your light";
    }
    if (result && result.landmarks && result.landmarks.length) {
      let drawLm = result.landmarks[0];   // motor yoksa ham ilk poz çizilir
      let rawPicked = result.landmarks[0];   // derinlik (z) kaynağı: hep ham dedektör

      if (engine && !switching && !timedAct) {
        // Faz 2: TÜM pozları (en fazla 2) heap'e ardışık bloklar halinde yaz;
        // motor izlediği vücudu kendi seçer (kalibre oran + son kare benzerliği) —
        // kadraja giren ikinci kişi iskeleti çalamaz. x aspect ile ölçekli ki açı
        // bozulmasın. İkinci buffer: MediaPipe DÜNYA koordinatları (metrik 3B).
        const heap = motorMod.HEAPF32;
        const n = Math.min(result.landmarks.length, 2);
        for (let pIdx = 0; pIdx < n; pIdx++) {
          const lm = result.landmarks[pIdx];
          const base = (bufPtr >> 2) + pIdx * FLOATS;
          for (let i = 0; i < LM; i++) {
            const p = lm[i];
            heap[base + i * 4]     = p ? p.x * aspect : 0;
            heap[base + i * 4 + 1] = p ? p.y : 0;
            heap[base + i * 4 + 2] = 0;
            heap[base + i * 4 + 3] = p ? (p.visibility ?? 1) : 0;
          }
        }
        let wn = 0;
        if (result.worldLandmarks && result.worldLandmarks.length) {
          wn = Math.min(result.worldLandmarks.length, n);
          for (let pIdx = 0; pIdx < wn; pIdx++) {
            const wl = result.worldLandmarks[pIdx];
            const wbase = (worldBufPtr >> 2) + pIdx * FLOATS;
            for (let i = 0; i < LM; i++) {
              const p = wl[i];
              heap[wbase + i * 4]     = p ? p.x : 0;
              heap[wbase + i * 4 + 1] = p ? p.y : 0;
              heap[wbase + i * 4 + 2] = p ? (p.z ?? 0) : 0;
              heap[wbase + i * 4 + 3] = p ? (p.visibility ?? 1) : 0;
            }
          }
        }
        const r = engine.updateMultiPtr(bufPtr, FLOATS, n, worldBufPtr, FLOATS, wn, performance.now());
        // sahne bandı: kalibrasyon ilerlemesi > görememe sebebi > form uyarısı
        if (r.calibrating) stageBanner = "learning your body... " + Math.round(r.calibProgress * 100) + "%";
        else if (!r.tracking && r.message) stageBanner = r.message;
        else if (r.formCue) stageBanner = r.formCue;
        else stageBanner = "";
        const picked = Math.max(0, Math.min(r.pickedPose || 0, result.landmarks.length - 1));
        drawLm = result.landmarks[picked];
        rawPicked = result.landmarks[picked];
        if (recLines) recFrame(performance.now(), drawLm,
          result.worldLandmarks && result.worldLandmarks[picked]);
        if (r.tracking) skeletonColor = r.phase === "bottom" ? "#A61B42" : "#33000E";
        // Faz 2: ekrana ham dedektör değil motorun YUMUŞATILMIŞ iskeleti çizilir
        // (nokta başına one euro; x motor tarafında aspect ölçekliydi, geri böl).
        if (r.tracking && engine.smoothPoseOk()) {
          const sbase = engine.smoothPosePtr() >> 2;
          const smoothHeap = motorMod.HEAPF32;   // heap update sonrası büyümüş olabilir
          const sm = new Array(LM);
          for (let i = 0; i < LM; i++) {
            sm[i] = {
              x: smoothHeap[sbase + i * 4] / aspect,
              y: smoothHeap[sbase + i * 4 + 1],
              z: 0,
              visibility: smoothHeap[sbase + i * 4 + 3],
            };
          }
          drawLm = sm;
        }
        render(r);
      }

      // ── CGI gövde: önce DOLU figür (derinlik-gölgeli hacim), sonra üstüne ince
      // iskelet omurgası. Damla "adet iskelet" demişti — artık dolu bir vücut,
      // iskelet sadece onun üstünde okunur bir çizgi. Konum yumuşatılmış pozdan
      // (drawLm), derinlik ham dedektörden (rawPicked, z var). ──
      // CV AĞ tek dil: parlak nokta-düğüm + ışıltılı ip örgüsü (mesh.js drawBody).
      // eski çöp-adam iskeleti (drawSkeleton3D) KALDIRILDI — Pilatess: iki iskelet
      // üst üste = gürültü, "not a stick figure" hedefini bozuyordu. ağ tek başına.
      drawBody(ctx, drawLm, rawPicked, canvas.width, canvas.height);
      drawBanner(stageBanner);

      // ── CGI yüz + el mesh: dolgulu deri + kavisli dudak/göz/kaş + gerçek
      // dolgulu parmaklar (mesh.js). fps koruması: 20'nin altına düşerse yüz/el
      // modelleri uykuya alınır — gövde dolgusu + iskelet zaten akıcı kalır. ──
      if (faceLandmarker && handLandmarker && !meshFaceHandsSleep) {
        meshFrame++;
        // yüz/el mesh her 2 karede bir algılanır (fps). Pilatess dersi: ATLANAN
        // karede eski landmark'ı çizersek video oynamışken maske yüzer. O yüzden
        // yalnız TAZE algılamanın olduğu karede çiz — arada mesh çizilmez (sabit
        // maske değil, hiç maske; gövde ağı zaten her kare akıyor).
        let freshMesh = false;
        if (meshFrame % 2 === 0) {
          try {
            lastFace = faceLandmarker.detectForVideo(video, performance.now());
            lastHands = handLandmarker.detectForVideo(video, performance.now());
            freshMesh = true;
          } catch (_) { /* mesh dusse de gövde ağı yasar */ }
        }
        if (freshMesh && lastFace && lastFace.faceLandmarks) {
          // kavisli özellikler: [connector listesi, çizgi kalınlığı, renk]
          const feats = [
            [FaceLandmarker.FACE_LANDMARKS_LIPS,          2.4, skeletonColor],
            [FaceLandmarker.FACE_LANDMARKS_LEFT_EYE,      1.6, skeletonColor],
            [FaceLandmarker.FACE_LANDMARKS_RIGHT_EYE,     1.6, skeletonColor],
            [FaceLandmarker.FACE_LANDMARKS_LEFT_EYEBROW,  1.8, skeletonColor],
            [FaceLandmarker.FACE_LANDMARKS_RIGHT_EYEBROW, 1.8, skeletonColor],
            [FaceLandmarker.FACE_LANDMARKS_FACE_OVAL,     1.4, "rgba(51,0,14,0.5)"],
          ];
          for (const fl of lastFace.faceLandmarks)
            drawFace(ctx, fl, FaceLandmarker.FACE_LANDMARKS_TESSELATION, feats, canvas.width, canvas.height);
        }
        if (freshMesh && lastHands && lastHands.landmarks)
          for (const hl of lastHands.landmarks) drawHand(ctx, hl, canvas.width, canvas.height);
      }
    }

    if ((!result || !result.landmarks || !result.landmarks.length) && stageBanner) drawBanner(stageBanner);

    frames++;
    const now = performance.now();
    if (now - fpsClock >= 500) {
      fps = Math.round((frames * 1000) / (now - fpsClock));
      frames = 0; fpsClock = now;
      // fps koruması (histerezis): yüz/el iki modeli fps'i yerse uykuya al; gövde
      // dolgusu + iskelet pozdan gelir, hep akıcı. toparlayınca geri uyanır.
      if (MESH_FACE_HANDS) {
        if (!meshFaceHandsSleep && fps < 20) meshFaceHandsSleep = true;
        else if (meshFaceHandsSleep && fps > 26) meshFaceHandsSleep = false;
      }
      fpsEl.textContent = fps + " fps  ·  all math on your device" +
        (meshFaceHandsSleep ? "  ·  face/hand detail paused for speed" : "");
    }
  }
  requestAnimationFrame(loop);
}

// seçici artık aday hareketi tutar (programa "add" ile girer); motorunkini kuyruk yönetir.
moveSel.addEventListener("change", () => {
  move = MOVES[moveSel.value] || MOVES.squat;
  // hold hareketi seçilince plan hedefi SANİYE (30) olur, rep hareketinde tekrar (10).
  // motor targetReps'i hold'da saniye yorumlar; giriş de ona göre başlasın.
  if (HOLD_MOVES.has(moveSel.value)) { planReps.value = 30; planSets.value = 1; }
});

// dinlenme süresi programın ortak ayarı — değişince kaydedilir.
planRest.addEventListener("change", () => { program.rest = readRestInput(); saveProgram(); });

// "hazırım": molayı erken bitir, sıradaki sete geç.
skipRestBtn.addEventListener("click", () => { if (engine) engine.skipRest(); });

// ── akış: workout kur → "start the workout" (TEK buton) → ilk sefer izin → kamera.
// ara "start camera" ekranı YOK; en az bir hareket olmadan kamera açılmaz. ──
const readyBtn = $("ready"), startWrap = $("startWrap");
const camstageEl = $("camstage");
if (camstageEl) camstageEl.addEventListener("click", (e) => {
  if (e.target.id === "ready") return;   // buton kendi dinleyicisiyle başlatır
  beginWorkout();
});
const consentEl = $("consent"), consentGo = $("consentGo");
const CONSENT_KEY = "gg_consent_v1";
function consentGiven() {
  try { return localStorage.getItem(CONSENT_KEY) === "yes"; } catch (_) { return false; }
}
// workout'u başlat: hareket yoksa seçili olanı workout say, sonra (ilk sefer) izin iste ve kamerayı aç.
function beginWorkout() {
  if (!program.items.length) program.items.push(readPlanInputs());
  program.rest = readRestInput();
  saveProgram(); renderProgram();
  if (!consentGiven()) {
    introCard.hidden = true; progCard.hidden = true;
    if (camstageEl) camstageEl.hidden = true;
    consentEl.hidden = false; consentGo.focus(); return;
  }
  start();
}
addMoveBtn.addEventListener("click", () => {
  program.items.push(readPlanInputs());
  program.rest = readRestInput();
  saveProgram(); renderProgram();
});
readyBtn.addEventListener("click", beginWorkout);
consentGo.addEventListener("click", () => {
  try { localStorage.setItem(CONSENT_KEY, "yes"); } catch (_) { /* yine başlar, bir daha sorulur */ }
  consentEl.hidden = true;
  start();
});
backProg.addEventListener("click", () => {
  if (running) stop();
  startWrap.hidden = true; consentEl.hidden = true;
  introCard.hidden = false; progCard.hidden = false;
  if (camstageEl) camstageEl.hidden = false;
});
planRest.value = program.rest;
renderProgram();
stopBtn.addEventListener("click", stop);
window.addEventListener("resize", () => { if (running) sizeCanvas(); });

// giriş değişince: bekleyen kuyruğu gönder, geçmişi o hesaptan yeniden çiz.
onAuth(() => { flushQueue(); loadHistory(); });
window.addEventListener("online", flushQueue);
window.addEventListener("gg-sessions-changed", loadHistory);   // "delete my synced workouts" sonrası

// pwa: ana ekrana kurulunca offline da açılır (sw.js dosyaları önbelleğe alır).
if ("serviceWorker" in navigator) navigator.serviceWorker.register("sw.js").catch(() => {});
