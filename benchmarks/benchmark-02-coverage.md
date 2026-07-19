# LOOP 02 — KAPSAMA (tüm ev hareketlerini koçla, 14 değil)

STATUS: IN PROGRESS — dalga 1 DONE (69 yeni koçlanabilir hareket, motor 19 → 88)
GRUP: FAZ 1 (motor gerçek olsun) · KATMAN: L4 (CV motoru)

## SORUN (kanıt: data/moves-db.js + coach.html moveSel)
MOVE_DB'de 386 hareket listeleniyor ama motorun gerçek MoveSpec kuralı olan 19
(14 rep + 5 hold). Kullanıcı 386 görüyor, ~19'u koçlanıyor = BAIT-AND-SWITCH.
Damla: "buraya bütün ev hareketlerini kaydedeceğiz, hepsini öğrenmesi lazım. 14 değil."

## 1) ENVANTER (programatik — engine/tools/classify-moves.py)
386 hareket, üç dürüst sınıfa ayrıldı. Belirsiz = "reference" (yanlış koçlamaktansa
dürüst under-claim). Deterministik/sıralı çıktı (sayılar sabitlenebilir):

| sınıf     | sayı | anlam                                   |
|-----------|------|-----------------------------------------|
| rep       | 159  | motor sayabilir (açı salınımı)          |
| hold      |  31  | motor süre tutar + form kapısı          |
| reference | 196  | dürüst etiket, koçlanmaz (stretch/yoga/mobility/balance/unusual) |
| **toplam**| 386  |                                         |

REP aileleri (classify sayımı): raise 55, pushup 41, situp 28, squat 17,
lunge 8, bridge 7, press 1, kickback 1, jack 1.
(Not: classify script "rep" havuzu GENİŞ ölçer — moves-db adları kaba. Motora
gerçekten eklenen alt küme "dalga 1" aşağıda, sentetik testi yazılabilenlerle sınırlı.)

## 2) AİLE ŞABLONU SİSTEMİ (mimari karar)
Motor ZATEN veri-güdümlü bir aile sistemi: `builtinMove(name)` bir MoveSpec döner,
her aile (squat/pushup/lunge...) izlenen eklem zinciri + faz döngüsü + form
kurallarını paylaşır. Elle 200 ayrı kural YOK. Eklenen şey:

- **Varyant tablosu** (`kVariants[]`, coach_engine.cpp): `{varyant adı → {aile base
  adı, dip farkı, tempo taban farkı}}`. VERİ. Yeni hareket = tabloya bir satır.
- **`resolveVariant()`**: ad tabloda ise aile base spec'ini klonlar (eklem zinciri,
  faz makinesi, form kuralları, adaptif ROM OLDUĞU GİBİ gelir), sadece dip bandı +
  tempo parametrelerini oynatır, varyantın kendi adını verir. `builtinMove` en başta
  bunu dener; varyant değilse eski kanonik dallara düşer.
- **Mevcut 14 kanonik hareket TAŞINMADI** — kendi dallarına düşüyor, dokunulmadı;
  yeni sistem yanlarına eklendi (ileride birleştirilebilir).
- **`coachableMoves()`** (yeni API, hpp+cpp+binding): kanonik 19 + varyantları
  {name, base, repBased} olarak döndürür. UI'ın TEK KAYNAĞI (elle liste yok).

Aileler: squat · lunge · pushup · kneeling-pushup · situp/crunch · bridge ·
raise · press · jack · calf (REP) — plank · sideplank · wallsit · hollow (HOLD).

## 3) DALGA 1 — eklenen hareketler (69 varyant, motor 19 → 88)
Her aileden en yaygın hareketler parametrelendi. Her aile için sentetik test
(engine/test.cpp, aile faz döngüsü + hold birikimi doğrulanıyor).

- **squat ailesi (base squat/sumosquat/lunge/glutebridge):** bodyweight squat,
  prisoner squat, sumo squat, jump squat, freehand jump squat, split squats,
  split squat jump, sit squats, banded squat, kneeling squat
- **lunge ailesi:** reverse lunge, crossover reverse lunge, curtsy lunge,
  lateral lunge (sidelunge base), jump lunge, bodyweight walking lunge
- **pushup ailesi:** pushups, push-up wide, feet-elevated, diamond, knee push-up,
  diamond on knees, incline (×3), decline, wall push-up (×2), close-grip wall,
  pike push-up, tempo push-up, eccentric push-up, wide, staggered
- **situp/crunch ailesi:** sit-up, crunches, crunch hands overhead, 3/4 sit-up,
  tuck crunch, reverse crunch, decline crunch, janda sit-up, frog sit-ups, v-up,
  jackknife sit-up
- **raise/press ailesi:** lateral raise, front raise, overhead press, shoulder
  press, military press, pike press, arnold press, push press
- **bridge ailesi:** glute bridge, elevated glute bridge, single(-)leg glute bridge
  (×2), hip thrust off chair, frog pump, pelvic tilt into bridge
- **jack/calf:** star jump, heel raise
- **HOLD aileleri:** forearm plank, high plank, straight arm plank, side plank hold,
  wall sit hold, wall squat hold, hollow body hold

Parametre örnekleri (biomekanik, uydurma değil): incline/wall push-up dip eşiği
sığlaşır (+5/+8°), jump squat/jump lunge tempo tabanı düşer (patlayıcı, ceza yeme),
tempo/eccentric push-up + janda sit-up tempo tabanı yükselir (yavaş şart).

## DALGA-DIŞI (bilerek eklenmedi — NEDENİYLE)
Dürüstlük: motorun tek-eksen faz döngüsü + tek izlenen açısıyla GÜVENİLİR sentetik
poz üretilemeyen / yanlış sayacak hareketler bu dalgaya alınmadı. Sonraki dalga
motor eklem verisi genişleyince (ör. lateral/dönme/asimetri izleme) ele alınır:

- **asimetrik/tek taraflı:** pistol squat, shrimp squat, bulgarian split squat,
  cossack squat, single-arm push-up, archer/typewriter push-up — tek bacak/kol
  izlemesi + telafi ayrımı gerekir, mevcut simetrik faz döngüsü yanlış sayar.
- **lateral/dönme baskın:** oblique/bicycle/side jackknife crunch, spiderman/hindu
  push-up, spider crawl — sagital tek-açı yeterli değil, gövde rotasyonu izlenmiyor.
- **balistik/patlayıcı-yüksek:** clap/plyo push-up, handstand push-up, box jump türevleri
  — kısa hava fazı + zıplama, mevcut tempo/ROM kapısı false-positive üretir.
- **flutter/scissor kick:** sürekli küçük salınım, ayrık "rep" sınırı yok → hold da
  değil rep de değil; dürüstçe reference.
- **RAISE havuzunun çoğu (curl/row/pull-up/fly, ~45):** izlenen eklem base
  armraise'in omuz açısı DEĞİL (curl=dirsek, row=çekiş, pull-up=asılı) → yanlış
  eklemden sayar. Sadece omuz-açısı-güdümlü raise/press varyantları alındı.

## 4) UI DÜRÜSTLÜĞÜ
- **coach.html seçici:** wasm yüklenince `motorMod.coachableMoves()` çağrılıyor
  (js/coach.js `applyEngineCatalog`); eksik varyantlar için `<option>` + `MOVES`
  kaydı (faz kelimeleri AİLE base'inden miras) eklenir. Elle liste çoğaltma yok.
- **moves.html:** her hareket artık "coached" / "coached hold" / "reference"
  etiketi taşır. Koçlanabilir küme motorun GERÇEK kataloğundan gelir (deferred
  wasm import, `requestIdleCallback`; wasm gelene kadar hiçbir şey "coached"
  değil = under-claim). "14 tracks live" kopyası kaldırıldı, dürüst etiket dili.
- Etiket CSS: koçlanan vişne, reference soluk (css/marquee.css .mvtag).

## 5) KANIT
- `bash engine/test.sh` → **233 test** yeşil (önce 213; +20 aile testi), exit 0.
- `bash engine/bench.sh suite --check` → exit **0** (regresyon kapısı GEÇTİ,
  hiçbir mevcut klip taban altına düşmedi).
- Koçlanabilir hareket sayısı (motordan `coachableMoves()`): **19 → 88**
  (rep 14 → 76, hold 5 → 12).
- `esbuild js/coach.js` temiz (0 uyarı); moves.html inline script temiz.
- wasm yeniden derlendi (`bash engine/build.sh`, motor.wasm değişti) → sw v67 → **v68**.

RİSKLER / AÇIK:
- Varyant dip/tempo farkları sentetik + biomekanik gerekçeli; GERÇEK kamerada
  Damla'nın gözüyle spot-check edilmedi (headless işe yaramaz). Dalga 1 doğru
  SAYIYOR (sentetik kanıt) ama gerçek ROM ince ayarı kamera testinde oturur.
- Dalga-dışı ~90+ rep hareketi hâlâ "reference" — asimetri/rotasyon izleme
  motora girmeden dürüst şekilde koçlanamaz (sonraki dalgalar).
- moves.html sw CORE'da değil (önceden de değildi) — offline etiket için wasm
  cache'ine güvenir; kritik değil.

## DONE ÖLÇÜTÜ
- [x] Aile şablonu sistemi kuruldu (kanoniğe dokunmadan).
- [x] Dalga 1: 60+ koçlanabilir hedefi (88 oldu), her aile sentetik testli.
- [x] Stretch/belirsiz "reference" (yanlış vaat yok).
- [x] moves listesi + coach seçici motorun gerçek listesinden, etiketli.
- [ ] Sonraki dalgalar: asimetrik/rotasyonel aileler (motor eklem izleme genişleyince).
- [ ] Damla kamerada dalga 1 spot-check.

## KAPANIŞTA
- Sonraki dalgalar bittiğinde STATUS: DONE, README kutusu. devlog/linkedin halkası.

## LOOP GÜNLÜĞÜ
- Dalga 1: envanter (classify-moves.py) → aile şablonu (kVariants + resolveVariant
  + coachableMoves) → 69 varyant + 20 test → UI dürüstlüğü (coach seçici + moves
  etiketi motordan) → 233 test yeşil, bench exit 0, wasm v68. Commit yok (dalga sürüyor).
