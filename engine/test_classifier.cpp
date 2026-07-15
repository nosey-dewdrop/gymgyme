// test_classifier.cpp — hareket sınıflandırıcının imza eşleştirmesini doğrular.
// clang++ -std=c++17 -O2 test_classifier.cpp -o /tmp/ct && /tmp/ct
#include "classifier.hpp"
#include <cstdio>
#include <cmath>
using namespace coach;

static int failed = 0;
static void check(bool c, const char* m) { std::printf("%s %s\n", c ? "ok  " : "FAIL", m); if (!c) failed++; }

int main() {
  // salınan DİZ, dik gövde -> squat
  {
    MoveClassifier c;
    for (int i = 0; i < 60; i++) {
      double phase = std::sin(i * 0.3);
      double knee = 130 + 50 * phase;   // 80..180 salınım
      c.feed(knee, 175, 170, 20, 10.0); // dirsek/kalça sabit, tilt dik
    }
    double conf; std::string m = c.classify(conf);
    check(m == "squat", "oscillating knee + upright -> squat");
    check(conf > 0.5, "squat classification has decent confidence");
  }

  // salınan DİRSEK, yatay gövde -> pushup
  {
    MoveClassifier c;
    for (int i = 0; i < 60; i++) {
      double phase = std::sin(i * 0.3);
      double elbow = 130 + 45 * phase;  // salınım
      c.feed(178, elbow, 175, 30, 85.0); // diz sabit, tilt yatay
    }
    double conf; std::string m = c.classify(conf);
    check(m == "pushup", "oscillating elbow + horizontal -> pushup");
  }

  // salınan OMUZ, dik -> jumping jack ya da arm raise (omuz ekseni)
  {
    MoveClassifier c;
    for (int i = 0; i < 60; i++) {
      double phase = std::sin(i * 0.3);
      double sh = 90 + 70 * phase;
      c.feed(178, 175, 170, sh, 12.0);
    }
    double conf; std::string m = c.classify(conf);
    check(m == "jumpingjack" || m == "armraise", "oscillating shoulder + upright -> a shoulder move");
  }

  // SABİT (salınım yok), yatay, dirsek destekte ~90 -> plank (hold)
  {
    MoveClassifier c;
    for (int i = 0; i < 60; i++) {
      double j = (i % 2 == 0) ? 2 : -2;
      // gerçek plank imzası: dirsek en çok "kıpırdayan" eklem (destek), gövde
      // düz+yatay. superman'dan ayrımı: superman'da kalça ekstansiyonda oynar.
      c.feed(178, 92 + j, 178, 30, 88.0);   // dirsek ~90 (destek), diğerleri düz
    }
    double conf; std::string m = c.classify(conf);
    check(m == "plank", "static + horizontal + elbow support -> plank (hold detected)");
  }

  // SABİT, dik -> wall sit (hold)
  {
    MoveClassifier c;
    for (int i = 0; i < 60; i++) {
      double j = (i % 2 == 0) ? 1.5 : -1.5;
      c.feed(92 + j, 178, 100, 20, 8.0);   // diz ~90 sabit, tilt dik
    }
    double conf; std::string m = c.classify(conf);
    check(m == "wallsit", "static knee ~90 + upright -> wall sit");
  }

  // ── squat vs lunge ayrımı (CS-dekan bulgusu: eskiden AYNI imza, ayırt
  // edilemezdi). Artık ASİMETRİ boyutu ayırır: squat simetrik (sol=sağ diz),
  // lunge asimetrik (bir bacak önde, büyük sol-sağ fark). ──
  {
    // simetrik salınan diz + DÜŞÜK asimetri -> squat
    MoveClassifier sq;
    for (int i = 0; i < 60; i++) {
      double knee = 130 + 50 * std::sin(i * 0.3);
      sq.feed(knee, 175, 170, 20, 10.0, 3.0);   // asimetri ~3° (simetrik)
    }
    double c1; std::string m1 = sq.classify(c1);
    check(m1 == "squat", "symmetric knee movement -> squat (not lunge)");

    // salınan diz + YÜKSEK asimetri -> lunge
    MoveClassifier lu;
    for (int i = 0; i < 60; i++) {
      double knee = 130 + 50 * std::sin(i * 0.3);
      lu.feed(knee, 175, 170, 20, 10.0, 35.0);   // asimetri ~35° (tek bacak önde)
    }
    double c2; std::string m2 = lu.classify(c2);
    check(m2 == "lunge", "asymmetric knee movement -> lunge (asymmetry dimension separates them)");
  }

  // yetersiz veri -> boş (motor emin değil)
  {
    MoveClassifier c;
    for (int i = 0; i < 5; i++) c.feed(130, 175, 170, 20, 10);
    double conf; std::string m = c.classify(conf);
    check(m.empty() && conf == 0, "too little data yields no guess");
  }

  // reset temizler
  {
    MoveClassifier c;
    for (int i = 0; i < 60; i++) c.feed(130 + 40 * std::sin(i * 0.3), 175, 170, 20, 10);
    c.reset();
    double conf; std::string m = c.classify(conf);
    check(m.empty(), "reset clears the classifier window");
  }

  std::printf(failed ? "\n%d classifier test FAILED\n" : "\nall classifier tests passed\n", failed);
  return failed ? 1 : 0;
}
