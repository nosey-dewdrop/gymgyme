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

// bir hareketin imzası: hangi eklem, dik mi yatay mı, rep mi hold mu.
struct MoveSignature {
  std::string name;
  SigJoint joint;
  bool horizontal;   // gövde yatay mı (plank/push-up) yoksa dik mi (squat)
  bool isHold;       // salınım yok mu (izometrik)
};

// bilinen hareket imzaları. Motor bu tabloyla canlı imzayı eşleştirir.
inline const std::vector<MoveSignature>& knownSignatures() {
  static const std::vector<MoveSignature> S = {
    {"squat",      SigJoint::Knee,     false, false},
    {"lunge",      SigJoint::Knee,     false, false},
    {"pushup",     SigJoint::Elbow,    true,  false},
    {"press",      SigJoint::Elbow,    false, false},
    {"glutebridge",SigJoint::Hip,      true,  false},
    {"situp",      SigJoint::Hip,      true,  false},
    {"jumpingjack",SigJoint::Shoulder, false, false},
    {"armraise",   SigJoint::Shoulder, false, false},
    {"plank",      SigJoint::Elbow,    true,  true},
    {"wallsit",    SigJoint::Knee,     false, true},
    {"superman",   SigJoint::Hip,      true,  true},
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
    tiltSum_ = 0; n_ = 0;
  }

  // bir kareyi besle: dört eklem açısı (diz, dirsek, kalça, omuz; -1 = yok) +
  // gövde tilt'i (derece, -1 = yok). Pencere dolunca eskiler düşer (kayan).
  void feed(double knee, double elbow, double hip, double shoulder, double tilt) {
    const double a[4] = {knee, elbow, hip, shoulder};
    for (int i = 0; i < 4; i++) {
      if (a[i] < 0) continue;
      mn_[i] = std::min(mn_[i], a[i]);
      mx_[i] = std::max(mx_[i], a[i]);
      sum_[i] += a[i];
    }
    if (tilt >= 0) tiltSum_ += tilt;
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

    // imza eşleştirme: eklem + oryantasyon + hold türü üç boyutta puanla.
    std::string bestName; double bestScore = -1;
    for (const auto& sig : knownSignatures()) {
      double sc = 0;
      if (sig.joint == dominant) sc += 3.0;               // dominant eklem en ağır
      if (avgTilt >= 0 && sig.horizontal == horizontal) sc += 1.5;
      if (sig.isHold == isHold) sc += 1.5;
      if (sc > bestScore) { bestScore = sc; bestName = sig.name; }
    }
    // güven: alınan puanın maksimuma (6.0) oranı, salınım netliğiyle ölçekli
    double clarity = std::min(1.0, bestAmp / 40.0);
    if (isHold) clarity = std::min(1.0, 0.5 + (12.0 - std::min(12.0, bestAmp)) / 24.0);
    confidence = (bestScore / 6.0) * (0.5 + 0.5 * clarity);
    return bestName;
  }

 private:
  static constexpr int kWindow = 60;   // ~2s @30fps
  double mn_[4] = {1e9, 1e9, 1e9, 1e9};
  double mx_[4] = {-1e9, -1e9, -1e9, -1e9};
  double sum_[4] = {0, 0, 0, 0};
  double tiltSum_ = 0;
  int n_ = 0;
};

}  // namespace coach
