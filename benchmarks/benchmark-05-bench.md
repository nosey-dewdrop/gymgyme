# LOOP 05 — OTONOM DOĞRULUK BENCH'İ (tek komut suite + regresyon kapısı)

STATUS: DONE (16 Tem, opus agent) — tek komutluk suite + kapı canlı, BENCHMARK.md
        gerçek koşuyla dolu, 213 test yeşil, motor koduna dokunulmadı. Commit YOK
        (agent kuralı). Kanıt zinciri aşağıda.
GRUP: C (motor gerçekten öğrensin) — bu loop ÖLÇÜM ALTYAPISI, motor işi değil.
KAYNAK: loop 04 (mmfit ucu) + benchmark-01 dal-C (squat 0→9/10) yolu kanıtlamıştı;
        bu loop o yolu TEK KOMUTA + REGRESYON KAPISINA bağladı.

## SORUN
Doğruluk her seferinde elle ölçülüyordu (üret + clip + göz). Bir motor değişikliği
sessizce bir hareketi bozarsa kimse görmez. Gereken: tek komut → deterministik tablo
+ "taban altına düşme" kapısı.

## NE YAPILDI

### 1. Tek komutluk suite koşucusu
- `bash engine/bench.sh suite` → `engine/tools/bench-suite.sh`'ı çalıştırır
  (bench.sh ince kaldı, tek satır exec).
- Akış: motoru derle → sentetik squat (makeclip, sabit seed) → 7 mmfit hareketi × 3
  segment (squat/pushup/lunge/situp/press/armraise/jumpingjack) deterministik retarget
  → her klibi motordan geçir (One Euro sütunu) → tabloyu `engine/BENCHMARK.md`'ye yaz.
- Tablo: klip / hareket / etiket rep / motor rep / half / reject-dropout / rep-doğruluk %
  + altta özet (toplam doğru rep / toplam etiket → genel %). **Tarih YOK** (git tarihler)
  → diff anlamlı.

### 2. Regresyon kapısı
- `bash engine/bench.sh suite --check` → aynı tablo + `engine/bench-baselines.txt`
  kontrolü. Her tabanlı klip için `motor rep < taban` ise **exit 1** + hangi klip
  düştü yazar.
- Taban dosyası (klip başına MIN rep) BUGÜNKÜ GERÇEK değerlerden yazıldı:
  synth 8, squat 9×3, lunge 6×3, pushup 0/1/0. Yükseltmek gelecek işlerin görevi,
  DÜŞÜRMEK yasak (yorumda yazılı).
- **Taban mantığı:** kapıya sadece asıl izlenen hareketler (squat/lunge/pushup/sentetik)
  girdi. press/situp/armraise/jumpingjack tabana KONMADI — hepsi şu an 0 sayıyor,
  kök retarget/ROM sıkışması (benchmark-04 teşhisi, motor eşiği değil); kapıya 0-taban
  koymak gürültü olur. Tabloda görünüyorlar (görünürlük için), kapıda yoklar.

### 3. test.sh'a BAĞLANMADI (test hızlı kalır)
- Suite ~15 mmfit retarget + derleme koşuyor, test.sh milisaniyelik kalmalı.
- `engine/build.sh` sonuna tek satır hatırlatma eklendi:
  `"run 'bash engine/bench.sh suite --check' before push (regresyon kapisi)"`.

### 4. Determinizm
- mmfit klipleri: `mmfit2ggclip.py` zaten deterministik (bbox normalize, jitter yok);
  aynı npy+csv → aynı ggclip doğrulandı.
- sentetik: `makeclip` sabit seed 42 (bench.cpp `makeSynth(...,42)`).
- `LC_ALL=C` export edildi → ondalık NOKTA (locale virgülü değil) + awk locale-bağımsız.
- KANIT: iki ardışık `suite` koşusu byte-byte aynı BENCHMARK.md üretti (`diff` temiz).

### 5. BENCHMARK.md gerçek koşuyla dolu (uydurma yok)
Aşağıdaki tablo `bash engine/bench.sh suite` gerçek çıktısı.

## TABLO (gerçek koşu)

| klip | hareket | etiket | motor | half | rej/drop | doğruluk % |
|------|---------|-------:|------:|-----:|---------:|-----------:|
| synth_squat | squat | 8 | 8 | 0 | 0 | 100.0 |
| squats_0/1/2 | squat | 10 | 9 | 0 | 0 | 90.0 |
| pushups_0 | pushup | 11 | 0 | 8 | 0 | 0.0 |
| pushups_1 | pushup | 10 | 1 | 5 | 0 | 10.0 |
| pushups_2 | pushup | 10 | 0 | 4 | 0 | 0.0 |
| lunges_0/1/2 | lunge | 10 | 6 | 0 | 0 | 60.0 |
| situps_0/1/2 | situp | 10 | 0 | 0 | 0 | 0.0 |
| press_0/1/2 | press | 10/10/9 | 0 | 0 | 0 | 0.0 |
| armraise_0/1/2 | armraise | 10 | 0 | 0 | 0 | 0.0 |
| jumpingjack_0/1/2 | jumpingjack | 11/11/10 | 0 | 0 | 0 | 0.0 |

**Özet:** 54 / 220 rep doğru → genel rep-doğruluk **%24.5** (press/situp/armraise/
jumpingjack retarget kırığı bu oranı bastırıyor; squat/lunge asıl motor sinyali).

## KANIT (gerçek komut + çıktı)
- `bash engine/bench.sh suite` → yukarıdaki tablo + BENCHMARK.md yazıldı.
- Determinizm: iki koşu → `diff /tmp/run1.md /tmp/run2.md` **temiz** (byte-byte aynı).
- Kapı GEÇEN hali: `suite --check` → tüm klipler "ok", **exit 0**.
- Kapı DÜŞEN hali (ısırma kanıtı): squats_0 tabanı geçici 9→11 yapıldı →
  `DUSTU squats_0: motor 9 < taban 11` + **exit 1**. Sonra taban 9'a geri konuldu,
  tekrar koşu **exit 0**. (Kapı gerçekten ısırıyor, dekoratif değil.)
- `bash engine/test.sh` → **213 ok** (motor koduna dokunulmadı, hiçbir test kırılmadı).
- Sözdizimi: `bash -n` build.sh / bench.sh / bench-suite.sh temiz.
- Ham mmfit verisi hâlâ gitignore (`git check-ignore` doğruladı) → repo şişmedi.
- Yeni dosyalar: `engine/BENCHMARK.md`, `engine/bench-baselines.txt`,
  `engine/tools/bench-suite.sh` (üçü de commit edilebilir, ignore değil).
  Değişen: `engine/bench.sh` (suite exec satırı), `engine/build.sh` (hatırlatma).

## GELECEK GENİŞLEME (tabana nasıl girer)
- **Kalan mmfit segmentleri (w01+):** yeni workout npy+csv indir → aynı retarget
  deseni → suite'in `for ex ... for s` döngüsüne dahil (dosya adı `w01_squats_0`
  gibi id ile). Etiket satırdan otomatik okunuyor, tabloya kendiliğinden düşer;
  tabana koymak için tek satır `bench-baselines.txt`'e eklenir.
- **EC3D / REHAB24-6:** her set için küçük `*2ggclip.py` adaptörü (mmfit deseni),
  ürettikleri ggclip'ler suite'e ayrı bir kaynak bloğu olarak eklenir. Retarget
  düzelince (motor işi) o hareketlerin tabanı 0'dan gerçek değere yükseltilir.
- **Damla golden klipleri:** kamera → iskelet JSON kaydı (ggclip) → `engine/data/golden/`
  altına, suite golden bloğu olarak okur; etiket Damla'nın saydığı rep. Kapsama
  boşluğundaki hareketler (mountain climber, russian twist...) böyle tabana girer.
- **Motor iyileştikçe:** press/situp/armraise/jumpingjack ROM sıkışması çözülünce
  (loop 01 işi) tabloda 0 → gerçek değere çıkar; o değer `bench-baselines.txt`'e
  taban olarak yazılır → bir daha düşemez. Kapı büyüdükçe motor kilitlenir.

## RİSKLER / AÇIK
- Genel %24.5 düşük görünüyor ama yanıltıcı: retarget-kırık 4 hareket (12 segment,
  hepsi 0) ortalamayı bastırıyor. Asıl motor sinyali squat %90 + lunge %60. Retarget
  düzeltmesi (loop 01/07) bu oranı hızla yükseltir; bench oranı o işi görünür yapıyor.
- Suite macOS sistem bash 3.2 uyumlu yazıldı (associative array YOK, satır-tabanlı
  tablo + `LC_ALL=C`). Homebrew bash gerekmiyor; diğer scriptlerle aynı ortam.
- Kapı yalnızca REP sayısını koruyor (form skoru / precision-recall değil). Form
  regresyonu ayrı bir metrik ister (gelecek: golden form-etiketli klipler).
- Ham veri lokal + gitignore; başka makinede suite koşmak için w00 npy+csv tekrar
  indirilmeli (mmfit2ggclip.py yolu benchmark-04'te belgeli). Klip yoksa suite o
  hareketleri atlar, sentetik + var olanlarla yine koşar.
