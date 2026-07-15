// bindings.cpp — saf coach motorunu (coach_engine) tarayıcıya açan İNCE katman.
//
// Buradaki tek iş çeviri: gelen noktaları C++ Landmark'lara, C++ Reading'i JS'in
// okuyabileceği düz bir nesneye çevirmek. Hiç analiz yok burada — açı, yumuşatma,
// faz hepsi coach_engine'de. Bu ayrım sayesinde motor web'e bağımlı değil.
//
// İki giriş yolu:
//   updatePtr(ptr, n) — HIZLI yol: JS landmark'ları wasm heap'ine yazar, biz
//                       pointer'dan okuruz. Kare başına sınır geçişi ~yok.
//   update(array)     — kolay yol / yedek: JS dizisini eleman eleman okur.

#include <emscripten/bind.h>
#include <emscripten/val.h>
#include <cstdint>
#include <string>
#include <vector>
#include "coach_engine.hpp"

using namespace emscripten;

// JS'e dönecek düz okuma (enum'lar string'e çevrilir, JS için kolay olsun).
struct JsReading {
  bool tracking;
  double confidence, framing, rawAngle, smoothAngle, depth;
  std::string phase, motion, view;
  double leftKnee, rightKnee, leftHip, rightHip, leftElbow, rightElbow;
  int reps;
  bool repTick;
  int halfReps;
  bool halfTick;
  int lastRepScore;
  double lastRepSeconds;
  int avgRepScore;
  std::string repComment;
  std::string formCue;
  int lastRepFormIssues;
  int currentSet, totalSets, repsInSet, targetReps;
  bool setTick, resting;
  double restRemaining;
  bool workoutComplete;
  std::string message;
  bool calibrating;
  double calibProgress;
  int pickedPose;   // Faz 2: çok kişili karede motorun seçtiği pozun indeksi
  // yeni CV yetenekleri
  double torsoTilt;       // yerçekimi-farkında gövde oryantasyonu (derece)
  double asymmetryDeg;    // canlı sol-sağ açı farkı
  int lastRepAsymmetry;   // son tekrarın asimetrisi
  bool isHold, inHold;    // hold modu
  double heldSeconds, holdQuality;
};

// Aşama 14: seans özeti (düz nesne).
struct JsSummary {
  int reps, halfReps, setsCompleted, totalSets, avgScore, bestScore, cleanReps;
  double durationSec;
  bool workoutComplete;
  bool isHold;
  double heldSeconds, bestHoldSeconds;
  int holdQualityPct;
};
static JsSummary toJsSummary(const coach::Summary& s) {
  JsSummary j;
  j.reps = s.reps; j.halfReps = s.halfReps;
  j.setsCompleted = s.setsCompleted; j.totalSets = s.totalSets;
  j.avgScore = s.avgScore; j.bestScore = s.bestScore; j.cleanReps = s.cleanReps;
  j.durationSec = s.durationSec; j.workoutComplete = s.workoutComplete;
  j.isHold = s.isHold; j.heldSeconds = s.heldSeconds;
  j.bestHoldSeconds = s.bestHoldSeconds; j.holdQualityPct = s.holdQualityPct;
  return j;
}

static std::string phaseStr(coach::Phase p) {
  return p == coach::Phase::Bottom ? "bottom" : "top";
}
static std::string motionStr(coach::Motion m) {
  switch (m) {
    case coach::Motion::Down: return "down";
    case coach::Motion::Up:   return "up";
    default:                  return "hold";
  }
}
static std::string viewStr(coach::View v) {
  switch (v) {
    case coach::View::Front: return "front";
    case coach::View::Side:  return "side";
    default:                 return "unknown";
  }
}
static JsReading toJs(const coach::Reading& r) {
  JsReading j;
  j.tracking = r.tracking;
  j.confidence = r.confidence;
  j.framing = r.framing;
  j.rawAngle = r.rawAngle;
  j.smoothAngle = r.smoothAngle;
  j.depth = r.depth;
  j.phase = phaseStr(r.phase);
  j.motion = motionStr(r.motion);
  j.view = viewStr(r.view);
  j.leftKnee = r.angles.leftKnee;
  j.rightKnee = r.angles.rightKnee;
  j.leftHip = r.angles.leftHip;
  j.rightHip = r.angles.rightHip;
  j.leftElbow = r.angles.leftElbow;
  j.rightElbow = r.angles.rightElbow;
  j.reps = r.reps;
  j.repTick = r.repTick;
  j.halfReps = r.halfReps;
  j.halfTick = r.halfTick;
  j.lastRepScore = r.lastRepScore;
  j.lastRepSeconds = r.lastRepSeconds;
  j.avgRepScore = r.avgRepScore;
  j.repComment = r.repComment;
  j.formCue = r.formCue;
  j.lastRepFormIssues = r.lastRepFormIssues;
  j.currentSet = r.currentSet;
  j.totalSets = r.totalSets;
  j.repsInSet = r.repsInSet;
  j.targetReps = r.targetReps;
  j.setTick = r.setTick;
  j.resting = r.resting;
  j.restRemaining = r.restRemaining;
  j.workoutComplete = r.workoutComplete;
  j.message = r.message;
  j.calibrating = r.calibrating;
  j.calibProgress = r.calibProgress;
  j.pickedPose = r.pickedPose;
  j.torsoTilt = r.torsoTilt;
  j.asymmetryDeg = r.asymmetryDeg;
  j.lastRepAsymmetry = r.lastRepAsymmetry;
  j.isHold = r.isHold;
  j.inHold = r.inHold;
  j.heldSeconds = r.heldSeconds;
  j.holdQuality = r.holdQuality;
  return j;
}

// motorun web yüzü. içeride saf coach::Engine'i sarar.
class WebEngine {
 public:
  explicit WebEngine(std::string move) : engine_(coach::builtinMove(move)) {}

  void setMove(std::string move) { engine_.setMove(coach::builtinMove(move)); }
  void reset() { engine_.reset(); }
  // Aşama 13: set/dinlenme planı. targetReps=0 → plan yok (sonsuz say).
  void setPlan(int targetReps, int totalSets, double restSeconds) {
    engine_.setPlan(targetReps, totalSets, restSeconds);
  }
  void skipRest() { engine_.skipRest(); }
  // kalibrasyon: aç/kapa (motor önce vücudu öğrenir, sonra ona kilitlenir).
  void setCalibration(bool on) { engine_.setCalibration(on); }
  JsSummary summary() { return toJsSummary(engine_.summary()); }

  // HIZLI yol: heap'teki float buffer'lardan oku (count = float adedi, 33*4=132).
  // ptr = ekran noktaları (kadraj/çizim uzayı), worldPtr = MediaPipe dünya
  // noktaları (metrik 3B; worldCount 0 ise yok sayılır ve motor 2B'ye düşer).
  // tMs = kare zamanı (performance.now()); tempo/kalite ölçümü için.
  JsReading updatePtr(std::uintptr_t ptr, unsigned count,
                      std::uintptr_t worldPtr, unsigned worldCount, double tMs) {
    auto readBuf = [](std::uintptr_t bp, unsigned c) {
      const float* buf = reinterpret_cast<const float*>(bp);
      unsigned n = c / 4;
      std::vector<coach::Landmark> pts(n);
      for (unsigned i = 0; i < n; i++) {
        pts[i].x = buf[i * 4];
        pts[i].y = buf[i * 4 + 1];
        pts[i].z = buf[i * 4 + 2];
        pts[i].visibility = buf[i * 4 + 3];
      }
      return pts;
    };
    std::vector<coach::Landmark> pts = readBuf(ptr, count);
    std::vector<coach::Landmark> wpts;
    if (worldPtr && worldCount) wpts = readBuf(worldPtr, worldCount);
    JsReading j = toJs(engine_.update(pts, wpts, tMs));
    fillSmooth();
    return j;
  }

  // ── Faz 2: çok kişili kare. Buffer'da poseCount adet ardışık 33'lük blok;
  // motor izlediği vücudu kendisi seçer (Reading.pickedPose). worldPoseCount
  // 0 olabilir (dünya verisi yoksa). ──
  JsReading updateMultiPtr(std::uintptr_t ptr, unsigned floatsPerPose, unsigned poseCount,
                           std::uintptr_t worldPtr, unsigned worldFloatsPerPose,
                           unsigned worldPoseCount, double tMs) {
    auto readPose = [](std::uintptr_t bp, unsigned floats, unsigned idx) {
      const float* buf = reinterpret_cast<const float*>(bp) + (size_t)idx * floats;
      unsigned n = floats / 4;
      std::vector<coach::Landmark> pts(n);
      for (unsigned i = 0; i < n; i++) {
        pts[i].x = buf[i * 4];
        pts[i].y = buf[i * 4 + 1];
        pts[i].z = buf[i * 4 + 2];
        pts[i].visibility = buf[i * 4 + 3];
      }
      return pts;
    };
    std::vector<std::vector<coach::Landmark>> screens, worlds;
    for (unsigned i = 0; i < poseCount; i++) screens.push_back(readPose(ptr, floatsPerPose, i));
    if (worldPtr)
      for (unsigned i = 0; i < worldPoseCount; i++) worlds.push_back(readPose(worldPtr, worldFloatsPerPose, i));
    JsReading j = toJs(engine_.updateBest(screens, worlds, tMs));
    fillSmooth();
    return j;
  }

  // Faz 2: çizim iskeleti buffer'ı — motorun yumuşatılmış ekran pozu (33×4 float).
  // Her update sonrası tazelenir; smoothPoseOk() false ise bu karede yok (ham çiz).
  std::uintptr_t smoothPosePtr() const { return reinterpret_cast<std::uintptr_t>(smoothBuf_); }
  bool smoothPoseOk() const { return smoothOk_; }

  // yedek yol: JS dizisini eleman eleman oku.
  JsReading update(val landmarks, double tMs) {
    unsigned n = landmarks["length"].as<unsigned>();
    unsigned count = n / 4;
    std::vector<coach::Landmark> pts(count);
    for (unsigned i = 0; i < count; i++) {
      pts[i].x = landmarks[i * 4].as<double>();
      pts[i].y = landmarks[i * 4 + 1].as<double>();
      pts[i].z = landmarks[i * 4 + 2].as<double>();
      pts[i].visibility = landmarks[i * 4 + 3].as<double>();
    }
    return toJs(engine_.update(pts, tMs));
  }

 private:
  void fillSmooth() {
    const std::vector<coach::Landmark>& s = engine_.smoothScreen();
    smoothOk_ = s.size() == 33;
    if (!smoothOk_) return;
    for (int i = 0; i < 33; i++) {
      smoothBuf_[i * 4]     = (float)s[i].x;
      smoothBuf_[i * 4 + 1] = (float)s[i].y;
      smoothBuf_[i * 4 + 2] = (float)s[i].z;
      smoothBuf_[i * 4 + 3] = (float)s[i].visibility;
    }
  }

  coach::Engine engine_;
  float smoothBuf_[33 * 4] = {};
  bool smoothOk_ = false;
};

EMSCRIPTEN_BINDINGS(coach) {
  value_object<JsReading>("Reading")
      .field("tracking", &JsReading::tracking)
      .field("confidence", &JsReading::confidence)
      .field("framing", &JsReading::framing)
      .field("rawAngle", &JsReading::rawAngle)
      .field("smoothAngle", &JsReading::smoothAngle)
      .field("depth", &JsReading::depth)
      .field("phase", &JsReading::phase)
      .field("motion", &JsReading::motion)
      .field("view", &JsReading::view)
      .field("leftKnee", &JsReading::leftKnee)
      .field("rightKnee", &JsReading::rightKnee)
      .field("leftHip", &JsReading::leftHip)
      .field("rightHip", &JsReading::rightHip)
      .field("leftElbow", &JsReading::leftElbow)
      .field("rightElbow", &JsReading::rightElbow)
      .field("reps", &JsReading::reps)
      .field("repTick", &JsReading::repTick)
      .field("halfReps", &JsReading::halfReps)
      .field("halfTick", &JsReading::halfTick)
      .field("lastRepScore", &JsReading::lastRepScore)
      .field("lastRepSeconds", &JsReading::lastRepSeconds)
      .field("avgRepScore", &JsReading::avgRepScore)
      .field("repComment", &JsReading::repComment)
      .field("formCue", &JsReading::formCue)
      .field("lastRepFormIssues", &JsReading::lastRepFormIssues)
      .field("currentSet", &JsReading::currentSet)
      .field("totalSets", &JsReading::totalSets)
      .field("repsInSet", &JsReading::repsInSet)
      .field("targetReps", &JsReading::targetReps)
      .field("setTick", &JsReading::setTick)
      .field("resting", &JsReading::resting)
      .field("restRemaining", &JsReading::restRemaining)
      .field("workoutComplete", &JsReading::workoutComplete)
      .field("message", &JsReading::message)
      .field("calibrating", &JsReading::calibrating)
      .field("calibProgress", &JsReading::calibProgress)
      .field("pickedPose", &JsReading::pickedPose)
      .field("torsoTilt", &JsReading::torsoTilt)
      .field("asymmetryDeg", &JsReading::asymmetryDeg)
      .field("lastRepAsymmetry", &JsReading::lastRepAsymmetry)
      .field("isHold", &JsReading::isHold)
      .field("inHold", &JsReading::inHold)
      .field("heldSeconds", &JsReading::heldSeconds)
      .field("holdQuality", &JsReading::holdQuality);

  value_object<JsSummary>("Summary")
      .field("reps", &JsSummary::reps)
      .field("halfReps", &JsSummary::halfReps)
      .field("setsCompleted", &JsSummary::setsCompleted)
      .field("totalSets", &JsSummary::totalSets)
      .field("avgScore", &JsSummary::avgScore)
      .field("bestScore", &JsSummary::bestScore)
      .field("cleanReps", &JsSummary::cleanReps)
      .field("durationSec", &JsSummary::durationSec)
      .field("workoutComplete", &JsSummary::workoutComplete)
      .field("isHold", &JsSummary::isHold)
      .field("heldSeconds", &JsSummary::heldSeconds)
      .field("bestHoldSeconds", &JsSummary::bestHoldSeconds)
      .field("holdQualityPct", &JsSummary::holdQualityPct);

  class_<WebEngine>("Engine")
      .constructor<std::string>()
      .function("setMove", &WebEngine::setMove)
      .function("reset", &WebEngine::reset)
      .function("setPlan", &WebEngine::setPlan)
      .function("skipRest", &WebEngine::skipRest)
      .function("setCalibration", &WebEngine::setCalibration)
      .function("summary", &WebEngine::summary)
      .function("updatePtr", &WebEngine::updatePtr)
      .function("updateMultiPtr", &WebEngine::updateMultiPtr)
      .function("smoothPosePtr", &WebEngine::smoothPosePtr)
      .function("smoothPoseOk", &WebEngine::smoothPoseOk)
      .function("update", &WebEngine::update);
}
