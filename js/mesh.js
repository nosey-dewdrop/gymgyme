// mesh.js — görsel katman. SADECE çizim; sayma/açı motoruna HİÇ girmez (bir
// çizim bug'ı bir tekrarı bozamaz — motordan tam yalıtık).
//
// Damla (15 tem): önce "adet iskelet / 3 dallı ağaç parmak / çizgi dudak"
// şikayeti; sonra "bir AĞ gibi görünsün — parmakla ışık büken interaktif
// kurulum gibi". Bu dosya gövdeyi bir NET olarak çizer: düğümler arası ışıltılı
// ipler (üçgen örgü) + parlak glow düğümler, derinlikle (z) parlar. Gerçek video
// ardından görünür — dolu blob DEĞİL (jüri: opak dolgu vücudu kapatıyordu).
// Yüz hâlâ dolgulu mesh (kavisli dudak/göz/kaş), eller dolgulu (21 eklem).
//
// NOT: burası "cila"dır, mühendislik derinliği coach_engine'de. Ağ, aynı 33
// landmark'ın süslü çizimi — parlayan şey TAKİP değil, görüntü.

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

// ── GÖVDE: çizgi değil hacim, AMA saydam bir AURA (Pilatess dersi 15 tem: opak
// dolgu vücudu kapatıyordu, "kendimi göremiyorum" = kırık his). Artık düşük
// alfa + kenar konturu: gerçek video görünür, mesh onun üstünde ışıltılı bir
// hacim kabuğu + ince mürekkep silüet. Ayna hissi korunur. ──
const BODY_ALPHA = 0.30;   // gövde/uzuv dolgusu saydamlığı (video görünsün)
const L = { LSHO:11, RSHO:12, LELB:13, RELB:14, LWRI:15, RWRI:16,
            LHIP:23, RHIP:24, LKNE:25, RKNE:26, LANK:27, RANK:28,
            LHEEL:29, RHEEL:30, LFT:31, RFT:32 };

const VIS_FILL = 0.55;   // dolu uzuv daha katı: düşük güvende çizme (Pilatess: yakın/kesik kadrajda snap)

// bir uzvu kapsül (yuvarlak uçlu kalın boru) — SAYDAM aura + ince mürekkep kontur.
function limbCapsule(ctx, a, b, W, H, wA, wB, t) {
  const va = (a && (a.visibility ?? 1)), vb = (b && (b.visibility ?? 1));
  if (!a || !b || va < VIS_FILL || vb < VIS_FILL) return;
  const ax = a.x * W, ay = a.y * H, bx = b.x * W, by = b.y * H;
  const dx = bx - ax, dy = by - ay;
  const len = Math.hypot(dx, dy) || 1;
  const nx = -dy / len, ny = dx / len;   // dike birim
  // güvene göre alfa sönümle (Pilatess: sert on/off yerine yumuşak çöz)
  const conf = Math.min(va, vb);
  const alpha = BODY_ALPHA * Math.max(0.4, Math.min(1, (conf - VIS_FILL) / 0.3 + 0.6));
  ctx.beginPath();
  ctx.moveTo(ax + nx * wA, ay + ny * wA);
  ctx.lineTo(bx + nx * wB, by + ny * wB);
  ctx.arc(bx, by, wB, Math.atan2(ny, nx), Math.atan2(-ny, -nx), false);
  ctx.lineTo(ax - nx * wA, ay - ny * wA);
  ctx.arc(ax, ay, wA, Math.atan2(-ny, -nx), Math.atan2(ny, nx), false);
  ctx.closePath();
  const grd = ctx.createLinearGradient(ax + nx * wA, ay + ny * wA, ax - nx * wA, ay - ny * wA);
  grd.addColorStop(0, shade(Math.min(1, t + 0.25), alpha));
  grd.addColorStop(0.5, shade(t, alpha));
  grd.addColorStop(1, shade(Math.max(0, t - 0.3), alpha));
  ctx.fillStyle = grd;
  ctx.fill();
  // ince mürekkep kontur: silüeti tanımlar (Pilatess: dolgu-kontursuz = pembe sosis)
  ctx.strokeStyle = "rgba(51,0,14," + (0.35 + 0.35 * t) + ")";
  ctx.lineWidth = 1.4;
  ctx.stroke();
}


// ── gövde figürünü DOLU çiz. Uzuvlar uzak→yakın sıralı (yakın uzuv üste biner). ──
export function drawBody(ctx, lm, zsrc, W, H) {
  const zs = zsrc || lm;
  const dep = (i) => depthOf(zs[i] ? zs[i].z : 0);
  const vis = (i) => (lm[i] ? (lm[i].visibility ?? 1) : 0);
  const px = (i) => lm[i].x * W, py = (i) => lm[i].y * H;

  // ── CV AĞ (Damla, 15 tem: "bir ağ gibi görünsün — parmakla sakız sündüren
  // interaktif kurulum gibi"): dolu blob DEĞİL. Vücut bir NET: düğümler arası
  // ışıltılı ipler (üçgen örgü) + parlak glow düğümler. Video ardından görünür;
  // ağ onun üstünde canlı, derinlikle parlayan bir enerji örgüsü. ──
  // ağ kenarları: gerçek vücut topolojisi + üçgenleyen çapraz bağlar (net hissi).
  const EDGES = [
    // gövde dörtgeni + köşegenler (üçgen örgü)
    [L.LSHO, L.RSHO], [L.LHIP, L.RHIP], [L.LSHO, L.LHIP], [L.RSHO, L.RHIP],
    [L.LSHO, L.RHIP], [L.RSHO, L.LHIP],
    // kollar
    [L.LSHO, L.LELB], [L.LELB, L.LWRI], [L.RSHO, L.RELB], [L.RELB, L.RWRI],
    // bacaklar
    [L.LHIP, L.LKNE], [L.LKNE, L.LANK], [L.RHIP, L.RKNE], [L.RKNE, L.RANK],
    // omuz-kalça çapraz örgüsü (ağı sıklaştırır)
    [L.LSHO, L.RELB], [L.RSHO, L.LELB],
    // boyun/baş bağı
    [L.LSHO, 0], [L.RSHO, 0],
  ];

  ctx.save();
  ctx.lineCap = "round"; ctx.lineJoin = "round";

  // görünürlük→alfa YUMUŞAK sönüm (Pilatess: sert 0.4 kesimi normal ışıkta
  // 0.35-0.45 salınan bilek/ayakla ağı yakıp söndürüyordu = "kırık" hissi).
  // 0.3-0.58 bandında yumuşak geçiş: nokta blink yerine soluklaşarak kaybolur.
  const vfade = (v) => Math.max(0, Math.min(1, (v - 0.3) / 0.28));

  // 1) ipler: her kenar derinliğe göre parlayan bir çizgi (yakın kalın+parlak).
  const edges = [];
  for (const [a, b] of EDGES) {
    const fa = vfade(vis(a)), fb = vfade(vis(b));
    if (fa <= 0 || fb <= 0) continue;
    edges.push({ a, b, t: (dep(a) + dep(b)) / 2, f: Math.min(fa, fb) });
  }
  edges.sort((p, q) => p.t - q.t);   // uzak ip önce, yakın üstte
  for (const e of edges) {
    const t = e.t, f = e.f;
    // dış hâle (yumuşak glow) — alfa görünürlükle de sönümlenir
    ctx.strokeStyle = "rgba(255,150,190," + ((0.10 + 0.14 * t) * f) + ")";
    ctx.lineWidth = 5 + 5 * t;
    ctx.beginPath(); ctx.moveTo(px(e.a), py(e.a)); ctx.lineTo(px(e.b), py(e.b)); ctx.stroke();
    // iç parlak tel
    ctx.strokeStyle = "rgba(255,220,235," + ((0.5 + 0.4 * t) * f) + ")";
    ctx.lineWidth = 1 + 1.6 * t;
    ctx.beginPath(); ctx.moveTo(px(e.a), py(e.a)); ctx.lineTo(px(e.b), py(e.b)); ctx.stroke();
  }

  // 2) düğümler: her eklem parlak bir nokta (yakın büyük+beyaz çekirdek).
  const nodes = [L.LSHO, L.RSHO, L.LELB, L.RELB, L.LWRI, L.RWRI,
                 L.LHIP, L.RHIP, L.LKNE, L.RKNE, L.LANK, L.RANK, 0];
  const shoulderW = Math.hypot((lm[L.LSHO].x - lm[L.RSHO].x) * W, (lm[L.LSHO].y - lm[L.RSHO].y) * H) || 60;
  const r0 = Math.max(3, shoulderW * 0.05);
  for (const i of nodes) {
    const f = vfade(vis(i));
    if (f <= 0) continue;
    const t = dep(i), x = px(i), y = py(i), r = r0 * (0.7 + 0.7 * t);
    // hâle — alfa görünürlükle sönümlenir (blink yerine soluklaşma)
    const g = ctx.createRadialGradient(x, y, 0, x, y, r * 2.6);
    g.addColorStop(0, "rgba(255,180,210," + ((0.5 + 0.4 * t) * f) + ")");
    g.addColorStop(1, "rgba(255,150,190,0)");
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.arc(x, y, r * 2.6, 0, Math.PI * 2); ctx.fill();
    // parlak çekirdek
    ctx.fillStyle = "rgba(255,246,250," + ((0.7 + 0.3 * t) * f) + ")";
    ctx.beginPath(); ctx.arc(x, y, r * 0.55, 0, Math.PI * 2); ctx.fill();
  }
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
