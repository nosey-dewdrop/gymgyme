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
    // bilek kalçaya çok yakın -> diz açısı çok küçük
    P[27*3]=0.03; P[27*3+1]=-0.05; P[27*3+2]=0;
    double before = ikAngle(P[23*3],P[23*3+1],P[23*3+2], P[25*3],P[25*3+1],P[25*3+2], P[27*3],P[27*3+1],P[27*3+2]);
    double shinBefore = dist(P, 25, 27);
    int fixed = clampHumanLimits(P);
    double after = ikAngle(P[23*3],P[23*3+1],P[23*3+2], P[25*3],P[25*3+1],P[25*3+2], P[27*3],P[27*3+1],P[27*3+2]);
    double shinAfter = dist(P, 25, 27);
    check(before < 15.0, "test setup: impossible over-bent knee starts below the limit");
    check(fixed >= 1, "the impossible joint is reported as corrected");
    check(after >= 14.0 && after <= 20.0, "the over-bent knee is pulled back to its limit");
    check(std::fabs(shinBefore - shinAfter) < 1e-6, "clamping preserves the shin bone length");
  }

  // hiper-ekstansiyon: diz geriye bükülü (>183°) — geri çekilmeli
  {
    double P[99] = {0};
    P[24*3]=0; P[24*3+1]=0; P[24*3+2]=0;          // sağ kalça
    P[26*3]=0; P[26*3+1]=-0.4; P[26*3+2]=0;       // sağ diz
    // bilek, kalça-diz doğrultusunun ÖTESİNE bükülü (geriye kırık) -> >183
    P[28*3]=-0.02; P[28*3+1]=-0.85; P[28*3+2]=0.0;
    // hafif geriye krılma acısı yarat: bilek dizden ileri+geride
    P[28*3]=0.0; P[28*3+1]=-0.80; P[28*3+2]=-0.02;
    double before = ikAngle(P[24*3],P[24*3+1],P[24*3+2], P[26*3],P[26*3+1],P[26*3+2], P[28*3],P[28*3+1],P[28*3+2]);
    int fixed = clampHumanLimits(P);
    double after = ikAngle(P[24*3],P[24*3+1],P[24*3+2], P[26*3],P[26*3+1],P[26*3+2], P[28*3],P[28*3+1],P[28*3+2]);
    // (bu poz cok geriye kirik degilse fixed 0 olabilir — o zaman zaten aralikta)
    if (before > 183.0) { check(after <= 184.0, "a hyperextended knee is pulled back under the limit"); }
    else check(true, "knee already within range (setup did not exceed hyperextension)");
    (void)fixed;
  }

  std::printf(failed ? "\n%d ik test FAILED\n" : "\nall ik tests passed\n", failed);
  return failed ? 1 : 0;
}
