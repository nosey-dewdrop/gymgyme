# gymgyme — PROTOKOL

Fazlar arası sözleşme sistemi. Amaç: FAZ 3→6'yı insan onayı beklemeden
kendi kendine yürütmek.

Okuma sırası: `PROTOKOL.md` (bu dosya) → `HANDOFF.md` (46 madde + faz
kapsamları) → `STATUS.md` (nerede kalındı) → `DECISIONS.md` (verilmiş
kararlar, tekrar sorulmaz).

---

## 0. NASIL ÇALIŞTIRILIR

Tek komut yeter:

```
PROTOKOL.md'yi oku ve sıradaki fazı yürüt.
```

Ajan kendi başına: fazı okur → yapar → kapıyı koşar → commit + deploy +
STATUS günceller → **bir sonraki faza kendiliğinden geçer.** FAZ 6'ya
kadar durmaz.

---

## 1. DEĞİŞMEZLER (hiçbir faz ihlal edemez)

1. Tek stylesheet: `css/site.css`. Yeni CSS dosyası yok, `!important` yok,
   inline `<style>` yok.
2. Copy'ye dokunulmaz. Kesilebilir, kısaltılamaz, yeniden yazılamaz.
   Yeni metin gerekirse aynı ses: küçük harf, kuru, ünlemsiz, iddia değil
   ölçü.
3. Palet (19 tem güncel — insan değiştirdi): `--paper --wash --ink --mut
   --line --lila #C9A9D9 --lila-soft #F0E6F5 --lila-deep #8E6BA8 --pink
   --pink-soft`. Başka renk yok. **Lila = motorun çıktısı** (aksan metin =
   --lila-deep, çip/fill/dot/aktif = --lila), **pembe = kullanıcının verisi**.
   **Butonlar --ink zemin beyaz yazı; lila ASLA buton zemini değil.**
   **Hiçbir yerde koyu kutu / terminal görünümü yok.** İkisi de dekoratif değil.
4. Emoji yok. Gradient yok. Siyah/dar gölge yok. Chevron yok.
   Radius: `--r-sm 10px` (buton, çip, input), `--r 16px` (kart, blok),
   `--r-lg 20px` (büyük panel). Bu sistem tüm sayfalarda geçerlidir;
   önceki fazların görünümünü değiştirmesi istenen sonuçtur.
5. Kart sistemi: `--wash` zemin, çerçevesiz, dinlenmede gölgesiz,
   26px padding, hover'da `translateY(-2px)` + lila tonlu yumuşak gölge.
6. Tek motif: nokta. İskelet çizgisi, illüstrasyon, ikon seti yok.
7. Hareket token'ları dışında sabit süre yazılmaz.
   `prefers-reduced-motion` altında tüm hareket durur.
8. Canlıda doğrulanmadan hiçbir madde "kapandı" sayılmaz.
9. `coach.js`'in çalışan motoruna dokunulmaz (ortak parça `engine-core.js`).
10. Telifli materyal (video, görsel, metin) izinsiz kullanılmaz.

---

## 2. FAZ SÖZLEŞMESİ — şema

```yaml
faz: <numara> — <ad>
kapsam: [<HANDOFF madde kodları>]
girdi:      # bu faz başlamadan var olması gereken
teslim:     # bu fazın üreteceği
miras:      # sonraki fazların kullanacağı ortak sistem
kapı:       # çalıştırılabilir kontroller
karar:      # ajan karar verir, DECISIONS.md'ye yazar, sormaz
```

---

## 3. KAPI = ÇALIŞTIRILABİLİR

`scripts/gate.sh` içinde her fazın fonksiyonu olur; `./scripts/gate.sh 3`
çalışır, çıktısı STATUS'a yapışır.

Her fazda koşan evrensel kontroller:

```bash
for f in *.html; do grep -c 'rel="stylesheet"' $f; done   # hepsi 1
grep -rc '!important' css/                                 # 0
grep -rn '<style' *.html                                   # boş
grep -rP '[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]' *.html   # boş (✦✧ hariç)
grep -rEo '#[0-9a-fA-F]{3,6}' css/site.css | sort -u        # sadece token'lar
grep -rn 'rgba(0,0,0' css/site.css                          # 0
grep -rn 'border-radius: *[0-9]px' css/site.css | grep -v 'var(--r'  # 0
grep -rnE '[0-9]+ms' css/site.css | grep -v 'var(--dur'     # 0
# nav ve footer bloklarını 12 sayfada diff'le → birebir aynı
# canlı doğrulama: curl -s <url> | grep -c <beklenen>
```

**Kapı düşerse:** düzelt, tekrar koş. Üç denemede geçmezse → maddeyi
STATUS'a "açık" yaz, **sonraki faza devam et.** Durma.

---

## 4. OTONOMİ

### VARSAYILAN: SORMA, YAP.

Emin olmadığında sorma. En makul seçeneği seç, uygula,
`DECISIONS.md`'ye gerekçesiyle yaz, devam et. **Karar geri alınabilir
olduğu sürece sormak yasaktır.**

Damla'ya soru sorulmaz — **gösterilir.** Faz biter, deploy edilir,
STATUS'a yazılır. Beğenmediği yeri söyler, geri alınır.

### KIRMIZI — sadece bu üçü için durulur

1. **Geri alınamaz veri kaybı riski** (repo/veritabanı silme, force push)
2. **Çalışan motoru bozma riski** (`coach.js`, wasm, mediapipe)
3. **Para harcanması gereken karar**

### Bunlar için ARTIK SORULMAZ

- Görsel ve tasarım tercihleri → en iyi olduğunu düşündüğünü yap
- Renk, radius, tipografi, boşluk, yerleşim
- Önceki fazın görünümünün değişmesi → değişmez kazanır
- Kapsam belirsizliği → dar olanı seç, yap, yaz
- İki eşit çözüm → birini seç, gerekçesini yaz
- Copy yerleştirme, sıralama, hangi metin nereye
- Kaynak / araç / kütüphane / API seçimi
- Teknik borç oluşturmak → borcu yaz, devam et
- Kapı düşmesi → 3 denemede geçmezse "açık" yaz, devam et
- 46 maddede olmayan küçük iş → yap, `X` kodu ver, yaz
- Eskiden "zevk kararı" denen her şey → karar ver, uygula,
  DECISIONS'a "Damla itiraz ederse geri alınacak" notuyla yaz

---

## 5. KENDİNİ DEĞİŞTİRME

- **HANDOFF maddesi silinemez.** "Gereksiz" olarak işaretlenir, gerekçesiyle.
- **Yeni madde eklenebilir**, kod verilerek: `X1, X2...`
- Faz sırası değiştirilebilir, gerekçe DECISIONS'a yazılır.
- Değişmezleri sadece insan değiştirir.

### FAZ BAŞLANGIÇ RİTÜELİ — her faz şununla başlar
1. `DECISIONS.md`'yi oku.
2. Önceki fazlarda verilen kararlar bu fazın sözleşmesini geçersiz kılıyor
   mu bak.
3. Kılıyorsa DÜZELTME ÖNERİSİ yaz, aşağıdaki testten geçir.
4. Geçerse uygula ve DECISIONS'a yaz. Geçmezse sözleşmeyi olduğu gibi yürüt.

### DÜZELTME TESTİ — bir sözleşme değişikliği ancak DÖRDÜ DE doğruysa geçerli
a) **Somut bulguya dayanıyor mu?** ("X'i denedim, şu sonuç çıktı.") Tahmine,
   tercihe veya kolaylığa dayanan değişiklik GEÇERSİZ.
b) **Kapsamı KÜÇÜLTMÜYOR mu?** Teslim maddesi çıkarılamaz, hedef sayı
   düşürülemez, kapı gevşetilemez. Bir madde yapılamıyorsa çıkarılmaz —
   STATUS'a "açık" yazılır, FAZ 6'da tekrar bakılır.
c) **Değişmezlerle (§1) çelişmiyor mu?** Çelişiyorsa geçersiz, değişmez kazanır.
d) **Geri alınabilir mi?** Geri alınamayan değişiklik KIRMIZI'dır, sorulur.

Her düzeltme DECISIONS'a şu formatta yazılır ve STATUS'ta "SÖZLEŞME
DEĞİŞİKLİĞİ" başlığı altında ayrıca listelenir:
  Ne değişti / Hangi bulguya dayanıyor / Kapsam küçüldü mü (evet ise neden
  geçerli) / Nasıl geri alınır

Sözleşmeler taslaktır ama sadece GERÇEK BULGU karşısında değişir, kolaylık
karşısında değil. Değişmezler (§1) hiç değişmez.

`DECISIONS.md` formatı:

```
## <tarih> · FAZ <n> · <karar başlığı>
Durum: <ne oldu>
Karar: <ne seçildi>
Gerekçe: <neden>
Etki: <hangi madde/faz değişti>
```

---

## 6. STATUS.md formatı

```
## FAZ n — <ad>   [devam | kapı geçti | açık madde var]
| kod | durum | kanıt |
|-----|-------|-------|
| C1  | kapandı | canlı grep: pembe zemin 0 |
| C3  | açık    | 3 denemede geçmedi, FAZ 6'da tekrar bakılacak |
Kapı: <gate.sh çıktısı özeti>
Sonraki: FAZ n+1
Verilen kararlar: <DECISIONS'a yazılanların özeti>
Teknik borç: <varsa>
Yarı-çıplak: <stilsiz kalan bloklar, hangi fazda kurulacak>
```

---

## 7. FAZ SÖZLEŞMELERİ

### FAZ 3 — coach
```yaml
kapsam: [C1, C2, C3, C4, C5, C6, C7, G7]
girdi: [site.css tek kaynak, partials nav/footer, engine-core.js]
teslim:
  - onboarding: 4 adım (hareket → tekrar/süre → kamera izni → çerçeve
    kontrolü). Cevapsız ilerlemez. X yok, atlama yok, geri serbest.
    Yatay kaydırma geçiş. Nokta ilerleme göstergesi (tamamlanan lila dolu,
    aktif nefes alan halka, bekleyen boş kontur).
    Adım 4: vücut çerçeveye girince kendiliğinden onaylanır.
  - whimsy ölçülü: adım tamamlanınca nokta dalgası, çerçeve tutunca tek
    lila hairline parıltısı. Konfeti/ses/animasyonlu emoji yok.
  - boş panel asla kalmaz: nokta figürü oynar + mono
    "this is what the engine sees"
  - HUD index paneliyle birebir aynı görsel dil, mono ve ayrık sayılar
  - göstergeler satır düzeninde (etiket + mono değer)
  - görünürlük düşükse saymaz, "can't see you clearly" der
  - program listesi yapılandırılmış (ad + mono hedef + tutamaç)
  - hesap paneli kart sistemine girer
  - sayfaya tek isim (nav = başlık = title = footer)
miras:
  - --dur-fast/--dur/--dur-slow/--ease token'ları
  - .empty (boş durum: wash + nokta kümesi + satır + buton)
  - .loading (dağılıp toplanan noktalar; spinner/skeleton yasak)
kapı:
  - onboarding cevapsız ilerlemiyor
  - X/skip yok
  - adım 4 otomatik onaylanıyor
  - grep: pembe zemin / kiraz metin / 999px hap = 0
  - .empty ve .loading tanımlı ve kullanımda
  - sabit ms kaçağı = 0
  - reduced-motion'da hareket duruyor
  - coach motoru canlıda çalışıyor
karar:
  - whimsy dozu → ajan karar verir
```

### FAZ 4 — moves · my-moves · my-program
```yaml
kapsam: [M1, M2, M3, M4, MM1, MM2, MM3, MP1, MP2, MP3, MP4, MP5, G7]
girdi: [.empty, .loading, kart sistemi, hareket token'ları]
teslim:
  - moves: 386 kart render, kart sisteminde, her kartta hangi eklem +
    mono hedef + coached(lila)/reference(nötr) etiketi + kalp (SVG)
  - filtre çipleri, mono sonuç sayacı, yüklenirken .loading
  - my-moves: kaydedilenler --pink-soft, boşta .empty + "browse 386 moves"
    butonu, boşken "save to your trainer" gizli
  - my-program: takvim tam genişlik, gün hücresinde hareket + mono skor,
    dolu gün --pink-soft, bugün lila ring
  - GitHub katkı grafiği ("less ▪▪▪ more") kalkar → nokta yoğunluğu
  - week/month/year çip sistemine geçer
  - manifesto başlıkları kalkar, sayfa başlığı tek satır ≤24px
kapı:
  - render edilen kart sayısı = 386
  - coached/reference etiketi görünür
  - "less"/"more" grafiği grep = 0
  - takvim max-width sınırı yok
  - boş durumların hepsinde buton var
karar:
  - grid kolon sayısı → ajan karar verir
```

### FAZ 5 — blog · patch-notes · gizlilik · terms · suggest
```yaml
kapsam: [B2, B3, P1, P2, P3, Z4, S1]
girdi: [.empty, .prose, kart sistemi]
teslim:
  - blog: sekmeler (kutu yok, aktif altı 2px lila), .prose 66ch,
    boş durum .empty deseninde
  - patch-notes üç kolon: ortada girdiler 66ch, sağ/sol ~200px kolonlarda
    Damla'nın 3 fotoğrafı, girdi hizasında, DÖNÜŞÜMLÜ (solda bir, aşağıda
    sağda bir), aynı hizada iki tane olmaz. 4:5 dikey, object-fit cover,
    16px radius + yumuşak gölge, filtre/gradient/rotasyon yok, mono
    altyazı, loading=lazy + width/height. Mobilde kenar kolonları gizli.
  - FOTOĞRAF SADECE BU SAYFADA. Başka hiçbir sayfada yok.
  - patch içerik: gerçek git geçmişinden ≥8 girdi (tarih + versiyon + ne
    değişti + neden). Uydurma yok, kaçırılanlar dahil.
  - gizlilik + terms + gizlilik-tr: .prose, 66ch
  - suggest: .field form sistemi
kapı:
  - patch girdi sayısı ≥ 8
  - fotoğraflar kenarda ve dönüşümlü
  - başka sayfada fotoğraf = 0
  - blog sekmeleri site.css'te tanımlı
karar:
  - hangi 3 fotoğraf, hangi sırada → ajan karar verir
```

### FAZ 6 — generic denetimi
```yaml
kapsam: [46 maddenin tamamı + kalite]
teslim:
  - STATUS.md'de 46 maddenin hepsi işaretli
  - 12 sayfa canlı kontrol
kapı:
  - kaç stylesheet / !important / inline style
  - nav + footer 12 sayfada birebir aynı
  - palet dışı renk yok
  - emoji / gradient / siyah gölge / chevron yok
  - nokta motifi ≥4 ayrı yerde tekrar ediyor
  - hangi sayfada hâlâ araç yerine manifesto var
  - boş durumların hepsinde buton var
  - onboarding cevapsız ilerlemiyor
  - LOGO TESTİ: her sayfa tek tek — logoyu kapat, başka bir fitness/SaaS
    sitesiyle karıştırılır mı? Karışan sayfayı düzelt.
  - sadece bu siteye ait ≥3 an var mı (nokta bulutu · altın satırlı Q&A ·
    onboarding nokta ilerlemesi)
karar:
  - hangi üç şeyi silsem site iyileşir → ajan karar verir, siler
```

---

## 8. DURMA KOŞULLARI

Ajan **sadece** şunlarda durur:
- §4'teki üç kırmızı tetikleyiciden biri
- FAZ 6 bitti

Bunlar dışında: faz biter → commit → deploy → STATUS güncellenir →
**sonraki faz başlar.** Faz sonlarında insan onayı BEKLENMEZ.
Damla döndüğünde STATUS.md'yi okur, beğenmediği yeri söyler.
