# devlog — gymgyme koç, build in public

IG için hook'lu 30-60 sn reel scriptleri. İlk cümle KANCA. Damla seslendirir. Kaynak: BUILD-LOG.md. Sınır yok, biriktirilecek.

---

## İKİ TEMPLATE — devlog ikisini de tutar

Bu dosyada iki tür kayıt var. Biri sosyal-medya (reels), biri teknik günlük. İkisi de burada yaşar.
NOT: reels malzemesini ne zaman düşüreceğine CLAUDE karar verir (Damla'ya sormaz) — aklına uygun bir an/konu geldiğinde stoğa atar. Sınır yok.

### TEMPLATE A — REELS (sosyal medya · Damla seslendirir · hepsi tek tür)

Reels tek türdür. İçinde üç kaynak var ama HEPSİ reel: (1) build anı — o loop'ta/sistemde ne yaptım. (2) kavram/açıklama — wasm, pose estimation gibi terimi mala öğretir gibi. (3) konu/sohbet — teknoloji, sosyoloji, marketing ya da günlük hayattan aklına düşen görüş. "Vlog" diye ayrı bir şey YOK; sohbet reel'leri de bu template.

DETAY + BOLLUK ŞART: içerik DETAYLI ve ÇOK olmalı. Bir sistem ne kadar büyükse o kadar çok reel çıkar — stitchu bir oyun motoru + SaaS (API), böyle bir proje 6-9 reel'e SIĞMAZ. Her sistem, her mimari karar, her alt-özellik, her downfall/pivot kendi reel'ini hak eder. "Birkaç reel yeter" YANLIŞ; derinlemesine ve bol üret. Küçük parça = ayrı reel.

TR/EN İKİ VERSİYON: her reel'in bir de İngilizce karşılığı olur.
- **TR** → konuşarak (seslendirme rahat). Hook + anlatı Damla'nın sesiyle.
- **EN** → VARSAYILAN "text-on-video" (çekim + üstüne yazı; Damla EN konuşurken utanıyor). Yani EN'de ekranda kısa güçlü YAZI cümleleri olur, sesli anlatı şart değil. Bazen EN'de de konuşabilir ama default yazı.

```
## Reel — [kısa başlık, konu ne]  (build ise: (loop XX / sistem adı))

**Hook (ilk 2 sn):** "[Merak uyandıran, ters köşe ilk cümle.]"

**Anlatı (~30-60 sn):** [TR · Damla'nın sesi. Build ise: neyi değiştirdim → çünkü şu sorun vardı → nasıl çözdüm → ders. Konu/sohbet ise: net görüş + neden + kendi deneyiminden örnek. Terim geçerse sıfırdan aç.]

**EN (text-on-video):** [aynı reel'in İngilizcesi ama EKRAN YAZISI olarak — kısa, güçlü, ardışık cümleler. Konuşma metni değil, üstüne bindirilecek yazı. Örn: "your camera counts. / nothing leaves your phone. / no server. no upload."]

**Format:** reel   (ya da: reel / carousel)
```

Kurallar: ilk cümle KANCA · 30-60sn kısa · gerçek tarihçeden/gerçek görüşten · terimi mala öğretir gibi aç · net duruş al (ortada durma) · TR konuşma + EN text-on-video · DETAYLI ve BOL · sınır yok, biriktir.

TON — DERS DEĞİL, SOHBET: Damla dünyanın eğitimcisi değil; bir insan build ediyor. Eğlence, espri, iç geçirme, "of yine mi bu bug", "3 saat uğraştım meğer noktalı virgülmüş" tarzı gerçek anlar önemli — asıl bağ orada kurulur. Düşünce akışı, kafadan geçenler, küçük zaferler/hüsranlar, arada laf sokma. Öğretme kısmı espinin/hikâyenin İÇİNE gömülü olsun. Her reel bilgi vermek zorunda değil — bazısı sadece bir an, bir düşünce, bir gülümseme.

### TEMPLATE B — TECH DEVİNİM (developer diary · düz teknik kayıt · sosyal medya DEĞİL)

Bu sosyal medya için değil — kendi teknik günlüğün. Ne yaptım, neden, nasıl; ilerde "burada ne düşünmüştüm" diye dönüp bakılan kayıt. Hook yok, espri şart değil, net ve dürüst.

```
## Devinim — [tarih] · [ne üstünde çalıştım]

**Ne yaptım:** [somut değişiklik — dosya/fonksiyon/parametre]
**Neden:** [hangi sorun/karar bunu getirdi]
**Nasıl:** [yaklaşım, seçtiğim yol + elediğim alternatif]
**Sonuç/kanıt:** [test/benchmark/render — sayıyla, iddia değil]
**Takıldığım / açık kalan:** [varsa; ileriye not]
```

Kurallar: dürüst (çalışmayan çalışmadı yazılır) · sayıyla konuş (test geçti/benchmark X) · kısa ama izlenebilir · gelecekteki Damla'ya not gibi.

STOK KONU FİKİRLERİ (reel için · Claude aklına geldikçe büyütür):
- yapay zekayla kod yazmak: asistan mı, koltuk değneği mi, çoğaltıcı mı? gerçek deneyim.
- slop uygulama nasıl anlaşılır — 5 işaret (backend yok, hepsi localStorage, aynı gradient, CRUD'un yarısı, "coming soon"lar).
- vibecoding gerçekten iş görür mü, nerede duvara çarpar (motor/mimari gerektiren yerde).
- AI kodu yazarken senin işin ne kalıyor: karar, mimari, "bu doğru mu"yu ölçmek.
- bir CS öğrencisi olarak AI çağında ne öğreniyorum / öğrenmiyorum.
- "her şeyi AI yazsın" ile "hiçbir şeye güvenme" arasında sağlıklı yer neresi.
- (teknoloji / sosyoloji / marketing / günlük hayat — sınır yok)

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

## Reel — kendi eklediğim şeyi ölçüm çürütünce kapattım

**Hook (ilk 2 sn):** "Motora bir katman ekledim, testler yeşildi, 'iyileştirdim' dedim. Sonra kendi ölçümüm beni yalancı çıkardı."

**Anlatı (~45 sn):** Kameranın gürültülü derinlik tahminini ikinci bir Kalman filtresinden geçirdim, açılar daha kararlı olsun diye. Yeşil testler, güzel bir build-log yazısı, devam. Sonra kurduğum jürideki CS dekanı benim kendi ölçüm bandımı kötü ışıkta çalıştırdı — ve katman motoru KÖTÜLEŞTİRİYORDU. İkinci filtre gecikme ekliyor, gürültüde işi bozuyordu. İki seçenek: ya essay'i yumuşatıp katmanı açık bırakmak, ya ölçüme uymak. Katmanı kapattım. Çünkü yeşil testler çoğu zaman senin varsayımını doğrular, gerçekliği değil. Bir şeyi eklemek kolay; kendi ölçümün çürüttüğü için geri kapatmak — işte o disiplin.

## Reel — "sabit dur" diyen kalibrasyon

**Hook (ilk 2 sn):** "Motor seni tanırken 2 saniye kıpırdarsan, öğrendiği vücut yanlış olur. Bunu düzelttim."

**Anlatı (~35 sn):** Kimlik kilidi kalibrasyonla başlar — motor ilk 2 saniyede vücut oranlarını öğrenip sana kilitlenir. Ama bir kalite kapısı yoktu: o 2 saniyede kıpırdarsan kirli ölçüler medyana giriyor, ve sonraki her "bu sen misin" kontrolü bozuk bir ölçüye dayanıyordu. Bir tutarlılık kapısı ekledim: her ölçünün yeterli örneği OLMALI ama saçılmamış da olmalı. Çok oynayan bir ölçü (hareket ettin) güvenilmez işaretlenip kilide alınmıyor. Ve hiç sağlam ölçü çıkmazsa motor çöpe kilitlenmiyor — "bir saniye sabit dur" deyip yeniden öğreniyor. Kilit artık gerçekten sabit olan ölçülere dayanıyor.

---

# TECH / AI / CV STOĞU (aklıma geldikçe biriktir)

gymgyme'ın CV motorundan doğal çıkan tech/yapay zeka/CV konulu reels fikirleri. Z-kuşağı formatı: ilk cümle kanca, kısa, "şu sanılıyor ama aslında bu" çevirmesi. Damla seslendirir. Çekilmeye hazır oldukça yukarı numaralı Reel'e taşınır.

---

## Stok — "AI spor yapamaz, o yüzden nasıl öğreniyor?"

**Hook:** "Bir yapay zekaya squat'ı nasıl öğretirsin? Kendisi spor yapamıyor ki."

**Anlatı (~45 sn):** Kamerası olan bir spor koçu yazıyorum. Ama garip bir duvara çarptım: modeli 'eğitmek' için birinin doğru ve yanlış squat'ı göstermesi lazım. Ben gidip binlerce squat yapamam. AI hiç yapamaz. İnternette milyar spor videosu var diyeceksin — ama hiçbiri etiketli değil: hangisi kaç tekrar, hangisinde bel yanlış, belli değil. Etiketsiz veriyle doğruluğu ÖLÇEMEZSİN. Çözüm şu: az sayıda temiz "altın" klip çekiyorum, sonra onları programla bozuyorum — sol omzu 15 derece düşür, tempoyu hızlandır, bir eklemi kaybet. Tek doğru hareketten yüzlerce etiketli yanlış üretiyorum. AI'nın spor yapmasına gerek yok; ben ona hatayı tarif ediyorum.

**Görsel:** tek temiz iskelet → yanına programla bozulmuş 5 varyant beliriyor; "1 doğru = 500 etiketli test".
**Format:** reel / carousel

---

## Stok — "milyar video var ama işine yaramaz"

**Hook:** "YouTube'da milyar spor videosu var. Yapay zeka eğitmek için hiçbiri işe yaramıyor. İşte sebebi."

**Anlatı (~40 sn):** İçgüdün diyor ki: bu kadar video varken veri sorunu mu olur? Ama bir modelin öğrenmesi için veriye 'cevap anahtarı' lazım — bu klipte 8 tekrar var, bu kişinin dizi içeri kaçıyor. Ham video bunu söylemez. Etiketsiz milyar saat, ölçemediğin için sıfır değerinde. Üstüne telif ve gizlilik: başkasının bedenini iznisiz eğitim verisi yapamazsın. O yüzden büyük veriyi kovalamak yerine küçük ama etiketli veriyi seçtim — akademik mocap setleri (iskelet, video değil) artı kendi çektiğim altın klipler. Az ama doğru, çok ama kör'den iyidir.

**Görsel:** "1.000.000.000 video" üstüne kırmızı çarpı; yanında "212 etiketli iskelet" yeşil tik.
**Format:** reel

---

## Stok — "titreme mi yoksa gerçek hareket mi?" (One Euro filtre)

**Hook:** "Kamera her karede vücudunu titretiyor. Koç bunu 'sen titredin' sanırsa sayacı bozar."

**Anlatı (~45 sn):** Poz tahmini gürültülüdür — el sabit dursa bile ekranda milimetrelerce zıplar. Basit çözüm: yumuşat. Ama fazla yumuşatırsan gerçek hareketin gecikir, koç 'geç' olur. İşte One Euro filtre bu ikilemi çözer: yavaş hareket ederken agresif yumuşatır (titreme gider), hızlı hareket ederken bırakır (gecikme olmaz). Hıza göre kendini ayarlayan bir filtre. Ben bir de üstüne 'kemik kilidi' koydum — uzuv uzunlukların sabit, o yüzden gerçek insan anatomisiyle çelişen her sıçramayı eledim. Sonuç: sayaç titremeden, gecikmeden sayıyor.

**Görsel:** ham zıplayan iskelet vs filtreli akıcı iskelet yan yana; "adapts to your speed".
**Format:** reel

---

## Stok — "gözünü hazır aldım, beynini kendim yazdım"

**Hook:** "Yapay zeka projemin yarısını Google yaptı. Diğer yarısı — asıl kısım — bende."

**Anlatı (~40 sn):** Dürüst olmak gerekirse vücudu görüntüde bulan modeli ben eğitmedim — o Google'ın pose tahmini, milyonlarca görselle eğitilmiş dev bir ağ. Kendi sinir ağımı sıfırdan eğitmek aylar sürer ve o işi zaten birileri benden iyi yapmış. Benim değerim orada değil: o gözün üstüne kurduğum katmanda. Açıyı ölçen, tekrarı sayan, formu yargılayan, 'bu yeterince derin mi' diye karar veren mantık — moat bu. Herkes aynı gözü kullanabilir; farkı yaratan gözün üstündeki ölçülebilir doğruluk. Doğru araç seçmek de mühendisliktir; her şeyi sıfırdan yazmak değil.

**Görsel:** "göz = hazır model" / "beyin = benim motor" iki katman; altında "the moat is the layer on top".
**Format:** reel / carousel

---

## Stok — "%100 arayan koç insanı delirtir" (%60 eşiği)

**Hook:** "Kusursuzluk arayan bir form kontrolü, ilk günde silinir. İşte neden %60'ı hedefledim."

**Anlatı (~40 sn):** İlk motor mantığı acımasızdı: ya kitaptaki gibi ya hiç. Ama insan vücudu kitap değil — nefes alırsın, bir an sallanırsan, kas-yağ oranın kadraja başka düşer. Robot gibi %100 arayan bir koç seni sürekli 'yanlış' der, ve sen uygulamayı silersin. O yüzden bir hata payı koydum: hareket yeterince doğruysa — eşik %60 — tekrar sayılır ve puanını alır. Çöp tekrar (yarım squat) sayılmaz, ama nefes payı olan gerçek bir tekrar cezalandırılmaz. İyi ürün, insanı mükemmelliğe zorlamaz; onu ilerlemeye bırakır.

**Görsel:** slider %100'de "kimse geçemez" kırmızı → %60'da "gerçek insan" yeşil.
**Format:** reel

---

## Stok — "wasm ne ya?" (sıfırdan anlatım, mala öğretir gibi)

**Hook:** "Kodumu C++'la yazıp tarayıcıda çalıştırdım. 'Ama tarayıcı C++ çalıştıramaz' diyorsun. İşte hile."

**Anlatı (~45 sn):** Sana en baştan anlatayım, terim bilmene gerek yok. Tarayıcı normalde tek bir dil bilir: JavaScript. C++ ise bilgisayarların dibindeki, çok hızlı ama tarayıcının anlamadığı bir dil. Peki C++ kodum tarayıcıda nasıl çalışıyor? WebAssembly diye bir şey var — kısaca "wasm". Şöyle düşün: C++'ı, tarayıcının anlayacağı çok basit bir "makine diline" çeviriyorum, tıpkı bir kitabı başka dile çevirir gibi. Tarayıcı bu çeviriyi okuyup çalıştırıyor, hem de neredeyse C++ hızında. Yani ben motoru güçlü dilde yazıyorum, sonra tarayıcının yiyebileceği forma çeviriyorum. Sonuç: web sitesi ama içinde gerçek bir motor var, sunucuya ihtiyaç yok.

**Görsel:** C++ dosyası → "çevirmen (wasm)" kutusu → tarayıcı; altında "senin dilin değil? çevir, çalışsın".
**Format:** reel / carousel

---

## Stok — "pose estimation nedir?" (sıfırdan anlatım)

**Hook:** "Kamera seni sadece renkli noktalar olarak görür. Peki nasıl 'bu senin dizin' diyor?"

**Anlatı (~40 sn):** Terim korkutmasın: 'pose estimation' demek, bir görüntüde insan vücudunun eklemlerini bulmak demek. Kamera aslında hiçbir şey 'anlamaz' — onun için sen sadece milyonlarca renkli noktasın. Ama Google gibi şirketler, milyonlarca fotoğrafı 'işte burnu, işte dizi, işte omzu' diye elle işaretleyip bir modele göstermiş. Model o kadar örnek görünce artık yeni bir görüntüde de eklemleri tahmin edebiliyor — bu yüzden adı 'estimation', yani tahmin. Bana 33 nokta veriyor: iki omuz, iki dirsek, iki diz... Ben de bu noktalardan açı hesaplıyorum. Squat'ta diz açısı küçülür, işte tekrarı oradan sayıyorum. Sihir değil, geometri.

**Görsel:** fotoğraf → üstüne 33 nokta beliriyor → diz açısı çiziliyor; "kamera görmez, model tahmin eder".
**Format:** reel

---

## Stok — "on-device ne demek, neden önemli?" (gizlilik, sıfırdan)

**Hook:** "Uygulamaların çoğu kameranı buluta yollar. Benimki telefonundan çıkmıyor. Farkı anlatayım."

**Anlatı (~40 sn):** İki yol var. Birincisi: kamera görüntün internetten bir sunucuya gider, orada işlenir, cevap geri gelir — buna 'bulutta işleme' denir. Hızlı kurulur ama en özel verin (vücudun) bir yerlere gitmiş olur. İkincisi: bütün hesap senin cihazının içinde yapılır, hiçbir şey dışarı çıkmaz — buna 'on-device', yani cihaz-üstü işleme denir. Ben ikincisini seçtim. Motor senin tarayıcının içinde çalışıyor, kamera görüntün tek bir kere bile telefonundan ayrılmıyor. Bunu yapması daha zor çünkü her şeyi küçük bir cihaza sığdırman lazım — ama gizlilik pazarlık konusu değil. KVKK, GDPR gibi yasaların da istediği tam bu.

**Görsel:** iki ok: "bulut = veri dışarı" kırmızı / "cihaz-üstü = veri içeride" yeşil.
**Format:** reel / carousel

---

## Stok — "false positive ne?" (koçun yanlış sayması, sıfırdan)

**Hook:** "Koç, sen hiç squat yapmadan sayı arttırıyordu. Buna 'false positive' denir."

**Anlatı (~35 sn):** Terimi açayım: 'false positive' — yani 'yanlış alarm'. Motor bir tekrar OLMADIĞI halde 'oldu' derse buna false positive denir. Bir doktor testinin, hasta olmadığın halde 'hastasın' demesi gibi. Benim koçumda bu şöyle oluyordu: masada otururken bile ufak bir hareket squat sanılıp sayılabiliyordu. Bunu ölçmek için bir 'skor tablosu' tutuyorum: motor bilerek yanlış hareketlere bakıyor ve kaç kere yanlış alarm verdiğini sayıyorum. Sonra eşikleri sıkılaştırıp o sayıyı düşürüyorum. İyi bir koç, saymadığı zaman da güvenilirdir — yani yanlış saymadığında.

**Görsel:** oturan kişi → sayaç yanlışlıkla artıyor → kırmızı "false positive"; eşik sıkılaşınca sayaç sabit.
**Format:** reel

---

## Stok — "benchmark neden her şeyin anası?" (ölçüm kültürü, sıfırdan)

**Hook:** "'Motorum iyi çalışıyor' demek bir şey ifade etmez. Sayı vermezsen inanma — bana bile."

**Anlatı (~40 sn):** Mühendislikte en tehlikeli cümle 'bence iyi oldu'dur. Hisse göre karar veremezsin çünkü his yanıltır. O yüzden 'benchmark' diye bir şey var: elinde cevabı belli bir test seti tutarsın, sistemini ondan geçirirsin, ve tek bir sayı çıkar — mesela 'squat tekrarını %96 doğru saydı'. Bir şeyi değiştirdiğinde bu sayı yükseldi mi düştü mü, görürsün. Bu yüzden bu projede her büyük değişikliğin bir benchmark tablosu var. Reklam değil bu — bu, 'işe yarıyor' demenin tek dürüst yolu. Bir şeyin doğru olduğunu ölçemiyorsan, aslında bilmiyorsun demektir.

**Görsel:** "bence iyi" kırmızı çarpı → "%96 doğruluk" yeşil tik; altında "ölçemezsen bilmiyorsun".
**Format:** reel / carousel

---

## Reel — bilgi vardı ama afişin altında kaybolmuştu (loop 01)

**Hook (ilk 2 sn):** "Sitemde her şey yazıyordu. Yine de kimse ne işe yaradığını anlamıyordu. Sorun bilgi değildi."

**Anlatı (~35 sn):** gymgyme'ın ana sayfasını bir sinema afişi gibi kurmuştum — "starring you", "admit one, price: a few squats". Sevdim, hâlâ da duruyor. Ama bir arkadaşım girip "bu tam olarak ne yapıyor?" dedi. Halbuki sayfa anlatıyordu: kameran seni sayar, puanlar... Ama o cümle afiş süslemesinin altında, üçüncü satırdaydı. İnsan bir sayfaya 2 saniye bakar. O 2 saniyede süsleme değil, SONUÇ görmeli. Tek bir şey yaptım: başlığın hemen altına, süssüz, çıplak bir cümle koydum — "kameran repini sayar, formunu 100 üzerinden puanlar ve düzeltir; canlı, cihazında, ücretsiz." Afişi silmedim, sadece önüne net bir çapa attım. Bilgiyi yaratmak değildi iş; onu görünür yere taşımaktı.

**Görsel:** afiş süslemesi bulanık → ortada net değer cümlesi keskinleşiyor; "the info was there, just buried".
**Format:** reel
