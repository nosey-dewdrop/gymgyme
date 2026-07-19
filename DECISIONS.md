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

## 19 Tem · FAZ 5 · patch fotoğraf sırası (zevk kararı → ajan)
Durum: 3 foto, hangisi hangi kolonda/sırada belirsizdi (eski "zevk kararı").
Karar: sol ray = 5289_crop (tested on herself, r2) + 5263 (built the engine, r6);
sağ ray = 5275 (damla bilkent cs, r4). Dönüşümlü, aynı satırda iki yok.
Gerekçe: PROTOKOL §4 zevk kararı ajana; dengeli dağılım (2 sol 1 sağ, hizalar
çakışmıyor). Damla itiraz ederse foto/sıra değişir (geri alınır).
Etki: P2 kapandı.

## 19 Tem · FAZ 7 · node motor target (canlı motora dokunmadan)
Durum: regresyon süiti motoru node'da koşmalı; motor.js web-only derlenmiş
(-sENVIRONMENT=web), node'da yüklenmiyor (fetch abort).
Karar: engine/build-node.sh eklendi — AYNI kaynak (coach_engine.cpp+bindings.cpp),
-sENVIRONMENT=node, ayrı çıktı motor.node.mjs/.wasm. Canlı motor.js/.wasm HİÇ
değişmedi. Süit bu node target'ı kullanır.
Gerekçe: değişmez #9 (canlı motora dokunma) + KIRMIZI #2 (motoru bozma) korunur;
test motoru = üretim motoru (birebir kaynak), sadece ortam bayrağı farklı.
Etki: motor.node.* gitignore (test artefaktı, validate build eder). Geri alınır:
build-node.sh sil.

## 19 Tem · FAZ 7 · sentetik golden = liveness guard (accuracy değil)
Durum: korpus boş (klip API key bekliyor). Regresyon süiti bir şey ölçemiyor.
Karar: golden-synth.mjs — sentetik 5-squat landmark serisi motora verilir,
"motor ≥3 sayar" guard'ı. Bu LIVENESS + negatif test (motor bozulursa 0 sayar,
kırmızı), ACCURACY DEĞİL. Gerçek doğruluk korpustan gelecek.
Gerekçe: süit boş korpusla da motoru koruyabilmeli (değişmez #11). Sentetik
sürücü idealize, gerçek squat landmark'ı farklı → tam N iddia edilmedi.
Etki: X10 kapı guard var, gerçek recall/precision korpus dolunca (FAZ 7 insan işi).
Kapsam küçülmedi — accuracy ölçümü korpusa bağlı, süit hazır bekliyor.

## 19 Tem · FAZ 7 · korpus kapalı (gitignore)
Durum: STRATEJI "korpus açık değil, sayılar yayınlanır klipler değil".
Karar: corpus/ gitignore'da. Klipler + landmark + lisans lokalde, repoda değil.
Gerekçe: STRATEJI §4.2 + değişmez #14 (lisans kaydı klip yanında, lokal).
Etki: baseline.json + süit kodu tracked; klipler değil.

## 19 Tem · FAZ 7 · headless auto-label (video seek → play-based)
Durum: labeler tarayıcı aracı, ama ön-etiketleme AJAN İŞİ (YOL-HARITASI). Node'da
mediapipe yok → Playwright headless chromium gerekti. İlk deneme video seek
(currentTime++) uzun klipte TAKILDI (720 seek, event kırılgan).
Karar: tools/auto-label.mjs — tarayıcı SADECE landmark çıkarır (play-based,
requestVideoFrameCallback, 10fps örnekleme, 40s/klip cap); motor tahmini NODE
tarafında (motor.node.mjs). Web motor + headless chromium'da TextDecoder/
resizable-ArrayBuffer bug'ı vardı → motoru tarayıcıdan çıkardım, tek motor
node target. Playwright tooling dep (package.json, node_modules ignore).
Gerçek bulgu: seek yaklaşımı 10+ dk takıldı, play-based 40 klibi ~8 dk işledi.
Etki: X28 ön-etiketleme çalışıyor. Geri alınır: auto-label.mjs sil.

## 19 Tem · FAZ 7 · GERÇEK BULGU: motor vahşi klipte az sayıyor
Durum: 40 klip (5 hareket) motordan geçti. squat 8 klipten 2'sinde saydı,
push-up 0/8, glute-bridge/lunge/plank yüksek (ama bunlar 0-rep ya da hold).
Bulgu: motor belirli mesafe/açı için kalibre; Pexels klipleri çeşitli
(yandan/önden, uzak/yakın, kısmi) → yakalama düşük.
Karar: bu bir motor HATASI değil, FAZ 9'un HEDEFİ (görüş açısı sınıflandırma,
antropometrik normalizasyon). Regresyon süiti tam bunu ölçmek için var.
baseline.json'a dürüstçe yazıldı (squat recall 0.75 ama motorCountedClips 2/8).
NOT: label'lar şu an AUTO (motor kendi tahmini) → recall/precision "tutarlılık"
ölçüyor, GERÇEK doğruluk DEĞİL. İnsan onayı (labeler.html) sonrası gerçek olur.
Etki: FAZ 9 baseline'ı bu. Kapsam küçülmedi — gerçek doğruluk insan onayına bağlı.

## 19 Tem · TASARIM v2 · palet + değişmez değişikliği (insan)
Durum: Damla yeni palet + kurallar emretti (FAZ 8 spec DSL askıya alındı).
Karar (İNSAN değiştirdi, §5 gereği geçerli): --lila #7A5BB0→#C9A9D9, +--lila-deep
#8E6BA8, --lila-soft #EDE6F7→#F0E6F5. Buton lila→--ink (lila asla buton zemini).
Aksan metin→--lila-deep. Koyu kutu/terminal YASAK. PROTOKOL §1.3 + gate ALLOWED
güncellendi. Q&A akordeon→açık blok, dizin index'ten kalkar (directory.html).
Gerekçe: değişmez sahibi insan; yeni tasarım yönü.
Etki: FAZ 0-6 görünümü değişir (istenen). FAZ 8 spec DSL sonraki tura.
Geri alınır: git revert (bu tur commit'leri).

## 19 Tem · TASARIM v2 · coach kamera panelleri ink kalır (video alanı)
Durum: "koyu kutu yasak" ama .panel (kamera video) + .onb-panel (çerçeve önizleme) ink.
Karar: bunlar DEKORATİF kutu değil, canlı kamera GÖRÜNTÜ alanı (video zaten koyu). ink kaldı.
index'te koyu kutu 0 (asıl hedef terminal'di, kalktı). Damla itiraz ederse wash yapılır.
Gerekçe: video zemini ink mantıklı; dekoratif koyu kutu (term/output) kaldırıldı.
Etki: koyu kutu kuralı = dekoratif kutulara; kamera alanları istisna.

## 19 Tem · TASARIM v2 · misafir deneme = tek localStorage flag
Durum: hesapsız 1 workout, takip YOK.
Karar: gg-guest-used localStorage flag; temizlenirse sıfırlanır (kabul, parmak izi yok).
Tam motor çalışır, sadece sonuç kaydedilmez (coach.js zaten sadece signed-in sync eder).
Gerekçe: KVKK/gizlilik — fingerprint yok, tek flag; Damla'nın dili (sert değil).
Etki: X-membership. Geri alınır: gate + flag kaldır.
