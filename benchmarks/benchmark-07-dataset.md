# LOOP 07 — VERİ SETİ (motor neyle öğrenecek/doğrulanacak)

STATUS: TODO
GRUP: C (motor gerçekten öğrensin)
BAĞIMLILIK: 06 bittikten sonra.

## SORU (Damla: "internette milyar spor videosu var, öyle mi eğiticez?")
CEVAP (araştırma kanıtlı): internetteki milyar video ETİKETSİZ (kaç rep / hangi form hatası belli değil),
telif+KVKK riskli, gigabaytlarca disk. Doğruluğu ÖLÇEMEZSİN → işe yaramaz.
Tek başına yeten açık set YOK. Ama etiketli + telif-temiz + indirilebilir 3 set var.

## KAYNAKLAR (araştırma raporu: reports/2026-07-15-gymgyme-vizyon-motor-teshis.md + agent bulgusu)
1. **REHAB24-6** (Zenodo, CC-BY-NC, 5.7GB): 2D/3D iskelet + rep segmenti + doğru/yanlış form. squat/lunge.
2. **EC3D** (~300MB): 3D iskelet + form-hatası etiketli. squat/lunge/plank.
3. **MM-Fit** (MIT): iskelet + rep-count, 10 hareket (squat/pushup/situp/jumping jack...).
   → hepsi İSKELET (video değil) veya iskelete dönüştürülür; disk makul, telif temiz.

## HEDEF
- Setleri indir, motorun MediaPipe-33 formatına DÖNÜŞTÜR (iskelet JSON zaman serisi).
- Her klip için ground-truth etiket tut: beklenen rep sayısı + form hataları.
- engine/dataset/ altında düzenli sakla. **Ham veri gitignore** (repo şişmesin, sadece dönüştürülmüş özet + golden).
- KAPSAMA BOŞLUĞU: açık setlerde olmayan hareketler (mountain climber, russian twist, high knees...)
  → Damla golden klip çeker (video değil, iskelet JSON kaydedilir, ~50KB, kimse tanınmaz, KVKK temiz).

## SINIRLAR (yasak)
- Ham video repoya GİRMEZ (disk). Sadece iskelet + etiket.
- Uydurma etiket YOK — her etiket ya set'ten gelir ya Damla golden çekiminden.
- Lisans: CC-BY-NC ticari değil ama gymgyme para hedefi yok → uygun. Kaynak künyesi dosyada.

## DONE ÖLÇÜTÜ
- [ ] En az REHAB24-6 + EC3D indirildi, iskelet JSON'a dönüştü.
- [ ] Ground-truth etiket tablosu var.
- [ ] Kapsama boşluğu listesi (Damla'nın çekeceği hareketler) net.
- [ ] Disk şişmedi (ham veri gitignore).

## KAPANIŞTA
- STATUS: DONE, README kutusu. Kapanış ritüeli: README.md (devlog her zaman; büyük rework ise +rapor+linkedin).
- Yeni sekme → benchmark-08-bench.md.

## LOOP GÜNLÜĞÜ
- (henüz başlamadı)
