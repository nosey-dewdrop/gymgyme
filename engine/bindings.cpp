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
  std::string message;
};

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
  j.message = r.message;
  return j;
}

// motorun web yüzü. içeride saf coach::Engine'i sarar.
class WebEngine {
 public:
  explicit WebEngine(std::string move) : engine_(coach::builtinMove(move)) {}

  void setMove(std::string move) { engine_.setMove(coach::builtinMove(move)); }
  void reset() { engine_.reset(); }

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
    return toJs(engine_.update(pts, wpts, tMs));
  }

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
  coach::Engine engine_;
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
      .field("message", &JsReading::message);

  class_<WebEngine>("Engine")
      .constructor<std::string>()
      .function("setMove", &WebEngine::setMove)
      .function("reset", &WebEngine::reset)
      .function("updatePtr", &WebEngine::updatePtr)
      .function("update", &WebEngine::update);
}
