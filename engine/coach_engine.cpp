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
MoveSpec builtinMove(const std::string& name) {
  MoveSpec s;
  s.emaAlpha = 0.5;        // 0.4'tü: Damla "hassas değil" dedi — ham sinyali daha çabuk izle
  s.minVisibility = 0.5;
  s.minFraming = 0.75;

  if (name == "pushup") {
    s.name = "pushup";
    s.primaryLeft  = {L_SHO, L_ELB, L_WRI};   // dirsek = omuz-dirsek-bilek
    s.primaryRight = {R_SHO, R_ELB, R_WRI};
    s.bottomAngle = 95.0;
    s.topAngle = 150.0;
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
    return s;
  }

  if (name == "sumosquat") {
    s.name = "sumosquat";
    s.primaryLeft  = {L_HIP, L_KNE, L_ANK};
    s.primaryRight = {R_HIP, R_KNE, R_ANK};
    s.bottomAngle = 120.0;   // 110'du — kameraya dönük squat açıyı olduğundan düz gösteriyor, gerçek dip sayılsın
    s.topAngle = 155.0;
    s.rules = {{RuleKind::TorsoLean, 40.0, View::Unknown, "stay tall - sumo keeps the chest up"}};
    return s;
  }
  if (name == "sidelunge") {
    s.name = "sidelunge";
    s.primaryLeft  = {L_HIP, L_KNE, L_ANK};   // bükülen bacak (netse o izlenir)
    s.primaryRight = {R_HIP, R_KNE, R_ANK};
    s.bottomAngle = 105.0;
    s.topAngle = 160.0;
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
    return s;
  }

  // squat — varsayılan; bilinmeyen isim de güvenle buraya düşer.
  s.name = "squat";
  s.primaryLeft  = {L_HIP, L_KNE, L_ANK};   // diz = kalça-diz-ayakbileği
  s.primaryRight = {R_HIP, R_KNE, R_ANK};
  s.bottomAngle = 120.0;   // 110'du — kameraya dönük squat açıyı olduğundan düz gösteriyor, gerçek dip sayılsın
  s.topAngle = 155.0;
  // form kuralları: veri. gövde dikeyden 55°'den fazla eğilmesin (her görüşte);
  // dizler bilek genişliğinin %72'sinden fazla içe çökmesin (sadece önden okunur).
  s.rules = {
    {RuleKind::TorsoLean, 55.0, View::Unknown, "keep your chest up - back straighter"},
    {RuleKind::KneeValgus, 0.72, View::Front, "push your knees out"},
  };
  return s;
}

void Engine::setCalibration(bool on) {
  calibOn_ = on;
  calibrated_ = false;
  calibCount_ = 0;
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
  prevFrameT_ = -1;
  // kalibrasyon: açık/kapalı ayarı KORUNUR, öğrenilen vücut yeniden öğrenilir
  calibrated_ = false;
  calibCount_ = 0;
  for (auto& v : calibSamples_) v.clear();
  phaseTop_ = true;
  reps_ = 0;
  halfReps_ = 0;
  inExcursion_ = false;
  excursionMin_ = 1e9;
  fakeT_ = 0;
  lastTrackedT_ = -1;
  inRep_ = false;
  repStartT_ = 0;
  repMinA_ = 1e9;
  repMinT_ = 0;
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
  s.workoutComplete = workoutDone_;
  s.durationSec = startT_ >= 0 ? std::max(0.0, (lastT_ - startT_) / 1000.0) : 0.0;
  if (targetReps_ > 0)
    s.setsCompleted = workoutDone_ ? totalSets_ : (currentSet_ - 1 + (resting_ ? 1 : 0));
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
  // açı geometrisi varsa DÜNYA verisinden (vücut gerçekte nasıl duruyor). ──
  const bool hasWorld = world.size() >= 33;
  const std::vector<Landmark>& g = hasWorld ? world : p;

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
    double dx = std::fabs(world[L_SHO].x - world[R_SHO].x) + std::fabs(world[L_HIP].x - world[R_HIP].x);
    double dz = std::fabs(world[L_SHO].z - world[R_SHO].z) + std::fabs(world[L_HIP].z - world[R_HIP].z);
    r.view = dx >= dz ? View::Front : View::Side;
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
  double raw, bestVis;
  if (visL >= visR) { raw = angleAt(g, spec_.primaryLeft);  bestVis = visL; }
  else              { raw = angleAt(g, spec_.primaryRight); bestVis = visR; }
  r.confidence = bestVis;

  if (r.framing < spec_.minFraming) {
    // hareketin kendi cümlesi varsa onu söyle: push-up bacak istemez, bunu bilsin.
    r.message = spec_.framingCue.empty() ? "step back so your whole body fits the frame" : spec_.framingCue;
    return r;
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
          for (int i = 0; i < kRatioN; i++) {
            ratioUsable_[i] = calibSamples_[i].size() >= (size_t)(kCalibFrames * 3 / 5);
            if (ratioUsable_[i]) bodyRatio_[i] = medianOf(calibSamples_[i]);
            calibSamples_[i].clear();
          }
          for (int i = 0; i < kBoneN; i++) {
            boneUsable_[i] = boneSamples_[i].size() >= (size_t)(kCalibFrames * 3 / 5);
            if (boneUsable_[i]) boneLen_[i] = medianOf(boneSamples_[i]);
            boneSamples_[i].clear();
          }
          calibrated_ = true;
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
        if (tested >= 2 && bad * 3 >= tested * 2) {
          r.tracking = false;
          r.message = "that read did not match your body - skipped it";
          return r;
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
    solveBones(world, p, solvedWorld_);
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
  smoothScreenApply(p, t);

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

  // derinlik: topAngle'da 0, bottomAngle'da 1 (daha derini 1'e kırpılır).
  r.depth = std::max(0.0, std::min(1.0, (spec_.topAngle - smooth_) / (spec_.topAngle - spec_.bottomAngle)));

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
  if (!inRep_ && phaseTop_ && smooth_ < spec_.topAngle) {
    inRep_ = true;
    repStartT_ = t;
    repMinA_ = smooth_;
    repMinT_ = t;
  }
  if (inRep_ && smooth_ < repMinA_) { repMinA_ = smooth_; repMinT_ = t; }

  // ── Aşama 9: form kuralları — hareketin anlamlı bölümünde (derinlik > 0.4),
  // sadece 3B veri varken değerlendirilir: emin olmadan form yargılanmaz.
  // Görüşe bağlı kural yanlış açıdan hiç bakılmaz (valgus yandan görünmez). ──
  if (hasWorld && r.depth > 0.4) {
    for (unsigned i = 0; i < spec_.rules.size() && i < 32; i++) {
      const FormRule& rule = spec_.rules[i];
      if (rule.view != View::Unknown && rule.view != r.view) continue;
      bool bad = false;
      if (rule.kind == RuleKind::TorsoLean) {
        double tx = (world[L_SHO].x + world[R_SHO].x) / 2.0 - (world[L_HIP].x + world[R_HIP].x) / 2.0;
        double ty = (world[L_SHO].y + world[R_SHO].y) / 2.0 - (world[L_HIP].y + world[R_HIP].y) / 2.0;
        double tz = (world[L_SHO].z + world[R_SHO].z) / 2.0 - (world[L_HIP].z + world[R_HIP].z) / 2.0;
        double m = std::sqrt(tx * tx + ty * ty + tz * tz);
        if (m > 1e-6) {
          double lean = std::acos(std::min(1.0, std::fabs(ty) / m)) * 180.0 / M_PI;
          bad = lean > rule.param;
        }
      } else if (rule.kind == RuleKind::KneeValgus) {
        double knees  = std::fabs(world[L_KNE].x - world[R_KNE].x);
        double ankles = std::fabs(world[L_ANK].x - world[R_ANK].x);
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
  if (phaseTop_) {
    if (smooth_ < spec_.bottomAngle) phaseTop_ = false;
  } else if (smooth_ > spec_.topAngle) {
    phaseTop_ = true;
    if (countingPaused) {
      // sayma durdu: pencereyi sessizce kapat, puanlama yapma.
      inRep_ = false; repMinA_ = 1e9; violMask_ = 0;
    } else {
    reps_++;
    r.repTick = true;

    // ── Aşama 13: set ilerlemesi. Hedefli planda tekrar bu setin hanesine
    // yazılır; hedefe ulaşınca set biter (setTick), son set değilse dinlenme
    // başlar, son setse antrenman tamamlanır. ──
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

    // tekrar bitti → puanla. Üç bileşen: derinlik (yarısı), tempo, kontrol.
    // Kontrol = iniş serbest düşüş olmasın (eksantrik faz çıkışa göre çok kısaysa
    // ağırlığı bırakıyorsun demektir). Hepsi MoveSpec verisinden beslenir.
    if (inRep_) {
      double durSec  = (t - repStartT_) / 1000.0;
      double descSec = (repMinT_ - repStartT_) / 1000.0;
      double ascSec  = (t - repMinT_) / 1000.0;
      double depthS = clamp01((spec_.topAngle - repMinA_) / (spec_.topAngle - spec_.bottomAngle));
      double tempoS = 1.0;
      if (durSec < spec_.goodRepSecMin)      tempoS = clamp01(durSec / spec_.goodRepSecMin);
      else if (durSec > spec_.goodRepSecMax) tempoS = clamp01(spec_.goodRepSecMax / durSec);
      double controlS = ascSec <= 0.05 ? 1.0 : clamp01(descSec / (0.4 * ascSec));
      lastScore_ = (int)std::lround(100.0 * (0.5 * depthS + 0.3 * tempoS + 0.2 * controlS));
      // form ihlali puandan düşer: farklı kural başına 12 puan.
      lastFormIssues_ = __builtin_popcount(violMask_);
      lastScore_ = std::max(0, lastScore_ - 12 * lastFormIssues_);
      violMask_ = 0;
      // ── Faz 3 katman 1: tekrar yorumu. Koç sayıyı söylemez, CÜMLE kurar —
      // öncelik sırası: en çok neyi düzeltmesi gerekiyorsa onu duyar. ──
      if (depthS >= 0.92 && tempoS >= 0.9 && controlS >= 0.85 && lastFormIssues_ == 0)
        r.repComment = "textbook - deep and controlled";
      else if (lastFormIssues_ > 0)
        r.repComment = "counted - but fix your form first";
      else if (depthS < 0.75)
        r.repComment = "counted - sink deeper next time";
      else if (durSec < spec_.goodRepSecMin)
        r.repComment = "a bit rushed - slow it down";
      else if (controlS < 0.6)
        r.repComment = "you dropped into it - own the way down";
      else if (durSec > spec_.goodRepSecMax)
        r.repComment = "you stalled in there - keep it flowing";
      else if (lastScore_ >= 85)
        r.repComment = "clean rep";
      else
        r.repComment = "solid - tighten it up";
      lastRepSec_ = durSec;
      scoreSum_ += lastScore_;
      if (lastScore_ > bestScore_) bestScore_ = lastScore_;   // Aşama 14
      if (lastFormIssues_ == 0) cleanReps_++;
      inRep_ = false;
      repMinA_ = 1e9;
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
  } else if (smooth_ < spec_.topAngle) {
    inExcursion_ = true;
    excursionMin_ = std::min(excursionMin_, smooth_);
  } else if (inExcursion_) {           // üste dönüldü ama Bottom hiç görülmedi
    double deepEnough = spec_.topAngle - spec_.halfRepDepth * (spec_.topAngle - spec_.bottomAngle);
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
  r.lastRepScore = lastScore_;
  r.lastRepSeconds = lastRepSec_;
  r.avgRepScore = reps_ > 0 ? (int)std::lround(scoreSum_ / reps_) : -1;
  r.lastRepFormIssues = lastFormIssues_;
  // set alanları bu karede değişmiş olabilir (setTick dinlenmeyi başlatır) → tazele.
  r.currentSet = currentSet_;
  r.repsInSet = repsInSet_;
  r.resting = resting_;
  r.restRemaining = resting_ ? std::max(0.0, (restEndT_ - t) / 1000.0) : 0.0;
  r.workoutComplete = workoutDone_;
  return r;
}

}  // namespace coach
