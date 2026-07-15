// test_kalman.cpp — Kalman filtresinin matematiğini bağımsız doğrular.
// Koşmak: clang++ -std=c++17 -O2 test_kalman.cpp -o /tmp/kt && /tmp/kt
#include "kalman.hpp"
#include <cstdio>
#include <cmath>
#include <algorithm>
using namespace coach;

static int failed = 0;
static void check(bool c, const char* m) { std::printf("%s %s\n", c ? "ok  " : "FAIL", m); if (!c) failed++; }

int main() {
  // sabit sinyal: filtre değere yakınsar, belirsizlik düşer
  {
    Kalman1D k; k.q = 1.0; k.r = 0.01;
    for (int i = 0; i < 60; i++) { k.predict(1.0 / 30); k.correct(5.0); }
    check(std::fabs(k.x - 5.0) < 0.01, "kalman converges to a constant signal");
    check(std::fabs(k.v) < 0.05, "velocity settles near zero on a still signal");
    check(k.uncertainty() < 0.5, "uncertainty shrinks with steady measurements");
  }

  // sabit-hız sinyali: filtre hızı öğrenir ve konumu izler (gecikmesiz)
  {
    Kalman1D k; k.q = 10.0; k.r = 1e-4;
    double truth = 0, vel = 2.0;   // birim/sn
    double dt = 1.0 / 30;
    for (int i = 0; i < 120; i++) { truth += vel * dt; k.predict(dt); k.correct(truth); }
    check(std::fabs(k.v - vel) < 0.3, "kalman learns the true velocity of a ramp");
    check(std::fabs(k.x - truth) < 0.05, "kalman tracks a constant-velocity ramp without lag");
  }

  // OCCLUSION: ölçüm kesilse de predict ile hızla akmaya devam eder
  {
    Kalman1D k; k.q = 5.0; k.r = 1e-4;
    double truth = 0, vel = 1.0, dt = 1.0 / 30;
    for (int i = 0; i < 60; i++) { truth += vel * dt; k.predict(dt); k.correct(truth); }
    double atOcclusion = truth;
    // 10 kare ölçüm YOK — sadece predict
    for (int i = 0; i < 10; i++) { truth += vel * dt; k.predict(dt); }
    check(k.x > atOcclusion + vel * dt * 8, "during occlusion the state keeps moving on predicted velocity");
    check(std::fabs(k.x - truth) < 0.2, "predicted position stays close to truth through a short occlusion");
    check(k.uncertainty() > 0.01, "uncertainty grows during occlusion (engine knows it is guessing)");
  }

  // ── DÖNÜŞ NOKTASINDA occlusion (CS-dekan bulgusu): rep bir kosinüs; tepe/dip'te
  // hız yön değiştirir. Constant-velocity öngörücü tam orada AŞAR (yanlış tarafa
  // devam eder). Bunu ÖLÇ: dönüş noktasında occlusion olursa hata sınırlı mı,
  // ve coasting penceresi (~0.5s) o hatayı makul tutuyor mu. ──
  {
    Kalman1D k; k.q = 40.0; k.r = 4e-4;
    double dt = 1.0 / 30, t = 0;
    // kosinüs squat: theta = 130 + 50*cos(w t), dip w t = pi civarı (hız ~0, döner)
    auto theta = [](double tt) { return 130.0 + 50.0 * std::cos(2.0 * M_PI * 0.5 * tt); };
    // dibe kadar besle (yaklaşık yarım periyot: 0.5Hz -> 1s'te dip)
    for (int i = 0; i < 30; i++) { t += dt; k.predict(dt); k.correct(theta(t)); }
    // tam dönüş noktasında 6 kare occlusion (ölçüm yok, sadece predict)
    double errMax = 0;
    for (int i = 0; i < 6; i++) { t += dt; k.predict(dt); errMax = std::max(errMax, std::fabs(k.x - theta(t))); }
    // constant-velocity dönüşte aşar ama coasting kısa olduğu için hata SINIRLI kalmalı.
    check(errMax < 25.0, "occlusion across a turnaround: constant-velocity overshoot stays bounded (<25deg)");
    // ölçüm dönünce hızla toparlar
    for (int i = 0; i < 10; i++) { t += dt; k.predict(dt); k.correct(theta(t)); }
    check(std::fabs(k.x - theta(t)) < 3.0, "recovers quickly once measurements return after a turnaround occlusion");
  }

  // gürültü bastırma: gürültülü ölçümlerin ortalamasına yakınsar, saçılmaz
  {
    Kalman1D k; k.q = 0.5; k.r = 0.05;
    // deterministik "gürültü" (test tekrarlanabilir): ±0.3 kare kare salınım
    double base = 10.0;
    double maxDev = 0;
    for (int i = 0; i < 100; i++) {
      double noise = (i % 2 == 0 ? 0.3 : -0.3);
      k.predict(1.0 / 30); k.correct(base + noise);
      if (i > 40) maxDev = std::max(maxDev, std::fabs(k.x - base));
    }
    check(maxDev < 0.15, "kalman suppresses alternating measurement noise (output smoother than input)");
  }

  // rScale: düşük güvenli ölçüme az ağırlık verilir (state daha az sapar)
  {
    Kalman1D a; a.q = 1.0; a.r = 0.01;
    Kalman1D b; b.q = 1.0; b.r = 0.01;
    for (int i = 0; i < 40; i++) { a.predict(1.0/30); a.correct(0.0); b.predict(1.0/30); b.correct(0.0); }
    // aynı aykırı ölçüm: a normal güven, b düşük güven (rScale büyük)
    a.predict(1.0/30); a.correct(5.0, 1.0);
    b.predict(1.0/30); b.correct(5.0, 100.0);
    check(a.x > b.x, "a low-confidence measurement moves the state less (rScale respected)");
  }

  // 3B nokta: eksenler bağımsız, hız büyüklüğü doğru
  {
    KalmanPoint p; p.setParams(10.0, 1e-4);
    double dt = 1.0 / 30, t = 0;
    for (int i = 0; i < 90; i++) { t += dt; p.predict(dt); p.correct(1.0 * t, 2.0 * t, 0.0); }
    check(p.ready(), "3d point is initialised after measurements");
    check(std::fabs(p.speed() - std::sqrt(1.0 + 4.0)) < 0.3, "3d speed magnitude matches the true velocity vector");
  }

  std::printf(failed ? "\n%d kalman test FAILED\n" : "\nall kalman tests passed\n", failed);
  return failed ? 1 : 0;
}
