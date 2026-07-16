# benchmark-09-marka — premium marka / landing (L1)

STATUS: TODO
KATMAN: L1 (marka / landing)
KAYNAK: 16 Tem marka yöneticisi agent incelemesi (rakipler: Onyx, Kemtai, BetterMe, NTC, Peloton). Rapor: reports/2026-07-16-gymgyme-katman-teshisi.md

## KUZEY YILDIZI (Damla, 16 Tem — agent önerisinin ÜSTÜNE yazar)
- His: **BetterMe / Headspace** — siteye giren insan "iyi bir yerdeyim" demeli. Sıcak, sakin, insana iyi gelen bir yer; teknik demo değil.
- **Fiş-kanıt bandı REDDEDİLDİ** ("yine slop cs projesi gibi duracak"). Test sayısı / landmark sayısı gibi mühendislik kanıtları vitrine ÇIKMAZ; güven hissi sıcaklıktan ve üründen gelir, spec dökümünden değil.
- Aşağıdaki ADIMLAR'dan 5 (fiş-kanıt bandı) İPTAL; kalanlar bu kuzey yıldızına göre yeniden yorumlanır.
- İnşaata başlamadan ÖNCE: BetterMe + Headspace ekranlarından somut referans seti toplanır, tek ekran mockup Damla'ya sunulur, onaysız kod yazılmaz (mockup = kontrat).

## SORUN
Ana sayfa 5 saniyede ürünü söylemiyor: H1 metafor ("✨ personal trainer 🎀 - starring you"), asıl değer cümlesi ("your camera counts your reps, scores your form out of 100...") alt satırda küçük. Motorun çalıştığını gösteren tek video/görüntü yok — kameralı ürünün kanıtı kameradır. "(0)" sayaçları ve "loading the good stuff…" ölü-site sinyali veriyor. Güven sinyalleri (92 test, 33 landmark, 0 upload) FAQ içine gömülü. "14 of these live today, and it is still in training" zayıflık diliyle yazılmış. Flop hissi bunların toplamı.

## KONUM (öneri, Damla onaylar)
- TR: "Kameran koçun: her tekrarını sayar, formunu 100 üzerinden puanlar, canlı düzeltir — ücretsiz ve hiçbir görüntü cihazından çıkmaz."
- EN: "Your camera is the coach: it counts every rep, scores your form out of 100 and fixes it live — free, and nothing ever leaves your device."
- Pazar boşluğu: Onyx paralı/ölü sayılır, Kemtai B2B'ye kaçtı; "ücretsiz + on-device + kanıtlı doğruluk" boş konum.
- Wow demo = canlı rep sayma + form skoru overlay'i; marquee'nin "perdesi" gerçek motor kaydı oynatır ("now showing" gerçek gösterime dönüşür).

## HEDEF
Yabancı 5 saniyede "kamera formumu puanlayan ücretsiz koç" desin, 60 saniyede ilk wow'u yaşasın. Vişne/fiş/marquee kimliği KORUNUR, premium kullanılır.

## TASARIM YASASI (Damla, 16 Tem — bu loop'ta KANUN)
- Renkler ve dil DEĞİŞMEZ; değişen şey tasarımın premium hissetmesi.
- ASLA generik olmayacak: sağı solu boş kalıp içeriğin ortada istiflendiği SaaS landing düzeni YASAK.
- Zekice kurgulanmış layout'lar: asimetri, katmanlı yerleşim, marquee/fiş öğelerinin kompozisyonda gerçek rol aldığı düzen — tam genişlik akıllıca kullanılır.
- Kör iterasyon yasağı geçerli: 2-3 turdan sonra dur, layout eskizini/screenshot'ını Damla'ya göster, onayla ilerle.

## ADIMLAR
1. Hero hiyerarşi takası (index.html): H1 = değer cümlesi (emojisiz), "starring you" satırı ADMIT ONE fiş koçanına iner, "NOW SHOWING" şeridi kalır. Emoji politikası: dekoratifler H1/CTA'dan çıkar.
2. Motor demo klibi: overlay'li 8-10 sn ekran kaydı (img/trailer.webm, <1.5MB, poster'lı muted loop) marquee perdesi olarak. Golden klip Damla'da — ondan kesilir; klip yoksa bu adım Damla klibi verene kadar bekler.
3. CTA tekilleştirme: tek birincil "open the camera", altında sessiz "browse moves" linki.
4. Sıfır avı: hiçbir sayaç "(0)" ya da "…" render etmez; >0 olana kadar gizlenir ya da gerçek seed sayısı basılır (topbar.js, script.js, seed.js).
5. Fiş-kanıt bandı: "92 tests · 33 landmarks · 0 uploads · X measured moves" receipt tipografisiyle hero altına; FAQ detay kalır. Fiş = güven aracı.
6. Tipografi pası: marquee başlıklarına tiyatro-afişi display hissi (css/marquee.css), gövde değişmez.
7. coach.html ilk ekran: playlist kurucusundan önce tek satır vaat + "try one move — 30 seconds" hızlı başlat (benchmark-00-flow ile ortak iş, hangisi önce gelirse yapar).
8. moves.html reframe: "X camera-coached · new moves weekly · 386 total" — zayıflık dili çıkar, rozet diline döner.
9. Yan yana kıyas: yeni hero screenshot'u Onyx + Kemtai hero'larıyla tek görselde, Damla'ya sunulur.

## DONE ÖLÇÜTLERİ
- 5-saniye testi geçer (Damla + 1 yabancı: "neye yarar / bana ne / şimdi ne" üçlüsü cevaplanır).
- Fold üstünde tek birincil CTA; H1'de emoji yok.
- Sitede hiçbir yerde "(0)" görünmez.
- Demo klip <1.5MB, <2 sn'de oynamaya başlar (klip Damla'dan geldiyse).
- Fiş-kanıt bandı canlıda görünür.
- Yan yana rakip kıyasını Damla onaylar.
- Push'lu + canlı URL'de hard refresh ile doğrulanmış, sürüm etiketi güncel.
