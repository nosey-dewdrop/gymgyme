# devlog — gymgyme koç, build in public

IG için hook'lu 30-60 sn reel scriptleri. İlk cümle KANCA. Damla seslendirir. Kaynak: BUILD-LOG.md. Sınır yok, biriktirilecek.

---

## Reel 1 — kameran seni izliyor ama hiçbir yere gitmiyor

**Hook (ilk 2 sn):** "Bu uygulama kameranla squat'ını izliyor. Ama tek bir kare bile telefonundan çıkmıyor."

**Anlatı (~40 sn):** Bir antrenman koçu yapıyorum: kameran seni görüyor, tekrarını sayıyor, formunu düzeltiyor. Ama bir koçu yaparken ilk kararım teknik değil, ahlakiydi. Seni görmesi için vücudunun kamera görüntüsünü işlemesi lazım — bu dünyadaki en hassas veri. Çoğu uygulama bunu bir sunucuya yollar. Ben en baştan dedim ki: hiçbir kare bu cihazdan çıkmayacak. Motor senin tarayıcının içinde çalışıyor, kamera görüntüsü hiçbir yere gitmiyor. Gizlilik sonradan yapıştırdığın bir şey değil — en başta verdiğin bir karar.

**Görsel:** ekranda canlı iskelet + "0 sunucu, 0 upload" yazısı; telefon eldeyken "hiçbir yere gitmiyor" vurgusu.
**Format:** reel

---

## Reel 2 — motoru JavaScript'le değil C++'la yazdım

**Hook (ilk 2 sn):** "Bir web uygulamasının motorunu JavaScript'le değil C++'la yazdım. Ve sebep hız değildi."

**Anlatı (~45 sn):** "Motor" diyoruz ama HTML bir motor değil — HTML çerçeve. Motor, açıyı ölçen, tekrarı sayan, formu yargılayan mantık. Bunu JavaScript'te yazabilirdim, performansı da yeterdi. Ama C++'ı seçtim, WebAssembly'ye derledim. Sebep hız değil: bu matematik JS'te de akardı. Sebep, gerçek bir dil, gerçek bir motor istemem — "her şey JS, her şey HTML slop" dünyasından çıkmak. Bedeli var: site artık bir derleme adımı istiyor. Ama çıktı iki küçük dosya, site hâlâ statik. Gözleri hazır bir modelden alıyorum, ama beyni kendim yazıyorum.

**Görsel:** C++ kodu → motor.wasm → tarayıcıda çalışan sayaç; "speed wasn't the reason" alt yazı.
**Format:** reel / carousel

---

## Reel 3 — yarım yaptığın squat'ı saymıyor

**Hook (ilk 2 sn):** "Uygulama tekrarını sayıyor. Ama yarım yaptığın squat'ı saymıyor — 'o sayılmadı' diyor."

**Anlatı (~40 sn):** Saymak kolay. Doğru saymak zor. Motor sadece "aşağı-yukarı" gördüğünde saymıyor; gerçekten dibe indin mi ona bakıyor. Anlamlı bir iniş yaptın ama dibe ulaşmadan döndüysen, bunu yakalıyor: pes bir "bzz" sesi, hafif bir titreşim, ekranda "o sayılmadı, biraz daha in". Ufak kıpırtıları da eliyor — her titreşimi tekrar sanmıyor. Üstüne her tekrara 100 üzerinden bir puan veriyor: derinlik, tempo, kontrol. Yani sana sadece kaç değil, nasıl yaptığını söylüyor.

**Görsel:** yarım squat → "not counted"; tam squat → koca sayaç + "88" puan.
**Format:** reel

---

## Reel 4 — kameraya doğru eğilip motoru kandırmaya çalıştım

**Hook (ilk 2 sn):** "Kameraya doğru eğilip motoru kandırmaya çalıştım. 3 boyutta yakaladı."

**Anlatı (~40 sn):** Kamera 2 boyutlu görür. Dizini kameraya doğru bükersen, ekranda düz görünür — motor 'ayaktasın' sanır, klasik bir kör nokta. Bunu çözmek için modelin verdiği 3 boyutlu dünya koordinatlarını kullandım: açıları gerçek metrik uzayda ölçüyorum, perspektif kısalması kayboluyor. Artık kameraya dönük bir büküm bile kaçmıyor. Aynı 3B veriyle formu da yargılıyor: dizlerin içe çöküyorsa "dizlerini dışa it", sırtın devriliyorsa "göğsünü kaldır" — ama sadece o kuralın görülebildiği açıdan. Emin olmadığında susuyor.

**Görsel:** yandan düz görünen büküm → 3B'de "bottom" yakalanıyor; "you can't fool it" alt yazı.
**Format:** reel

---

## Reel 5 — "backend yok" demiştim, sonra fikir değişti

**Hook (ilk 2 sn):** "Aylarca 'backend yok' dedim. Sonra 'olmaz, database'e geçelim' dedik. Ama kameran hâlâ hiçbir yere gitmiyor."

**Anlatı (~45 sn):** gymgyme'nin kuralı 'sunucu yok'tu. Sonra fark ettim: bunu gerçek bir ürün yapan şey hesap — antrenmanların cihazlar arası seninle gelsin, ileride bir para modeli otursun. O yüzden gerçek bir database ekledim, hesap ekledim. Ama kritik çizgiyi korudum: kamera ve video hâlâ sadece cihazda. Database'e giden tek şey seansın sayıları — kaç tekrar, skor, tarih. Görüntü asla. Veri toplamaya başladığın an gizlilik metni ve onay da aynı gün çıktı, sonraya bırakmadan. Yön değiştirmek zayıflık değil; hangi çizgiyi asla geçmeyeceğini bilmek güç.

**Görsel:** "no backend" üstü çizili → "accounts + db"; yanında "video: still on your device only".
**Format:** reel / carousel
