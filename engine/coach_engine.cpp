// coach_engine.cpp — coach motorunun saf C++ implementasyonu.
// Web yok, tarayıcı yok: sadece geometri ve durum. (API: coach_engine.hpp)

#include "coach_engine.hpp"
#include <algorithm>
#include <cmath>

namespace coach {

// MediaPipe Pose landmark indeksleri.
enum {
  L_SHO = 11, R_SHO = 12, L_ELB = 13, R_ELB = 14, L_WRI = 15, R_WRI = 16,
  L_HIP = 23, R_HIP = 24, L_KNE = 25, R_KNE = 26, L_ANK = 27, R_ANK = 28
};

// B köşesindeki açı (A-B-C), derece. Görüntü düzleminde (x,y).
static double angleDeg(const Landmark& A, const Landmark& B, const Landmark& C) {
  double v1x = A.x - B.x, v1y = A.y - B.y;
  double v2x = C.x - B.x, v2y = C.y - B.y;
  double m1 = std::sqrt(v1x * v1x + v1y * v1y);
  double m2 = std::sqrt(v2x * v2x + v2y * v2y);
  if (m1 < 1e-6 || m2 < 1e-6) return -1.0;
  double c = (v1x * v2x + v1y * v2y) / (m1 * m2);
  c = std::max(-1.0, std::min(1.0, c));
  return std::acos(c) * 180.0 / M_PI;
}

static double angleAt(const std::vector<Landmark>& p, const JointRef& j) {
  return angleDeg(p[j.a], p[j.b], p[j.c]);
}

MoveSpec builtinMove(const std::string& name) {
  MoveSpec s;
  if (name == "squat") {
    s.name = "squat";
    s.primaryLeft  = {L_HIP, L_KNE, L_ANK};   // diz = kalça-diz-ayakbileği
    s.primaryRight = {R_HIP, R_KNE, R_ANK};
    s.bottomAngle = 110.0;
    s.topAngle = 155.0;
    s.emaAlpha = 0.4;
    s.minVisibility = 0.5;
    s.minFraming = 0.75;
    return s;
  }
  // bilinmeyen isim → güvenli varsayılan (squat).
  return builtinMove("squat");
}

void Engine::reset() {
  smooth_ = -1.0;
  prevSmooth_ = -1.0;
  haveSmooth_ = false;
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
}

static double clamp01(double v) { return std::max(0.0, std::min(1.0, v)); }

Reading Engine::update(const std::vector<Landmark>& p, double timestampMs) {
  double t = timestampMs;
  if (t < 0) { fakeT_ += 1000.0 / 30.0; t = fakeT_; }   // saat verilmediyse ~30fps varsay

  Reading r;
  r.phase = phaseTop_ ? Phase::Top : Phase::Bottom;
  r.reps = reps_;
  r.halfReps = halfReps_;
  r.lastRepScore = lastScore_;
  r.lastRepSeconds = lastRepSec_;
  r.avgRepScore = reps_ > 0 ? (int)std::lround(scoreSum_ / reps_) : -1;

  if (p.size() < 33) { r.message = "i cannot see you yet"; return r; }

  // ── Aşama 5: kadraj doluluğu — gövde+bacak noktalarının kaçı görünüyor ──
  const int core[] = {L_SHO, R_SHO, L_HIP, R_HIP, L_KNE, R_KNE, L_ANK, R_ANK};
  int seen = 0;
  for (int idx : core) if (p[idx].visibility >= 0.5) seen++;
  r.framing = seen / 8.0;

  // altı ham açı (gösterim).
  r.angles.leftKnee   = angleAt(p, {L_HIP, L_KNE, L_ANK});
  r.angles.rightKnee  = angleAt(p, {R_HIP, R_KNE, R_ANK});
  r.angles.leftHip    = angleAt(p, {L_SHO, L_HIP, L_KNE});
  r.angles.rightHip   = angleAt(p, {R_SHO, R_HIP, R_KNE});
  r.angles.leftElbow  = angleAt(p, {L_SHO, L_ELB, L_WRI});
  r.angles.rightElbow = angleAt(p, {R_SHO, R_ELB, R_WRI});

  // ── Aşama 5: güven kapısı — takip edilen zinciri iki taraftan kontrol et,
  // hangisi daha net görünüyorsa onu kullan; zayıfsa hiç okuma yapma. ──
  auto chainVis = [&](const JointRef& j) {
    return std::min(p[j.a].visibility, std::min(p[j.b].visibility, p[j.c].visibility));
  };
  double visL = chainVis(spec_.primaryLeft);
  double visR = chainVis(spec_.primaryRight);
  double raw, bestVis;
  if (visL >= visR) { raw = angleAt(p, spec_.primaryLeft);  bestVis = visL; }
  else              { raw = angleAt(p, spec_.primaryRight); bestVis = visR; }
  r.confidence = bestVis;

  if (r.framing < spec_.minFraming) { r.message = "step back so your whole body fits the frame"; return r; }
  if (bestVis < spec_.minVisibility || raw < 0.0) { r.message = "i lost your legs - check the light and the frame"; return r; }
  r.tracking = true;
  r.rawAngle = raw;

  // ── Aşama 4: yumuşatma (EMA) ──
  if (!haveSmooth_) { smooth_ = raw; haveSmooth_ = true; }
  else              { smooth_ = spec_.emaAlpha * raw + (1.0 - spec_.emaAlpha) * smooth_; }
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

  // ── Aşama 6: durum makinesi (histerezis) ──
  // ── Aşama 7: sayma — dipten üste TAM dönüş = bir tekrar. Bottom'a ancak alt
  // eşiği geçerek girilebildiği için Bottom→Top geçişi her zaman tam bir
  // döngüdür; yarım inişler fazı hiç değiştirmez, dolayısıyla sayılmaz. ──
  if (phaseTop_) {
    if (smooth_ < spec_.bottomAngle) phaseTop_ = false;
  } else if (smooth_ > spec_.topAngle) {
    phaseTop_ = true;
    reps_++;
    r.repTick = true;

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
      lastRepSec_ = durSec;
      scoreSum_ += lastScore_;
      inRep_ = false;
      repMinA_ = 1e9;
    }
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
  }

  r.reps = reps_;
  r.halfReps = halfReps_;
  r.lastRepScore = lastScore_;
  r.lastRepSeconds = lastRepSec_;
  r.avgRepScore = reps_ > 0 ? (int)std::lround(scoreSum_ / reps_) : -1;
  return r;
}

}  // namespace coach
