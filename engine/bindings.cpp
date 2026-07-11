// bindings.cpp — saf coach motorunu (coach_engine) tarayıcıya açan İNCE katman.
//
// Buradaki tek iş çeviri: JS'ten gelen düz sayı dizisini C++ Landmark'lara,
// C++ Reading'i JS'in okuyabileceği düz bir nesneye çevirmek. Hiç mantık yok —
// mantık coach_engine'de. Bu ayrım sayesinde motor web'e bağımlı değil.
//
// Sadece bu dosya emscripten bilir; coach_engine saf C++ kalır.

#include <emscripten/bind.h>
#include <emscripten/val.h>
#include <string>
#include <vector>
#include "coach_engine.hpp"

using namespace emscripten;

// JS'e dönecek düz okuma (enum'lar string'e çevrilir, JS için kolay olsun).
struct JsReading {
  bool tracking;
  double confidence, framing, rawAngle, smoothAngle, depth;
  std::string phase, motion;
  double leftKnee, rightKnee, leftHip, rightHip, leftElbow, rightElbow;
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

// motorun web yüzü. içeride saf coach::Engine'i sarar.
class WebEngine {
 public:
  explicit WebEngine(std::string move) : engine_(coach::builtinMove(move)) {}

  void setMove(std::string move) { engine_.setMove(coach::builtinMove(move)); }
  void reset() { engine_.reset(); }

  JsReading update(val landmarks) {
    unsigned n = landmarks["length"].as<unsigned>();
    unsigned count = n / 4;
    std::vector<coach::Landmark> pts(count);
    for (unsigned i = 0; i < count; i++) {
      pts[i].x = landmarks[i * 4].as<double>();
      pts[i].y = landmarks[i * 4 + 1].as<double>();
      pts[i].z = landmarks[i * 4 + 2].as<double>();
      pts[i].visibility = landmarks[i * 4 + 3].as<double>();
    }

    coach::Reading r = engine_.update(pts);

    JsReading j;
    j.tracking = r.tracking;
    j.confidence = r.confidence;
    j.framing = r.framing;
    j.rawAngle = r.rawAngle;
    j.smoothAngle = r.smoothAngle;
    j.depth = r.depth;
    j.phase = phaseStr(r.phase);
    j.motion = motionStr(r.motion);
    j.leftKnee = r.angles.leftKnee;
    j.rightKnee = r.angles.rightKnee;
    j.leftHip = r.angles.leftHip;
    j.rightHip = r.angles.rightHip;
    j.leftElbow = r.angles.leftElbow;
    j.rightElbow = r.angles.rightElbow;
    j.message = r.message;
    return j;
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
      .field("leftKnee", &JsReading::leftKnee)
      .field("rightKnee", &JsReading::rightKnee)
      .field("leftHip", &JsReading::leftHip)
      .field("rightHip", &JsReading::rightHip)
      .field("leftElbow", &JsReading::leftElbow)
      .field("rightElbow", &JsReading::rightElbow)
      .field("message", &JsReading::message);

  class_<WebEngine>("Engine")
      .constructor<std::string>()
      .function("setMove", &WebEngine::setMove)
      .function("reset", &WebEngine::reset)
      .function("update", &WebEngine::update);
}
