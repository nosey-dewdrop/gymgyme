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
#include "kalman.hpp"
#include "ik.hpp"
#include "classifier.hpp"

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

// ── hareketin sayım TÜRÜ. Rep = açı salınımı (squat, push-up); Hold = izometrik
// tutuş (plank, wall-sit): salınım yok, hedef açı bandında GEÇİRİLEN SÜRE + form
// kararlılığı ölçülür. Aynı motor, farklı sayım ekseni. ──
enum class MoveKind { Rep, Hold };

// form kuralı çeşitleri. Kural = VERİ: hangi ölçüm, hangi eşik, hangi görüşte
// anlamlı, ihlalde ne söylenir. Yeni kural türü kod ister ama yeni hareketin
// kuralları sadece veri.
enum class RuleKind {
  TorsoLean,    // gövde dikeyden param dereceden fazla eğilmesin ("sırt düz")
  KneeValgus,   // dizler bilek genişliğinin param katından fazla İÇE çökmesin (önden)
  HipSag,       // omuz-kalça-diz hattı param derecenin altına kırılmasın (plank/push-up)
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
  // ── One Euro filtre (varsayılan yol). EMA'nın açmazı: tek katsayı hem duruşta
  // sakin hem harekette hızlı olamaz. One Euro kesim frekansını HIZA göre ayarlar:
  // duruşta minCutoff'a iner (titreme ezilir), hızlanınca beta ile açılır (gecikme
  // yok). useOneEuro=false eski EMA yoluna döner (ölçüm karşılaştırması için).
  bool useOneEuro = true;
  double euroMinCutoff = 2.5;   // Hz — duruştaki taban kesim (küçük = daha sakin duruş)
  double euroBeta = 0.005;      // hız başına kesim artışı (büyük = hızlı harekete daha çevik)
                                // 2.5/0.005: bench sweep ile seçildi (jitter+rmse+GECİKME+yanlış sayım,
                                // 3 gürültü seviyesi toplamı; elle değil ölçümle — bench.sh sweep)
  double euroDCutoff = 1.0;     // hız sinyalinin kendi alçak geçireni
  double minVisibility = 0.5;   // bu güvenin altındaki okuma reddedilir
  double minFraming = 0.75;     // izlenen noktaların en az bu kadarı kadrajda olmalı
  std::vector<int> framingPoints;  // bu hareket için kadrajda olması GEREKEN noktalar
                                   // (boşsa gövde+bacak varsayılanı kullanılır)
  double halfRepDepth = 0.20;   // iniş bu derinliği (0..1) geçip de dibe ulaşmazsa "yarım" sayılır
                                // (0.35'ti — Damla'nın sığ denemeleri sessiz kalıyordu; artık uyarı alır)
  // ── adaptif dip eşiği (Damla, 15 tem: "eğildiğimi görüyor ama squat saymıyor").
  // Sabit bottomAngle her vücutta/kamerada tetiklenmez: önden squat'ta world-z
  // dip açısını olduğundan düz gösterir, kişi derin çömelse de eşiğe hiç değmez.
  // Çözüm: motor kişinin GERÇEK üst duruşunu (ilk hareketteki en açık açı) ölçer;
  // dip eşiğini o duruştan adaptiveDrop kadar aşağı koyar. Yani "senin ayakta
  // durduğun yerden bu kadar bükülürsen = squat". range hareket başına türetilir,
  // spec sabitine bağlı kalmaz. 0 = kapalı (eski sabit eşik davranışı).
  bool adaptiveBottom = false;  // squat ailesinde açılır (aşağıda set edilir)
  double adaptiveDrop = 0.0;    // üst duruştan dip eşiğine düşüş (derece)
  double goodRepSecMin = 1.2;   // bundan hızlı tekrar = momentum/sıçrama, tempo puanı düşer
  double goodRepSecMax = 8.0;   // bundan yavaşı da tam puan almaz (takılma/duraksama)
  std::vector<FormRule> rules;  // form kuralları (Aşama 9) — hepsi veri
  std::string framingCue;       // kadraj yetersizken hareketin KENDİ cümlesi ("" = genel mesaj)
  // ── HOLD (izometrik) modu: plank, wall-sit, superman, hollow hold. Salınım
  // yok; motor takip edilen açının [holdMin, holdMax] bandında GEÇİRDİĞİ süreyi
  // biriktirir ve o süre boyunca form kurallarını (HipSag vb) izler. Banttan
  // çıkınca sayaç DURUR (tekrar girince kaldığı yerden değil — kararlılık ödülü).
  MoveKind kind = MoveKind::Rep;
  double holdMin = 0.0;         // hedef açı bandı alt sınırı (derece)
  double holdMax = 0.0;         // hedef açı bandı üst sınırı (derece)
  JointRef holdJoint;           // hold'da izlenen açı (boşsa primaryLeft/Right kullanılır)
  // ── yerçekimi kapısı (3B veri varken): tutuş yalnız gövde bu tilt bandındayken
  // sayılır. plank yatay ister (tilt yüksek), wall-sit dik ister (tilt düşük).
  // Böylece ayakta dururken plank "sayılmaz". [0,180] = kapalı (her oryantasyon).
  double holdTiltMin = 0.0;
  double holdTiltMax = 180.0;
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
  // ── yerçekimi-farkında gövde oryantasyonu (3B veri varken). torsoTilt =
  // gövde ekseninin DİKEYden sapması, derece: 0 = dimdik ayakta, 90 = yatay
  // (plank/şınav). Motor artık "ayakta mı yatay mı" bilir — plank'ı ayakta
  // durmaktan ayıran budur, eklem açısı değil. -1 = ölçülemedi (2B). ──
  double torsoTilt = -1;
  // ── simetri / denge analizi: sol ve sağ tarafın izlenen açısı ne kadar
  // ayrışıyor. 0 = kusursuz simetri, büyüdükçe bir taraf telafi ediyor demektir
  // (fizyo değeri: sakatlık sonrası kaçınma, zayıf taraf). -1 = ölçülemedi. ──
  double asymmetryDeg = -1;  // sol-sağ izlenen açı farkının canlı mutlak değeri
  int lastRepAsymmetry = -1; // son tekrarda görülen EN BÜYÜK sol-sağ fark (derece)
  // ── hareket sınıflandırma: motor son ~2s'den ne yaptığını KENDİ tahmin eder.
  // Seçili hareketle uyuşmuyorsa "did you mean X?" için kullanılır. "" = emin değil. ──
  std::string detectedMove;      // motorun tahmini hareket adı
  double detectedConfidence = 0; // 0..1
  JointAngles angles;
  // ── Faz 2: çok kişili karede motorun SEÇTİĞİ pozun indeksi (updateBest).
  // Çizim bu pozu kullanmalı — motor kimi izliyorsa ekran onu göstersin. ──
  int pickedPose = 0;
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
  // ── Faz 3 katman 1: tekrar yorumu — sayılar insanca TEK cümleye çevrilir.
  // SADECE tekrarın sayıldığı karede dolu gelir (repTick gibi); koç konuşur. ──
  std::string repComment;
  // ── Aşama 9: form ──
  std::string formCue;       // bu karede ihlal edilen kuralın düzeltme cümlesi ("" = form temiz)
  int lastRepFormIssues = 0; // son tekrarda ihlal edilen FARKLI kural sayısı
  // ── Aşama 13: setler ve dinlenme ──
  int currentSet = 1;        // kaçıncı settesin (1..totalSets)
  int totalSets = 1;         // planlanan set sayısı
  int repsInSet = 0;         // bu sette şu ana kadar sayılan tam tekrar
  int targetReps = 0;        // set başı hedef (0 = plan yok, sonsuz say)
  bool setTick = false;      // SADECE bir set hedefe ulaştığı karede true
  bool resting = false;      // set arası dinlenme sürüyor mu (tekrar sayılmaz)
  double restRemaining = 0;  // dinlenmede kalan saniye (0 = dinlenmede değil)
  bool workoutComplete = false; // son setin hedefi de doldu — antrenman bitti
  std::string message;       // insana dönük kısa mesaj (kadraj/ışık uyarısı vb.)
  // ── kalibrasyon: motor önce vücudu tanır, sonra ona kilitlenir ──
  bool calibrating = false;  // şu an vücut ölçüleri öğreniliyor (sayma duraklatılır)
  double calibProgress = 0;  // 0..1
  // ── HOLD modu çıktıları (kind == Hold ise anlamlı) ──
  bool isHold = false;       // bu hareket izometrik bir tutuş mu
  bool inHold = false;       // şu an hedef bantta ve süre birikiyor mu
  double heldSeconds = 0;    // bu tutuşta hedef bantta geçirilen toplam süre
  double holdQuality = 0;    // 0..1: banttaki kararlılık + form temizliği (canlı)
};

// ── Aşama 14: seans özeti — antrenman bitince (ya da durunca) yapılandırılmış
// küçük bir rapor. Motor zaten her tekrarı sayıyor/puanlıyor; özet bunları
// oturum boyunca biriktirir. Ekranda değil, VERİDE: sonra "programım"a da işlenir.
struct Summary {
  int reps = 0;             // toplam tam tekrar
  int halfReps = 0;         // sayılmayan yarımlar
  int setsCompleted = 0;    // tamamlanan set (plan yoksa 0)
  int totalSets = 1;        // planlanan set
  int avgScore = -1;        // ortalama tekrar puanı 0..100 (-1 = tekrar yok)
  int bestScore = -1;       // en iyi tekrar puanı
  int cleanReps = 0;        // form sorunu olmayan tekrar sayısı
  double durationSec = 0;   // ilk kareden son kareye seans süresi
  bool workoutComplete = false;
  // ── HOLD modu özeti ──
  bool isHold = false;      // bu hareket izometrik tutuş muydu
  double heldSeconds = 0;   // hedef bantta biriken toplam süre
  double bestHoldSeconds = 0; // en uzun kesintisiz tutuş
  int holdQualityPct = -1;  // ortalama tutuş kalitesi 0..100 (-1 = hold değil)
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

  // ── Aşama 13: antrenman planı. targetReps>0 verilince motor setleri sayar:
  // hedefe ulaşınca set biter, restSec saniye dinlenme başlar (motor zaman-
  // farkında olduğu için geri sayımı KENDİ tutar), sonra sıradaki sete geçilir.
  // targetReps=0 planı kapatır (bugünkü gibi sonsuz say). Plan hareket değişince
  // korunur, sadece ilerleme (set/tekrar/dinlenme) sıfırlanır.
  void setPlan(int targetReps, int totalSets, double restSeconds);
  // dinlenmeyi erken bitir (kullanıcı "hazırım" derse) — sıradaki sete geç.
  void skipRest();

  // ── kalibrasyon (opt-in): açıkken motor ilk ~1.5 saniyede uzuv ORANLARINI
  // öğrenir (uyluk/baldır/kol/omuz, gövdeye bölünmüş — ölçekten bağımsız),
  // sonrasında bu vücuda uymayan okumaları reddeder: iskelet başka birine ya da
  // eşyaya "ışınlanamaz". 3B dünya verisi ister (uzuv boyu 3B'de bükülmeyle
  // değişmez); dünya verisi olmayan karede es geçilir. reset() ilerlemeyi
  // sıfırlar (yeniden öğrenir), açık/kapalı ayarı korunur.
  void setCalibration(bool on);

  // Aşama 14: oturumun o ana kadarki özeti.
  Summary summary() const;

  // yumuşatma ve faz durumunu sıfırla (hareket/oturum değişince). plan korunur.
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

  // ── Faz 2: çok kişili kare. Dedektör birden çok vücut verdiğinde motor
  // İZLEDİĞİ vücudu kendi seçer: kalibre edilen orana + son kabul edilen
  // poza en çok benzeyen aday kazanır. Kadraja giren yabancı (hoca vakası)
  // iskelet çalamaz. Dönen Reading.pickedPose = seçilen adayın indeksi. ──
  Reading updateBest(const std::vector<std::vector<Landmark>>& screens,
                     const std::vector<std::vector<Landmark>>& worlds, double timestampMs);

  // ── Faz 2: kemik kilidi. Kalibrasyon mutlak kemik uzunluklarını da öğrenir
  // (dünya/metrik — bükülmeyle değişmez); kilit açıkken her kare iskelet bu
  // uzunluklara hiyerarşik projeksiyonla oturtulur ve açılar KİLİTLİ iskeletten
  // ölçülür: kemik uzayamaz, eklem kayamaz. Kalibrasyon kapalıysa etkisiz. ──
  void setBoneLock(bool on) { boneLockOn_ = on; }
  // son karenin kilitli dünya iskeleti (boş = bu karede çözüm yok). ölçüm/bench için.
  const std::vector<Landmark>& solvedWorld() const { return solvedWorld_; }
  // son karenin çizim iskeleti: ekran noktaları, nokta başına One Euro ile
  // yumuşatılmış. Ekrana ham dedektör değil BU çizilir (görsel sükunet).
  const std::vector<Landmark>& smoothScreen() const { return smoothScreen_; }

 private:
  double euroApply(double x, double tMs);   // One Euro adımı (durumu aşağıda)
  // aday puanı (küçük iyi): son kabul edilen poza uzaklık + kalibre orana uzaklık.
  double candidateScore(const std::vector<Landmark>& screen,
                        const std::vector<Landmark>& world) const;
  // kalibre vücuda oran uyumsuzluğu (ortalama bağıl hata; -1 = ölçülemedi).
  double ratioMismatch(const std::vector<Landmark>& screen,
                       const std::vector<Landmark>& world) const;
  // kemik kilidi çözümü: dünya iskeletini öğrenilen uzunluklara oturt (out'a yazar).
  void solveBones(const std::vector<Landmark>& world,
                  const std::vector<Landmark>& vis, std::vector<Landmark>& out) const;
  // çizim iskeleti: ekran noktalarını nokta başına One Euro'dan geçir.
  void smoothScreenApply(const std::vector<Landmark>& screen, double tMs);
  // Kalman occlusion-recovery: görünür noktaları düzelt, kayıpları tahminle
  // doldur. out'a yazar (görünmeyen nokta = tahmin, visibility düşük işaretli).
  void kalmanApply(const std::vector<Landmark>& screen, double tMs, std::vector<Landmark>& out);

  MoveSpec spec_;
  double smooth_ = -1;
  double prevSmooth_ = -1;
  bool haveSmooth_ = false;
  // One Euro durumu (reset'te sıfırlanır)
  bool euroInit_ = false;
  double euroX_ = 0, euroDx_ = 0, euroLastT_ = -1;
  // ince takip: tek karelik dev sıçrama (ışınlanma) yutulur, süreni kabul edilir
  bool spikeHold_ = false;
  // kalibrasyon durumu (setCalibration açar; ilerleme reset'te sıfırlanır)
  static constexpr int kCalibFrames = 60;   // ~2 sn @30fps (Damla: daha sağlam öğrensin)
  static constexpr int kRatioN = 5;         // uyluk, baldır, üst kol, ön kol, omuz genişliği
  bool calibOn_ = false;
  bool calibrated_ = false;
  int calibCount_ = 0;
  std::vector<double> calibSamples_[kRatioN];
  double bodyRatio_[kRatioN] = {0, 0, 0, 0, 0};
  bool ratioUsable_[kRatioN] = {false, false, false, false, false};
  // ── Faz 2: kemik kilidi durumu. uzunluklar MUTLAK (metre, dünya uzayı);
  // iki taraf tek uzunluk kullanır (vücut simetrik, örnek sayısı ikiye katlanır).
  static constexpr int kBoneN = 4;          // uyluk, baldır, üst kol, ön kol
  bool boneLockOn_ = true;
  bool ikOn_ = true;   // anatomik eklem limitleri (ik.hpp) — kemik kilidi sonrası açı kırpma
  std::vector<double> boneSamples_[kBoneN];
  double boneLen_[kBoneN] = {0, 0, 0, 0};
  bool boneUsable_[kBoneN] = {false, false, false, false};
  std::vector<Landmark> solvedWorld_;       // bu karenin kilitli iskeleti (boş = yok)
  // ── Faz 2: çok kişi seçimi — son kabul edilen pozun çekirdek noktaları ──
  std::vector<Landmark> lastCore_;
  double lastCoreT_ = -1;
  // ── Faz 2: çizim iskeleti filtreleri (33 nokta × x,y) ──
  std::vector<Landmark> smoothScreen_;
  bool visEuroInit_[33] = {};
  double visX_[33] = {}, visY_[33] = {}, visDx_[33] = {}, visDy_[33] = {};
  double visEuroLastT_ = -1;
  // ── Kalman occlusion-recovery: her ekran noktası için konum-hız durumu.
  // görünür nokta correct edilir; görünmeyen nokta yalnız predict'le akar
  // (el gövde arkasına geçince iskelet zıplamaz, tahmini hızla devam eder).
  // occludedFor_ = o noktanın kaç kaç kaç kaç karedir ölçümsüz kaldığı. ──
  KalmanPoint kf_[33];
  int occludedFor_[33] = {};
  double kfLastT_ = -1;
  // ── Faz 2: zaman-farkında ışınlanma kapısı için önceki kare zamanı ──
  double prevFrameT_ = -1;
  bool phaseTop_ = true;
  // ── HOLD modu durumu (spec_.kind == Hold). heldSec_ = hedef bantta biriken
  // süre; holdInBand_ = son kare banttaydı mı; holdFormSum_/holdFrames_ =
  // canlı kalite ortalaması için form-temizliği birikimi. ──
  double heldSec_ = 0;
  bool holdInBand_ = false;
  double holdQualitySum_ = 0;
  int holdFrames_ = 0;
  double bestHoldSec_ = 0;   // özet için en uzun kesintisiz tutuş
  double curHoldRunSec_ = 0; // şu anki kesintisiz tutuş süresi
  // ── adaptif dip eşiği durumu (spec_.adaptiveBottom açıksa). topRest_ = kişinin
  // gözlenen en açık (rahat/üst) açısı, sürekli güncellenir; bottomLive_/topLive_
  // = ondan türetilen çalışan eşikler. -1 = henüz öğrenilmedi (spec sabiti kullanılır).
  double topRest_ = -1.0;
  double bottomLive_ = -1.0;
  double topLive_ = -1.0;
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
  double repMaxAsym_ = 0;      // bu tekrar penceresinde görülen en büyük sol-sağ açı farkı
  int lastRepAsym_ = -1;       // son tamamlanan tekrarın asimetrisi (derece)
  MoveClassifier classifier_;  // hareket sınıflandırıcı (motor ne yapıldığını tahmin eder)
  int lastScore_ = -1;
  double lastRepSec_ = 0;
  double scoreSum_ = 0;
  unsigned violMask_ = 0;      // bu tekrar penceresinde ihlal edilen kuralların bitleri
  int lastFormIssues_ = 0;
  // ── Aşama 13: set/dinlenme planı (config, reset'te KORUNUR) ──
  int targetReps_ = 0;         // set başı hedef (0 = plan yok)
  int totalSets_ = 1;
  double restSec_ = 60.0;
  // ── ilerleme (reset'te sıfırlanır) ──
  int currentSet_ = 1;
  int repsInSet_ = 0;
  bool resting_ = false;
  double restEndT_ = 0;        // dinlenmenin biteceği motor-zamanı (ms)
  bool workoutDone_ = false;
  // Aşama 14: özet birikimi
  int bestScore_ = -1;
  int cleanReps_ = 0;          // form sorunu olmayan tekrar
  double startT_ = -1;         // ilk kare zamanı
  double lastT_ = 0;           // son kare zamanı
};

}  // namespace coach
