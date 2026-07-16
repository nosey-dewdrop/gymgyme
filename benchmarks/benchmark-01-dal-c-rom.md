# benchmark-01 / dal C — ROM sıkışması: gerçek veride motor görmüyor

STATUS: DONE (16 Tem, opus agent) — MM-Fit squat 0→9/10, sentetik 8/8 KALDI, 213 test yeşil, wasm v67.
        Commit YOK (agent kuralı). Kanıt zinciri aşağıda.
ANA LOOP: benchmark-01-algilama.md
KAYNAK: loop 04 mmfit ucu (16 Tem) — gerçek veri motoru İLK KEZ yeniden üretilebilir şekilde düşürdü.

## SORUN
MM-Fit gerçek squat: etiket 10 rep, motor 0. Sentetik squat: 8/8. Teşhis: monoküler lifting gürültüsü + projeksiyon ROM'u sıkıştırıyor (diz açısı 92°-120° bandında kalıyor, ~160° "top" eşiği hiç tutmuyor) → top→bottom→top döngüsü başlamıyor → SESSİZ SIFIR. Pushup hep half, lunge yarı sayıyor — aynı kök. Damla'nın "kamera hareket algılamıyor / beni roblox gibi görüyor" şikayetiyle büyük ihtimalle aynı aile: gerçek dünya iskeleti sentetik kadar temiz değil, eşikler mutlak açıya çakılı.

## HEDEF
Motor mutlak açı eşiğine değil, KİŞİNİN O SEANSTA GÖSTERDİĞİ harekete göre faz görsün. MM-Fit squat ≥8/10 sayarken sentetik 8/8 KALIR, 204 test yeşil KALIR.

## DONE
- bench tablosunda mmfit squat/pushup/lunge motor sayıları etikete yaklaşır (squat ≥8/10)
- sentetik regresyon bozulmaz, 204+ test yeşil
- değişiklik açıklanabilir: motor neyi neden kabul ettiğini söyleyebilir

## ÇÖZÜM GÜNLÜĞÜ (16 Tem — opus agent)

### KÖK (teşhis rafine edildi)
benchmark-04 "diz 92-120° bandında" demişti; motorun İZLEDİĞİ açı (L/R'den net olan)
aslında squat klibinde **36-96.5° (ort 64°)**. Kritik nokta: kişinin "üst/dik" duruşu
sadece **~96.5°** görünüyor, spec.topAngle **155°**'ye HİÇ çıkmıyor. Eski adaptif KOD
sadece DİP eşiğini uyarlıyordu; ÜST eşik `min(spec.topAngle, ...)` ile spec tavanına
bağlıydı ve `topLive_ = max(bottomLive_+10, ...)` onu ~130°'ye itiyordu. Sinyal 96'yı
geçmediği için faz Bottom'a girip **bir daha Top'a dönemiyor** → döngü kapanmıyor →
SESSİZ SIFIR. Ayrıca `spec.bottomAngle=120` TABAN'ı kişinin max'ından (96) yüksek
olunca kişi kalıcı Bottom fazına kilitleniyor, faz-kapılı `topRest_` öğrenmesi DONUYORDU.

### YAKLAŞIM (neden percentile-benzeri band / neden bu pencere)
- **İki ayrı üst-uç izleyici** (kasıtlı ayrım, tek değişkenle çözülemiyordu):
  1. `topRest_` = ESKİ semantik, YALNIZ Top fazında + yavaş sönümlü. "Rahat duruş"
     açısı; SIKIŞMAMIŞ (sağlıklı kamera) yolun dip eşiğini (adaptiveDrop) sürer.
     Sığ-ama-gerçek squat testinin dayandığı davranış — hiç değişmedi.
  2. `obsHigh_`/`obsLow_` = per-KARE gözlenen band uçları (FAZ BAĞIMSIZ, yeni-uca hızlı
     atla + yavaş sön). Faz Bottom'a kilitlense bile band öğrenilmeye devam eder →
     donma tuzağı kapanır. Bu, ROM-sıkışması yolunun eşiklerini sürer.
- **Sıkışma tespiti**: `obsHigh_ < spec.topAngle - 15°` → gerçek hastalık (üst açı
  düz-duruşa hiç ulaşmıyor). Sıkışmışsa eşikler tamamen gözlenen bandın İÇİNE iner
  (`bottom = obsHigh - 0.55*range`, `top = obsHigh - 0.28*range` → aralarında
  histerezis, mutlak dereceye çakılı değil). Sağlıklı ROM'da (obsHigh≈spec.top)
  ESKİ mutlak yol AYNEN kalır → geniş-ROM davranışı değişmez.
- **Pencere/kalibrasyon**: ayrı sabit pencere yok; band ilk 1-2 tekrarda dolar
  (ilk tekrarlar feda edilebilir, sonrası oturur — bu yüzden 10 etikette 9 sayıyor:
  ilk tekrar bandı kurarken kaçıyor). Motorun mevcut kalibrasyon penceresiyle
  çakışmıyor (o kemik-oranı öğrenmesi, bu faz-band öğrenmesi — ayrı eksenler).

### FİLTRE ≠ EŞİK ≠ FORM-KAPISI ayrımı KORUNDU (talep 2)
- One Euro FİLTRE'ye dokunulmadı (sinyal temizliği).
- %60 `acceptPct` KABUL KAPISI'na dokunulmadı (kabul kararı — reject/half yolu aynı).
- Anatomik FORM KURALLARI (TorsoLean/KneeValgus/HipSag, mutlak derece + world geometri)
  değişmedi; skor DÜRÜSTLÜĞÜ mutlak referansta kalıyor. Adaptifleşen SADECE faz tespiti
  (top/bottom eşiği + depth). Yarım-rep `deepEnough`: referans aktif topTh, derinlik
  MİKTARI spec ROM'undan sabit → adaptif band "yarım" tanımını kaydırmaz (2° kıpırtı
  rep sayılmaz), sıkışmış veride topTh'a göre ölçülür (155'e takılıp her kareyi yarım
  saymaz — eski kod öyle yapardı).

### AÇIKLANABİLİRLİK (talep 3)
Reading'e `activeTopTh`, `activeBottomTh`, `adaptiveActive` eklendi → bindings.cpp
köprüsü + coach.js rec teşhis paneli ("angle X° · top≥.. bottom≤.. (adaptive ROM|fixed)").
Motor artık "hangi eşikleri neden kullandığını" söylüyor.

### PUSHUP (bonus, form skoru BOZULMADI)
pushup'a da `adaptiveBottom` açıldı (aynı ROM-sıkışması kökü — dirsek açısı perspektifle
sıkışır). AMA pushup'ın sıkışması TOP'ta değil BOTTOM'ta (üst 156° tutuyor, dip 108'de
kalıyor). Top-sıkışma kapısı bunu tam yakalamıyor → pushup 0→(0/1/0 rep, half-detection
iyileşti). Zorlamak için bottom-sıkışma kapısı eklemek sentetik yarım-rep testleriyle
çakışıyordu; form skorunu bozmadan güvenli tarafta bırakıldı. Squat hedefi (asıl iş)
tutuyor; pushup/lunge iyileşme bonus olarak raporlandı.

### ÖNCE / SONRA (one euro sütunu, `bench.sh clip`)
| etiket        | eski motor | yeni motor | half | notlar                     |
|---------------|-----------:|-----------:|-----:|----------------------------|
| squat set 0   | 0/10       | **9/10**   | 0    | HEDEF ≥8 tuttu             |
| squat set 1   | 0/10       | **9/10**   | 0    |                            |
| squat set 2   | 0/10       | **9/10**   | 0    |                            |
| pushup set 0  | 0 (11 half)| 0 (8 half) | 8    | bottom-sıkışma, bonus      |
| pushup set 1  | 0 (10 half)| 1 (5 half) | 5    |                            |
| pushup set 2  | 0 (7 half) | 0 (4 half) | 4    |                            |
| lunge set 0   | 5/10       | **6/10**   | 0    | tek-bacak seçimi ayrı iş   |
| lunge set 1   | 5/10       | **6/10**   | 0    |                            |
| lunge set 2   | 5/10       | **6/10**   | 0    |                            |
| SENTETİK squat| 8/8        | **8/8**    | 0    | regresyon YOK (kanıt)      |

### KANIT (gerçek komut çıktısı)
- `bash engine/test.sh` → **213 ok, 0 fail** (baseline 204; +9 yeni adaptif-ROM testi,
  1 test güncellendi: pushup artık adaptif). Yeni testler: sıkışmış-ROM band döngüyü
  başlatır + sayar; adaptiveActive=true + activeTopTh<spec.top; 2° kıpırtı rep sayılmaz;
  geniş-ROM tam-açılım squat hâlâ 8/8 + eşikler saptırılmaz.
- `bash engine/bench.sh makeclip /tmp/synth.ggclip && bash engine/bench.sh clip ...` → 8/8.
- `python3 engine/tools/mmfit2ggclip.py ... ` (9 klip) + `bash engine/bench.sh clip` → yukarıdaki tablo.
- `bash engine/build.sh` → wasm yeniden derlendi (emcc var), motor.wasm md5 değişti
  (fa00e7b1→73710877) → sw.js v66→**v67** bump edildi.

### RİSKLER / AÇIK
- Lunge 6/10: tek-bacak dönüşümlü lunge'ta motor tek bacağın primary açısını izliyor,
  "hangi bacak/perspektif" seçimi ayrı bir iş (bu benchmark'ın kapsamı değil).
- Pushup bottom-sıkışması çözülmedi (yukarıda neden). Ayrı bir gate ister; sentetik
  testlerle güvenli birlikte yaşaması ek tasarım.
- İlk tekrar band-kurulumuna feda ediliyor (10→9). Canlı seansta ilk rep'i saymamak
  kabul edilebilir; istenirse ilk tekrarın açısıyla band ön-tohumlanabilir (gelecek iş).
- Gerçek kamerada DOĞRULAMA Damla'da (headless kamera testi yararsız): rec panelinde
  "adaptive ROM" görünüp squat'ın gerçekten sayılması teyit edilecek.
