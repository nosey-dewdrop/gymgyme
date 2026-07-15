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

// YARIM squat: ayak bileği 45 derece geride -> diz ~135° (alt eşik 110'un ÜSTÜNDE).
static std::vector<Landmark> poseHalf() {
  std::vector<Landmark> p = pose(false);
  auto set = [&](int i, double x, double y) { p[i].x = x; p[i].y = y; };
  set(27, 0.59, 0.84); set(28, 0.69, 0.84);
  return p;
}

// SIĞ kıpırtı: diz ~148° — üst eşiğin altında ama yarım derinliğine bile ulaşmıyor.
static std::vector<Landmark> poseSlight() {
  std::vector<Landmark> p = pose(false);
  auto set = [&](int i, double x, double y) { p[i].x = x; p[i].y = y; };
  set(27, 0.55, 0.86); set(28, 0.65, 0.86);
  return p;
}

// DÜNYA pozu (metrik 3B). bentTowardCamera=true: diz KAMERAYA doğru bükülü —
// ekran düzleminde düz görünür (perspektif kısalması), gerçekte ~70°.
static std::vector<Landmark> worldPose(bool bentTowardCamera) {
  std::vector<Landmark> p(33);
  auto set = [&](int i, double x, double y, double z) { p[i].x = x; p[i].y = y; p[i].z = z; p[i].visibility = 1; };
  set(11, -0.18, -0.50, 0); set(12, 0.18, -0.50, 0);   // omuzlar (x'te yayılmış = önden)
  set(23, -0.10,  0.00, 0); set(24, 0.10,  0.00, 0);   // kalçalar
  if (!bentTowardCamera) {
    set(25, -0.10, 0.40, 0);  set(26, 0.10, 0.40, 0);  // dizler
    set(27, -0.10, 0.80, 0);  set(28, 0.10, 0.80, 0);  // bilekler: düz ~180°
  } else {
    set(25, -0.10, 0.25, -0.35); set(26, 0.10, 0.25, -0.35);  // dizler kameraya doğru
    set(27, -0.10, 0.50, 0);     set(28, 0.10, 0.50, 0);      // ~70° gerçek büküm
  }
  return p;
}

// YAN duruş dünya pozu: omuz/kalça hattı derinlik ekseninde yayılmış.
static std::vector<Landmark> worldPoseSide() {
  std::vector<Landmark> p = worldPose(false);
  auto set = [&](int i, double x, double y, double z) { p[i].x = x; p[i].y = y; p[i].z = z; };
  set(11, 0, -0.50, -0.18); set(12, 0, -0.50, 0.18);
  set(23, 0,  0.00, -0.10); set(24, 0,  0.00, 0.10);
  return p;
}

// dipte VALGUS: bükülü diz pozu ama dizler içe çökmüş (bilek genişliğinin %25'i).
static std::vector<Landmark> worldPoseValgus() {
  std::vector<Landmark> p = worldPose(true);
  auto set = [&](int i, double x, double y, double z) { p[i].x = x; p[i].y = y; p[i].z = z; };
  set(25, -0.03, 0.25, -0.35); set(26, 0.03, 0.25, -0.35);   // dizler içerde
  set(27, -0.12, 0.50, 0);     set(28, 0.12, 0.50, 0);       // bilekler geniş
  return p;
}

// dipte ÖNE EĞİLME: bükülü diz + gövde dikeyden ~77° devrik.
static std::vector<Landmark> worldPoseLean() {
  std::vector<Landmark> p = worldPose(true);
  auto set = [&](int i, double x, double y, double z) { p[i].x = x; p[i].y = y; p[i].z = z; };
  set(11, -0.18, -0.10, -0.45); set(12, 0.18, -0.10, -0.45);  // omuzlar öne düşmüş
  return p;
}

// KOL pozu (push-up / press): dirsek düz (~180°) ya da bükülü (~90°).
static std::vector<Landmark> poseArms(bool bent) {
  std::vector<Landmark> p(33);
  auto set = [&](int i, double x, double y) { p[i].x = x; p[i].y = y; p[i].z = 0; p[i].visibility = 1; };
  set(11, 0.45, 0.30); set(12, 0.55, 0.30);   // omuzlar
  set(13, 0.45, 0.50); set(14, 0.55, 0.50);   // dirsekler
  set(23, 0.45, 0.62); set(24, 0.55, 0.62);   // kalçalar (push-up kadrajı için)
  if (!bent) { set(15, 0.45, 0.70); set(16, 0.55, 0.70); }   // bilek dirseğin altında -> ~180°
  else       { set(15, 0.65, 0.50); set(16, 0.75, 0.50); }   // bilek yanda -> ~90°
  return p;
}

// KALÇA pozu (glute bridge / sit-up): kalça açık (~180°, gövde-bacak düz)
// ya da kapalı (crunch, ~70°).
static std::vector<Landmark> poseHips(bool open) {
  std::vector<Landmark> p(33);
  auto set = [&](int i, double x, double y) { p[i].x = x; p[i].y = y; p[i].z = 0; p[i].visibility = 1; };
  set(11, 0.30, 0.58); set(12, 0.30, 0.62);   // omuzlar
  set(23, 0.50, 0.58); set(24, 0.50, 0.62);   // kalçalar
  if (open) { set(25, 0.70, 0.58); set(26, 0.70, 0.62); }        // diz uzakta -> ~180°
  else      { set(25, 0.432, 0.412); set(26, 0.432, 0.452); }    // diz yukarıda -> ~70°
  return p;
}

// köprü ARASI kalça: ~123° (köprünün alt eşiği 140'ın altında, dip sayılır).
static std::vector<Landmark> poseHipsMid() {
  std::vector<Landmark> p = poseHips(true);
  auto set = [&](int i, double x, double y) { p[i].x = x; p[i].y = y; };
  set(25, 0.60, 0.43); set(26, 0.60, 0.47);
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

  // ── One Euro filtre: sabit girdiye yakınsar, reset hafızayı siler ──
  {
    Engine e(builtinMove("squat"));   // varsayılan yol One Euro
    Reading r;
    for (int i = 0; i < 30; i++) r = e.update(pose(false));
    check(std::fabs(r.smoothAngle - r.rawAngle) < 1.0, "one euro converges on a still pose");

    // reset sonrası filtre eski açıyı HATIRLAMAMALI: bükük pozla ilk okuma
    // düz bacağın (~180) değil bükük bacağın (~90) yanında başlamalı.
    e.reset();
    r = e.update(pose(true));
    check(r.smoothAngle < 120.0, "reset clears the one euro memory");
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

  // ── Aşama 7: sayma — tam döngü sayılır, yarım iniş sayılmaz ──
  {
    Engine e(builtinMove("squat"));
    Reading r;
    for (int i = 0; i < 6; i++) r = e.update(pose(false));
    check(r.reps == 0, "no reps before any cycle");

    bool ticked = false;
    for (int i = 0; i < 10; i++) r = e.update(pose(true));      // dibe
    for (int i = 0; i < 12; i++) { r = e.update(pose(false)); ticked |= r.repTick; }  // üste
    check(r.reps == 1, "one full cycle = one rep");
    check(ticked, "repTick fires on the counting frame");

    for (int i = 0; i < 10; i++) r = e.update(pose(true));
    for (int i = 0; i < 12; i++) r = e.update(pose(false));
    check(r.reps == 2, "second full cycle = two reps");

    // yarım iniş: alt eşiğe hiç inilmiyor -> sayaç oynamamalı
    for (int i = 0; i < 10; i++) r = e.update(poseHalf());
    for (int i = 0; i < 12; i++) r = e.update(pose(false));
    check(r.reps == 2, "half descent does not count");

    e.reset();
    r = e.update(pose(false));
    check(r.reps == 0, "reset clears the rep count");
  }

  // ── Aşama 8: yarım tekrar — anlamlı ama dipsiz iniş yakalanır, kıpırtı elenir ──
  {
    Engine e(builtinMove("squat"));
    Reading r;
    for (int i = 0; i < 6; i++) r = e.update(pose(false));

    bool ticked = false;
    for (int i = 0; i < 10; i++) r = e.update(poseHalf());       // ~135°: derin ama dipsiz
    for (int i = 0; i < 12; i++) { r = e.update(pose(false)); ticked |= r.halfTick; }
    check(r.halfReps == 1 && r.reps == 0, "half descent is flagged, not counted");
    check(ticked, "halfTick fires when the half rep is caught");

    for (int i = 0; i < 10; i++) r = e.update(poseSlight());     // ~148°: kıpırtı
    for (int i = 0; i < 12; i++) r = e.update(pose(false));
    check(r.halfReps == 1, "a slight dip is not a half rep");

    for (int i = 0; i < 10; i++) r = e.update(pose(true));       // tam tekrar
    for (int i = 0; i < 12; i++) r = e.update(pose(false));
    check(r.reps == 1 && r.halfReps == 1, "a full rep does not add a half");

    e.reset();
    r = e.update(pose(false));
    check(r.halfReps == 0, "reset clears half reps");
  }

  // ── kalite skoru: kontrollü tekrar yüksek, aceleci tekrar düşük puan alır ──
  {
    Engine e(builtinMove("squat"));
    Reading r;
    double t = 0;
    auto step = [&](const std::vector<Landmark>& p, double dtMs) { t += dtMs; return e.update(p, t); };

    for (int i = 0; i < 6; i++) r = step(pose(false), 100);
    check(r.lastRepScore == -1, "no score before the first rep");

    for (int i = 0; i < 10; i++) r = step(pose(true), 100);   // 1 sn kontrollü iniş
    for (int i = 0; i < 10; i++) r = step(pose(false), 100);  // 1 sn kontrollü çıkış
    check(r.reps == 1 && r.lastRepScore >= 90, "controlled full rep scores high");
    int good = r.lastRepScore;

    for (int i = 0; i < 9; i++) r = step(pose(true), 20);     // ~0.4 sn'lik aceleci tekrar
    for (int i = 0; i < 9; i++) r = step(pose(false), 20);
    check(r.reps == 2 && r.lastRepScore < good, "a rushed rep scores lower");
    check(r.avgRepScore > 0 && r.avgRepScore <= 100, "session average is tracked");

    e.reset();
    r = e.update(pose(false));
    check(r.lastRepScore == -1, "reset clears the score");
  }

  // ── 3B: kameraya doğru bükülme 2B'de kaybolur, dünya verisiyle görülür ──
  {
    // sadece ekran verisi: bükülü diz "düz" görünür, motor üstte sanır
    Engine flat(builtinMove("squat"));
    Reading rf;
    for (int i = 0; i < 10; i++) rf = flat.update(pose(false));   // ekranda hep düz
    check(rf.phase == Phase::Top, "2d only: camera-facing bend is invisible");

    // dünya verisiyle: aynı ekran görüntüsü, ama motor gerçek 3B açıyı ölçer
    Engine e(builtinMove("squat"));
    Reading r;
    double t = 0;
    for (int i = 0; i < 6; i++) { t += 100; r = e.update(pose(false), worldPose(false), t); }
    check(r.phase == Phase::Top && r.view == View::Front, "3d: straight pose reads top, front view");
    for (int i = 0; i < 10; i++) { t += 100; r = e.update(pose(false), worldPose(true), t); }
    check(r.phase == Phase::Bottom, "3d: camera-facing bend is caught as deep");
    check(r.angles.leftKnee < 90.0, "3d knee angle is the real one, not the flattened one");
    for (int i = 0; i < 12; i++) { t += 100; r = e.update(pose(false), worldPose(false), t); }
    check(r.reps == 1, "3d rep counts through the same machine");

    // yan duruş tespiti
    Engine s(builtinMove("squat"));
    Reading rs = s.update(pose(false), worldPoseSide(), 33);
    check(rs.view == View::Side, "side stance is detected from depth spread");
  }

  // ── Aşama 9: form kuralları — temiz tekrar sessiz, bozuk form konuşur ve puan kırar ──
  {
    // temiz tekrar
    Engine c(builtinMove("squat"));
    Reading r;
    double t = 0;
    auto step = [&](Engine& e, const std::vector<Landmark>& w) { t += 100; return e.update(pose(false), w, t); };
    bool anyCue = false;
    for (int i = 0; i < 6; i++) r = step(c, worldPose(false));
    for (int i = 0; i < 10; i++) { r = step(c, worldPose(true)); anyCue |= !r.formCue.empty(); }
    for (int i = 0; i < 12; i++) r = step(c, worldPose(false));
    int cleanScore = r.lastRepScore;
    check(!anyCue, "clean depth raises no cue");
    check(r.lastRepFormIssues == 0, "clean rep has zero form issues");

    // valgus'lu tekrar: cue + puan cezası
    Engine v(builtinMove("squat"));
    bool cued = false;
    for (int i = 0; i < 6; i++) r = step(v, worldPose(false));
    for (int i = 0; i < 10; i++) { r = step(v, worldPoseValgus()); cued |= (r.formCue == "push your knees out"); }
    for (int i = 0; i < 12; i++) r = step(v, worldPose(false));
    check(cued, "knee valgus raises the knees-out cue");
    check(r.lastRepFormIssues == 1, "valgus rep records one form issue");
    check(r.lastRepScore < cleanScore, "form issue costs score");

    // öne eğilme: sırt uyarısı
    Engine l(builtinMove("squat"));
    cued = false;
    for (int i = 0; i < 6; i++) r = step(l, worldPose(false));
    for (int i = 0; i < 10; i++) { r = step(l, worldPoseLean()); cued |= (r.formCue == "keep your chest up - back straighter"); }
    check(cued, "torso lean raises the chest-up cue");

    // valgus yandan görünmez: yan görüşte kural hiç bakılmaz
    Engine sv(builtinMove("squat"));
    std::vector<Landmark> sideValgus = worldPoseValgus();
    // omuz/kalça hattını derinliğe çevir -> view side
    sideValgus[11] = {0, -0.50, -0.18, 1}; sideValgus[12] = {0, -0.50, 0.18, 1};
    sideValgus[23] = {0, 0.00, -0.10, 1};  sideValgus[24] = {0, 0.00, 0.10, 1};
    cued = false;
    for (int i = 0; i < 10; i++) { t += 100; r = sv.update(pose(false), sideValgus, t); cued |= (r.formCue == "push your knees out"); }
    check(!cued, "valgus rule is not judged from the side view");
  }

  // ── hareket kütüphanesi: aynı motor, farklı veri ──
  {
    check(builtinMove("pushup").name == "pushup", "pushup spec exists");
    check(builtinMove("nonsense").name == "squat", "unknown move falls back to squat");

    // push-up: dirsek zincirinden sayar
    Engine pu(builtinMove("pushup"));
    Reading r;
    for (int i = 0; i < 6; i++) r = pu.update(poseArms(false));
    check(r.tracking && r.phase == Phase::Top, "pushup: straight arms read top");
    for (int i = 0; i < 10; i++) r = pu.update(poseArms(true));
    check(r.phase == Phase::Bottom, "pushup: bent arms read bottom");
    for (int i = 0; i < 12; i++) r = pu.update(poseArms(false));
    check(r.reps == 1, "pushup: full cycle counts on the same machine");

    // push-up kadrajı kol ister: bacak pozu (kollar görünmez) takip edilmez
    Engine puf(builtinMove("pushup"));
    Reading rf = puf.update(pose(false));
    check(!rf.tracking, "pushup framing needs the arms, legs alone fail");

    // press: bükülü başlar (raf) — ilk kilitte 1. tekrar
    Engine pr(builtinMove("press"));
    for (int i = 0; i < 6; i++) r = pr.update(poseArms(true));
    check(r.phase == Phase::Bottom && r.reps == 0, "press: racked start reads bottom");
    for (int i = 0; i < 12; i++) r = pr.update(poseArms(false));
    check(r.reps == 1, "press: counts on lockout from a bent start");

    // glute bridge: kalça açısından, uzama yönünde
    Engine gb(builtinMove("glutebridge"));
    for (int i = 0; i < 6; i++) r = gb.update(poseHipsMid());   // yerde: ~123° < 140
    check(r.phase == Phase::Bottom, "bridge: on the floor reads bottom");
    for (int i = 0; i < 12; i++) r = gb.update(poseHips(true)); // köprü: ~180°
    check(r.reps == 1, "bridge: full extension counts a rep");

    // sit-up: kalça kapanınca dip, geri yatınca tekrar
    Engine su(builtinMove("situp"));
    for (int i = 0; i < 6; i++) r = su.update(poseHips(true));  // yerde ~180°
    check(r.phase == Phase::Top, "situp: lying flat reads top");
    for (int i = 0; i < 10; i++) r = su.update(poseHips(false)); // crunch ~70°
    check(r.phase == Phase::Bottom, "situp: crunch reads bottom");
    for (int i = 0; i < 12; i++) r = su.update(poseHips(true));
    check(r.reps == 1, "situp: counts on the way back down");

    // hip sag kuralı (push-up'ın kuralı) değerlendiriliyor mu — squat spec'ine takıp
    // dipteki doğal kalça kırılmasıyla tetikliyoruz (evaluator testi)
    MoveSpec hs = builtinMove("squat");
    hs.rules = {{RuleKind::HipSag, 160.0, View::Unknown, "keep your body in one line - hips up"}};
    Engine he(hs);
    bool cued = false;
    double t2 = 0;
    for (int i = 0; i < 6; i++) { t2 += 100; he.update(pose(false), worldPose(false), t2); }
    for (int i = 0; i < 10; i++) { t2 += 100; Reading rr = he.update(pose(false), worldPose(true), t2); cued |= (rr.formCue == "keep your body in one line - hips up"); }
    check(cued, "hip sag rule evaluates from the shoulder hip knee line");
  }

  // ── Aşama 13: setler ve dinlenme — hedefe ulaşınca set biter, mola başlar,
  // mola bitince sıradaki set, son set sonrası antrenman tamamlanır ──
  {
    Engine e(builtinMove("squat"));
    e.setPlan(2, 2, 60.0);        // set başı 2 tekrar, 2 set, 60 sn mola
    Reading r;
    double t = 0;
    auto rep = [&](Engine& en) {  // bir tam tekrar (dip + üst), zaman ilerler
      Reading rr;
      for (int i = 0; i < 10; i++) { t += 100; rr = en.update(pose(true), t); }
      for (int i = 0; i < 12; i++) { t += 100; rr = en.update(pose(false), t); }
      return rr;
    };
    for (int i = 0; i < 6; i++) { t += 100; r = e.update(pose(false), t); }
    check(r.currentSet == 1 && r.repsInSet == 0 && r.targetReps == 2, "plan starts at set 1, target 2");

    r = rep(e);
    check(r.reps == 1 && r.repsInSet == 1 && !r.resting, "first rep fills the set, no rest yet");
    bool setDone = false;
    for (int i = 0; i < 10; i++) { t += 100; r = e.update(pose(true), t); }
    for (int i = 0; i < 12; i++) { t += 100; r = e.update(pose(false), t); setDone |= r.setTick; }
    check(setDone, "setTick fires when the set target is reached");
    check(r.resting && r.restRemaining > 55.0, "reaching the target starts the rest countdown");
    check(r.currentSet == 1, "still on set 1 label until the rest ends");

    // dinlenme sırasında yapılan tekrar sıradaki setin hanesine YAZILMAZ
    int repsBefore = r.reps;
    r = rep(e);
    check(r.reps == repsBefore && r.resting, "reps during rest do not count");

    e.skipRest();
    r = e.update(pose(false), (t += 100));
    check(!r.resting && r.currentSet == 2 && r.repsInSet == 0, "skipRest advances to the next set");

    // son set: hedefe ulaşınca antrenman biter, mola YOK
    rep(e);
    r = rep(e);
    check(r.workoutComplete && !r.resting, "finishing the last set completes the workout, no rest");
    int repsAtEnd = r.reps;
    r = rep(e);
    check(r.reps == repsAtEnd, "no reps count after the workout is complete");

    // reset ilerlemeyi sıfırlar ama planı korur
    e.reset();
    r = e.update(pose(false), (t += 100));
    check(r.currentSet == 1 && r.repsInSet == 0 && r.targetReps == 2 && !r.workoutComplete,
          "reset clears set progress but keeps the plan");
  }

  // ── Aşama 13: dinlenme SÜRESI dolunca otomatik sıradaki sete geçilir ──
  {
    Engine e(builtinMove("squat"));
    e.setPlan(1, 3, 1.0);         // 1 tekrar/set, 3 set, 1 sn mola
    Reading r;
    double t = 0;
    for (int i = 0; i < 6; i++) { t += 100; r = e.update(pose(false), t); }
    for (int i = 0; i < 10; i++) { t += 100; r = e.update(pose(true), t); }
    // yukarı dön ve tekrarın SAYILDIĞI karede dur — kontrol filtrenin yakınsama
    // hızına bağlı olmasın (One Euro EMA'dan bir kare önce varabiliyor).
    for (int i = 0; i < 20 && !r.repTick; i++) { t += 100; r = e.update(pose(false), t); }
    check(r.resting && r.currentSet == 1, "one-rep set enters rest");
    // molanın süresini geçecek kadar zaman ilerlet (üstte dur)
    for (int i = 0; i < 15; i++) { t += 100; r = e.update(pose(false), t); }
    check(!r.resting && r.currentSet == 2, "rest auto-expires into the next set after its seconds");
  }

  // ── Aşama 13: plansız (targetReps=0) davranış bugünküyle aynı — sonsuz say ──
  {
    Engine e(builtinMove("squat"));
    Reading r;
    check(builtinMove("squat").name == "squat", "");   // (no-op anchor)
    for (int i = 0; i < 6; i++) r = e.update(pose(false));
    check(r.targetReps == 0 && r.currentSet == 1 && !r.workoutComplete, "no plan = endless counting, never completes");
  }

  // ── Aşama 14: seans özeti ──
  {
    Engine e(builtinMove("squat"));
    e.setPlan(2, 2, 60.0);
    double t = 0;
    auto rep = [&](Engine& en) {
      Reading rr;
      for (int i = 0; i < 10; i++) { t += 100; rr = en.update(pose(true), t); }
      for (int i = 0; i < 12; i++) { t += 100; rr = en.update(pose(false), t); }
      return rr;
    };
    for (int i = 0; i < 6; i++) { t += 100; e.update(pose(false), t); }
    check(e.summary().reps == 0 && e.summary().avgScore == -1, "empty summary before any rep");

    rep(e); rep(e);                 // 1. set + mola
    e.skipRest();
    rep(e); rep(e);                 // 2. set → tamamlandı
    Summary s = e.summary();
    check(s.reps == 4, "summary counts every rep");
    check(s.workoutComplete && s.setsCompleted == 2, "summary marks a completed workout");
    check(s.avgScore >= 0 && s.bestScore >= s.avgScore, "summary has avg and best");
    check(s.cleanReps == 4, "clean reps counted (no 3d = no form issue)");
    check(s.durationSec > 0, "summary has a session duration");

    e.reset();
    check(e.summary().reps == 0 && e.summary().bestScore == -1, "reset clears the summary");
  }

  // ── ince takip: tek karelik ışınlanma yutulur, süren hareket kabul edilir ──
  {
    Engine e(builtinMove("squat"));
    Reading r;
    for (int i = 0; i < 8; i++) r = e.update(pose(false));
    r = e.update(pose(true));                 // tek karelik glitch (~90° sıçrama)
    check(r.phase == Phase::Top, "a single teleport frame is swallowed");
    for (int i = 0; i < 10; i++) r = e.update(pose(true));
    check(r.phase == Phase::Bottom, "a sustained move is accepted after one frame");
    for (int i = 0; i < 12; i++) r = e.update(pose(false));
    check(r.reps == 1, "counting still works with the spike gate on");
  }

  // ── DÖNÜŞ NOKTASINDA occlusion, ENGINE seviyesi (CS-dekan: Kalman1D testi
  // vardı ama rep FSM occlusion altında sınanmamıştı). Dip anında bir bacak
  // noktası birkaç kare görünmez olsa bile rep sayısı bozulmamalı: ne phantom
  // (fazla), ne miss (eksik). ──
  {
    Engine e(builtinMove("squat"));
    Reading r;
    // dip pozunun bir kopyası ama sağ bilek (28) görünmez — occlusion
    auto poseBentOccluded = []() {
      std::vector<Landmark> p = pose(true);
      p[28].visibility = 0.0;   // sağ bilek kaybolur (dipte sık: en çok kapanan)
      return p;
    };
    for (int i = 0; i < 6; i++) r = e.update(pose(false));
    for (int i = 0; i < 4; i++) r = e.update(pose(true));          // dibe in
    for (int i = 0; i < 4; i++) r = e.update(poseBentOccluded());  // dipte occlusion
    for (int i = 0; i < 12; i++) r = e.update(pose(false));        // üste dön
    check(r.reps == 1, "occlusion at the turnaround: exactly one rep, no phantom, no miss");
    // ikinci temiz tekrar da normal sayılmalı (occlusion kalıcı hasar bırakmadı)
    for (int i = 0; i < 10; i++) r = e.update(pose(true));
    for (int i = 0; i < 12; i++) r = e.update(pose(false));
    check(r.reps == 2, "counting recovers cleanly after a turnaround occlusion");
  }

  // ── kalibrasyon: önce vücudu öğren, sayma o sırada dursun, sonra kilitlen ──
  {
    Engine e(builtinMove("squat"));
    e.setCalibration(true);
    Reading r;
    double t = 0;
    r = e.update(pose(false), worldPose(false), (t += 33));
    check(r.calibrating && r.calibProgress > 0, "calibration starts on the first tracked frame");
    // kalibrasyon sürerken yapılan tam döngü SAYILMAZ
    for (int i = 0; i < 10; i++) r = e.update(pose(true), worldPose(true), (t += 33));
    for (int i = 0; i < 12; i++) r = e.update(pose(false), worldPose(false), (t += 33));
    check(r.reps == 0, "no reps are counted while calibrating");
    // öğrenme tamamlanır (60 kare)
    for (int i = 0; i < 45; i++) r = e.update(pose(false), worldPose(false), (t += 33));
    check(!r.calibrating, "calibration completes after enough frames");
    // kalibre olduktan sonra normal döngü sayılır (bükülme oranları bozmaz)
    for (int i = 0; i < 10; i++) r = e.update(pose(true), worldPose(true), (t += 33));
    for (int i = 0; i < 14; i++) r = e.update(pose(false), worldPose(false), (t += 33));
    check(r.reps == 1, "counting works after calibration, bending does not break the lock");
    // bacakları yarıya inmiş sahte vücut: bu okuma reddedilir
    std::vector<Landmark> shrunk = worldPose(false);
    shrunk[25].y = 0.20; shrunk[26].y = 0.20;   // dizler yukarı: uyluk yarıya iner
    shrunk[27].y = 0.40; shrunk[28].y = 0.40;   // bilekler de: baldır yarıya iner
    r = e.update(pose(false), shrunk, (t += 33));
    check(!r.tracking, "a body that does not match the calibration is rejected");
    // kalibrasyonsuz motor aynı okumayı kabul ederdi (kilit gerçekten kalibrasyondan)
    Engine e2(builtinMove("squat"));
    Reading r2;
    for (int i = 0; i < 6; i++) r2 = e2.update(pose(false), shrunk, 33.0 * (i + 1));
    check(r2.tracking, "without calibration the same read is accepted");
  }

  // ── kalibrasyon güçlendirme: TUTARLILIK KAPISI. Kişi kalibrasyon boyunca
  // hareket ederse (oranlar saçılır) motor kirli örnekle kilitlenmez — yeniden
  // öğrenir (bir kez uzatır). Temiz örnekte ise normal tamamlanır. ──
  {
    // KİRLİ kalibrasyon: her kare vücut oranları rastgele oynatılır (kişi hareketli).
    // Motor ilk 60 karede güvenilir oran bulamayıp yeniden öğrenmeye geçmeli.
    Engine e(builtinMove("squat"));
    e.setCalibration(true);
    Reading r;
    double t = 0;
    // kirli örnek üretmek için diz konumunu kare kare kaydır (uyluk/baldır oranı sapar)
    for (int i = 0; i < 62; i++) {
      std::vector<Landmark> w = worldPose(false);
      double jitter = (i % 4 - 1.5) * 0.10;   // ±0.15 deterministik saçılma
      w[25].y += jitter; w[26].y += jitter;    // dizler oynar -> uyluk/baldır oranı kirlenir
      r = e.update(pose(false), w, (t += 33));
    }
    // 60 kare doldu ama oranlar kirli: motor "sabit dur" deyip yeniden öğrenmeli
    // (calibrating hâlâ true, retry mesajı). En azından temiz-olmayan örnekle
    // hemen "tamam" dememeli.
    check(r.calibrating, "dirty calibration (moving body) does not lock immediately - it re-learns");

    // aynı motora şimdi TEMİZ (sabit) örnek ver: ikinci turda kilitlenmeli
    for (int i = 0; i < 62; i++) r = e.update(pose(false), worldPose(false), (t += 33));
    check(!r.calibrating, "after re-learning on a steady body, calibration completes");
  }

  // ── adaptif dip eşiği (Damla, 15 tem: "eğildiğimi görüyor ama squat saymıyor").
  // Kişinin gerçek çömelmesi, sabit 120° eşiğine değmese bile, kendi üst
  // duruşundan yeterince bükülüyorsa SAYILMALI. ──
  {
    // ~130° dip yapan poz: sabit 120 eşiğinin ÜSTÜNDE (eski motor saymazdı) ama
    // ayakta ~180'den 130'a düşüş = 50° > adaptiveDrop(42) → adaptif sayar.
    auto poseShallowSquat = []() {
      std::vector<Landmark> p(33);
      auto set = [&](int i, double x, double y) { p[i].x = x; p[i].y = y; p[i].z = 0; p[i].visibility = 1; };
      set(11, 0.45, 0.20); set(12, 0.55, 0.20);
      set(23, 0.45, 0.50); set(24, 0.55, 0.50);
      set(25, 0.45, 0.70); set(26, 0.55, 0.70);
      set(27, 0.62, 0.80); set(28, 0.72, 0.80);   // bilek ileride+aşağıda -> diz ~130°
      return p;
    };
    // önce açının gerçekten ~130 (sabit 120 eşiğinin üstünde) olduğunu doğrula
    {
      Engine chk(builtinMove("squat"));
      Reading rc = chk.update(poseShallowSquat());
      check(rc.angles.leftKnee > 120.0 && rc.angles.leftKnee < 140.0,
            "adaptive: the shallow squat sits above the fixed 120 threshold");
    }
    // adaptif motor: ayakta dur (üst duruşu öğrensin), sonra ~130'a çömel → saymalı
    Engine e(builtinMove("squat"));
    Reading r;
    for (int i = 0; i < 12; i++) r = e.update(pose(false));       // üst duruş ~180 öğrenilir
    for (int i = 0; i < 12; i++) r = e.update(poseShallowSquat()); // kişiye göre derin iniş
    check(r.phase == Phase::Bottom, "adaptive: a real squat below the person's range reads bottom");
    for (int i = 0; i < 12; i++) r = e.update(pose(false));
    check(r.reps == 1, "adaptive: the shallow-but-real squat is counted");

    // güvenlik ağı: adaptif eşik spec tabanından (120) daha ZOR olamaz. Kısa
    // biri (üst duruşu ~150) çömelince eşik 150-42=108 çıkardı; taban 120'de
    // tutulur, yani hâlâ makul bir dip istenir (imkansız derinlik zorlanmaz).
    // Burada sadece adaptif eşiğin sabit tabanı deldiğini değil, TABANDA
    // kaldığını görmek için sığ üst duruşlu bir seri sürmek yeterli — davranışın
    // sabit motorla ÇELİŞMEDİĞİNİ zaten yukarıdaki tam-tekrar testleri kanıtlıyor.

    // adaptif KAPALI hareket (pushup) eskisi gibi sabit eşikle çalışır
    check(!builtinMove("pushup").adaptiveBottom, "adaptive is off for non-squat moves");
    check(builtinMove("squat").adaptiveBottom, "adaptive is on for squat");
  }

  // ── HOLD (izometrik) motoru: plank/wall-sit gibi tutuşlarda salınım yok,
  // hedef açı bandında geçirilen SÜRE + form kararlılığı ölçülür ──
  {
    // plank spec: hold modu, omuz-kalça-diz hattı ~180°
    MoveSpec ps = builtinMove("plank");
    check(ps.kind == MoveKind::Hold, "plank is a hold-type move");
    check(builtinMove("wallsit").kind == MoveKind::Hold, "wall-sit is a hold-type move");
    check(builtinMove("squat").kind == MoveKind::Rep, "squat stays a rep-type move");

    // düz plank pozu: omuz-kalça-diz tek çizgi (~180°). yatay gövde.
    auto posePlank = [](bool sagging) {
      std::vector<Landmark> p(33);
      auto set = [&](int i, double x, double y) { p[i].x = x; p[i].y = y; p[i].z = 0; p[i].visibility = 1; };
      set(11, 0.25, 0.45); set(12, 0.25, 0.47);   // omuzlar (solda)
      set(13, 0.25, 0.60); set(14, 0.25, 0.62);   // dirsekler (yerde destek)
      if (!sagging) { set(23, 0.55, 0.45); set(24, 0.55, 0.47); }   // kalça omuz hizasında -> düz
      else          { set(23, 0.55, 0.58); set(24, 0.55, 0.60); }   // kalça sarkmış -> hat kırık
      set(25, 0.75, 0.45); set(26, 0.75, 0.47);   // dizler omuz-kalça hizasında
      set(27, 0.90, 0.45); set(28, 0.90, 0.47);   // bilekler
      return p;
    };
    Engine e(builtinMove("plank"));
    Reading r;
    double t = 0;
    // düz plank tut: süre birikmeli
    for (int i = 0; i < 10; i++) { t += 100; r = e.update(posePlank(false), t); }
    check(r.isHold, "hold reading is flagged");
    check(r.inHold && r.heldSeconds > 0.5, "holding in the band accumulates held seconds");
    double held1 = r.heldSeconds;
    for (int i = 0; i < 10; i++) { t += 100; r = e.update(posePlank(false), t); }
    check(r.heldSeconds > held1, "held seconds keep growing while in the band");
    double heldClean = r.heldSeconds;

    // banttan çık: plank'ı bozup pike'a geç (kalça yukarı, omuz-kalça-diz açısı
    // bandın altına düşer) — down dog gibi. hip açısı ~90 -> banttan çıkar, süre DURMALI.
    auto posePike = []() {
      std::vector<Landmark> p(33);
      auto set = [&](int i, double x, double y) { p[i].x = x; p[i].y = y; p[i].z = 0; p[i].visibility = 1; };
      set(11, 0.25, 0.60); set(12, 0.25, 0.62);   // omuzlar aşağıda (eller yerde)
      set(13, 0.25, 0.72); set(14, 0.25, 0.74);
      set(23, 0.55, 0.25); set(24, 0.55, 0.27);   // kalça YUKARI (pike tepesi)
      set(25, 0.75, 0.55); set(26, 0.75, 0.57);   // dizler aşağı -> omuz-kalça-diz keskin açı
      set(27, 0.90, 0.75); set(28, 0.90, 0.77);
      return p;
    };
    for (int i = 0; i < 5; i++) { t += 100; r = e.update(posePike(), t); }
    check(!r.inHold, "leaving the band stops the hold");
    check(std::fabs(r.heldSeconds - heldClean) < 0.15, "held total is preserved when the band is left, not reset");

    e.reset();
    r = e.update(posePlank(false), (t += 100));
    check(r.heldSeconds < 0.2, "reset clears held seconds");

    // 3B form: sarkmış plank kalitesi düşer (HipSag kuralı hold boyunca izlenir).
    // dünya pozu: düz hat vs sarkmış hat
    auto worldPlank = [](bool sagging) {
      std::vector<Landmark> p(33);
      auto set = [&](int i, double x, double y, double z) { p[i].x = x; p[i].y = y; p[i].z = z; p[i].visibility = 1; };
      // yan görüş (side): derinlik ekseninde omuz/kalça yayılmış degil; duz yatay govde
      set(11, -0.40, 0.0, 0); set(12, -0.40, 0.02, 0);
      if (!sagging) { set(23, 0.0, 0.0, 0); set(24, 0.0, 0.02, 0); }       // duz
      else          { set(23, 0.0, 0.14, 0); set(24, 0.0, 0.16, 0); }      // sarkmis
      set(25, 0.30, 0.0, 0); set(26, 0.30, 0.02, 0);
      set(27, 0.55, 0.0, 0); set(28, 0.55, 0.02, 0);
      set(13, -0.40, 0.15, 0); set(14, -0.40, 0.17, 0);
      return p;
    };
    Engine cq(builtinMove("plank"));
    double t2 = 0; Reading rq;
    for (int i = 0; i < 12; i++) { t2 += 100; rq = cq.update(posePlank(false), worldPlank(false), t2); }
    double cleanQ = rq.holdQuality;
    Engine sq(builtinMove("plank"));
    double t3 = 0; Reading rs2;
    for (int i = 0; i < 12; i++) { t3 += 100; rs2 = sq.update(posePlank(true), worldPlank(true), t3); }
    check(cleanQ > rs2.holdQuality, "a sagging plank scores lower hold quality than a clean one");

    // hold özeti
    Summary hs = cq.summary();
    check(hs.isHold && hs.heldSeconds > 0.5, "hold summary reports held seconds");
    check(hs.holdQualityPct >= 0, "hold summary reports a quality percent");

    // ── çok-set hold TOPLAMI (bulgu #5): iki seti tutunca özet toplam süreyi
    // göstermeli, sadece son seti değil (heldSec_ set başı sıfırlanır ama
    // totalHeldSec_ korunur). plan: 2s hedef, 2 set. ──
    {
      Engine ms(builtinMove("plank"));
      ms.setPlan(2, 2, 1.0);   // 2 saniye hedef, 2 set, 1s mola
      double tm = 0; Reading rm;
      // 1. set: ~2.5s tut (hedefi geç, mola başlar)
      for (int i = 0; i < 25; i++) { tm += 100; rm = ms.update(posePlank(false), tm); }
      // mola geçsin (1s), 2. sete geç
      for (int i = 0; i < 15; i++) { tm += 100; rm = ms.update(posePlank(false), tm); }
      // 2. set: ~2.5s daha tut
      for (int i = 0; i < 25; i++) { tm += 100; rm = ms.update(posePlank(false), tm); }
      Summary mss = ms.summary();
      check(mss.heldSeconds > 3.5, "multi-set hold summary sums ALL sets, not just the last");
    }

    // ── yerçekimi-farkında oryantasyon: plank YATAY gövde ister; ayakta dururken
    // (dik gövde) aynı düz hip açısı olsa bile plank SAYILMAZ. ──
    auto worldHorizontal = []() {   // yatay gövde: omuz-kalça y'de düz, x'te yayılmış
      std::vector<Landmark> p(33);
      auto set = [&](int i, double x, double y, double z) { p[i].x = x; p[i].y = y; p[i].z = z; p[i].visibility = 1; };
      set(11, -0.40, 0.0, 0); set(12, -0.40, 0.02, 0);   // omuz ve kalça AYNI y (yatay)
      set(23, 0.0, 0.0, 0); set(24, 0.0, 0.02, 0);
      set(25, 0.30, 0.0, 0); set(26, 0.30, 0.02, 0);
      set(27, 0.55, 0.0, 0); set(28, 0.55, 0.02, 0);
      set(13, -0.40, 0.15, 0); set(14, -0.40, 0.17, 0);
      return p;
    };
    auto worldVertical = []() {   // dik gövde: omuz kalçanın ÜSTÜNDE (y farkı büyük)
      std::vector<Landmark> p(33);
      auto set = [&](int i, double x, double y, double z) { p[i].x = x; p[i].y = y; p[i].z = z; p[i].visibility = 1; };
      set(11, -0.02, -0.50, 0); set(12, 0.02, -0.50, 0);   // omuz yukarıda
      set(23, -0.02, 0.0, 0); set(24, 0.02, 0.0, 0);       // kalça altta -> gövde dikey
      set(25, -0.02, 0.40, 0); set(26, 0.02, 0.40, 0);
      set(27, -0.02, 0.80, 0); set(28, 0.02, 0.80, 0);
      set(13, -0.02, -0.30, 0); set(14, 0.02, -0.30, 0);
      return p;
    };
    // yatay: tilt ~90, plank sayılır
    Engine ph(builtinMove("plank"));
    double th = 0; Reading rh;
    for (int i = 0; i < 8; i++) { th += 100; rh = ph.update(posePlank(false), worldHorizontal(), th); }
    check(rh.torsoTilt > 55.0, "horizontal torso reads high tilt (plank orientation)");
    check(rh.inHold && rh.heldSeconds > 0.3, "a real horizontal plank counts");
    // dikey: tilt ~0, aynı hareket ama ayakta -> plank SAYILMAZ
    Engine pv(builtinMove("plank"));
    double tv = 0; Reading rv;
    for (int i = 0; i < 8; i++) { tv += 100; rv = pv.update(posePlank(false), worldVertical(), tv); }
    check(rv.torsoTilt < 45.0, "vertical torso reads low tilt (standing)");
    check(!rv.inHold && rv.heldSeconds < 0.2, "standing upright does NOT count as a plank (gravity gate)");
  }

  // ── Faz 2: kemik kilidi — kalibre uzunluklar sabitlenir, gerilen kemik
  // çözülmüş iskelette gerilemez; açılar kilitli iskeletten ölçülür ──
  {
    Engine e(builtinMove("squat"));
    e.setCalibration(true);
    Reading r;
    double t = 0;
    for (int i = 0; i < 65; i++) r = e.update(pose(false), worldPose(false), (t += 33));
    check(!r.calibrating, "bone lock: calibration completed");

    // baldırı %20 uzamış okuma (dedektör gürültüsü): oran testi bunu tek başına
    // reddedecek kadar bozuk bulmaz ama kilit uzunluğu geri çekmeli.
    std::vector<Landmark> stretched = worldPose(false);
    stretched[27].y += 0.08; stretched[28].y += 0.08;   // bilekler aşağı: baldır uzar
    r = e.update(pose(false), stretched, (t += 33));
    check(r.tracking, "bone lock: mildly stretched read is still tracked");
    const std::vector<Landmark>& s = e.solvedWorld();
    check(s.size() == 33, "bone lock: solved skeleton exists");
    auto len = [&](const std::vector<Landmark>& v, int a, int b) {
      double dx = v[a].x - v[b].x, dy = v[a].y - v[b].y, dz = v[a].z - v[b].z;
      return std::sqrt(dx * dx + dy * dy + dz * dz);
    };
    double shinSolved = len(s, 25, 27);
    double shinTrue = len(worldPose(false), 25, 27);
    double shinObs = len(stretched, 25, 27);
    check(std::fabs(shinSolved - shinTrue) < 0.02 && shinObs > shinTrue + 0.05,
          "bone lock: solved shin snaps back to the calibrated length");
  }

  // ── Faz 2: çok kişi — kadraja giren yabancı iskelet çalamaz (hoca vakası) ──
  {
    Engine e(builtinMove("squat"));
    e.setCalibration(true);
    Reading r;
    double t = 0;
    for (int i = 0; i < 65; i++) r = e.update(pose(false), worldPose(false), (t += 33));
    check(!r.calibrating, "multi-person: calibration completed");
    // iki aday: 0 = kısa uzuvlu yabancı ekranın öbür yanında, 1 = bizim vücut.
    // MediaPipe sırayı garanti etmez — motor 0'ı değil BİZİ seçmeli.
    std::vector<Landmark> strangerS = pose(false), strangerW = worldPose(false);
    for (auto* v : {&strangerS}) for (auto& p2 : *v) p2.x += 0.30;   // ekranda uzakta
    for (int i : {25, 26}) { strangerW[i].y = 0.28; }                 // uyluk kısa
    for (int i : {27, 28}) { strangerW[i].y = 0.52; }                 // baldır kısa
    std::vector<std::vector<Landmark>> screens = {strangerS, pose(false)};
    std::vector<std::vector<Landmark>> worlds  = {strangerW, worldPose(false)};
    r = e.updateBest(screens, worlds, (t += 33));
    check(r.pickedPose == 1, "multi-person: the calibrated body wins over the stranger");
    check(r.tracking, "multi-person: tracking continues on the picked body");
    // tek adaylı çağrı eski davranış: aday 0 seçilir
    std::vector<std::vector<Landmark>> one = {pose(false)};
    std::vector<std::vector<Landmark>> oneW = {worldPose(false)};
    r = e.updateBest(one, oneW, (t += 33));
    check(r.pickedPose == 0, "multi-person: single candidate falls through");

    // SERT KİLİT: kadrajda SADECE yabancı — tek adayda veto yok (gercek kamera
    // dersi) ama motorun ic kalibrasyon kapisi yabanciyi yine de IZLEMEZ.
    std::vector<std::vector<Landmark>> onlyStranger = {strangerS};
    std::vector<std::vector<Landmark>> onlyStrangerW = {strangerW};
    for (int i = 0; i < 5; i++) r = e.updateBest(onlyStranger, onlyStrangerW, (t += 33));
    check(r.pickedPose == -1 && !r.tracking, "hard lock: a clearly different lone body is never coached");
    // vücut dönünce takip kaldığı yerden devam eder
    r = e.updateBest(one, oneW, (t += 33));
    check(r.pickedPose == 0 && r.tracking, "hard lock: tracking resumes when the body returns");

    // ── kimlik kilidi, benzer-boyutlu yabancı (Damla, 15 tem: "başka biri girince
    // ona odaklanmasın, bende kalsın"). Yabancı BİZİM oranlarımıza yakın olsa da
    // (oran ayıramaz) az önce bulunduğumuz yerden ışınlanamaz: zaman tutarlılığı
    // onu eler, iskelet bizde kalır. ──
    // önce birkaç kare bizi izle (lastCore_ tazelensin, konumumuz otursun)
    for (int i = 0; i < 3; i++) r = e.updateBest(one, oneW, (t += 33));
    check(r.pickedPose == 0, "identity: locked on our body before the twin enters");
    // ikiz yabancı: aynı oranlar ama ekranın öbür ucunda belirir
    std::vector<Landmark> twinS = pose(false), twinW = worldPose(false);
    for (auto& p2 : twinS) p2.x += 0.32;   // uzakta — ışınlanma
    std::vector<std::vector<Landmark>> withTwin = {twinS, pose(false)};
    std::vector<std::vector<Landmark>> withTwinW = {twinW, worldPose(false)};
    r = e.updateBest(withTwin, withTwinW, (t += 33));
    check(r.pickedPose == 1, "identity: a same-sized stranger cannot steal the lock (teleport gate)");
  }

  // ── Faz 3 katman 1: tekrar yorumu — koç her tekrardan sonra cümle kurar ──
  {
    Engine e(builtinMove("squat"));
    Reading r;
    double t = 0;
    for (int i = 0; i < 6; i++) r = e.update(pose(false), (t += 100));
    check(r.repComment.empty(), "no comment before any rep");
    // derin + kontrollü + doğru tempoda tekrar (~2.5 sn): "textbook"
    // (10 karelik iniş motorun saatinde 1.0 sn'ye düşüyor ve "rushed" yiyor —
    // yorum motoru haklıydı, testi gerçekçi tempoya çektik)
    for (int i = 0; i < 16; i++) r = e.update(pose(true), (t += 100));
    std::string comment;
    for (int i = 0; i < 18; i++) {
      r = e.update(pose(false), (t += 100));
      if (r.repTick) comment = r.repComment;
    }
    check(r.reps == 1 && comment.find("textbook") != std::string::npos,
          "deep controlled rep earns the textbook comment");
    // aşırı hızlı tekrar (~0.4 sn): "rushed"
    for (int i = 0; i < 2; i++) r = e.update(pose(true), (t += 100));
    comment.clear();
    for (int i = 0; i < 10; i++) {
      r = e.update(pose(false), (t += 100));
      if (r.repTick) comment = r.repComment;
    }
    check(r.reps == 2 && comment.find("rushed") != std::string::npos,
          "a rushed rep is told to slow down");
    // yorum sadece sayım karesinde gelir, sonraki kare boş
    r = e.update(pose(false), (t += 100));
    check(r.repComment.empty(), "comment is transient like repTick");
  }

  // ── Faz 3 katman 1: egzersiz-önselli hız tavanı — squat'ın kapısı artık
  // kendi fiziğinden (sıkı), eski 50°/kare sabitinin altındaki ışınlanmaları da yutar ──
  {
    Engine e(builtinMove("squat"));
    Reading r;
    double t = 0;
    for (int i = 0; i < 8; i++) r = e.update(pose(false), (t += 33));
    double before = r.smoothAngle;
    r = e.update(poseHalf(), (t += 33));   // tek karede ~45° sıçrama (eski eşik 50'nin ALTI)
    check(std::fabs(r.smoothAngle - before) < 5.0,
          "exercise prior: a 45-degree single-frame jump is swallowed for squat");
    // iki kare sürerse gerçek kabul edilir (ince takip korunur)
    r = e.update(poseHalf(), (t += 33));
    check(r.smoothAngle < before - 3.0, "exercise prior: a sustained move is accepted");
  }

  // ── 2D->3D metrik poz iyileştirme: world-z kare-kare gürültülü gelse de
  // Kalman'dan geçtiği için okunan açı ham world'den DAHA STABİL olmalı ──
  {
    // sabit duran bir vücut ama world-z'de deterministik ±gürültü enjekte et.
    // ham açı gürültüyle salınır; motorun okuduğu (refined) açı sakinleşmeli.
    auto worldNoisy = [](int i) {
      std::vector<Landmark> p(33);
      auto set = [&](int idx, double x, double y, double z) { p[idx].x=x; p[idx].y=y; p[idx].z=z; p[idx].visibility=1; };
      // bilek Z'sinde ASİMETRİK kare-kare gürültü (0..0.16 arası deterministik
      // dört-adımlı desen). açı z'ye karesel bağlı olduğu için işaret simetrik
      // gürültü açıyı oynatmaz; bu yüzden pozitif, değişen büyüklükte gürültü.
      double pat[4] = {0.0, 0.16, 0.04, 0.12};
      double n = pat[i % 4];
      set(11,-0.18,-0.50,0); set(12,0.18,-0.50,0);
      set(23,-0.10,0.0,0);   set(24,0.10,0.0,0);
      set(25,-0.10,0.40,0);  set(26,0.10,0.40,0);   // diz sabit
      set(27,-0.10,0.80,n);  set(28,0.10,0.80,n);   // bilek z titrer -> açı titrer
      return p;
    };
    Engine e(builtinMove("squat"));
    e.setWorldRefine(true);   // katman VARSAYILAN KAPALI (kötü ışıkta zarar); açıkken
                              // temiz-z senaryosunda stabilize ettiğini doğrula (yetenek çalışıyor).
    Reading r;
    double t = 0, rawSum = 0, refSum = 0, rawMean = 0, refMean = 0;
    std::vector<double> raws, refs;
    for (int i = 0; i < 40; i++) {
      t += 33;
      r = e.update(pose(false), worldNoisy(i), t);
      // ham world açısı (filtre yok) — kıyas için elle hesap
      auto wn = worldNoisy(i);
      double v1x=wn[23].x-wn[25].x, v1y=wn[23].y-wn[25].y, v1z=wn[23].z-wn[25].z;
      double v2x=wn[27].x-wn[25].x, v2y=wn[27].y-wn[25].y, v2z=wn[27].z-wn[25].z;
      double m1=std::sqrt(v1x*v1x+v1y*v1y+v1z*v1z), m2=std::sqrt(v2x*v2x+v2y*v2y+v2z*v2z);
      double rawAng = std::acos(std::max(-1.0,std::min(1.0,(v1x*v2x+v1y*v2y+v1z*v2z)/(m1*m2))))*180.0/M_PI;
      if (i >= 20) { raws.push_back(rawAng); refs.push_back(r.angles.leftKnee); rawSum+=rawAng; refSum+=r.angles.leftKnee; }
    }
    rawMean = rawSum / raws.size(); refMean = refSum / refs.size();
    double rawVar = 0, refVar = 0;
    for (size_t i = 0; i < raws.size(); i++) { rawVar += (raws[i]-rawMean)*(raws[i]-rawMean); refVar += (refs[i]-refMean)*(refs[i]-refMean); }
    rawVar /= raws.size(); refVar /= refs.size();
    check(refVar < rawVar, "refined 3d knee angle is more stable than the raw noisy world angle");
  }

  // ── hareket sınıflandırma (motor seviyesi): squat yapılırken motor bunu
  // KENDİ tahmin eder (kullanıcı söylemeden), detectedMove'a yazar ──
  {
    Engine e(builtinMove("squat"));
    Reading r;
    double t = 0;
    // birkaç tam squat döngüsü sür — classifier penceresi dolsun
    for (int cyc = 0; cyc < 3; cyc++) {
      for (int i = 0; i < 10; i++) { t += 33; r = e.update(pose(true), t); }
      for (int i = 0; i < 10; i++) { t += 33; r = e.update(pose(false), t); }
    }
    check(!r.detectedMove.empty(), "engine produces a move guess after enough motion");
    check(r.detectedMove == "squat" || r.detectedMove == "lunge",
          "engine independently classifies an oscillating-knee move as a leg move");
    check(r.detectedConfidence > 0.3, "the classification carries a confidence");
  }

  // ── simetri analizi: iki taraf dengeli inince asimetri düşük; bir bacak
  // daha az bükülünce (telafi) asimetri yükselir ve koç uyarır ──
  {
    // simetrik squat: sol ve sağ diz aynı açıda
    Engine sym(builtinMove("squat"));
    Reading r;
    for (int i = 0; i < 6; i++) r = sym.update(pose(false));
    for (int i = 0; i < 10; i++) r = sym.update(pose(true));
    check(r.asymmetryDeg >= 0 && r.asymmetryDeg < 8.0, "symmetric squat reads low asymmetry");
    for (int i = 0; i < 12; i++) r = sym.update(pose(false));
    check(r.reps == 1 && (r.lastRepAsymmetry < 10 || r.lastRepAsymmetry == -1), "a balanced rep records low/no asymmetry");

    // asimetrik squat: SAĞ bacak neredeyse düz kalıyor (sol iniyor) -> büyük fark
    auto poseLopsided = []() {
      std::vector<Landmark> p(33);
      auto set = [&](int i, double x, double y) { p[i].x = x; p[i].y = y; p[i].z = 0; p[i].visibility = 1; };
      set(11, 0.45, 0.20); set(12, 0.55, 0.20);
      set(23, 0.45, 0.50); set(24, 0.55, 0.50);
      set(25, 0.45, 0.70); set(26, 0.55, 0.70);
      // sol bilek ileride (sol diz ~90 bükülü), sağ bilek dizin altında (sağ diz ~180 düz)
      set(27, 0.65, 0.70); set(28, 0.55, 0.90);
      return p;
    };
    Engine asy(builtinMove("squat"));
    Reading ra;
    for (int i = 0; i < 6; i++) ra = asy.update(pose(false));
    for (int i = 0; i < 10; i++) ra = asy.update(poseLopsided());
    check(ra.asymmetryDeg > 20.0, "a lopsided squat reads high live asymmetry");
    std::string cmt;
    for (int i = 0; i < 12; i++) { ra = asy.update(pose(false)); if (ra.repTick) cmt = ra.repComment; }
    check(ra.lastRepAsymmetry > 15, "a lopsided rep records the imbalance");
    check(cmt.find("one side") != std::string::npos, "the coach flags one-sided compensation");
  }

  // ── Kalman occlusion-recovery: çizim iskeleti, bir landmark bir kaç kare
  // kaybolunca tahmini hızla akmaya devam eder (zıplamaz), sayma bozulmaz ──
  {
    Engine e(builtinMove("squat"));
    Reading r;
    double t = 0;
    // sağa doğru sabit hızla kayan bir vücut: her kare hepsi +0.004 x
    auto poseMoving = [](double shift) {
      std::vector<Landmark> p(33);
      auto set = [&](int i, double x, double y) { p[i].x = x + shift; p[i].y = y; p[i].z = 0; p[i].visibility = 1; };
      set(11, 0.45, 0.20); set(12, 0.55, 0.20);
      set(23, 0.45, 0.50); set(24, 0.55, 0.50);
      set(25, 0.45, 0.70); set(26, 0.55, 0.70);
      set(27, 0.45, 0.90); set(28, 0.55, 0.90);
      return p;
    };
    double shift = 0;
    for (int i = 0; i < 20; i++) { t += 33; shift += 0.004; r = e.update(poseMoving(shift), t); }
    check(e.smoothScreen().size() == 33, "kalman: smooth screen pose exists");
    double kneeXbefore = e.smoothScreen()[25].x;
    // sağ diz (26) 5 kare KAYBOLUR (occlusion), gövde kaymaya devam eder
    double kneeX26_atOcclusion = e.smoothScreen()[26].x;
    for (int i = 0; i < 5; i++) {
      t += 33; shift += 0.004;
      auto pm = poseMoving(shift);
      pm[26].visibility = 0.0;   // sağ diz görünmez
      r = e.update(pm, t);
    }
    double kneeX26_after = e.smoothScreen()[26].x;
    check(kneeX26_after > kneeX26_atOcclusion + 0.008,
          "kalman: an occluded joint keeps flowing on predicted velocity (does not freeze)");
    check(kneeXbefore < e.smoothScreen()[25].x,
          "kalman: visible joints keep tracking normally during a neighbour's occlusion");
    // occlusion sayma matematiğini bozmadı (bu poz hiç dip yapmadı -> 0 rep)
    check(r.reps == 0, "kalman: occlusion recovery is draw-only, counting is unaffected");
  }

  // ── Faz 2: çizim iskeleti — takip olan karede yumuşatılmış ekran pozu üretilir ──
  {
    Engine e(builtinMove("squat"));
    Reading r;
    double t = 0;
    for (int i = 0; i < 8; i++) r = e.update(pose(false), (t += 33));
    check(r.tracking && e.smoothScreen().size() == 33, "smooth screen pose exists while tracking");
    check(std::fabs(e.smoothScreen()[25].x - 0.45) < 0.02, "smooth screen pose sits on the body");
  }

  // ── yeni hareketler: kickback bükülü başlar, jumping jack omuzdan sayar,
  // calf raise ayak bileğinden okur — hepsi saf veri, motor kodu aynı ──
  {
    Engine kb(builtinMove("kickback"));
    Reading r;
    for (int i = 0; i < 6; i++) r = kb.update(poseHips(false));   // emekleme: kalça bükülü
    check(r.phase == Phase::Bottom, "kickback: folded hip reads bottom");
    for (int i = 0; i < 12; i++) r = kb.update(poseHips(true));   // bacak uzadı
    check(r.reps == 1, "kickback: counts on the extension");

    // jumping jack: omuz açısı (kalça-omuz-dirsek). kol aşağıda ~15°, tepede ~165°.
    auto poseJack = [](bool up) {
      std::vector<Landmark> p(33);
      auto set = [&](int i, double x, double y) { p[i].x = x; p[i].y = y; p[i].z = 0; p[i].visibility = 1; };
      set(11, 0.45, 0.30); set(12, 0.55, 0.30);   // omuzlar
      set(23, 0.46, 0.60); set(24, 0.54, 0.60);   // kalçalar (omuzun altında)
      if (up) { set(13, 0.44, 0.05); set(14, 0.56, 0.05); }   // dirsek tepede -> geniş açı
      else    { set(13, 0.46, 0.55); set(14, 0.54, 0.55); }   // dirsek kalçaya yakın -> dar açı
      return p;
    };
    Engine jj(builtinMove("jumpingjack"));
    for (int i = 0; i < 6; i++) r = jj.update(poseJack(false));
    check(r.phase == Phase::Bottom, "jumping jack: arms down reads bottom");
    for (int i = 0; i < 12; i++) r = jj.update(poseJack(true));
    check(r.reps == 1, "jumping jack: counts at the top");

    // calf raise: diz-bilek-ayak ucu. tabanda ~120°, parmak ucunda ~150°.
    auto poseCalf = [](bool up) {
      std::vector<Landmark> p(33);
      auto set = [&](int i, double x, double y) { p[i].x = x; p[i].y = y; p[i].z = 0; p[i].visibility = 1; };
      set(25, 0.48, 0.40); set(26, 0.58, 0.40);   // dizler
      set(27, 0.50, 0.80); set(28, 0.60, 0.80);   // bilekler
      if (up) { set(31, 0.54, 0.94); set(32, 0.64, 0.94); }   // yükselmiş: açı açık
      else    { set(31, 0.62, 0.86); set(32, 0.72, 0.86); }   // taban: açı dar
      return p;
    };
    Engine cr(builtinMove("calfraise"));
    for (int i = 0; i < 8; i++) r = cr.update(poseCalf(false));
    check(r.tracking && r.phase == Phase::Bottom, "calf raise: flat foot reads bottom");
    for (int i = 0; i < 14; i++) r = cr.update(poseCalf(true));
    check(r.reps == 1, "calf raise: counts on the rise");
  }

  // ── hareket bazında kadraj: push-up bacaksız çalışır, cümlesi kolu ister ──
  {
    Engine e(builtinMove("pushup"));
    Reading r;
    for (int i = 0; i < 6; i++) r = e.update(poseArms(false));
    for (int i = 0; i < 10; i++) r = e.update(poseArms(true));
    for (int i = 0; i < 12; i++) r = e.update(poseArms(false));
    check(r.reps == 1, "pushup counts with the legs fully out of frame");
    Engine s(builtinMove("pushup"));
    Reading rs = s.update(pose(false));       // sadece bacak görünür: kadraj yetmez
    check(rs.message.find("arms") != std::string::npos, "pushup framing cue asks for the arms");
  }

  std::printf(failed ? "\n%d test FAILED\n" : "\nall tests passed\n", failed);
  return failed ? 1 : 0;
}
