# gymgyme REWORK — enumlu workflow

## 0. ÇALIŞMA KURALLARI

Bu dosya tek kaynaktır. Her faz başında oku, faz sonunda STATUS.md'yi güncelle.
Canlıda görmeden hiçbir maddeye "kapandı" yazma. Kapatma kanıtı = canlı URL + ekran görüntüsü.
Bir fazın çıkış kapısı geçilmeden sonraki faza geçme. Kapı düşerse geri dön, düzelt, tekrar dene.
Tek stylesheet: css/site.css. Yeni CSS dosyası yok, !important yok, inline <style> yok, sayfaya özel stil yok.
Copy'ye dokunma. Metinler Damla'nın sesi; değiştirme, çevirme, "profesyonelleştirme" yok. Kesebilirsin, kısaltamazsın: bir cümle ya aynen kalır ya tamamen gider. Yeni metin gerekirse aynı ses: küçük harf, kuru, ünlemsiz, iddia değil ölçü.
Emoji yasak (✦ ✧ tipografik ayraç hariç). Gradient, gölge, ikon kütüphanesi, chevron yasak. Radius 3px (çip ve avatar hariç).

Palet — sadece bunlar:
--paper:#FFFFFF · --wash:#F5F2FA · --ink:#191320 · --mut:#6E6579 · --line:#E7E2EE · --lila:#7A5BB0 · --lila-soft:#EDE6F7 · --pink:#D96BA0 · --pink-soft:#FBEAF2
Lila = motorun çıktısı (açı, skor, sayaç, coached etiketi, aktif çip/tab, odak, birincil buton).
Pembe = kullanıcının verisi (dolu antrenman günü, kaydedilmiş hareket, kişisel geçmiş).
Hiçbiri dekoratif kullanılmaz.

Tipografi: başlık Bricolage Grotesque 600, h1: clamp(30px,3.4vw,42px) — büyütme. Gövde Inter 16px/1.62. Tüm sayı/açı/skor/süre/versiyon/terminal/eyebrow: JetBrains Mono. Başlıkta renkli veya italik vurgu kelime yok.

Tek motif: nokta. İskelet çizgisi, illüstrasyon, ikon seti eklenmez. Nokta her ölçekte tekrar eder: hero bulutu, onboarding ilerleme göstergesi, dizin kategori işaretleri, yoğunluk grafiği, buton hover, yükleme durumu.

## 1. STATUS.md formatı
Her faz sonunda bu dosyayı güncelle:
```
## FAZ n — <ad>   [devam ediyor | kapı geçildi]
| kod | durum | kanıt |
|-----|-------|-------|
| G1  | kapandı | /moves.html ss-01.png |
| G2  | açık    | gizlilik nav hâlâ farklı |
Kapı sonucu: <geçti / düştü, sebep>
```

## FAZ 0 — Kritik hatalar  G8 · Z3 · I5

- `/` ile `/index.html` iki farklı sayfa; root eski sinema sürümünü serve ediyor. Root yeni index'i serve etsin, eski dosya silinsin.
- Eski root'ta olup yeni index'te kaybolan içeriği geri al: 9 soruluk Q&A ve 8 kategorili dizin + arama. Metinler birebir eski sayfadan taşınır, yeniden yazılmaz.
- gizlilik.html içindeki index.html#my-program kırık linkini my-program.html'e çevir.

Kapı 0: `curl -s https://gymgyme.noseydewdrop.com/ | diff - <(curl -s .../index.html)` boş dönüyor mu? Q&A 9 soru ve 8 kategori yeni index'te var mı? Sitede kırık link kaldı mı (tüm href'leri tara)?

## FAZ 1 — Tek kabuk, tek CSS  G1 · G2 · G3 · G4 · G5 · G9 · B1 · B4 · Z1 · Z2 · S1

- index.html inline <style>ını css/site.css'e taşı.
- styles.css, marquee.css, theme.css, calm.css, coach.css silinir; tüm referansları 10 sayfadan çıkarılır. Sadece site.css kalır.
- Silinen dosyalardaki mekanik CSS'i (takvim ızgarası, çipler, kart grid, kamera overlay, geçmiş listesi, blog sekmeleri, form alanları) site.css'e renksiz ve gölgesiz, sadece yapı olarak taşı.
- Sinema kalıntısı isimleri değiştir: .stage→.panel, .receipt→.summary, #camstage→#camera. JS referanslarını güncelle, mekanikleri bozma.
- Nav 10 sayfada birebir aynı HTML: gymgyme. (nokta lila) · moves · build a workout · my moves (n) · blog · patch notes · arama (inline SVG) · dolu buton open the camera. Mobilde tek satır kaydırmalı.
- Footer 10 sayfada birebir aynı: moves · my moves · build a workout · open the camera · blog · patch notes · suggest a move · privacy · terms · github + "no ads, no tracking, no cookies" + sağda mono v63 · patch notes →. gizlilik ve terms dahil istisnasız.
- Tüm emoji'leri kaldır (🔍 ♥ 📸 ✨ 🎀 🤸 ▸ ▾) → inline SVG veya mono metin etiket.
- Tek buton sistemi: .btn (dolu), .btn-ghost (çizgili/alt çizgili), .btn-sm. 999px hap ve pembe buton kalkar.
- Form dili site.css'te tanımlanır (.field, input/textarea/select) — suggest ve hesap paneli bunu kullanır.
- Meta tutarlılığı: her sayfada canonical + og:image. my-program, my-moves, gizlilik, terms noindex kalır.

Kapı 1: Her sayfa için <link rel=stylesheet> listesini bas — hepsi tek satır mı? `grep -rc "!important" css/` = 0 mı? `grep -rn "<style" *.html` boş mu? 10 sayfanın nav ve footer HTML'i birbirinin aynısı mı (diff ile kanıtla)? Emoji taraması temiz mi?

## FAZ 2 — index  I1 · I2 · I3 · I4 · I6 · I7 · I8 · G6

- Hero iki kolon: sol başlık + lead + iki buton + "Free. No account..." satırı; sağ .panel (--wash zemin, 1px --line, aspect-ratio:4/3.1, tam boy canvas).
- Sayaç bloğu panelin içinde, sağ üst köşede: büyük mono rakam + "reps counted live, of this figure" + altında lila açı. "What the camera sees..." satırı panelin sol alt köşesinde.
- Nokta bulutu: ~450 nokta, çizgi/iskelet yok, uzuv hacmine dağılmış (gövde spread .082 ~130 nokta · uyluk .058 · baldır .042 · kol .034/.028 · baş kümesi .052). Boyut 1–2.7px, opaklık .38–.88, hafif titreşim. Figür panel yüksekliğinin %84'ü, yatayda %46'da. Altta noktalı zemin çizgisi. Diz lila dolu + nefes alan halka + canlı açı. Tam cycle kapanınca sayaç artar. prefers-reduced-motion'da statik.
- Canlı kamera: hero butonu sayfadan ayrılmadan kamerayı bu panelde başlatır (coach'taki wasm motoru index'e bağlanır). İzin verilirse kullanıcının kendi noktaları + gerçek sayaç; verilmezse demo figüre sessizce döner.
- "three jobs"taki 01/02/03 numaraları kalkar (orada sıra yok). Numaralandırma sadece "loop"ta kalır.
- "worth" ve "how" bölümleri birleşir; cümleler kesilir, yeniden yazılmaz.
- Bölüm ritmi kırılır: en az iki bölüm eyebrow+başlık+kolon kalıbının dışında dursun.
- Gerçek çıktı bloğu: mono squat · set 3 / 12 reps · tempo 2-1-2 / knee angle min 94° · target <110° ✓ / knee cave on reps 4, 7, 11, üstünde mono etiket real output. Skor ve açı lila.
- Q&A (Faz 0'da geri gelen 9 soru) dizinden sonra, footer'dan önce: native <details>/<summary>, kutu yok, arka plan yok, chevron yok. Soru 19px + kapalıyken görünen tek altın satır (cevabın içinden birebir, --mut, sonunda ✧) + 1px hairline. İşaret ✦: kapalı kontur, açık lila dolu. Varsayılan hepsi kapalı.

Kapı 2: Sayaç panelin içinde mi? Nokta bulutunda çizgi var mı? Kamera izni akışı iki senaryoda da çalışıyor mu (izin ver / reddet)? Sayfada kaç 01/02/03 kaldı?

## FAZ 3 — coach  C1..C7 · G7

- Pembe zemin, kiraz metin, hap butonlar kalkar; sayfa index'le aynı dünyaya girer.
- Sayfaya tek isim: nav etiketi = sayfa başlığı. Üç ayrı ad sona erer.
- Onboarding — adım adım, cevapsız ilerlemez:
  - Adımlar: (1) hangi hareket · (2) kaç tekrar/süre · (3) kamera izni · (4) çerçeve kontrolü.
  - Cevaplanmadan sonraki adım açılmaz. Kapatma (X) yok, atlama yok. Geri gitmek serbest.
  - Geçiş: yatay kaydırma transform:translateX, 240ms, cubic-bezier(.2,.7,.3,1). reduced-motion'da anında.
  - İlerleme göstergesi nokta dizisi: tamamlanan lila dolu, aktif nefes alan halkalı, bekleyen boş kontur.
  - Adım 4'te canlı görüntü üstünde nokta overlay'i; vücut çerçeveye girince adım kendiliğinden onaylanır, kullanıcı butona basmaz.
  - Whimsy ölçülü: adım tamamlanınca noktalardan küçük bir dalga geçer; çerçeve tutunca panel kenarında tek lila hairline yanıp söner. Konfeti, ses, animasyonlu emoji yok.
- Bekleme/hazırlık durumlarında panelde nokta figürü oynar (boş placeholder asla kalmaz), üstünde mono this is what the engine sees.
- HUD: sayaç/skor/açı index'le birebir aynı dilde, mono, ayrık, etiketli. 0reps 45 TOTAL REPS0 yapışıklığı biter.
- "depth / tracking confidence / body in frame" göstergeleri hairline'lı satırlar, değerleri mono.
- 19 hareketlik program listesi yapılandırılır (grid + çip), düz metin yığını olmaktan çıkar.
- Hesap paneli standart buton/form sistemine geçer, footer üstünde hairline ile ayrılmış sakin blok.

Kapı 3: Onboarding cevapsız ilerliyor mu (ilerlememeli)? X butonu var mı (olmamalı)? Adım 4 otomatik onaylanıyor mu? Sayfada pembe zemin/hap buton kaldı mı? HUD index'le aynı görünüyor mu (yan yana ekran görüntüsü)?

## FAZ 4 — moves · my-moves · my-program  M1..M4 · MM1..MM3 · MP1..MP5 · G7

- moves: kart grid'i (1px hairline, gölgesiz) gerçekten 386 hareketi render eder. Her kartta hareket adı + mono satır: hangi eklem sürüyor + coached (lila etiket) / reference (nötr etiket). Filtre çipleri üstte, aktif olan lila dolu. Sonuç sayacı mono.
- my-moves: boş durum = bir satır açıklama (Damla'nın sesinde) + browse 386 moves butonu. "save to your trainer" butonu liste boşken gizlenir. Sayfanın moves'tan farkı görünür olur (kaydedilenler pembe işaretli).
- my-program: takvim tam genişlik (max-width sınırı kalkar), 7 kolon hairline ızgara. Gün hücresi bilgi taşır: hareket adı + mono skor. Dolu gün --pink-soft, bugün lila inset ring.
- "less ▪▪▪ more" GitHub katkı grafiği tamamen kalkar — yerine kendi nokta dilinde yoğunluk göstergesi (az gün seyrek nokta, çok gün sık nokta).
- week/month/year sekmeleri çip sistemine geçer. Takvim üstündeki manifesto başlık kalkar, sayfa başlığı tek satır ≤24px.
- Tüm boş durumlar tek desende: bir satır açıklama + bir eylem butonu. Uygulanacak yerler: my-moves, takvim, PAST SESSIONS, blog listesi, moves arama sonucu boş.

Kapı 4: moves'ta kaç kart render oluyor (386 olmalı)? coached/reference etiketi görünüyor mu? Takvim tam genişlik mi? GitHub grafiği kalktı mı? Boş durumların hepsinde buton var mı (tek tek listele)?

## FAZ 5 — blog · patch-notes · gizlilik · terms · suggest  B2 · B3 · P1..P3 · Z4 · S1

- blog: .blogtabs/.tab — kutu yok, aktif sekme altı 2px lila. .prose max 66ch. Boş durum madde 36 desenine uyar.
- patch-notes üç kolon: ortada girdiler (max-width:66ch), sağ ve sol ~200px kolonlarda Damla'nın üç fotoğrafı — girdi hizasında, dönüşümlü (solda bir, aşağıda sağda bir), aynı hizada iki tane olmaz. 4:5 dikey, object-fit:cover, 1px --line çerçeve, 3px radius, filtre/gradient/rotasyon yok, altında mono altyazı, loading="lazy" + width/height. Mobilde kenar kolonları gizlenir.
- Damla'nın fotoğrafı sitede yalnızca patch-notes'ta bulunur. index, coach, moves dahil hiçbir sayfada fotoğraf yok.
- patch-notes içerik: gerçek git geçmişinden en az 8 girdi — tarih + versiyon (mono) + ne değişti + neden. Uydurma yok. Kaçırılan/bozulan şeyler de yazılır.
- "who / the person behind it" başlık parçalanması düzelir.
- gizlilik + terms ortak kabuğa girer, .prose düzeninde, okuma genişliği 66ch. Türkçe sürüm linki mono etiket.
- suggest form dili site.css'ten gelir.

Kapı 5: patch-notes'ta kaç girdi var (≥8)? Fotoğraflar kenarlarda ve dönüşümlü mü? Başka sayfada fotoğraf kaldı mı? gizlilik/terms kabuğa girdi mi?

## FAZ 6 — Generic denetimi (kendi kendini denetler)

10 sayfayı canlıda aç, ekran görüntüsü al, 46 maddenin tamamını STATUS.md'de tek tek işaretle. Açık kalan varsa kapat.
Şu soruları tek tek cevapla:
- Kaç stylesheet? !important kaç adet? Inline <style> var mı?
- Nav + footer 10 sayfada birebir aynı mı?
- Palet dışı renk var mı? Lila sadece motor çıktısında, pembe sadece kullanıcı verisinde mi?
- Emoji kaldı mı? Gradient/gölge/chevron kaldı mı?
- Nokta motifi kaç ayrı yerde tekrar ediyor (≥4 olmalı)?
- Hangi sayfada hâlâ araç yerine manifesto var?
- Boş durumların hepsinde eylem butonu var mı?
- Onboarding cevapsız ilerliyor mu? X var mı?
- Logoyu kapat: her sayfa için tek tek — başka bir fitness/SaaS sitesiyle karıştırılır mı? Karışan sayfayı düzelt.
- Yalnızca bu siteye ait, başka yerde görülmeyecek en az üç an var mı? (nokta bulutu · altın satırlı Q&A · onboarding nokta ilerlemesi)

Son adım: hangi üç şeyi silsem site iyileşir? Sil, sonra teslim et.

Kapı 6: 46 maddenin hepsi "kapandı" mı? Değilse teslim etme.
