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

---

## Aşama 9 — Koçun koç olduğu yer

Saymak bir makinenin işi; **düzeltmek** koçun işi. Bu aşamada motor ilk kez formuna karıştı: "göğsünü dik tut", "dizlerini dışarı it".

İki kuralla başladım, ikisi de squat'ın en bilinen iki hatası. Biri **öne devrilme**: gövde (omuz-kalça hattı) dikeyden 55 dereceden fazla eğilirse sırt tehlikeye giriyor — "keep your chest up". Öbürü **diz çökmesi** (valgus): dipteyken dizler bileklerin genişliğine göre içe kaçarsa — "push your knees out". İkisi de 3B dünya koordinatlarından ölçülüyor; dünkü 3B işi bugünün temeli oldu.

Ama asıl mesele kuralların NE olduğu değil, NASIL durduğu. Üç tasarım kararı:

Bir: **kural = veri.** Motorda "squat'ın sırt kuralı" diye bir fonksiyon yok; MoveSpec'in içinde bir kural listesi var — ölçüm türü, eşik, mesaj. Push-up eklerken "kalça sarkmasın" kuralı kod değil, tabloya bir satır olacak.

İki: **kural, görüş yönünü biliyor.** Diz çökmesi ancak önden görünür — kameraya yan duran birinde o ölçüm anlamsız çıkar ve motor saçmalar. Dünkü "önden mi yandan mı" tespiti bugün müşterisini buldu: her kural hangi görüşte anlamlıysa yalnız o görüşte değerlendiriliyor. Yanlış açıdan yargılamayan koç.

Üç: **form puana işliyor.** Uyarı anlık ekranda beliriyor (yarım tekrar uyarısıyla aynı satır, o öncelikli), ama iş orada bitmiyor: tekrar boyunca ihlal edilen her farklı kural o tekrarın puanından 12 götürüyor. "10 tekrar yaptın" ile "10 tekrarın 6'sında dizlerin içerdeydi" arasındaki fark artık sayıda görünüyor.

Ve dürüstlük ilkesi burada da geçerli: 3B veri yoksa form hiç yargılanmıyor. Emin olmadan akıl vermek, yanlış akıl vermektir.

Testler: temiz tekrar sessiz ve cezasız, valgus cue + 1 ihlal + düşük puan, devrik gövde sırt uyarısı, yan görüşte valgus kuralına hiç bakılmıyor. Otuz dokuz test, hepsi geçiyor.

**Sırada:** motoru tek hareketten kurtarmak — hareket kütüphanesi: push-up, lunge, glute bridge, sit-up, press. Hepsi veri.

---

## Hareket kütüphanesi — bir motor, altı hareket

Bugüne kadar her şeyi squat üstünden anlattım. Sınav günü bugündü: "hareket = veri" iddiası doğruysa, yeni hareket eklerken motora DOKUNMAMAM lazım. Dokunmadım. Motor artık altı hareket izliyor — squat, push-up, lunge, glute bridge, sit-up, press — ve sayma/yarım/puan/form zincirinin TEK SATIRI değişmedi.

Her hareket bir veri satırı: hangi eklem zinciri izlenecek (squat dize bakar, push-up dirseğe, köprü kalçaya), hangi açı "dip" hangi açı "üst" demek, hangi noktalar kadrajda olmalı, hangi form kuralları geçerli, makul tempo ne. Kadraj bile hareketin verisi oldu: squat bacak ister, push-up kol ister — push-up modunda bacaklarını gösterip kollarını saklarsan motor dürüstçe "seni göremiyorum" diyor.

Beklemediğim bir hediye çıktı: faz makinesi tekrarı "bükülüden açığa dönüş" olarak saydığı için, iki zıt hareket ailesi kendiliğinden aynı makinede çalıştı. Squat gibi "in-kalk" hareketlerde de, press gibi bükülü BAŞLAYAN hareketlerde de (raftan kilide ilk açış = 1. tekrar) sayaç doğru. Bunu tasarlarken fark etmemiştim; veri modeli doğru olunca kod kendini genelledi.

Push-up'a ilk yeni form kuralı da geldi: kalça hattı. Omuz-kalça-diz çizgisi kırılırsa — kalça sarkarsa — "keep your body in one line". Kural türü motorda bir kez yazıldı; artık plank de eklesek aynı türü kullanacak, sadece eşiği farklı olacak.

Sayfada artık bir hareket seçici var (pembe, köşesiz, gymgyme dilinde) ve bütün kelimeler hareketle birlikte değişiyor: squat'ta "standing/deep", press'te "racked/locked", sit-up'ta "lying/up". Koç hangi hareketi izlediğini biliyor ve onun dilinden konuşuyor.

On dört yeni test — her hareketin kendi döngüsü, press'in bükülü başlangıcı, push-up kadrajının kol istemesi, kalça kuralı. Elli üç test, hepsi geçiyor.

**Sırada:** ürünleştirme bandı — hareketi gymgyme dizininden seçip koça bağlamak, set & dinlenme akışı, seans özeti.

## Aşama 13 — Bir tekrardan bir antrenmana

Şimdiye kadar motor tek bir şeyi çok iyi yapıyordu: tekrar say. Ama kimse "tekrar" yapmaz — insan "3 set, arada dinlen" yapar. Bugün motor tek tekrarı bırakıp bütün bir antrenmanı tutmayı öğrendi: kaç tekrarlık set, kaç set, aralarda kaç saniye mola.

En sevdiğim karar şu oldu: mola geri sayımını JS'e değil MOTORA koydum. Motor zaten saate kavuşmuştu (kalite skoru için her kareye zaman damgası veriyorum), o yüzden molanın süresini de o sayabilir. Bunun güzel yan etkisi: mola sırasında kameradan çıkıp su içsen bile saat işlemeye devam ediyor — çünkü geri sayım "seni göremiyorum" kontrolünden ÖNCE, en başta dönüyor. Mantık motorda, JS sadece kalan saniyeyi büyük pembe bir sayıya yazıyor. Kural hep aynı: analiz C++'ta, tarayıcı sadece tutkal.

İnce ama önemli bir kural: mola sırasında yaptığın hareket sıradaki setin hanesine yazılmaz. Dinlenirken kolunu esnetsen, bir yarım squat yapsan sayaç oynamaz — set arası settir. Faz makinesi çalışmaya devam ediyor (pozisyonunu kaybetmesin diye) ama tekrar ekleme adımı molada kapalı. Son set de dolunca antrenman "tamamlandı" oluyor, mola yok, üç notalı bir zil çalıyor ve sayfa "workout complete — 24 reps in 3 sets" diyor.

Plan tamamen opsiyonel. Tekrar sayısını 0 bırakırsan hiçbir şey değişmiyor, sayfa dünküyle birebir aynı: serbest say, hiç bitme. Plan verdiğinde ise sayacın üstünde küçük bir satır beliriyor — "set 2 of 3 · 5 of 12" — ve set bitince sayacın yeri sakin bir dinlenme bloğuna bırakıyor: "rest", büyük geri sayım, "i'm ready" ile erken çıkış. Set biterken iki notalı bir "tık", antrenman biterken üç notalı bir zil; kulağın da nerede olduğunu bilsin.

On yedi yeni test — planın 1. setten başlaması, hedefe ulaşınca molanın açılması, mola sırasındaki tekrarların sayılmaması, "hazırım"ın sıradaki sete geçmesi, molanın süresi dolunca kendiliğinden ilerlemesi, son setin antrenmanı bitirmesi, reset'in ilerlemeyi silip planı koruması, ve plansız modun hâlâ sonsuz sayması. Yetmiş test, hepsi geçiyor.

**Sırada:** seans özeti — antrenman bitince kaç tekrar, ortalama derinlik/skor, kaç temiz set; stitchu ruhunda yapılandırılmış küçük bir rapor.

## Aşama 14 — Seans bitince ne oldu

Bir antrenmanı yapmakla, yaptığını GÖRMEK ayrı şeyler. Motor tekrarları sayıyordu ama iş bitince ekranda "24" yazıp kalıyordu — o an insanın "e, nasıldı?" diye sorduğu an. Bugün motor o soruya cevap veriyor.

Özet yeni bir hesap değil, zaten tuttuğu şeyleri toplaması: kaç tam tekrar, kaç yarım (sayılmayan), ortalama puan, en iyi tekrar, kaç tanesi temiz formla, ve ilk kareden son kareye ne kadar sürdü. Motora bir `summary()` ekledim; oturum boyunca en iyi skoru ve temiz tekrarları biriktiriyor, süreyi ilk/son kare zamanından çıkarıyor. Hepsi C++'ta, test edilebilir; JS sadece sıcak cümlelere çeviriyor: "24 reps across 3 sets, in 4 min 12s. they averaged 88 out of 100, your best was 96. 21 came with clean form."

Küçük ama düşündüğüm bir detay: özet, motor sıfırlanmadan ÖNCE alınmalı. Antrenmanı durdurunca `reset()` her şeyi siliyor — o yüzden "stop"ta önce özeti ekrana basıp sonra sıfırlıyorum. Antrenman kendi bitince (son set dolunca) özet zaten üç notalı zille birlikte beliriyor.

Altı yeni test, yetmiş altı test hepsi geçiyor. Motor artık bir tekrarı değil, bütün bir seansı anlatabiliyor.

**Sırada:** bu özeti gymgyme "programım"a işlemek — "en son ne zaman yaptın" güncellensin, seans geçmişe düşsün.

## Aşama 16 & 17 — Herkese ve her telefona

İki sessiz ama şart olan pas: erişilebilirlik ve mobil/performans.

Erişilebilirlik: sayaç, form ipuçları, set satırı ve mola geri sayımı artık `aria-live` — ekran okuyucu her tekrarı, her uyarıyı sesli duyuruyor. Plan alanlarına etiket, butonlara görünür klavye odağı, hareket hassasiyeti olanlar için `prefers-reduced-motion`'da sayaç zıplaması ve bar animasyonu kapanıyor. Koç gözle görmeyen için de çalışıyor.

Mobil & performans: kamera artık sabit 640x480 istemiyor, ön kamerayı esnek çözünürlükle istiyor — telefon dikey verirse motor kadraja uyuyor. Ve sekme arkaya atılınca ağır pose işini atlıyoruz; kamera açık kalıyor ama telefon ısınmıyor, pil yanmıyor. Çoğu insan bunu telefonla yapacak; o yüzden bu pas lüks değil.

## Aşama 11 & 15 — Koç yalnız bir sayfa değil artık

Koç şimdiye kadar ada gibiydi: açarsın, çalışırsın, kaparsın, iz kalmaz. İki bağ attım.

Derin bağlantı (11): coach.html artık `?move=squat` gibi bir adresle açılıyor ve o hareketi seçili getiriyor. Böylece ileride her yerden ("şu hareketi çalıştır" düğmesi, program, mail) koça doğrudan o hareketle girilebilir. Dizindeki linkleri koç hareketlerine otomatik eşlemeyi bilerek YAPMADIM — "Duvarda Yüz Nefesi" bir squat değil; uydurma eşleme kötü bir "coach me" düğmesi demek. O bağ, hareketlerin gerçek meta verisi olduğunda kurulur, tahminle değil.

Seansı gymgyme'ye işlemek (15): antrenman bitince seans localStorage'a yazılıyor ve bugün gymgyme takviminde bir "antrenman günü" olarak yanıyor — koç ile dizin aynı origin, aynı hafıza. "Programım"a gidince bugünün dolu olduğunu görüyorsun. Özette küçük bir satır da bunu söylüyor: "saved - today is now a workout day". Koç artık ürünün geri kalanıyla konuşuyor.

## PWA — App Store'a uğramadan telefona kurulan app

Telefonuna bir fitness app'i kurdun ama App Store'u hiç açmadın. Nasıl?

Bugün personal trainer bir PWA oldu. Üç parça: bir manifest dosyası (isim, ikon, "tam ekran aç" talimatı), site pembesi Arial ikonlar, ve bir service worker. Service worker şunu yapıyor: sayfayı ilk açtığında motorun wasm'ını, MediaPipe'ı, modeli, her şeyi telefona önbellekliyor. Safari'de paylaş menüsünden "ana ekrana ekle" diyorsun, ikon ana ekrana düşüyor, tıklayınca tarayıcı çubuğu olmadan tam ekran açılıyor — ve uçak modunda bile çalışıyor, çünkü kamera da motor da zaten cihazda, sunucuya giden hiçbir şey yok. İndirme bariyeri yok, inceleme kuyruğu yok: reels'te linki gören 10 saniye sonra squat sayıyor, beğenen ana ekranına kuruyor.

## Hesap bandı sertleşti — yalan söylemeyen senkron

Bir fitness uygulaması sana "kaydedildi" dedi ve yalan söyledi. Bizimki söyleyemez, çünkü bugün onu imkansız hale getirdim.

Ship-check üç gedik buldu. Bir: özet kartı, kayıt veritabanına gerçekten ulaşmadan "hesabına kaydedildi" diyordu — offline'da bu düpedüz yalandı. Artık satır önce "saving..." diyor, sonuç gelince gerçeği söylüyor; başaramayan kayıt cihazda kuyruğa giriyor ve bağlantı dönünce kendiliğinden gönderiliyor, seansın gerçek tarihiyle. İki: şifreni unutursan hesabın sonsuza dek kilitliydi. Artık "forgot your password?" var; maildeki link yeni şifre sayfasına düşüyor. Üç: seansların veritabanına yazılıyor ama hiçbir yerde görünmüyordu — yazılan ama okunmayan veri, ölü veridir. Artık sayfanın altında "your workouts" var: girişliysen hesabındaki, değilsen bu cihazdaki son seansların, satır satır.

## Aşama 18 — Yayın: kapı açıldı

On dokuz aşamanın sonuncusu tek kelimeyle geldi: "yayınla".

Bugüne kadar personal trainer sitede saklı bir sayfaydı: menüde yok, Google'a kapalı, sadece adresi bilen girer. Bugün üç kilit açıldı. Menü: dizinin ve öneri sayfasının kenar çubuğuna "personal trainer" linki kondu, artık siteye giren herkes onu görüyor. Google: noindex kalktı, sitemap'e girdi, canonical ve paylaşım kartı eklendi — arayan bulacak. Ve kapının önüne bir cümle: ilk seansından önce, kamera izni istenmeden, ürün sana açıkça söylüyor — "kameran bu cihazda okunur, hiçbir video yüklenmez, kaydedilmez" — sen "got it - start" demeden kamera açılmıyor. KVKK'nın istediği de, zaten doğrusu da bu. Motor 0'dan 18'e tamam: link listesi olarak doğan site, artık seni izleyip sayan, puanlayan, düzelten ve hatırlayan bir ürün.

## Motor vücudunu tanıyor artık

İlk gerçek kullanıcım (Damla) ilk gerçek şikayeti getirdi: "iskelet bazen iç içe geçiyor, takip kopuyor." Haklıydı. Üç şey değişti.

Bir: kalibrasyon. Kamera açılınca motor ilk bir buçuk saniyede vücudunun oranlarını öğreniyor — uyluğun, baldırın, kolların, omuz genişliğin, hepsi gövdene bölünmüş halde, yani kameraya yaklaşsan da aynı. Sonra o vücuda kilitleniyor: gelen okuma öğrendiği vücuda uymuyorsa (iskelet koltuğa ya da odaya giren birine ışınlandıysa) o kareyi reddediyor. "learning your body - one moment" derken yaptığı bu. İki: ince takip. Tek karelik dev açı sıçramaları (ışınlanma) yutuluyor; hareket iki kare sürüyorsa gerçek kabul ediliyor. Üç: her hareket artık kendi kadraj cümlesini söylüyor. Push-up bütün vücudunu istemiyor; bacakların kadraj dışında kalabilir ve motor bunu biliyor: "i need your arms and torso - your legs can stay out." 86 native test, hepsi yeşil. Ve en güzeli: bu üçü de motora girdi, yani yarın bale de fizyoterapi de aynı kilidi miras alacak.

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
- **9 · Form kuralları (squat)** — diz-parmak hizası, sırt açısı → "biraz daha in", "sırtın düz". Koç burada koç oluyor. *(bitti)*
- **10 · İkinci hareket** — push-up ya da lunge ekle; kural setini genelleştir (her hareket = bir eşikler tablosu). Tek harekete gömülü kalmasın. *(bitti — altı hareketle)*

**Ürünleştirmek**
- **11 · Kütüphaneye bağla** — gymgyme'deki hareketi seç → o harekete özel koç modu açılsın. Dizin ile motor birleşir. *(bitti — ?move= derin bağlantı; link→hareket otomatik eşleme bilerek yapılmadı, gerçek meta veri ister)*
- **12 · Hareket kural verisi** — moves verisine açı eşikleri + talimat alanları; yeni hareket = veri eklemek, kod değil. Genişleyen sistem. *(bitti — motor tarafı; dizin verisine bağlama 11 ile birlikte)*
- **13 · Set & dinlenme akışı** — "3 set x 12", set arası dinlenme sayacı, sesli yönlendirme. Tek tekrardan tam antrenmana. *(bitti — mola geri sayımı motorda, plan opsiyonel)*
- **14 · Seans özeti** — kaç tekrar, ortalama derinlik, form skoru; bölge bölge küçük rapor. Yapılandırılmış çıktı (stitchu ruhu). *(bitti — motorda summary(), sıcak dilde kart)*
- **15 · "Programım"a bağla** — seansı gymgyme planlayıcısına işle, "en son ne zaman yaptın" güncellensin. Motor ürünün geri kalanıyla konuşsun. *(bitti — seans localStorage'a + bugün takvimde antrenman günü olarak yanar)*
- **16 · Ton & erişilebilirlik** — VOICE diline uygun, suçlamasız cümleler; sesli sayım; düşük görme/renk körü uyumu. Soğuk bir makine değil. *(bitti — aria-live, klavye odağı, reduced-motion)*
- **17 · Mobil & performans** — telefon kamerası, dikey çerçeve, lite model/GPU, düşük pil. Çoğu insan telefonla antrenman yapacak. *(bitti — ön kamera esnek çözünürlük, sekme arkada pose durur)*
- **18 · Yayına aç** — menüye ekle, ilk kullanım onboarding'i, gizlilik/consent metni (cihazda çalışır, kayıt yok — KVKK temiz). Artık herkese açık.

Büyük ve çok oturumluk iş — acele yok. Bittiğinde gymgyme "linklere bak"tan "seni izleyip çalıştıran koç"a dönüşmüş olacak: aynı site, bambaşka bir kalp.

## the night the site became a cinema (jul 14)
hook: "i redesigned my whole fitness site as a movie theater marquee - in one night, live with the founder yelling at every draft."
- 24 mockup iterations in one sitting: receipts, sticker sheets, night gyms, playlists, word walls - all rejected or mined for parts
- the winner: a cherry marquee sign with blinking bulbs, scalloped awning, ticket stubs and a "TESTED ON HERSELF DAILY" stamp
- the set list is now a RECEIPT: tilted, draggable, closable, prints itself line by line
- new moves.html: 188 no-equipment moves (public-domain free-exercise-db), muscle filters, hearts that feed "my moves"
- global search bar that shows results and waits for YOUR click (strava energy)
- the whole faq rewritten techy-but-human: "is it chatgpt? no - it's trigonometry running at camera speed."

## the ruler came before the engine (jul 14)
hook: "everyone tunes their computer vision by eyeballing it. i built a ruler first."
- the precision plan: gymgyme's engine becomes a reusable body-CGI motor (gym today, ballet and physio tomorrow)
- phase 0 shipped: a measurement bench (engine/bench.sh) — synthetic squats where the TRUE angle is known, plus a hidden ?rec=1 recorder that dumps exactly what the motor sees into a .ggclip file
- phase 1 shipped: the One Euro filter (the same filter inside VR headsets) replaced plain EMA — in angle space, time-aware, parameters chosen by a grid sweep, not by feel
- numbers, same noise, same seed: bad-light jitter 5.01° raw → 2.82° EMA → 2.32° one euro, lag unchanged at 33 ms, zero false "didn't count" warnings
- first sweep quietly optimized calm by buying it with lag — exactly the "not responsive" complaint from before. added a lag penalty to the score and re-swept. the ruler caught the ruler.
- pose model upgraded lite → full (9 MB, still fully on-device)
- 94 native tests green, wasm rebuilt, pwa cache v15

## the skeleton can no longer be stolen (jul 14, later that night)
hook: "my teacher walked into the frame and my AI started coaching HER. fixed it at the physics level."
- phase 2 of the precision plan: the engine now works like a CGI rig, not a point detector
- BONE LOCK: calibration learns your absolute bone lengths (world space, metric), then every frame the skeleton is re-fit to those lengths — the detector proposes a direction, never a length. bone variance: 1.3-5.7% raw → 0.00% locked, in every noise scenario
- MULTI-PERSON: the detector now returns 2 bodies and the ENGINE picks whose to trust — calibrated proportions + similarity to the last accepted pose. benchmark: naive path spent 360 frames coaching the stranger and lost 2 reps; engine pick: 0 wrong frames, 8/8 reps
- the drawn skeleton is now the MOTOR's smoothed skeleton (per-landmark one euro), not raw mediapipe — what you see is what the engine believes
- teleport gate went time-aware: 700°/s physiological ceiling instead of a per-frame constant
- angle metrics IMPROVED with the lock on: bad-light rmse 3.54°→2.70°
- 104 native tests green

## the engine now coaches exactly one person: you (jul 14, addendum)
hook: "my fitness AI is now as loyal as a DJI drone - it locks on YOU and refuses everyone else"
- damla's call: no two-person mode (too slow, not the product) - instead the lock got HARD
- a candidate body that fails the calibrated proportions VETO is disqualified, not just penalized - and the veto uses the WORST ratio, not the mean (a stranger's short legs can't hide behind normal arms)
- if only strangers are in the frame the engine waits for you instead of coaching them: "i only coach the body i learned"
- benchmark: stranger-alone window, naive path coaches them for 420 frames; hard lock: 0 frames, 8/8 reps, tracking resumes the moment you step back in
- 106 native tests, sw v17

## the coach talks back now (jul 15, small hours)
hook: "my AI trainer doesn't just count anymore - after every rep it tells you what it thought of it"
- phase 3 layer 1: after each rep the engine writes a SENTENCE from the numbers it already measured - "textbook - deep and controlled", "counted - sink deeper next time", "you dropped into it - own the way down"
- priority order is a coach's: form first, depth second, tempo third
- the teleport gate became exercise-aware: the speed ceiling now derives from each move's own physics (a squat physically can't sweep 90° in one frame, a jumping jack can) - the engine assumes squat physics DURING a squat. first brick of the exercise-prior solver.
- funny honest moment: the comment engine called my own test rep "a bit rushed" - and it was right, the test was too fast. fixed the test, not the engine.
- 112 native tests, sw v18. also told github linguist that mediapipe's 5 MB bundle is not my code - the repo now shows what it really is: a C++ engine

## no more stick figure, and the squat that never counted (jul 15, night)
three complaints from Damla in one message, tackled in her order: mesh, lock, counting.

**"it shows me like a wire stick figure. my fingers are a 3-branched tree. my lips are one line - but they're curved. we're multi-dimensional."** — she's right, the overlay was thin 2D lines. built a real drawing layer (js/mesh.js) that is DRAW-ONLY, never touches the counting math:
- the body is now VOLUME, not a line: limbs drawn as depth-shaded capsules (muscle thickness), torso as a filled shaded shell, joints as spheres. near surfaces light and thick, far ones dark and thin - a 3D surface, not a wireframe.
- the face is a filled mesh: 468-point tesselation as shaded skin, then the CURVED features (lips, eyes, brows, oval) inked on top. her lip is a curve now, not a line.
- the hands are filled: palm polygon + each finger a capsule with rounded knuckles. not a 3-branched tree - a real hand.
- fps stayed the worry (her phone lesson): the two extra models (face+hand) auto-SLEEP below 20 fps and wake above 26 (hysteresis). the body fill costs nothing - it comes from the pose we already have.

**"it doesn't stay on me - it focuses on whoever walks in."** — the lock was already there; proved it holds against a SAME-SIZED twin (ratios can't tell them apart) - the teleport gate elees anyone who appears where we weren't a frame ago. added the test.

**"i bend, it sees me bend, but it doesn't count the squat."** — the real bug. counting keyed on a FIXED 120° knee threshold. front-facing, perspective flattens the knee angle, so a real deep squat never touches 120 - zero reps, even though the depth bar fills. fix: an ADAPTIVE bottom threshold. the engine learns your actual standing angle, then sets "bottom" at 42° below YOUR rest - so counting keys off your real range, not a constant. the fixed 120 stays as a floor (safety net, never asks impossible depth). proved with a test: a ~130° squat (above the old fixed threshold) now counts.

120 native tests, wasm rebuilt, sw v34.

## the engine grows real capabilities: hold motor, kalman, +198 moves (jul 15, deep night)
Damla's push: "this is a real product to be sold, not a kid's toy - make the engine bigger, don't be timid."  she's right that 2800 lines is thin for a "CV engine". so i started adding REAL capability, not filler lines - each one tested.

- HOLD MOTOR (isometric): the engine could only count rep oscillations (squat down-up). planks, wall-sits, side-planks, supermans, hollow holds have NO oscillation - they were silently a dumb 45s stopwatch. added a MoveKind::Hold path: the engine accumulates seconds spent inside a target angle band and grades hold quality live from the form rules (a sagging plank scores lower than a clean one). leaving the band stops the timer; the best unbroken hold is remembered.
- a real insight fell out of debugging: the engine can't tell "standing" from "plank" by joint angle alone (both have a straight hip). it needs gravity-aware body orientation - next.
- KALMAN FILTER (engine/kalman.hpp): One Euro smooths one signal but has no model of the future - if a landmark drops for a frame it goes silent. a constant-velocity Kalman holds each point's position AND velocity: predict (keeps flowing on predicted velocity through an occlusion - the skeleton doesn't jump when a hand passes behind the body), update (optimally blends measurement vs process noise by the Kalman gain). 12 tests prove the math: convergence, velocity learning, occlusion coasting, noise suppression, confidence-weighted updates. this is the same math mocap/AR solvers (Vision Pro, mediapipe internals) are built on.
- LIBRARY 188 -> 386 moves: expanded MOVE_DB with 198 real, fact-checked home/bodyweight exercises across all 7 muscle groups (no fabrication - a verify pass removed anything gym-only or invented).
- gitattributes: marked the data files as generated so github linguist stops calling this a JS project - it's a C++ vision engine with a thin web binding.
- 143 native tests (131 engine + 12 kalman).

## kalman wired into the engine: the skeleton stops jumping (jul 15, deep night)
the Kalman filter existed as a tested module; now it's actually in the draw path. before drawing, each landmark runs predict (coast on velocity) then correct (blend by confidence). when a joint drops for a few frames it keeps flowing on its last known velocity instead of freezing or teleporting; when it comes back a blurry low-visibility read is trusted less. after ~0.5s of occlusion it stops guessing (no phantom limb). draw-only: the counting angles still read raw/world data, so counting is provably unaffected (test asserts reps unchanged through an occlusion). 151 native tests.

## anatomical joint limits: the skeleton can't bend backwards anymore (jul 15, deep night)
bone-lock fixed LENGTH (a bone can't stretch). but the ANGLE was still free - detector noise could bend a knee backwards, which is anatomically impossible. added engine/ik.hpp: real human joint ranges (knee ~15-183, elbow ~20-185, hip ~25-205). after bone-lock places the chain, each joint angle is clamped into its legal range by rotating the child around the parent (Rodrigues) - direction preserved, length preserved, angle made legal. an impossible read is treated as what it is: noise. this is the core of mocap "cleanup". 9 ik tests prove the math (valid angle untouched, over-bent knee pulled to its limit, bone length preserved). wired behind ikOn_ after bone-lock. 158 native tests (engine + kalman + ik). wasm grew 66kb -> 74kb of real capability.

## symmetry analysis: the engine sees left-right imbalance (jul 15, deep night)
a real coaching/physio insight most apps miss. when both sides are visible the engine now measures the left-vs-right tracked-angle gap every frame (asymmetryDeg), keeps the worst gap seen during each rep, and if one side does meaningfully more work than the other (>15deg) the coach says so: "counted - but one side is doing more work than the other". this is exactly the compensation pattern a physio watches for after an injury. -1 when only one side is visible (side-on) - it won't fake a number it can't measure. exposed torsoTilt, asymmetry, hold fields through bindings so the JS layer can show them next. 163 native tests.

## the engine recognizes the exercise on its own (jul 15, deep night)
until now the engine watched the move the user PICKED. a real coach recognizes what you're doing without being told. engine/classifier.hpp reads a signature from the last ~2s of motion: which of the four big joints oscillates most (knee/elbow/hip/shoulder), is the torso upright or horizontal (gravity tilt), is it a rep or a static hold, how big is the swing. those four dimensions separate most home moves: oscillating knee + upright = squat, oscillating elbow + horizontal = push-up, static + elbow-support + horizontal = plank. it returns a best guess WITH a confidence - explainable geometry, not a black box, so every call can be debugged. 8 classifier tests + a motor-level test (the engine independently calls a squat a leg move). exposed detectedMove/detectedConfidence through bindings for a future "did you mean X?" nudge. 174 native tests. wasm 75kb -> 79kb.

## 2d->3d metric pose refinement: steadying the ground all angles stand on (jul 15, deep night)
every angle, every rep, every form rule reads from MediaPipe's world (3d metric) landmarks. but world-z is the noisiest channel - it jumps frame to frame, and that jitter leaked straight into the angle. added refineWorld(): each world point runs through its own 3d Kalman (predict + confidence-weighted correct) before any angle is measured. z gets the most benefit since it's the noisiest axis. the angles now stand on a temporally-consistent metric skeleton. proved it with a variance test: inject frame-to-frame z noise, and the refined knee angle is measurably steadier than the raw world angle (caught a squaring-symmetry trap in the test setup along the way - signed-symmetric z noise doesn't move the angle, so the test had to use asymmetric noise). 175 native tests. wasm 80kb.

## second-pass audit: 6 real bugs the growth introduced, all fixed (jul 15, deep night)
ran an adversarial gap-hunt over the grown engine (3 dimensions, each finding verified by an independent skeptic). it found 6 confirmed major bugs - the kind that hide exactly where new code meets old:
1. refineWorld was BYPASSED in steady state: once calibrated, bone-lock solved from RAW world, throwing away the z-smoothing i'd just added. now solveBones consumes the refined world - the feature actually works on the main path.
2/3. mixed raw/refined within a frame: angles read refined but tilt, view, torso-lean and valgus read raw. now all read the refined skeleton - counting, orientation and form cues agree, and the plank/wall-sit tilt gate stops chattering on z-jitter.
4. hold plan showed "0 of 30 reps" and "0 reps" completion - the rep-based set line leaking into hold mode. now shows seconds: "set 1 of 2 · 12s of 30s".
5. multi-set hold summary reported only the LAST set's seconds (heldSec_ zeroed each set but summary read it). added a lifetime accumulator; a test proves a 2-set hold now sums both.
6. hold quality couldn't drop for hollowhold/superman (no form rules). added a rule where it fit and made hold quality also reward staying near the CENTER of the band - works for every hold without needing a rule.
also gave press/jumpingjack/armraise the form rules they were missing. 176 native tests. sw v37.
noted but deferred honestly: world-kalman + one-euro are now two smoothers in series; the one-euro params were bench-tuned for the old pipeline. re-tuning needs a real golden clip (Damla's) - i won't blind-tweep filter params.

## the CGI overlay is now a NET, not a blob (jul 15, deep night)
Damla: "make the CV look like a net - like those interactive installations where you stretch light between your fingers." and the jury's harshest finding backed it: the old body fill was a ~90% opaque cherry blob painted OVER the video - you literally couldn't see yourself, reads as "the filter broke". replaced the whole body render: no fill. the body is now a NET - glowing threads (a triangulated weave: torso quad + diagonals + limb edges + shoulder-elbow cross-lacing) with a soft halo and a bright inner filament, plus glowing nodes at every joint (radial-gradient halo + white core), all depth-lit so near threads are brighter/thicker. the real video shows through - it's an energy weave on top of you, not a mask. also removed the second stick-figure skeleton that was drawn over the fill (jury: two skeletons stacked = noise, brought the stick figure back). one visual language now. sw v38.

## IK honesty pass: relabel, widen, iterate to convergence (jul 15, jury response)
the CS dean caught three real things about the joint limits, all fair:
1. the numbers were presented as "derived from human ROM" with no citation - they were educated guesses. relabeled honestly as HEURISTIC SAFETY clamps whose only job is to reject the physically impossible, not to correct a real angle.
2. the bands were too tight (knee 15, elbow 20) - a legitimately deep bend could get rotated OUT and corrupt a real rep. widened to reject only the impossible (knee/elbow <5 or >185-188); a test proves a real ~30deg elbow bend is left untouched.
3. clamping coupled joints in one pass doesn't guarantee a globally-legal skeleton - fixing the hip moves the knee back out. now iterates to a fixed point (<=4 passes); a test builds an over-bent knee AND over-closed hip and asserts BOTH are legal after clamping.
180 native tests.

## jury polish: honest hold label, count-up, nudge own slot (jul 15, jury response)
three more jury findings fixed:
- pilates princess: don't print a "quality %" for a hold whose form you can't measure. superman (no form rule) now shows "in position N" instead of "hold quality N" - honest about what the geometry can back.
- pilatess princess: the rep count and hold seconds hard-swapped like a gym timer. added a count-up tween (numbers climb smoothly to target, snap down on reset) - Damla's premium-flow standard.
- pilatess princess: the did-you-mean nudge wrote into the same element as form cues and got clobbered / only fired at reps===0. moved it to its own slot (subEl, separate from the msg cue) and it now fires through reps<=1. sw v39.

## classifier can now tell squat from lunge (jul 15, jury response)
the CS dean's sharpest classifier finding: squat and lunge had IDENTICAL signatures (both Knee/upright/rep), so claiming "the engine recognizes what you're doing" while it provably couldn't separate the two most common leg moves was inflated. fixed it for real, not by scoping down: added an ASYMMETRY dimension. a squat is symmetric (left knee = right knee); a lunge is one leg forward = a large left-right angle gap the engine already measures. the classifier now feeds mean asymmetry and separates the pair - a test proves symmetric knee motion -> squat, asymmetric knee motion -> lunge. the claim is now true. 182 native tests.

## pilates safety: breath cue + lumbar warning (jul 15, jury response)
two safety findings from the pilates instructor, both real and cheap:
- no breath cue anywhere. holding your breath (Valsalva) during a plank/wall-sit spikes blood pressure - dangerous for some. every hold now rotates "keep breathing - don't hold your breath" into the phase text every ~6s. costs nothing, removes a real liability.
- lumbar-loading moves (sit-up, superman, hollow hold, glute bridge) were offered to anyone with no warning. now each shows a one-time cue on load: "this move loads your lower back - skip or keep it small if you have back pain". the instructor's exact ask for a fragile-back client.
sw v40.

## kalman params are now swept, not guessed (jul 15, jury response)
the CS dean's most repeated jab: the one-euro params were grid-swept but the world-Kalman q/r were hand-picked magic numbers - the exact sin the project accused EMA of. fixed the inconsistency: added `bench kalmansweep`, a q/r grid search against the synthetic ground truth scored on jitter+rmse+lag with rep-accuracy as a hard gate. picked q=10/r=2e-4 by measurement (marginally better than the old 40/4e-4). the honest sub-result: the world-Kalman is nearly insensitive to q/r on this synthetic path (jitter 1.63-1.77 across the whole grid) - i.e. one-euro is already doing the work and this layer's real payoff is occlusion, not steady-state smoothing. that's the truth and it's in the sweep output. 182 native tests.
