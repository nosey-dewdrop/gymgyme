# LOOP 02 — OVERLAY (ham iskelet → premium renk-kodlu his)

STATUS: IN PROGRESS
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
- 15 tem: kör başlamadı — Damla referans verdi. Önce iki prototip yan yana (A kutu / B düğüm)
  çip'le canlıda gösterildi → ikisi de kötü (kutular uzvu sarmıyordu, düğüm spagetti).
- Damla referansı: "sabah bir html vardı, kutular vişne, ince ve zarif." Bulundu: commit dd85ef2
  ("real CV-engine look: labeled detection boxes per body part"). O köşe-işaretli vişne
  bounding-box overlay'i geri getirildi + LOOP 02 renk-kodu eklendi (izlenen eklem: form
  iyi=nane, düzelt=vişne pulse). Yüz mesh yok. A/B çip kaldırıldı, tek overlay.
- Kamera testi (Damla, 22:37): kutu tuttu AMA iki bug: (1) etiket yazıları ayna-ters
  ("good"→"boog"), (2) parça etiketleri üst üste biniyor = kare kare kirli.
- Çözüm (Damla kararı: "küçük tek etiket"): parça adları + güven % kaldırıldı. Sadece izlenen
  parçaya küçük "good/fix" rozeti, ctx.scale(-1,1) ile ayna-geri (düz okunur). Çakışma bitti.
- AÇIK: son sürüm YERELDE hazır, Damla kamerada henüz onaylamadı. Vercel deploy limiti dolu →
  CANLIDA DEĞİL. DONE değil. Sonraki oturum: limit açılınca push, Damla kamerada "premium,
  çirkin değil" onayı → DONE. drawBody (mesh.js) artık render'da kullanılmıyor (import duruyor).
