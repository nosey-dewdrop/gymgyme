# LOOP 04 — %60 KABUL KAPISI (rep sadece yeterince iyiyse sayılsın)

STATUS: TODO
GRUP: B (sonuç güvenilir mi)
BAĞIMLILIK: GRUP A bittikten sonra.

## SORUN (kanıt: coach_engine.cpp:1221)
Şu an rep, SADECE açı penceresi kapanınca (topTh→bottomTh→topTh) sayılıyor —
skordan BAĞIMSIZ. Skoru %20 de olsa sayılıyor, %95 de olsa. "accuracy ≥ %60 olunca say"
diye bir kapı MOTORDA YOK. Robot gibi %100 aramamalı ama çöp rep'i de saymamalı.

## KRİTİK AYRIM (karıştırma)
- FİLTRE toleransı (nefes/titreme/sarsıntı) = ZATEN var (One Euro + Kalman). Bu ayrı katman.
- KABUL eşiği (%60 "yeterince iyi rep") = YENİ eklenecek. Bu ayrı katman.
- Mimari: Filtre → Rep pencere → **%60 KAPISI (yeni)** → 0-100 skor.

## HEDEF
- `kRepAcceptPct` MoveSpec'e (hareket başına ayarlanabilir; plank≠squat).
- Rep tamamlandığında lastScore_ zaten hesaplı → `if (lastScore_ >= kRepAcceptPct) reps_++`.
  Altındaysa: yarım-rep / "biraz daha derine" uyarısı, SAYMA.
- Default eşik 60; her hareket kendi eşiğini MoveSpec'ten alır.

## SINIRLAR (yasak)
- 104+ yerel test BOZULMAZ. Yeni testler eklenir (eşik altı sayılmaz, üstü sayılır).
- One Euro/Kalman kalbine dokunma.

## DONE ÖLÇÜTÜ
- [ ] kRepAcceptPct MoveSpec'te, motor rep'i eşiğe göre sayıyor.
- [ ] Yeni birim testler yeşil, eski 104+ hâlâ yeşil (test.sh çıktısı kanıt).
- [ ] Damla kamerada: çöp rep sayılmıyor, düzgün rep sayılıyor.

## KAPANIŞTA
- STATUS: DONE, README kutusu. Kapanış ritüeli: README.md (devlog her zaman; büyük rework ise +rapor+linkedin).
- Yeni sekme → benchmark-05-scorebadge.md.

## LOOP GÜNLÜĞÜ
- (henüz başlamadı)
