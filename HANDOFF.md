# gymgyme — DEVİR NOTU (19 Tem 2026)

Bu dosya tek kaynaktır. Yeni session bunu okuyup buradan devam eder.

---

## 1. ÜRÜN

Tarayıcıda çalışan kamera antrenörü. MediaPipe pose landmarker (33 nokta) +
Damla'nın kendi yazdığı C++ motoru, wasm'a derlenmiş. Eklem açılarından tekrar
sayar, her tekrarı 0-100 puanlar (depth / tempo / control), formu düzeltir.
Video hiçbir yere yüklenmez, hepsi cihazda. 386 hareketlik kütüphane.
92 native test. Sürüm v63. Ücretsiz, reklamsız.

10 sayfa: index · moves · my-moves · my-program · coach · suggest · blog ·
patch-notes · gizlilik · terms

---

## 2. ŞU ANKİ DURUM — FAZ 0 KAPANMADI

Kanıt (19 Tem, canlıdan):

```
curl -sI https://gymgyme.noseydewdrop.com/ | grep -i -E "x-vercel-cache|cache-control"
cache-control: public, max-age=0, must-revalidate
x-vercel-cache: HIT
```

Root hâlâ **eski sinema sürümünü** serve ediyor: "NOW SHOWING · EVERY NIGHT ·
YOUR LIVING ROOM", "✨ personal trainer 🎀 - starring you", ADMIT ONE bileti,
3 Damla fotoğrafı, eski nav (personal trainer / moves list / my moves /
my program / suggest something!).

`/index.html` ise yeni sürümü veriyor. İkisi farklı.

**Teşhis:** Vercel edge cache (`x-vercel-cache: HIT`). Header'da `s-maxage=0`
yok — sadece `max-age=0, must-revalidate` var, bu yalnızca tarayıcı cache'ini
kapatır, CDN katmanını kapatmaz. Alternatif ihtimal: production domaini eski
bir deployment'a alias'lanmış (o zaman purge işe yaramaz, alias düzeltilmeli).

**Uyarı:** `?nc=rastgele` gibi query ile test etmek cache'i baypas eder ve
yanlış "geçti" sonucu verir. Çıplak URL ile test et.

### İlk yapılacak iş

```
cat vercel.json
vercel ls
vercel inspect gymgyme.noseydewdrop.com
vercel --prod --force

curl -sI https://gymgyme.noseydewdrop.com/ | grep -i -E "x-vercel-cache|cache-control|age|x-vercel-id"
curl -s https://gymgyme.noseydewdrop.com/ | grep -c "NOW SHOWING"     # beklenen 0
curl -s https://gymgyme.noseydewdrop.com/ | grep -c "is it chatgpt"   # beklenen 1
```

---

## 3. DEĞİŞMEZ KURALLAR

- **Tek stylesheet:** `css/site.css`. Yeni CSS dosyası yok, `!important` yok,
  inline `<style>` yok, sayfaya özel stil yok.
- **Copy'ye dokunma.** Metinler Damla'nın sesi. Kesebilirsin, kısaltamazsın:
  bir cümle ya aynen kalır ya tamamen gider. Yeniden yazma, çevirme,
  "profesyonelleştirme" yok. Yeni metin gerekirse aynı ses: küçük harf, kuru,
  ünlemsiz, iddia değil ölçü.
- **Canlıda görmeden hiçbir maddeye "kapandı" deme.** Kanıt = çıplak URL curl
  çıktısı + ekran görüntüsü.
- Emoji yasak (✦ ✧ tipografik ayraç hariç). Gradient, gölge, ikon kütüphanesi,
  chevron yasak. Radius 3px (çip ve avatar hariç).

### Palet — sadece bunlar

```
--paper:#FFFFFF  --wash:#F5F2FA  --ink:#191320  --mut:#6E6579  --line:#E7E2EE
--lila:#7A5BB0   --lila-soft:#EDE6F7  --pink:#D96BA0  --pink-soft:#FBEAF2
```

**Lila = motorun çıktısı** (açı, skor, sayaç, coached etiketi, aktif çip/tab,
odak, birincil buton). **Pembe = kullanıcının verisi** (dolu antrenman günü,
kaydedilmiş hareket, kişisel geçmiş). Hiçbiri dekoratif kullanılmaz.

### Tipografi

Başlık Bricolage Grotesque 600, `h1: clamp(30px,3.4vw,42px)` — büyütme.
Gövde Inter 16px/1.62. Tüm sayı/açı/skor/süre/versiyon/terminal/eyebrow:
JetBrains Mono. Başlıkta renkli veya italik vurgu kelime yok.

### Tek motif: nokta

İskelet çizgisi, illüstrasyon, ikon seti eklenmez. Nokta her ölçekte tekrar
eder: hero bulutu, onboarding ilerleme göstergesi, dizin kategori işaretleri,
takvim yoğunluk grafiği, buton hover, yükleme durumu.

---

## 4. GENERIC ENVANTERİ — 46 madde

### Global
- **G1** Beş ayrı tasarım dünyası: index beyaz-lila, coach pembe-hap,
  my-program yarı stilsiz, blog sıfır CSS, gizlilik eski kabuk.
- **G2** Nav'ın 4 varyantı, footer'ın 3 varyantı var.
- **G3** Emoji-ikon: 🔍 ♥ 📸 ✨ 🎀 🤸 ▸ ▾
- **G4** Üç ayrı buton dili (pembe 999px hap / siyah dikdörtgen / lila hap).
- **G5** Tarayıcı varsayılanları görünüyor (mavi altı çizili link, Times).
- **G6** Ürün sinyali (sayaç/açı/skor/nokta) sadece index'te.
- **G7** Boş durumlar ölü, hiçbirinde çıkış yolu yok.
- **G8** `/` ile `/index.html` farklı sayfa (cache).
- **G9** Meta tutarsız (canonical/og:image bazı sayfalarda yok).

### index
- **I1** Bölüm ritmi tekdüze: 8 bölüm de eyebrow→başlık→paragraf→kolonlar.
- **I2** `01/02/03` "three jobs"ta anlamsız — orada sıra yok.
- **I3** "worth" ve "how" aynı şeyi iki kez anlatıyor.
- **I4** Sayfa tamamen pasif; canlı motoru olan üründe tıklanacak tek şey link.
- **I5** Dizin, arama ve 9 soruluk Q&A kayboldu (eski root'ta duruyor).
- **I6** Tek gerçek çıktı yok, hepsi iddia.
- **I7** Sayaç bloğu panelin dışında, sayfa kenarında öksüz.
- **I8** Nokta bulutu seyrek, ziyaretçiyle ilgilenmiyor.

### moves
- **M1** 386 hareketin hiçbiri render olmuyor.
- **M2** Filtre çipi, kategori, sayaç yok.
- **M3** `coached / reference` ayrımı sitenin en özgün fikri ama sadece
  paragrafta; görsel sistemi yok.
- **M4** Arama ve beğeni emoji.

### my-moves
- **MM1** Boş durumda eylem yok.
- **MM2** "save to your trainer" butonu liste boşken de duruyor.
- **MM3** Kendi kimliği yok, moves'un kopyası gibi.

### my-program
- **MP1** "less ▪▪▪ more" = GitHub katkı grafiğinin birebir kopyası.
- **MP2** Takvim dar kolonda ortalanmış, iki yanı boş.
- **MP3** Gün hücreleri bilgisiz (skor/tekrar/hareket yok).
- **MP4** Takvimin üstünde manifesto başlık.
- **MP5** week/month/year sekmeleri stilsiz düz metin.

### coach
- **C1** Pembe zemin + kiraz metin + hap butonlar; siteyle akraba değil.
- **C2** Sayfanın üç adı var (open the camera / personal trainer /
  set up your workout).
- **C3** Onboarding yok; "📸 your camera opens here" placeholder.
- **C4** 19 hareket düz metin yığını.
- **C5** `0reps` `45` `TOTAL REPS0` yapışık, mono değil.
- **C6** depth / tracking confidence / body in frame göstergeleri çıplak.
- **C7** Hesap paneli pembe hap dünyasında.

### blog
- **B1** Sıfır CSS. **B2** Sekmeler düz metin. **B3** İçerik yok.
- **B4** Nav'da "my moves" yok.

### patch-notes
- **P1** Tek patch notu yok (en güçlü kanıt boş).
- **P2** 3 fotoğraf alt alta akışta; istenen sağ-sol kenar düzeni değil.
- **P3** "who / the person behind it" başlığı parçalanmış.

### gizlilik + terms
- **Z1** Dördüncü kabuk. **Z2** Footer bambaşka. **Z3** Kırık link (düzeldi).
- **Z4** Okuma genişliği yok.

### suggest
- **S1** Form alanları sistem dışı.

---

## 5. YOL HARİTASI — fazlar ve kapılar

Her fazın sonunda kapı var. **Kapı geçilmeden sonraki faza geçilmez.**
Faz sonunda `STATUS.md` güncellenir: madde kodu | durum | kanıt.

### FAZ 0 — Kritik `G8 · Z3 · I5`  ← ŞU AN BURADA, AÇIK
Root = index olsun (cache/alias sorunu çöz), eski sinema dosyası silinsin.
Q&A (9 soru) + dizin + arama index'e taşınsın, metinler birebir.
**Kapı:** çıplak URL diff boş; `NOW SHOWING`→0, `is it chatgpt`→1;
`x-vercel-cache` MISS/BYPASS.

### FAZ 1 — Tek kabuk, tek CSS `G1 G2 G3 G4 G5 G9 B1 B4 Z1 Z2 S1`
1. `css/site.css` tek elden yazılır (palet, tipografi, nav, footer, buton,
   form, mekanik yapılar).
2. `partials/nav.html` + `partials/footer.html` kanonik bloklar; tüm SVG'ler
   burada.
3. Eski CSS'ler (`styles.css`, `marquee.css`, `theme.css`, `calm.css`,
   `coach.css`) silinir, referansları çıkarılır.
4. Workflow ajanlarının işi **sadece kes-yapıştır**: eski link sök, inline
   `<style>` sök, nav/footer'ı partial içeriğiyle aynen değiştir, emoji sök.
   Ajanlar CSS'e dokunmaz, karar vermez.
5. Sinema kalıntısı isimler: `.stage→.panel`, `.receipt→.summary`,
   `#camstage→#camera` (JS referansları güncellenir).
**Kapı:** her sayfada tek stylesheet; `grep -rc "!important" css/`=0;
`grep -rn "<style" *.html` boş; 10 sayfanın nav+footer diff'i aynı;
emoji taraması temiz.

### FAZ 2 — index `I1 I2 I3 I4 I6 I7 I8 G6`
Hero iki kolon; sayaç panelin İÇİNDE sağ üstte; nokta bulutu ~450 nokta
(gövde spread .082 ~130 nokta, uyluk .058, baldır .042, kol .034/.028,
baş .052), boyut 1–2.7px, opaklık .38–.88, figür panel yüksekliğinin %84'ü,
diz lila + canlı açı, cycle kapanınca sayaç artar, reduced-motion'da statik.
Hero butonu **sayfadan ayrılmadan** kamerayı bu panelde başlatır (coach'taki
wasm motoru bağlanır); izin yoksa demo figüre sessizce döner.
`01/02/03` kalkar; "worth"+"how" birleşir; bölüm ritmi kırılır;
`real output` set raporu bloğu eklenir; Q&A altın satırlı akordeon olur.
**Kapı:** sayaç panel içinde mi, bulutta çizgi var mı, kamera iki senaryoda
da çalışıyor mu.

### FAZ 3 — coach `C1..C7 G7`
Pembe dünya kalkar. Sayfaya tek isim. **Onboarding:** 4 adım (hareket →
tekrar/süre → kamera izni → çerçeve kontrolü), cevapsız ilerlemez,
**X yok, atlama yok**, geri serbest. Geçiş `translateX` 240ms
`cubic-bezier(.2,.7,.3,1)`, reduced-motion'da anında. İlerleme göstergesi
nokta dizisi (tamamlanan lila dolu, aktif nefes alan halkalı, bekleyen boş).
Adım 4'te vücut çerçeveye girince **kendiliğinden** onaylanır.
Whimsy ölçülü: nokta dalgası, tek lila hairline parıltısı. Konfeti/ses yok.
Boş panel asla kalmaz; nokta figürü oynar + mono `this is what the engine sees`.
HUD index'le birebir aynı dilde, mono ve ayrık.
**Kapı:** cevapsız ilerliyor mu (hayır), X var mı (hayır), adım 4 otomatik mi,
pembe kaldı mı, HUD index'le aynı mı.

### FAZ 4 — moves · my-moves · my-program `M1..M4 MM1..MM3 MP1..MP5 G7`
386 kart render; her kartta hangi eklem + **coached**(lila)/**reference**;
filtre çipleri. my-moves boş durumu = açıklama + `browse 386 moves` butonu.
Takvim tam genişlik, gün hücresinde hareket + mono skor, dolu gün pink-soft,
bugün lila ring. **GitHub katkı grafiği kalkar**, yerine nokta yoğunluğu.
Tüm boş durumlar tek desen: bir satır + bir buton.
**Kapı:** kaç kart render (386), coached/reference görünüyor mu, takvim tam
genişlik mi, GitHub grafiği kalktı mı, boş durumlarda buton var mı.

### FAZ 5 — blog · patch-notes · gizlilik · terms · suggest `B2 B3 P1..P3 Z4 S1`
blog sekmeleri (kutu yok, aktif altı 2px lila), `.prose` 66ch.
**patch-notes üç kolon:** ortada girdiler 66ch, sağ/sol ~200px kolonlarda
**Damla'nın üç fotoğrafı** — girdi hizasında, dönüşümlü, aynı hizada iki tane
olmaz, 4:5, 1px line çerçeve, filtre/rotasyon yok, mono altyazı, lazy,
mobilde gizli. **Fotoğraf sitede yalnızca bu sayfada bulunur.**
Gerçek git geçmişinden ≥8 patch girdisi (tarih + versiyon + ne + neden,
kaçırılanlar dahil). gizlilik/terms ortak kabuğa girer.
**Kapı:** ≥8 girdi, fotoğraflar kenarda ve dönüşümlü, başka sayfada fotoğraf
yok, gizlilik/terms kabukta.

### FAZ 6 — Generic denetimi
46 maddenin tamamı STATUS.md'de işaretlenir. Sonra:
kaç stylesheet / `!important` / inline style · nav+footer 10 sayfada aynı mı ·
palet dışı renk var mı · emoji/gradient/gölge/chevron kaldı mı · nokta motifi
kaç yerde tekrar ediyor (≥4) · hangi sayfada hâlâ manifesto var · boş
durumlarda buton var mı · onboarding cevapsız ilerliyor mu · **logoyu kapat:**
hangi sayfa başka bir fitness/SaaS sitesiyle karıştırılır · yalnızca bu siteye
ait en az üç an var mı (nokta bulutu, altın satırlı Q&A, onboarding nokta
ilerlemesi) · **hangi üç şeyi silsem site iyileşir** → sil, teslim et.

---

## 6. REDDEDİLENLER (tekrar önerme)

Sinema/tiyatro teması · dev serif afiş tipografisi · başlıkta tek kelime
renklendirme · pastel lila + saf beyaz + gri SaaS paleti · kiraz/bordo/pembe
zemin · 999px hap butonlar · logonun yanına nokta motifi · `!important`
override katmanları · her sayfaya ayrı CSS · GitHub katkı grafiği kopyası ·
index/coach/moves'ta fotoğraf.
