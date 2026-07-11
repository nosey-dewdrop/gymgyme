# gymgyme coach — yapım günlüğü (build in public)

Bu dosya ham malzeme. Her aşamada "ne yaptım" değil, **"durum şöyleydi, şu yüzden böyle karar verdim"** yazıyorum — sen seslendirirken kendi dilinle güzelleştirirsin. Reels/vlog anlatısı buradan çıkacak.

Ne yapıyoruz: gymgyme bugüne kadar bir **dizin**di — ev antrenmanı linkleri ve hareketler. Faydalı ama "slop": sana bir şey göstermiyor, sadece listeliyor. Ekleyeceğimiz şey bir **motor**: kameran seni izleyip hareketini takip etsin, tekrarını saysın, formunu düzeltsin. Dizin "bak, şu hareket var" der; motor "hadi, ben sayıyorum, biraz daha in" der.

En kritik karar en başta verildi: **her şey senin cihazında çalışacak, görüntü hiçbir yere gitmeyecek.** İki sebep. Biri ilke: yüz/vücut kamera görüntüsü en hassas veridir, onu bir sunucuya yollamak hem yanlış hem KVKK kâbusu. İkincisi mimari: gymgyme'nin kuralı "backend yok". Kamera analizini tarayıcının içinde yaparsak bu kuralı hiç bozmadan, sunucu maliyeti sıfırla gerçek bir motor kurmuş oluyoruz. Yani gizlilik ve mimari aynı kararda buluştu — bedava değil, doğru olduğu için böyle.

---

## Aşama 0 — Görme (bitti)

Bir koç önce **görmeli**. Saymadan, düzeltmeden önce vücudu okuyabilmesi lazım. O yüzden ilk aşama tek bir şeye odaklandı: kamerayı aç, ve ekranda gerçek zamanlı olarak vücudumun **33 noktasını** (omuz, dirsek, kalça, diz, bilek...) bir iskelet olarak çizdir.

Bunu sıfırdan yazmadım, çünkü yazmak yanlış olurdu. Bir görüntüden "işte dirsek burada" demek — insan pozu tahmini — yıllarca eğitilmiş dev bir yapay zeka modeli işi; onu ben yeniden yazsam ne öğrenirdim ne de iyi olurdu. Onun yerine Google'ın **MediaPipe Pose** modelini kullandım: bana her karede 33 noktayı hazır veriyor. **Asıl motor benim yazacağım kısım** — o noktalardan tekrarı tanımak, açıyı ölçmek, formu yargılamak. Model gözleri veriyor; beyni ben yazacağım. Bu ayrım önemli: kütüphaneye "yaş kaç / kaç tekrar" diye sormuyoruz, biz kendimiz ölçüyoruz.

Teknik olarak neden bu şekilde: model ve çalıştıran kod (WASM) bir CDN'den geliyor ama **tarayıcının içinde** koşuyor. Yani dosyalar internetten inse de, kameranın gördüğü kareler senin cihazından **hiç çıkmıyor**. Ekranı bir aynaya çevirdim (görüntüyü yatay çevirdim) çünkü insan antrenman yaparken kendini aynada görmeye alışık — sağ el sağda olsun.

Kamerayı otomatik açmadım; bir "start" düğmesine bastırıyorum. Sebebi hem nezaket (izinsiz kamera açmak korkutucu) hem dürüstlük: kullanıcı ne zaman görüldüğünü bilsin. Sayfayı şimdilik menüye de koymadım, kimse yanlışlıkla denk gelmesin — önce çalıştığını görelim, sonra herkese açarız.

Bu aşama gymgyme'nin dizininde tek bir şeyi bile bozmuyor: ayrı bir sayfa (`coach.html`), kendi başına duruyor. Slop'a dokunmadan yanına motoru koymaya başladık.

**Sırada:** artık görüyor; şimdi **anlamaya** başlayacak — noktalardan eklem açılarını (diz, kalça, dirsek) canlı hesaplamak. Saymanın ham sinyali o.

---

## Yol haritası (kabaca 6 aşama)

- **0 · Görme** — kamera + canlı iskelet, cihazda. *(bitti)*
- **1 · Açı okuma** — noktalardan eklem açıları (diz/kalça/dirsek) canlı çıksın. Motorun ham sinyali.
- **2 · Tekrar sayma** — tek hareket üzerinde (mesela squat) in-çık durumunu tanıyan bir mantık → say. İlk gerçek "motor".
- **3 · Form kontrol** — açı eşikleriyle "biraz daha in", "sırtın düz kalsın" gibi anlık geri bildirim.
- **4 · Hareket kütüphanesine bağlama** — gymgyme'deki hareketi seç → o harekete özel koç modu; her harekete kendi kuralı.
- **5 · Cila + seans** — tam bir set (tekrar/dinlenme), seans özeti, "programım"a bağlanma, mobil + erişilebilirlik.

Her aşama kendi içinde birçok küçük, çekilebilir adıma bölünür (build in public için bol malzeme). Büyük ve çok oturumluk iş — acele değil, her aşama ayrı bir "oldu" anı.
