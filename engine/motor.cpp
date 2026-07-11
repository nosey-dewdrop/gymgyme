// gymgyme coach — motor (C++ → WebAssembly)
//
// Bu, koçun BEYNİ. Kamera ve çizim tarayıcıda (JS) kalıyor; ama vücudu SAYIYA
// çeviren, hareketi anlayan hesap burada, C++'ta yaşıyor ve WebAssembly'ye
// derlenip tarayıcıda çalışıyor (stitchu gibi). JS sadece MediaPipe'ın verdiği
// 33 noktayı bize uzatır; anlamı biz üretiriz. HTML motor değil — motor bu.
//
// Kapsam (bu oturum): Aşama 2–6.
//   2/3 · açılar      — noktalardan diz/kalça/dirsek bükülme açıları
//   4   · yumuşatma   — ham nokta titrer; EMA ile açı sinyali stabil
//   5   · güven kapısı— nokta güveni düşükse (ışık az / kadraja sığma) okuma reddedilir
//   6   · durum makinesi — hareketin "üstte" mi "dipte" mi olduğunu, gidiş yönünü tanır
// (Sayma = Aşama 7, sonraki oturum. Durum makinesi onun temelini kuruyor.)
//
// Derleme: engine/build.sh (emscripten gerekir). LSP'nin "bind.h yok" uyarısı
// sahtedir — o başlıklar emcc'de gelir, sistem clang'ında değil.

#include <emscripten/bind.h>
#include <emscripten/val.h>
#include <vector>
#include <string>
#include <cmath>

using namespace emscripten;

// MediaPipe Pose landmark indeksleri (33 nokta):
//  sol/sağ omuz 11/12, dirsek 13/14, bilek 15/16, kalça 23/24, diz 25/26, ayak bileği 27/28.
enum {
  L_SHO = 11, R_SHO = 12, L_ELB = 13, R_ELB = 14, L_WRI = 15, R_WRI = 16,
  L_HIP = 23, R_HIP = 24, L_KNE = 25, R_KNE = 26, L_ANK = 27, R_ANK = 28
};

// ── geometri ────────────────────────────────────────────────────────────────
// B köşesindeki açı (A-B-C), derece. Görüntü düzleminde (x,y) çalışıyoruz;
// kamera 2B gördüğü için yeterli ve derinlik gürültüsünden bağımsız, stabil.
static double angleDeg(double ax, double ay, double bx, double by, double cx, double cy) {
  double v1x = ax - bx, v1y = ay - by;
  double v2x = cx - bx, v2y = cy - by;
  double m1 = std::sqrt(v1x * v1x + v1y * v1y);
  double m2 = std::sqrt(v2x * v2x + v2y * v2y);
  if (m1 < 1e-6 || m2 < 1e-6) return -1.0;
  double c = (v1x * v2x + v1y * v2y) / (m1 * m2);
  if (c > 1.0) c = 1.0;
  if (c < -1.0) c = -1.0;
  return std::acos(c) * 180.0 / M_PI;
}

// JS'ten düz dizi gelir: her nokta için [x, y, z, visibility] → 33 * 4 = 132 sayı.
// x,y açı için; visibility güven kapısı için; z ileride derinlik için ayrılmış.
static inline double X(const std::vector<double>& p, int i) { return p[i * 4]; }
static inline double Y(const std::vector<double>& p, int i) { return p[i * 4 + 1]; }
static inline double V(const std::vector<double>& p, int i) { return p[i * 4 + 3]; }

static double joint(const std::vector<double>& p, int a, int b, int c) {
  return angleDeg(X(p, a), Y(p, a), X(p, b), Y(p, b), X(p, c), Y(p, c));
}

// ── motorun bu aşamadaki çıktısı ─────────────────────────────────────────────
struct State {
  bool tracking;          // vücut güvenle okunuyor mu
  double trackedAngle;    // sayımı sürecek açı (squat = diz), yumuşatılmış
  std::string phase;      // "top" | "bottom"  (durum makinesi)
  std::string direction;  // "down" | "up" | "hold"
  double leftKnee, rightKnee, leftHip, rightHip, leftElbow, rightElbow; // ham açılar (gösterim)
  std::string message;    // insana dönük kısa mesaj (güven kapısı vb.)
};

// ── motor ────────────────────────────────────────────────────────────────────
class Motor {
 public:
  explicit Motor(std::string move) { configure(move); reset(); }

  void configure(std::string move) {
    move_ = move;
    // her hareket, sayımı süren eklemi ve iki eşiği tanımlar (üstte / dipte).
    // şimdilik squat; ikinci hareket Aşama 10'da genelleşecek.
    if (move == "squat") { joint_ = KNEE; down_ = 110.0; up_ = 155.0; }
    else                 { joint_ = KNEE; down_ = 110.0; up_ = 155.0; move_ = "squat"; }
  }

  void reset() {
    smooth_ = -1.0; haveSmooth_ = false; prevSmooth_ = -1.0; phaseTop_ = true;
  }

  State update(val landmarks) {
    unsigned n = landmarks["length"].as<unsigned>();
    std::vector<double> p(n);
    for (unsigned i = 0; i < n; i++) p[i] = landmarks[i].as<double>();

    State s;
    s.tracking = false; s.trackedAngle = -1.0; s.phase = phaseTop_ ? "top" : "bottom";
    s.direction = "hold"; s.message = "";
    s.leftKnee = s.rightKnee = s.leftHip = s.rightHip = s.leftElbow = s.rightElbow = -1.0;

    if (n < 33 * 4) { s.message = "i cannot see you yet"; return s; }

    // ham açılar (gösterim + ileri aşamalar)
    s.leftKnee   = joint(p, L_HIP, L_KNE, L_ANK);
    s.rightKnee  = joint(p, R_HIP, R_KNE, R_ANK);
    s.leftHip    = joint(p, L_SHO, L_HIP, L_KNE);
    s.rightHip   = joint(p, R_SHO, R_HIP, R_KNE);
    s.leftElbow  = joint(p, L_SHO, L_ELB, L_WRI);
    s.rightElbow = joint(p, R_SHO, R_ELB, R_WRI);

    // ── Aşama 5: güven kapısı ──
    // squat için diz zincirini (kalça-diz-ayakbileği) hangi taraf daha net görüyorsa
    // onu seç. İki taraf da zayıfsa hiç sayma — motor kötü veriyle karar vermez.
    double visL = std::min(V(p, L_HIP), std::min(V(p, L_KNE), V(p, L_ANK)));
    double visR = std::min(V(p, R_HIP), std::min(V(p, R_KNE), V(p, R_ANK)));
    double raw; double bestVis;
    if (visL >= visR) { raw = s.leftKnee;  bestVis = visL; }
    else              { raw = s.rightKnee; bestVis = visR; }

    const double VIS_MIN = 0.5;
    if (bestVis < VIS_MIN || raw < 0.0) {
      s.message = "step back so your legs fit, and check the light";
      return s;                       // tracking=false; durum makinesi dokunulmaz
    }
    s.tracking = true;

    // ── Aşama 4: yumuşatma (EMA) ──
    // ham açı kareler arası titrer; alçak-geçiren süzgeç sinyali sakinleştirir,
    // yoksa durum makinesi eşiğin kenarında zıplar. alpha küçük = daha sakin.
    const double alpha = 0.4;
    if (!haveSmooth_) { smooth_ = raw; haveSmooth_ = true; }
    else              { smooth_ = alpha * raw + (1.0 - alpha) * smooth_; }
    s.trackedAngle = smooth_;

    // gidiş yönü (yumuşatılmış sinyalin eğimi). diz açısı DÜŞERSE çömeliyoruz.
    if (prevSmooth_ >= 0.0) {
      double d = smooth_ - prevSmooth_;
      if (d < -0.6) s.direction = "down";
      else if (d > 0.6) s.direction = "up";
      else s.direction = "hold";
    }
    prevSmooth_ = smooth_;

    // ── Aşama 6: durum makinesi ──
    // histerezisli iki durum: üstte (ayakta) ↔ dipte (çömelmiş). İki ayrı eşik,
    // gürültünün eşiği ileri-geri tetiklemesini önler. (Sayma Aşama 7'de bu
    // geçişlerin üstüne binecek — şimdilik sadece nerede olduğumuzu biliyoruz.)
    if (phaseTop_) {
      if (smooth_ < down_) phaseTop_ = false;   // yeterince indi → dip
    } else {
      if (smooth_ > up_) phaseTop_ = true;       // yeterince kalktı → üst
    }
    s.phase = phaseTop_ ? "top" : "bottom";
    return s;
  }

 private:
  enum TrackJoint { KNEE };
  std::string move_;
  TrackJoint joint_ = KNEE;
  double down_ = 110.0, up_ = 155.0;
  // durum
  double smooth_, prevSmooth_;
  bool haveSmooth_, phaseTop_;
};

// ── JS'e köprü (embind) ──────────────────────────────────────────────────────
EMSCRIPTEN_BINDINGS(motor) {
  value_object<State>("State")
      .field("tracking", &State::tracking)
      .field("trackedAngle", &State::trackedAngle)
      .field("phase", &State::phase)
      .field("direction", &State::direction)
      .field("leftKnee", &State::leftKnee)
      .field("rightKnee", &State::rightKnee)
      .field("leftHip", &State::leftHip)
      .field("rightHip", &State::rightHip)
      .field("leftElbow", &State::leftElbow)
      .field("rightElbow", &State::rightElbow)
      .field("message", &State::message);

  class_<Motor>("Motor")
      .constructor<std::string>()
      .function("configure", &Motor::configure)
      .function("reset", &Motor::reset)
      .function("update", &Motor::update);
}
