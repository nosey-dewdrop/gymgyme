// ik.hpp — anatomik eklem-limiti çözücü, saf C++.
//
// Kemik kilidi (coach_engine solveBones) UZUNLUĞU sabitliyordu: kemik uzayamaz.
// Ama AÇI hâlâ serbestti — dedektör gürültüsü dizi geriye bükebilir (anatomik
// olarak imkansız: insan dizi 180°'yi geçmez, ~0°'nin altına inmez). Gerçek bir
// IK solver bunu bilir: her eklemin fiziksel bir açı aralığı vardır, dışına
// çıkan okuma GÜRÜLTÜdür, sınıra geri çekilir.
//
// Bu, mocap temizleme ("solve/cleanup") aşamasının çekirdeği. Burada eklem
// açısını limitlerine kırpıp, çocuğu ebeveyn etrafında o düzeltilmiş açıya
// döndürerek zinciri yeniden konumlandırıyoruz — yön korunur, açı yasallaşır.

#pragma once
#include <cmath>
#include <algorithm>

namespace coach {

// bir eklemin anatomik açı aralığı (derece). a-b-c üçlüsünde b'deki açı.
struct JointLimit {
  int a, b, c;           // landmark üçlüsü (b = eklem)
  double minDeg, maxDeg; // fiziksel aralık
};

// ── SEZGİSEL güvenlik kırpma sınırları (biyomekanik ROM tablosu DEĞİL, atıfsız
// heuristik). ÖNEMLİ DÜRÜSTLÜK NOTU (CS-dekan turu): ikAngle üç noktanın İÇ
// açısını verir, matematiksel olarak 0-180° arası. Bu yüzden 185/210 gibi ÜST
// sınırlar ASLA tetiklenmez — kaldırıldılar (yalancı güvenlik). Kırpmanın
// gerçek işi ALT sınır: dedektör gürültüsü bir eklemi fiziken imkansız kadar
// (birkaç derece) kapatırsa geri açılır. Gerçek derin tekrar (diz/dirsek ~20-40°)
// bandın rahat içinde, dokunulmaz. Hiperekstansiyon (>180) bu 2B açı ölçümüyle
// zaten temsil edilemiyor; onu iddia etmiyoruz. ──
inline const JointLimit* humanLimits(int& count) {
  static const JointLimit L[] = {
    // dizler: ~5°'nin altı fiziken imkansız (bilek uyluğa katlanmaz). üst 180 = etkisiz sınır.
    {23, 25, 27,  5.0, 180.0},   // sol diz (kalça-diz-bilek)
    {24, 26, 28,  5.0, 180.0},   // sağ diz
    // dirsekler: ~5°'nin altı imkansız. gerçek tam-büküm ~25-40° bandın içinde.
    {11, 13, 15,  5.0, 180.0},   // sol dirsek (omuz-dirsek-bilek)
    {12, 14, 16,  5.0, 180.0},   // sağ dirsek
    // kalça (gövde-uyluk iç açısı): ~8°'nin altı imkansız.
    {11, 23, 25,  8.0, 180.0},   // sol kalça (omuz-kalça-diz)
    {12, 24, 26,  8.0, 180.0},   // sağ kalça
  };
  count = sizeof(L) / sizeof(L[0]);
  return L;
}

// üç noktadan b'deki açı (derece). -1 = dejenere.
inline double ikAngle(double ax, double ay, double az,
                      double bx, double by, double bz,
                      double cx, double cy, double cz) {
  double v1x = ax - bx, v1y = ay - by, v1z = az - bz;
  double v2x = cx - bx, v2y = cy - by, v2z = cz - bz;
  double m1 = std::sqrt(v1x * v1x + v1y * v1y + v1z * v1z);
  double m2 = std::sqrt(v2x * v2x + v2y * v2y + v2z * v2z);
  if (m1 < 1e-9 || m2 < 1e-9) return -1.0;
  double d = (v1x * v2x + v1y * v2y + v1z * v2z) / (m1 * m2);
  d = std::max(-1.0, std::min(1.0, d));
  return std::acos(d) * 180.0 / M_PI;
}

// ── bir eklemi limite kırp. b'deki açı aralık dışındaysa, c noktasını b
// etrafında (a-b-c düzleminde) döndürerek açıyı en yakın sınıra çeker. Kemik
// uzunluğu (|b-c|) KORUNUR — sadece yön düzeltilir. Değişti mi döner. ──
// P: her noktanın x,y,z'sini içeren düz dizi (3*33). idx*3 ile erişilir.
inline bool clampJoint(double* P, const JointLimit& j) {
  const int ai = j.a * 3, bi = j.b * 3, ci = j.c * 3;
  double cur = ikAngle(P[ai], P[ai+1], P[ai+2],
                       P[bi], P[bi+1], P[bi+2],
                       P[ci], P[ci+1], P[ci+2]);
  if (cur < 0) return false;
  double target = std::max(j.minDeg, std::min(j.maxDeg, cur));
  if (std::fabs(target - cur) < 0.5) return false;   // zaten aralıkta

  // b→c vektörünü, b→a düzleminde, açı farkı kadar döndür (Rodrigues).
  double bax = P[ai]-P[bi], bay = P[ai+1]-P[bi+1], baz = P[ai+2]-P[bi+2];
  double bcx = P[ci]-P[bi], bcy = P[ci+1]-P[bi+1], bcz = P[ci+2]-P[bi+2];
  double bcLen = std::sqrt(bcx*bcx + bcy*bcy + bcz*bcz);
  if (bcLen < 1e-9) return false;
  // dönme ekseni = ba × bc (düzleme dik)
  double nx = bay*bcz - baz*bcy, ny = baz*bcx - bax*bcz, nz = bax*bcy - bay*bcx;
  double nLen = std::sqrt(nx*nx + ny*ny + nz*nz);
  if (nLen < 1e-9) return false;   // a,b,c eşdoğrusal — döndürme düzlemi yok
  nx /= nLen; ny /= nLen; nz /= nLen;
  double delta = (target - cur) * M_PI / 180.0;   // ne kadar döneceğiz
  // c-b'yi ekseni etrafında delta döndür (Rodrigues formülü)
  double cosd = std::cos(delta), sind = std::sin(delta);
  double dot = bcx*nx + bcy*ny + bcz*nz;
  double rx = bcx*cosd + (ny*bcz - nz*bcy)*sind + nx*dot*(1-cosd);
  double ry = bcy*cosd + (nz*bcx - nx*bcz)*sind + ny*dot*(1-cosd);
  double rz = bcz*cosd + (nx*bcy - ny*bcx)*sind + nz*dot*(1-cosd);
  // uzunluğu koru (sayısal kayma olabilir), b'ye ekle
  double rLen = std::sqrt(rx*rx + ry*ry + rz*rz);
  if (rLen < 1e-9) return false;
  rx *= bcLen/rLen; ry *= bcLen/rLen; rz *= bcLen/rLen;
  P[ci]   = P[bi]   + rx;
  P[ci+1] = P[bi+1] + ry;
  P[ci+2] = P[bi+2] + rz;
  return true;
}

// tüm insan limitlerini uygula, kaç eklem düzeltildiğini döndür.
// ── Eklemler ZİNCİRDE bağlı: kalçayı kırpmak dizi (paylaşılan nokta) oynatır,
// bu da az önce kırpılan diz açısını yeniden bozabilir. Tek geçiş global-yasal
// bir iskelet garanti etmez. O yüzden YAKINSAYANA kadar (ya da en çok 4 geçiş)
// tekrarla — hiçbir eklem değişmediğinde dur. ──
inline int clampHumanLimits(double* P) {
  int n = 0; const JointLimit* lim = humanLimits(n);
  int totalFixed = 0;
  for (int pass = 0; pass < 4; pass++) {
    int fixedThisPass = 0;
    for (int i = 0; i < n; i++) if (clampJoint(P, lim[i])) fixedThisPass++;
    totalFixed += fixedThisPass;
    if (fixedThisPass == 0) break;   // yakınsadı: tüm eklemler aynı anda yasal
  }
  return totalFixed;
}

}  // namespace coach
