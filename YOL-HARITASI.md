# gymgyme — YOL HARİTASI (FAZ 7+)

`PROTOKOL.md`'nin devamı. Aynı sözleşme şeması, aynı otonomi kuralları,
aynı kapı mantığı. FAZ 6 (tasarım denetimi) bittikten sonra buradan devam.

Gerekçeler ve strateji: `STRATEJI.md`.

**Yeni değişmez (FAZ 7'den itibaren geçerli):**
11. Motor davranışı değişiyorsa regresyon süiti koşmadan deploy edilmez.
12. Doğruluk iddiası ölçülmeden yayınlanmaz. "coached" etiketi ölçüm
    sonucudur, karar değil.
13. Ürün içinde LLM yok. Toolchain'de kullanılabilir, patch notes'ta yazılır.

**İnsan işi (ajan yapamaz, planda yer tutar):** klip çekimi, klip
etiketleme, antrenör görüşmeleri, video üretimi, stüdyo temasları.
Ajan bunlar için araç yazar, veriyi insan üretir.

---

## FAZ 7 — ölçüm altyapısı
```yaml
kapsam: [X10 regresyon süiti, X11 etiketleme aracı]
girdi: [çalışan motor, spec değerleri (data/specs.json)]
teslim:
  - tools/labeler: yerel çalışan tek sayfalık araç. Klibi oynatır,
    boşlukla tekrar işaretlenir, tuşlarla hata etiketlenir (valgus,
    heel_lift, trunk_lean, butt_wink, asymmetry, tempo_collapse),
    çıktı JSON. Tasarım önemsiz, hız önemli.
  - corpus/ klasör yapısı: <hareket>/<klip>.mp4 + <klip>.labels.json
  - tests/regression: korpusu motordan geçirir, hareket başına
    kaçırılan tekrar / yanlış sayım / hata precision-recall üretir
  - scripts/validate.sh: tam süit; CI'da gecelik, commit'te hızlı süit
  - baseline.json: mevcut doğruluk taban çizgisi
miras:
  - her motor değişikliği bu süitten geçer
kapı:
  - labeler ile 1 klip uçtan uca etiketlenebiliyor
  - validate.sh çalışıyor, metrik üretiyor
  - baseline.json commit'li
  - motorda kasıtlı bozma → süit kırmızı veriyor (negatif test)
zevk_karari: yok
insan_isi:
  - ilk 5 hareket × 40 klip çekimi (çeşitli vücut, açı, ışık, kıyafet,
    telefon yüksekliği, düşük fps cihaz)
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
  - üretim hattı: taslak (LLM, toolchain) → insan onayı → klip doğrulama
    → coached/reference OTOMATİK etiket
kapı:
  - 12 şablon tanımlı, testli
  - yeni hareket eklemek yalnızca DSL satırı gerektiriyor (kanıt: bir
    hareketi sıfırdan ekle, kod değişmeden çalışsın)
  - coached/reference etiketi ölçümden geliyor (elle atanmış = 0)
  - 50 harekette süit yeşil, baseline düşmemiş
zevk_karari:
  - coached eşiği ne olsun (kaçırma/yanlış sayım üst sınırı)
```

## FAZ 9 — motor kalitesi
```yaml
kapsam: [X15 zamansal filtre, X16 açı sınıflandırma, X17 görünürlük,
         X18 antropometrik normalizasyon, X19 düşük fps]
girdi: [FAZ 8 çıktısı, ≥10 hareketlik korpus]
teslim:
  - One Euro / Kalman filtresi landmark'lara
  - görüş açısı sınıflandırma (omuz/kalça genişlik oranı) → açıya göre
    spec seçimi; ölçülemeyen açıda "bu açıdan ölçemiyorum" der
  - görünürlük eşiği: düşükse saymaz, "can't see you clearly" der
  - antropometrik normalizasyon: ilk sette kişisel ROM ölçülür, eşikler
    taban çizgisine göre normalize edilir, cihazda saklanır (yükleme yok)
  - düşük fps modu: adaptif örnekleme, eski Android'de faz kaçırmaz
kapı:
  - her madde öncesi/sonrası baseline karşılaştırması, hepsinde iyileşme
  - yanlış sayım oranı düştü
  - 15 fps klip setinde kaçırma oranı hedef altında
  - hiçbir maddede regresyon yok
zevk_karari:
  - "ölçemiyorum" mesajının dili
```

## FAZ 10 — kütüphane ölçeği + SEO
```yaml
kapsam: [X20 hareket sayfaları, X21 500'e ölçek]
girdi: [FAZ 9 motoru, üretim hattı, tasarım sistemi]
teslim:
  - hareket sayfası şablonu: her hareket kendi URL'inde, sayfada O
    HAREKETİ ölçen canlı kamera (index hero modülünün hareket-parametreli
    hali), altında spec bilgisi + doğruluk satırı + ilgili hareketler
  - 500 harekete ölçek (coached olanlar ölçülüyor, gerisi reference)
  - sitemap, structured data, canonical
  - iç bağlantı: kategori → hareket → benzer hareket
miras:
  - bu şablon blog ve program sayfalarında da kullanılır
kapı:
  - hareket sayfası sayısı = kütüphane sayısı
  - her sayfada canlı kamera çalışıyor (rastgele 10 sayfa testi)
  - Lighthouse: performans ≥90, erişilebilirlik ≥95
  - sitemap geçerli, kırık iç link = 0
  - mediapipe hâlâ lazy (ilk yüklemede inmiyor)
zevk_karari:
  - hareket sayfasının üst bloğu: kamera mı önce, açıklama mı
```

## FAZ 11 — doğruluk kaydı (moat'ın görünür yüzü)
```yaml
kapsam: [X22 kanıt yayını, X23 antrenör kalibrasyonu]
girdi: [FAZ 9 metrikleri, ≥20 hareketlik korpus]
teslim:
  - /accuracy sayfası: hareket başına test edilen tekrar sayısı,
    kaçırılan, yanlış sayılan. Kaçırılanlar dahil, dürüst.
  - her hareket sayfasında kendi doğruluk satırı
  - patch notes'a doğruluk değişimleri otomatik düşer
  - antrenör kalibrasyonu: 2-3 sertifikalı antrenör aynı kliplere puan
    verir, skor eğrileri buna göre ayarlanır, uyum oranı yayınlanır
  - KORPUS AÇIK DEĞİL — sayılar yayınlanır, klipler yayınlanmaz
kapı:
  - accuracy sayfası canlı, sayılar süitten otomatik üretiliyor (elle
    yazılmış sayı = 0)
  - antrenör uyum metriği hesaplanıyor
  - hiçbir doğruluk iddiası ölçüm olmadan yayınlanmamış
zevk_karari:
  - kötü sayıların ne kadarı yayınlanacak (öneri: hepsi)
insan_isi:
  - antrenör bulma ve puanlama seansları
```

## FAZ 12 — dağıtım ve para
```yaml
kapsam: [X24 set kartı, X25 klip bağışı, X26 Pro, X27 içerik]
girdi: [çalışan ürün, doğruluk kaydı]
teslim:
  - set kartı: set sonunda tek kare — nokta figürü, tekrar, skor, tarih,
    alan adı. Vücut yok, fotoğraf yok. Paylaş/indir.
  - klip bağışı: opsiyonel, varsayılan KAPALI, açık rıza, geri alınabilir.
    Video değil, landmark zaman serisi. Ne gönderildiği ekranda görünür.
    Gelen veri korpusa aday olarak düşer, insan onayıyla girer.
  - Pro katmanı: senkron, ilerleme analizi, çevrimdışı paket, seans
    tipleri. Aylık düşük band + ömür boyu seçeneği.
  - çekirdek ücretsiz kalır, hiçbir mevcut özellik Pro'ya taşınmaz
  - ölçüm: Plausible/Umami self-host, çerezsiz
  - kuzey yıldızı paneli: ilk 90 saniyede sayılmış tekrarı olan
    ziyaretçi oranı
kapı:
  - set kartı üretiliyor, paylaşılabiliyor, içinde kişisel görüntü yok
  - bağış varsayılan kapalı, kapatınca gerçekten duruyor (ağ trafiği ile
    kanıtla)
  - hiçbir ücretsiz özellik Pro'ya taşınmamış (öncesi/sonrası liste)
  - kuzey yıldızı ölçülüyor
zevk_karari:
  - Pro fiyatı ve ömür boyu fiyatı
  - set kartının görsel düzeni
insan_isi:
  - video üretimi, topluluk paylaşımları, stüdyo/fizyoterapist görüşmeleri
```

---

## SIRA VE PARALELLİK

```
FAZ 3-6  tasarım           → ajan yürütür
FAZ 7    ölçüm altyapısı   → ajan yürütür + insan klip çeker (paralel başlar)
FAZ 8    spec sanayisi     → ajan
FAZ 9    motor kalitesi    → ajan
FAZ 10   ölçek + SEO       → ajan
FAZ 11   doğruluk kaydı    → ajan + insan (antrenör)
FAZ 12   dağıtım + para    → ajan + insan (içerik)
```

**Klip toplama FAZ 7'de başlar ve hiç durmaz.** Korpus büyümesi tüm
sonraki fazların hızını belirler; en uzun süren iş odur, en erken
başlaması gereken de.

**Kritik bağımlılık:** FAZ 8-11 sırayla yapılmalı. Spec sanayisi olmadan
ölçek, motor kalitesi olmadan doğruluk kaydı anlamsız. Sıra atlanamaz.

---

## BİTİŞ DURUMU

FAZ 12 bittiğinde elde olan:

- 12 sayfa + 500 hareket sayfası, tek tasarım sisteminde
- 500 hareket, ölçülenler ölçüm sonucuyla etiketli
- 20+ hareket × 8 hata kalibre edilmiş kural tablosu
- 800+ klipli etiketli korpus (kapalı)
- Regresyon süiti: motor bozulursa deploy durur
- Yayınlanmış doğruluk kaydı + antrenör uyum metriği
- Kişiselleştirilmiş eşikler (antropometrik normalizasyon)
- Paylaşılabilir set kartı, klip bağışı akışı
- Pro + ömür boyu, çekirdek ücretsiz

Bu noktada rakibin sorunu "motor yazmak" değil, "bu tabloyu üretmek" —
ve o iki ay değil, iki yıl.
