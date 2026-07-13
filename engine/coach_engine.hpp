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

enum class Phase { Top, Bottom };            // durum makinesi
enum class Motion { Down, Up, Hold };        // yumuşatılmış sinyalin yönü
enum class View { Unknown, Front, Side };    // kamera vücudu nereden görüyor (3B veri varsa)

// form kuralı çeşitleri. Kural = VERİ: hangi ölçüm, hangi eşik, hangi görüşte
// anlamlı, ihlalde ne söylenir. Yeni kural türü kod ister ama yeni hareketin
// kuralları sadece veri.
enum class RuleKind {
  TorsoLean,    // gövde dikeyden param dereceden fazla eğilmesin ("sırt düz")
  KneeValgus,   // dizler bilek genişliğinin param katından fazla İÇE çökmesin (önden)
};

struct FormRule {
  RuleKind kind = RuleKind::TorsoLean;
  double param = 0;          // eşik: derece (TorsoLean) ya da oran (KneeValgus)
  View view = View::Unknown; // sadece bu görüşte değerlendir (Unknown = her görüşte)
  std::string cue;           // insana dönük düzeltme cümlesi
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
  double halfRepDepth = 0.35;   // iniş bu derinliği (0..1) geçip de dibe ulaşmazsa "yarım" sayılır
  double goodRepSecMin = 1.2;   // bundan hızlı tekrar = momentum/sıçrama, tempo puanı düşer
  double goodRepSecMax = 8.0;   // bundan yavaşı da tam puan almaz (takılma/duraksama)
  std::vector<FormRule> rules;  // form kuralları (Aşama 9) — hepsi veri
};

// altı büyük eklem açısı (gösterim + ileri aşamalar). -1 = okunamadı.
struct JointAngles {
  double leftKnee = -1, rightKnee = -1;
  double leftHip = -1, rightHip = -1;
  double leftElbow = -1, rightElbow = -1;
};

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
  View view = View::Unknown;
  JointAngles angles;
  // ── Aşama 7: sayma ──
  int reps = 0;              // bu oturumda sayılan TAM tekrar
  bool repTick = false;      // SADECE tekrarın sayıldığı karede true (ses/titreşim için)
  // ── Aşama 8: yarım tekrar ──
  int halfReps = 0;          // dibe ulaşmadan geri dönülen "sayılmadı" inişler
  bool halfTick = false;     // SADECE yarımın yakalandığı karede true
  // ── Kalite skoru: her tekrar aynı değil ──
  int lastRepScore = -1;     // son tekrarın puanı 0..100 (-1 = henüz tekrar yok)
  double lastRepSeconds = 0; // son tekrarın süresi
  int avgRepScore = -1;      // oturum ortalaması 0..100
  // ── Aşama 9: form ──
  std::string formCue;       // bu karede ihlal edilen kuralın düzeltme cümlesi ("" = form temiz)
  int lastRepFormIssues = 0; // son tekrarda ihlal edilen FARKLI kural sayısı
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

  // bir kare işle: 33 nokta ver, okuma al. timestampMs = kare zamanı (milisaniye,
  // herhangi bir monotonik saat); verilmezse motor kendi sahte saatini ilerletir
  // (kare başına ~33 ms) — tempo/kalite ölçümü zaman ister.
  Reading update(const std::vector<Landmark>& landmarks, double timestampMs = -1.0);

  // 3B yol: screen = ekran koordinatları (kadraj + görünürlük için),
  // world = MediaPipe'ın metrik dünya koordinatları (açı geometrisi için).
  // world doluysa açılar 3B ölçülür — kameraya dönük bükülme (perspektif
  // kısalması) 2B'de kaybolur, 3B'de kaybolmaz. world boşsa 2B'ye düşer.
  Reading update(const std::vector<Landmark>& screen,
                 const std::vector<Landmark>& world, double timestampMs);

 private:
  MoveSpec spec_;
  double smooth_ = -1;
  double prevSmooth_ = -1;
  bool haveSmooth_ = false;
  bool phaseTop_ = true;
  int reps_ = 0;
  int halfReps_ = 0;
  bool inExcursion_ = false;   // üst fazdayken eşiğin altına sarkan bir iniş sürüyor mu
  double excursionMin_ = 1e9;  // o inişte görülen en derin (en küçük) açı
  // kalite skoru durumu
  double fakeT_ = 0;           // timestamp verilmezse kullanılan sahte saat
  double lastTrackedT_ = -1;   // takip kopmalarını yakalamak için
  bool inRep_ = false;         // skorlanan bir tekrar penceresi açık mı
  double repStartT_ = 0;       // pencere başlangıcı (üstten ilk sarkma anı)
  double repMinA_ = 1e9;       // penceredeki en derin açı
  double repMinT_ = 0;         // o derinliğin zamanı (iniş/çıkış süresi ayrımı)
  int lastScore_ = -1;
  double lastRepSec_ = 0;
  double scoreSum_ = 0;
  unsigned violMask_ = 0;      // bu tekrar penceresinde ihlal edilen kuralların bitleri
  int lastFormIssues_ = 0;
};

}  // namespace coach
