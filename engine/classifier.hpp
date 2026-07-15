// classifier.hpp — hareket sınıflandırıcı, saf C++.
//
// Motor şimdiye kadar kullanıcının SEÇTİĞİ hareketi izliyordu. Gerçek bir koç,
// ne yaptığını söylemeden tanır. Bu modül son birkaç saniyenin hareketinden bir
// İMZA çıkarır ve bilinen hareketlerle eşleştirir:
//   - hangi eklem en çok salınıyor (diz / dirsek / kalça / omuz)?
//   - gövde dik mi yatay mı (yerçekimi tilt'i)?
//   - salınım mı var (rep) yoksa sabit mi (hold)?
//   - salınımın genliği ne?
// Bu dört boyut çoğu ev hareketini ayırt etmeye yeter: squat (diz salınır, dik),
// push-up (dirsek salınır, yatay), plank (dirsek/omuz sabit, yatay), jumping
// jack (omuz salınır, dik). Kesin değil — bir GÜVEN'le en olası adayı önerir.
//
// Bu, "activity recognition"ın hafif, açıklanabilir hali. Derin ağ değil; her
// kararı insanın okuyabileceği geometrik gerekçeye dayanır — bir üründe hata
// ayıklanabilir olması black-box doğruluktan değerli.

#pragma once
#include <string>
#include <vector>
#include <cmath>
#include <algorithm>

namespace coach {

// izlenen dört büyük eklemin adı (imza ekseni).
enum class SigJoint { Knee, Elbow, Hip, Shoulder, None };

// bir hareketin imzası: hangi eklem, dik mi yatay mı, rep mi hold mu, ve
// TEK-TARAFLI mı (lunge bir bacak önde = asimetrik; squat iki bacak simetrik).
// Asimetri boyutu, aynı eklemi paylaşan hareketleri ayırır (squat vs lunge).
struct MoveSignature {
  std::string name;
  SigJoint joint;
  bool horizontal;   // gövde yatay mı (plank/push-up) yoksa dik mi (squat)
  bool isHold;       // salınım yok mu (izometrik)
  bool asymmetric;   // sol-sağ belirgin farklı mı (lunge, sidelunge) yoksa simetrik mi (squat)
};

// bilinen hareket imzaları. Motor bu tabloyla canlı imzayı eşleştirir.
inline const std::vector<MoveSignature>& knownSignatures() {
  static const std::vector<MoveSignature> S = {
    {"squat",      SigJoint::Knee,     false, false, false},
    {"lunge",      SigJoint::Knee,     false, false, true},   // tek bacak önde: asimetrik
    {"pushup",     SigJoint::Elbow,    true,  false, false},
    {"press",      SigJoint::Elbow,    false, false, false},
    {"glutebridge",SigJoint::Hip,      true,  false, false},
    {"situp",      SigJoint::Hip,      true,  false, false},
    {"jumpingjack",SigJoint::Shoulder, false, false, false},
    {"armraise",   SigJoint::Shoulder, false, false, false},
    {"plank",      SigJoint::Elbow,    true,  true,  false},
    {"wallsit",    SigJoint::Knee,     false, true,  false},
    {"superman",   SigJoint::Hip,      true,  true,  false},
  };
  return S;
}

// ── canlı imza çıkarıcı: son N ka. karenin dört eklem açısını biriktirir,
// hangisinin salınımı (max-min genliği) en büyükse "izlenen eklem" odur.
// Gövde tilt'i son karelerin ortalamasından, hold/rep genlikten belirlenir. ──
class MoveClassifier {
 public:
  void reset() {
    for (int i = 0; i < 4; i++) { mn_[i] = 1e9; mx_[i] = -1e9; sum_[i] = 0; }
    tiltSum_ = 0; n_ = 0; asymSum_ = 0; asymN_ = 0;
  }

  // bir kareyi besle: dört eklem açısı (diz, dirsek, kalça, omuz; -1 = yok) +
  // gövde tilt'i (derece, -1 = yok) + sol-sağ asimetri (derece, -1 = ölçülemedi).
  // Asimetri squat/lunge gibi aynı-eklem hareketleri ayırır.
  void feed(double knee, double elbow, double hip, double shoulder, double tilt, double asym = -1.0) {
    const double a[4] = {knee, elbow, hip, shoulder};
    for (int i = 0; i < 4; i++) {
      if (a[i] < 0) continue;
      mn_[i] = std::min(mn_[i], a[i]);
      mx_[i] = std::max(mx_[i], a[i]);
      sum_[i] += a[i];
    }
    if (tilt >= 0) tiltSum_ += tilt;
    if (asym >= 0) { asymSum_ += asym; asymN_++; }
    n_++;
    if (n_ > kWindow) {
      // kaba kayan pencere: pencere aşılınca uçları hafif daralt (yeni salınıma
      // yer aç) — tam ring buffer değil, canlı sınıflandırma için yeterli.
      for (int i = 0; i < 4; i++) {
        double mid = (mn_[i] + mx_[i]) / 2.0;
        mn_[i] += (mid - mn_[i]) * 0.1;
        mx_[i] += (mid - mx_[i]) * 0.1;
      }
    }
  }

  // yeterli veri toplandı mı (en az ~1 saniye).
  bool ready() const { return n_ >= 20; }

  // en olası hareketi + güveni döndür. conf 0..1; düşükse motor "emin değilim".
  std::string classify(double& confidence) const {
    confidence = 0;
    if (!ready()) return "";
    // en çok salınan eklem
    double amp[4];
    int best = -1; double bestAmp = 0;
    for (int i = 0; i < 4; i++) {
      amp[i] = (mx_[i] > mn_[i]) ? (mx_[i] - mn_[i]) : 0;
      if (amp[i] > bestAmp) { bestAmp = amp[i]; best = i; }
    }
    if (best < 0) return "";
    SigJoint dominant = (SigJoint)best;   // Knee=0, Elbow=1, Hip=2, Shoulder=3
    const bool isHold = bestAmp < 12.0;   // <12° salınım ~2s = izometrik tutuş
    const double avgTilt = n_ > 0 ? tiltSum_ / n_ : -1;
    const bool horizontal = avgTilt >= 0 && avgTilt > 50.0;
    // asimetri ölçüldüyse: ort. sol-sağ fark >18° = tek-taraflı hareket (lunge).
    const double avgAsym = asymN_ > 0 ? asymSum_ / asymN_ : -1;
    const bool asymMeasured = avgAsym >= 0;
    const bool asymmetric = asymMeasured && avgAsym > 18.0;

    // imza eşleştirme: eklem + oryantasyon + hold türü + asimetri dört boyutta puanla.
    std::string bestName; double bestScore = -1;
    for (const auto& sig : knownSignatures()) {
      double sc = 0;
      if (sig.joint == dominant) sc += 3.0;               // dominant eklem en ağır
      if (avgTilt >= 0 && sig.horizontal == horizontal) sc += 1.5;
      if (sig.isHold == isHold) sc += 1.5;
      // asimetri yalnız ölçülebildiyse ayırıcı — squat(sim) vs lunge(asim)
      if (asymMeasured && sig.asymmetric == asymmetric) sc += 1.5;
      if (sc > bestScore) { bestScore = sc; bestName = sig.name; }
    }
    // ── BERABERE TESPİTİ (CS-dekan tur-4): bazı hareketler AYNI imzayı paylaşır
    // (situp/glutebridge, jumpingjack/armraise bu 4 boyutta ayırt edilemez).
    // Kaç imza kazananla ~eşit puanda? Birden çoksa bu bir tahmin değil yazı-tura;
    // güveni sert kır — "emin gibi yanlış" (nudge'ı yanlış tetikleyen) olmasın. ──
    int tied = 0;
    for (const auto& sig : knownSignatures()) {
      double sc = 0;
      if (sig.joint == dominant) sc += 3.0;
      if (avgTilt >= 0 && sig.horizontal == horizontal) sc += 1.5;
      if (sig.isHold == isHold) sc += 1.5;
      if (asymMeasured && sig.asymmetric == asymmetric) sc += 1.5;
      if (bestScore - sc < 0.01) tied++;
    }
    // güven: alınan puanın maksimuma oranı (asimetri ölçüldüyse 7.5, yoksa 6.0)
    double maxScore = asymMeasured ? 7.5 : 6.0;
    double clarity = std::min(1.0, bestAmp / 40.0);
    if (isHold) clarity = std::min(1.0, 0.5 + (12.0 - std::min(12.0, bestAmp)) / 24.0);
    confidence = (bestScore / maxScore) * (0.5 + 0.5 * clarity);
    // berabere cezası: 2 imza eşitse güveni yarıla, 3+ ise üçe böl — bu bir
    // yazı-tura, "emin" gösterme (nudge sadece >0.72'de tetiklenir, kırılan
    // güven yanlış öneriyi susturur).
    if (tied >= 2) confidence /= (double)tied;
    return bestName;
  }

 private:
  static constexpr int kWindow = 60;   // ~2s @30fps
  double mn_[4] = {1e9, 1e9, 1e9, 1e9};
  double mx_[4] = {-1e9, -1e9, -1e9, -1e9};
  double sum_[4] = {0, 0, 0, 0};
  double asymSum_ = 0;   // sol-sağ asimetri toplamı (lunge vs squat ayırıcı)
  int asymN_ = 0;
  double tiltSum_ = 0;
  int n_ = 0;
};

}  // namespace coach
