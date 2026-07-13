// coach_engine.hpp — gymgyme coach motorunun SAF C++ API'si.
//
// Bu başlık web'i, tarayıcıyı, WebAssembly'yi HİÇ bilmez. Sadece "hareket
// analizi" bilir: 33 poz noktası ver, sana temiz bir okuma (açı, derinlik,
// faz) döndürür. O yüzden aynı motor yarın başka bir yere de takılabilir —
// web'e (WASM), native bir uygulamaya, bir sunucuya. Gerçek API bu ayrımda:
// ÇEKİRDEK saf ve taşınabilir, web'e bağlama işi ayrı bir katmanda (bindings.cpp).
//
// Kapsam (bu oturum): Aşama 2–6. Sayma (Aşama 7) buraya küçük bir sayaç
// eklenerek gelecek — API bunu taşıyacak şekilde tasarlandı.

#pragma once
#include <string>
#include <vector>

namespace coach {

// tek bir poz noktası (MediaPipe normalize koordinatları: x,y ∈ [0,1]).
struct Landmark {
  double x = 0, y = 0, z = 0, visibility = 0;
};

// bir eklem = üç nokta; açı ortadaki (b) köşesinde ölçülür.
// örn. diz = kalça(a) – diz(b) – ayakbileği(c).
struct JointRef {
  int a = 0, b = 0, c = 0;
};

// bir hareketin motoru nasıl okuyacağının VERİSİ. yeni hareket = yeni MoveSpec,
// kod değil (Aşama 12'de bu dışarıdan veriyle beslenecek).
struct MoveSpec {
  std::string name = "squat";
  JointRef primaryLeft;    // sayımı süren eklem, sol taraf
  JointRef primaryRight;   // ... sağ taraf (hangisi daha net görünüyorsa o kullanılır)
  double bottomAngle = 110.0;   // bu açının altı = "dipte"
  double topAngle = 155.0;      // bu açının üstü = "üstte"
  double emaAlpha = 0.4;        // yumuşatma katsayısı (0..1, küçük = daha sakin)
  double minVisibility = 0.5;   // bu güvenin altındaki okuma reddedilir
  double minFraming = 0.75;     // gövde+bacak noktalarının en az bu kadarı kadrajda olmalı
};

// altı büyük eklem açısı (gösterim + ileri aşamalar). -1 = okunamadı.
struct JointAngles {
  double leftKnee = -1, rightKnee = -1;
  double leftHip = -1, rightHip = -1;
  double leftElbow = -1, rightElbow = -1;
};

enum class Phase { Top, Bottom };            // durum makinesi
enum class Motion { Down, Up, Hold };        // yumuşatılmış sinyalin yönü

// motorun bir kareye verdiği tam cevap.
struct Reading {
  bool tracking = false;     // vücut güvenle okunuyor mu
  double confidence = 0;     // takip edilen zincirin güveni 0..1
  double framing = 0;        // gövde+bacak noktalarının kaçı kadrajda 0..1
  double rawAngle = -1;      // takip edilen açı, HAM
  double smoothAngle = -1;   // takip edilen açı, YUMUŞATILMIŞ (motorun kullandığı)
  double depth = 0;          // 0 (üstte) .. 1 (dipte)
  Phase phase = Phase::Top;
  Motion motion = Motion::Hold;
  JointAngles angles;
  // ── Aşama 7: sayma ──
  int reps = 0;              // bu oturumda sayılan TAM tekrar
  bool repTick = false;      // SADECE tekrarın sayıldığı karede true (ses/titreşim için)
  std::string message;       // insana dönük kısa mesaj (kadraj/ışık uyarısı vb.)
};

// hazır hareket kütüphanesi. bilinmeyen isim → squat döner.
MoveSpec builtinMove(const std::string& name);

// ── motor ────────────────────────────────────────────────────────────────────
// durumlu (stateful): tekrar tekrar update() çağırırsın, o yumuşatmayı ve
// faz geçişlerini kareler arasında hatırlar.
class Engine {
 public:
  explicit Engine(const MoveSpec& spec) : spec_(spec) { reset(); }

  void setMove(const MoveSpec& spec) { spec_ = spec; reset(); }
  const MoveSpec& move() const { return spec_; }

  // yumuşatma ve faz durumunu sıfırla (hareket/oturum değişince).
  void reset();

  // bir kare işle: 33 nokta ver, okuma al.
  Reading update(const std::vector<Landmark>& landmarks);

 private:
  MoveSpec spec_;
  double smooth_ = -1;
  double prevSmooth_ = -1;
  bool haveSmooth_ = false;
  bool phaseTop_ = true;
  int reps_ = 0;
};

}  // namespace coach
