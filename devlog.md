# devlog — gymgyme koç, build in public

IG için hook'lu 30-60 sn reel scriptleri. İlk cümle KANCA. Damla seslendirir. Kaynak: BUILD-LOG.md. Sınır yok, biriktirilecek.

---

## FORMAT + KONU BÖLÜMLERİ

MARKA NOTU: Damla sadece "tech konuşan" bir marka değil. İçerik tech'in yanında SOSYOLOJİ, HAYAT, PSİKOLOJİ, MARKETING de taşır — insanlar insana bağlanır, sadece koda değil. Tek boyutlu mühendis markası KURMA.

Bu dosyada iki template var: (A) REELS — tek format, ama farklı KONU bölümlerinde birikir. (B) TECH DEVİNİM — teknik günlük, sosyal medya değil.
NOT: reels malzemesini ne zaman düşüreceğine CLAUDE karar verir (Damla'ya sormaz) — aklına uygun bir an/konu geldiğinde ilgili konu bölümüne atar. Sınır yok.

### TEMPLATE A — REELS (tek format · Damla seslendirir · farklı konu bölümleri)

Reels TEK formattır. Bu dosyada (PROJE devlog'u) sadece PROJEYE ÖZEL iki bölüm var:
- **build-in-public** — o loop/sistemde ne yaptım, gymgyme'ın inşa anları.
- **tech sohbetleri** — bu projeden doğan teknoloji açıklaması (wasm, pose estimation, on-device...).

PROJEYE BAĞSIZ konular (sosyoloji / hayat / psikoloji / genel tech görüşü) BURAYA DEĞİL → merkezi `~/damla_projects_2026/damla-icerik.md` dosyasına yazılır. Her proje aynı genel konuyu tekrar tutmasın diye. (Ama o merkezi konular projelerin ALANINDAN beslenir — gymgyme=fitness/sağlık → "insan neden antrenmanı bırakır" gibi.)

Format:

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

STOK KONU FİKİRLERİ (Claude aklına geldikçe ilgili bölüme yazar):
- tech sohbetleri: AI'yla kod yazmak (asistan mı çoğaltıcı mı) · slop uygulama nasıl anlaşılır (backend yok, hepsi localStorage, aynı gradient, yarım CRUD, "coming soon"lar) · vibecoding nerede duvara çarpar · AI kodu yazınca senin işin ne kalıyor (karar/mimari/ölçüm).
- sosyoloji: insanlar hangi ürüne bağlanır neden · "herkes yapıyor" baskısı · dijital utanç/gösteriş.
- hayat: CS öğrencisi + gerçek ürün build etmek nasıl · gece 3'te bug · üretmenin ruh haline etkisi.
- psikoloji: insan neden yarım bırakır · "sonuç görmek" motivasyonu · ürün insanı nasıl iyi/kötü hissettirir.
- (marketing vb. — sınır yok, yeni başlık aç)

---

# ═══ BÖLÜM: BUILD-IN-PUBLIC ═══

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

# ═══ BÖLÜM: TECH SOHBETLERİ ═══

Teknoloji/yapay zeka/CV üzerine reel fikirleri. Kanca + "şu sanılıyor ama aslında bu". Damla seslendirir (TR) + EN text-on-video.

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

---

## Reel — üç kere çirkin overlay yaptım, dördüncüsü kendi eski kodumdu (loop 02)

**Hook (ilk 2 sn):** "Aynı ekranı dört kere yaptım. En güzeli benim iki gün önce sildiğim versiyondu."

**Anlatı (~40 sn):** kamera seni izlerken üstüne bir "overlay" çizilir — vücudunun neresine baktığını gösteren çizgiler. İlk hali ham iskelet çizgisiydi, "CS ödevi" gibi. Yeniledim: dönük dikdörtgenler → uzuvları sarmadı, kırık tel kafesi çıktı. Bir tane daha: parlayan düğümler → spagetti oldu. Damla ikisine de "çok çirkin" dedi, haklıydı. Sonra dedi ki "sabah bir versiyon vardı, kutular vişne renginde, ince ve zariftti — onu bulabilir misin?" Git geçmişine daldım, iki gün önce yazıp sonra "sadeleştirmek" için sildiğim bir commit vardı: her vücut parçasını köşe-çentikli ince bir kutuyla saran, gerçek CV motoru hissi veren bir overlay. Onu geri getirdim, üstüne şunu ekledim: izlediğin eklem — mesela kol kaldırınca kolun — formun doğruysa nane yeşili "good", düzeltmen gerekiyorsa vişne "fix" diye yanıp söner. Bir bug daha: yazılar ayna görüntüsünde ters okunuyordu ("good" → "boog"). Metni ayna-geri çevirdim. Ders: her yeni fikir daha iyi değil. Bazen en iyi tasarım, senin bir hafta önce beğenmeyip sildiğin şeydir.

**Görsel:** dört overlay yan yana (kafes → spagetti → kirli kutu → temiz vişne kutu + "good/fix" rozeti); "the winner was in my git history".
**Format:** reel

---

## Reel — iki iOS uygulaması gömdüm, fikir web'de dirildi

**Hook (ilk 2 sn):** "Bu proje aslında bir iPhone uygulamasıydı. İki tane yaptım, ikisi de öldü."

**Anlatı (~45 sn):** gymgyme diye başlayan şeyin ilk hali native bir iOS app'ti. Sonra bir v2 daha yaptım. İkisi de mezara gitti. Ama itiraf edeyim: sorun fikir değildi — araştırma sağlamdı, evde antrenman + kadın topluluğu + kaçan günü cezalandırmayan tasarım, böyle bir şey piyasada yoktu. Sorun benim onu taşıdığım kaptı. Native app kurmak, App Store review'u, güncelleme döngüsü — hepsi ben fikri daha kanıtlamadan üstüme binen ağırlıktı. O yüzden platformu değiştirdim, aynı fikri web'e taşıdım. Web'de bir fikri yayınlamak bir push, bir canlı link. Yanlışsam saatler içinde öğreniyorum, aylar değil. Bir fikri gömmek fikrin ölümü değil — iki app öldü ama tez yaşadı. Yanlış olan tez değildi, onu kanıtlamak için seçtiğim en ağır yoldu.

**EN (text-on-video):** "this started as an iOS app. / i buried two of them. / the idea wasn't wrong. / the platform was too heavy to test it. / i moved it to the web. / one push, one live link. / burying an app isn't burying the idea."

**Format:** reel

---

## Reel — sitem güzeldi ama ne yaptığı belli değildi

**Hook (ilk 2 sn):** "Ana sayfamı bir sinema afişine çevirdim. Herkes 'güzel' dedi. Kimse ne işe yaradığını anlamadı."

**Anlatı (~45 sn):** Site teknik olarak hazırdı ama ruhsuzdu — beyaz kartlar, standart yerleşim, başka bir web app. O yüzden büyük bir redesign yaptım: siteyi ışıklı bir sinema tabelası dünyasına taşıdım. "Starring you", "admit one", program bir tiyatro fişi, takvim katkı grafiği gibi boyanan bir residency. His olarak bayıldım. Ama bir arkadaşım girip "bu tam olarak ne yapıyor?" dedi ve haklıydı. Bütün o afiş süslemesi değer cümlesini gömmüştü — "kameran seni sayar, puanlar" cümlesi üçüncü satırda, süsün altında kaybolmuştu. İnsan bir sayfaya iki saniye bakar; o iki saniyede süs değil sonuç görmeli. Afişi silmedim, o siteye ruhunu veriyordu. Sadece başlığın altına çıplak bir cümle koydum. Ders: whimsy ve netlik rakip değil ama sırası var — önce anlaşıl, sonra unutulmaz ol.

**EN (text-on-video):** "i turned my homepage into a cinema poster. / everyone said 'pretty'. / nobody knew what it did. / the decoration buried the value line. / people look for 2 seconds. / they need the result, not the sparkle. / kept the world. added one bare sentence."

**Format:** reel

---

## Reel — arkadan biri geçince koç yabancıyı çalıştırıyordu

**Hook (ilk 2 sn):** "Odaya ikinci biri girince koç seni bırakıp onu saymaya başlıyordu."

**Anlatı (~45 sn):** Motor tek kişi için düzgündü. Sonra gerçek senaryo geldi: odada iki kişi, ya da arkada biri geçiyor. Kamera kareyi görüyor ama 'hangi iskelet antrenmanı yapan kişi?' bilmiyor. Yanlış kişiyi seçince senin yerine arkadaki adamın hareketini sayıyor. Komik ama ürünü çöpe atan bir hata. İlk çözüm 'en büyük gövdeyi seç'ti — kırılgan, çünkü açıya göre yabancı daha büyük görünebilir. O yüzden kimliği kalibrasyona bağladım: ilk saniyelerde senin kemik oranlarını kilitliyorum, her karede adayları o oranla kıyaslıyorum, en iyi eşleşen sensin. Sonra bir 'hard lock' ekledim — oranı hiç tutmayan yabancı tamamen veto edilir, yalnız bir yabancı asla koçlanmaz. Bunu bir iskeleti sahnede zıplatıp motorun onu reddettiğini ölçerek kanıtladım: sıfır yanlış kare. Ders: gerçek dünya tek kullanıcılı bir laboratuvar değil.

**EN (text-on-video):** "someone walks behind you. / the coach starts counting THEM. / 'pick the biggest body' was fragile. / so i locked identity to your calibration. / your bone ratios are your fingerprint. / a lone stranger is never coached. / 0 wrong frames."

**Format:** reel

---

## Reel — motoru bir gecede büyüttüm, sabah kötüydü

**Hook (ilk 2 sn):** "Bir gecede motora 2000 satır ekledim. 191 test geçti. Sabah açtım, berbattı."

**Anlatı (~50 sn):** Bir gece boyunca motoru 2837'den 4700 satıra çıkardım. One Euro filtre, Kalman, IK limitleri, simetri analizi, hareket sınıflandırıcı — 191 test, hepsi yeşil. Mühendislik olarak gurur gecesiydi. Sonra sabah telefonu açıp kamerayı çalıştırdım. Ürün kötüydü. Görsel çirkin, yerleşim bozuk, ve kolumu kaldırınca saymıyordu. İçeride 4700 satır zeka, dışarıda işe yaramayan bir ekran. En net dersim buydu ve canımı yaktı: motoru büyütmek işe yarar ürün yapmaz, ikisi farklı eksen. 191 testin hiçbiri 'açtım, kolumu kaldırdım, saydı mı, tekrar açar mıyım' sorusunu ölçmüyordu. Yeşil testler mühendisi rahatlatır, müşteriyi değil. O yüzden yönü değiştirdim — müşteri gözü döngüsü, 'bu işime yarıyor mu' diyen sıradan insan gözü. Motorun doğruluğu ürünün değeri değil, sadece bir parçası.

**EN (text-on-video):** "i added 2000 lines to the engine overnight. / 191 tests, all green. / opened the camera in the morning. / it was bad. / raised my arm — it didn't count. / a smarter engine is not a better product. / green tests calm the engineer, not the user."

**Format:** reel

---

## Reel — link listesinden gerçek bir motora

**Hook (ilk 2 sn):** "İlk hali sadece güzel bir liste sitesiydi. Onu gerçek yapan şey sonra geldi."

**Anlatı (~40 sn):** Web'e taşıdığımda gymgyme önce bir topluluk diziniydi: pembe, kenarsız, evde yapılan hareketlerin kaynaklı bir listesi. Üstüne bir 'bana program yap' üreteci koydum — saf formül, zaman bütçesi, kas dengesi. Backend bile yoktu, öneriler mailto ile gidiyordu, veri localStorage'da. Bilinçliydi: bir aracın işe yarayıp yaramadığını sunucu maliyeti almadan öğrenmek istedim. Ama dürüst olayım, o dizin hâlâ biraz slop kokuyordu — güzel bir liste, ama 'başka bir statik site' hissi. Onu gerçek ürün yapan şey kamera motoruydu: bir link listesi herkesin yapabileceği şeydi, kameranla squat'ını sayan bir motor değildi. Pivotun asıl anlamı buydu — önce hafifle, sonra derinleş.

**EN (text-on-video):** "it started as a pretty link directory. / then a formula-based program generator. / no backend, mailto suggestions, localStorage. / but it still smelled like slop. / a list is something anyone can build. / a camera engine that counts your squat is not. / get light first. then go deep."

**Format:** reel
