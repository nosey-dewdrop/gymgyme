// bench.cpp — coach motorunun ÖLÇÜM BANDI (hassas motor planı, Faz 0).
//
// İki mod:
//   bench synth            — sentetik squat akışı: gerçek açı BİLİNİR, üstüne
//                            dedektör gürültüsü + ışınlanma kareleri eklenir.
//                            ham / EMA / One Euro yan yana puanlanır.
//   bench clip <dosya>     — coach sayfasının kaydedicisinden (?rec=1) inen
//                            .ggclip dosyasını motordan geçirir, metrik basar.
//
// Metrikler:
//   jitter   — duruş sırasında açının gerçek etrafındaki std'si (derece).
//   rmse     — hareket boyunca gerçek açıya uzaklık (hizalama sonrası, derece).
//   lag      — filtrenin sinyali kaç ms geriden izlediği (en iyi hizalama kayması).
//   reps     — sayılan tekrar / gerçek tekrar.
//   bone var — kare kare kemik uzunluğu oynaması (%, dünya verisinden) — "eklem
//              kayması"nın sayısı. (clip modunda; sentetikte iskelet zaten katı.)
//
// Koşmak: engine/bench.sh

#include "coach_engine.hpp"
#include <cmath>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <random>
#include <sstream>
#include <string>
#include <vector>

using namespace coach;

// ── sentetik squat dünyası ───────────────────────────────────────────────────
// tek serbestlik: diz açısı θ. bacak geometrisi θ'dan kurulur, yani "gerçek"
// iskelet katı — gördüğümüz her oynama bizim eklediğimiz gürültüdür.

struct Frame {
  double t;                       // ms
  std::vector<Landmark> screen;   // 33 nokta, normalize
  std::vector<Landmark> world;    // 33 nokta, metrik
  double gtAngle;                 // gerçek diz açısı (derece)
  bool hold;                      // bu karede duruş mu (jitter penceresi)
};

// θ diz açısından basit ama tutarlı bir vücut kur: kalça sabit, uyluk aşağı,
// baldır uyluğa θ ile bağlı. omuz/dirsek/bilek sabit gövde.
static void bodyFromTheta(double thetaDeg, std::vector<Landmark>& s, std::vector<Landmark>& w) {
  s.assign(33, {});
  w.assign(33, {});
  auto set = [](std::vector<Landmark>& p, int i, double x, double y, double z) {
    p[i].x = x; p[i].y = y; p[i].z = z; p[i].visibility = 1.0;
  };
  const double thigh = 0.24, shin = 0.24;           // normalize uzunluklar
  const double th = (180.0 - thetaDeg) * M_PI / 180.0;   // 180° = düz bacak
  // sol/sağ simetrik; x'te ±0.05 ayrık.
  for (int side = 0; side < 2; side++) {
    double bx = 0.5 + (side == 0 ? -0.05 : 0.05);
    int SHO = side == 0 ? 11 : 12, HIP = side == 0 ? 23 : 24,
        KNE = side == 0 ? 25 : 26, ANK = side == 0 ? 27 : 28,
        ELB = side == 0 ? 13 : 14, WRI = side == 0 ? 15 : 16,
        FT  = side == 0 ? 31 : 32;
    double hipY = 0.45, kneX = bx, kneY = hipY + thigh;
    // baldır uyluktan th kadar kırılır (ekran düzleminde ileri)
    double ankX = kneX + shin * std::sin(th), ankY = kneY + shin * std::cos(th);
    set(s, SHO, bx, 0.18, 0);          set(s, HIP, bx, hipY, 0);
    set(s, KNE, kneX, kneY, 0);        set(s, ANK, ankX, ankY, 0);
    set(s, ELB, bx + 0.07, 0.30, 0);   set(s, WRI, bx + 0.09, 0.42, 0);
    set(s, FT,  ankX + 0.04, ankY + 0.02, 0);
    // dünya: aynı geometri, metrik ölçek (gövde ~0.5 m), kamera önden.
    double sc = 1.8;
    set(w, SHO, (bx - 0.5) * sc, -0.55, 0);       set(w, HIP, (bx - 0.5) * sc, 0.0, 0);
    set(w, KNE, (kneX - 0.5) * sc, thigh * sc, 0);
    set(w, ANK, (ankX - 0.5) * sc, (ankY - 0.45) * sc, 0);
    set(w, ELB, (bx - 0.5) * sc + 0.12, -0.35, 0); set(w, WRI, (bx - 0.5) * sc + 0.16, -0.12, 0);
    set(w, FT,  (ankX - 0.5) * sc + 0.07, (ankY - 0.45) * sc + 0.04, 0);
  }
}

// akış: 4 sn duruş (170°) → 8 tekrar (3 sn/tekrar, 170↔95 kosinüs) → 4 sn duruş.
static std::vector<Frame> makeSynth(double noiseSigma, double spikeProb, unsigned seed) {
  const double fps = 30.0, repSec = 3.0;
  const int reps = 8;
  const double hold1 = 4.0, moveSec = reps * repSec, hold2 = 4.0;
  const int total = (int)((hold1 + moveSec + hold2) * fps);
  std::mt19937 rng(seed);
  std::normal_distribution<double> noise(0.0, noiseSigma);
  std::uniform_real_distribution<double> uni(0.0, 1.0);
  std::vector<Frame> out;
  out.reserve(total);
  for (int i = 0; i < total; i++) {
    double tSec = i / fps;
    double theta;
    bool hold;
    if (tSec < hold1 || tSec >= hold1 + moveSec) { theta = 170.0; hold = true; }
    else {
      double ph = (tSec - hold1) / repSec * 2.0 * M_PI;   // tekrar başına tam tur
      theta = 132.5 + 37.5 * std::cos(ph);                // 170 ↔ 95
      hold = false;
    }
    Frame f;
    f.t = tSec * 1000.0;
    f.gtAngle = theta;
    f.hold = hold;
    bodyFromTheta(theta, f.screen, f.world);
    // dedektör gürültüsü: her noktaya bağımsız gauss; ışınlanma: %spikeProb kare,
    // bir bacak noktası 0.06 birim kaçar (gerçekte iskeletin eşyaya atlaması).
    for (auto* pv : {&f.screen, &f.world}) {
      double s = (pv == &f.world) ? 1.8 : 1.0;   // dünya metrik: gürültü de ölçekli
      for (auto& p : *pv) {
        if (p.visibility <= 0) continue;
        p.x += noise(rng) * s; p.y += noise(rng) * s; p.z += noise(rng) * s;
      }
    }
    if (uni(rng) < spikeProb) {
      int idx = (uni(rng) < 0.5) ? 27 : 25;   // bilek ya da diz kaçar
      f.screen[idx].x += 0.06; f.screen[idx].y -= 0.06;
      f.world[idx].x += 0.11;  f.world[idx].y -= 0.11;
    }
    out.push_back(std::move(f));
  }
  return out;
}

// ── metrik hesabı ────────────────────────────────────────────────────────────

struct RunResult {
  std::vector<double> angle;   // motorun (ya da hamın) açı izi; -1 = okuma yok
  int reps = 0, halfReps = 0, dropouts = 0;
};

static RunResult runEngine(const std::vector<Frame>& clip, bool oneEuro, bool useRaw,
                           double minCutoff = -1, double beta = -1) {
  MoveSpec spec = builtinMove("squat");
  spec.useOneEuro = oneEuro;
  if (minCutoff > 0) spec.euroMinCutoff = minCutoff;
  if (beta >= 0) spec.euroBeta = beta;
  Engine e(spec);
  RunResult r;
  bool wasTracking = false;
  for (const auto& f : clip) {
    Reading rd = e.update(f.screen, f.world, f.t);
    r.angle.push_back(rd.tracking ? (useRaw ? rd.rawAngle : rd.smoothAngle) : -1.0);
    if (wasTracking && !rd.tracking) r.dropouts++;
    wasTracking = rd.tracking;
    r.reps = rd.reps;
    r.halfReps = rd.halfReps;
  }
  return r;
}

static double holdJitter(const std::vector<Frame>& clip, const std::vector<double>& a) {
  // duruş karelerinde gerçek açı etrafındaki std. ilk 1 sn ısınma dışı.
  double sum = 0, sum2 = 0; int n = 0;
  for (size_t i = 30; i < clip.size(); i++) {
    if (!clip[i].hold || a[i] < 0) continue;
    double d = a[i] - clip[i].gtAngle;
    sum += d; sum2 += d * d; n++;
  }
  if (n < 2) return -1;
  double mean = sum / n;
  return std::sqrt(std::max(0.0, sum2 / n - mean * mean));
}

// gecikme: iziyi gerçek açıya 0..12 kare kaydırarak en küçük RMSE'yi ara.
// dönen: {en iyi kaymanın ms karşılığı, o hizadaki RMSE}.
static void lagAndRmse(const std::vector<Frame>& clip, const std::vector<double>& a,
                       double& lagMs, double& rmse) {
  int bestShift = 0; double bestErr = 1e18;
  for (int shift = 0; shift <= 12; shift++) {
    double s2 = 0; int n = 0;
    for (size_t i = 30 + shift; i < clip.size(); i++) {
      if (clip[i].hold || a[i] < 0) continue;   // sadece hareket kareleri
      double d = a[i] - clip[i - shift].gtAngle;
      s2 += d * d; n++;
    }
    if (n < 10) continue;
    double err = std::sqrt(s2 / n);
    if (err < bestErr) { bestErr = err; bestShift = shift; }
  }
  lagMs = bestShift * 1000.0 / 30.0;
  rmse = bestErr >= 1e17 ? -1 : bestErr;
}

static void printRow(const char* name, const std::vector<Frame>& clip, const RunResult& r) {
  double lag, rmse;
  lagAndRmse(clip, r.angle, lag, rmse);
  std::printf("  %-9s jitter %6.3f deg   rmse %6.3f deg   lag %5.1f ms   reps %d/8   half %d   dropouts %d\n",
              name, holdJitter(clip, r.angle), rmse, lag, r.reps, r.halfReps, r.dropouts);
}

static int runSynth() {
  std::printf("olcum bandi - sentetik squat (gercek aci bilinir)\n");
  struct Case { const char* label; double sigma; double spike; };
  const Case cases[] = {
    {"temiz kamera (sigma 0.002, %0.5 isinlanma)", 0.002, 0.005},
    {"normal kamera (sigma 0.004, %1 isinlanma)", 0.004, 0.010},
    {"kotu isik    (sigma 0.008, %3 isinlanma)", 0.008, 0.030},
  };
  for (const auto& c : cases) {
    std::printf("\n%s\n", c.label);
    auto clip = makeSynth(c.sigma, c.spike, 42);
    printRow("ham", clip, runEngine(clip, false, true));
    printRow("ema", clip, runEngine(clip, false, false));
    printRow("one euro", clip, runEngine(clip, true, false));
  }
  std::printf("\nnot: jitter = durusta gercek etrafinda std. rmse = harekette gercege uzaklik\n"
              "(hizalama sonrasi). lag = en iyi hizalama kaymasi. hepsi ayni tohum, ayni gurultu.\n");
  return 0;
}

// ── clip modu: coach sayfasının kaydedicisinden inen .ggclip dosyası ─────────
// format: satır 1  "ggclip 1 <hareket>"
//         sonra her kare bir satır: t  ekran 33x(x y z v)  dünya 33x(x y z v)
//         dünya yoksa ekran bloğundan sonra tek "-".

static int runClip(const char* path) {
  std::ifstream in(path);
  if (!in) { std::fprintf(stderr, "acamadim: %s\n", path); return 1; }
  std::string header;
  std::getline(in, header);
  std::istringstream hs(header);
  std::string magic, moveName;
  int ver = 0;
  hs >> magic >> ver >> moveName;
  if (magic != "ggclip") { std::fprintf(stderr, "bu bir ggclip dosyasi degil\n"); return 1; }
  if (moveName.empty()) moveName = "squat";

  std::vector<Frame> clip;
  std::string line;
  while (std::getline(in, line)) {
    if (line.empty()) continue;
    std::istringstream ls(line);
    Frame f;
    ls >> f.t;
    f.screen.assign(33, {});
    for (auto& p : f.screen) ls >> p.x >> p.y >> p.z >> p.visibility;
    // dünya bloğu: ya "-" ya 132 sayı
    std::string peek;
    if (ls >> peek && peek != "-") {
      f.world.assign(33, {});
      f.world[0].x = std::stod(peek);
      ls >> f.world[0].y >> f.world[0].z >> f.world[0].visibility;
      for (int i = 1; i < 33; i++) ls >> f.world[i].x >> f.world[i].y >> f.world[i].z >> f.world[i].visibility;
    }
    f.gtAngle = -1; f.hold = false;
    clip.push_back(std::move(f));
  }
  if (clip.size() < 30) { std::fprintf(stderr, "klip cok kisa (%zu kare)\n", clip.size()); return 1; }

  // motoru koş (hareketin kendi spec'i, One Euro açık ve kapalı)
  auto run = [&](bool euro) {
    MoveSpec spec = builtinMove(moveName);
    spec.useOneEuro = euro;
    Engine e(spec);
    RunResult r;
    bool was = false;
    for (const auto& f : clip) {
      Reading rd = f.world.size() == 33 ? e.update(f.screen, f.world, f.t)
                                        : e.update(f.screen, f.t);
      r.angle.push_back(rd.tracking ? rd.smoothAngle : -1.0);
      if (was && !rd.tracking) r.dropouts++;
      was = rd.tracking;
      r.reps = rd.reps; r.halfReps = rd.halfReps;
    }
    return r;
  };

  // gerçek klipte gerçek açı yok → jitter vekili: ardışık kare farklarının RMS'i
  // (yüksek frekans enerjisi). kemik varyansı: dünya verisinden uyluk/baldır/üst
  // kol uzunluklarının std/ortalama yüzdesi — "eklem kayması"nın kendisi.
  auto hfEnergy = [](const std::vector<double>& a) {
    double s2 = 0; int n = 0;
    for (size_t i = 1; i < a.size(); i++) {
      if (a[i] < 0 || a[i - 1] < 0) continue;
      double d = a[i] - a[i - 1];
      s2 += d * d; n++;
    }
    return n ? std::sqrt(s2 / n) : -1.0;
  };
  auto boneVar = [&](int a, int b) {
    std::vector<double> len;
    for (const auto& f : clip) {
      if (f.world.size() != 33) continue;
      if (f.screen[a].visibility < 0.5 || f.screen[b].visibility < 0.5) continue;
      double dx = f.world[a].x - f.world[b].x, dy = f.world[a].y - f.world[b].y,
             dz = f.world[a].z - f.world[b].z;
      len.push_back(std::sqrt(dx * dx + dy * dy + dz * dz));
    }
    if (len.size() < 10) return -1.0;
    double s = 0; for (double v : len) s += v;
    double m = s / len.size(), s2 = 0;
    for (double v : len) s2 += (v - m) * (v - m);
    return m > 1e-9 ? 100.0 * std::sqrt(s2 / len.size()) / m : -1.0;
  };

  std::printf("klip: %s   hareket: %s   kare: %zu   sure: %.1f sn\n",
              path, moveName.c_str(), clip.size(), (clip.back().t - clip.front().t) / 1000.0);
  RunResult ema = run(false), euro = run(true);
  std::printf("  ema       hf-jitter %6.3f deg/kare   reps %d   half %d   dropouts %d\n",
              hfEnergy(ema.angle), ema.reps, ema.halfReps, ema.dropouts);
  std::printf("  one euro  hf-jitter %6.3f deg/kare   reps %d   half %d   dropouts %d\n",
              hfEnergy(euro.angle), euro.reps, euro.halfReps, euro.dropouts);
  std::printf("  kemik varyansi (ham dunya verisi): uyluk %.2f%%  baldir %.2f%%  ust kol %.2f%%\n",
              boneVar(23, 25), boneVar(25, 27), boneVar(11, 13));
  return 0;
}

// ── Faz 2 kanıtı: kemik kilidi — ham dünya iskeleti vs çözülmüş iskelet,
// kemik uzunluğu varyansı (%). Kalibrasyonlu motor, gerçek üretim yolu. ──
static int runBones() {
  std::printf("kemik kilidi - ham vs cozulmus iskelet (kemik varyansi %%, kucuk iyi; hedef ~0)\n\n");
  struct Case { const char* label; double sigma; double spike; };
  const Case cases[] = {
    {"temiz kamera ", 0.002, 0.005},
    {"normal kamera", 0.004, 0.010},
    {"kotu isik    ", 0.008, 0.030},
  };
  for (const auto& c : cases) {
    auto clip = makeSynth(c.sigma, c.spike, 42);
    Engine e(builtinMove("squat"));
    e.setCalibration(true);
    auto var = [](const std::vector<double>& len) {
      if (len.size() < 10) return -1.0;
      double s = 0; for (double v : len) s += v;
      double m = s / len.size(), s2 = 0;
      for (double v : len) s2 += (v - m) * (v - m);
      return m > 1e-9 ? 100.0 * std::sqrt(s2 / len.size()) / m : -1.0;
    };
    auto dist = [](const std::vector<Landmark>& v, int a, int b) {
      double dx = v[a].x - v[b].x, dy = v[a].y - v[b].y, dz = v[a].z - v[b].z;
      return std::sqrt(dx * dx + dy * dy + dz * dz);
    };
    std::vector<double> rawThigh, rawShin, solThigh, solShin;
    int reps = 0;
    for (const auto& f : clip) {
      Reading rd = e.update(f.screen, f.world, f.t);
      reps = rd.reps;
      if (!rd.tracking) continue;
      rawThigh.push_back(dist(f.world, 23, 25));
      rawShin.push_back(dist(f.world, 25, 27));
      if (e.solvedWorld().size() == 33) {
        solThigh.push_back(dist(e.solvedWorld(), 23, 25));
        solShin.push_back(dist(e.solvedWorld(), 25, 27));
      }
    }
    std::printf("%s  uyluk ham %5.2f%% -> kilitli %5.2f%%   baldir ham %5.2f%% -> kilitli %5.2f%%   reps %d/8\n",
                c.label, var(rawThigh), var(solThigh), var(rawShin), var(solShin), reps);
  }
  std::printf("\nnot: kilitli iskelette kemik uzunlugu kalibrasyonda dondurulur. asil soru aci\n"
              "metriklerinin bozulmamasi - synth tablosunu kalibrasyonlu kosan mod: bench synthcal.\n");
  return 0;
}

// synth ama kalibrasyon + kemik kilidi AÇIK (üretim yolu): kilit açı metriklerini
// bozuyor mu bozmuyor mu, aynı tabloyla cevap.
static int runSynthCal() {
  std::printf("olcum bandi - kalibrasyon + kemik kilidi ACIK (uretim yolu)\n");
  struct Case { const char* label; double sigma; double spike; };
  const Case cases[] = {
    {"temiz kamera (sigma 0.002, %0.5 isinlanma)", 0.002, 0.005},
    {"normal kamera (sigma 0.004, %1 isinlanma)", 0.004, 0.010},
    {"kotu isik    (sigma 0.008, %3 isinlanma)", 0.008, 0.030},
  };
  for (const auto& c : cases) {
    std::printf("\n%s\n", c.label);
    auto clip = makeSynth(c.sigma, c.spike, 42);
    Engine e(builtinMove("squat"));
    e.setCalibration(true);
    RunResult r;
    bool was = false;
    for (const auto& f : clip) {
      Reading rd = e.update(f.screen, f.world, f.t);
      r.angle.push_back(rd.tracking ? rd.smoothAngle : -1.0);
      if (was && !rd.tracking) r.dropouts++;
      was = rd.tracking;
      r.reps = rd.reps; r.halfReps = rd.halfReps;
    }
    printRow("kilitli", clip, r);
  }
  return 0;
}

// ── Faz 2 kanıtı: çok kişi — kadraja giren yabancı (hoca vakası). Aday sırası
// garanti değil: dedektör sırayı her an değiştirebilir. Naif yol (hep aday 0)
// vs motor seçimi (updateBest) yan yana. ──
static int runTwoPerson() {
  std::printf("iki kisi senaryosu - 8. saniyede kadraja yabanci giriyor, aday sirasi guvenilmez\n\n");
  auto clip = makeSynth(0.004, 0.01, 42);
  // yabancı: ekranda +0.3 sağda, kısa uzuvlu, ayakta duran statik vücut.
  std::vector<Landmark> strangerS, strangerW;
  bodyFromTheta(170.0, strangerS, strangerW);
  for (auto& p : strangerS) if (p.visibility > 0) p.x += 0.30;
  for (int i : {25, 26}) strangerW[i].y *= 0.58;   // uyluk bariz kısa (%42)
  for (int i : {27, 28}) strangerW[i].y *= 0.60;   // baldır bariz kısa
  const int enterAt = 240;   // kalibrasyon (ilk ~2 sn) çoktan bitmiş

  auto run = [&](bool best) {
    Engine e(builtinMove("squat"));
    e.setCalibration(true);
    int reps = 0, wrong = 0, lost = 0;
    for (size_t i = 0; i < clip.size(); i++) {
      const auto& f = clip[i];
      Reading rd;
      if ((int)i < enterAt) {
        rd = best ? e.updateBest({f.screen}, {f.world}, f.t) : e.update(f.screen, f.world, f.t);
      } else if (i >= clip.size() - 90) {
        // son 3 saniye: BİZ kadrajdan çıktık, sadece yabancı var — sert kilit
        // ona geçmemeli (naif yol geçer ve onu koçlar).
        std::vector<std::vector<Landmark>> ss = {strangerS};
        std::vector<std::vector<Landmark>> ww = {strangerW};
        rd = best ? e.updateBest(ss, ww, f.t) : e.update(ss[0], ww[0], f.t);
        if (rd.tracking) wrong++;   // bu karede kimi izliyorsa yabancıdır
      } else {
        // dedektör sırası güvenilmez: her 30 karede bir yabancı 0. sıraya geçer
        bool swap = ((i / 30) % 2) == 0;
        std::vector<std::vector<Landmark>> ss = swap
            ? std::vector<std::vector<Landmark>>{strangerS, f.screen}
            : std::vector<std::vector<Landmark>>{f.screen, strangerS};
        std::vector<std::vector<Landmark>> ww = swap
            ? std::vector<std::vector<Landmark>>{strangerW, f.world}
            : std::vector<std::vector<Landmark>>{f.world, strangerW};
        rd = best ? e.updateBest(ss, ww, f.t)
                  : e.update(ss[0], ww[0], f.t);   // naif: hep aday 0
        if (best) { int ours = swap ? 1 : 0; if (rd.pickedPose != ours) wrong++; }
        else if (swap) wrong++;   // naif yol swap karesinde yabancıyı yer
        if (!rd.tracking) lost++;
      }
      reps = rd.reps;
    }
    std::printf("  %-14s yanlis vucut karesi %3d   kopan kare %3d   reps %d/8\n",
                best ? "motor secimi" : "naif (aday 0)", wrong, lost, reps);
  };
  run(false);
  run(true);
  return 0;
}

// parametre taraması: One Euro (minCutoff, beta) ızgarası, üç gürültü seviyesinin
// TOPLAM skoru üstünden. skor = jitter + rmse + yanlış sayım cezası (yarım tekrar
// gerçekte hiç yok; motor "sayılmadı" derse kullanıcıya haksızlık — 2 derece cezası).
static int runSweep() {
  const double cuts[] = {2.0, 2.5, 3.0, 4.0, 5.0};
  const double betas[] = {0.002, 0.004, 0.006, 0.008, 0.012};
  struct Case { double sigma, spike; } cases[] = {{0.002, 0.005}, {0.004, 0.01}, {0.008, 0.03}};
  std::printf("one euro taramasi (skor = jitter + rmse + 2*|yanlis yarim|, 3 seviye toplami; kucuk iyi)\n\n");
  std::printf("%8s", "");
  for (double b : betas) std::printf("  beta=%-5.3f", b);
  std::printf("\n");
  double best = 1e18, bestC = 0, bestB = 0;
  for (double c : cuts) {
    std::printf("cut=%-4.1f", c);
    for (double b : betas) {
      double score = 0;
      for (const auto& cs : cases) {
        auto clip = makeSynth(cs.sigma, cs.spike, 42);
        auto r = runEngine(clip, true, false, c, b);
        double lag, rmse;
        lagAndRmse(clip, r.angle, lag, rmse);
        // gecikme de puana girer (kare başına 1 puan): Damla'nın "hassas değil"
        // şikayeti gecikmeydi — sakinliği gecikmeyle satın almak yasak.
        score += holdJitter(clip, r.angle) + rmse + 0.03 * lag + 2.0 * r.halfReps + 5.0 * std::abs(r.reps - 8);
      }
      std::printf("  %9.2f", score);
      if (score < best) { best = score; bestC = c; bestB = b; }
    }
    std::printf("\n");
  }
  std::printf("\nen iyi: minCutoff=%.2f beta=%.3f (skor %.2f)\n", bestC, bestB, best);
  return 0;
}

int main(int argc, char** argv) {
  if (argc >= 2 && std::strcmp(argv[1], "synth") == 0) return runSynth();
  if (argc >= 2 && std::strcmp(argv[1], "synthcal") == 0) return runSynthCal();
  if (argc >= 2 && std::strcmp(argv[1], "sweep") == 0) return runSweep();
  if (argc >= 2 && std::strcmp(argv[1], "bones") == 0) return runBones();
  if (argc >= 2 && std::strcmp(argv[1], "twoperson") == 0) return runTwoPerson();
  if (argc >= 3 && std::strcmp(argv[1], "clip") == 0) return runClip(argv[2]);
  std::fprintf(stderr, "kullanim: bench synth | synthcal | sweep | bones | twoperson | clip <dosya.ggclip>\n");
  return 1;
}
