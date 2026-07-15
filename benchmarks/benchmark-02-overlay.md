# LOOP 02 — OVERLAY (ham iskelet → premium renk-kodlu his)

STATUS: TODO
GRUP: A (görünür değer)
BAĞIMLILIK: 01 bittikten sonra.

## SORUN
Müşteriye ham iskelet çizgisi gösteriliyor = mühendis dili, "CS ödevi" hissi.
Müşteri "formumu düzeltiyor" hissini iskeletten almaz; DÜZELTMENİN KENDİSİNDEN alır.

## HEDEF
- Ham iskelet çizgisi → yumuşak renk-kodlu overlay:
  - eklem = dolu yumuşak düğüm, aralar ince yarı-saydam bağ (çizgi-spagetti değil).
  - renk = durum: doğru eklem NANE/yeşil, düzeltilecek eklem VİŞNE pulse.
  - aktif kas bölgesi hafif hale (canvas radial gradient, shader YOK, ucuz) → "seni okuyorum / CGI" hissi.
- Premium akıcılık: One Euro zaten jitter'ı emiyor, overlay de akıcı çizilir.

## SINIRLAR (yasak)
- 468-nokta yüz mesh geri GELMEZ ("travesti" hissi, MESH_FACE_HANDS=false kalır).
- AI slop, neon, mor, gereksiz parçacık → YOK. Premium = sade + anlamlı.
- KÖR ÜRETME: önce Damla referans (görüntü/çizim) verir YA DA tek ekranda birlikte iterasyon (mib dersi: 9 tur kör = slop). Bu loop referanssız BAŞLAMAZ.

## DONE ÖLÇÜTÜ
- [ ] Yeni overlay canlı, doğru/yanlış renk kodu çalışıyor.
- [ ] Damla "premium, çirkin değil" onayı verdi.
- [ ] Kamera akıcı (jitter yok), fps düşmedi.
- [ ] Damla tarayıcıda gördü (render kanıtı).

## KAPANIŞTA
- STATUS: DONE, README kutusu. Kapanış ritüeli: README.md (devlog her zaman; büyük rework ise +rapor+linkedin).
- Yeni sekme → benchmark-03-declutter.md.

## LOOP GÜNLÜĞÜ
- (henüz başlamadı)
