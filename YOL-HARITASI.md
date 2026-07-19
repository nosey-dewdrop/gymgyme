# gymgyme — YOL HARİTASI (FAZ 7+)

`PROTOKOL.md`'nin devamı. Aynı sözleşme şeması, aynı otonomi kuralları
(§4: SORMA, YAP), aynı kapı mantığı. FAZ 6 bittikten sonra buradan devam.

Gerekçeler: `STRATEJI.md`.

**Ek değişmezler (FAZ 7'den itibaren):**
11. Motor davranışı değişiyorsa regresyon süiti koşmadan deploy edilmez.
12. Doğruluk iddiası ölçülmeden yayınlanmaz. "coached" etiketi ölçüm
    sonucudur, karar değil.
13. Ürün içinde LLM yok. Toolchain'de kullanılabilir, patch notes'ta yazılır.
14. Telifli video izinsiz kullanılmaz. Korpus yalnızca açık lisanslı
    (CC0 / ticari kullanıma açık) veya telifi bizde olan kliplerden kurulur.
    Her klibin yanında lisans kaydı bulunur.

**İnsan işi — sadece bunlar:** belirsiz kalan klip etiketlerini onaylamak,
antrenör görüşmeleri, video/içerik üretimi, fiyat kararı.
Klip aramak, indirmek, ön etiketlemek AJAN İŞİDİR.

---

## FAZ 7 — ölçüm altyapısı
```yaml
kapsam: [X10 regresyon süiti, X11 etiketleme aracı, X28 klip toplama]
girdi: [çalışan motor, data/specs.json]
teslim:
  - tools/fetch-clips: Pexels / Pixabay / Mixkit API'lerinden hareket
    adına göre video arar, indirir, corpus/<hareket>/ altına koyar,
    yanına <klip>.license.txt yazar (kaynak URL, lisans, tarih).
    Çeşitlilik hedefi: farklı vücut tipi, farklı kamera açısı, farklı
    ışık. Aynı kanaldan/modelden art arda klip alınmaz.
  - tools/labeler: motor ÖNCE kendi tahminini üretir (kaç tekrar, hangi
    karede dip, hangi hatalar). İnsan sadece onaylar veya düzeltir:
    tek tuş onay, sürükleyerek düzeltme, klavyeyle sonraki klibe geçiş.
    Fare gerekmez. Yüksek güvenli tahminler OTOMATİK kabul edilir;
    yalnızca düşük güvenli klipler onay kuyruğuna düşer (aktif öğrenme).
  - corpus/ yapısı: <hareket>/<klip>.mp4 + .labels.json + .license.txt
  - tests/regression: korpusu motordan geçirir, hareket başına kaçırılan
    tekrar / yanlış sayım / hata precision-recall üretir
  - scripts/validate.sh: tam süit (gecelik) + hızlı süit (her commit)
  - baseline.json: mevcut doğruluk taban çizgisi
miras:
  - her motor değişikliği bu süitten geçer
kapı:
  - fetch-clips ile ≥5 hareket için klip indirildi, lisans dosyaları var
  - labeler ile 1 klip uçtan uca onaylanabiliyor
  - validate.sh çalışıyor, metrik üretiyor
  - baseline.json commit'li
  - motorda kasıtlı bozma → süit kırmızı veriyor (negatif test)
hedef:
  - hareket başına 15 klip + motorun zorlandığı ek klipler
insan_isi:
  - onay kuyruğunu boşaltmak (belirsiz klipler)
```

## FAZ 8 — spec sanayileşmesi (14 → 50 hareket)
```yaml
kapsam: [X12 arketip şablonları, X13 spec DSL, X14 üretim hattı]
girdi: [regresyon süiti, ≥5 hareketlik etiketli korpus]
teslim:
  - 12 arketip şablonu: squat · hinge · lunge · press · pull · raise ·
    bridge · plank/hold · crunch · rotation · kick · balance
    Her şablon: sürücü eklem, dip/lockout tanımı, izlenecek hata
    eklemleri, güvenilir kamera açıları
  - spec DSL (YAML) + derleyici → C++/wasm. Yeni hareket = satır eklemek
  - hata taksonomisi: ilk 5 hareket için tam hata seti (eşik + kaç kare
    üst üste + hangi faz)
  - üretim hattı: taslak (LLM, toolchain) → doğrulama → coached/reference
    OTOMATİK etiket
kapı:
  - 12 şablon tanımlı, testli
  - yeni hareket eklemek yalnızca DSL satırı gerektiriyor (kanıt: bir
    hareketi sıfırdan ekle, kod değişmeden çalışsın)
  - coached/reference etiketi ölçümden geliyor (elle atanmış = 0)
  - 50 harekette süit yeşil, baseline düşmemiş
karar:
  - coached eşiği → ajan belirler, DECISIONS'a yazar
```

## FAZ 9 — motor kalitesi
```yaml
kapsam: [X15 zamansal filtre, X16 açı sınıflandırma, X17 görünürlük,
         X18 antropometrik normalizasyon, X19 düşük fps]
girdi: [FAZ 8 çıktısı, ≥10 hareketlik korpus]
teslim:
  - One Euro / Kalman filtresi landmark'lara
  - görüş açısı sınıflandırma (omuz/kalça genişlik oranı) → açıya göre
    spec seçimi; ölçülemeyen açıda "bu açıdan ölçemiyorum"
  - görünürlük eşiği: düşükse saymaz
  - antropometrik normalizasyon: ilk sette kişisel ROM ölçülür, eşikler
    taban çizgisine göre normalize edilir, cihazda saklanır
  - düşük fps modu: adaptif örnekleme
kapı:
  - her madde öncesi/sonrası baseline karşılaştırması, hepsinde iyileşme
  - yanlış sayım oranı düştü
  - 15 fps klip setinde kaçırma oranı hedef altında
  - hiçbir maddede regresyon yok
karar:
  - "ölçemiyorum" mesajının dili → ajan yazar (mevcut sese uygun)
```

## FAZ 10 — kütüphane ölçeği + SEO
```yaml
kapsam: [X20 hareket sayfaları, X21 500'e ölçek]
girdi: [FAZ 9 motoru, üretim hattı, tasarım sistemi]
teslim:
  - hareket sayfası şablonu: her hareket kendi URL'inde, sayfada O
    HAREKETİ ölçen canlı kamera (index hero modülünün parametreli hali),
    altında spec bilgisi + doğruluk satırı + ilgili hareketler
  - 500 harekete ölçek
  - sitemap, structured data, canonical
  - iç bağlantı: kategori → hareket → benzer hareket
kapı:
  - hareket sayfası sayısı = kütüphane sayısı
  - rastgele 10 sayfada canlı kamera çalışıyor
  - Lighthouse: performans ≥90, erişilebilirlik ≥95
  - sitemap geçerli, kırık iç link = 0
  - mediapipe hâlâ lazy
karar:
  - sayfanın üst bloğu (kamera mı açıklama mı) → ajan karar verir
```

## FAZ 11 — doğruluk kaydı
```yaml
kapsam: [X22 kanıt yayını, X23 antrenör kalibrasyonu]
girdi: [FAZ 9 metrikleri, ≥20 hareketlik korpus]
teslim:
  - /accuracy sayfası: hareket başına test edilen tekrar, kaçırılan,
    yanlış sayılan. Kaçırılanlar dahil, dürüst.
  - her hareket sayfasında kendi doğruluk satırı
  - patch notes'a doğruluk değişimleri otomatik düşer
  - antrenör kalibrasyonu: 2-3 antrenör aynı kliplere puan verir, skor
    eğrileri buna göre ayarlanır, uyum oranı yayınlanır
  - KORPUS AÇIK DEĞİL — sayılar yayınlanır, klipler yayınlanmaz
kapı:
  - accuracy sayfası canlı, sayılar süitten otomatik (elle yazılmış = 0)
  - antrenör uyum metriği hesaplanıyor
  - ölçülmemiş hiçbir doğruluk iddiası yok
karar:
  - kötü sayıların hepsi yayınlanır (varsayılan: hepsi)
insan_isi:
  - antrenör bulma ve puanlama seansları
```

## FAZ 12 — dağıtım ve para
```yaml
kapsam: [X24 set kartı, X25 klip bağışı, X26 Pro, X27 ölçüm]
girdi: [çalışan ürün, doğruluk kaydı]
teslim:
  - set kartı: set sonunda tek kare — nokta figürü, tekrar, skor, tarih,
    alan adı. Vücut yok, fotoğraf yok. Paylaş/indir.
  - klip bağışı: opsiyonel, varsayılan KAPALI, açık rıza, geri alınabilir.
    Video değil, landmark zaman serisi. Ne gönderildiği ekranda görünür.
    Gelen veri korpusa aday olarak düşer.
  - Pro katmanı: senkron, ilerleme analizi, çevrimdışı paket, seans
    tipleri. Aylık düşük band + ömür boyu seçeneği.
  - çekirdek ücretsiz kalır, hiçbir mevcut özellik Pro'ya taşınmaz
  - ölçüm: Plausible/Umami self-host, çerezsiz
  - kuzey yıldızı paneli: ilk 90 saniyede sayılmış tekrarı olan
    ziyaretçi oranı
kapı:
  - set kartı üretiliyor, içinde kişisel görüntü yok
  - bağış varsayılan kapalı, kapatınca gerçekten duruyor (ağ trafiğiyle
    kanıtla)
  - hiçbir ücretsiz özellik Pro'ya taşınmamış (öncesi/sonrası liste)
  - kuzey yıldızı ölçülüyor
karar:
  - set kartının görsel düzeni → ajan karar verir
KIRMIZI (durulur):
  - Pro fiyatı ve ömür boyu fiyatı → para kararı, insana aittir
insan_isi:
  - video üretimi, topluluk paylaşımları, stüdyo görüşmeleri
```

---

## SIRA

```
FAZ 3-6   tasarım           → ajan
FAZ 7     ölçüm altyapısı   → ajan (klip toplama dahil)
FAZ 8     spec sanayisi     → ajan
FAZ 9     motor kalitesi    → ajan
FAZ 10    ölçek + SEO       → ajan
FAZ 11    doğruluk kaydı    → ajan + insan (antrenör)
FAZ 12    dağıtım + para    → ajan + insan (fiyat, içerik)
```

**Klip toplama FAZ 7'de başlar ve hiç durmaz.** Ajan arka planda indirmeye
ve ön etiketlemeye devam eder; insana sadece belirsiz kalanlar gider.

**Kritik bağımlılık:** FAZ 8-11 sırayla yapılır. Spec sanayisi olmadan
ölçek, motor kalitesi olmadan doğruluk kaydı anlamsız.

---

## BİTİŞ DURUMU

- 12 sayfa + 500 hareket sayfası, tek tasarım sisteminde
- 500 hareket, ölçülenler ölçüm sonucuyla etiketli
- 20+ hareket × 8 hata kalibre edilmiş kural tablosu
- Lisanslı, etiketli, kapalı korpus
- Regresyon süiti: motor bozulursa deploy durur
- Yayınlanmış doğruluk kaydı + antrenör uyum metriği
- Kişiselleştirilmiş eşikler
- Set kartı, klip bağışı akışı
- Pro + ömür boyu, çekirdek ücretsiz

Rakibin sorunu artık "motor yazmak" değil, "bu tabloyu üretmek".
