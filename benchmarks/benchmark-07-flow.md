# benchmark-07-flow — ürün akışı (L2)

STATUS: TODO
KATMAN: L2 (ürün akışı / navigasyon)

## SORUN
İki ürün (dizin + trainer) tek çatıda köprüsüz yarışıyor. index.html hem landing hem directory (index.html:102 `#directory` + seed.js/script.js); "moves list" ile "directory" farkı müşteri için anlaşılmaz. Soğuk ziyaretçinin kameraya giden risksiz hızlı yolu yok (coach.html zorunlu session adımıyla açılıyor). Bunlar Damla'nın 15 Tem 6 kararından #1 ve #6 — karar verilmiş, loop'a hiç bağlanmamıştı.

## HEDEF
Landing'den kameranın saydığı ilk rep'e ≤ 3 tık / ≤ 30 sn. Ana sayfa tek kimlik (marquee + değer + FAQ), dizin moves.html'de yaşar.

## ADIMLAR
1. index'teki directory DOM'unu + seed.js/script.js yüklemesini moves.html'e taşı; iki hareket kaynağını (seed.js dış-link dizini + MOVE_DB) tek listede birleştir ya da tek sayfada net iki bölüm yap.
2. index.html sadece marquee + değer + tek CTA + FAQ kalır.
3. "just try it" yolu: coach.html'e session kurmadan tek hareketle giren hızlı başlangıç (örn. arm raise, oturan da sayabilir).
4. Dizindeki koçlanabilir her hareket satırından koça geçiş linki ("train with camera"); koçlanmayanlar "reference" etiketi taşır (bait-and-switch = 0).
5. Topbar'ı yeni yapıya göre sadeleştir (my moves/my program kalır, directory=moves tekilleşir).

## DONE ÖLÇÜTLERİ
- index.html'de directory DOM'u ve seed.js/script.js script etiketi YOK.
- Landing → sayan ilk rep: ≤ 3 tık, session kurulumu şart değil.
- moves.html'de koçlanan/koçlanmayan ayrımı görünür rozetle.
- Damla telefonda akışı gezip onaylar; push'lu + canlı URL'de doğrulanmış.
