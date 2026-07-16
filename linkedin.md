# linkedin — damla-essays

Mühendislik kararlarının "neden"i + kariyer/duruş yazıları. LinkedIn / blog için. Kaynak: BUILD-LOG.md. Dil şimdilik Türkçe (İngilizce isteniyorsa çevrilir).

---

## TEMPLATE — DAMLA-ESSAY (inşa yolculuğu · numaralı zincir · 300-500+ kelime)

Bir cümle koca bir yazı olamaz. Bu essay'ler İNŞA SÜRECİNİ gösterir: adım adım ne yaptım, her adımın altında hangi karar yatıyor, neden böyle yaptım. Numaralı zincir. Blog/LinkedIn paylaşımı olacak kadar dolu, 300-500 kelime (gerekirse daha uzun).

Zincir şablonu (istediğin kadar uzat, her adım = bir karar):

```
## [Projenin dönüşümünü özetleyen başlık]

1. [BAŞLANGIÇ: projeyi yazdım, amacı buydu — AMA slopware hissi verdi. Fikir nereden geldi, neyi çözmek istedim? İtiraf dürüst olsun.]

2. [İLK EKLEME: o yüzden şunu ekledim. NEDEN? Hangi eksik/sorun bunu getirdi?]

3. [PİVOT: fakat sonra şunu değiştirdim/attım. NEDEN? Hangi karar bu dönüşü zorladı? (yanlış giden neydi?)]

4. [GERÇEK ÜRÜNE GİDEN YOL: slopware'den çıkmak için şunları yaptım. Her biri bir mühendislik/ürün kararı.]

[…gerektiği kadar adım…]

[KAPANIŞ: bu yolculuktan çıkan kalıcı ders / bu projeyi neyin gerçek ürün yaptığı.]
```

Kurallar:
- Her adım bir KARAR anlatır — "ne yaptım" değil, "neden böyle yaptım, altında ne yatıyor".
- Dürüst: slopware hissini, yanlış giden pivotu, bedeli sakla-ma. Gerçek inşa hikâyesi bu.
- Numaralı zincir inşa sürecini görünür kılar — okuyan adım adım seninle düşünsün.
- 300-500 kelime hedef; tek cümle/tek paragraf DEĞİL, dolu bir yazı.
- Terim geçerse insan diliyle aç. Pazarlama değil, düşünce.

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

Gerçek bir hareket-yakalama hattında bu, "cleanup" ya da "solve" aşamasının işidir: ham veri temizlenirken fiziksel olarak imkansız okumalar (bir eklemin kendi üstüne katlanması gibi) gürültü sayılıp sınıra çekilir. Not: bu sınırları önce "insan ROM tablosu" diye sundum — ama kendi kurduğum jürideki CS dekanı haklı olarak yakaladı, onlar atıfsız göz-kararı sayılardı, biyomekanik bir tablo değil. Dürüst olanı yaptım, "heuristik güvenlik kırpması" diye yeniden adlandırdım; dahası üç noktanın iç açısı 0-180 arası olduğundan koyduğum üst sınırlar zaten hiç tetiklenmiyordu (yalancı güvenlik), onları kaldırdım. Kırpmanın gerçek işi tek yerde: bir eklem fiziken imkansız kadar kapanırsa geri açmak. Gerçek derin bir tekrar buna dokunulmadan geçer.

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

## Eklediğim bir şeyi, kendi ölçümüm çürütünce kapattım

Bir gece boyunca gymgyme'nin kamera motorunu büyüttüm ve beş kişilik bir düşman jüriyle altı kez denetlettim. En değerli an, jürinin motoru bir yalanla yakaladığı andı — ve o yalanın sahibi bendim.

Motora "world-refine" diye bir katman eklemiştim: MediaPipe'ın gürültülü derinlik tahminini ikinci bir Kalman filtresinden geçirip açıları daha kararlı kılmak. Testler yeşildi, build-log'a "ölçülebilir şekilde daha kararlı" diye yazdım, geçtim. Sonra jürideki CS dekanı benim kendi ölçüm bandımı çalıştırdı — kötü ışık senaryosunda. Sonuç: refine AÇIKken jitter 2.14'ten 2.21'e ÇIKIYORDU. Yani katman, tam da işe yaraması gereken gürültülü ortamda, motoru KÖTÜLEŞTİRİYORDU. İkinci bir alçak geçiren filtre, One Euro'nun üstüne faz gecikmesi ekliyor ve gürültüde tahmini bayat hıza doğru çekiyordu.

İki seçeneğim vardı. Birincisi: essay'i yumuşatmak, "bazı durumlarda yardımcı olur" demek, katmanı açık bırakmak. İkincisi: ölçüme uymak. İkincisini yaptım — katmanı varsayılan olarak KAPATTIM. Kod hâlâ duruyor (occlusion kurtarma için değeri olabilir, ve gerçek bir kayıtta kazanç gösterirse geri açılır), ama artık motoru bozarken "iyileştiriyorum" hikayesi anlatmıyor.

Bunu neden önemli buluyorum: bir mühendisin kendine söylediği en tatlı yalan, "ekledim, testler geçti, demek ki iyileştirdim"dir. Ama yeşil testler çoğu zaman senin kendi varsayımını doğrular, gerçekliği değil. Bu katmanı sentetik veride test etmiştim ve sentetik veride kusursuz görünüyordu. Onu gerçek gürültü rejiminde ölçen tek şey, bench'in kötü-ışık senaryosuydu — ve o benim duymak istemediğimi söyledi.

Kendine düşman bir jüri kurmanın bütün değeri bu. Nihilist hiçbir şeyi beğenmiyor, VC reddetmek için geliyor, dekan her sayıyı sahte kabul ediyor. Çoğu zaman haksızlar. Ama arada bir, senin görmezden geldiğin gerçeği söylüyorlar, ve o an değerlidir. İyi mühendislik "çalışıyor" demek değil; "yanıldığım yeri aradım, buldum, ve düzelttim — düzeltmek onu SİLMEK anlamına gelse bile" demektir. Bir katmanı eklemek kolaydır. Onu, kendi ölçümün çürüttüğü için geri kapatmak — işte o disiplindir.

## İki iOS uygulaması gömdüm, sonra fikri web'de yeniden doğurdum

1. gymgyme diye başlayan şeyin ilk hali bir iOS uygulamasıydı — hatta iki. Evde antrenman için native bir app yaptım, sonra bir v2 daha. Araştırması sağlamdı: kadınlara özel, küçük grup hesap verebilirliği olan, kaçırılan günü cezalandırmayan bir fitness app'i piyasada yoktu. Boşluk gerçekti. Ama iki sürüm de mezara gitti. İtiraf: sorun fikir değildi, benim onu taşıdığım kaptı. Native bir app kurmak, App Store'a sokmak, güncelleme döngüsü — hepsi, ben ürünü daha kanıtlamadan üstüme yüklenen bir ağırlıktı.

2. O yüzden ilk büyük kararı verdim: platformu değiştirdim. Aynı fikri — evde antrenman + topluluk + şefkatli tasarım — web'e taşıdım. Neden? Çünkü web'de bir fikri yayınlamak ile gömmek arasında bir "review süreci" yok. Bir push, bir canlı URL. Yanlışsam saatler içinde öğreniyorum, aylar içinde değil. Native'in bütün güzelliği fikrimi kanıtlamadan önce bana lazım değildi.

3. Web'de ilk hali bir topluluk dizini oldu: pembe, kenarsız, evde yapılan hareketlerin kaynaklı bir listesi. Sonra üstüne bir "bana program yap" üreteci koydum — saf formül, zaman bütçesi, kas dengesi, esneme soğuması. Backend bile yoktu; öneriler mailto ile gidiyordu, veri localStorage'da yaşıyordu. Bilinçliydi: bir aracın işe yarayıp yaramadığını, sunucu maliyeti almadan önce öğrenmek istedim.

4. Ama dürüst olmam gerekirse, o dizin hâlâ biraz slopware kokuyordu — güzel bir liste, evet, ama "başka bir statik site" hissi. Onu gerçek bir ürün yapan şey sonra geldi: kamera motoru. Bir link listesi herkesin yapabileceği şeydi; kameranla squat'ını sayan, formunu 3B'de yargılayan, hiçbir kareyi cihazdan çıkarmayan bir motor değildi. İşte pivotun asıl anlamı buydu: platform değişimi (iOS→web) sadece kabuğu değiştirmedi, beni "araç" olmaktan "motor" olmaya iten yolun başıydı.

5. Bu yolculuktan çıkardığım ders şu: bir fikri gömmek fikrin ölümü değil. İki iOS app'i öldü ama tez yaşadı. Yanlış olan tezin kendisi değil, onu kanıtlamak için seçtiğim en ağır yoldu. Doğru platform, fikri en ucuz ve en hızlı yanlışlayabildiğin platformdur — ve gymgyme gerçek bir ürüne ancak o hafif zeminde, üstüne gerçek bir mühendislik çekirdeği koyabildiğimde dönüştü. Önce hafifle, sonra derinleş.

## Ana sayfamı bir sinema afişine çevirdim — ve bunun bir bedeli vardı

1. gymgyme bir noktada teknik olarak hazırdı ama görsel olarak ruhsuzdu: beyaz kartlar, standart yerleşim, "başka bir web app". Damla'nın kuralı net: default gri, robotik arayüz yasak. O yüzden büyük bir redesign yaptım — siteyi bir sinema/tiyatro afişi dünyasına taşıdım. Ana sayfa bir "marquee", ışıklı bir sinema tabelası oldu: "starring you", "admit one". Program listesi bir tiyatro fişine dönüştü. Hareket kütüphanesi bir "acts" listesi. Takvim bir "residency calendar" oldu — GitHub katkı grafiği gibi, yoğunluğa göre boyanan.

2. Bu kararın altında bir inanç var: insanlar bir koda değil, bir dünyaya bağlanır. Bir fitness aracı sıkıcı olmak zorunda değil. Sinema metaforu bir amaç taşıyordu — kullanıcıyı sahnenin yıldızı yapmak, antrenmanı bir performansa çevirmek. His olarak çalıştı, hâlâ da seviyorum.

3. Ama dürüst olmam gereken bir bedeli vardı. Bir arkadaşım siteye girip "bu tam olarak ne yapıyor?" dedi — ve haklıydı. Bütün o afiş süslemesi, değer cümlesini gömmüştü. "Kameran seni sayar, puanlar" cümlesi üçüncü satırda, dekoratif yazının altında kayboluyordu. İnsan bir sayfaya iki saniye bakar; o iki saniyede süsleme değil, sonuç görmeli. Estetik, iletişimi boğmuştu.

4. Çözüm redesign'ı geri almak değildi — afişi silmek yanlış olurdu, o siteye ruhunu veriyordu. Bunun yerine başlığın hemen altına, süssüz, çıplak bir değer cümlesi koydum: "kameran repini sayar, formunu 100 üzerinden puanlar ve düzeltir; canlı, cihazında, ücretsiz." Afişin önüne net bir çapa attım. Dünya kaldı, mesaj öne çıktı.

5. Ders: whimsy ve netlik rakip değil, ama sıralaması var. Önce kullanıcı iki saniyede NE olduğunu anlamalı, sonra dünyanın büyüsüne kapılmalı. Tasarımın ruhu iletişimin önüne geçtiği an, güzel ama işe yaramaz bir vitrin olursun. Marquee'yi tuttum çünkü doğruydu; değer cümlesini ekledim çünkü gerekiyordu. İyi ürün ikisini de yapar — önce anlaşılır, sonra unutulmaz.

## İki kişi kameraya girdiğinde koç kimi çalıştıracak?

1. Kamera motoru tek kişi için düzgün çalışıyordu. Sonra gerçek bir senaryo geldi: odada iki kişi var, ya da arkada biri geçiyor. MediaPipe kareyi görüyor ama "hangi iskelet senin antrenmanı yapan kişi?" sorusuna cevap vermiyor. Motor yanlış kişiyi seçerse, senin tekrarını saymak yerine arkadaki adamın hareketini sayar — koç, seni bırakıp yabancıyı çalıştırır. Bu komik ama ürünü çöpe atan bir hata.

2. İlk çözüm en büyük/en ortadaki gövdeyi seçmekti. Yetersiz: kamera açısına göre yabancı daha büyük görünebilir, ya da sen kenara kayabilirsin. Kişiyi "en belirgin" diye seçmek kırılgan bir kural. Kimlik, kareden kareye tutarlı olmalı — motor bir kez "sen busun" dedikten sonra, sen hareket etsen de o kilidi kaybetmemeli.

3. O yüzden kimlik kilidini kalibrasyona bağladım. İlk saniyelerde motor senin kemik uzunluklarını ölçüp kilitliyor (bu zaten form doğruluğu için vardı). Aynı kilit kimlik için de çalışıyor: her karede aday iskeletlerin oranlarını, kalibre edilmiş senin oranlarınla kıyaslıyor. En iyi eşleşen sensin. Yabancının vücut oranları tutmaz, o yüzden seçilmez.

4. Sonra "hard lock" diye bir katman ekledim: en kötü kemik oranı sapması bir eşiği aşarsa o aday tamamen veto edilir. Yalnız bir yabancı — kalibrasyonuyla hiç eşleşmeyen biri — asla koçlanmaz. Bunu bir "ışınlanma testi"yle kanıtladım: bir iskeleti sahnede zıplatıp motorun onu reddedip gerçek kullanıcıya kilitli kaldığını ölçtüm. Sonuç: 0 yanlış kare.

5. Ders şu: gerçek dünya tek kullanıcılı bir laboratuvar değil. Bir motoru "çalışıyor" saymadan önce, onu kirli senaryoda — iki kişi, geçen biri, kötü açı — test etmek zorundasın. Kimlik problemi teknik olarak "çok kişi seçimi" gibi görünüyor ama aslında bir güven problemi: kullanıcı, koçun kendisini çalıştırdığından emin olmalı. Ve bu güveni, ancak yabancıyı görünür şekilde reddederek kazanıyorsun.

## Motoru bir gecede büyüttüm, sabah müşteri gözüyle açtım ve kötüydü

1. Bir gece boyunca gymgyme'nin kamera motorunu 2837 satırdan 4700 satıra çıkardım. One Euro filtre, Kalman occlusion kurtarma, IK anatomik limitler, simetri analizi, hareket sınıflandırıcı — 191 native test, hepsi yeşil. Mühendislik olarak gurur duyulacak bir geceydi. Build-log şişti, essay stoğu doldu.

2. Sabah Damla telefonu açıp kamerayı çalıştırdı. Ve ürün kötüydü. Görsel çirkindi, yerleşim bozuktu, ve — en acısı — kolunu kaldırdığında rep saymıyordu. Motor içeride 4700 satır zekaydı; dışarıda, gerçek bir insanın gözünde, işe yaramayan bir ekran. Bu, kariyerimin en net derslerinden biriydi ve canımı yaktı.

3. Ders şu: motoru büyütmek, işe yarar bir ürün yapmaz. İkisi farklı eksenler. Bütün gece "daha doğru ölçen" bir motor kovaladım ama hiç durup "müşteri bunu açınca ne görüyor, ne hissediyor?" diye sormadım. Test sayısı 191'di ama bunların hiçbiri "Damla telefonu açtı, kolunu kaldırdı, saydı mı, güzel miydi, tekrar açar mı?" sorusunu ölçmüyordu. Yeşil testler mühendisi rahatlatır, müşteriyi değil.

4. O yüzden yönü tamamen değiştirdim: müşteri gözü döngüsü. CS hocası, VC, PM gözüyle değil — "bu ürün işime yarıyor mu?" diyen sıradan insan gözüyle. Her turda ürünü gerçek bir kullanıcı gibi açıp kırılanı buldum: default hareket squat'tı ve oturan biri sayamıyordu (arm raise yaptım — oturan da sayabilsin), kilit 5 karede kayıyordu, takvim grid'i eksikti, debug paneli müşteriye CS ödevi gibi görünüyordu, fiş videoyu örtüyordu. Hiçbiri "motoru daha akıllı yap" değildi; hepsi "bu işe yarıyor mu" idi.

5. Kalıcı ders: bir motorun doğruluğu, ürünün değeri değildir — sadece bir bileşenidir. Bir feature'ı bitirdim demeden önce, onu yabancı bir kullanıcı gibi açıp yürümek zorundasın. "191 test geçti" bir cümle; "açtım, kolumu kaldırdım, saydı, gülümsedim, tekrar açtım" başka bir cümle. Ürünü satan ikincisidir. Mühendis olarak en zor öğrendiğim şey buydu: kendi motoruma değil, müşterinin gözüne güvenmek.

## Neyi düzelteceğimi bilmiyordum — sonra ürünü katmanlara ayırdım

1. gymgyme'de garip bir tıkanma yaşadım: iş çoktu, enerji vardı, ama her oturumda "bugün neye çalışmalıyım?" sorusu beni yoruyordu. Motor mu, tasarım mı, landing mi, akış mı? Hepsi biraz bozuktu ve hepsi birbirine değiyordu. Bir şeyi düzeltmeye başlıyordum, başka bir şeyin kırığına takılıp oraya kayıyordum.

2. Teşhis için ürünü katmanlara ayırdım — bir binanın katları gibi: L1 marka/landing, L2 ürün akışı, L3 koç deneyimi ekranı, L4 kamera motoru, L5 veri/backend, L6 topluluk dizini, L7 içerik ve operasyon. Her katmana tek tek baktım: ne içeriyor, durumu ne, somut sorunu ne.

3. Harita çıkınca tıkanmanın sebebi tek bakışta göründü: motor katmanı üründen iki kat öndeydi. C++ motor 104+ testle, kemik kilidiyle, filtreleriyle ligin üstünde; ama bir yabancı siteye girince iki kimlikli bir sayfa görüyor, koça girince debug paneliyle karşılaşıyor. Ben haftalardır L4'te kazıyordum, kırılma L2 ve L3'teydi. "Motor 2000 satır büyüdü ama sabah ürün kötüydü" krizim de aynı şeydi — o zaman adını koyamamıştım, katman haritası adını koydu.

4. Daha da önemlisi: iş planımdaki 8 loop'u katmanlara eşleyince, en kritik katmanın — ürün akışının — hiçbir loop'a bağlanmamış olduğunu gördüm. Kararlar verilmişti, ama hiçbir dosyaya yazılmamıştı; o yüzden her oturum "acaba nereden başlasam" ile açılıyordu. Loop'suz katman, görünmez katmandır. Ona bir loop yazdım; artık o iş bir dosyada, sırada, ölçütleriyle duruyor.

5. Kalıcı ders: "her şey biraz bozuk" hissi, teşhis değildir — haritasızlıktır. Ürünü katmanlara ayırmak sorunları çoğaltmaz, adreslerini verir. Ve en tehlikeli sorun en gürültülü olan değil, hiçbir listeye yazılmamış olandır.

## Sitem flop hissi veriyordu — bir marka yöneticisine baktırdım

1. gymgyme'nin motoru güçlüydü ama siteye giren biri bunu hissetmiyordu; kendi kelimemle "flop hissi" vardı ve nedenini kendim göremiyordum — çünkü ben siteye her gün bakıyordum, yabancı gözümü çoktan kaybetmiştim.

2. O yüzden işi dışarı verdim: bir incelemeyi marka yöneticisi gözüyle yaptırdım — müşteri gibi girsin, rakiplerle kıyaslasın, business ve satış açısından baksın. Rakip listesi netti: Onyx, Kemtai, BetterMe, Nike Training Club.

3. Bulgular acıttı ama hepsi somuttu. En güçlü cümlem — "kameran tekrarlarını sayar, formunu 100 üzerinden puanlar, canlı düzeltir" — sayfada vardı ama başlık değildi; başlıkta metafor vardı, değer alt satırda küçüktü. Sitede motorun çalıştığını gösteren tek bir görüntü yoktu: kameralı bir ürünün kanıtı kameradır, ben onu hiç göstermiyordum. Ve en somut flop kaynağı: "(0)" sayaçları. "my moves (0)", "articles (0)" — sıfırlar ilk ekranda "terk edilmiş proje" diye bağırıyordu.

4. Rakip kıyası ise beklediğimin tersini söyledi: elim zayıf değil güçlüydü. Bu kategorideki en bilinen ürün paralıydı ve artık ölü sayılır; en ciddi rakip B2B'ye kaçmış. "Ücretsiz + görüntü cihazdan çıkmaz + kanıtlı doğruluk" konumu pazarda boş duruyor. Sorun ürün değilmiş; vitrinin hiyerarşisi ve kanıt eksikliğiymiş.

5. Ders: "flop duruyor" bir duygu, ama duygular teşhis edilebilir. Yabancı göz kaybolduysa ödünç al — ve ona sadece "beğendin mi" değil, "beş saniyede ne anladın, rakibin yanında nasıl duruyor, neden güvenesin" sorularını sordur. Cevaplar duyguyu iş listesine çevirir.
