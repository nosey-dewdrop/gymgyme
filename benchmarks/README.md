# gymgyme — BENCHMARK LOOP DÜZENİ

Bu klasör her sorunu **ayrı bir loop** olarak tutar. Kural:
- **Bir sekme = bir loop = bir `benchmark-XX.md`.**
- Loop o dosyadaki DONE ölçütlerine ulaşınca **kapanır**, pencere **temizlenir**, yeni sekme **temiz** (clear context) başlar, sonraki dosyayı açar.
- Her loop tek konuya odaklıdır — context şişmez, iş tıkır tıkır ilerler.
- Her loop `STATUS: TODO | IN PROGRESS | DONE` taşır. Yeni sekme açılınca önce bu README'ye bakılır, ilk `TODO/IN PROGRESS` olan loop'a girilir.

## KAPANIŞ RİTÜELİ (her loop DONE olunca)
1. Loop dosyası `STATUS: DONE`, README kutusu işaretle.
2. **devlog.md** — HER loop'ta (büyük/küçük fark etmez): ufak Z-kuşağı reels parçaları düşer (hook zorunlu, 30-60sn, "şunu değiştirdim çünkü şu sorun vardı" tonu, gerçek tarihçeden, sınırsız içerik). Bazıları AÇIKLAMALI olsun — tech stack / terim (wasm, pose estimation, on-device, false positive, benchmark...) sıfırdan, "mala öğretir gibi" sıcak dille; izleyen bilmeyebilir. Ton hep bu. Stok aklına geldikçe, farklı alanlardan da büyür (devlog.md sonundaki "TECH/AI/CV STOĞU" bölümü).
3. **BÜYÜK REWORK ise** (motor/UI'ı gerçekten değiştiren iş — her küçük loop DEĞİL): ek olarak benchmark **raporu** (reports/ altına) + **linkedin.md** halkası (300-500 kelime, numaralı inşa zinciri: ne+neden+karar).
4. Push.
5. Pencereyi TEMİZLE, yeni sekmede sıradaki loop'a geç.

## GENEL İLKELER (her loop bunlara uyar)
- **Whimsy yan kalır** (fiş/receipt, afiş/marquee, vişne palet) — SİLİNMEZ. Ama bu bir üründür: ham iskelet/debug müşteriden gizlenir.
- **AI slop YASAK:** generic gradient, renkli-tek-kelime, emoji-bullet, pill badge, mor, ölü boşluk YOK. Premium his = az öğe + net değer + akıcı hareket.
- **Kör iterasyon YASAK:** UI'da 2-3 turdan sonra dur, referans al ya da tek ekranda Damla ile ilerle.
- **Kanıtla, iddia etme:** her loop kapanışında derleme/test/tablo kanıtı. "oldu" demeden önce göster.
- **104+ yerel test BOZULMAZ.** Yeni test eklenir, var olan kalır.
- **Damla kamerada kendi gözüyle bakar** (headless işe yaramaz — kamera).
- Değer sırası: **önce görünür müşteri değeri (UI + skor kapısı), sonra görünmez sağlamlık (benchmark).**

## KOÇLAMA KAPSAMI (net karar)
MOVE_DB'de **386 hareket** var ama hepsi koçlanamaz. Üç sınıf:
1. **REP-based** (say + puanla): squat/pushup/lunge/crunch/raise/twist türevleri → motora GİRER.
2. **HOLD-based** (süre + form): plank/side plank/wall sit/hollow hold türevleri → motora GİRER.
3. **STRETCH/REFERENCE** (child's pose, cobra, cat stretch, tüm "stretch"ler): rep yok, form kapısı yok → dürüstçe **"reference"** kalır, koçlanmaz gibi gösterilmez.

**Hedef: 1+2'nin HEPSİ öğrenilir** (bugünkü ~5 kurallı hareket değil). Bu ~200+ hareket. Bait-and-switch böyle kapanır: koçlanan "counts reps/coached hold", koçlanmayan "reference" etiketi taşır.

---

## KATMAN HARİTASI (16 Tem teşhisi — her loop bir katmana bağlıdır)
Tam teşhis: reports/2026-07-16-gymgyme-katman-teshisi.md

- **L1 marka/landing** — index.html, styles.css, marquee, FAQ. Sorun: H1 metafor değer değil, görsel kanıt (demo klip) yok, "(0)" sayaçları flop sinyali. → loop 01 (DONE), **loop 09**
- **L2 ürün akışı/nav** — topbar, sayfa geçişleri, iki hareket kaynağı (seed.js dizini vs MOVE_DB). Sorun: dizin+trainer köprüsüz yarışıyor, "just try it" yolu yok. EN KRİTİK LOOP'SUZ KATMANDI. → **loop 00**
- **L3 koç deneyimi UI** — coach.html, js/coach.js (1479 satır tek dosya), css/coach.css. Sorun: debug paneli müşteriye açık, fiş videoyu örtüyor. → loop 02 (IN PROGRESS), 03, 05
- **L4 CV motoru doğruluk** — engine/ (16 dosya, coach_engine.cpp 1744 satır, 104+ test). En olgun katman AMA %60 kapısı yok, 386 vitrin / ~14 kurallı hareket, doğruluk iddiası ölçümsüz. → loop 04, 06, 07, 08
- **L5 veri/backend** — Supabase, auth, sw.js, KVKK bandı. En sağlam katman. Açık: hold planı "reps" değil saniye olmalı; SW bump manuel disiplin. → loop'suz, karar bekliyor
- **L6 dizin/topluluk** — seed.js, script.js, suggest. Sahipsiz; trainer'la konuşmuyor. Köprü işi loop 00'ın içinde; "dizin ürün mü arşiv mi" kararı Damla'da.
- **L7 içerik/büyüme/operasyon** — devlog/linkedin ritüeli işliyor. Sorun: deploy disiplini (limit yakma) + canlıda sıfır ölçüm. → kural: loop başına ≤ 2 deploy

**TEŞHİS ÖZETİ:** Motor (L4) üründen 2 katman önde. 15 Tem krizi ("motor 4700 satır büyüdü, ürün kötü") tam bu: iş L4'te yapılıyordu, kırılma L2/L3'teydi. "Hangi layerda çalışacağımı bilmiyorum" hissinin kaynağı L2'nin loop'suz kalmasıydı — artık loop 00 var. Sıradaki iş L4'ü büyütmek DEĞİL, Grup A'yı bitirmek.

## LOOP SIRASI

### GRUP A — MÜŞTERİ NEDEN BURADA (görünür değer, önce bu)
- [x] **benchmark-01-value.md** — Ana sayfa + coach girişinde net değer cümlesi. "Adam neden burada, ne kullanıyor, ne elde edecek." (L1)
- [ ] **benchmark-02-overlay.md** — Ham iskelet → yumuşak renk-kodlu eklem overlay (doğru=nane, düzelt=vişne). Premium his. (referans/birlikte iterasyon) (L3)
- [ ] **benchmark-03-declutter.md** — Debug metreleri (açı/fps/confidence) müşteriden gizle (`?rec=1` arkası). Fiş videoyu örtmesin. CS-ödevi hissini kaldır. (L3)
- [ ] **benchmark-00-flow.md** — Ürün akışı: directory'yi moves'a birleştir, "just try it" hızlı kamera yolu, koçlanabilirden koça link. Damla'nın 15 Tem kararları #1+#6. (L2)
- [ ] **benchmark-09-marka.md** — Premium marka/landing: H1 = değer (emojisiz), motor demo klibi marquee perdesi, fiş-kanıt bandı, sıfır avı, rakip yan-yana kıyas. 16 Tem marka agent'ı yazdı. (L1)

### GRUP B — SONUÇ GÜVENİLİR Mİ (skor + kapı)
- [ ] **benchmark-04-gate.md** — %60 kabul kapısı: rep sadece accuracy ≥ eşik olunca sayılır. Eşik MoveSpec'te (hareket başına). Filtre ≠ eşik ayrımı korunur.
- [ ] **benchmark-05-scorebadge.md** — 0-100 skorun müşteriye premium sunumu (rozet/count-up, ham sayı değil). "Sonuç" hissi.

### GRUP C — MOTOR GERÇEKTEN ÖĞRENSİN (görünmez sağlamlık)
- [ ] **benchmark-06-coverage.md** — Tüm koçlanabilir REP+HOLD hareketlerine MoveSpec form kuralı (14 değil, hepsi). Stretch'ler "reference".
- [ ] **benchmark-07-dataset.md** — Açık etiketli mocap setleri indir+dönüştür (REHAB24-6, EC3D, MM-Fit) → iskelet JSON, motor formatına. Golden = kapsama boşluğunu Damla doldurur.
- [ ] **benchmark-08-bench.md** — Otonom doğruluk loop'u: bench.cpp seti geçirir → rep-doğruluk/form-precision/recall tablosu repoya. Parametre taraması regresyonla.

**Not:** GRUP A önce biter (Damla kamerada premium his görür), sonra B, en son C. C'nin çıktısı A/B'yi doğrular ama A/B görünür değeri C'den önce teslim eder.
