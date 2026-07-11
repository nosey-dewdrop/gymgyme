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

## Yol haritası (19 aşama, 0–18)

Her aşama tek başına çekilebilir gerçek bir adım — biri bitince küçük bir "oldu" anı, bir reels. Sıra kabaca **görmek → anlamak → saymak → düzeltmek → ürünleştirmek** diye ilerliyor.

**Görmek**
- **0 · Görme** — kamera + canlı iskelet, cihazda. *(bitti)*
- **1 · Sahne cilası** — ayna hissi, "tüm vücudun çerçeveye sığsın" kılavuzu, kaç kare/saniye ve güven göstergesi. Motor değil ama ilk izlenim.

**Anlamak**
- **2 · İlk açı** — tek eklemi ölç: diz açısı ekranda canlı bir sayı olsun. Motorun ilk ham sinyali.
- **3 · Tüm açılar** — kalça, dirsek, omuz; sol/sağ ayrı. Vücut artık sayılara dönüşüyor.
- **4 · Sinyali temizle** — ham noktalar titrer; yumuşatma (EMA/low-pass) ile açı sinyali stabil. Yoksa sayaç zıplar.
- **5 · Güven kontrolü** — nokta güveni düşükse ("ışık az", "bir adım geri") uyar. Motor kötü veriyle saymasın — bu bir mühendislik dürüstlüğü.

**Saymak**
- **6 · Durum makinesi** — tek harekette (squat) "aşağı" ve "yukarı" fazlarını tanı. Saymanın kalbi.
- **7 · Tekrar sayma** — faz geçişinden bir tekrar üret; büyük sayaç + "tık" (ses/haptik). İlk gerçek motor anı.
- **8 · Yanlış tekrarı reddet** — yarım/eksik hareketi sayma (derinlik eşiği), "yarım kaldı" de. Saymak kolay, doğru saymak zor.

**Düzeltmek**
- **9 · Form kuralları (squat)** — diz-parmak hizası, sırt açısı → "biraz daha in", "sırtın düz". Koç burada koç oluyor.
- **10 · İkinci hareket** — push-up ya da lunge ekle; kural setini genelleştir (her hareket = bir eşikler tablosu). Tek harekete gömülü kalmasın.

**Ürünleştirmek**
- **11 · Kütüphaneye bağla** — gymgyme'deki hareketi seç → o harekete özel koç modu açılsın. Dizin ile motor birleşir.
- **12 · Hareket kural verisi** — moves verisine açı eşikleri + talimat alanları; yeni hareket = veri eklemek, kod değil. Genişleyen sistem.
- **13 · Set & dinlenme akışı** — "3 set x 12", set arası dinlenme sayacı, sesli yönlendirme. Tek tekrardan tam antrenmana.
- **14 · Seans özeti** — kaç tekrar, ortalama derinlik, form skoru; bölge bölge küçük rapor. Yapılandırılmış çıktı (stitchu ruhu).
- **15 · "Programım"a bağla** — seansı gymgyme planlayıcısına işle, "en son ne zaman yaptın" güncellensin. Motor ürünün geri kalanıyla konuşsun.
- **16 · Ton & erişilebilirlik** — VOICE diline uygun, suçlamasız cümleler; sesli sayım; düşük görme/renk körü uyumu. Soğuk bir makine değil.
- **17 · Mobil & performans** — telefon kamerası, dikey çerçeve, lite model/GPU, düşük pil. Çoğu insan telefonla antrenman yapacak.
- **18 · Yayına aç** — menüye ekle, ilk kullanım onboarding'i, gizlilik/consent metni (cihazda çalışır, kayıt yok — KVKK temiz). Artık herkese açık.

Büyük ve çok oturumluk iş — acele yok. Bittiğinde gymgyme "linklere bak"tan "seni izleyip çalıştıran koç"a dönüşmüş olacak: aynı site, bambaşka bir kalp.
