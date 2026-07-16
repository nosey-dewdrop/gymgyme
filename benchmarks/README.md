# gymgyme — BENCHMARK LOOP DÜZENİ

Bu klasör her sorunu **ayrı bir loop** olarak tutar. Kural:
- **Bir sekme = bir loop = bir `benchmark-XX.md`.**
- Loop o dosyadaki DONE ölçütlerine ulaşınca **kapanır**, pencere **temizlenir**, yeni sekme **temiz** (clear context) başlar, sonraki dosyayı açar.
- Her loop tek konuya odaklıdır — context şişmez, iş tıkır tıkır ilerler.
- Her loop `STATUS: TODO | IN PROGRESS | DONE` taşır. Yeni sekme açılınca önce bu README'ye bakılır, ilk `TODO/IN PROGRESS` olan loop'a girilir.

## DAL KURALI (Damla, 16 Tem — proje parmak izi)
Loop içinde beklenmedik bir SORUN çıkarsa ana loop şişirilmez: **dala ayrılınır**. Dal = kendi mini dosyası (`benchmark-XX-dal-konu.md`), tek konuya odaklı, kendi DONE ölçütü var, **dal kendi başına teslim eder**, sonra ana loop kaldığı yerden devam eder. Bu loop+dal düzeni bizim ÖZGÜN desenimiz — moat, kopyalanamaz proje parmak izi. Her dalın sonucu dev-log'a (patch notes / DX içeriği) düşer: "şu loop'ta şu sorun çıktı, dala ayrıldık, dal bunu teslim etti."
Dallar AYRI AGENT'lara ayrı promptlarla verilir (16 Tem): loop koşarken sorun/iş parçası çıkınca ayrı test/loop/prompt yazılır, agent'lar kendi dallarını bitirir; loop'un agent'ları bitince pencere CLEAR, sıradaki işe temiz geçilir.

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

- **L1 marka/landing** — index.html, styles.css, marquee, FAQ. Sorun: H1 metafor değer değil, görsel kanıt (demo klip) yok, "(0)" sayaçları flop sinyali. → loop 00-value (DONE), **loop 08-marka**
- **L2 ürün akışı/nav** — topbar, sayfa geçişleri, iki hareket kaynağı (seed.js dizini vs MOVE_DB). Sorun: dizin+trainer köprüsüz yarışıyor, "just try it" yolu yok. EN KRİTİK LOOP'SUZ KATMANDI. → **loop 07-flow**
- **L3 koç deneyimi UI** — coach.html, js/coach.js (1479 satır tek dosya), css/coach.css. Sorun: debug paneli müşteriye açık, fiş videoyu örtüyor. → loop 06-declutter, 09-scorebadge, 10-overlay (kod yerelde hazır)
- **L4 CV motoru doğruluk** — engine/ (16 dosya, coach_engine.cpp 1744 satır, 104+ test). En olgun katman AMA %60 kapısı yok, 386 vitrin / ~14 kurallı hareket, doğruluk iddiası ölçümsüz. → loop 01-algilama, 02-coverage, 03-gate, 04-dataset, 05-bench
- **L5 veri/backend** — Supabase, auth, sw.js, KVKK bandı. En sağlam katman. Açık: hold planı "reps" değil saniye olmalı; SW bump manuel disiplin. → loop'suz, karar bekliyor
- **L6 dizin/topluluk** — seed.js, script.js, suggest. Sahipsiz; trainer'la konuşmuyor. Köprü işi loop 07-flow'un içinde; "dizin ürün mü arşiv mi" kararı Damla'da.
- **L7 içerik/büyüme/operasyon** — devlog/linkedin ritüeli işliyor. Sorun: deploy disiplini (limit yakma) + canlıda sıfır ölçüm. → kural: loop başına ≤ 2 deploy

**TEŞHİS ÖZETİ:** Motor (L4) üründen 2 katman önde. 15 Tem krizi ("motor 4700 satır büyüdü, ürün kötü") tam bu: iş L4'te yapılıyordu, kırılma L2/L3'teydi. "Hangi layerda çalışacağımı bilmiyorum" hissinin kaynağı L2'nin loop'suz kalmasıydı — artık loop 07-flow var. 16 Tem güncellemesi: Damla kararıyla sıra YETENEK ÖNCE (motor gerçekten görsün + kapsama), cila sonra — çünkü kamera hareket algılamıyor, en temel kusur orada.

## LOOP SIRASI (16 Tem YENİDEN NUMARALANDI — numara = çalışma sırası)
Damla kuralı: "kamera hareketleri görmüyo, 14 hareket sınırı var, loop bunları kapatmaya yönelik tut." YETENEK ÖNCE, CİLA SONRA. Eski grup düzeni ve eski numaralar İPTAL.

- [x] **benchmark-00-value.md** — DONE. Ana sayfa + coach girişinde net değer cümlesi. (L1)

### FAZ 1 — MOTOR GERÇEK OLSUN
- [ ] **benchmark-01-algilama.md** — BİR NUMARALI KUSUR: kamera hareketi GERÇEKTEN görsün. Kopuk halka kayıtla teşhis, red nedeni görünür, sessiz sıfır yok. (L4)
- [ ] **benchmark-02-coverage.md** — 14 sınırı kalkar: tüm REP+HOLD hareketlerine MoveSpec kuralı (~200), stretch'ler dürüstçe "reference". (L4)
- [ ] **benchmark-03-gate.md** — %60 kabul kapısı: rep sadece accuracy ≥ eşik olunca sayılır, eşik MoveSpec'te. Filtre ≠ eşik ayrımı korunur. (L4)
- [ ] **benchmark-04-dataset.md** — Açık etiketli mocap setleri (REHAB24-6, EC3D, MM-Fit) indir + motor formatına dönüştür. Golden boşluğunu Damla doldurur. (L4)
- [ ] **benchmark-05-bench.md** — Otonom doğruluk loop'u: bench.cpp seti geçirir, rep-doğruluk/precision/recall tablosu repoya, regresyonlu. (L4)

### FAZ 2 — GÖRÜNÜR CİLA
- [ ] **benchmark-06-declutter.md** — Debug metreleri müşteriden gizle (`?rec=1` arkası), fiş videoyu örtmesin, CS-ödevi hissi biter. (L3)
- [ ] **benchmark-07-flow.md** — Directory moves'a birleşir, "just try it" hızlı kamera yolu, koçlanabilirden koça link. Damla'nın 15 Tem kararları #1+#6. (L2)
- [ ] **benchmark-08-marka.md** — Premium landing. KUZEY YILDIZI: BetterMe/Headspace "iyi bir yerdeyim" hissi; H1 = değer (emojisiz), "(0)" sayaçları ölür, patch notes / dev-log köşesi (fiş-kanıt bandı RED), renk/dil değişmez, generic/ortada-istif YASAK, mockup onaysız kod yok. (L1)
- [ ] **benchmark-09-scorebadge.md** — 0-100 skorun premium sunumu (rozet/count-up). "Sonuç" hissi. (L3)
- [ ] **benchmark-10-overlay.md** — Vişne köşe-kutu + renk kod (iyi=nane, düzelt=vişne). Kod YERELDE hazır; Damla istemeden gösterilmez, sırası gelince canlıya. (L3)
