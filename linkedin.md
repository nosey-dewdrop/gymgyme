# linkedin — damla-essays

Mühendislik kararlarının "neden"i. Her biri 300-500 kelime, LinkedIn / blog için. Kaynak: BUILD-LOG.md. Dil şimdilik Türkçe (İngilizce isteniyorsa çevrilir).

---

## Antrenman koçun seni asla görmemeli

Bir kamera koçu yapmaya karar verdiğimde ilk sorun teknik değil ahlakiydi. Formunu düzeltmek için uygulamanın seni görmesi lazım — dizin ne kadar bükülü, sırtın ne kadar eğik. Ama "seni görmek" demek, elindeki en hassas veriyi, vücudunun kamera görüntüsünü işlemek demek. Piyasadaki çoğu çözüm bu kareleri bir sunucuya yollar, orada işler, sonucu geri gönderir. Ben en baştan şunu söyledim: hiçbir kare bu cihazdan çıkmayacak.

Bu kararı iki ayrı sebep aynı noktada buluşturdu. Birincisi ilke: yüz ve vücut görüntüsü bir insanın verebileceği en mahrem veridir. Onu bir sunucuya göndermek hem etik olarak yanlış, hem de KVKK açısından bir kâbus — sakladığın anda sorumluluğun, sızması ihtimalin, silme yükümlülüğün başlıyor. İkincisi mimari: gymgyme'nin kuralı "backend yok" idi. Kamera analizini tarayıcının içinde yaparsam bu kuralı hiç bozmadan, sıfır sunucu maliyetiyle gerçek bir motor kurabilirdim.

Yani gizlilik ve mimari aynı kararda buluştu. Bu bende kalıcı bir ders bıraktı: gizlilik sonradan üstüne yapıştırdığın bir özellik değil, en başta verdiğin ve sonra her şeyi şekillendiren bir karardır. Sunucuya veri göndermeyeceğime karar verince, motoru da tarayıcıda çalışacak şekilde kurmak zorunda kaldım — ve bu beni daha iyi bir mimariye itti, engellemedi.

Teknik olarak nasıl duruyor: gözler için Google'ın MediaPipe modeli, her karede vücudumun 33 noktasını veriyor. Asıl motoru — o noktalardan tekrarı saymak, açıyı ölçmek, formu yargılamak — kendim C++'ta yazdım, WebAssembly'ye derledim. Model ve çalıştıran kod internetten inse bile, kameranın gördüğü kareler cihazdan hiç çıkmıyor. Kamerayı otomatik da açmıyorum; bir düğmeye bastırıyorum, çünkü kullanıcı ne zaman görüldüğünü bilmeli.

Sonuç: "seni izleyen" ama "seni hiçbir yere göndermeyen" bir koç. Bunu bir pazarlama cümlesi olsun diye yapmadım — doğru olan buydu, ve doğru olan aynı zamanda en ucuz olan çıktı. İyi mimarinin genelde böyle bir huyu var: doğru kararı verdiğinde, bedava gelen şeyler seni şaşırtıyor.

---

## Bir spor uygulamasının motorunu C++'la yazdım — sebep hız değildi

"Motor" diyorduk ama dürüst bir soru vardı ortada: yine mi HTML ve JavaScript yazıyoruz? Çünkü HTML bir motor değil. HTML çerçevedir — düğme, sayfa, yerleşim. Motor o çerçevenin içindeki hesaptır: açıyı ölçen, tekrarı tanıyan, formu yargılayan mantık. O mantığı nereye yazacağım sorusu, aslında nasıl bir şey inşa etmek istediğimin sorusuydu.

İki yol vardı. Biri her şeyi JavaScript'te yazmak: hızlı, standart, ve bu matematik için performansı fazlasıyla yeterli — açı hesabı ağır bir iş değil. İkincisi motorun beynini C++'ta yazıp WebAssembly'ye derlemek. C++'ı seçtim, ve en net söyleyeceğim şey şu: sebep hız değildi. Bu matematik JavaScript'te de akıcı koşardı, kimse farkı hissetmezdi.

Sebep şuydu: gerçek bir dil, gerçek bir motor, ve "her şey JavaScript, her şey HTML slop" dünyasından çıkmak istiyordum. Bir şeyin gerçekten mühendislik ürünü gibi durmasını istiyorsan, bazen doğru araç en pratik araç değildir. Bunun bir bedeli de vardı: gymgyme o güne kadar "build adımı yok" saf statik bir siteydi. C++ bir derleyici (emscripten) ekliyor. Ama çıktı iki küçük dosya — motor.js ve motor.wasm — onları repoya koyuyorum, site yine statik kalıyor. Yani mimariyi bozmadan gerçek bir C++ çekirdeği kazandım.

İşin kalbinde bir ayrım var: gözleri hazır bir modelden alıyorum (33 nokta), ama beyni kendim yazıyorum. Kütüphaneye "kaç tekrar yaptım" diye sormuyorum; noktalardan anlamı ben üretiyorum. Saf çekirdeği web'den, tarayıcıdan, WebAssembly'den tamamen habersiz tuttum — o sadece "hareket analizi" biliyor. Bu sayede aynı motor yarın native bir uygulamaya da takılabilir; sadece ince bağlama katmanını değiştiririm, beyin aynı kalır.

Çıkardığım ders: "en pratik" ile "doğru" her zaman aynı şey değil. Bazen bir şeyi zor yoldan yapmak, onu daha iyi değil ama daha gerçek yapıyor — ve build-in-public yapıyorsan, gerçek olması zaten yarısı.
