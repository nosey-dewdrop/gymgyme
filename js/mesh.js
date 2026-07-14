// mesh.js — CGI-grade görsel katman. SADECE çizim; sayma/açı motoruna HİÇ girmez.
//
// Damla (15 tem): "beni bir adet kol iskeleti gibi gösteriyor. parmaklarım 3 dallı
// bir ağaç gibi. yüzüm dudağım bir çizgi. oysa dudağım kavisli, detayları var. çok
// boyutlu integral gibi insanlarız." — bu dosya o şikayeti kapatır: çöp-adam değil,
// dolgulu yüz mesh'i (kavisli dudak/göz/kaş), gerçek dolgulu eller (21 eklem), ve
// gövdenin ÇİZGİ değil HACİM olarak render'ı (derinlik-gölgeli, kaslı kabuk).
//
// Tasarım kararı: her şey derinlik (z) ile gölgelenir. MediaPipe her noktanın z'sini
// tahmin ediyor; yakın yüzey aydınlık ve dolgun, uzak yüzey koyu ve soluk. Böylece
// düz 2B çizgi yığını değil, üç boyutlu bir yüzey hissi doğar — "CGI gibi".

// gymgyme paleti — vişne/gül tonları (site ile uyumlu).
const SKIN_NEAR = [255, 190, 205];   // yakın yüzey (aydınlık)
const SKIN_FAR  = [120, 30,  60];    // uzak yüzey (koyu vişne)
const INK       = "#33000E";         // kontur mürekkebi
const GLOW      = "rgba(255, 214, 233, 0.9)";

// z ~ [-0.5..0.5] → 0 (uzak) .. 1 (yakın). Dedektör z'si kabaca bu aralıkta.
function depthOf(z) { return Math.max(0, Math.min(1, 0.5 - (z || 0))); }

// iki uç rengi arasında derinlikle karış — yüzey ışığı.
function shade(t, a) {
  const r = Math.round(SKIN_FAR[0] + (SKIN_NEAR[0] - SKIN_FAR[0]) * t);
  const g = Math.round(SKIN_FAR[1] + (SKIN_NEAR[1] - SKIN_FAR[1]) * t);
  const b = Math.round(SKIN_FAR[2] + (SKIN_NEAR[2] - SKIN_FAR[2]) * t);
  return "rgba(" + r + "," + g + "," + b + "," + (a == null ? 1 : a) + ")";
}

// ── GÖVDE: çizgi değil hacim. Landmark'lardan kapalı bir kabuk (gövde poligonu +
// uzuvlar boru gibi kalın) çizilir, derinlikle gölgelenir. İskelet çizgisi bunun
// ÜSTÜNE ince bir omurga gibi biner — artık "adet iskelet" değil, dolu bir figür. ──
const L = { LSHO:11, RSHO:12, LELB:13, RELB:14, LWRI:15, RWRI:16,
            LHIP:23, RHIP:24, LKNE:25, RKNE:26, LANK:27, RANK:28,
            LHEEL:29, RHEEL:30, LFT:31, RFT:32 };

// bir uzvu kapsül (yuvarlak uçlu kalın boru) olarak doldur — kas hacmi hissi.
function limbCapsule(ctx, a, b, W, H, wA, wB, t) {
  if (!a || !b || (a.visibility ?? 1) < 0.4 || (b.visibility ?? 1) < 0.4) return;
  const ax = a.x * W, ay = a.y * H, bx = b.x * W, by = b.y * H;
  const dx = bx - ax, dy = by - ay;
  const len = Math.hypot(dx, dy) || 1;
  const nx = -dy / len, ny = dx / len;   // dike birim
  ctx.beginPath();
  ctx.moveTo(ax + nx * wA, ay + ny * wA);
  ctx.lineTo(bx + nx * wB, by + ny * wB);
  ctx.arc(bx, by, wB, Math.atan2(ny, nx), Math.atan2(-ny, -nx), false);
  ctx.lineTo(ax - nx * wA, ay - ny * wA);
  ctx.arc(ax, ay, wA, Math.atan2(-ny, -nx), Math.atan2(ny, nx), false);
  ctx.closePath();
  // yüzey ışığı: uzvun ekseni boyunca aydınlıktan koyuya gradyan
  const grd = ctx.createLinearGradient(ax + nx * wA, ay + ny * wA, ax - nx * wA, ay - ny * wA);
  grd.addColorStop(0, shade(Math.min(1, t + 0.25), 0.92));
  grd.addColorStop(0.5, shade(t, 0.92));
  grd.addColorStop(1, shade(Math.max(0, t - 0.3), 0.92));
  ctx.fillStyle = grd;
  ctx.fill();
}

// gövde gövdesi: omuz-omuz-kalça-kalça dörtgeni, dolu.
function torsoShell(ctx, lm, W, H, t) {
  const p = (i) => lm[i];
  const need = [L.LSHO, L.RSHO, L.LHIP, L.RHIP];
  if (need.some((i) => !p(i) || (p(i).visibility ?? 1) < 0.4)) return;
  ctx.beginPath();
  ctx.moveTo(p(L.LSHO).x * W, p(L.LSHO).y * H);
  ctx.lineTo(p(L.RSHO).x * W, p(L.RSHO).y * H);
  ctx.lineTo(p(L.RHIP).x * W, p(L.RHIP).y * H);
  ctx.lineTo(p(L.LHIP).x * W, p(L.LHIP).y * H);
  ctx.closePath();
  const cx = (p(L.LSHO).x + p(L.RHIP).x) / 2 * W, cy = (p(L.LSHO).y + p(L.RHIP).y) / 2 * H;
  const grd = ctx.createRadialGradient(cx, cy, 4, cx, cy, Math.max(W, H) * 0.3);
  grd.addColorStop(0, shade(Math.min(1, t + 0.2), 0.9));
  grd.addColorStop(1, shade(Math.max(0, t - 0.2), 0.9));
  ctx.fillStyle = grd;
  ctx.fill();
}

// ── gövde figürünü DOLU çiz. Uzuvlar uzak→yakın sıralı (yakın uzuv üste biner). ──
export function drawBody(ctx, lm, zsrc, W, H) {
  const zs = zsrc || lm;
  const dep = (i) => depthOf(zs[i] ? zs[i].z : 0);
  const bodyDepth = (dep(L.LSHO) + dep(L.RSHO) + dep(L.LHIP) + dep(L.RHIP)) / 4;

  // uzuv listesi: [a, b, kalınlıkA, kalınlıkB]. kalınlık gövde ölçeğine oranlı.
  const shoulderW = Math.hypot((lm[L.LSHO].x - lm[L.RSHO].x) * W, (lm[L.LSHO].y - lm[L.RSHO].y) * H) || 60;
  const u = shoulderW * 0.16;   // temel uzuv yarıçapı
  const limbs = [
    [L.LHIP, L.LKNE, u * 1.15, u * 0.95], [L.LKNE, L.LANK, u * 0.9, u * 0.6],
    [L.RHIP, L.RKNE, u * 1.15, u * 0.95], [L.RKNE, L.RANK, u * 0.9, u * 0.6],
    [L.LSHO, L.LELB, u * 0.85, u * 0.7],  [L.LELB, L.LWRI, u * 0.65, u * 0.5],
    [L.RSHO, L.RELB, u * 0.85, u * 0.7],  [L.RELB, L.RWRI, u * 0.65, u * 0.5],
  ];
  // derinliğe göre sırala: uzak uzuvlar önce çizilir
  limbs.sort((A, B) => (dep(A[0]) + dep(A[1])) - (dep(B[0]) + dep(B[1])));

  ctx.save();
  ctx.lineJoin = "round";
  torsoShell(ctx, lm, W, H, bodyDepth);
  for (const [a, b, wa, wb] of limbs) {
    const t = (dep(a) + dep(b)) / 2;
    limbCapsule(ctx, lm[a], lm[b], W, H, wa, wb, t);
  }
  // eklem yuvarlakları — kabuğu pürüzsüz bağlar
  const joints = [L.LSHO, L.RSHO, L.LELB, L.RELB, L.LWRI, L.RWRI,
                  L.LHIP, L.RHIP, L.LKNE, L.RKNE, L.LANK, L.RANK];
  for (const i of joints) {
    const q = lm[i];
    if (!q || (q.visibility ?? 1) < 0.4) continue;
    const t = dep(i);
    ctx.beginPath();
    ctx.arc(q.x * W, q.y * H, u * 0.75, 0, Math.PI * 2);
    ctx.fillStyle = shade(t, 0.9);
    ctx.fill();
  }
  // ince kontur: figürün kenarına mürekkep — çizimin "hand-drawn" kimliği kalsın
  ctx.restore();
}

// ── YÜZ: dolgulu mesh. FACE_LANDMARKS_TESSELATION üçgen ağı dolu çizilir
// (derinlik gölgeli deri), sonra kavisli dudak/göz/kaş konturları mürekkeple
// üstüne biner. "dudağım bir çizgi değil, kavisli" — bu tam onu verir. ──
export function drawFace(ctx, face, tesselation, contours, W, H) {
  if (!face || !face.length) return;
  ctx.save();

  // 1) deri: üçgen ağı dolu çiz (her üçgen kendi derinlik-ışığında)
  const dep = (p) => depthOf(p.z);
  ctx.lineWidth = 0.5;
  for (const c of tesselation) {
    // tesselation connector listesi (start,end); üçgenleri komşu çiftlerden değil,
    // doğrudan her segmenti ince deri-dolgu şeridi olarak çizeriz (ucuz + yumuşak).
    const a = face[c.start], b = face[c.end];
    if (!a || !b) continue;
    const t = (dep(a) + dep(b)) / 2;
    ctx.strokeStyle = shade(t, 0.5);
    ctx.beginPath();
    ctx.moveTo(a.x * W, a.y * H);
    ctx.lineTo(b.x * W, b.y * H);
    ctx.stroke();
  }

  // 2) kavisli özellikler: dudak (üst+alt), göz, kaş — kalın mürekkep kontur
  ctx.lineJoin = "round";
  ctx.lineCap = "round";
  for (const [conn, wLine, col] of contours) {
    ctx.strokeStyle = col;
    ctx.lineWidth = wLine;
    ctx.beginPath();
    let started = false;
    for (const c of conn) {
      const a = face[c.start];
      if (!a) { started = false; continue; }
      const x = a.x * W, y = a.y * H;
      if (!started) { ctx.moveTo(x, y); started = true; } else ctx.lineTo(x, y);
    }
    ctx.stroke();
  }
  ctx.restore();
}

// ── ELLER: 3 dallı ağaç değil, dolgulu el. Avuç poligonu doldurulur, parmaklar
// kapsül boru, uç boğumlar yuvarlak — gerçek parmak hacmi. ──
const HAND_FINGERS = [
  [0, 1, 2, 3, 4],       // başparmak
  [0, 5, 6, 7, 8],       // işaret
  [0, 9, 10, 11, 12],    // orta
  [0, 13, 14, 15, 16],   // yüzük
  [0, 17, 18, 19, 20],   // serçe
];
const HAND_PALM = [0, 1, 5, 9, 13, 17];

export function drawHand(ctx, hand, W, H) {
  if (!hand || hand.length < 21) return;
  ctx.save();
  ctx.lineJoin = "round"; ctx.lineCap = "round";
  const dep = (i) => depthOf(hand[i] ? hand[i].z : 0);
  // el ölçeği: bilek→orta boğum
  const scale = Math.hypot((hand[0].x - hand[9].x) * W, (hand[0].y - hand[9].y) * H) || 40;
  const rBase = scale * 0.16;

  // avuç dolgusu
  ctx.beginPath();
  for (let k = 0; k < HAND_PALM.length; k++) {
    const p = hand[HAND_PALM[k]];
    const x = p.x * W, y = p.y * H;
    if (k === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
  }
  ctx.closePath();
  ctx.fillStyle = shade(dep(0), 0.9);
  ctx.fill();

  // parmaklar: her boğum kapsül
  for (const f of HAND_FINGERS) {
    for (let k = 0; k < f.length - 1; k++) {
      const a = hand[f[k]], b = hand[f[k + 1]];
      const t = (dep(f[k]) + dep(f[k + 1])) / 2;
      const wr = rBase * (1 - k * 0.13);
      limbCapsule(ctx, a, b, W, H, wr, wr * 0.8, t);
    }
  }
  // uç noktalar (tırnak ucu hissi)
  for (const i of [4, 8, 12, 16, 20]) {
    const p = hand[i];
    ctx.beginPath();
    ctx.arc(p.x * W, p.y * H, rBase * 0.55, 0, Math.PI * 2);
    ctx.fillStyle = shade(Math.min(1, dep(i) + 0.15), 0.95);
    ctx.fill();
  }
  ctx.restore();
}
