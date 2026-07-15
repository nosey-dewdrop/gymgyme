// kalman.hpp — sabit-hız (constant velocity) Kalman filtresi, saf C++.
//
// Neden Kalman, One Euro varken? One Euro tek bir sinyali (açı) yumuşatır ama
// gelecek hakkında bir MODELİ yoktur — ölçüm gelmezse (landmark bir kare
// kaybolursa) susar. Kalman filtresi her noktanın DURUMUNU tutar: konum VE hız.
// İki fazı vardır:
//   predict — ölçüm gelmese bile hızı kullanıp bir sonraki konumu ÖNGÖRÜR
//             (occlusion: el gövdenin arkasına geçtiğinde iskelet zıplamaz,
//              son bilinen hızla akmaya devam eder).
//   update  — ölçüm gelince, ölçüm gürültüsü (R) ile süreç gürültüsünü (Q)
//             tartıp optimal karışımı alır — Kalman kazancı. Gürültülü kare
//             ölçüme az, güvenilir ölçüme çok ağırlık verir; hepsi otomatik.
//
// Bu, mocap/AR solver'larının (Vision Pro, mediapipe'ın kendi iç filtreleri)
// temel taşıdır. Burada her landmark ekseni (x, y, z) için bağımsız bir 1B
// konum-hız Kalman'ı koşuyoruz — hafif, kare başına 33×3 küçük filtre.

#pragma once
#include <cmath>

namespace coach {

// tek eksenli sabit-hız Kalman: durum = [konum, hız]. Ölçüm = konum.
// Sürekli-zaman beyaz ivme gürültü modeli (Q, dt ile ölçeklenir) → 30fps'te de
// 60fps'te de aynı fiziksel davranış.
struct Kalman1D {
  double x = 0, v = 0;          // durum: konum, hız
  double P00 = 1, P01 = 0, P10 = 0, P11 = 1;   // 2x2 kovaryans
  bool init = false;
  double q = 1.0;               // süreç gürültüsü yoğunluğu (ivme belirsizliği)
  double r = 1e-3;              // ölçüm gürültüsü varyansı (landmark titremesi)

  void reset() { x = v = 0; P00 = P11 = 1; P01 = P10 = 0; init = false; }

  // öngörü adımı: dt saniye ileri sar. Durum: x += v*dt. Kovaryans F P Fᵀ + Q.
  void predict(double dt) {
    if (!init) return;
    if (dt <= 0) dt = 1.0 / 30.0;
    if (dt > 0.25) dt = 0.25;   // uzun kopmada tek dev adım atma
    // durum geçişi F = [[1, dt],[0,1]]
    x += v * dt;
    // P = F P Fᵀ + Q
    double p00 = P00 + dt * (P10 + P01) + dt * dt * P11;
    double p01 = P01 + dt * P11;
    double p10 = P10 + dt * P11;
    double p11 = P11;
    // süreç gürültüsü (sabit-hız beyaz-ivme): Q = q * [[dt³/3, dt²/2],[dt²/2, dt]]
    double dt2 = dt * dt, dt3 = dt2 * dt;
    p00 += q * dt3 / 3.0;
    p01 += q * dt2 / 2.0;
    p10 += q * dt2 / 2.0;
    p11 += q * dt;
    P00 = p00; P01 = p01; P10 = p10; P11 = p11;
  }

  // güncelleme adımı: konum ölçümü z ile durumu düzelt. rScale: bu ölçümün
  // güvenine göre R'yi ölçekle (düşük görünürlük → büyük R → ölçüme az güven).
  void correct(double z, double rScale = 1.0) {
    if (!init) { x = z; v = 0; P00 = 1; P11 = 1; P01 = P10 = 0; init = true; return; }
    double R = r * (rScale > 0 ? rScale : 1.0);
    // ölçüm matrisi H = [1, 0]; innovation S = P00 + R
    double S = P00 + R;
    if (S < 1e-12) S = 1e-12;
    double K0 = P00 / S;        // Kalman kazancı (konum)
    double K1 = P10 / S;        // ... (hız)
    double y = z - x;           // innovation
    x += K0 * y;
    v += K1 * y;
    // kovaryans güncelle: P = (I - K H) P
    double p00 = (1 - K0) * P00;
    double p01 = (1 - K0) * P01;
    double p10 = P10 - K1 * P00;
    double p11 = P11 - K1 * P01;
    P00 = p00; P01 = p01; P10 = p10; P11 = p11;
  }

  // öngörülen konumun belirsizliği (P00). occlusion uzadıkça büyür — motor
  // "bu noktayı ne kadar tahmin ediyorum" bilir, çizim/karar buna göre solar.
  double uncertainty() const { return P00; }
};

// üç eksenli (x,y,z) landmark Kalman'ı — bir poz noktasının tam durumu.
struct KalmanPoint {
  Kalman1D kx, ky, kz;
  void reset() { kx.reset(); ky.reset(); kz.reset(); }
  void setParams(double q, double r) {
    kx.q = ky.q = kz.q = q;
    kx.r = ky.r = kz.r = r;
  }
  void predict(double dt) { kx.predict(dt); ky.predict(dt); kz.predict(dt); }
  void correct(double x, double y, double z, double rScale = 1.0) {
    kx.correct(x, rScale); ky.correct(y, rScale); kz.correct(z, rScale);
  }
  bool ready() const { return kx.init; }
  double speed() const { return std::sqrt(kx.v * kx.v + ky.v * ky.v + kz.v * kz.v); }
};

}  // namespace coach
