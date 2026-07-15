// test_ik.cpp — anatomik eklem-limiti çözücüsünün matematiğini doğrular.
// clang++ -std=c++17 -O2 test_ik.cpp -o /tmp/ikt && /tmp/ikt
#include "ik.hpp"
#include <cstdio>
#include <cmath>
using namespace coach;

static int failed = 0;
static void check(bool c, const char* m) { std::printf("%s %s\n", c ? "ok  " : "FAIL", m); if (!c) failed++; }

static double dist(const double* P, int a, int b) {
  double dx = P[a*3]-P[b*3], dy = P[a*3+1]-P[b*3+1], dz = P[a*3+2]-P[b*3+2];
  return std::sqrt(dx*dx+dy*dy+dz*dz);
}

int main() {
  // geçerli diz açısı (~120°): dokunulmamalı
  {
    double P[99] = {0};
    // sol kalça(23), diz(25), bilek(27) — makul bükülü bacak
    P[23*3]=0; P[23*3+1]=0; P[23*3+2]=0;
    P[25*3]=0; P[25*3+1]=-0.4; P[25*3+2]=0;
    P[27*3]=0.2; P[27*3+1]=-0.7; P[27*3+2]=0;
    double before = ikAngle(P[23*3],P[23*3+1],P[23*3+2], P[25*3],P[25*3+1],P[25*3+2], P[27*3],P[27*3+1],P[27*3+2]);
    int fixed = clampHumanLimits(P);
    double after = ikAngle(P[23*3],P[23*3+1],P[23*3+2], P[25*3],P[25*3+1],P[25*3+2], P[27*3],P[27*3+1],P[27*3+2]);
    check(before > 15 && before < 183, "test setup: knee starts in a valid range");
    check(std::fabs(before - after) < 0.5, "a valid knee angle is left untouched");
    (void)fixed;
  }

  // imkansız açı: diz çok fazla bükülü (~8°, min 15'in altında) — sınıra çekilmeli
  {
    double P[99] = {0};
    P[23*3]=0; P[23*3+1]=0; P[23*3+2]=0;         // kalça
    P[25*3]=0; P[25*3+1]=-0.4; P[25*3+2]=0;      // diz
    // bilek kalça yönüne neredeyse geri katlanmış -> diz açısı ~2° (imkansız, <5° sınır)
    P[27*3]=0.005; P[27*3+1]=-0.01; P[27*3+2]=0;
    double before = ikAngle(P[23*3],P[23*3+1],P[23*3+2], P[25*3],P[25*3+1],P[25*3+2], P[27*3],P[27*3+1],P[27*3+2]);
    double shinBefore = dist(P, 25, 27);
    int fixed = clampHumanLimits(P);
    double after = ikAngle(P[23*3],P[23*3+1],P[23*3+2], P[25*3],P[25*3+1],P[25*3+2], P[27*3],P[27*3+1],P[27*3+2]);
    double shinAfter = dist(P, 25, 27);
    check(before < 5.0, "test setup: impossible over-bent knee starts below the 5deg limit");
    check(fixed >= 1, "the impossible joint is reported as corrected");
    check(after >= 4.0 && after <= 10.0, "the over-bent knee is pulled back to its limit");
    check(std::fabs(shinBefore - shinAfter) < 1e-6, "clamping preserves the shin bone length");
  }

  // DÜRÜSTLÜK: ikAngle 0-180° arası iç açı verir, yani >180 üst sınır ASLA
  // tetiklenmez — düz bir bacak (180°) hiç kırpılmaz. Bunu doğrula (yalancı üst
  // sınır iddiası yok). Kırpma yalnız ALT sınırda (imkansız aşırı-büküm) çalışır.
  {
    double P[99] = {0};
    P[24*3]=0; P[24*3+1]=0; P[24*3+2]=0;         // kalça
    P[26*3]=0; P[26*3+1]=-0.4; P[26*3+2]=0;      // diz
    P[28*3]=0; P[28*3+1]=-0.8; P[28*3+2]=0;      // bilek tam altta -> düz bacak ~180
    double before = ikAngle(P[24*3],P[24*3+1],P[24*3+2], P[26*3],P[26*3+1],P[26*3+2], P[28*3],P[28*3+1],P[28*3+2]);
    clampHumanLimits(P);
    double after = ikAngle(P[24*3],P[24*3+1],P[24*3+2], P[26*3],P[26*3+1],P[26*3+2], P[28*3],P[28*3+1],P[28*3+2]);
    check(before > 178.0, "test setup: a straight leg reads ~180deg");
    check(std::fabs(before - after) < 0.5, "a straight (180deg) leg is left untouched - no false upper clamp");
  }

  // gerçek DERİN tekrar kırpma ile DEĞİŞMEMELİ (CS-dekan: geniş güvenlik bandı,
  // meşru derin push-up/squat'ı bozma). dirsek ~30° (gerçek tam büküm) korunmalı.
  {
    double P[99] = {0};
    // omuz üstte, dirsek altta; bilek dirsekten omuza doğru dar açıyla geri katlı.
    P[11*3]=0.0;  P[11*3+1]=0.0;   P[11*3+2]=0;   // omuz
    P[13*3]=0.0;  P[13*3+1]=-0.30; P[13*3+2]=0;   // dirsek (omuzun altında)
    // bilek: dirsekten yukarı-yana, omuz yönüne dar açı (~30°)
    P[15*3]=0.14; P[15*3+1]=-0.02; P[15*3+2]=0;
    double before = ikAngle(P[11*3],P[11*3+1],P[11*3+2], P[13*3],P[13*3+1],P[13*3+2], P[15*3],P[15*3+1],P[15*3+2]);
    clampHumanLimits(P);
    double after = ikAngle(P[11*3],P[11*3+1],P[11*3+2], P[13*3],P[13*3+1],P[13*3+2], P[15*3],P[15*3+1],P[15*3+2]);
    check(before > 20 && before < 50, "test setup: a real deep elbow bend (~30deg)");
    check(std::fabs(before - after) < 0.5, "a real deep bend is NOT altered by the safety clamp (wide band)");
  }

  // ZİNCİR YAKINSAMA (CS-dekan): diz VE kalça aynı anda ihlal → kırpma sonrası
  // İKİSİ de yasal olmalı (tek geçiş birini bozabilirdi, iterasyon çözer).
  {
    double P[99] = {0};
    // sol bacak zinciri: omuz(11)-kalça(23)-diz(25)-bilek(27)
    P[11*3]=0.0; P[11*3+1]=-0.5; P[11*3+2]=0;
    P[23*3]=0.0; P[23*3+1]=0.0;  P[23*3+2]=0;
    P[25*3]=0.0; P[25*3+1]=0.4;  P[25*3+2]=0;
    // diz aşırı bükülü (bilek kalçaya çok yakın) + kalça aşırı kapalı olacak şekilde kur
    P[27*3]=0.02; P[27*3+1]=0.05; P[27*3+2]=0;   // diz açısı çok küçük
    clampHumanLimits(P);
    double knee = ikAngle(P[23*3],P[23*3+1],P[23*3+2], P[25*3],P[25*3+1],P[25*3+2], P[27*3],P[27*3+1],P[27*3+2]);
    double hip  = ikAngle(P[11*3],P[11*3+1],P[11*3+2], P[23*3],P[23*3+1],P[23*3+2], P[25*3],P[25*3+1],P[25*3+2]);
    check(knee >= 4.0 && knee <= 181.0, "after clamp: knee is within limits");
    check(hip >= 7.0 && hip <= 181.0, "after clamp: hip is ALSO within limits (chain converged)");
  }

  std::printf(failed ? "\n%d ik test FAILED\n" : "\nall ik tests passed\n", failed);
  return failed ? 1 : 0;
}
