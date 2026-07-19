// coach_engine.cpp — coach motorunun saf C++ implementasyonu.
// Web yok, tarayıcı yok: sadece geometri ve durum. (API: coach_engine.hpp)

#include "coach_engine.hpp"
#include <algorithm>
#include <cmath>

namespace coach {

// MediaPipe Pose landmark indeksleri.
enum {
  L_SHO = 11, R_SHO = 12, L_ELB = 13, R_ELB = 14, L_WRI = 15, R_WRI = 16,
  L_HIP = 23, R_HIP = 24, L_KNE = 25, R_KNE = 26, L_ANK = 27, R_ANK = 28,
  L_FT = 31, R_FT = 32   // ayak ucu (calf raise: ayak bileği açısı ister)
};

// B köşesindeki açı (A-B-C), derece. Tam 3B: ekran verisinde z=0 gelir ve bu
// 2B'ye indirgenir; dünya verisinde z gerçek derinliktir ve kameraya doğru
// bükülmeler (2B'de "düz" görünen) doğru ölçülür.
static double angleDeg(const Landmark& A, const Landmark& B, const Landmark& C) {
  double v1x = A.x - B.x, v1y = A.y - B.y, v1z = A.z - B.z;
  double v2x = C.x - B.x, v2y = C.y - B.y, v2z = C.z - B.z;
  double m1 = std::sqrt(v1x * v1x + v1y * v1y + v1z * v1z);
  double m2 = std::sqrt(v2x * v2x + v2y * v2y + v2z * v2z);
  if (m1 < 1e-6 || m2 < 1e-6) return -1.0;
  double c = (v1x * v2x + v1y * v2y + v1z * v2z) / (m1 * m2);
  c = std::max(-1.0, std::min(1.0, c));
  return std::acos(c) * 180.0 / M_PI;
}

static double angleAt(const std::vector<Landmark>& p, const JointRef& j) {
  return angleDeg(p[j.a], p[j.b], p[j.c]);
}

// HAREKET KÜTÜPHANESİ. Her hareket = bir MoveSpec verisi: hangi eklem zinciri
// izlenir, hangi açı "dipte" hangi açı "üstte" demektir, hangi noktalar kadrajda
// olmalı, hangi form kuralları geçerli. Motor kodu HİÇBİR hareketi tanımıyor —
// yeni hareket eklemek bu tabloya satır eklemek.
//
// Sayma yönü kendiliğinden iki tip hareketi de kapsıyor: squat gibi "bük-aç"
// hareketlerde de, press/köprü gibi "açarak çalışılan" hareketlerde de tekrar
// Bottom→Top (bükülüden açığa) geçişinde sayılır — press'te ilk açış 1. tekrardır.
// ── AİLE ŞABLONU SİSTEMİ (Loop 02 — 14 hareket sınırı kalkar). Kütüphanedeki
// 386 hareketin çoğu, motorun ZATEN kurallı olduğu 14 hareketin bir AİLESİ:
// "diamond push-up" bir push-up'tır (aynı omuz-dirsek-bilek zinciri, aynı faz
// döngüsü), "reverse lunge" bir lunge'dır. O yüzden elle 200 ayrı kural YOK:
// her varyant = bir AİLE BASE spec'i (kanonik hareket) + küçük PARAMETRE farkı
// (dip bandı, tempo tavanı, izlenen taraf, kadraj cümlesi). Aile mantığı —
// izlenen eklem zinciri, faz durum makinesi, form kuralları, adaptif ROM — base
// spec'ten OLDUĞU GİBİ gelir; varyant sadece sayıları oynatır. Mevcut 14 hareket
// bu tabloya GİRMEZ (kendi dallarına düşer, dokunulmaz); yeni sistem yanlarında.
//
// Varyant tablosu = VERİ: {varyant adı → {aile base adı, dip farkı, tempo taban,
// ek/değişen form kuralı}}. Yeni hareket = tabloya bir satır, kod değil.
struct MoveVariant {
  const char* alias;      // kütüphanedeki hareket adı (lowercase, moves-db.js ile birebir)
  const char* family;     // hangi aile base spec'i klonlanır (builtinMove'daki kanonik ad)
  double bottomShift;     // aile dip açısına eklenen fark (derece; + = daha sığ dip ister)
  double repSecMinShift;  // aile tempo tabanına eklenen fark (sn; + = daha yavaş ister)
};

// Faz döngüsü + form ihlali base spec'ten aynen okunur; burada SADECE parametre farkı.
static const MoveVariant kVariants[] = {
  // ── SQUAT ailesi (diz = kalça-diz-ayakbileği; adaptif dip; gövde-dik kuralı) ──
  {"bodyweight squat",  "squat",     0.0,  0.0},
  {"prisoner squat",    "squat",     0.0,  0.0},
  {"sumo squat",        "sumosquat", 0.0,  0.0},   // aile: sumosquat (daha geniş duruş kuralı)
  {"jump squat",        "squat",     0.0, -0.4},   // patlayıcı: tempo tabanı düşer, hızlı sayılır
  {"freehand jump squat","squat",    0.0, -0.4},
  {"split squats",      "lunge",     0.0,  0.0},   // split squat = statik lunge geometrisi
  {"split squat jump",  "lunge",     0.0, -0.4},
  {"sit squats",        "squat",     0.0,  0.0},
  {"banded squat",      "squat",     0.0,  0.0},
  {"kneeling squat",    "glutebridge",0.0, 0.0},   // dizüstü: kalça açısı sürer (bridge geometrisi)
  // ── LUNGE ailesi (öndeki diz; adaptif dip; gövde-dik kuralı) ──
  {"reverse lunge",     "lunge",     0.0,  0.0},
  {"crossover reverse lunge","lunge",0.0,  0.0},
  {"curtsy lunge",      "lunge",     0.0,  0.0},
  {"lateral lunge",     "sidelunge", 0.0,  0.0},   // aile: sidelunge (yana oturma)
  {"jump lunge",        "lunge",     0.0, -0.3},
  {"bodyweight walking lunge","lunge",0.0, 0.0},
  // ── PUSH-UP ailesi (dirsek = omuz-dirsek-bilek; adaptif dip; kalça-hattı kuralı) ──
  {"pushups",           "pushup",    0.0,  0.0},
  {"push-up wide",      "pushup",    0.0,  0.0},
  {"push-ups with feet elevated","pushup",0.0,0.0},
  {"diamond push-up",   "pushup",    0.0,  0.0},
  {"knee push-up",      "kneelingpushup",0.0,0.0}, // aile: kneelingpushup
  {"diamond push-up on knees","kneelingpushup",0.0,0.0},
  {"incline push-up",   "pushup",    5.0,  0.0},   // eğik: dirsek ROM'u biraz sığ, dip eşiği yumuşar
  {"incline push-up wide","pushup",  5.0,  0.0},
  {"incline push-up medium","pushup",5.0,  0.0},
  {"decline push-up",   "pushup",    0.0,  0.0},
  {"wall push-up",      "pushup",    8.0,  0.0},   // duvara: en sığ ROM
  {"kneeling wall push-up","kneelingpushup",8.0,0.0},
  {"close-grip wall push-up","pushup",8.0, 0.0},
  {"pike push-up",      "pushup",    0.0,  0.0},
  {"tempo push-up",     "pushup",    0.0,  0.8},   // tempo: yavaş iniş şartı yükselir
  {"eccentric push-up", "pushup",    0.0,  0.8},
  {"wide push-up",      "pushup",    0.0,  0.0},
  {"staggered push-up", "pushup",    0.0,  0.0},
  // ── SIT-UP / CRUNCH ailesi (kalça = omuz-kalça-diz; doğrulma sayılır) ──
  {"sit-up",            "situp",     0.0,  0.0},
  {"crunches",          "situp",     0.0,  0.0},
  {"crunch - hands overhead","situp",0.0,  0.0},
  {"3/4 sit-up",        "situp",     0.0,  0.0},
  {"tuck crunch",       "situp",     0.0,  0.0},
  {"reverse crunch",    "situp",     0.0,  0.0},
  {"decline crunch",    "situp",     0.0,  0.0},
  {"janda sit-up",      "situp",     0.0,  0.3},   // kontrollü: tempo tabanı biraz yükselir
  {"frog sit-ups",      "situp",     0.0,  0.0},
  {"v-up",              "situp",     0.0,  0.0},
  {"jackknife sit-up",  "situp",     0.0,  0.0},
  // ── RAISE / PRESS ailesi (omuz açısı = kalça-omuz-dirsek; gövde-dik kuralı) ──
  {"lateral raise",     "armraise",  0.0,  0.0},
  {"front raise",       "armraise",  0.0,  0.0},
  {"overhead press",    "press",     0.0,  0.0},   // aile: press (dirsek = omuz-dirsek-bilek)
  {"shoulder press",    "press",     0.0,  0.0},
  {"military press",    "press",     0.0,  0.0},
  {"pike press",        "press",     0.0,  0.0},
  {"arnold press",      "press",     0.0,  0.0},
  {"push press",        "press",     0.0, -0.2},
  // ── BRIDGE ailesi (kalça = omuz-kalça-diz; köprü açılışında sayılır) ──
  {"glute bridge",      "glutebridge",0.0, 0.0},
  {"elevated glute bridge","glutebridge",0.0,0.0},
  {"single leg glute bridge","glutebridge",0.0,0.0},
  {"single-leg glute bridge","glutebridge",0.0,0.0},
  {"hip thrust off chair","glutebridge",0.0,0.0},
  {"frog pump",         "glutebridge",0.0, 0.0},
  {"pelvic tilt into bridge","glutebridge",0.0,0.0},
  // ── JACK / CALF ailesi ──
  {"star jump",         "jumpingjack",0.0, 0.0},
  {"heel raise",        "calfraise", 0.0,  0.0},
  // ── HOLD aileleri (izometrik: süre + form kapısı; salınım yok) ──
  {"forearm plank",     "plank",     0.0,  0.0},
  {"high plank",        "plank",     0.0,  0.0},
  {"straight arm plank","plank",     0.0,  0.0},
  {"side plank hold",   "sideplank", 0.0,  0.0},
  {"wall sit hold",     "wallsit",   0.0,  0.0},
  {"wall squat hold",   "wallsit",   0.0,  0.0},
  {"hollow body hold",  "hollowhold",0.0,  0.0},
};

MoveSpec builtinMove(const std::string& name);

// varyant çözücü: ad tabloda ise aile base'ini klonla, parametreleri oynat, yeniden
// adlandır. tabloda yoksa {} döner (çağıran kanonik dallara devam eder).
static bool resolveVariant(const std::string& name, MoveSpec& out) {
  for (const auto& v : kVariants) {
    if (name == v.alias) {
      out = builtinMove(v.family);       // AİLE mantığı olduğu gibi (eklem zinciri, faz, form, adaptif ROM)
      out.name = name;                   // kimlik varyantın (rec/özet doğru adı görsün)
      if (out.kind == MoveKind::Rep) {   // parametre farkı: dip bandı + tempo (hold'da anlamsız)
        out.bottomAngle += v.bottomShift;
        if (out.adaptiveBottom) out.adaptiveDrop = std::max(10.0, out.adaptiveDrop - v.bottomShift);
        out.goodRepSecMin = std::max(0.2, out.goodRepSecMin + v.repSecMinShift);
      }
      return true;
    }
  }
  return false;
}

MoveSpec builtinMove(const std::string& name) {
  { MoveSpec v; if (resolveVariant(name, v)) return v; }   // aile şablonu: varyantsa aile base + fark
  MoveSpec s;
  s.emaAlpha = 0.5;        // 0.4'tü: Damla "hassas değil" dedi — ham sinyali daha çabuk izle
  s.minVisibility = 0.5;
  s.minFraming = 0.55;     // 0.75'ti: yakın oturan gerçek kullanıcı tam sığmasa da
                           // izlenen açı okunuyorsa saysın (Damla: herkes tam boy girmez)

  if (name == "pushup") {
    s.name = "pushup";
    s.primaryLeft  = {L_SHO, L_ELB, L_WRI};   // dirsek = omuz-dirsek-bilek
    s.primaryRight = {R_SHO, R_ELB, R_WRI};
    s.bottomAngle = 95.0;
    s.topAngle = 150.0;
    s.adaptiveBottom = true; s.adaptiveDrop = 42.0;   // dirsek açısı da kameraya dönük
                                                      // şınavda perspektifle sıkışır (aynı ROM kökü)
    s.goodRepSecMin = 1.0;
    s.framingPoints = {L_SHO, R_SHO, L_ELB, R_ELB, L_WRI, R_WRI, L_HIP, R_HIP};
    s.framingCue = "i need your arms and torso in the frame - your legs can stay out";
    s.rules = {{RuleKind::HipSag, 160.0, View::Unknown, "keep your body in one line - hips up"}};
    return s;
  }
  if (name == "lunge") {
    s.name = "lunge";
    s.primaryLeft  = {L_HIP, L_KNE, L_ANK};   // öndeki diz (hangisi netse o izlenir)
    s.primaryRight = {R_HIP, R_KNE, R_ANK};
    s.bottomAngle = 100.0;
    s.topAngle = 160.0;
    s.adaptiveBottom = true; s.adaptiveDrop = 45.0;   // önden lunge da perspektifle düzleşir
    s.rules = {{RuleKind::TorsoLean, 40.0, View::Unknown, "stay upright - chest tall"}};
    return s;
  }
  if (name == "glutebridge") {
    s.name = "glutebridge";
    s.primaryLeft  = {L_SHO, L_HIP, L_KNE};   // kalça açısı: omuz-kalça-diz
    s.primaryRight = {R_SHO, R_HIP, R_KNE};
    s.bottomAngle = 140.0;   // yerde, kalça bükülü
    s.topAngle = 165.0;      // köprü: gövde-bacak tek çizgi
    s.goodRepSecMin = 1.0;
    s.framingPoints = {L_SHO, R_SHO, L_HIP, R_HIP, L_KNE, R_KNE};
    s.framingCue = "lie side-on so i can see your torso and knees";
    return s;
  }
  if (name == "situp") {
    s.name = "situp";
    s.primaryLeft  = {L_SHO, L_HIP, L_KNE};
    s.primaryRight = {R_SHO, R_HIP, R_KNE};
    s.bottomAngle = 85.0;    // doğrulmuş (kalça kapalı)
    s.topAngle = 130.0;      // yerde (kalça açık)
    s.goodRepSecMin = 1.0;
    s.framingPoints = {L_SHO, R_SHO, L_HIP, R_HIP, L_KNE, R_KNE};
    s.framingCue = "lie side-on so i can see your torso and knees";
    return s;
  }
  if (name == "press") {
    s.name = "press";
    s.primaryLeft  = {L_SHO, L_ELB, L_WRI};
    s.primaryRight = {R_SHO, R_ELB, R_WRI};
    s.bottomAngle = 100.0;   // raf: dirsek bükülü
    s.topAngle = 150.0;      // kilit: kol açık
    s.goodRepSecMin = 0.8;
    s.framingPoints = {L_SHO, R_SHO, L_ELB, R_ELB, L_WRI, R_WRI};
    s.framingCue = "i need your arms and shoulders in the frame";
    // form: gövde dik kalsın — bel yaslanıp bacakla itme (arka planda squat-press).
    s.rules = {{RuleKind::TorsoLean, 25.0, View::Unknown, "keep your torso upright - press with your arms, not your back"}};
    return s;
  }

  if (name == "sumosquat") {
    s.name = "sumosquat";
    s.primaryLeft  = {L_HIP, L_KNE, L_ANK};
    s.primaryRight = {R_HIP, R_KNE, R_ANK};
    s.bottomAngle = 120.0;   // 110'du — kameraya dönük squat açıyı olduğundan düz gösteriyor, gerçek dip sayılsın
    s.topAngle = 155.0;
    s.adaptiveBottom = true; s.adaptiveDrop = 42.0;   // adaptif dip (squat ile aynı gerekçe)
    s.rules = {{RuleKind::TorsoLean, 40.0, View::Unknown, "stay tall - sumo keeps the chest up"}};
    return s;
  }
  if (name == "sidelunge") {
    s.name = "sidelunge";
    s.primaryLeft  = {L_HIP, L_KNE, L_ANK};   // bükülen bacak (netse o izlenir)
    s.primaryRight = {R_HIP, R_KNE, R_ANK};
    s.bottomAngle = 105.0;
    s.topAngle = 160.0;
    s.adaptiveBottom = true; s.adaptiveDrop = 42.0;   // önden side lunge da perspektifle düzleşir
    s.rules = {{RuleKind::TorsoLean, 45.0, View::Unknown, "chest up as you sit into the side"}};
    return s;
  }
  if (name == "kneelingpushup") {
    s.name = "kneelingpushup";
    s.primaryLeft  = {L_SHO, L_ELB, L_WRI};
    s.primaryRight = {R_SHO, R_ELB, R_WRI};
    s.bottomAngle = 95.0;
    s.topAngle = 150.0;
    s.goodRepSecMin = 1.0;
    s.framingPoints = {L_SHO, R_SHO, L_ELB, R_ELB, L_WRI, R_WRI, L_HIP, R_HIP};
    s.framingCue = "i need your arms and torso in the frame - your legs can stay out";
    s.rules = {{RuleKind::HipSag, 150.0, View::Unknown, "keep your body in one line - hips up"}};
    return s;
  }
  if (name == "kickback") {
    s.name = "kickback";                       // emeklemede bacağı geriye uzat
    s.primaryLeft  = {L_SHO, L_HIP, L_KNE};    // kalça açısı açılınca sayar
    s.primaryRight = {R_SHO, R_HIP, R_KNE};
    s.bottomAngle = 110.0;                     // emekleme: kalça bükülü
    s.topAngle = 155.0;                        // uzatılmış bacak
    s.goodRepSecMin = 0.8;
    s.framingPoints = {L_SHO, R_SHO, L_HIP, R_HIP, L_KNE, R_KNE};
    s.framingCue = "on all fours, side-on so i can see your torso and legs";
    // form: bacağı kaldırırken bel sarkmasın/kavis yapmasın — gövde çizgisi düz.
    s.rules = {{RuleKind::TorsoLean, 25.0, View::Unknown, "keep your back flat - don't let it arch as you lift"}};
    return s;
  }
  if (name == "birddog") {
    s.name = "birddog";                        // kickback ile aynı geometri, farklı dil
    s.primaryLeft  = {L_SHO, L_HIP, L_KNE};
    s.primaryRight = {R_SHO, R_HIP, R_KNE};
    s.bottomAngle = 110.0;
    s.topAngle = 155.0;
    s.goodRepSecMin = 1.0;
    s.framingPoints = {L_SHO, R_SHO, L_HIP, R_HIP, L_KNE, R_KNE};
    s.framingCue = "on all fours, side-on so i can see your torso and legs";
    // form: uzatırken gövde sabit + düz kalsın (bird-dog dengeyi test eder).
    s.rules = {{RuleKind::TorsoLean, 22.0, View::Unknown, "stay level - don't rotate or arch as you reach out"}};
    return s;
  }
  if (name == "calfraise") {
    s.name = "calfraise";                      // parmak ucuna yüksel
    s.primaryLeft  = {L_KNE, L_ANK, L_FT};     // ayak bileği açısı: diz-bilek-ayak ucu
    s.primaryRight = {R_KNE, R_ANK, R_FT};
    s.bottomAngle = 125.0;                     // taban yerde
    s.topAngle = 145.0;                        // parmak ucunda (açı açılır)
    s.emaAlpha = 0.35;                         // dar açı aralığı: biraz daha sakin izle
    s.goodRepSecMin = 0.8;
    s.framingPoints = {L_KNE, R_KNE, L_ANK, R_ANK, L_FT, R_FT};
    s.framingCue = "i need your knees, ankles and feet - point the camera lower";
    // form: dik dur, öne düşme — denge için gövdeyi eğmek yükselişi çalar.
    s.rules = {{RuleKind::TorsoLean, 25.0, View::Unknown, "stay tall - rise straight up, don't lean forward"}};
    return s;
  }
  if (name == "jumpingjack") {
    s.name = "jumpingjack";
    s.primaryLeft  = {L_HIP, L_SHO, L_ELB};    // omuz açısı: kol yanda ~20°, tepede ~160°
    s.primaryRight = {R_HIP, R_SHO, R_ELB};
    s.bottomAngle = 40.0;                      // kollar aşağıda
    s.topAngle = 140.0;                        // kollar tepede — orada sayar
    s.goodRepSecMin = 0.35;                    // hızlı bir hareket, ceza yeme
    s.goodRepSecMax = 3.0;
    s.framingPoints = {L_SHO, R_SHO, L_ELB, R_ELB, L_HIP, R_HIP};
    s.framingCue = "i need your arms and torso in the frame";
    s.rules = {{RuleKind::TorsoLean, 30.0, View::Unknown, "stay tall - don't lean as you jump"}};
    return s;
  }
  if (name == "armraise") {
    s.name = "armraise";                       // kol öne/yana yukarı (fizyo klasiği)
    s.primaryLeft  = {L_HIP, L_SHO, L_ELB};
    s.primaryRight = {R_HIP, R_SHO, R_ELB};
    s.bottomAngle = 40.0;
    s.topAngle = 150.0;
    s.goodRepSecMin = 1.0;
    s.framingPoints = {L_SHO, R_SHO, L_ELB, R_ELB, L_HIP, R_HIP};
    s.framingCue = "i need your arms and torso in the frame";
    // form: gövde dik kalsın — momentum için sallanma, kolu izole et.
    s.rules = {{RuleKind::TorsoLean, 25.0, View::Unknown, "keep still - raise with your shoulder, no body swing"}};
    return s;
  }

  // ── HOLD (izometrik) hareketler: salınım yok, hedef açı bandında geçirilen
  // SÜRE + form kararlılığı ölçülür. plank line, wall-sit knee, hollow, superman. ──
  if (name == "plank" || name == "frontplank" || name == "front-plank") {
    s.name = "plank"; s.kind = MoveKind::Hold;
    s.holdJoint = {L_SHO, L_HIP, L_KNE};   // omuz-kalça-diz hattı (düz olmalı)
    s.primaryLeft = {L_SHO, L_HIP, L_KNE}; s.primaryRight = {R_SHO, R_HIP, R_KNE};   // güven+açı kapısı
    s.holdMin = 155.0; s.holdMax = 195.0;  // gövde tek çizgi (~180°); sarkma/pike dışarı
    s.holdTiltMin = 55.0; s.holdTiltMax = 125.0;   // YATAY gövde: ayakta dururken sayılmaz
    s.framingPoints = {L_SHO, R_SHO, L_HIP, R_HIP, L_KNE, R_KNE, L_ANK, R_ANK};
    s.framingCue = "get side-on so i can see your shoulders, hips and ankles in one line";
    s.rules = {{RuleKind::HipSag, 160.0, View::Unknown, "hips are dropping - lift them into the line"}};
    return s;
  }
  if (name == "sideplank" || name == "side-plank" || name == "sidebridge" || name == "side bridge") {
    s.name = "sideplank"; s.kind = MoveKind::Hold;
    s.holdJoint = {L_SHO, L_HIP, L_ANK};   // omuz-kalça-ayak hattı (düz)
    s.primaryLeft = {L_SHO, L_HIP, L_ANK}; s.primaryRight = {R_SHO, R_HIP, R_ANK};
    s.holdMin = 155.0; s.holdMax = 195.0;
    s.holdTiltMin = 55.0; s.holdTiltMax = 125.0;   // yatay gövde
    s.framingPoints = {L_SHO, L_HIP, L_KNE, L_ANK};
    s.framingCue = "face me side-on with your shoulder, hip and ankle stacked";
    s.rules = {{RuleKind::HipSag, 160.0, View::Unknown, "keep your hip up - don't let it sink"}};
    return s;
  }
  if (name == "wallsit" || name == "wall-sit" || name == "wall sit") {
    s.name = "wallsit"; s.kind = MoveKind::Hold;
    s.holdJoint = {L_HIP, L_KNE, L_ANK};   // diz ~90° tutulmalı
    s.primaryLeft = {L_HIP, L_KNE, L_ANK}; s.primaryRight = {R_HIP, R_KNE, R_ANK};
    s.holdMin = 75.0; s.holdMax = 110.0;
    s.holdTiltMin = 0.0; s.holdTiltMax = 45.0;   // DİK gövde (duvara yaslı otur)
    s.framingPoints = {L_HIP, R_HIP, L_KNE, R_KNE, L_ANK, R_ANK};
    s.framingCue = "side-on so i can see your hips, knees and ankles - knees at ninety";
    s.rules = {{RuleKind::TorsoLean, 30.0, View::Unknown, "sit tall against the wall - back flat"}};
    return s;
  }
  if (name == "hollowhold" || name == "hollow hold" || name == "hollow body hold" || name == "hollow-body-hold") {
    s.name = "hollowhold"; s.kind = MoveKind::Hold;
    s.holdJoint = {L_SHO, L_HIP, L_KNE};   // gövde-bacak hafif kapalı (dishing)
    s.primaryLeft = {L_SHO, L_HIP, L_KNE}; s.primaryRight = {R_SHO, R_HIP, R_KNE};
    s.holdMin = 120.0; s.holdMax = 165.0;
    s.holdTiltMin = 45.0; s.holdTiltMax = 135.0;   // sırtüstü, gövde yataya yakın
    s.framingPoints = {L_SHO, R_SHO, L_HIP, R_HIP, L_KNE, R_KNE};
    s.framingCue = "lie side-on so i can see your torso and legs";
    // form: gövde-bacak çizgisi çok açılmasın (bel yerden kopmasın = hollow bozulur).
    s.rules = {{RuleKind::HipSag, 175.0, View::Unknown, "keep your lower back pressed down - don't let it arch up"}};
    return s;
  }
  if (name == "superman" || name == "superman-hold" || name == "supermanhold") {
    s.name = "superman"; s.kind = MoveKind::Hold;
    s.holdJoint = {L_SHO, L_HIP, L_KNE};   // sırt ekstansiyonu: gövde-bacak hattı açık+kalkık
    s.primaryLeft = {L_SHO, L_HIP, L_KNE}; s.primaryRight = {R_SHO, R_HIP, R_KNE};
    s.holdMin = 160.0; s.holdMax = 200.0;
    s.holdTiltMin = 45.0; s.holdTiltMax = 135.0;   // yüzüstü yatay
    s.framingPoints = {L_SHO, R_SHO, L_HIP, R_HIP, L_KNE, R_KNE};
    s.framingCue = "lie facedown side-on so i can see your back line";
    return s;
  }

  // squat — varsayılan; bilinmeyen isim de güvenle buraya düşer.
  s.name = "squat";
  s.primaryLeft  = {L_HIP, L_KNE, L_ANK};   // diz = kalça-diz-ayakbileği
  s.primaryRight = {R_HIP, R_KNE, R_ANK};
  s.bottomAngle = 120.0;   // 110'du — kameraya dönük squat açıyı olduğundan düz gösteriyor, gerçek dip sayılsın
  s.topAngle = 155.0;
  // Damla "eğildiğimi görüyor ama saymıyor": dip eşiği artık kişinin gerçek
  // ayakta duruşundan 42° bükülme (o kadar çömelirse squat sayılır). Sabit 120
  // taban güvenlik ağı olarak kalır — adaptif eşik ondan daha derin olmaz.
  s.adaptiveBottom = true;
  s.adaptiveDrop = 42.0;
  // masada oturan kullanıcı squat yapamaz; sessiz kalma, dürüstçe söyle.
  s.framingCue = "stand up and step back so your knees and hips are in frame - squats need your legs";
  // form kuralları: veri. gövde dikeyden 55°'den fazla eğilmesin (her görüşte);
  // dizler bilek genişliğinin %72'sinden fazla içe çökmesin (sadece önden okunur).
  s.rules = {
    {RuleKind::TorsoLean, 55.0, View::Unknown, "keep your chest up - back straighter"},
    {RuleKind::KneeValgus, 0.72, View::Front, "push your knees out"},
  };
  return s;
}

// ── koçlanabilir katalog: kanonik 14 + aile varyantları, sırayla, tekrarsız.
// UI bu listeyi motorun kendisinden okur (tek kaynak; elle liste yok). repBased
// = MoveKind::Rep. Kanonik liste builtinMove'daki dallarla birebir tutulur. ──
std::vector<CoachEntry> coachableMoves() {
  static const char* kCanon[] = {
    // REP kanonik
    "squat", "sumosquat", "lunge", "sidelunge", "pushup", "kneelingpushup",
    "glutebridge", "situp", "press", "kickback", "birddog", "calfraise",
    "jumpingjack", "armraise",
    // HOLD kanonik
    "plank", "sideplank", "wallsit", "hollowhold", "superman",
  };
  std::vector<CoachEntry> out;
  auto add = [&](const std::string& n, const std::string& base) {
    for (const auto& e : out) if (e.name == n) return;   // tekrarsız
    MoveSpec s = builtinMove(n);
    out.push_back({n, base, s.kind == MoveKind::Rep});
  };
  for (const char* n : kCanon) add(n, n);                 // kanonik: base kendisi
  for (const auto& v : kVariants) add(v.alias, v.family); // varyant: base ailesi
  return out;
}

void Engine::setCalibration(bool on) {
  calibOn_ = on;
  calibrated_ = false;
  calibCount_ = 0;
  calibRetries_ = 0;
  ratioMissStreak_ = 0;
  for (auto& v : calibSamples_) v.clear();
  for (auto& v : boneSamples_) v.clear();
  for (int i = 0; i < kBoneN; i++) { boneLen_[i] = 0; boneUsable_[i] = false; }
}

// ── One Euro (Casiez ve ark. 2012): hıza uyarlanan alçak geçiren. dt gerçek kare
// aralığından gelir — motor zaten zaman-farkında, filtre de öyle olmalı: 30fps'te
// de 60fps'te de aynı derece/saniye davranışı verir (EMA bunu veremezdi).
double Engine::euroApply(double x, double tMs) {
  double dt = (euroLastT_ >= 0 && tMs > euroLastT_) ? (tMs - euroLastT_) / 1000.0 : (1.0 / 30.0);
  dt = std::min(dt, 0.25);   // uzun kopmada dev dt filtreyi "kapatmasın"
  euroLastT_ = tMs;
  if (!euroInit_) { euroX_ = x; euroDx_ = 0; euroInit_ = true; return x; }
  auto alpha = [](double cutoff, double dt) {
    double tau = 1.0 / (2.0 * M_PI * cutoff);
    return 1.0 / (1.0 + tau / dt);
  };
  double dx = (x - euroX_) / dt;
  double aD = alpha(spec_.euroDCutoff, dt);
  euroDx_ = aD * dx + (1.0 - aD) * euroDx_;
  double cutoff = spec_.euroMinCutoff + spec_.euroBeta * std::fabs(euroDx_);
  double a = alpha(cutoff, dt);
  euroX_ = a * x + (1.0 - a) * euroX_;
  return euroX_;
}

void Engine::reset() {
  smooth_ = -1.0;
  prevSmooth_ = -1.0;
  haveSmooth_ = false;
  spikeHold_ = false;
  euroInit_ = false;
  euroX_ = 0; euroDx_ = 0; euroLastT_ = -1;
  // Faz 2: kemik kilidi yeniden öğrenilir (açık/kapalı ayarı korunur),
  // poz seçimi hafızası ve çizim filtreleri sıfırlanır.
  for (auto& v : boneSamples_) v.clear();
  for (int i = 0; i < kBoneN; i++) { boneLen_[i] = 0; boneUsable_[i] = false; }
  solvedWorld_.clear();
  lastCore_.clear();
  lastCoreT_ = -1;
  smoothScreen_.clear();
  for (int i = 0; i < 33; i++) { visEuroInit_[i] = false; visX_[i] = visY_[i] = visDx_[i] = visDy_[i] = 0; }
  visEuroLastT_ = -1;
  for (int i = 0; i < 33; i++) { kf_[i].reset(); occludedFor_[i] = 0; }
  kfLastT_ = -1;
  for (int i = 0; i < 33; i++) wkf_[i].reset();
  wkfLastT_ = -1;
  refinedWorld_.clear();
  prevFrameT_ = -1;
  // kalibrasyon: açık/kapalı ayarı KORUNUR, öğrenilen vücut yeniden öğrenilir
  calibrated_ = false;
  calibCount_ = 0;
  calibRetries_ = 0;
  ratioMissStreak_ = 0;
  for (auto& v : calibSamples_) v.clear();
  phaseTop_ = true;
  topRest_ = -1.0; obsHigh_ = -1.0; obsLow_ = -1.0; bottomLive_ = -1.0; topLive_ = -1.0;   // adaptif band yeniden öğrenilir
  heldSec_ = 0; totalHeldSec_ = 0; holdInBand_ = false; holdQualitySum_ = 0; holdFrames_ = 0;
  bestHoldSec_ = 0; curHoldRunSec_ = 0;   // hold modu sıfırla
  reps_ = 0;
  halfReps_ = 0;
  rejectedReps_ = 0;
  inExcursion_ = false;
  excursionMin_ = 1e9;
  fakeT_ = 0;
  lastTrackedT_ = -1;
  inRep_ = false;
  repStartT_ = 0;
  repMinA_ = 1e9;
  repMinT_ = 0;
  repMaxAsym_ = 0;
  lastRepAsym_ = -1;
  asymRepSum_ = 0; asymRepN_ = 0;
  classifier_.reset();
  lastScore_ = -1;
  lastRepSec_ = 0;
  scoreSum_ = 0;
  violMask_ = 0;
  lastFormIssues_ = 0;
  // plan config (targetReps_/totalSets_/restSec_) KORUNUR; sadece ilerleme sıfırlanır.
  currentSet_ = 1;
  repsInSet_ = 0;
  resting_ = false;
  restEndT_ = 0;
  workoutDone_ = false;
  bestScore_ = -1;
  cleanReps_ = 0;
  startT_ = -1;
  lastT_ = 0;
}

Summary Engine::summary() const {
  Summary s;
  s.reps = reps_;
  s.halfReps = halfReps_;
  s.totalSets = totalSets_;
  s.avgScore = reps_ > 0 ? (int)std::lround(scoreSum_ / reps_) : -1;
  s.bestScore = bestScore_;
  s.cleanReps = cleanReps_;
  s.avgAsymmetry = asymRepN_ > 0 ? (int)std::lround(asymRepSum_ / asymRepN_) : -1;
  s.workoutComplete = workoutDone_;
  s.durationSec = startT_ >= 0 ? std::max(0.0, (lastT_ - startT_) / 1000.0) : 0.0;
  if (targetReps_ > 0)
    s.setsCompleted = workoutDone_ ? totalSets_ : (currentSet_ - 1 + (resting_ ? 1 : 0));
  // HOLD özeti
  s.isHold = spec_.kind == MoveKind::Hold;
  if (s.isHold) {
    s.heldSeconds = totalHeldSec_;   // TÜM setlerin toplamı (heldSec_ set başı sıfırlanır)
    s.bestHoldSeconds = bestHoldSec_;
    s.holdQualityPct = holdFrames_ > 0 ? (int)std::lround(100.0 * holdQualitySum_ / holdFrames_) : -1;
  }
  return s;
}

void Engine::setPlan(int targetReps, int totalSets, double restSeconds) {
  targetReps_ = std::max(0, targetReps);
  totalSets_ = std::max(1, totalSets);
  restSec_ = std::max(0.0, restSeconds);
  // yeni plan = yeni antrenman: ilerlemeyi sıfırla, ama yumuşatma/faz durmasın.
  currentSet_ = 1;
  repsInSet_ = 0;
  resting_ = false;
  restEndT_ = 0;
  workoutDone_ = false;
}

void Engine::skipRest() {
  if (!resting_) return;
  resting_ = false;
  currentSet_++;
  repsInSet_ = 0;
}

static double clamp01(double v) { return std::max(0.0, std::min(1.0, v)); }

// ── kalibrasyon ölçüleri: gövde boyuna oranlanmış uzuv uzunlukları.
// [uyluk, baldır, üst kol, ön kol, omuz genişliği] / gövde. Ölçekten bağımsız:
// kameraya yaklaşınca da aynı kalır; başka bir vücutta ya da çöp okumada kalmaz.
// w = dünya noktaları (geometri), vis = ekran noktaları (görünürlük kaynağı).
static bool bodyRatiosFrame(const std::vector<Landmark>& w,
                            const std::vector<Landmark>& vis,
                            double out[], bool have[]) {
  enum { L_SHO = 11, R_SHO = 12, L_ELB = 13, R_ELB = 14, L_WRI = 15, R_WRI = 16,
         L_HIP = 23, R_HIP = 24, L_KNE = 25, R_KNE = 26, L_ANK = 27, R_ANK = 28 };
  auto dist = [&](int a, int b) {
    double dx = w[a].x - w[b].x, dy = w[a].y - w[b].y, dz = w[a].z - w[b].z;
    return std::sqrt(dx * dx + dy * dy + dz * dz);
  };
  auto seen = [&](int a, int b) { return vis[a].visibility >= 0.5 && vis[b].visibility >= 0.5; };
  if (!seen(L_SHO, R_SHO) || !seen(L_HIP, R_HIP)) return false;
  double tx = (w[L_SHO].x + w[R_SHO].x) / 2.0 - (w[L_HIP].x + w[R_HIP].x) / 2.0;
  double ty = (w[L_SHO].y + w[R_SHO].y) / 2.0 - (w[L_HIP].y + w[R_HIP].y) / 2.0;
  double tz = (w[L_SHO].z + w[R_SHO].z) / 2.0 - (w[L_HIP].z + w[R_HIP].z) / 2.0;
  double torso = std::sqrt(tx * tx + ty * ty + tz * tz);
  if (torso < 1e-6) return false;
  // her uzuv iki taraftan görüneni kullanır; ikisi de görünüyorsa ortalama.
  auto limb = [&](int aL, int bL, int aR, int bR, double& val) {
    bool l = seen(aL, bL), r = seen(aR, bR);
    if (!l && !r) return false;
    double s = 0; int n = 0;
    if (l) { s += dist(aL, bL); n++; }
    if (r) { s += dist(aR, bR); n++; }
    val = (s / n) / torso;
    return true;
  };
  have[0] = limb(L_HIP, L_KNE, R_HIP, R_KNE, out[0]);   // uyluk
  have[1] = limb(L_KNE, L_ANK, R_KNE, R_ANK, out[1]);   // baldır
  have[2] = limb(L_SHO, L_ELB, R_SHO, R_ELB, out[2]);   // üst kol
  have[3] = limb(L_ELB, L_WRI, R_ELB, R_WRI, out[3]);   // ön kol
  out[4] = dist(L_SHO, R_SHO) / torso; have[4] = true;  // omuz genişliği
  return true;
}

static double medianOf(std::vector<double> v) {
  std::nth_element(v.begin(), v.begin() + v.size() / 2, v.end());
  return v[v.size() / 2];
}

// bir örnek kümesinin varyasyon katsayısı (std/ortalama). Kalibrasyon kalite
// kapısı: bu yüksekse örnekler saçılmış demektir (kişi kalibrasyon sırasında
// hareket etmiş / kadraj oynamış) ve o ölçü GÜVENİLMEZ — kilide alınmamalı.
static double coeffVar(const std::vector<double>& v) {
  if (v.size() < 3) return 1e9;
  double sum = 0; for (double x : v) sum += x;
  double mean = sum / v.size();
  if (std::fabs(mean) < 1e-9) return 1e9;
  double s2 = 0; for (double x : v) s2 += (x - mean) * (x - mean);
  return std::sqrt(s2 / v.size()) / std::fabs(mean);
}

// ── Faz 2: mutlak kemik uzunlukları (metre, dünya uzayı). İki taraf tek havuzda:
// vücut simetrik, örnek iki katına çıkar. [uyluk, baldır, üst kol, ön kol].
static void boneLengthsFrame(const std::vector<Landmark>& w,
                             const std::vector<Landmark>& vis,
                             double out[], bool have[]) {
  auto dist = [&](int a, int b) {
    double dx = w[a].x - w[b].x, dy = w[a].y - w[b].y, dz = w[a].z - w[b].z;
    return std::sqrt(dx * dx + dy * dy + dz * dz);
  };
  auto seen = [&](int a, int b) { return vis[a].visibility >= 0.5 && vis[b].visibility >= 0.5; };
  auto limb = [&](int aL, int bL, int aR, int bR, double& val) {
    bool l = seen(aL, bL), r = seen(aR, bR);
    if (!l && !r) return false;
    double s = 0; int n = 0;
    if (l) { s += dist(aL, bL); n++; }
    if (r) { s += dist(aR, bR); n++; }
    val = s / n;
    return true;
  };
  have[0] = limb(L_HIP, L_KNE, R_HIP, R_KNE, out[0]);
  have[1] = limb(L_KNE, L_ANK, R_KNE, R_ANK, out[1]);
  have[2] = limb(L_SHO, L_ELB, R_SHO, R_ELB, out[2]);
  have[3] = limb(L_ELB, L_WRI, R_ELB, R_WRI, out[3]);
}

// ── Faz 2: kemik kilidi çözümü. CGI mantığının çekirdeği: dedektörün önerdiği
// YÖN kabul edilir, UZUNLUK edilmez. Kalça/omuz çapa kalır, zincir aşağı doğru
// hiyerarşik oturtulur: çocuk = çözülmüş ebeveyn + öğrenilen uzunluk × gözlenen
// segment yönü. Kemik uzayamadığı için eklem "kayamaz". ──
void Engine::solveBones(const std::vector<Landmark>& world,
                        const std::vector<Landmark>& vis, std::vector<Landmark>& out) const {
  out = world;
  auto place = [&](int parent, int child, int bone) {
    if (!boneUsable_[bone]) return;
    if (vis[parent].visibility < 0.5 || vis[child].visibility < 0.5) return;
    // yön GÖZLENEN segmentten (ebeveynin ham hali → çocuğun ham hali):
    // ebeveyn düzeltmesi yönü bozmasın, sadece zinciri taşısın.
    double dx = world[child].x - world[parent].x;
    double dy = world[child].y - world[parent].y;
    double dz = world[child].z - world[parent].z;
    double m = std::sqrt(dx * dx + dy * dy + dz * dz);
    if (m < 1e-6) return;
    out[child].x = out[parent].x + boneLen_[bone] * dx / m;
    out[child].y = out[parent].y + boneLen_[bone] * dy / m;
    out[child].z = out[parent].z + boneLen_[bone] * dz / m;
  };
  // bacaklar: kalça çapa → diz → ayak bileği
  place(L_HIP, L_KNE, 0); place(L_KNE, L_ANK, 1);
  place(R_HIP, R_KNE, 0); place(R_KNE, R_ANK, 1);
  // kollar: omuz çapa → dirsek → bilek
  place(L_SHO, L_ELB, 2); place(L_ELB, L_WRI, 3);
  place(R_SHO, R_ELB, 2); place(R_ELB, R_WRI, 3);

  // ── anatomik eklem limitleri (ik.hpp): kemik kilidi UZUNLUĞU sabitledi, bu
  // AÇIYI yasal aralığa çeker. Dedektör dizi geriye bükerse (imkansız) sınıra
  // döndürülür, kemik boyu korunarak. Çözülmüş iskelet artık hem doğru boyda
  // hem anatomik olarak mümkün — mocap "cleanup" aşamasının çekirdeği. ──
  if (ikOn_) {
    double P[99];
    for (int i = 0; i < 33; i++) { P[i*3] = out[i].x; P[i*3+1] = out[i].y; P[i*3+2] = out[i].z; }
    clampHumanLimits(P);
    for (int i = 0; i < 33; i++) { out[i].x = P[i*3]; out[i].y = P[i*3+1]; out[i].z = P[i*3+2]; }
  }
}

// ── Faz 2: aday puanı (küçük iyi). Kadraja ikinci kişi girince motor kimi
// izleyeceğini buna göre seçer: (a) son kabul edilen poza yakınlık — iskelet
// bir karede odanın öbür ucuna ışınlanamaz, (b) kalibre edilen vücut oranlarına
// uyum — hoca Damla'nın oranlarını taşımaz, (c) görünürlük (eşitlik bozucu). ──
double Engine::candidateScore(const std::vector<Landmark>& screen,
                              const std::vector<Landmark>& world) const {
  static const int core[] = {L_SHO, R_SHO, L_HIP, R_HIP, L_KNE, R_KNE};
  double temporal = 0;
  if (lastCore_.size() == 33) {
    double s = 0; int n = 0;
    for (int idx : core) {
      if (screen[idx].visibility < 0.3 || lastCore_[idx].visibility < 0.3) continue;
      double dx = screen[idx].x - lastCore_[idx].x, dy = screen[idx].y - lastCore_[idx].y;
      s += std::sqrt(dx * dx + dy * dy); n++;
    }
    temporal = n ? s / n : 0.5;   // hiç ortak nokta yok = şüpheli aday
  }
  double ratioErr = 0.15;   // ölçülemiyorsa nötr-hafif ceza
  if (calibrated_ && world.size() >= 33) {
    double ratios[kRatioN]; bool have[kRatioN];
    if (bodyRatiosFrame(world, screen, ratios, have)) {
      double s = 0; int n = 0;
      for (int i = 0; i < kRatioN; i++) {
        if (!ratioUsable_[i] || !have[i] || bodyRatio_[i] < 1e-6) continue;
        s += std::fabs(ratios[i] - bodyRatio_[i]) / bodyRatio_[i]; n++;
      }
      if (n >= 2) ratioErr = s / n;
    }
  }
  double vis = 0;
  for (int idx : core) vis += screen[idx].visibility;
  vis /= 6.0;
  return 2.0 * temporal + 1.5 * ratioErr + 0.3 * (1.0 - vis);
}

// bir adayın kalibre vücuda oran uyumsuzluğu: EN KÖTÜ bağıl hata (ölçülemedi = -1).
// Ortalama değil en kötü: kimlik en bariz farktan belli olur — kısa bacaklı
// yabancının kolları normal diye ortalamada aklanmasın.
double Engine::ratioMismatch(const std::vector<Landmark>& screen,
                             const std::vector<Landmark>& world) const {
  if (!calibrated_ || world.size() < 33) return -1.0;
  double ratios[kRatioN]; bool have[kRatioN];
  if (!bodyRatiosFrame(world, screen, ratios, have)) return -1.0;
  double worst = -1.0; int n = 0;
  for (int i = 0; i < kRatioN; i++) {
    if (!ratioUsable_[i] || !have[i] || bodyRatio_[i] < 1e-6) continue;
    worst = std::max(worst, std::fabs(ratios[i] - bodyRatio_[i]) / bodyRatio_[i]); n++;
  }
  return n >= 2 ? worst : -1.0;
}

Reading Engine::updateBest(const std::vector<std::vector<Landmark>>& screens,
                           const std::vector<std::vector<Landmark>>& worlds, double timestampMs) {
  static const std::vector<Landmark> kEmpty;
  if (screens.empty()) return update(kEmpty, kEmpty, timestampMs);

  // ── TEK ADAY = VETO YOK (15 Tem gercek-kamera dersi): kadrajda tek kisi
  // varken oran vetosu GERCEK gurultude sahibini de reddedebiliyor (derin
  // squat'ta uyluk orani sapar). Tek adayda motorun icindeki savas-testli
  // kalibrasyon kapisi (2/3 oran, %30 tolerans) yeterli koruma. Veto yalniz
  // COK adayli karede "kimi izleyecegim" secimi icin devrededir. ──
  if (screens.size() == 1) {
    const std::vector<Landmark>& w = worlds.empty() ? kEmpty : worlds[0];
    // bariz farkli vucut (%35+ en kotu oran) yine reddedilir; onun altindaki
    // benzerlikte sahibine oncelik — benzer oranli iki insani oranla ayirmak
    // fiziken mumkun degil, o is zaman tutarliligina kalir.
    double mis = screens[0].size() >= 33 ? ratioMismatch(screens[0], w) : -1.0;
    if (mis >= 0.0 && mis > 0.35) {
      Reading r = update(kEmpty, kEmpty, timestampMs);
      r.pickedPose = -1;
      r.message = "i only coach the body i learned - step back in when you are ready";
      return r;
    }
    Reading r = update(screens[0], w, timestampMs);
    r.pickedPose = 0;
    return r;
  }

  // ── SERT KİLİT (Damla, 14 Tem): motor tek kişilik — kalibre ettiği vücut
  // dışında KİMSEYİ koçlamaz. Aday önce elemeden geçer: (a) kalibre orana
  // ölçülebilir ve %25'ten fazla uymayan vücut DİSKALİFİYE (ceza değil, veto),
  // (b) az önce izlediğimiz vücuttan ekranın öbür ucuna ışınlanan aday da öyle.
  // Hiç aday kalmazsa motor yabancıya geçmek yerine BEKLER. ──
  int best = -1;
  double bestScore = 1e18;
  const bool coreFresh = !lastCore_.empty() && lastCoreT_ >= 0 &&
                         timestampMs >= 0 && timestampMs - lastCoreT_ < 1500.0;
  for (size_t i = 0; i < screens.size(); i++) {
    if (screens[i].size() < 33) continue;
    const std::vector<Landmark>& w = i < worlds.size() ? worlds[i] : kEmpty;
    double mis = ratioMismatch(screens[i], w);
    if (mis >= 0.0 && mis > 0.25) continue;            // bu vücut sen değilsin: veto
    if (coreFresh && screens.size() > 1) {
      // az önce izlenen vücuttan tek karede 0.35 ekran birimi ışınlanma da veto —
      // oranı ölçülemeyen (dünya verisiz) yabancıya karşı ikinci kilit.
      static const int core[] = {L_SHO, R_SHO, L_HIP, R_HIP, L_KNE, R_KNE};
      double s = 0; int n = 0;
      for (int idx : core) {
        if (screens[i][idx].visibility < 0.3 || lastCore_[idx].visibility < 0.3) continue;
        double dx = screens[i][idx].x - lastCore_[idx].x, dy = screens[i][idx].y - lastCore_[idx].y;
        s += std::sqrt(dx * dx + dy * dy); n++;
      }
      if (n >= 3 && s / n > 0.35) continue;
    }
    double sc = candidateScore(screens[i], w);
    if (sc < bestScore) { bestScore = sc; best = (int)i; }
  }
  if (best < 0) {
    // kadrajda izlediğimiz vücut yok: durumu İLERLETME (yabancı filtrelere
    // sızmasın), sayaçları taşıyan boş okuma dön ve dürüstçe bekle.
    Reading r = update(kEmpty, kEmpty, timestampMs);
    r.pickedPose = -1;
    r.message = "i only coach the body i learned - step back in when you are ready";
    return r;
  }
  Reading r = update(screens[best], (size_t)best < worlds.size() ? worlds[best] : kEmpty, timestampMs);
  r.pickedPose = best;
  return r;
}

// ── Faz 2: çizim iskeleti — ekran noktalarını nokta başına One Euro'dan geçir.
// Görsel katman: sayma/açı matematiğine karışmaz, sadece ekrandaki iskeletin
// "ağ gibi" sakin durmasını sağlar. Parametreler ekran uzayı için (birim 0..1).
void Engine::smoothScreenApply(const std::vector<Landmark>& screen, double tMs) {
  const double minCut = 1.2, beta = 5.0, dCut = 1.0;
  double dt = (visEuroLastT_ >= 0 && tMs > visEuroLastT_) ? (tMs - visEuroLastT_) / 1000.0 : (1.0 / 30.0);
  dt = std::min(dt, 0.25);
  visEuroLastT_ = tMs;
  smoothScreen_ = screen;
  auto alpha = [](double cutoff, double dt) {
    double tau = 1.0 / (2.0 * M_PI * cutoff);
    return 1.0 / (1.0 + tau / dt);
  };
  for (int i = 0; i < 33; i++) {
    if (screen[i].visibility < 0.3) { visEuroInit_[i] = false; continue; }   // görünmeyeni filtreleme
    if (!visEuroInit_[i]) {
      visX_[i] = screen[i].x; visY_[i] = screen[i].y;
      visDx_[i] = 0; visDy_[i] = 0;
      visEuroInit_[i] = true;
      continue;
    }
    double aD = alpha(dCut, dt);
    double dx = (screen[i].x - visX_[i]) / dt, dy = (screen[i].y - visY_[i]) / dt;
    visDx_[i] = aD * dx + (1 - aD) * visDx_[i];
    visDy_[i] = aD * dy + (1 - aD) * visDy_[i];
    double ax = alpha(minCut + beta * std::fabs(visDx_[i]), dt);
    double ay = alpha(minCut + beta * std::fabs(visDy_[i]), dt);
    visX_[i] = ax * screen[i].x + (1 - ax) * visX_[i];
    visY_[i] = ay * screen[i].y + (1 - ay) * visY_[i];
    smoothScreen_[i].x = visX_[i];
    smoothScreen_[i].y = visY_[i];
  }
}

// ── Kalman occlusion-recovery. Her nokta için: predict (dt ileri sar), sonra
// GÖRÜNÜRSE correct (görünürlüğe göre R ölçekli — bulanık ölçüme az güven),
// GÖRÜNMEZSE yalnız tahmin. Kayıp nokta son bilinen hızla akar; kısa occlusion
// boyunca iskelet zıplamaz. Uzun kopmada (>~0.5s) tahmine güvenmeyi bırakır:
// nokta "yok" işaretlenir, hayali bir uzvu çizmeyiz. ──
void Engine::kalmanApply(const std::vector<Landmark>& screen, double tMs, std::vector<Landmark>& out) {
  double dt = (kfLastT_ >= 0 && tMs > kfLastT_) ? (tMs - kfLastT_) / 1000.0 : (1.0 / 30.0);
  if (dt <= 0) dt = 1.0 / 30.0;
  dt = std::min(dt, 0.25);
  kfLastT_ = tMs;
  out = screen;
  const int kMaxOccludeFrames = 15;   // ~0.5s @30fps: sonrasında tahmine güvenme
  for (int i = 0; i < 33; i++) {
    // ekran uzayı (0..1) Kalman: hızlı harekete uyum + titreme bastırma. DÜRÜSTLÜK
    // (CS-dekan): world Kalman kalmansweep ile ölçüldü ama BU (ekran) filtre el
    // ayarlı — çünkü ÇİZİM iskeletini besliyor (occlusion'da akma), sayma/açıya
    // GİRMİYOR. O yüzden jitter/gecikme optimalliği ürünün çekirdek sayısını
    // etkilemez; görsel sükunet için "yeterince iyi" kabul edildi, ölçülmedi.
    kf_[i].setParams(60.0, 2e-3);
    kf_[i].predict(dt);
    const double vis = screen[i].visibility;
    if (vis >= 0.3) {
      // görünür: düzelt. düşük görünürlük → büyük R ölçeği → ölçüme az güven.
      double rScale = std::max(0.5, 1.0 / std::max(0.05, vis));
      kf_[i].correct(screen[i].x, screen[i].y, screen[i].z, rScale);
      occludedFor_[i] = 0;
      out[i].x = kf_[i].kx.x; out[i].y = kf_[i].ky.x; out[i].z = kf_[i].kz.x;
    } else if (kf_[i].ready() && occludedFor_[i] < kMaxOccludeFrames) {
      // görünmez ama yakın zamanda görüldü: tahminle akıt, görünürlüğü sönümle
      occludedFor_[i]++;
      out[i].x = kf_[i].kx.x; out[i].y = kf_[i].ky.x; out[i].z = kf_[i].kz.x;
      out[i].visibility = std::max(0.0, 0.5 - 0.03 * occludedFor_[i]);   // "tahmin ediyorum" sinyali
    } else {
      // uzun kayıp: hayali uzuv çizme, olduğu gibi (görünmez) bırak
      occludedFor_[i] = kMaxOccludeFrames;
    }
  }
}

// ── world (3B metrik) poz iyileştirme. MediaPipe'ın world-z'si kare-kare zıplar;
// açı geometrisi buradan okunduğu için bu gürültü doğrudan açıya ve saymaya
// sızıyordu. Her world noktasını kendi 3B Kalman'ından geçiriyoruz: predict +
// confidence-ağırlıklı correct. z ekseni en gürültülü olduğu için filtre orada
// en çok kazanç sağlar. Çıktı: temporal-tutarlı metrik iskelet. ──
void Engine::refineWorld(const std::vector<Landmark>& world, double tMs, std::vector<Landmark>& out) {
  out = world;
  if (world.size() < 33) return;
  double dt = (wkfLastT_ >= 0 && tMs > wkfLastT_) ? (tMs - wkfLastT_) / 1000.0 : (1.0 / 30.0);
  if (dt <= 0) dt = 1.0 / 30.0;
  dt = std::min(dt, 0.25);
  wkfLastT_ = tMs;
  for (int i = 0; i < 33; i++) {
    // world uzayı metre ölçekli. q/r bench sweep ile seçilir (setWorldKalmanParams);
    // varsayılan 10/2e-4 (bench kalmansweep ile seçildi), el kararı değil.
    wkf_[i].setParams(wkfQ_, wkfR_);
    wkf_[i].predict(dt);
    double vis = world[i].visibility;
    if (vis >= 0.3) {
      double rScale = std::max(0.6, 1.0 / std::max(0.05, vis));
      wkf_[i].correct(world[i].x, world[i].y, world[i].z, rScale);
      out[i].x = wkf_[i].kx.x; out[i].y = wkf_[i].ky.x; out[i].z = wkf_[i].kz.x;
    } else if (wkf_[i].ready()) {
      out[i].x = wkf_[i].kx.x; out[i].y = wkf_[i].ky.x; out[i].z = wkf_[i].kz.x;
    }
  }
}

Reading Engine::update(const std::vector<Landmark>& p, double timestampMs) {
  static const std::vector<Landmark> kNoWorld;
  return update(p, kNoWorld, timestampMs);
}

Reading Engine::update(const std::vector<Landmark>& p,
                       const std::vector<Landmark>& world, double timestampMs) {
  double t = timestampMs;
  if (t < 0) { fakeT_ += 1000.0 / 30.0; t = fakeT_; }   // saat verilmediyse ~30fps varsay
  if (startT_ < 0) startT_ = t;                          // seans süresi için (Aşama 14)
  lastT_ = t;
  // Faz 2: gerçek kare aralığı (ışınlanma kapısı zaman-farkında çalışsın)
  const double dtSec = (prevFrameT_ >= 0 && t > prevFrameT_)
                       ? std::min((t - prevFrameT_) / 1000.0, 0.25) : (1.0 / 30.0);
  prevFrameT_ = t;
  solvedWorld_.clear();   // bu karenin çözümü aşağıda üretilir; bayat kalmasın

  // ── Aşama 13: dinlenme geri sayımı. Motor zaman-farkında olduğu için süreyi
  // KENDİ tutar — dinlenirken vücut kadrajda olmasa da (mola verip çıkabilirsin)
  // saat ilerlesin diye bu, "seni göremiyorum" dönüşünden ÖNCE. Süre dolunca
  // sıradaki sete otomatik geçilir. ──
  if (resting_) {
    if (t >= restEndT_) { resting_ = false; currentSet_++; repsInSet_ = 0; }
  }

  Reading r;
  r.phase = phaseTop_ ? Phase::Top : Phase::Bottom;
  r.reps = reps_;
  r.halfReps = halfReps_;
  r.rejectedReps = rejectedReps_;
  r.lastRepScore = lastScore_;
  r.lastRepSeconds = lastRepSec_;
  r.avgRepScore = reps_ > 0 ? (int)std::lround(scoreSum_ / reps_) : -1;
  r.currentSet = currentSet_;
  r.totalSets = totalSets_;
  r.repsInSet = repsInSet_;
  r.targetReps = targetReps_;
  r.resting = resting_;
  r.restRemaining = resting_ ? std::max(0.0, (restEndT_ - t) / 1000.0) : 0.0;
  r.workoutComplete = workoutDone_;

  if (p.size() < 33) { r.message = "i cannot see you yet"; return r; }

  // ── 3B kaynak seçimi: kadraj/görünürlük EKRAN verisinden (kamera ne görüyor),
  // açı geometrisi varsa DÜNYA verisinden (vücut gerçekte nasıl duruyor). Dünya
  // verisi önce Kalman'dan geçirilir (refineWorld): kare-kare z gürültüsü açıya
  // sızmasın — tüm açı/sayma/form buradan okuduğu için temeli sağlamlaştırır. ──
  const bool hasWorld = world.size() >= 33;
  if (hasWorld) {
    if (worldRefineOn_) refineWorld(world, t, refinedWorld_);
    else refinedWorld_ = world;   // kapalı: ham world (bench karşılaştırması için)
  }
  const std::vector<Landmark>& g = hasWorld ? refinedWorld_ : p;

  // ── Aşama 5: kadraj doluluğu — bu hareketin İZLEDİĞİ noktaların kaçı görünüyor
  // (squat bacak ister, push-up kol ister; liste MoveSpec verisinden gelir) ──
  static const std::vector<int> kDefaultCore = {L_SHO, R_SHO, L_HIP, R_HIP, L_KNE, R_KNE, L_ANK, R_ANK};
  const std::vector<int>& corePts = spec_.framingPoints.empty() ? kDefaultCore : spec_.framingPoints;
  int seen = 0;
  for (int idx : corePts) if (p[idx].visibility >= 0.5) seen++;
  r.framing = (double)seen / (double)corePts.size();

  // kamera vücudu nereden görüyor: omuz+kalça hattı ekran düzleminde mi (önden)
  // yoksa derinlik ekseninde mi (yandan) yayılmış — form kuralları buna bakacak.
  if (hasWorld) {
    // view/tilt REFINED world'den (g): açılarla aynı kaynak — tutarlılık + tilt
    // gate (plank/wall-sit) kare-kare z gürültüsüyle titremesin.
    double dx = std::fabs(g[L_SHO].x - g[R_SHO].x) + std::fabs(g[L_HIP].x - g[R_HIP].x);
    double dz = std::fabs(g[L_SHO].z - g[R_SHO].z) + std::fabs(g[L_HIP].z - g[R_HIP].z);
    r.view = dx >= dz ? View::Front : View::Side;
    // ── yerçekimi-farkında gövde tilt'i: gövde ekseni (kalça ortası → omuz
    // ortası) ile DİKEY (y ekseni, world'de yerçekimi) arasındaki açı. 0 =
    // dimdik, 90 = yatay. Plank'ı ayakta durmaktan ayıran ölçü bu. ──
    double tx = (g[L_SHO].x + g[R_SHO].x) / 2.0 - (g[L_HIP].x + g[R_HIP].x) / 2.0;
    double ty = (g[L_SHO].y + g[R_SHO].y) / 2.0 - (g[L_HIP].y + g[R_HIP].y) / 2.0;
    double tz = (g[L_SHO].z + g[R_SHO].z) / 2.0 - (g[L_HIP].z + g[R_HIP].z) / 2.0;
    double tm = std::sqrt(tx * tx + ty * ty + tz * tz);
    if (tm > 1e-6) r.torsoTilt = std::acos(std::min(1.0, std::fabs(ty) / tm)) * 180.0 / M_PI;
  }

  // altı ham açı (gösterim).
  r.angles.leftKnee   = angleAt(g, {L_HIP, L_KNE, L_ANK});
  r.angles.rightKnee  = angleAt(g, {R_HIP, R_KNE, R_ANK});
  r.angles.leftHip    = angleAt(g, {L_SHO, L_HIP, L_KNE});
  r.angles.rightHip   = angleAt(g, {R_SHO, R_HIP, R_KNE});
  r.angles.leftElbow  = angleAt(g, {L_SHO, L_ELB, L_WRI});
  r.angles.rightElbow = angleAt(g, {R_SHO, R_ELB, R_WRI});

  // ── Aşama 5: güven kapısı — takip edilen zinciri iki taraftan kontrol et,
  // hangisi daha net görünüyorsa onu kullan; zayıfsa hiç okuma yapma. ──
  auto chainVis = [&](const JointRef& j) {
    return std::min(p[j.a].visibility, std::min(p[j.b].visibility, p[j.c].visibility));
  };
  double visL = chainVis(spec_.primaryLeft);
  double visR = chainVis(spec_.primaryRight);
  double angL = angleAt(g, spec_.primaryLeft);
  double angR = angleAt(g, spec_.primaryRight);
  double raw, bestVis;
  if (visL >= visR) { raw = angL; bestVis = visL; }
  else              { raw = angR; bestVis = visR; }
  r.confidence = bestVis;

  // ── simetri: İKİ taraf da güvenle görünüyorsa sol-sağ izlenen açı farkı.
  // Tek taraf görünürse (yandan duruş) asimetri ölçülemez — dürüstçe -1. ──
  if (visL >= spec_.minVisibility && visR >= spec_.minVisibility && angL >= 0 && angR >= 0) {
    r.asymmetryDeg = std::fabs(angL - angR);
  }

  // ── hareket sınıflandırıcıyı besle: dört büyük eklemin sol-sağ ortalaması +
  // gövde tilt'i. Motor bağımsızca "ne yapılıyor" tahmin eder (seçili hareketten
  // ayrı). İki tarafın ortalaması gürültüye daha dayanıklı; -1'ler atlanır. ──
  auto avg2 = [](double a, double b) {
    if (a >= 0 && b >= 0) return (a + b) / 2.0;
    return a >= 0 ? a : b;   // biri -1 ise diğeri (ikisi de -1 ise -1)
  };
  // ── sınıflandırıcı için HAREKETTEN BAĞIMSIZ asimetri (CS-dekan bulgusu:
  // r.asymmetryDeg SEÇİLİ hareketin çiftinden gelir — push-up seçiliyken
  // dirsek asimetrisini ölçer, lunge'ı ayırmaz). Sınıflandırıcı "kendin tanı"
  // olduğundan asimetriyi de spec'ten bağımsız ölçmeli: dominant BACAK
  // (diz) sol-sağ farkı — lunge'ı squat'tan ayıran gerçek eksen. ──
  double clsAsym = -1.0;
  if (r.angles.leftKnee >= 0 && r.angles.rightKnee >= 0)
    clsAsym = std::fabs(r.angles.leftKnee - r.angles.rightKnee);
  classifier_.feed(avg2(r.angles.leftKnee, r.angles.rightKnee),
                   avg2(r.angles.leftElbow, r.angles.rightElbow),
                   avg2(r.angles.leftHip, r.angles.rightHip),
                   avg2(angleAt(g, {L_HIP, L_SHO, L_ELB}), angleAt(g, {R_HIP, R_SHO, R_ELB})),
                   r.torsoTilt, clsAsym);   // spec-bağımsız diz asimetrisi: squat vs lunge
  {
    double dc = 0;
    std::string dm = classifier_.classify(dc);
    r.detectedMove = dm;
    r.detectedConfidence = dc;
  }

  // ── kadraj: izlenen noktaların yeterince görünmesi lazım. YETERSİZSE kibarca
  // "tam boy gir" der AMA kritik olan: izlenen açı zinciri (raw) OKUNABİLİYORSA
  // motor yine de sayabilir. Diz/bilek görünüyorsa (squat için gereken) framing
  // biraz eksik olsa da (arka plan noktaları) sayma devam eder. Sadece izlenen
  // açının kendisi okunamıyorsa dururuz — o zaman gerçekten sayamayız. ──
  if (r.framing < spec_.minFraming) {
    r.message = spec_.framingCue.empty() ? "step back so your whole body fits the frame" : spec_.framingCue;
    // izlenen açı zinciri hâlâ okunuyorsa (raw geçerli + güven yeterli) DURMA,
    // uyar ama saymaya devam et — kişi tam sığmasa da o hareketi yapıyorsa saysın.
    if (raw < 0.0 || bestVis < spec_.minVisibility) return r;
  }
  if (bestVis < spec_.minVisibility || raw < 0.0) { r.message = "i lost the joints i am watching - check the light and the frame"; return r; }
  r.tracking = true;
  r.rawAngle = raw;

  // ── kalibrasyon + vücut kilidi (önce vücudu tanı, sonra ona kilitlen).
  // dünya verisi şart: uzuv boyu 3B'de bükülmeyle değişmez, ölçünün güvenilir
  // olduğu tek yer orası. dünya verisi olmayan kare es geçilir.
  if (calibOn_ && hasWorld) {
    double ratios[kRatioN]; bool have[kRatioN];
    if (bodyRatiosFrame(world, p, ratios, have)) {
      if (!calibrated_) {
        for (int i = 0; i < kRatioN; i++) if (have[i]) calibSamples_[i].push_back(ratios[i]);
        // Faz 2: aynı karelerden MUTLAK kemik uzunlukları da öğrenilir (kilit için)
        double lens[kBoneN]; bool haveLen[kBoneN];
        boneLengthsFrame(world, p, lens, haveLen);
        for (int i = 0; i < kBoneN; i++) if (haveLen[i]) boneSamples_[i].push_back(lens[i]);
        calibCount_++;
        r.calibrating = true;
        r.calibProgress = (double)calibCount_ / kCalibFrames;
        r.message = "learning your body - one moment";
        if (calibCount_ >= kCalibFrames) {
          // ── TUTARLILIK KAPISI (kalibrasyon güçlendirme): bir ölçü hem yeterli
          // örneğe sahip olmalı HEM de saçılmamış olmalı. Varyasyon katsayısı
          // eşiği aşarsa (kişi kalibrasyon sırasında hareket etti / kadraj
          // oynadı) o ölçü GÜVENİLMEZ — kilide alınmaz. Böylece kirli bir örnek
          // tüm kimlik kilidini bozmaz; kilit yalnız sağlam ölçülere dayanır. ──
          const double kMaxRatioCV = 0.18;   // oran örnekleri: %18 saçılmadan fazlası kirli
          const double kMaxBoneCV = 0.15;    // kemik uzunluğu (metrik): %15
          int usableRatios = 0;
          for (int i = 0; i < kRatioN; i++) {
            bool enough = calibSamples_[i].size() >= (size_t)(kCalibFrames * 3 / 5);
            bool steady = coeffVar(calibSamples_[i]) <= kMaxRatioCV;
            ratioUsable_[i] = enough && steady;
            if (ratioUsable_[i]) { bodyRatio_[i] = medianOf(calibSamples_[i]); usableRatios++; }
            calibSamples_[i].clear();
          }
          for (int i = 0; i < kBoneN; i++) {
            bool enough = boneSamples_[i].size() >= (size_t)(kCalibFrames * 3 / 5);
            bool steady = coeffVar(boneSamples_[i]) <= kMaxBoneCV;
            boneUsable_[i] = enough && steady;
            if (boneUsable_[i]) boneLen_[i] = medianOf(boneSamples_[i]);
            boneSamples_[i].clear();
          }
          // hiç güvenilir oran çıkmadıysa (kişi hep hareket etti) kalibrasyonu
          // BİTİRME, yeniden öğren — "sabit dur" de. En çok bir kez uzatılır ki
          // sonsuz döngü olmasın; ikinci turda ne çıkarsa onunla kilitlen.
          if (usableRatios < 2 && calibRetries_ < 1) {
            calibRetries_++;
            calibCount_ = 0;
            r.message = "hold still for a moment while i learn your body";
          } else {
            calibrated_ = true;
          }
        }
      } else {
        // öğrenilen vücutla karşılaştır: test edilebilen oranların üçte ikisi
        // şaşıyorsa bu okuma bu vücut değil — kareyi reddet, iskelet kaçamaz.
        int tested = 0, bad = 0;
        for (int i = 0; i < kRatioN; i++) {
          if (!ratioUsable_[i] || !have[i] || bodyRatio_[i] < 1e-6) continue;
          tested++;
          if (std::fabs(ratios[i] - bodyRatio_[i]) / bodyRatio_[i] > 0.30) bad++;
        }
        // KİLİT KAYMASI DÜZELTMESİ (denetçi/gerçek-kullanıcı dersi): tek gürültülü
        // kare (MediaPipe kenar/occlusion titremesi) tracking'i düşürüp "kilit
        // kaydı" hissi veriyordu. Artık 5 ARDIŞIK uyumsuz kare gerek — gerçek
        // yabancı 5+ kare düşer, gerçek kullanıcının tek titremesi düşmez.
        if (tested >= 2 && bad * 3 >= tested * 2) {
          if (++ratioMissStreak_ >= 5) {
            r.tracking = false;
            r.message = "that read did not match your body - skipped it";
            return r;
          }
        } else {
          ratioMissStreak_ = 0;
        }
      }
    } else if (!calibrated_) {
      r.calibrating = true;
      r.message = "learning your body - one moment";
    }
  }

  // ── Faz 2: kemik kilidi — vücut öğrenildiyse iskelet, kalibre edilen kemik
  // uzunluklarına hiyerarşik projeksiyonla oturtulur ve TÜM açılar kilitli
  // iskeletten yeniden ölçülür. Dedektörün uzunluk gürültüsü açıya giremez. ──
  if (boneLockOn_ && calibrated_ && hasWorld) {
    // kemik kilidi REFINED world'den çözülür (raw değil): world-Kalman'ın
    // sönümlediği z gürültüsü kilitli iskelete de geçsin, yoksa refineWorld ana
    // yolda boşa giderdi (kilit raw yön vektörü kullanıp gürültüyü geri sokardı).
    solveBones(refinedWorld_, p, solvedWorld_);
    const std::vector<Landmark>& s = solvedWorld_;
    r.angles.leftKnee   = angleAt(s, {L_HIP, L_KNE, L_ANK});
    r.angles.rightKnee  = angleAt(s, {R_HIP, R_KNE, R_ANK});
    r.angles.leftHip    = angleAt(s, {L_SHO, L_HIP, L_KNE});
    r.angles.rightHip   = angleAt(s, {R_SHO, R_HIP, R_KNE});
    r.angles.leftElbow  = angleAt(s, {L_SHO, L_ELB, L_WRI});
    r.angles.rightElbow = angleAt(s, {R_SHO, R_ELB, R_WRI});
    double rawSolved = (visL >= visR) ? angleAt(s, spec_.primaryLeft)
                                      : angleAt(s, spec_.primaryRight);
    if (rawSolved >= 0.0) { raw = rawSolved; r.rawAngle = raw; }
  }

  // ── Faz 2: bu poz kabul edildi — çok kişi seçimi (updateBest) bir sonraki
  // karede "en son kimi izliyordum"u bilsin; çizim iskeleti de üretilsin. ──
  lastCore_ = p;
  lastCoreT_ = t;
  // Kalman occlusion-recovery ÖNCE (kayıp noktaları tahminle doldur), sonra One
  // Euro pürüzsüzleştirme — çizim iskeleti hem occlusion'da akar hem sakin durur.
  std::vector<Landmark> kfScreen;
  kalmanApply(p, t, kfScreen);
  smoothScreenApply(kfScreen, t);

  // ── Aşama 4: yumuşatma + ince takip: tek karelik dev sıçrama (iskeletin
  // eşyaya/başkasına ışınlanması) yutulur; iki kare sürerse gerçek kabul edilir.
  // Filtre varsayılanı One Euro (açı uzayında, hıza uyarlı); EMA yolu ölçüm
  // karşılaştırması için duruyor. ──
  // ── Faz 3 katman 1: EGZERSİZ-ÖNSELLİ hız tavanı. Genel bir sabit yerine
  // eşik hareketin KENDİ fiziğinden türer: tam tekrar range dereceyi en hızlı
  // goodRepSecMin'de tarar → sinüs tepe hızı π·range/T, ×3 güvenlik payı.
  // Squat ~300°/sn'e kilitlenir (sıkı), jumping jack ~1500'e kadar serbest —
  // motor squat sırasında squat'ın fiziğini varsayar. ──
  const double rangeDeg = std::max(10.0, spec_.topAngle - spec_.bottomAngle);
  const double maxVel = std::min(1500.0, std::max(300.0, 3.0 * M_PI * rangeDeg / spec_.goodRepSecMin));
  const bool spike = haveSmooth_ && std::fabs(raw - smooth_) > std::max(25.0, maxVel * dtSec);
  if (spike && !spikeHold_) {
    spikeHold_ = true;                 // bu kareyi yut: yumuşatılmış açı yerinde kalır
  } else {
    spikeHold_ = false;
    if (spec_.useOneEuro) {
      smooth_ = euroApply(raw, t);
      haveSmooth_ = true;
    } else if (!haveSmooth_) { smooth_ = raw; haveSmooth_ = true; }
    else { smooth_ = spec_.emaAlpha * raw + (1.0 - spec_.emaAlpha) * smooth_; }
  }
  r.smoothAngle = smooth_;

  // ── adaptif dip eşiği (Damla: "eğildiğimi görüyor ama saymıyor"). Çalışan
  // eşikler varsayılan olarak spec sabitidir; adaptif açıksa kişinin GERÇEK üst
  // duruşundan türetilir. topRest_ = gözlenen en açık (rahat) açı — dip fazında
  // DEĞİLKEN güncellenir ki çömelme onu aşağı çekmesin. Dip eşiği o duruştan
  // adaptiveDrop kadar aşağıda; ama spec.bottomAngle bir TABAN kalır (adaptif
  // eşik ondan daha derin/katı olamaz — kimse imkansız derinlik zorlanmasın).
  // Üst eşik de duruşa göre biraz altta tutulur ki çıkış güvenle "üst"e dönsün. ──
  double bottomTh = spec_.bottomAngle;
  double topTh = spec_.topAngle;
  if (spec_.adaptiveBottom) {
    // ── İKİ ayrı üst-uç izleyici, çünkü iki yol iki farklı şey ister:
    // (1) topRest_ = ESKİ semantik, yalnız ÜST fazda + yavaş sönümlü. Kişinin
    //     "rahat duruş" açısıdır; sıkışmamış yolun dip eşiğini (drop) sürer.
    //     Sığ-ama-gerçek squat testinin dayandığı davranış budur — DEĞİŞMEZ.
    // (2) obsHigh_/obsLow_ = per-KARE gözlenen band uçları (faz bağımsız). Sıkışmış
    //     veride kişi baştan Bottom fazına kilitlenip topRest_ donsa bile band
    //     öğrenilmeye devam eder → döngü açılır (mmfit squat: standing hiç
    //     "dik görünmüyor", faz-kapılı öğrenme donardı, per-kare öğrenme kurtarır). ──
    if (phaseTop_ && smooth_ > 0) {
      if (topRest_ < 0 || smooth_ > topRest_) topRest_ = smooth_;
      else topRest_ = 0.98 * topRest_ + 0.02 * smooth_;
    }
    if (smooth_ > 0) {
      if (obsHigh_ < 0 || smooth_ > obsHigh_) obsHigh_ = smooth_;             // en açığa hızlı atla
      else obsHigh_ = 0.995 * obsHigh_ + 0.005 * smooth_;                     // yavaş sön
      if (obsLow_ < 0 || smooth_ < obsLow_)   obsLow_ = smooth_;              // en dibe hızlı atla
      else obsLow_ = 0.995 * obsLow_ + 0.005 * smooth_;                       // yavaş sön
    }
    // ── SIKIŞMA TESPİTİ: kişinin gözlenen üst açısı spec'in beklediği düz-duruşa
    // yakınsa (obsHigh ≈ spec.topAngle) ROM SIKIŞMASI YOK → eski/mutlak yol
    // (dip = topRest−adaptiveDrop, spec.bottomAngle TABAN; top = spec.topAngle).
    // Sağlıklı kamerada davranış AYNEN korunur. Üst açı spec top'un belirgin
    // altına sıkışmışsa (mmfit squat ~96° vs 155°) eşikler bandın İÇİNE iner. ──
    const bool compressed = obsHigh_ > 0 && obsHigh_ < spec_.topAngle - 15.0;
    if (compressed && obsLow_ >= 0 && (obsHigh_ - obsLow_) >= 20.0) {
      double range = obsHigh_ - obsLow_;
      // eşikler tamamen gözlenen bandın içinde; mutlak spec sabitine takılmaz.
      // dip = üstten %55 aşağı, top = üstten %28 aşağı → aralarında histerezis.
      bottomLive_ = obsHigh_ - 0.55 * range;
      topLive_    = obsHigh_ - 0.28 * range;
      bottomTh = bottomLive_;
      topTh    = topLive_;
    } else if (topRest_ > 0) {
      // sıkışma yok: ESKİ davranış (dip adaptiveDrop + spec taban, top = spec).
      double adaptBottom = topRest_ - spec_.adaptiveDrop;
      bottomLive_ = std::max(spec_.bottomAngle, adaptBottom);
      topLive_ = std::max(bottomLive_ + 10.0, topRest_ - spec_.adaptiveDrop * 0.30);
      bottomTh = bottomLive_;
      topTh    = std::min(spec_.topAngle, topLive_);
    }
  }

  // derinlik: üst eşikte 0, dip eşiğinde 1 (daha derini 1'e kırpılır).
  r.depth = std::max(0.0, std::min(1.0, (topTh - smooth_) / (topTh - bottomTh)));
  // açıklanabilirlik: bu karede kullanılan aktif eşikleri dışarı ver.
  r.activeTopTh = topTh;
  r.activeBottomTh = bottomTh;
  r.adaptiveActive = spec_.adaptiveBottom &&
                     (std::fabs(topTh - spec_.topAngle) > 0.5 || std::fabs(bottomTh - spec_.bottomAngle) > 0.5);

  // yön: yumuşatılmış sinyalin eğimi. diz açısı DÜŞERSE çömeliyoruz.
  if (prevSmooth_ >= 0.0) {
    double d = smooth_ - prevSmooth_;
    if (d < -0.6) r.motion = Motion::Down;
    else if (d > 0.6) r.motion = Motion::Up;
    else r.motion = Motion::Hold;
  }
  prevSmooth_ = smooth_;

  // ── Kalite skoru: tekrar penceresi. Üstten ilk sarkma anında açılır; en derin
  // açıyı ve zamanını tutar (iniş/çıkış süresi ayrımı için). Takip 2 sn'den uzun
  // koparsa pencere atılır — eski zamanlarla sahte süre üretmeyelim. ──
  if (inRep_ && lastTrackedT_ >= 0 && t - lastTrackedT_ > 2000.0) inRep_ = false;
  lastTrackedT_ = t;
  if (!inRep_ && phaseTop_ && smooth_ < topTh) {
    inRep_ = true;
    repStartT_ = t;
    repMinA_ = smooth_;
    repMinT_ = t;
    repMaxAsym_ = 0;   // yeni tekrar: asimetri birikimi sıfırdan
  }
  if (inRep_ && smooth_ < repMinA_) { repMinA_ = smooth_; repMinT_ = t; }
  // tekrar boyunca en büyük sol-sağ farkı tut (dip bölgesinde en anlamlı)
  if (inRep_ && r.asymmetryDeg >= 0 && r.asymmetryDeg > repMaxAsym_) repMaxAsym_ = r.asymmetryDeg;

  // ── Aşama 9: form kuralları — hareketin anlamlı bölümünde (derinlik > 0.4),
  // sadece 3B veri varken değerlendirilir: emin olmadan form yargılanmaz.
  // Görüşe bağlı kural yanlış açıdan hiç bakılmaz (valgus yandan görünmez).
  // HOLD modunda kurallar SÜREKLİ değerlendirilir (derinlik yok, tutuş boyunca
  // form izlenir); rep modunda yalnız hareketin anlamlı derininde (depth>0.4). ──
  const bool evalRules = hasWorld && (spec_.kind == MoveKind::Hold || r.depth > 0.4);
  if (evalRules) {
    for (unsigned i = 0; i < spec_.rules.size() && i < 32; i++) {
      const FormRule& rule = spec_.rules[i];
      if (rule.view != View::Unknown && rule.view != r.view) continue;
      bool bad = false;
      if (rule.kind == RuleKind::TorsoLean) {
        // REFINED world (g): açı/tilt ile aynı kaynak, form cue z-gürültüsüyle titremesin
        double tx = (g[L_SHO].x + g[R_SHO].x) / 2.0 - (g[L_HIP].x + g[R_HIP].x) / 2.0;
        double ty = (g[L_SHO].y + g[R_SHO].y) / 2.0 - (g[L_HIP].y + g[R_HIP].y) / 2.0;
        double tz = (g[L_SHO].z + g[R_SHO].z) / 2.0 - (g[L_HIP].z + g[R_HIP].z) / 2.0;
        double m = std::sqrt(tx * tx + ty * ty + tz * tz);
        if (m > 1e-6) {
          double lean = std::acos(std::min(1.0, std::fabs(ty) / m)) * 180.0 / M_PI;
          bad = lean > rule.param;
        }
      } else if (rule.kind == RuleKind::KneeValgus) {
        double knees  = std::fabs(g[L_KNE].x - g[R_KNE].x);
        double ankles = std::fabs(g[L_ANK].x - g[R_ANK].x);
        if (ankles > 1e-3) bad = knees < rule.param * ankles;
      } else if (rule.kind == RuleKind::HipSag) {
        double hl = angleAt(g, {L_SHO, L_HIP, L_KNE});
        double hr = angleAt(g, {R_SHO, R_HIP, R_KNE});
        double h = std::max(hl, hr);   // iki taraftan iyi olanı; ikisi de kırıksa kırık
        bad = h > 0.0 && h < rule.param;
      }
      if (bad) {
        if (r.formCue.empty()) r.formCue = rule.cue;
        if (inRep_) violMask_ |= (1u << i);
      }
    }
  }

  // ── Aşama 6: durum makinesi (histerezis) ──
  // ── Aşama 7: sayma — dipten üste TAM dönüş = bir tekrar. Bottom'a ancak alt
  // eşiği geçerek girilebildiği için Bottom→Top geçişi her zaman tam bir
  // döngüdür; yarım inişler fazı hiç değiştirmez, dolayısıyla sayılmaz. ──
  // dinlenirken ya da antrenman bittiğinde faz izlenmeye devam eder ama tekrar
  // SAYILMAZ — mola sırasında yaptığın hareket sıradaki setin hanesine yazılmaz.
  // kalibrasyon sürerken tekrar sayılmaz: motor daha kimin vücudu olduğunu öğreniyor.
  const bool countingPaused = resting_ || workoutDone_ || r.calibrating;

  // ── HOLD modu: rep salınımı yerine hedef açı bandında geçirilen SÜRE +
  // form kararlılığı. Takip edilen açı [holdMin, holdMax] bandındaysa süre
  // birikir; formCue varsa o karenin kalitesi düşer. Banttan çıkınca kesintisiz
  // tutuş biter (en uzunu bestHoldSec_'e yazılır) ama toplam heldSec_ korunur. ──
  if (spec_.kind == MoveKind::Hold) {
    r.isHold = true;
    double holdA = smooth_;   // takip edilen açı (holdJoint boşsa primary kullanıldı)
    if (spec_.holdJoint.a != spec_.holdJoint.b) {
      double hj = angleAt(g, spec_.holdJoint);
      if (hj >= 0) holdA = hj;
    }
    // yerçekimi kapısı: 3B varsa gövde doğru oryantasyonda mı (plank yatay,
    // wall-sit dik). 2B'de tilt ölçülemez → kapı açık (eski davranış).
    const bool tiltOk = r.torsoTilt < 0 ||
                        (r.torsoTilt >= spec_.holdTiltMin && r.torsoTilt <= spec_.holdTiltMax);
    const bool inBand = holdA >= spec_.holdMin && holdA <= spec_.holdMax && tiltOk;
    if (inBand && !countingPaused) {
      heldSec_ += dtSec;
      totalHeldSec_ += dtSec;   // seans toplamı (set başı sıfırlanmaz)
      curHoldRunSec_ += dtSec;
      if (curHoldRunSec_ > bestHoldSec_) bestHoldSec_ = curHoldRunSec_;
      // canlı kalite: iki bileşen. (a) form temizliği (formCue varsa düşük),
      // (b) bant MERKEZİNE yakınlık — tam ortada tutuş 1.0, kenarda (kırılmaya
      // yakın) düşer. Bu ikincisi kural GEREKTİRMEZ, her hold için çalışır
      // (superman gibi form kuralı olmayanda bile kalite anlamlı kalır). ──
      double formQ = r.formCue.empty() ? 1.0 : 0.4;
      double mid = (spec_.holdMin + spec_.holdMax) / 2.0;
      double halfBand = std::max(1.0, (spec_.holdMax - spec_.holdMin) / 2.0);
      double centerQ = 1.0 - std::min(1.0, std::fabs(holdA - mid) / halfBand);   // 1 orta, 0 kenar
      double frameQ = 0.6 * formQ + 0.4 * (0.4 + 0.6 * centerQ);   // form ağır, merkez destek
      holdQualitySum_ += frameQ; holdFrames_++;
      r.inHold = true;
      if (!holdInBand_) r.repTick = true;   // banda İLK girişte "tık" (haptik/ses)
    } else {
      curHoldRunSec_ = 0;   // banttan çıktı: kesintisiz tutuş sıfırlanır
      r.inHold = false;
      if (holdInBand_ && !inBand) {
        // az önce banttaydı, şimdi çıktı: neden çıktığını söyle
        if (holdA < spec_.holdMin) r.message = "you're breaking the hold - get back into position";
        else if (holdA > spec_.holdMax) r.message = "ease back into the hold";
      }
    }
    holdInBand_ = inBand;
    r.heldSeconds = heldSec_;
    r.holdQuality = holdFrames_ > 0 ? holdQualitySum_ / holdFrames_ : 0.0;
    // set/plan: hold'da "reps" yerine hedef SÜRE (targetReps_ saniye yorumlanır).
    // hedef süreye ulaşınca set biter — rep akışıyla aynı plan mantığı.
    if (targetReps_ > 0 && !countingPaused && heldSec_ >= targetReps_ && !workoutDone_) {
      r.setTick = true;
      if (currentSet_ >= totalSets_) workoutDone_ = true;
      else { resting_ = true; restEndT_ = t + restSec_ * 1000.0; heldSec_ = 0; curHoldRunSec_ = 0; }
    }
    // hold modu rep state machine'ini ATLAR — okuma tazelenip döner.
    // (rejectedReps hold'da hep 0; alan tutarlılığı için yine de taşınır.)
    r.reps = reps_; r.halfReps = halfReps_; r.rejectedReps = rejectedReps_;
    r.currentSet = currentSet_; r.repsInSet = repsInSet_;
    r.resting = resting_; r.restRemaining = resting_ ? std::max(0.0, (restEndT_ - t) / 1000.0) : 0.0;
    r.workoutComplete = workoutDone_;
    return r;
  }

  if (phaseTop_) {
    if (smooth_ < bottomTh) phaseTop_ = false;
  } else if (smooth_ > topTh) {
    phaseTop_ = true;
    if (countingPaused) {
      // sayma durdu: pencereyi sessizce kapat, puanlama yapma.
      inRep_ = false; repMinA_ = 1e9; violMask_ = 0;
    } else {
    // ── tekrar penceresi üstte kapandı. ÖNCE puanla, SONRA %60 kapısıyla
    // saymaya karar ver. reps_++ artık koşulsuz DEĞİL: dibe inen ama formu
    // eşiğin altında kalan rep SAYILMAZ (rejectedReps_), koç "o saymadı" der.
    // Not: inRep_ yoksa (pencere açılmadan üste dönüş) eskiden de skorlanmazdı;
    // o durumda ne sayılır ne reddedilir — sadece faz güncellenir. ──
    if (inRep_) {
      // tekrar bitti → puanla. Üç bileşen: derinlik (yarısı), tempo, kontrol.
      // Kontrol = iniş serbest düşüş olmasın (eksantrik faz çıkışa göre çok kısaysa
      // ağırlığı bırakıyorsun demektir). Hepsi MoveSpec verisinden beslenir.
      double durSec  = (t - repStartT_) / 1000.0;
      double descSec = (repMinT_ - repStartT_) / 1000.0;
      double ascSec  = (t - repMinT_) / 1000.0;
      double depthS = clamp01((topTh - repMinA_) / (topTh - bottomTh));
      double tempoS = 1.0;
      if (durSec < spec_.goodRepSecMin)      tempoS = clamp01(durSec / spec_.goodRepSecMin);
      else if (durSec > spec_.goodRepSecMax) tempoS = clamp01(spec_.goodRepSecMax / durSec);
      double controlS = ascSec <= 0.05 ? 1.0 : clamp01(descSec / (0.4 * ascSec));
      int score = (int)std::lround(100.0 * (0.5 * depthS + 0.3 * tempoS + 0.2 * controlS));
      // form ihlali puandan düşer: farklı kural başına 12 puan.
      int formIssues = __builtin_popcount(violMask_);
      score = std::max(0, score - 12 * formIssues);
      violMask_ = 0;
      lastScore_ = score;
      lastFormIssues_ = formIssues;
      lastRepSec_ = durSec;
      // simetri: bu tekrarda görülen en büyük sol-sağ farkı sakla (rapor + ipucu).
      lastRepAsym_ = repMaxAsym_ > 0 ? (int)std::lround(repMaxAsym_) : -1;
      inRep_ = false;
      repMinA_ = 1e9;

      // ── %60 KABUL KAPISI (Loop 03): skor eşiğin altındaysa rep SAYILMAZ. ──
      if (score < spec_.acceptPct) {
        rejectedReps_++;
        r.rejectTick = true;
        r.lastRejectReason = "form " + std::to_string(score) + " < " + std::to_string(spec_.acceptPct);
        r.repComment = "that one didn't count - form " + std::to_string(score)
                     + ", need " + std::to_string(spec_.acceptPct) + "+";
        r.message = "that one didn't count - clean it up, form was " + std::to_string(score);
        // reddedilen rep skora/ortalamaya/sete girmez; simetri sayacına da girmez.
      } else {
        // ── SAYILDI ──
        reps_++;
        r.repTick = true;
        if (lastRepAsym_ >= 0) { asymRepSum_ += lastRepAsym_; asymRepN_++; }   // seans ortalaması

        // ── Faz 3 katman 1: tekrar yorumu. Koç sayıyı söylemez, CÜMLE kurar —
        // öncelik sırası: en çok neyi düzeltmesi gerekiyorsa onu duyar. ──
        if (depthS >= 0.92 && tempoS >= 0.9 && controlS >= 0.85 && formIssues == 0)
          r.repComment = "textbook - deep and controlled";
        else if (formIssues > 0)
          r.repComment = "counted - but fix your form first";
        else if (depthS < 0.75)
          r.repComment = "counted - sink deeper next time";
        else if (durSec < spec_.goodRepSecMin)
          r.repComment = "a bit rushed - slow it down";
        else if (controlS < 0.6)
          r.repComment = "you dropped into it - own the way down";
        else if (durSec > spec_.goodRepSecMax)
          r.repComment = "you stalled in there - keep it flowing";
        else if (score >= 85)
          r.repComment = "clean rep";
        else
          r.repComment = "solid - tighten it up";
        // belirgin dengesizlik (>15°) form sorunundan sonra ama depth/tempo
        // yorumlarından ÖNCE gelir: telafi, "biraz daha in"den önemli bir uyarı.
        if (lastRepAsym_ > 15 && formIssues == 0)
          r.repComment = "counted - but one side is doing more work than the other";

        scoreSum_ += score;
        if (score > bestScore_) bestScore_ = score;   // Aşama 14
        if (formIssues == 0) cleanReps_++;

        // ── Aşama 13: set ilerlemesi. Hedefli planda tekrar bu setin hanesine
        // yazılır; hedefe ulaşınca set biter (setTick), son set değilse dinlenme
        // başlar, son setse antrenman tamamlanır. (Reddedilen rep sete girmez.) ──
        if (targetReps_ > 0) {
          repsInSet_++;
          if (repsInSet_ >= targetReps_) {
            r.setTick = true;
            if (currentSet_ >= totalSets_) {
              workoutDone_ = true;
            } else {
              resting_ = true;
              restEndT_ = t + restSec_ * 1000.0;
            }
          }
        }
      }
    }
    }  // ── countingPaused değilse ── (Aşama 13)
  }
  r.phase = phaseTop_ ? Phase::Top : Phase::Bottom;

  // ── Aşama 8: yarım tekrar — üst fazdayken eşiğin altına sarkıp dibe
  // ULAŞMADAN geri dönen inişi yakala. Dibe ulaşan iniş faza geçer ve buraya
  // hiç düşmez; ufak kıpırtılar da halfRepDepth'i geçemediği için elenir. ──
  if (!phaseTop_) {
    inExcursion_ = false;              // gerçek inişe dönüştü, yarım değil
    excursionMin_ = 1e9;
  } else if (smooth_ < topTh) {
    inExcursion_ = true;
    excursionMin_ = std::min(excursionMin_, smooth_);
  } else if (inExcursion_) {           // üste dönüldü ama Bottom hiç görülmedi
    // yarım-rep eşiği: "anlamlı ama dipsiz iniş" = aktif top eşiğinden, hareketin
    // KENDİ tam ROM'unun (spec top-bottom) halfRepDepth katı kadar aşağı sarkmış
    // ama bottom eşiğine ulaşmamış iniş. Referans aktif topTh (band sıkışmışsa
    // orası), derinlik MİKTARI spec ROM'undan sabit — böylece adaptif band yarım
    // tanımını kaydırmaz (kıpırtı yarım sayılmaz), ama sıkışmış veride topTh'a
    // göre ölçülür (mutlak 155'e takılıp her kareyi yarım saymaz).
    double deepEnough = topTh - spec_.halfRepDepth * (spec_.topAngle - spec_.bottomAngle);
    if (excursionMin_ < deepEnough) {
      halfReps_++;
      r.halfTick = true;
      r.message = "that one did not count - go all the way down";
    }
    inExcursion_ = false;
    excursionMin_ = 1e9;
    inRep_ = false;              // yarım iniş skorlanmaz, pencereyi kapat
    repMinA_ = 1e9;
    violMask_ = 0;
  }

  r.reps = reps_;
  r.halfReps = halfReps_;
  r.rejectedReps = rejectedReps_;
  r.lastRepScore = lastScore_;
  r.lastRepSeconds = lastRepSec_;
  r.avgRepScore = reps_ > 0 ? (int)std::lround(scoreSum_ / reps_) : -1;
  r.lastRepFormIssues = lastFormIssues_;
  r.lastRepAsymmetry = lastRepAsym_;
  // set alanları bu karede değişmiş olabilir (setTick dinlenmeyi başlatır) → tazele.
  r.currentSet = currentSet_;
  r.repsInSet = repsInSet_;
  r.resting = resting_;
  r.restRemaining = resting_ ? std::max(0.0, (restEndT_ - t) / 1000.0) : 0.0;
  r.workoutComplete = workoutDone_;
  return r;
}

}  // namespace coach
