# gymgyme — DECISIONS

Verilmiş kararlar. Aynı soru iki kez sorulmaz (PROTOKOL §5). Format:
tarih · faz · başlık / Durum / Karar / Gerekçe / Etki.

---

## 19 Tem · FAZ 2 · engine-core: coach.js'e dokunmama
Durum: canlı kamera index'e bağlanacaktı; ortak motor mantığı gerekiyordu.
Karar: js/engine-core.js ortak modül yazıldı (mediapipe pose loader + wasm
motor + writePosesToHeap). index kullanıyor. coach.js'e DOKUNULMADI.
Gerekçe: coach.js canlı, kırılgan, 1500+ satır; recovery+mesh+calibration
state iç içe, makePose iki yerde. engine-core aynı mantığı bağımsız barındırıyor,
"ortak parça ayrı modülde" talebini karşılıyor. coach'u zorla bağlamak
"davranış birebir aynı" garantisini bozardı (Damla onayı: "coach'a dokunma").
Etki: küçük kod tekrarı (pose ladder ~15 satır) iki yerde. Değişmez #9 korundu.

## 19 Tem · FAZ 2 · I3 worth+how tam birleştirilmedi
Durum: HANDOFF I3 "worth ve how'u tek bölümde birleştir" diyordu.
Karar: iki bölüm ayrı bırakıldı AMA how'a band-lila (farklı zemin) verildi +
araya "real output" mono bloğu kondu, ritim kırıldı.
Gerekçe: uygulamada worth ("neden değer") ve how ("nasıl çalışır") farklı
sorulara cevap veriyor; ritim kırma "aynı şeyi iki kez" hissini çözüyor.
Etki: I3 KISMİ. Damla'ya faz sonu sorusu açıldı (tam birleştirme mi?).

## 19 Tem · FAZ 2 · kart sistemi radius token'ı bekliyor
Durum: kart sistemi (Damla spec'i) 16px radius ile eklendi, ama hardcoded.
Karar: geçici hardcoded 16px; PROTOKOL §1.4 radius token sistemi (--r-sm/
--r/--r-lg) FAZ 3 başında kurulacak, sonra tokenlaştırılacak.
Gerekçe: PROTOKOL FAZ 2'den SONRA geldi; radius sistemini geriye dönük
uygulamak FAZ 3 açılış işi.
Etki: gate.sh radius kapısı FAZ 3 başına kadar kırmızı (bilinen borç).

## 19 Tem · FAZ 3 · radius sistemi PROTOKOL kazandı (10/16/20)
Durum: PROTOKOL §1.4 radius'u --r-sm:10px --r:16px --r-lg:20px yeniden
tanımladı; site.css her yerde --r:3px kullanıyordu.
Karar: PROTOKOL kazanır. --r:3px→16px, --r-sm:10px eklendi, --r-lg:20px
eklendi. Tüm site yumuşak köşeye geçti (nav/buton/input 10px, kart/blok
16px, büyük panel 20px). Damla onayladı ("PROTOKOL kazanır").
Gerekçe: PROTOKOL en yeni sözleşme; §1.4 "önceki fazların görünümünü
değiştirmesi istenen sonuçtur" diyor.
Etki: FAZ 0/1/2 görünümü değişti (keskin→yumuşak). gate.sh radius yeşil.

## 19 Tem · FAZ 2 · onaylandı
Durum: FAZ 2 (index nokta bulutu + canlı sayaç + kamera) deploy'da.
Karar: Damla "onaylıyorum, FAZ 3'e geç" dedi. I3 (worth+how) ritim-kırma
haliyle kabul; tam birleştirme yapılmadı, itiraz gelmedi.
Gerekçe: canlı gösterildi, kabul edildi.
Etki: FAZ 3 açıldı.

## 19 Tem · FAZ 4 · kartta "mono hedef" verisi yok
Durum: HANDOFF M3 "her kartta hangi eklem + mono hedef" istiyor. MOVE_DB
sadece {kategori: [isim]} tutuyor — eklem grubu VAR (kategori), ama
per-hareket "mono hedef" (reps/açı) verisi YOK.
Karar: kartta eklem grubu (kategori) + coached/reference + kalp gösterildi.
"Mono hedef" gösterilmedi çünkü veri yok; uydurma yasak (§4).
Gerekçe: olmayan veriyi uydurmak dürüstlük ihlali (STRATEJI: coached ölçüm
sonucu). Hedef değerleri motor spec'inden FAZ 8'de (spec DSL) gelecek.
Etki: M3 "mono hedef" kısmı AÇIK, FAZ 8'de kapanır. Kapsam küçülmedi —
veri üretilince eklenecek (§5b: yapılamayan "açık" yazıldı).

## 19 Tem · FAZ 4 · yearwall nokta yoğunluğu (github rampası kalktı)
Durum: MP1 "less▪▪▪more" GitHub katkı grafiği kopyasıydı (lv1-4 yeşil rampa).
Karar: legend kaldırıldı; lv1-4 tek pink tonuna bağlandı (yoğunluk = opaklık
.5/.75/1 + pink-soft), GitHub yeşil rampası gitti. JS lv class'larını üretmeye
devam ediyor (dokunulmadı), sadece CSS anlamı değişti.
Gerekçe: PROTOKOL reddedilenler + MP1; nokta motifi tutarlılığı.
Etki: MP1 kapandı. Geri alınır: legend geri + lv CSS eski rampaya.
