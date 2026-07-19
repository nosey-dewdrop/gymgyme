# gymgyme — PROTOKOL

Fazlar arası sözleşme sistemi. Amaç: her turda insan kararı beklemeden
FAZ 3→6'yı kendi kendine yürütmek, insanı yalnızca **zevk kararlarında**
rahatsız etmek.

Okuma sırası: `PROTOKOL.md` (bu dosya) → `HANDOFF.md` (46 madde + faz
kapsamları) → `STATUS.md` (nerede kalındı) → `DECISIONS.md` (verilmiş
kararlar, tekrar sorulmaz).

---

## 0. NASIL ÇALIŞTIRILIR

Tek komut yeter:

```
PROTOKOL.md'yi oku ve sıradaki fazı yürüt.
```

Ajan kendi başına: fazı okur → yapar → kapıyı koşar → geçerse commit +
deploy + STATUS günceller → **bir sonraki faza kendiliğinden geçer.**

Durduğu tek yer: §4'teki KIRMIZI tetikleyiciler. Onlar dışında sormaz.

---

## 1. DEĞİŞMEZLER (hiçbir faz ihlal edemez)

Bunlar sözleşmenin anayasası. Bir faz bunları ihlal ediyorsa faz yanlıştır,
kural değil.

1. Tek stylesheet: `css/site.css`. Yeni CSS dosyası yok, `!important` yok,
   inline `<style>` yok.
2. Copy'ye dokunulmaz. Kesilebilir, kısaltılamaz, yeniden yazılamaz.
   Yeni metin gerekirse aynı ses: küçük harf, kuru, ünlemsiz, iddia değil
   ölçü.
3. Palet: `--paper --wash --ink --mut --line --lila --lila-soft --pink
   --pink-soft`. Başka renk yok. **Lila = motorun çıktısı**, **pembe =
   kullanıcının verisi**. İkisi de dekoratif kullanılmaz.
4. Emoji yok. Gradient yok. Siyah/dar gölge yok. Chevron yok.
   Radius: `--r-sm 10px` (buton, çip, input), `--r 16px` (kart, blok),
   `--r-lg 20px` (büyük panel).
5. Kart sistemi: `--wash` zemin, çerçevesiz, dinlenmede gölgesiz,
   26px padding, hover'da `translateY(-2px)` + lila tonlu yumuşak gölge.
6. Tek motif: nokta. İskelet çizgisi, illüstrasyon, ikon seti yok.
7. Hareket token'ları dışında sabit süre yazılmaz.
   `prefers-reduced-motion` altında tüm hareket durur.
8. Canlıda doğrulanmadan hiçbir madde "kapandı" sayılmaz.
9. `coach.js`'in çalışan motoruna dokunulmaz (ortak parça `engine-core.js`).
10. Kapı düşerse sonraki faza geçilmez.

---

## 2. FAZ SÖZLEŞMESİ — şema

Her faz bu şemayla tanımlıdır. Ajan fazı bu alanlara göre yürütür.

```yaml
faz: <numara> — <ad>
kapsam: [<HANDOFF madde kodları>]
girdi:      # bu faz başlamadan var olması gereken
  - <önceki fazın ürettiği artefakt>
teslim:     # bu fazın üreteceği
  - <dosya / bileşen / davranış>
miras:      # sonraki fazların kullanacağı ortak sistem
  - <site.css'te tanımlanan sınıf / token>
kapı:       # çalıştırılabilir kontroller — hepsi geçmeli
  - <komut> → <beklenen sonuç>
zevk_karari:  # insana sorulacak, otomatik karar verilmez
  - <soru>
```

---

## 3. KAPI = ÇALIŞTIRILABİLİR

Kapı bir cümle değil, bir script. `scripts/gate.sh` içinde her fazın
fonksiyonu olur; `./scripts/gate.sh 3` çalışır, çıktısı STATUS'a yapışır.

Her fazda koşan **evrensel kontroller**:

```bash
# tek stylesheet
for f in *.html; do grep -c 'rel="stylesheet"' $f; done   # hepsi 1
grep -rc '!important' css/                                 # 0
grep -rn '<style' *.html                                   # boş
# emoji
grep -rP '[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]' *.html   # boş (✦✧ hariç)
# palet dışı renk
grep -rEo '#[0-9a-fA-F]{3,6}' css/site.css | sort -u        # sadece 9 token
grep -rn 'rgba(0,0,0' css/site.css                          # 0
# radius kaçağı
grep -rn 'border-radius: *[0-9]px' css/site.css | grep -v 'var(--r'  # 0
# sabit süre kaçağı
grep -rnE '[0-9]+ms' css/site.css | grep -v 'var(--dur'     # 0
# kabuk tutarlılığı
# nav ve footer bloklarını 12 sayfada diff'le → birebir aynı
# canlı doğrulama
curl -s <url> | grep -c <beklenen>                          # faz bazlı
```

**Kapı düşerse:** faz kapanmaz, ajan düzeltir, tekrar koşar. Üç denemede
geçmezse → KIRMIZI (bkz. §4).

---

## 4. OTONOMİ KURALLARI — ne zaman sorar, ne zaman sormaz

### YEŞİL — kendi karar verir, sormaz
- Uygulama detayı: sınıf adı, dosya yapısı, DOM sırası, JS mimarisi
- Değişmezlerin nasıl uygulanacağı (hangi flex/grid, hangi breakpoint)
- HANDOFF'ta zaten yazılı olan her şey
- Kapı düzeltmeleri
- Küçük copy taşıma (cümleyi bozmadan yerini değiştirmek)

### SARI — kendi karar verir, **DECISIONS.md'ye yazar**, sormaz
- İki eşit iyi çözüm arasında seçim → birini seç, gerekçesini yaz
- HANDOFF'ta belirsiz kalmış detay → makul olanı seç, yaz
- Küçük kapsam genişlemesi (aynı fazın içinde, aynı madde kodunda)
- Teknik borç oluşturmak → borcu yaz

### KIRMIZI — **durur ve sorar**
1. Bir DEĞİŞMEZ ihlal edilmeden iş bitmiyorsa
2. Copy değişikliği gerekiyorsa (kesme değil, değiştirme)
3. Kapı 3 denemede geçmediyse
4. Çalışan motoru (`coach.js`, wasm, mediapipe) bozma riski varsa
5. 46 maddede olmayan yeni bir iş açılması gerekiyorsa
6. `zevk_karari` alanındaki sorular — bunlar hep insana aittir

**Sorular biriktirilir, faz sonunda TEK mesajda sorulur.** Her soruda:
seçenekler + ajanın önerisi + gerekçe. Ajan önerisiyle devam eder, insan
itiraz ederse geri alınır. Tek istisna: 1, 2 ve 4 numaralı tetikleyiciler
— onlarda beklenir.

---

## 5. KENDİNİ DEĞİŞTİRME (self-amendment)

Bir faz, sonucuna bakarak planı değiştirebilir. Kural:

- **HANDOFF maddesi silinemez.** Sadece "gereksiz" olarak işaretlenir,
  gerekçesiyle. (Örnek: I3 "worth+how birleştir" → uygulamada iki bölümün
  farklı sorulara cevap verdiği görüldü, ritim kırma yeterli.)
- **Yeni madde eklenebilir**, kod verilerek: `X1, X2...`. Eklenen madde
  hangi fazda kapanacağını da yazar.
- Faz sırası değiştirilebilir, gerekçe DECISIONS.md'ye yazılır.
- Değişmezler değiştirilemez — sadece insan değiştirir.

Her değişiklik `DECISIONS.md`'ye şu formatta:

```
## <tarih> · FAZ <n> · <karar başlığı>
Durum: <ne oldu>
Karar: <ne seçildi>
Gerekçe: <neden>
Etki: <hangi madde/faz değişti>
```

Bu dosya sayesinde aynı soru iki kez sorulmaz.

---

## 6. STATUS.md formatı

```
## FAZ n — <ad>   [devam | kapı geçti | KIRMIZI]
| kod | durum | kanıt |
|-----|-------|-------|
| C1  | kapandı | canlı grep: pembe zemin 0 |
| C3  | açık    | onboarding adım 2'de |
Kapı: <gate.sh çıktısı özeti>
Sonraki: FAZ n+1
Biriken sorular: <faz sonunda sorulacaklar>
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
  - onboarding: 4 adım, cevapsız ilerlemez, X yok, atlama yok,
    yatay kaydırma geçiş, nokta ilerleme göstergesi,
    adım 4 çerçeve tutunca otomatik onay
  - HUD index paneliyle birebir aynı görsel dil
  - göstergeler satır düzeninde (etiket + mono değer)
  - program listesi yapılandırılmış (ad + mono hedef + tutamaç)
  - hesap paneli kart sistemine girer
  - sayfaya tek isim (nav = başlık = title = footer)
miras:
  - --dur-fast/--dur/--dur-slow/--ease token'ları
  - .empty (boş durum deseni: wash + nokta kümesi + satır + buton)
  - .loading (dağılıp toplanan noktalar; spinner/skeleton yasak)
kapı:
  - onboarding cevapsız ilerlemiyor
  - X/skip yok
  - adım 4 otomatik onaylanıyor
  - grep: pembe zemin / kiraz metin / 999px hap = 0
  - .empty ve .loading site.css'te tanımlı ve kullanımda
  - sabit ms kaçağı = 0
  - reduced-motion'da hareket duruyor
  - coach motoru canlıda çalışıyor (kamera açılıyor, sayıyor, skor veriyor)
zevk_karari:
  - whimsy dozu yeterli mi (nokta dalgası + hairline parıltısı)
```

### FAZ 4 — moves · my-moves · my-program
```yaml
kapsam: [M1, M2, M3, M4, MM1, MM2, MM3, MP1, MP2, MP3, MP4, MP5, G7]
girdi: [.empty, .loading, kart sistemi, hareket token'ları]
teslim:
  - moves: 386 kart render, kart sisteminde, her kartta hangi eklem +
    mono hedef + coached(lila)/reference(nötr) etiketi + kalp
  - filtre çipleri, mono sonuç sayacı, yükleme durumunda .loading
  - my-moves: kaydedilen kartlar --pink-soft, boş durumda .empty +
    "browse 386 moves" butonu, boşken "save to your trainer" gizli
  - my-program: takvim tam genişlik, gün hücresinde hareket + mono skor,
    dolu gün --pink-soft, bugün lila ring
  - GitHub katkı grafiği ("less ▪▪▪ more") kalkar → nokta yoğunluğu
  - week/month/year çip sistemine geçer
  - manifesto başlıkları kalkar, sayfa başlığı tek satır ≤24px
kapı:
  - render edilen kart sayısı = 386
  - coached/reference etiketi görünür
  - "less" / "more" grafiği grep = 0
  - takvim max-width sınırı yok
  - boş durumların hepsinde buton var (tek tek listele)
zevk_karari:
  - kart yoğunluğu (grid kolon sayısı) doğru mu
```

### FAZ 5 — blog · patch-notes · gizlilik · terms · suggest
```yaml
kapsam: [B2, B3, P1, P2, P3, Z4, S1]
girdi: [.empty, .prose, kart sistemi]
teslim:
  - blog: sekmeler (kutu yok, aktif altı 2px lila), .prose 66ch,
    boş durum .empty deseninde
  - patch-notes: üç kolon — ortada girdiler 66ch, sağ/sol ~200px
    kolonlarda Damla'nın 3 fotoğrafı, girdi hizasında, DÖNÜŞÜMLÜ
    (solda bir, aşağıda sağda bir), aynı hizada iki tane olmaz.
    4:5 dikey, object-fit cover, 16px radius + yumuşak gölge,
    filtre/gradient/rotasyon yok, mono altyazı, loading=lazy +
    width/height. Mobilde kenar kolonları gizli.
  - FOTOĞRAF SADECE BU SAYFADA. index/coach/moves dahil hiçbir yerde yok.
  - patch içerik: gerçek git geçmişinden ≥8 girdi (tarih + versiyon +
    ne değişti + neden). Uydurma yok, kaçırılanlar dahil.
  - gizlilik + terms + gizlilik-tr: .prose, 66ch
  - suggest: .field form sistemi
kapı:
  - patch girdi sayısı ≥ 8
  - fotoğraflar kenarda ve dönüşümlü (DOM sırası ile kanıtla)
  - başka sayfada <img> ile fotoğraf = 0
  - blog sekmeleri site.css'te tanımlı
zevk_karari:
  - hangi 3 fotoğraf, hangi sırada
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
zevk_karari:
  - hangi üç şeyi silsem site iyileşir → sil
```

---

## 8. DURMA KOŞULLARI

**HER FAZ SONUNDA İNSAN ONAYI BEKLENİR** (19 Tem, Damla'nın emri —
§0/§8'in "sonraki faza kendiliğinden geç" kısmını EZER). Faz biter →
commit → deploy → STATUS.md güncellenir → **DUR.** Damla canlıda bakıp
"devam" diyene kadar sonraki faza GEÇME. Faz İÇİNDE ise §4 yeşil/sarı
kurallarıyla sormadan ilerle; sorular biriktirilir, faz sonunda tek
mesajda sorulur.

Ajan şu durumlarda da (faz ortasında) durur ve insanı bekler:
- KIRMIZI tetikleyici 1, 2 veya 4
- Kapı üç denemede geçmedi
- FAZ 6 bitti

Özet: faz İÇİ otonom, faz SONU insan kapısı. İnsan STATUS.md'yi okur,
biriken soruları tek seferde cevaplar, "devam" der, sonraki faz başlar.
