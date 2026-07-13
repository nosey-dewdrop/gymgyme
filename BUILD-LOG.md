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

## Karar — motor hangi dilde yazılsın?

Burada durup dürüst bir soruyu cevaplamak gerekti: "motor" diyoruz ama yine mi HTML/JS yazıyoruz? Çünkü HTML bir motor değil — HTML sadece **çerçeve** (düğme, sayfa yerleşimi). Motor, o çerçevenin içindeki **hesap**: açıyı ölçen, tekrarı tanıyan, formu yargılayan mantık.

İki yol vardı. Biri: her şeyi JavaScript'te yazmak — hızlı, standart, bu math için performansı da yeter (açı hesabı ağır değil). Ama bu, sıkıldığım o "her şey JS" dünyasında kalmak demekti. İkincisi: motorun **beynini C++'ta yazıp WebAssembly'ye derlemek** — tam stitchu'nun yaptığı gibi. JS sadece ince tutkal olur (kameradan kareyi al, ekrana çiz); açıyı, durumu, saymayı **C++ hesaplar**.

C++'ı seçtim, ve sebebi *hız değil* — bu math JS'te de akıcı koşardı. Sebep şu: istediğim şey gerçek dil, gerçek motor, ve HTML sloptan çıkmak. Bunun için doğru olan C++. Bedeli de var: gymgyme bugüne kadar "build adımı yok" saf statik bir siteydi; C++→WASM bir derleyici (emscripten) ekliyor. Ama çıktı iki küçük dosya (motor.js + motor.wasm) — onları repoya koyuyoruz, site yine statik kalıyor, sadece motoru derlemiş oluyoruz. Yani mimariyi bozmadan gerçek bir C++ çekirdeği kazandık.

Önemli ayrım: gözleri (33 noktayı) hazır bir modelden alıyoruz, ama **beyni kendimiz yazıyoruz.** Kütüphaneye "kaç tekrar" diye sormuyoruz — noktalardan anlamı biz üretiyoruz. Motorun olduğu yer tam burası.

---

## Aşama 2–6 — Vücut sayıya dönüşüyor (motor, C++)

Bu dört küçük aşama birlikte tek bir şeyi kurdu: kameranın gördüğü şekilsiz noktaları, üstüne mantık kurulabilecek **temiz bir sinyale** çevirmek. Hepsi `engine/motor.cpp` içinde.

**Açılar (2–3).** Bir koç için önemli olan noktaların yeri değil, aralarındaki **açı**. Diz ne kadar bükülü, sırt ne kadar eğik — hareket bu. O yüzden ilk iş: üç nokta al (mesela kalça-diz-ayakbileği), aradaki açıyı hesapla. Diz, kalça, dirsek için, hem sol hem sağ. Vücut artık altı sayıya dönüştü. Bunu ekranın 2 boyutlu (x,y) haliyle yaptım, çünkü kamera zaten 2B görüyor ve derinlik tahmini gürültülü — sağlam olan basit olandı.

**Yumuşatma (4).** İlk denemede sayılar titriyordu: kişi kıpırdamadan dursa bile açı 141-139-142 diye zıplıyor, çünkü model her karede noktaları azıcık oynatıyor. Bu titreşim sonra sayacı yanıltırdı (eşiğin kenarında ileri-geri sayardı). Çözüm bir **alçak-geçiren süzgeç** (EMA): yeni okumayı eskisiyle harmanla, ani sıçramaları yumuşat. Artık sinyal sakin akıyor.

**Güven kapısı (5).** Motor kötü veriyle karar vermemeli. Kişi kadraja tam sığmıyorsa ya da ışık azsa, model noktaları düşük "güven"le veriyor. O yüzden squat için diz zincirini iki taraftan da kontrol edip **hangi taraf daha net görünüyorsa onu** kullanıyorum; ikisi de zayıfsa hiç saymıyorum, bunun yerine "biraz geri çekil, ışığa bak" diyorum. Bu bir dürüstlük: emin olmadığında susan bir motor, uyduran bir motordan iyidir.

**Durum makinesi (6).** Son parça: hareketin **neresinde** olduğumuzu bilmek. İki durum — "üstte" (ayakta) ve "dipte" (çömelmiş) — arasında geçiş yapan küçük bir mantık. İki ayrı eşik kullandım (inmek için bir, kalkmak için başka): buna histerezis denir, tek eşik olsaydı gürültü sınırın etrafında sürekli ileri-geri tetiklerdi. Şimdi motor "şu an diptesin, şimdi kalkıyorsun" diyebiliyor — ve **tekrar saymak** (Aşama 7) tam olarak bu geçişlerin üstüne binecek. Yani bu aşama sayının iskeletini kurdu, saymanın kendisini bir sonrakine bıraktı.

Hepsi ekrana bağlı: coach sayfasında artık büyük bir kelime ("standing" / "deep"), altında canlı diz açısı, faz ve gidiş yönü görünüyor; iskelet dipteyken vişne, ayaktayken koyu renge dönüyor. Motor gerçekten "anlıyor".

**Burada durduldu (Aşama 6).** Sıradaki oturum: Aşama 7 — durum geçişinden gerçek tekrar sayımı + yarım tekrarı reddetme.

---

## Mimari — motoru bir "API" gibi kurmak

Bir soru geldi: "motor" diyoruz ama iyi tasarlanmış, ileride başka yere de takılabilen bir şey mi, yoksa tek kullanımlık bir yığın kod mu? Doğru cevap için motoru ikiye böldüm.

Bir yanda **saf çekirdek** (`coach_engine.hpp` + `coach_engine.cpp`): bu dosyalar web'i, tarayıcıyı, WebAssembly'yi *hiç* bilmez. Sadece "hareket analizi" bilir — 33 nokta ver, temiz bir okuma (açı, derinlik, faz) al. Öbür yanda **ince bir bağlama katmanı** (`bindings.cpp`): tek işi çeviri, JS'in verdiği diziyi C++ nesnesine, C++ sonucunu JS'in okuyabileceği nesneye çevirmek. Mantık burada değil, çekirdekte.

Bu ayrım motoru gerçek bir API yapıyor: aynı çekirdek yarın native bir uygulamaya, bir sunucuya, başka bir dile de bağlanabilir — sadece bağlama katmanını değiştirirsin, beyin aynı kalır. Ayrıca hareketleri **veri** olarak tanımladım (`MoveSpec`): squat = "diz eklemini izle, dip 110°, üst 155°". Yeni bir hareket eklemek kod yazmak değil, veri eklemek olacak (bu Aşama 12'nin tohumu).

## Derleme — C++ artık gerçekten .wasm

Bugüne kadar C++ kaynak koddu; şimdi **çalışan ikili** oldu. emscripten'i kurdum, `engine/build.sh` iki C++ dosyasını derledi ve iki dosya çıktı: `motor.js` (45 KB, küçük yükleyici) ve `motor.wasm` (**22 KB, asıl motorun kendisi — bir WebAssembly ikilisi**). İşte "JS'ten mi motor" sorusunun somut cevabı: beyin bu 22 KB'lik `.wasm` dosyasında, JavaScript değil. JS sadece onu çağırıyor.

Site yine "build adımı yok" statik kalıyor — bu iki dosyayı repoya koyuyoruz, kullanıcı hiçbir şey derlemiyor, tarayıcı hazır `.wasm`'ı indirip çalıştırıyor.

## Sayfayı bölmek — html ayrı, css ayrı, js ayrı

Küçük ama kimlik açısından önemli bir düzeltme: coach sayfası tek bir HTML dosyasında stil + kodla şişmişti. Kod HTML içinde toplanınca proje "bir HTML projesi" gibi görünüyor — oysa bu bir C++ motoru + ince bir web katmanı. O yüzden üçe böldüm: `coach.html` sadece iskelet (markup + linkler), `css/coach.css` stil, `js/coach.js` tutkal kod. Artık en büyük ve gerçek kod C++, ardından JavaScript; proje ne ise o görünüyor.

## Aşama 1 — Sahne cilası

Motor "görüyor ve anlıyor" ama insanın bunu *hissetmesi* lazım. Bu aşama okuma panelini kurdu: en üstte büyük bir kelime hareketin nerede olduğunu söylüyor ("standing" / "going down" / "deep" / "coming up"); altında üç canlı ölçer — **squat derinliği** (0'dan 1'e dolan vişne bir bar), **takip güveni**, ve **kadraja sığma** (motorun neden bazen "biraz geri çekil" dediğini görürsün). Bir de altı eklem açısı listeleniyor, ve takip edilen dizin hem ham hem yumuşatılmış hali yan yana — böylece EMA'nın titremeyi nasıl sakinleştirdiğini gözünle görüyorsun. Köşede bir fps sayacı, "tüm hesap cihazında" notuyla. İskelet dipteyken vişneye dönüyor. Hepsi gymgyme'nin pembe/bordersiz dilinde; kutu yok, ayrım boşluk ve renk.

## Sertleştirme — güvenlik, hız, temiz kod, ve "neden JS görünüyor"

Bir duraklama yapıp mevcut hali gerçek bir gözle denetledim: güvenlik, hız, temiz kod. Çıkanları tek tek düzelttim, çünkü "çalışıyor" ile "üretime hazır" arasındaki fark bu.

**"App neden JS görünüyor?"** GitHub'ın dil çubuğu "çoğu JavaScript" diyordu ve bu yanıltıcıydı. Sebep: sayılan JS'in çoğu ya emscripten'in ürettiği yükleyici (`motor.js`, 45 KB) ya da dizin verisi (`seed.js`, 48 KB) — ikisi de elle yazılmış uygulama kodu değil. Bir `.gitattributes` ekleyip bunları "üretilmiş / veri" olarak işaretledim; artık dil çubuğu gerçek kodu, yani C++'ı ve tutkal JS'i gösteriyor. Bir de sayfayı html/css/js diye böldüğüm için kod artık HTML dosyasında toplanmıyor.

**Güvenlik — CDN'i içeri aldım.** En büyük risk gizlilik değildi (o zaten temiz: video cihazdan çıkmıyor), tedarik zinciriydi: MediaPipe kütüphanesini bir CDN'den, modeli Google'dan indiriyordum. O sunuculardan biri ele geçse, kameraya erişimi olan bir sayfaya kötü kod girebilirdi. Çözüm: kütüphaneyi, wasm'ını ve modeli (toplam ~34 MB) repoya **vendor'ladım**. Artık çalışırken hiçbir üçüncü taraf sunucuya bağlanmıyor — hem güvenli, hem çevrimdışı çalışıyor, hem de Google'a "kim kullanıyor" bilgisi sızmıyor. Üstüne sıkı bir **Content-Security-Policy** (her şey `self`) ve `Permissions-Policy: camera=(self)` koydum: sayfa artık yalnızca kendi origin'inden kod çalıştırabiliyor ve kamerayı başka kimse gömemiyor.

**Hız — sınırı geçmeyi bıraktım.** Her karede 33 noktayı JS'ten C++'a tek tek geçiriyordum: kare başına ~132 küçük JS↔wasm sınır geçişi + bir dizi allocation'ı. Bunu tersine çevirdim: noktaları bir kez wasm'ın kendi belleğine (heap) yazıp motora sadece bir **pointer** veriyorum. Tek çağrı, sıfır tekrar allocation. Masaüstünde farkı görmezsin ama telefonda pili ve akıcılığı korur.

**Temiz kod — motoru test ettim.** Çekirdeği web'siz saf C++ tuttuğumun karşılığını burada aldım: normal derleyiciyle (tarayıcı yok) küçük bir test dosyası yazdım ve motorun mantığını doğruladım — düz bacak ~180°, bükülü ~90°, görünmeyen vücut sayılmıyor, ayakta→dip→ayakta faz geçişleri doğru, histerezis sınırda titremiyor. On bir testin hepsi geçti. Motor büyüdükçe bu testler beni yanlış değişiklikten koruyacak. Bir de açı panelini artık her karede baştan kurmak yerine sadece sayıları güncelliyorum (daha temiz, daha hafif).

Özet karne: mimari ve gizlilik baştan sağlamdı; bu turda tedarik zinciri kapatıldı, mobil hız yolu açıldı, motor testlendi, ve proje kimliği (C++) görünür oldu.

## Aşama 7 — Motor sayıyor

Bugüne kadar motor görüyordu ve anlıyordu — ama söylediği tek şey "şu an diptesin"di. Bugün ilk kez bir işe yaradı: **tekrar saydı.**

İşin güzel tarafı, saymanın neredeyse bedava gelmesi. Aşama 6'daki durum makinesi zaten "üstte/dipte" geçişlerini biliyordu; tekrar dediğin şey de tam bir döngü: dibe in, üste dön. O yüzden sayacın kuralı tek cümle: **motor "dipten üste" geçişini gördüğünde bir tekrar say.** İncelik şurada: histerezis sayesinde "dip" durumuna ancak alt eşiği gerçekten geçersen girebiliyorsun. Yani yarım inişler — 135 dereceye inip geri kalkmalar — fazı hiç değiştirmiyor ve kendiliğinden sayılmıyor. Sahte tekrarı reddetmek için ek kural yazmadım; doğru kurulmuş durum makinesi onu zaten reddediyordu. (Bunun kullanıcıya "yarım kaldı" diye söylenmesi ayrı bir iş — o sonraki aşama.)

Sayaç motorda, C++'ta duruyor — ekranda değil. Ekran sadece motorun verdiği sayıyı gösteriyor: panelin en üstünde, sayfadaki en büyük şey olarak, vişne renkli koca bir sayı. Sayı arttığı karede motor bir de "bu karede saydım" bayrağı veriyor; tarayıcı o bayrağı görünce kısa bir bip çalıyor (ses dosyası yok, tarayıcının kendi ses motoruyla üretiliyor) ve telefonda minik bir titreşim veriyor. Gözünü ekrana dikmeden antrenman yapabilesin diye — koç sayar, sen duyarsın.

Testlere de beş yeni madde girdi: tam döngü bir sayıyor, iki döngü iki sayıyor, yarım iniş saymıyor, sayma anında bayrak kalkıyor, reset sayacı sıfırlıyor. On altı test, hepsi geçiyor.

**Sırada:** saymak kolay, doğru saymak zor — yarım tekrarı fark edip kullanıcıya söylemek ("biraz daha in, o sayılmadı").

---

## Aşama 8 — "O sayılmadı"

Aşama 7'de şunu demiştim: histerezis yarım tekrarı zaten saymıyor. Doğru — ama saymamak yetmiyor. Yarım squat yapan biri sayacın artmadığını fark eder, sebebini anlamaz, ve motora küser: "bozuk bu". İyi bir koç sessizce yok saymaz; **"o sayılmadı, biraz daha in" der.** Bu aşama o cümleyi kurdu.

Mantık şöyle: kişi üst fazdayken açı üst eşiğin altına sarkarsa motor bunu bir "iniş denemesi" olarak izlemeye başlıyor ve o inişte görülen en derin açıyı aklında tutuyor. İki son var. Ya alt eşiği geçer — o zaman bu gerçek bir iniştir, faz makinesi devralır, tekrar normal sayılır. Ya da dibe ulaşmadan üste geri döner — işte o an motor karar veriyor: iniş anlamlı derinliğe ulaştıysa (hareket aralığının üçte birinden fazla) bu bir **yarım tekrar**: sayaç artmıyor ama ayrı bir "sayılmadı" hanesine yazılıyor ve kullanıcıya söyleniyor. Ulaşmadıysa hiçbir şey olmuyor — ağırlık alırken ufak bir kıpırdanma, esneme, duruş değişikliği yarım tekrar DEĞİL; onları azarlamak yanlış olurdu. Yani üç ayrı kader var: tam tekrar sayılır, yarım tekrar söylenir, kıpırtı görmezden gelinir.

Geri bildirim de ikiye ayrıldı: tam tekrarda tiz kısa bir "tık" + tek titreşim; yarımda pes bir "bzz" + çift titreşim. Ekrana bakmadan bile hangisi olduğunu duyuyorsun. Sayacın altında da küçük bir satır birikiyor: "not counted: 2 (too shallow)". Suçlayıcı değil, ama dürüst.

Eşik de veri, kod değil: "ne kadar derin iniş yarım sayılır" MoveSpec'te bir alan (yüzde 35). Yarın başka bir harekette bu oran farklıysa kod değişmeyecek, sayı değişecek.

Beş yeni test: yarım iniş yakalanıyor ve sayılmıyor, yakalandığı karede bayrak kalkıyor, sığ kıpırtı yarım bile değil, tam tekrar yarım üretmiyor, reset temizliyor. Yirmi bir test, hepsi geçiyor.

**Sırada:** her tekrar aynı değil — tekrar başına bir **kalite skoru**: derinlik, tempo, kontrol.

---

## Kalite skoru — motor saate kavuşuyor

Sayaç 12 diyor; ama 12 tekrarın 12'si aynı değil. Biri dibe kadar inip kontrollü kalktı, öbürü yarı yolda zıplayarak gitti geldi. İkisine de "1" demek saymak, ama koçluk değil. Bu adım her tekrara bir **puan** verdi: 0–100.

Bunun için motorun eksik bir duyusu vardı: **zaman.** Bugüne kadar motor kareleri sırayla görüyordu ama aralarında ne kadar süre geçtiğini bilmiyordu — tempo ölçemezsin. Şimdi her kareyle birlikte bir zaman damgası geliyor. Tasarım yine temiz kaldı: tarayıcı kendi saatini veriyor, testler sahte bir saat veriyor, motor umursamıyor — kim çağırırsa onun saatiyle çalışıyor. Saat verilmezse de saniyede 30 kare varsayıp kendi ilerliyor.

Puan üç bileşenden: **derinlik** (puanın yarısı — dibe gerçekten inildi mi), **tempo** (tekrar makul sürede mi; 1.2 saniyeden hızlısı momentumla zıplamaktır, puan kırar), ve **kontrol** (iniş serbest düşüş olmasın — inişin süresi çıkışa göre çok kısaysa ağırlığı bırakıyorsun demektir; spora gidenler bilir, eksantrik faz işin yarısı). Üç eşik de MoveSpec verisinde — başka hareket, başka tempo, kod aynı.

Bir de dürüstlük detayı: takip koparsa (kadrajdan çıktın, ışık gitti) motor o anki tekrar penceresini çöpe atıyor. Yoksa iki dakika sonra döndüğünde "126 saniyelik tekrar" diye saçma bir süre puanlanırdı. Emin olmadığını puanlamayan motor, uyduran motordan iyidir — bu ilke artık her katmanda.

Ekranda sayacın altında küçük bir satır: son tekrarın puanı, süresi, oturum ortalaması. Testler: kontrollü tekrar 90 üstü alıyor, aceleci tekrar daha düşük, ortalama birikimli, reset temizliyor. Yirmi altı test, hepsi geçiyor.

**Sırada:** motorun gözüne üçüncü boyut — MediaPipe'ın dünya koordinatları ile açıları 3B ölçmek, kamera açısından bağımsızlaşmak.

---

## 3B — düzlükten kurtulmak

Motorun baştan beri bilinen bir kör noktası vardı: açıları ekran düzleminde, iki boyutta ölçüyordu. Çoğu zaman sorun değil — ama vücut kameraya DOĞRU bükülünce perspektif o bükülmeyi yutuyor. Dizini kameraya doğru kırdığında ekranda bacak neredeyse düz görünür; 2B motor "ayaktasın" der, sen çömelmişsindir. Aşama 2'de bunu bilerek ertelemiştim ("derinlik tahmini gürültülü, sağlam olan basit olandı"); bugün borç kapandı.

Çözümün anahtarı MediaPipe'ın zaten verdiği ama kullanmadığımız bir şeydi: **dünya koordinatları.** Model her kare iki takım nokta üretiyor: ekrandaki yerleri (piksel uzayı) ve vücudun kalça merkezli, metre cinsinden 3B konumu. İkincisi kamera perspektifinden bağımsız — diz kameraya da bükülse yana da bükülse, metrik uzayda açı aynı açı.

Motor artık iki buffer alıyor ve işi ikiye bölüyor: **kadraj ve görünürlük ekran verisinden** (çünkü "kadraja sığıyor musun" sorusu kameranın gördüğüyle ilgili), **açı geometrisi dünya verisinden** (çünkü "dizin kaç derece" sorusu gerçek vücutla ilgili). Açı matematiği üç boyuta çıktı; dünya verisi yoksa motor eskisi gibi 2B'ye düşüyor — API kırılmadı, testlerin eski yarısı hâlâ aynı kodu sınıyor.

Bunun bir hediyesi de oldu: motor artık **nereden izlendiğini biliyor.** Omuz ve kalça hattı ekran düzleminde mi yayılmış, derinlik ekseninde mi — önden mi duruyorsun, yandan mı. Şimdilik ekranda küçük bir "view front/side" yazısı; ama asıl müşterisi bir sonraki aşama: form kuralları. Çünkü "dizler içe çöküyor" ancak önden görünür, "sırt açısı" en iyi yandan okunur — koç hangi kuralı ne zaman uygulayacağını artık seçebilecek.

Testin güzeli şu oldu: sentetik bir poz kurdum — ekranda dümdüz bacak, dünya verisinde kameraya 70 derece bükülü diz. 2B motor gerçekten kanıyor ("ayakta" diyor), 3B motor yakalıyor ve aynı faz makinesi/sayaç zinciri hiç değişmeden çalışıyor. Otuz iki test, hepsi geçiyor.

**Sırada:** koçun koç olduğu yer — form kuralları: "sırtın düz", "dizler dışarı". Kural = veri, görüş yönüne göre seçilir.

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
- **7 · Tekrar sayma** — faz geçişinden bir tekrar üret; büyük sayaç + "tık" (ses/haptik). İlk gerçek motor anı. *(bitti)*
- **8 · Yanlış tekrarı reddet** — yarım/eksik hareketi sayma (derinlik eşiği), "yarım kaldı" de. Saymak kolay, doğru saymak zor. *(bitti)*

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
