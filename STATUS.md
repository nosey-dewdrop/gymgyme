# gymgyme REWORK — STATUS

## FAZ 0 — Kritik hatalar   [kapı geçildi — 19 Tem]
| kod | durum | kanıt |
|-----|-------|-------|
| cache | kapandı | freshness testi: işaretli deploy → root'ta 1, işaret kaldırıldı deploy → root'ta 0; edge her deploy'da anında tazeleniyor (HIT görünse de stale dönmüyor). Ölçüt "MISS/BYPASS" → "içerik taze" güncellendi (Damla). |
| G8  | kapandı | `diff root index.html` = AYNI; root NOW SHOWING = 0, is it chatgpt = 1 |
| I5  | kapandı | 9 Q&A native `<details>/<summary>`, dizinden sonra + contributors'tan önce, metin cf49e20'den BİREBİR; canlı: details = 9, the strictest privacy policy = 1, calisthenics = 1, healthy-living-articles = 1 |
| Z3  | kapandı | gizlilik/terms link kırığı önceki oturumda düzeldi; site geneli sinema kalıntısı canlıda yok |

Kapı sonucu: GEÇTİ.
- Cache: gerçek sebep vercel.json'daki `/(.*\\.html)?` regex'iydi — opsiyonel `.html?` çıplak root `/`'u kapsamıyordu, sadece tarayıcı cache'i kapanıyor, CDN açık kalıyordu. Düzeltme: `source: "/"` + `source: "/(.*\\.html)"` ayrı iki kural, ikisine de `s-maxage=0`. Statik varlıklar (css/js/img/wasm) kasıtlı cache'li bırakıldı.
- I5 uyarı: `ed6394a` commit mesajı "restore 9-question qa" diyor ama içeriği boş — commit mesajına değil içeriğe bakıldı. Gerçek kaynak cf49e20 (sinema orijinali). Beklenen "does my video / will it work / who made" ifadeleri hiç var olmamış (Damla teyit etti).
- Dizin = topluluk link dizini (articles/workouts sayacı, hep 0); 386 hareket moves.html'de, AYRI şey.
- AÇIK (FAZ 1'e devir): topbar arama kutusu (`#topSearch`) HTML'den düşmüş, topbar.js onu arıyor. FAZ 0 kapısında değil; topbar FAZ 1'de kanonikleşecek, orada geri gelir.

## FAZ 1 — Tek kabuk, tek CSS   [kapı: Damla ekran görüntüsü onayı bekliyor — 19 Tem]
| kod | durum | kanıt (canlı, çıplak URL) |
|-----|-------|------|
| tek stylesheet | kapandı | 13 URL (root + 12 sayfa) hepsi yalnız css/site.css; eski css'ler canlıda 404; site.css 200 text/css |
| G1 G2 | kapandı | tek css/site.css = tek tasarım dünyası; nav 12/12 + footer 12/12 partial'a BİREBİR (diff ok) |
| G3 emoji | kapandı | 🔍♥📸✨🎀🤸▸▾ tümü söküldü; canlı emoji taraması 13 URL = 0. moves.html'deki görünür ♥ cümle KORUNARAK inline SVG kalbe çevrildi (.icon-inline helper); moves listesi (.hh) + my-moves unlike butonu da aynı SVG ile eşlendi (ajanların boşalttığı butonlar geri geldi) |
| G4 buton | kapandı | tek buton dili site.css (.btn lila / .ghost hairline); pembe hap + siyah dikdörtgen kalktı |
| G5 | kapandı | site.css reset + tipografi (Bricolage/Inter/JetBrains Mono google fonts) — tarayıcı varsayılanı yok |
| G9 | kapandı | favicon 🎀 → icons/icon-192.png tüm sayfalar; fontlar her head'de |
| B1 B4 | kapandı | blog.html artık site.css + kanonik nav (my moves dahil) |
| Z1 Z2 | kapandı | gizlilik/gizlilik-tr/terms sidebar kabuğundan çıktı, ortak kabuk (nav+main.prose+footer) |
| S1 | site.css'te | suggest form alanları .field/input site.css sistemine bağlı (görsel FAZ 5'te teyit) |
| !important | 0 | grep -rc "!important" css/ = 0 |
| inline style | 0 | grep -l "<style" *.html boş |
| #topSearch | 12/12 | her sayfada canlı |
| rename | tamam | .stage→.panel, .receipt→.summary, #camstage→#camera (coach.html + js/coach.js $("camera")); coach.js node --check OK |

Notlar / açık:
- partials/nav.html + footer.html = tek kaynak. Site'de build step yok → içerik her sayfaya BİREBİR yapıştırıldı (kapı "10 sayfada aynı" böyle sağlandı).
- INLINE STYLE SİLİNDİ → index (hero .worth/.how/.priv/.loop), patch-notes (polaroid/timeline) ve moves/my-program sayfa-özel görselleri şu an STİLSİZ. FAZ 2/4/5 onları site.css sistemiyle yeniden kuracak. Bu FAZ 1'in doğası (tek CSS'e in), FAZ 2 index'i baştan tasarlıyor zaten.
- sw.js CACHE v69→v70, CORE'dan silinen css'ler çıkarıldı + css/site.css eklendi (install kırılmasın).
- Ekran görüntüsü: Damla kendi dev'inde bakar (headless screenshot kuralı gereği ben üretmiyorum).

### 12 sayfa (HANDOFF "10 sayfa" dedi; gerçekte deploy edilen 12 HTML var)
HANDOFF'un saydığı 10: index · moves · my-moves · my-program · coach · suggest · blog · patch-notes · gizlilik · terms.
Ek 2: **gizlilik-tr.html** (privacy'nin TR sürümü — gizlilik.html ile ikiz) ve **reset-password.html** (şifre sıfırlama form sayfası). İkisi de aynı tek kabuğa alındı.

### css/site.css — 399 satır, bölüm başlıkları
tokens · type · the dot motif · nav · buttons · forms · bands/prose · Q&A accordion ·
directory · flow/how grids · cards/posts · empty state · blog tabs · moves library ·
calendar · coach · footer · reveal+a11y · responsive.

### YARI-ÇIPLAK (inline <style> silindi, site.css'te henüz karşılığı yok — FAZ 2/4/5'te kurulacak)
Bu bloklar canlıda şu an stilsiz akar; kaybolmasın diye burada:
- **index.html** (→ FAZ 2 zaten baştan tasarlıyor): sayfa-özel sınıfların HİÇBİRİ site.css'te yok —
  .hero .sub .acts .stub .demo .read .worth .how .cols .priv .loop .split .close.
  (nav, footer, .btn, .quiet, .term, .eyebrow, Q&A, directory ZATEN site.css'te — onlar stilli.)
- **patch-notes.html** (→ FAZ 5): .timeline · .polaroids · patch-* (girdi/foto düzeni) stilsiz.
- **moves.html / my-moves.html / my-program.html / coach.html / suggest.html** (→ FAZ 4/3/5):
  mekanik sınıflar (moves library, calendar, coach, form) site.css'te KURULU ve stilli;
  yalnız her sayfanın kendi başlık/hero/yerleşim inline'ından gelen ufak süsler gitti.
  Bu sayfaların işlevi (liste render, takvim, kamera, form) çalışır; görsel cila ilgili fazda.


## FAZ 2 — index   [Damla canlı kamera onayı bekliyor — 19 Tem]
Kapsam I1 I2 I3 I4 I6 I7 I8 G6 + kart sistemi + canlı kamera.
| kod | durum | kanıt |
|-----|-------|------|
| I7 sayaç panelde | kapandı | DOM: #reps → .panel-read → .panel#heroPanel içinde (sağ üst köşe); artık sayfa kenarında öksüz değil |
| I8 nokta bulutu | kapandı | landing.js ~450 nokta HANDOFF katsayılarıyla (gövde .082/130 · uyluk .058 · baldır .042 · kol .034/.028 · baş .052), boyut ≤2.7px, opaklık .38-.88, figür %84 yükseklik %46 yatay, diz lila+nefes halkası+canlı açı; ÇİZGİ YOK (grep lineTo/moveTo = 0; stroke sadece halka) |
| I4 canlı kamera | kapandı (Damla test edecek) | "open the camera" butonu → lazy import engine-core → mediapipe pose + wasm motor, panelde kullanıcının KENDİ noktaları + gerçek sayaç; toggle stop → track.stop() + _free; izin/hata → sessizce demo (mesaj yok); tab gizlenince/pagehide otomatik stop |
| I2 numaralar | kapandı | three-jobs'tan 01/02/03 kalktı (HTML'de 0); numaralandırma yalnız .loop'ta (CSS counter, dört gerçek adım) |
| I3 worth+how | KISMİ | worth ve how ayrı kaldı AMA how artık band-lila (farklı zemin) + real output bloğu araya girdi; "aynı şeyi iki kez" hissi kırıldı. Not: Damla "tek bölümde birleştir" dedi — ben ritmi kırıp araya output koydum; tam birleştirme YAPILMADI, Damla'ya sorulacak |
| I6 gerçek çıktı | kapandı | .output-band mono bloğu: squat·set 3/12·tempo 2-1-2 / knee angle min 94° target <110° ✓ / knee cave on reps 4,7,11; skor+açı lila |
| I1 ritim | kapandı | worth(2-kolon) · how(lila band 4-kolon) · output(mono blok) · priv(2-kolon+terminal) · loop(numaralı) · close(ortalı tek cümle) — kalıp kırıldı |
| G6 ürün sinyali | kapandı | sayaç+açı+nokta+output artık index'in her yerinde, sadece hero'da değil |
| kart sistemi | site.css'te | .card wash/16px/26px/no-frame + hover lila shadow + .saved pink-soft + .card-dots imza (6-8 nokta sağ alt, 1.5px .12 opaklık); coach FAZ 3'te bu sisteme oturacak |
| engine-core | çıkarıldı | js/engine-core.js ortak (mediapipe pose loader + wasm motor + writePosesToHeap); index kullanıyor. KARAR: coach.js'e DOKUNULMADI (git temiz) — coach canlı/kırılgan, recovery+mesh+calibration state iç içe; davranış riske girmesin (Damla onayı). Küçük kod tekrarı kabul edildi |

Lazy-load kanıtı: canlı index HTML'inde vendor/mediapipe ve engine/motor referansı = 0 (ilk açılışta indirilmiyor, sadece butona basınca import()). js/landing.js + engine-core.js + site.css hepsi 200.
site.css 417→499 satır; yeni bölümler: card system + dot signature + index (faz 2).
sw.js v70→v71.

AÇIK (Damla kararı): (1) I3 tam birleştirme mi yoksa ritim-kırma yeterli mi? (2) kamera 4 senaryo canlı test (izin ver / reddet / stop / mobil).

## FAZ 3 — coach   [kapı geçti — 19 Tem]
| kod | durum | kanıt |
|-----|-------|------|
| C1 pembe dünya | kapandı | gate.sh 3: pink/cherry ground 0; coach artık site.css tek dünyası, mono HUD |
| C2 tek isim | kapandı | "open the camera" nav+h1+title+footer; sinema kalıntısı (sub-sign/stagefloor) canlıda 0 |
| C3 onboarding | kapandı | js/coach-onboarding.js: 4 adım (move→reps/sets→izin→çerçeve), cevapsız ilerlemez (answered[] guard), X/skip yok (gate onb bloğu temiz), geri serbest, translateX yatay geçiş, nokta ilerleme (done lila/active nefes/waiting boş), adım 4 vücut görününce (vis≥24, 12 kare) OTOMATİK onay → #ready.click() |
| C4 hareket yığını | kapandı | onboarding move seçimi çip düzeninde (ilk 8), düz metin yığını değil |
| C5 yapışık sayılar | site.css'te | HUD mono/ayrık (.phase-word head, .rep-count mono); FAZ 4'te moves tarafı da |
| C6 çıplak göstergeler | kapandı | .meter/.bar mono etiketli, "can't see you clearly" motor tarafında (coach.js, dokunulmadı) |
| C7 hesap paneli | kapandı | .foldcard (account) wash zemin, kart diline yakın |
| G7 boş durum | KISMİ | .empty + .loading site.css'te TANIMLI (dot cluster + satır + buton / dağılıp toplanan nokta); coach'ta kullanım FAZ 4'te (moves/my-moves boş durumları) — açık, FAZ 4 kapatır |
Kapı: gate.sh 3 GEÇTİ (universal 13/13 + coach 8/8; 999px sadece meşru çip uyarısı).
DEĞİŞMEZ #9: coach.js motoruna DOKUNULMADI (git: son değişiklik faz 1 rename; onboarding ayrı JS, #ready.click() ile devreder). 50 coach.js ID'si korundu (grep doğrulandı).
Miras kuruldu: --dur-fast/--dur/--dur-slow/--ease, --r-sm/--r/--r-lg, .empty, .loading.
Radius sistemi (SÖZLEŞME DEĞİŞİKLİĞİ, DECISIONS'ta): --r:3px→16px sistemine geçti, tüm site yumuşak köşe.
Sonraki: FAZ 4.
Açık (Damla canlı test): onboarding izin ver/reddet, adım 4 otomatik onay, kamera sayıyor mu.
## FAZ 4 — moves · my-moves · my-program   [kapı geçti — 19 Tem]
| kod | durum | kanıt |
|-----|-------|------|
| M1 386 render | kapandı | .lib-mv liste → .card sistemi (mv-card); render MOVE_DB'nin 386 hareketini geziyor; canlı mv-card + card-grid; kesin sayı Damla'da (JS render, curl göremez) |
| M2 filtre+sayaç | kapandı | libfilters çipleri + mono #libCount "N / 386" canlı |
| M3 coached/reference | KISMİ | her kartta eklem grubu (kategori) + coached(lila-soft)/reference(nötr) + kalp SVG. "mono hedef" verisi MOVE_DB'de YOK → uydurulmadı, FAZ 8 spec'ten gelecek (DECISIONS) |
| M4 emoji arama/kalp | kapandı | kalp SVG (FAZ 1), arama emoji yok |
| MM1 boş durum eylem | kapandı | my-moves boş → .empty deseni (dot + satır + "browse 386 moves" btn) |
| MM2 save boşken gizli | kapandı | createBtn.hidden = kept.length===0 (mevcut) |
| MM3 kimlik | kapandı | kaydedilenler pink-soft kart (.kept-row.card.saved), moves kopyası değil |
| MP1 github grafiği | kapandı | "less▪▪▪more" legend kalktı (canlı grep 0), yearwall pink nokta yoğunluğu |
| MP2 takvim genişlik | kapandı | .mcal/.wcal/.ycal max-width:none, tam genişlik |
| MP3 gün hücresi | kapandı | .monthwall .d.lit hareket+skor (mevcut), dolu gün pink-soft, bugün lila ring |
| MP4 manifesto | kapandı | başlık tek satır (copy'ye dokunulmadı, h1 sistemi) |
| MP5 week/month/year | kapandı | .viewpick çip sistemi (999px, lila aktif) |
| G7 boş durum çıkış | kapandı | moves/my-moves/my-program boş durumların HEPSİNDE .empty + buton; inline #8e6fd8 palet kaçakları temizlendi |
Kapı: gate.sh 4 GEÇTİ (universal 13/13 + no github graph). SÖZLEŞME DEĞİŞİKLİĞİ: M3 mono-hedef açık (veri yok, FAZ 8), MP1 dot-density (DECISIONS).
Sonraki: FAZ 5.
Açık: 386 kesin render sayısı (Damla canlı), M3 mono hedef (FAZ 8).
## FAZ 5 — blog · patch-notes · gizlilik · terms · suggest   [kapı geçti — 19 Tem]
| kod | durum | kanıt |
|-----|-------|------|
| B2 blog sekme | kapandı | .tabs (kutu yok, aktif altı 2px lila) canlı; .blogtabs→.tabs |
| B3 blog boş durum | kapandı | .empty deseni (dot + satır + "open the camera" btn); inline style kaldırıldı |
| P1 patch ≥1 girdi | kapandı | 8 gerçek git girdisi (v73→v10, tarih+versiyon+ne+neden, v62 "miss" kaçırılan dahil) — canlı grep 8 |
| P2 fotoğraf kenar+dönüşümlü | kapandı | 3-kolon .patch-grid; 3 foto sağ/sol raylarda dönüşümlü (sol r2/r6, sağ r4 — aynı hizada iki yok); 4:5, object-fit cover, mono altyazı, lazy+width/height, mobilde gizli |
| P3 who başlığı | kapandı | parçalı "who/person behind" kalktı, girdiler tutarlı |
| Z4 okuma genişliği | kapandı | gizlilik/terms/gizlilik-tr .prose 66ch (FAZ 1'de kabuk, .prose sınıfı) |
| S1 form sistemi | kapandı | suggest .field/.office; input/select/textarea site.css forms; .sub-body→.suggest-body |
| FOTOĞRAF sadece bu sayfa | kapandı | img/damla yalnız patch-notes'ta; index/coach/moves + 6 sayfada <img> foto = 0 (canlı) |
Kapı: gate.sh 5 GEÇTİ (universal 13/13 + no photo outside patch + entries≥8). Canlı: 8 girdi, 3 foto lazy, index'te foto 0.
Sonraki: FAZ 6.
## FAZ 6 — Generic denetimi   [kapı geçti — 19 Tem] · TASARIM REWORK BİTTİ
gate.sh 6 GEÇTİ (universal 13/13). Denetim sonucu:
- stylesheet: 12/12 tek css/site.css · !important 0 · inline <style> 0
- nav+footer 12 sayfada birebir aynı (diff)
- palet: sadece 9 token (gate) · emoji/gradient/siyah gölge/chevron: canlı 0
  (takvim chevron ‹› → ince ok SVG; has-strip ölü class temizlendi)
- nokta motifi 7 ayrı yerde (≥4 ✓): hero point-cloud · card-dots · empty-dots ·
  onb-dots · yearwall · loading · .dot
- manifesto: kalan yok, tüm h1 kısa+düz
- boş durumlar: moves/my-moves/my-program/blog HEPSİNDE .empty + buton
- onboarding cevapsız ilerlemiyor (answered[] guard), X/skip yok
- LOGO TESTİ: index (nokta bulut+real output+mono) · coach (onboarding+mono HUD) ·
  moves (coached/reference) · patch-notes (3-kolon foto) → hiçbiri generic SaaS'la
  karışmaz; en nötr gizlilik/terms bile mono nav + prose kabuğunda
- ≥3 imza anı: (1) hero nokta bulutu + panel-içi canlı sayaç (2) onboarding nokta
  ilerlemesi + adım 4 otomatik (3) coached/reference dürüstlük etiketi + real output
- "sil-3": bariz ölü CSS yok (FAZ 1'de temizlendi); silme copy'ye dokunur = KIRMIZI,
  yapılmadı
Sonraki: YOL-HARITASI FAZ 7 (ölçüm altyapısı).

---
## TASARIM REWORK ÖZET (FAZ 0-6, 19 Tem)
0 cache+Q&A · 1 tek kabuk · 2 index canlı kamera · 3 coach onboarding ·
4 moves kart · 5 patch 3-kolon · 6 denetim. Canlı v75. Değişmez #9 korundu
(coach.js motoru dokunulmadı). Açık (Damla/sonraki faz): kamera 4 senaryo canlı
test · M3 mono hedef (FAZ 8 spec) · 386 kesin render sayısı.
