// test.cpp — coach motorunun SAF çekirdek testleri.
// Web yok, wasm yok: normal clang++ ile derlenir, terminalde koşar. Çekirdek
// framework'süz olduğu için bunu yapabiliyoruz — mantığı tarayıcıya girmeden
// doğruluyoruz. Koşmak: engine/test.sh

#include "coach_engine.hpp"
#include <cmath>
#include <cstdio>
#include <vector>

using namespace coach;

static int failed = 0;
static void check(bool cond, const char* msg) {
  std::printf("%s %s\n", cond ? "ok  " : "FAIL", msg);
  if (!cond) failed++;
}

// squat için sentetik bir poz: düz bacak (~180° diz) ya da bükülü (~90° diz).
static std::vector<Landmark> pose(bool bent) {
  std::vector<Landmark> p(33);
  auto set = [&](int i, double x, double y) { p[i].x = x; p[i].y = y; p[i].z = 0; p[i].visibility = 1; };
  set(11, 0.45, 0.20); set(12, 0.55, 0.20);   // omuzlar
  set(23, 0.45, 0.50); set(24, 0.55, 0.50);   // kalçalar
  set(25, 0.45, 0.70); set(26, 0.55, 0.70);   // dizler
  if (!bent) { set(27, 0.45, 0.90); set(28, 0.55, 0.90); }   // düz: ayak bileği dizin altında -> ~180°
  else       { set(27, 0.65, 0.70); set(28, 0.75, 0.70); }   // bükülü: ayak bileği ileride -> ~90°
  return p;
}

int main() {
  // ── açı geometrisi ──
  {
    Engine e(builtinMove("squat"));
    Reading r = e.update(pose(false));
    check(std::fabs(r.angles.leftKnee - 180.0) < 5.0, "straight leg knee angle ~180");
    Engine e2(builtinMove("squat"));
    Reading rb = e2.update(pose(true));
    check(std::fabs(rb.angles.leftKnee - 90.0) < 5.0, "bent leg knee angle ~90");
  }

  // ── güven / kadraj kapısı ──
  {
    Engine e(builtinMove("squat"));
    std::vector<Landmark> blank(33);            // hepsi visibility 0
    Reading r = e.update(blank);
    check(!r.tracking, "invisible body is not tracked");
    std::vector<Landmark> few;                  // 33'ten az
    Reading r2 = e.update(few);
    check(!r2.tracking, "too few points is not tracked");
  }

  // ── durum makinesi + derinlik: ayakta -> dip -> ayakta ──
  {
    Engine e(builtinMove("squat"));
    Reading r;
    for (int i = 0; i < 6; i++) r = e.update(pose(false));   // EMA otursun
    check(r.tracking, "clear pose is tracked");
    check(r.phase == Phase::Top, "straight leg = phase top");
    check(r.depth < 0.2, "straight leg = shallow depth");

    for (int i = 0; i < 10; i++) r = e.update(pose(true));
    check(r.phase == Phase::Bottom, "bent leg = phase bottom");
    check(r.depth > 0.8, "bent leg = deep");

    for (int i = 0; i < 10; i++) r = e.update(pose(false));
    check(r.phase == Phase::Top, "standing again = phase top");
  }

  // ── histerezis: tek eşik olsaydı sınırda titrerdi; iki eşik sağlam olmalı ──
  {
    Engine e(builtinMove("squat"));
    for (int i = 0; i < 6; i++) e.update(pose(false));
    // dibe in, sonra sadece biraz kalk (üst eşiği geçmeden) -> hâlâ bottom kalmalı
    Reading r;
    for (int i = 0; i < 10; i++) r = e.update(pose(true));
    check(r.phase == Phase::Bottom, "hysteresis: stays bottom until fully up");
  }

  std::printf(failed ? "\n%d test FAILED\n" : "\nall tests passed\n", failed);
  return failed ? 1 : 0;
}
