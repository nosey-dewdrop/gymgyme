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

  // ── GERÇEK CV MOTORU GÖRÜNÜMÜ (Damla: "beni kutu kutu seç, sağ kol sol kol
  // bel torso diye etiketle, gerçek cv motoru hissi versin"). Her vücut parçası
  // = bir tespit kutusu (bounding box) + köşe işaretleri + etiket. YOLO/detection
  // hissi. Ağ/dolgu YOK; video net görünür, üstünde takip kutuları oynar. ──
  const vfade = (v) => Math.max(0, Math.min(1, (v - 0.25) / 0.25));

  // her parça: etiket + o parçayı çevreleyen landmark noktaları.
  const PARTS = [
    { label: "torso",     pts: [L.LSHO, L.RSHO, L.LHIP, L.RHIP] },
    { label: "right arm", pts: [L.RSHO, L.RELB, L.RWRI] },   // ayna: kullanıcının sağı
    { label: "left arm",  pts: [L.LSHO, L.LELB, L.LWRI] },
    { label: "right leg", pts: [L.RHIP, L.RKNE, L.RANK] },
    { label: "left leg",  pts: [L.LHIP, L.LKNE, L.LANK] },
  ];

  ctx.save();
  ctx.lineJoin = "miter"; ctx.lineCap = "butt";

  for (const part of PARTS) {
    // görünür noktalardan kutu sınırlarını çıkar
    let minx = 1e9, miny = 1e9, maxx = -1e9, maxy = -1e9, vsum = 0, n = 0;
    for (const i of part.pts) {
      const f = vfade(vis(i));
      if (f <= 0) continue;
      const x = px(i), y = py(i);
      minx = Math.min(minx, x); miny = Math.min(miny, y);
      maxx = Math.max(maxx, x); maxy = Math.max(maxy, y);
      vsum += f; n++;
    }
    if (n < 2) continue;   // parça yeterince görünmüyor
    const conf = vsum / part.pts.length;      // "güven" (0..1): kaç nokta net
    const alpha = 0.35 + 0.55 * Math.min(1, conf);
    // kutuya biraz pay ver (parçayı sarsın)
    const pad = 14;
    minx -= pad; miny -= pad; maxx += pad; maxy += pad;
    const bw = maxx - minx, bh = maxy - miny;

    // 1) köşe işaretli tespit kutusu (klasik detection köşeleri)
    ctx.strokeStyle = "rgba(166,27,66," + alpha + ")";
    ctx.lineWidth = 1.5;
    const cl = Math.min(22, bw * 0.28, bh * 0.28);   // köşe uzunluğu
    const corner = (cx, cy, dx, dy) => {
      ctx.beginPath();
      ctx.moveTo(cx + dx * cl, cy); ctx.lineTo(cx, cy); ctx.lineTo(cx, cy + dy * cl);
      ctx.stroke();
    };
    corner(minx, miny, 1, 1); corner(maxx, miny, -1, 1);
    corner(minx, maxy, 1, -1); corner(maxx, maxy, -1, -1);
    // ince tam çerçeve (soluk)
    ctx.strokeStyle = "rgba(166,27,66," + (alpha * 0.28) + ")";
    ctx.lineWidth = 1;
    ctx.strokeRect(minx, miny, bw, bh);

    // 2) etiket sekmesi (parça adı + güven yüzdesi) — sol üst köşede
    const tag = part.label + "  " + Math.round(conf * 100) + "%";
    ctx.font = "600 12px 'Courier New', monospace";
    const tw = ctx.measureText(tag).width;
    ctx.fillStyle = "rgba(166,27,66," + alpha + ")";
    ctx.fillRect(minx, miny - 17, tw + 12, 17);
    ctx.fillStyle = "rgba(255,240,246," + Math.min(1, alpha + 0.2) + ")";
    ctx.textBaseline = "middle";
    ctx.fillText(tag, minx + 6, miny - 17 + 9);
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
