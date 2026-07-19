# gymgyme — STRATEJİ (19 Tem 2026)

Konumlandırma · psikoloji · ürün · mühendislik · dağıtım · para · 90 gün

---

## 1. KONUMLANDIRMA

### Tek cümle
**Kameran formunu ölçer.**

Ürün geniş olabilir (form check + antrenman + kayıt + paylaşım), ama giriş
cümlesi tek olmak zorunda. İnsan bir ürünü tek bir şey olarak hatırlar,
gerisini içeri girdikten sonra keşfeder. Instagram "kare filtreli fotoğraf"tı.

### Kategori
Kategori adı **form check**. Bu kategori boş.

"AI fitness app" kategorisine girme — orada Peloton, Tempo, Freeletics var,
bütçe savaşıdır. Senin gerçek rakibin **ayna ve seni çeken arkadaşın**.

### Kama (ilk kırılma noktası)
Tek soru: **"am I squatting deep enough?"**

386 hareketle pazarlama yapılmaz. Bir hareketi tam sahiplen, oradan wall
pilates ve glute bridge'e yayıl (kadın kitlede en yüksek arama hacmi).
Kütüphane derinliktir, kama değil.

### Ne satıyoruz
**Cevap.** Motivasyon değil.

Fitness uygulaması motivasyon satar (streak, rozet, program) — ikinci
haftada ölür. Cevap satan ürün rafta durur ve lazım olunca açılır.
Bundan çıkan kural: **streak, rozet, "3 gündür yoksun" bildirimi yok.**

### Ne değiliz
Kalori sayacı değil. Motivasyon uygulaması değil. Bağıran bir AI koç değil.
Fizyoterapist değil (bkz. §12 regülasyon).

---

## 2. PSİKOLOJİ — neden bu ürün işe yarar

**Belirsizlik, tembellikten daha çok engeller.** İnsanlar spor yapmıyor
değil; doğru yapıp yapmadıklarını bilmedikleri için bırakıyorlar. Salonda
aynanın önünde tereddüt, evde hiç geri bildirim. Ürün bu tereddüdü kapatıyor.

**Utanç, fitness ürünlerinin en büyük dönüşüm katili.** Kamerayla çalışan
her uygulama "izleniyorum" hissi yaratır. Senin çözümün yapısal: video
hiçbir yere gitmiyor, ekranda vücut değil nokta bulutu var. "Kimse görmüyor,
matematik görüyor" — bu hem doğru hem rahatlatıcı.

**Kadın kitleye premium hissi veren şey pembe-mor değil, ciddiye alınmak.**
Ölçüm dili ("12 tekrarın 3'ünde diz içe kaydı") saygı gösterir; motivasyon
dili ("harikasın! 💪") küçümser. Ton farkı ürünün kendisi.

**Dürüstlük bağlılık üretir.** "Bu hareketi ölçemiyorum" demek, ölçebildiğin
şeylerdeki iddianı güçlendirir. `coached / reference` ayrımı bir özellik
değil, güven mekanizması.

**Göreli ölçüm mutlaktan daha motive eder.** "Senin dip açın 96°, bugün
104°de kaldın" — kendi geçmişiyle yarışma, başkasıyla değil. Liderlik
tablosu tam tersini yapar ve kitleni kaçırır.

---

## 3. ÜRÜN MİMARİSİ — katmanlar

```
1. ÖLÇÜM ÇEKİRDEĞİ   sayma · skor · hata tespiti · ROM taban çizgisi
2. KÜTÜPHANE         500 hareket · coached/reference · her biri canlı kameralı sayfa
3. SEANS             ölçüm seansı · adaptif set · progresyon merdiveni · zayıf halka
4. KAYIT             takvim · geçmiş · kişisel ilerleme (Strava katmanı)
5. PAYLAŞIM          set kartı (nokta + sayı, vücut yok)
6. KATKI             klip bağışı · hareket spec önerisi
```

Her katman bir alttakine dayanır. Ölçüm güvenilir değilken 3. katmanı
yapmak, yanlış veriye göre kullanıcıyı durdurmak demektir — güveni bir
kerede yok eder.

### Seans tipleri (kendi "hareketlerimiz")
Yeni squat varyantı icat etmenin değeri yok. İcat edilecek şey, motorun
ölçebildiği şeyler etrafında tasarlanmış seanslar:

- **Ölçüm seansı** — 5 dk, antrenman değil test. ROM, simetri, tempo
  kontrolü ölçülür, taban çizgisi çıkar. Ayda bir tekrarlanır. Hiçbir
  uygulamada yok, çünkü kimse ölçemiyor. Antropometrik kalibrasyon için
  zaten gerekli: tek işle iki kazanç.
- **Adaptif set** — skor düşünce set biter. "12'yi tamamladın ama son 3'ün
  skoru 70'in altındaydı, seti burada kesiyorum."
- **Progresyon merdiveni** — zorlaşma kararı takvimle değil eşikle:
  "son üç sette skorun 90+, bulgarian split squat'a hazırsın."
- **Zayıf halka seansı** — en düşük skorlu hareket, en asimetrik taraf,
  en kısıtlı ROM'a odaklı 10 dk.

---

## 4. MOAT — iki ayda yazılamaz hale getirmek

Motor moat değil: MediaPipe açık, pose estimation emtia. Kod kopyalanır,
**kalibre edilmiş yargı kopyalanmaz.** Beş birikimli katman:

### 4.1 Hata taksonomisi
"Tekrar oldu mu" değil, "ne yanlış". Squat için: diz içe kayması (valgus),
butt wink, topuk kalkması, gövde öne eğimi, sağ/sol asimetri, tempo çöküşü.
Her hata için: hangi landmark üçlüsü, hangi eşik, hangi fazda, kaç kare üst
üste görülürse gerçek sayılır.

Hedef: **20 hareket × 8 hata = 160 kalibre edilmiş kural.** Rakip motoru
iki ayda yazar, bu tabloyu yazamaz — her eşik gerçek klipte doğrulanmak
zorunda.

### 4.2 Etiketli klip korpusu
Hareket başına 30-50 klip. Çeşitlilik zorunlu: farklı vücut tipi ve boy
oranı, yan/45°/ön açı, farklı ışık, geniş ve dar kıyafet, farklı telefon
yüksekliği, 15 fps eski cihaz kaydı. Her klip elle etiketli: kaç temiz
tekrar, hangi karede dip, hangi hatalar.

**Korpus açık olmasın.** Doğruluk sayılarını yayınla, klipleri değil.

Hedef: 20 hareket × 40 klip = 800 klip.

### 4.3 Antropometrik uyarlama
Uzun femurlu ile kısa femurluda aynı squat farklı açı üretir. Sabit eşik
haksızlık. Çözüm: ilk sette kişisel ROM ölç, eşikleri taban çizgisine göre
normalize et. Mevcut ürünlerin hepsinin zayıf noktası burası.

### 4.4 Görüş açısı varyantları
Kullanıcı telefonu yan koymaz. Motor önce açıyı tespit etmeli (omuz/kalça
genişlik oranı), sonra o açıya ait spec'i kullanmalı. Yan profilde derinlik
güvenilir, önden değil; önden valgus ölçülür. Ve "bu açıdan ölçemiyorum"
diyebilmeli.

### 4.5 İnsan hakemle kalibrasyon
Skor eğrileri sezgiyle değil, 2-3 sertifikalı antrenörün aynı kliplere
verdiği puanla ayarlanır. Sonra yayınla: *"motorun puanı ile antrenörlerin
puanı arasındaki uyum, antrenörlerin birbirleriyle uyumu kadar."*
Bunu söyleyebilen tek ürün olursun.

### 4.6 Yapısal avantaj: sıfır marjinal maliyet
Rakiplerin donanım veya sunucu maliyeti var, abonelik almak zorundalar.
Sen ücretsiz kalabilirsin. VC parası olan rakip seni fiyatta yenemez —
kendi iş modelini yıkmadan bedavaya inemez. **Taklit edilemez.**

---

## 5. MÜHENDİSLİK — 14 hareketten 500'e

### Teşhis
Darboğaz MediaPipe değil, **spec üretimi.** En iyi modeli koysan 15. hareket
kendiliğinden gelmiyor. Yol model değişimi değil, spec üretiminin
sanayileşmesi.

MediaPipe'ın gerçek sınırları dar: yerde yatan pozisyonlar (uzuv örtüşmesi),
yüzüstü, ön kamerada derinlik belirsizliği, düşük fps'te faz kaçırma.
Çözümleri model değişimi değil: zamansal filtreleme, açı sınıflandırma,
"ölçemiyorum" diyebilme.

### 5.1 Arketip şablonları — asıl kaldıraç
500 spec yazmak imkânsız. 500 hareket bir avuç mekanik kalıptan ibaret:

```
squat · hinge · lunge · press · pull · raise
bridge · plank/hold · crunch · rotation · kick/abduksiyon · balance
```

Her arketip parametrik şablon. Tek tek hareketler onun parametreleri.
İş **12 şablon + 500 parametre satırı**na iner.

### 5.2 Spec DSL + derleme
Spec'ler C++'a gömülü kalmaz, ayrı veri katmanı olur:

```yaml
squat/goblet:
  archetype: squat
  driver: knee
  bottom: 95            # kişisel ROM ile normalize
  lockout: 168
  views: {side: full, front: errors_only}
  errors: [valgus, heel_lift, trunk_lean, tempo_collapse]
  tempo: {ecc: 2, pause: 1, con: 2}
```

Build'de C++'a derlenir (kod üretimi), motor wasm'da sabit hızda kalır.
Yeni hareket = satır eklemek. Tek başına 14 → 200 farkını yaratır.

### 5.3 Üretim hattı
1. **Taslak** — free-exercise-db açıklamasından spec taslağı. Burada LLM
   kullanılabilir, **ama sadece toolchain'de, üründe değil.** Ürün hâlâ
   "no llm, no api call". Patch notes'ta açıkça yaz.
2. **İnsan onayı** — sen ya da antrenör gözden geçirir, kabul/düzelt.
3. **Klip doğrulama** — spec o hareketin etiketli kliplerinde koşar;
   kaçırılan tekrar, yanlış sayım, precision/recall ölçülür.
4. **Etiket kararı otomatik** — eşiği geçerse `coached`, geçemezse
   `reference`. Böylece "500 hareket, 213'ü ölçülüyor, kaydı şurada"
   diyebilirsin. Rakip "500 hareket destekliyoruz" der; fark satar.

### 5.4 Motor iyileştirmeleri (etki sırasına göre)
1. **Zamansal filtreleme** — One Euro / Kalman. En ucuz, en büyük kazanç.
2. **Görüş açısı sınıflandırma** — açıya göre spec seçimi.
3. **Görünürlük eşiği** — landmark visibility düşükse sayma, "seni
   göremiyorum" de. Yanlış sayım, yanlış cevaptan çok daha yıkıcı.
4. **Antropometrik normalizasyon.**
5. **Düşük fps modu** — eski Android'de adaptif örnekleme.
6. En son: model değişimi/fine-tune. Muhtemelen hiç gerekmeyecek.

### 5.5 Altyapı
- **Golden clip regresyon süiti** — korpus CI'da koşar, doğruluk düşerse
  deploy durur. Bu olmadan biriken her şey bir refactor'da buharlaşır.
  92 native test birim testi; asıl lazım olan uçtan uca klip testi.
- **Ray gerekmiyor.** İş utanç verici derecede paralel: iş kuyruğu +
  N worker, tek makine. Motor native C++, saniyeler sürer. Ray'in dağıtık
  zamanlaması bu ölçekte maliyet. Gerekirse korpus on binlere çıkınca.
- CI: her commit'te hızlı süit (arketip başına birkaç klip), gecelik tam süit.
- **Statik site generator (Astro/11ty)** — "beş ayrı kabuk" sorununun
  mimari çözümü. Nav/footer tek dosyada yaşar, bir daha ayrışamaz.
- **Playwright görsel regresyon** — her deploy'da 10 sayfa karşılaştırılır,
  tasarım kaymaları otomatik yakalanır.
- **Plausible/Umami self-host** — çerezsiz. Ölçemezsen büyütemezsin.
- **PWA + offline** — salonda internet kötüdür.

### Sıra
regresyon süiti → spec DSL + derleyici → 12 arketip → 5 hareketle uçtan uca
doğrulama → üretim hattı → 50 hareket → zamansal filtre + açı sınıflandırma
→ 200 → 500

---

## 6. DAĞITIM

### 6.1 Set kartı — en güçlü büyüme aracı
Set bitince tek kare: nokta bulutu figürü, tekrar sayısı, skor, tarih,
altta alan adı. Fotoğraf yok, vücut yok, sadece geometri — **bu yüzden
paylaşılabilir.** Fitness uygulamalarında paylaşım utanç yüzünden çalışmaz;
senin kartında utanılacak bir şey yok. Ürüne özgü avantaj.

### 6.2 SEO — 500 sayfa, her biri canlı kameralı
Hareket sayfası yazıp bırakmak sıradan içerik. Ama her sayfada **o hareketi
ölçen canlı kamera** olursa sayfa okunan değil kullanılan bir şey olur.
"wall pilates form" araması yapan kişi makaleye değil, iki tıkla kendi
formunu ölçtüğü sayfaya düşer. Dwell time, dönüşüm, backlink oradan gelir.

Uzun kuyruk: "squat depth without a mirror", "am i squatting deep enough",
"wall pilates form check", "glute bridge doğru mu".

**Mühendislik ile dağıtım aynı işten çıkıyor** — asıl kaldıraç burada.

### 6.3 Kısa video
Ekran kaydı = reklam. Sayaç artarken diz açısının değiştiği 15 saniye,
hiçbir metnin yapamayacağı işi yapar. Tek format, sonsuz varyant.
İngilizce + Türkçe ayrı hesaplar.

### 6.4 Topluluk
r/xxfitness, r/bodyweightfitness — satış değil, "bunu yaptım, doğruluk
kaydı burada" tonuyla. Senin sesin oraya birebir uyuyor.

### 6.5 Build-in-public
patch notes + doğruluk kaydı kendi başına içerik. stitchu'da işleyen
mekanizma, buraya bire bir taşınıyor.

---

## 7. SOSYAL — sadece algoritmayı besleyen sosyal

Feed, liderlik tablosu, takip, streak, rozet, arkadaş daveti: **hayır.**
Hepsi kritik kütle ister, hepsi generic, hepsi konumu bozar.

İki mekanizma sosyal ama kritik kütle beklemiyor:

- **Klip bağışı** — set sonunda opsiyonel. Video değil, 33 landmark'ın
  zaman serisi (birkaç KB sayı, kimliksiz). Korpusun kendi kendine
  büyümesi. Varsayılan kapalı, açık rıza, geri alınabilir, ne
  gönderildiği ekranda görünür.
- **Hareket spec katkısı** — "suggest a move" sayfası zaten var. Kullanıcı
  hangi eklemin sürdüğünü söyler, sen doğrularsın, adı hareket sayfasında
  durur. Wikipedia tarzı birikimli katkı.

Sıra: önce regresyon süiti + hata taksonomisi, sonra klip bağışı. Bağış,
işleyen süit yoksa işe yaramaz.

---

## 8. PARA

Ücretsiz sözünü bozma — asıl silah o.

1. **Çekirdek ücretsiz, süresiz.** Sayma, skor, kütüphane.
2. **Pro: aylık 3-4 dolar bandı** (rakipler 15-40). Amaç kâr değil,
   düşünmeden alınan fiyat. İçerik: cihazlar arası senkron, ilerleme
   analizi, çevrimdışı paket, seans tipleri.
3. **Ömür boyu ~40-50 dolar.** Abonelik yorgunu kitlede dönüşümü yüksek,
   peşin nakit, sunucu maliyetin yok. **Bunu yapabilen tek oyuncu sensin.**
4. **En yüksek marj: motor lisansı (B2B).** Fizyoterapi klinikleri, pilates
   stüdyoları, kurumsal wellness. Hepsi "kamerayla form takibi" istiyor,
   hiçbiri yazamıyor. Cihazda çalıştığı için onların da sunucu maliyeti yok.
   **Erken keşfet, geç kur:** şimdiden 5-10 stüdyo/fizyoterapistle konuş,
   öğren, ama ürünü onlara göre bükme.

---

## 9. METRİK

**Kuzey yıldızı: ilk 90 saniyede sayılmış tekrarı olan ziyaretçi oranı.**

Tek sayı her şeyi kapsıyor: onboarding çalışıyor mu, kamera izni alınıyor
mu, çerçeve tespiti tutuyor mu, motor sayıyor mu. Yükselirse her şey yükselir.

İkincil: 7 gün dönüş oranı (düşük olması normal, takılma), hareket başına
doğruluk, coached hareket sayısı.

Vanity metrik yok.

---

## 10. 90 GÜN

**Ay 1 — temel**
- FAZ 1-6 tasarım rework'ü bitir (bkz. HANDOFF.md)
- Golden clip regresyon süiti kur
- 5 hareket × 40 klip korpus (çeşitli vücutlar)
- Etiketleme aracı yaz (klibi oynat, boşlukla tekrar işaretle, tuşla hata)

**Ay 2 — sanayileşme**
- Spec DSL + derleyici
- 12 arketip şablonu
- 5 hareketle uçtan uca doğrulama, hata taksonomisi
- Zamansal filtreleme + görünürlük eşiği
- Set kartı özelliği
- İlk 20 hareket sayfası canlı kameralı (SEO başlangıcı)

**Ay 3 — ölçek ve görünürlük**
- 50 harekete çıkar, coached/reference otomatik etiketleme
- Doğruluk kaydını yayınla (ilk sürüm)
- Ölçüm seansı
- Kısa video üretimine başla (haftada 3)
- 5-10 stüdyo/fizyoterapist görüşmesi (öğrenme, satış değil)

---

## 11. RİSKLER

- **Apple/Google bunu OS'a gömerse.** Gerçek risk. Savunma: derinlik —
  onlar üç hareket yapar, sen 500 ve doğruluk kaydı.
- **MediaPipe bağımlılığı.** Alternatifleri (MoveNet, kendi derlemen) bir
  kere araştır, patch notes'a yaz.
- **Tek vücutta kalibrasyon.** Motor sadece bir kişide test edildiyse
  farklı vücut tiplerinde sapar. Hem doğruluk hem etik mesele — özellikle
  kadın kitleye "seni ölçüyorum" diyen üründe. Çeşitlilik, doğruluk
  kaydının en önemli sütunu.
- **Eski Android performansı.** Hedef kitlenin çoğu orada. Düşük fps modu şart.
- **Yanlış sayım güveni yıkar.** Emin değilken sayma; "göremiyorum" de.

---

## 12. REGÜLASYON — kırmızı çizgi

"Fizyoterapist" kelimesini kullanma. Yaralanma değerlendirmesi, ağrı
yorumu, rehabilitasyon programı öneren yazılım tıbbi cihazdır (AB: MDR,
ABD: FDA). Tek kişilik üründe bu işi durdurur.

**Yapılabilir hali:** hata → olası mekanik sebep → deneyebileceğin ayar
tablosu. Sabit metin, cihazda, LLM'siz. Fizyoterapiste danışılarak yazılır.

> **diz içe kayması** · genelde kalça abdüktörleri yorulunca başlar. dip
> derinliğini bir tık azalt, ayakları biraz daha aç, clam shell ısınması dene.

Dil kuralları: teşhis yok, ağrı yorumu yok, "sakatlığı önler" yok, "tedavi"
yok. Ağrı geçen her girdide tek yanıt: bu bir ölçüm aracı, ağrı varsa sağlık
profesyoneline görün.

Klinik tarafa girilecekse **B2B'den, insan döngüde:** hasta evde çeker,
motor ölçer, rapor fizyoterapiste gider, yorumu insan yapar. Sen ölçüm
aleti olursun, regülasyon yükü hafif, gelir yüksek, konum bozulmaz.

---

## 13. REDDEDİLENLER

LLM chatbot / AI koç · streak, rozet, bildirim baskısı · liderlik tablosu ·
sosyal feed · sinema teması · dev serif afiş tipografisi · başlıkta tek
kelime renklendirme · pastel lila + beyaz + gri SaaS paleti · abonelik
zorunluluğu · tıbbi iddia dili · korpusu açık yayınlamak · "AI fitness app"
kategorisinde konumlanmak.
