# benchmark-08-marka — premium marka / landing (L1)

STATUS: PARKED (Damla, 16 Tem: tasarim 2 gun ertelendi, ~18 Tem devam; mock gymgyme-v3 repoda, deploy bekliyor)
KATMAN: L1 (marka / landing)
KAYNAK: 16 Tem marka yöneticisi agent incelemesi (rakipler: Onyx, Kemtai, BetterMe, NTC, Peloton). Rapor: reports/2026-07-16-gymgyme-katman-teshisi.md

## KUZEY YILDIZI (Damla, 16 Tem — agent önerisinin ÜSTÜNE yazar)
- His: **BetterMe / Headspace** — siteye giren insan "iyi bir yerdeyim" demeli. Sıcak, sakin, insana iyi gelen bir yer; teknik demo değil.
- **Fiş-kanıt bandı REDDEDİLDİ** ("yine slop cs projesi gibi duracak"). Hero'da spec dökümü YOK; güven hissi sıcaklıktan ve üründen gelir.
- **AMA (Damla, 16 Tem düzeltme): mühendislik hikayesi ÇIKACAK — patch notes / developer log formatında.** Oyunların patch notes'u gibi: "bu hafta neyi düzelttik, ne eklendi" tonunda bir dev-log köşesi. Bu spec dökümü değil, kullanıcıyla BAĞ kuran bir öğe (build-in-public'in üründeki hali). Yeri hero değil; kendi köşesi/sayfası olur, sıcak dille yazılır.
- Aşağıdaki ADIMLAR'dan 5 (fiş-kanıt bandı) İPTAL; yerine patch-notes/dev-log köşesi tasarlanır. Kalan adımlar kuzey yıldızına göre yeniden yorumlanır.
- İnşaata başlamadan ÖNCE: BetterMe + Headspace ekranlarından somut referans seti toplanır, tek ekran mockup Damla'ya sunulur, onaysız kod yazılmaz (mockup = kontrat).

## SORUN
Ana sayfa 5 saniyede ürünü söylemiyor: H1 metafor ("✨ personal trainer 🎀 - starring you"), asıl değer cümlesi ("your camera counts your reps, scores your form out of 100...") alt satırda küçük. Motorun çalıştığını gösteren tek video/görüntü yok — kameralı ürünün kanıtı kameradır. "(0)" sayaçları ve "loading the good stuff…" ölü-site sinyali veriyor. Güven sinyalleri (92 test, 33 landmark, 0 upload) FAQ içine gömülü. "14 of these live today, and it is still in training" zayıflık diliyle yazılmış. Flop hissi bunların toplamı.

## KONUM (öneri, Damla onaylar)
- TR: "Kameran koçun: her tekrarını sayar, formunu 100 üzerinden puanlar, canlı düzeltir — ücretsiz ve hiçbir görüntü cihazından çıkmaz."
- EN: "Your camera is the coach: it counts every rep, scores your form out of 100 and fixes it live — free, and nothing ever leaves your device."
- Pazar boşluğu: Onyx paralı/ölü sayılır, Kemtai B2B'ye kaçtı; "ücretsiz + on-device + kanıtlı doğruluk" boş konum.
- Wow demo = canlı rep sayma + form skoru overlay'i; marquee'nin "perdesi" gerçek motor kaydı oynatır ("now showing" gerçek gösterime dönüşür).

## HEDEF
Yabancı 5 saniyede "kamera formumu puanlayan ücretsiz koç" desin, 60 saniyede ilk wow'u yaşasın, ve "iyi bir yerdeyim" hissi alsın. Mevcut kimlik öğeleri (vişne/fiş/marquee) premium hisse hizmet ediyorsa kalır, etmiyorsa değişir — karar mockup turunda Damla'nın.

## TASARIM YASASI (Damla, 16 Tem — bu loop'ta KANUN)
- GÜNCELLEME (16 Tem akşam): "rengi/konsepti koru" şartı ESNEDİ — o şart premium hissi öldürüyorsa renk ve konsept DEĞİŞEBİLİR ("ısrar etmiyorum"). Premium his (BetterMe/Headspace "iyi bir yerdeyim") kazanır. Değişiklik yine somut referans + mockup onayıyla gider.
- ASLA-YAPMA listesi MUTLAK, hiçbir esneme yok:
  - ortada istiflenen, iki yanı boş generic SaaS landing düzeni
  - slop CS projesi hissi — TANIMI (Damla, 16 Tem): kötü dizilmiş, müşteri gözüyle kurgulanmamış web 1.0 sayfalar; ÖLÜ hissiyatı veren bu. (Spec dökümü/debug metreleri ayrı birer madde ama CS-ödevi hissinin özü YERLEŞİM ve müşteri gözü eksikliği)
  - mor, gradient, pill badge, emoji-bullet, renkli-tek-kelime, krem zemin
  - ölü boşluk; "(0)" sayaçları ve "loading…" ölü-site sinyalleri
  - H1/CTA'da dekoratif emoji yığını
  - zayıflık dili ("still in training" tonu)
- Zekice kurgulanmış layout'lar: asimetri, katmanlı yerleşim, tam genişlik akıllıca kullanılır.
- GEREKSİZ BORDER / GÖRÜNÜR YATAY-DİKEY ÇİZGİ YOK (Damla, 16 Tem): hiza çizgiyle DEĞİL boşluk ritmi, tipografi ölçeği, renk blokları ve yumuşak gölgeyle hissettirilir. Omurga görünmez kalır.
- Kör iterasyon yasağı geçerli: 2-3 turdan sonra dur, layout eskizini/screenshot'ını Damla'ya göster, onayla ilerle.

## KONSEPT (16 Tem akşam, Damla ile konuşuldu — mockup bundan çıkar)
- İçerinin ana ekranı "today": selamlama + günün önerilen seansı + tek başlat. Koç sekme değil, "başla"nın fiili. Alt dock en fazla 3: today / moves / me. **AMA today = ÜYE ekranı; üye olmayan today ile karşılanmaz.**
- Üye olmayan: landing = nav'sız tek kapılı davet; koçun sesiyle konuşan kısa satırlar + gerçek motor kaydı + tek CTA. (Misafir "just try it" yolu loop 07-flow'da.)
- Koça tipografik kimlik: hep aynı ses, lowercase, kısa sıcak cümleler.
- Fiş = HATIRA: her biten seans tarih/rep/skor basan bir koçan üretir, geçmiş = koçan çekmecesi. Vitrin kanıtı değil ödül objesi.
- Renk: sıcak beyaz zemin, mürekkep metin, vişne tek vurgu, nane sadece "form iyi" anı.

## ADIMLAR
1. Hero hiyerarşi takası (index.html): H1 = değer cümlesi (emojisiz), "starring you" satırı ADMIT ONE fiş koçanına iner, "NOW SHOWING" şeridi kalır. Emoji politikası: dekoratifler H1/CTA'dan çıkar.
2. Motor demo klibi: overlay'li 8-10 sn ekran kaydı (img/trailer.webm, <1.5MB, poster'lı muted loop) marquee perdesi olarak. Golden klip Damla'da — ondan kesilir; klip yoksa bu adım Damla klibi verene kadar bekler.
3. CTA tekilleştirme: tek birincil "open the camera", altında sessiz "browse moves" linki.
4. Sıfır avı: hiçbir sayaç "(0)" ya da "…" render etmez; >0 olana kadar gizlenir ya da gerçek seed sayısı basılır (topbar.js, script.js, seed.js).
5. İPTAL (fiş-kanıt bandı RED) → yerine: patch notes / dev-log köşesi — oyunlardaki gibi "bu hafta neyi düzelttik" tonunda, sıcak dille, kendi köşesinde/sayfasında. Bağ kuran öğe, spec dökümü değil.
6. Tipografi pası: marquee başlıklarına tiyatro-afişi display hissi (css/marquee.css), gövde değişmez.
7. coach.html ilk ekran: playlist kurucusundan önce tek satır vaat + "try one move — 30 seconds" hızlı başlat (benchmark-07-flow ile ortak iş, hangisi önce gelirse yapar).
8. moves.html reframe: "X camera-coached · new moves weekly · 386 total" — zayıflık dili çıkar, rozet diline döner.
9. Yan yana kıyas: yeni hero screenshot'u Onyx + Kemtai hero'larıyla tek görselde, Damla'ya sunulur.

## DONE ÖLÇÜTLERİ
- 5-saniye testi geçer (Damla + 1 yabancı: "neye yarar / bana ne / şimdi ne" üçlüsü cevaplanır).
- Fold üstünde tek birincil CTA; H1'de emoji yok.
- Sitede hiçbir yerde "(0)" görünmez.
- Demo klip <1.5MB, <2 sn'de oynamaya başlar (klip Damla'dan geldiyse).
- Patch-notes/dev-log köşesi canlıda görünür ve sıcak dille yazılmış.
- Yan yana rakip kıyasını Damla onaylar.
- Push'lu + canlı URL'de hard refresh ile doğrulanmış, sürüm etiketi güncel.
