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

## Reel — "beni çöp adam gibi çiziyordu"

**Hook (ilk 2 sn):** "AI koçum beni bir çöp adam gibi çiziyordu. Parmaklarım 3 dallı bir ağaçtı, dudağım tek bir çizgi. Bu gece onu düzelttim."

**Anlatı (~45 sn):** Bir kamera koçu yapıyorum, kameran seni görüp squat'ını sayıyor. Ama ekranda seni gösterişi berbattı: ince çizgilerden bir iskelet. İnsan öyle değil ki — dudağın kavisli, parmakların dolgun, vücudun hacimli. O yüzden çizim katmanını baştan yazdım. Artık uzuvların kas gibi kalın kapsüller, derinliğe göre gölgeli — yakın olan aydınlık ve dolgun, uzak olan koyu. Yüzün 468 noktalı dolu bir ağ, kavisli dudağın üstüne mürekkeple çiziliyor. Ellerin gerçek eller: avuç + dolgulu parmaklar. Ama bir kural: bu katman SADECE görüntü, sayma motoruna hiç dokunmuyor. Ve telefonu yormasın diye: fps düşerse yüz/el detayı otomatik uykuya geçiyor, vücut hep akıcı kalıyor.

---

## Reel — "eğildiğimi görüyordu ama saymıyordu"

**Hook (ilk 2 sn):** "Squat yapıyorum, koç eğildiğimi görüyor — ama saymıyor. En sinir bozucu bug bu."

**Anlatı (~40 sn):** Motorun squat'ı sayma şekli sabit bir eşiğe bağlıydı: diz açın 120 dereceye inecek. Ama kameraya dönük çömeldiğinde perspektif diz açını olduğundan düz gösteriyor — sen derin iniyorsun, ekrandaki açı 120'ye hiç değmiyor, sayaç sıfır. Derinlik barı doluyor ama tekrar gelmiyor. Çözüm: eşiği herkese sabit koymayı bıraktım. Motor artık senin GERÇEK ayakta duruşunu öğreniyor, dip eşiğini o duruştan 42 derece aşağı koyuyor. Yani "sen ne kadar bükülürsen senin squat'ın o" diyor. Sabit eşik de bir taban olarak kalıyor, kimseden imkansız derinlik istemesin. Test ettim: eski eşiğin üstünde kalan gerçek bir squat artık sayılıyor.

## Reel — "iskelet neden zıplıyor" ve Kalman

**Hook (ilk 2 sn):** "Kamera koçlarında iskelet sürekli zıplar. Sebebini ve gerçek çözümünü buldum: Kalman filtresi."

**Anlatı (~45 sn):** Elini kaldırdığında el bir an gövdenin önünden geçer ve kamera onu kaybeder. O anda çoğu iskelet ya donar ya da zıplar. Çünkü filtreleri sadece "nokta neredeydi" biliyor. Bense her noktaya bir hız hafızası verdim — Kalman filtresi. Nokta kaybolunca "son gördüğümde saniyede şu hızla yukarı gidiyordu, o zaman şimdi buradadır" diyor ve akmaya devam ediyor. Nokta geri gelince ölçümün ne kadar net olduğuna göre otomatik ağırlık veriyor. Bu, Vision Pro'nun ve sinema mocap sistemlerinin kullandığı matematik. Ben de yazabildim çünkü onların mühendisleri de insan. 12 testle matematiğin doğruluğunu kanıtladım — "sanırım düzeldi" demedim, ölçtüm.

## Reel — koç sol-sağ dengesizliğini görüyor

**Hook (ilk 2 sn):** "Squat yaparken farkında olmadan bir bacağına daha çok yükleniyorsun. Motorum bunu görüyor."

**Anlatı (~40 sn):** Çoğu insan bir tarafına telafi yapar — sakatlık sonrası, ya da sadece alışkanlıktan. Gözle fark edilmez ama sakatlık sebebidir. Motora sol ve sağ tarafın açısını aynı anda ölçüp farkı tutmayı öğrettim. Bir taraf diğerinden belirgin fazla çalışıyorsa koç söylüyor: "saydım ama bir tarafın daha çok çalışıyor". Bu fizyoterapistlerin izlediği tam o telafi paterni. Ve dürüst: yandan durduğunda iki tarafı göremezse uydurmuyor, ölçemediğini söylemiyor.

## Reel — kendi kodumu yerden yere vuran bir jüri kurdum

**Hook (ilk 2 sn):** "Kendi kodumu değerlendirmesi için, benden nefret eden beş kişilik bir jüri kurdum."

**Anlatı (~50 sn):** Bir motoru büyütürken en tehlikeli an 'oldu' dediğin andır. O yüzden bir jüri kurdum — bir CS dekanı mühendisliği yerden yere vursun, iki pilates uzmanı hareketleri denetlesin, bir VC paneli 'buna gerek yok, feature bu şirket değil' desin, ve bir nihilist hiçbir şeyi beğenmesin. Sonra bu jüriyi gerçekten koduma saldım, her bulguyu bağımsız doğrulattım. Utandırıcı derecede işe yaradı. En büyüğü: yeni eklediğim bir Kalman katmanının, testler geçmesine rağmen ana yolda bypass edildiğini buldular — faydasını almadan maliyetini ödüyordum. Düzelttim. Sonra dekanın sorusuna kendi silahıyla cevap verdim: katmanın kazancını ölçtüm, ve ölçüm alçakgönüllüydü — saklamadım, commit'e yazdım. İyi mühendislik 'çalışıyor' demek değil, 'yanıldığım yeri aradım ve buldum' demek.
