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

## Bir eşiği herkese sabit koymak neden yanlıştı

gymgyme'nin koç motorunda en sinir bozucu bug şuydu: kullanıcı squat yapıyor, motor onu görüyor, eğildiğini algılıyor — ama tekrarı saymıyor. Derinlik göstergesi doluyor, sayaç sıfırda kalıyor. Bir kullanıcı bunu "eğildiğimi görüyorsun ama saymıyorsun" diye tarif etti ve tam yerine parmak bastı.

Kökü basit ama öğreticiydi. Motor bir squat'ı şöyle sayıyordu: diz açın belirli bir alt eşiğin (120°) altına insin, sonra üst eşiğin üstüne dönsün — bu bir tekrar. Sorun eşiğin SABİT olmasıydı. Kullanıcı kameraya dönük çömeldiğinde perspektif kısalması diz açısını olduğundan düz gösteriyor. Kişi gerçekten derin iniyor ama ölçülen açı 120°'ye hiç değmiyor. Sonuç: motor "sen hiç dibe inmedin" diyor, oysa insan tam bir squat yapmış.

İlk içgüdü eşiği düşürmek olurdu — 120'yi 130 yap. Ama bu yanlış çözüm: birinin bacağı, kamera açısı, çömelme derinliği bir diğerininkinden farklı. Hangi sabiti koyarsan koy, birinde fazla katı birinde fazla gevşek olur. Sabit bir sayı, değişken bir dünyaya asla oturmaz.

Doğru çözüm eşiği kişiselleştirmekti. Motor zaten kalibrasyon aşamasında kullanıcının vücudunu öğreniyor. Buna bir ölçü daha ekledim: kişinin GERÇEK ayakta duruş açısı — rahat dururken dizinin ne kadar açık olduğu. Sonra dip eşiğini o duruştan sabit bir düşüşle (42°) türetiyorum. Yani eşik artık "120 dereceye in" değil, "senin ayakta durduğun yerden bu kadar bükül" diyor. Uzun bacaklıda da kısa bacaklıda da, kameraya dönükte de yandan da, kişinin kendi hareket aralığına oturuyor.

Bir emniyet ağı bıraktım: eski sabit eşik bir TABAN olarak duruyor — adaptif eşik ondan daha zor olamıyor, yani motor kimseden fiziksel olarak imkansız bir derinlik istemiyor. Adaptif mekanizma yalnızca saymayı KOLAYLAŞTIRIYOR, hiçbir zaman zorlaştırmıyor.

Ders şu: bir ürün gerçek insanlarla buluştuğunda, "makul bir sabit" diye koyduğun her sayı birinin gerçekliğiyle çelişir. Ölçtüğün şey insandan insana değişiyorsa, eşiğin de değişmeli. Sabit sayı mühendisin kolayına gelir; kullanıcının vücuduna değil.

## İskeletin neden zıpladığını çözmek: One Euro'dan Kalman'a

gymgyme'nin kamera motorunda uzun süre One Euro filtresi kullandım. İyi bir filtredir: bir açıyı hem duruşta sakin hem harekette çevik tutar, kesim frekansını hıza göre ayarlar. Ama bir sınırı var ve o sınır tam da ürünü ucuz gösteren yerde patlıyordu: bir eklem bir kare için kaybolduğunda — el gövdenin önünden geçer, diz bir başkasının arkasında kalır — One Euro'nun söyleyecek sözü yoktur. Ölçüm yoksa çıktı yoktur. İskelet o noktada ya donar ya da model yeni bir tahmin ürettiğinde oraya zıplar. Kullanıcı bunu "bozuk" diye okur, ve haklıdır.

Sorunun kökü şu: One Euro'nun geleceğe dair bir modeli yok. Sadece geçmiş ölçümleri yumuşatıyor. Oysa bir eklem kaybolduğunda elimizde çok değerli bir bilgi var — o eklemin son bilinen HIZI. Kol yukarı gidiyorduysa, görünmediği o birkaç karede de yukarı gitmeye devam ediyordur. Bunu kullanabilmek için filtrenin bir durumu olmalı: sadece "neredeydi" değil, "nereye ve ne hızla gidiyordu".

Bu tam olarak Kalman filtresinin yaptığı iş. Her noktanın durumunu konum VE hız olarak tutuyor, iki fazda çalışıyor. Predict fazı: ölçüm gelmese bile hızı kullanıp bir sonraki konumu öngörüyor — occlusion boyunca iskelet donmuyor, son bilinen hızla akmaya devam ediyor. Update fazı: ölçüm gelince, ölçüm gürültüsüyle süreç gürültüsünü tartıp optimal karışımı alıyor. Bulanık, düşük güvenli bir kare ölçümüne az ağırlık veriyor; net bir ölçüme çok. Bu ağırlığı (Kalman kazancı) elle ayarlamıyorum, matematik kendisi türetiyor.

Bunu neden önemli buluyorum: bu, oyuncak bir yumuşatmadan gerçek bir kestirim katmanına geçiş. Vision Pro'nun, mocap sistemlerinin, MediaPipe'ın kendi iç filtrelerinin oturduğu matematik bu. Tek webcam'le, tarayıcıda, gerçek zamanlı çalıştırıyoruz — Pixar'ın çok kameralı offline lüksü yok, ama "hareketi çöz" problemi aynı problem, ve o problemde rekabet edilebilir.

Bir mühendislik disiplini de dayattı kendini: Kalman'ı motora bağlamadan önce 12 test yazdım — yakınsama, hız öğrenme, occlusion boyunca akma, gürültü bastırma, güven-ağırlıklı güncelleme. "Sanırım daha pürüzsüz" demek istemedim; matematiğin doğru olduğunu ölçtüm. Occlusion sırasında eklemin gerçekten tahmini hızla ilerlediğini, komşu eklemlerin normal takibini sürdürdüğünü, ve en önemlisi sayma matematiğinin hiç etkilenmediğini — çünkü bu katman sadece çizime bağlı, açı ölçümü hâlâ ham veriden — testle sabitledim.

## Dizin geriye bükülemez: iskelete anatomi öğretmek

gymgyme'nin motorunda kemik kilidi diye bir katman var: dedektörün önerdiği yönü kabul eder ama uzunluğu kalibrasyonda öğrenilen sabite çeker. Kemik uzayamaz, eklem kayamaz. Bu iyi çalışıyordu ama bir boşluk bıraktığını fark ettim: uzunluğu sabitliyordum, açıyı değil. Dedektör gürültüsü bir dizi geriye bükebiliyordu — insan dizinin fiziksel olarak yapamayacağı bir şey. İskelet doğru boyda ama imkansız bir şekilde kırılmış görünüyordu.

Gerçek bir hareket-yakalama hattında bu, "cleanup" ya da "solve" aşamasının işidir: ham veri temizlenirken her eklemin fiziksel bir hareket açıklığı (ROM) olduğu bilinir, dışına çıkan okuma gürültü sayılıp sınıra çekilir. Diz yaklaşık 0 ile 180 derece arasında bükülür; 185'i geçmez, 15'in altına inmez. Dirsek geriye kırılmaz. Kalça belli bir aralıkta döner. Bunlar keyfi sayılar değil, insan anatomisinin sınırları.

ik.hpp'de bu limitleri kodladım ve kemik kilidinden sonra uyguluyorum. Bir eklemin açısı yasal aralığın dışındaysa, çocuk noktayı ebeveyn etrafında en yakın sınıra kadar döndürüyorum. Kritik olan: döndürme sırasında hem yönü hem kemik uzunluğunu koruyorum. Bunu Rodrigues dönme formülüyle yapıyorum — bir vektörü bir eksen etrafında tam bir açı kadar döndürmenin temiz yolu. Sonuç: iskelet artık hem doğru boyda hem anatomik olarak mümkün.

Neden bu kadar önemsiyorum: bir CV motorunu oyuncaktan ürüne taşıyan şey tam bu tür katmanlar. Ham dedektör çıktısı bir başlangıçtır, bitiş değil. Onun üstüne kestirim (Kalman), kısıt (kemik kilidi + eklem limitleri), ve anlam (form kuralları) koydukça motor "noktaları çizen bir şey"den "vücudu anlayan bir şey"e dönüşüyor. Anatomik bilgi bunun bir parçası: motor artık sadece nokta görmüyor, o noktaların bir İNSANA ait olduğunu ve insanların nasıl büküldüğünü biliyor.

Ve her zamanki disiplin: 9 test yazdım önce. Geçerli bir açının dokunulmadan bırakıldığını, aşırı bükülü bir dizin sınıra çekildiğini, ve en önemlisi kemik uzunluğunun kırpma sırasında korunduğunu ölçtüm. Matematik doğru olmadan "düzeldi" demek istemiyorum.

## Motor ne yaptığını söylemeden bilmeli: açıklanabilir hareket tanıma

gymgyme'nin koç motoru bugüne kadar kullanıcının SEÇTİĞİ hareketi izliyordu. "Squat yapacağım" dersin, motor squat'ı sayar. Ama gerçek bir koç, ne yaptığını söylemeden tanır. Bu farkı kapatmak istedim — ve bunu bir derin öğrenme modeliyle değil, açıklanabilir geometriyle yaptım.

Yaklaşım şu: her hareketin bir imzası var. Son iki saniyenin hareketinden dört şeye bakıyorum. Birincisi, hangi büyük eklem en çok salınıyor — diz mi, dirsek mi, kalça mı, omuz mu? Squat'ta diz salınır, push-up'ta dirsek. İkincisi, gövde dik mi yatay mı — bunu yerçekimi-farkında tilt ölçümünden alıyorum (daha önce eklediğim katman). Squat dik, plank yatay. Üçüncüsü, salınım mı var yoksa sabit mi — salınım varsa rep, yoksa izometrik tutuş. Dördüncüsü, salınımın genliği. Bu dört boyut çoğu ev hareketini ayırt etmeye yetiyor.

Neden derin ağ değil de bu? Çünkü bir üründe her kararın HATA AYIKLANABİLİR olması, black-box doğruluktan değerli. Motor "bu squat" dediğinde, neden dediğini tam olarak söyleyebiliyorum: diz en çok salınan eklemdi, gövde dikti, salınım genişti. Bir kullanıcı yanlış tanıma bildirdiğinde, hangi boyutun yanıldığını görüp düzeltebiliyorum. Bir sinir ağı "bilmiyorum, ağırlıklar öyle diyor" derdi. Küçük, hızlı, tarayıcıda çalışan ve her kararını açıklayan bir sınıflandırıcı, bu ürün için doğru mühendislik tercihi.

Sonuç bir tahmin ve bir GÜVEN döndürüyor. Güven düşükse motor "emin değilim" diyebiliyor — uydurmuyor. Bu, ürünün geri kalanındaki dürüstlük çizgisiyle aynı: ölçemediğini ölçmüş gibi yapma, tanıyamadığını tanımış gibi yapma.

Şimdilik bunu "seçtiğin hareket bu değil galiba, X mi demek istedin?" nazik uyarısı için kullanacağım. Ama asıl yön şu: motor giderek daha az soru soran, daha çok anlayan bir şeye dönüşüyor. Önce vücudu tanıdı (kalibrasyon), sonra oryantasyonu (yerçekimi), şimdi de niyeti (hangi hareket). Her katman onu "nokta çizen bir şey"den "ne yaptığını anlayan bir şey"e biraz daha yaklaştırıyor.

Ve yine: 8 birim testi önce. Salınan dizin squat, salınan dirseğin push-up, sabit yatay gövdenin plank olarak sınıflandığını ölçtüm. Motorun kendisi de bir squat'ı bağımsızca "bacak hareketi" olarak tanıdı. Doğruluk iddiası ölçümle gelir.

## Kendi kodumu yerden yere vuran bir jüri kurdum

Bir motoru büyütürken en tehlikeli an, "oldu" dediğin andır. O yüzden gymgyme'nin kamera motorunu geliştirirken kendime bir kural koydum: her büyümenin ardından, kodu ben değil, benden nefret eden bir jüri denetlesin. Bu gece o jüriyi kurdum — beş farklı düşman gözü, her biri farklı bir zaaf avlıyor.

Birincisi CS Dekanı: mühendisliği yerden yere vuruyor. "Kalman diyorsun ama q ve r gerçek veriye mi ayarlı, yoksa sihirli sayılar mı? World-refine'ı One Euro'nun üstüne koydun — iki alçak geçiren filtreyi arka arkaya dizince gecikmeyi tekrar ölçtün mü, yoksa 'daha iyidir' diye varsaydın mı? 'CGI netliği' pazarlama lafı — gerçek klipte ölçülmüş jitter nerede?" İkinci ve üçüncü, iki pilates uzmanı: biri sertifikalı eğitmen (hold hareketleri kaliteyi mi süreyi mi ölçüyor, form ipuçları gerçek biyomekanik mi), biri acımasız içerik üreticisi (bir tek takılan kare görsem giderim). Dördüncüsü Türk VC paneli: reddetmek için bahane arıyor — "wrapper bu, moat yok, feature bu şirket değil, al götüne sok". Beşincisi nihilist: hiçbir şeyi beğenmiyor, her şeye "buna gerek yok, sil" diyor.

Sonra bu jüriyi gerçekten koda saldım — her denetçinin bulgusunu bağımsız bir şüpheci doğruladı, sahte suçlamalar elendi, gerçek olanlar kaldı. Ve utandırıcı derecede işe yaradı. İkinci tur altı gerçek bug buldu — tam da yeni kodun eskiyle buluştuğu yerlerde saklananlar. En kötüsü: world-refine katmanını ekledim, testler geçti, "oldu" dedim — ama denetçi gösterdi ki kalibrasyon sonrası motor o katmanı BYPASS ediyordu, eklediğim gürültü sönümlemesi ana yolda hiç kullanılmıyordu. İki Kalman filtresinin maliyetini ödüyor, faydasını almıyordum. Düzelttim: kemik kilidi artık iyileştirilmiş dünyadan çözülüyor.

Sonra CS Dekanı'nın sorusuna kendi silahıyla cevap verdim — bench'e world-refine AÇIK vs KAPALI karşılaştırması ekledim. Ölçüm alçakgönüllüydü: sentetik klipte ikinci Kalman katmanı One Euro'nun üstüne kayda değer bir şey katmıyor, hatta kötü ışıkta jitter'ı biraz artırıyor. Bunu saklamadım, commit mesajına yazdım. Çünkü katmanın gerçek değeri occlusion-recovery — ve sentetik test onu hiç sınamıyor (dropout yok). Bu ancak gerçek bir klipte yargılanabilir.

İşin özü şu: iyi mühendislik "çalışıyor" demek değil, "yanılıyor olabileceğim yeri arayıp buldum" demektir. Kendine bir jüri kurmak, o aramayı sistematik hale getiriyor. Nihilist haklıysa, kesersin. Değilse, soğukkanlılıkla kanıtlarsın. Her iki durumda da slopware dışarıda kalıyor.

## "CGI netliği" bir pazarlama lafıydı — jüri haklıydı, düzeltiyorum

Motoru geliştirirken bir cümle kullandım: "CGI netliği." Kulağa iyi geliyordu. Sonra kendi kurduğum jürideki CS dekanı onu yerden yere vurdu, ve haklıydı: "CGI netliği ölçülebilir bir şey değil, pazarlama. Sen bana gerçek bir klipte ölçülmüş jitter, RMSE, gecikme göster."

Doğru. Motorun tüm hassasiyet sayıları — jitter 4.57°'den 2.21°'ye, kemik varyansı %5.7'den %0'a — sentetik veriden geliyor. Sentetik veride ben gerçek açıyı biliyorum çünkü iskeleti o açıdan kuruyorum, sonra üstüne kendi eklediğim Gauss gürültüsünü koyuyorum. Bu, kodun benim gürültü modelime uyduğunu kanıtlar. Gerçekliğe uyduğunu değil. Çünkü MediaPipe'ın gerçek hatası Gauss değil — korelasyonlu, önyargılı, özellikle derinlik ekseninde (z) sistematik. Benim temizlediğim titreme onda yok; onda olan başka bir şey.

Dahası, "kemik varyansı %0" diye övündüğüm sayı bir totoloji. Kemik kilidi iskeleti öğrenilmiş bir uzunluğa yeniden yansıtıyor; sonra o aynı uzunluğu geri ölçünce tabii ki %0 çıkıyor. Bu bir sadakat ölçütü değil, projeksiyonun matematiksel bir özelliği. Dekan bunu da yakaladı.

Peki ne yapıyorum? İki şey. Birincisi, dili düzeltiyorum: bu sayılar "modellenmiş gürültü altında filtre davranışı"dır, "gerçeklikte hassasiyet" değil. İkincisi — ve asıl doğrusu bu — gerçek bir ölçüm hattı kurdum ama gerçek klip henüz yok. Motora gizli bir kaydedici koydum (?rec=1), gerçek bir insanın gerçek bir squat'ı kaydedilip motordan geçirilebiliyor. O klip çekilene kadar hiçbir "gerçek hassasiyet" iddiası etmeyeceğim. Tek kameralı bir sistemde derinlik zaten bir tahmindir; onu gerçek ölçüm gibi sunmak, dekanın deyimiyle, "tahmini gerçeğe çamaşır yıkamak" olur.

Bunu neden yazıyorum? Çünkü bir mühendisin en kolay yalanı kendine söylediğidir. "CGI netliği" hoş bir cümleydi ve testler yeşildi, o yüzden inanmak kolaydı. Ama yeşil testlerin çoğu benim kendi kurgumu doğruluyordu, gerçekliği değil. Kendine düşman bir jüri kurmanın bütün değeri bu: senin duymak istemediğin ama duyman gereken cümleyi, senin yerine biri söylüyor. İyi ürün, rahatsız edici doğruları erken duyan üründür.
