# LOOP 08 — DOĞRULUK LOOP'U (otonom, ölçülebilir, regresyonlu)

STATUS: TODO
GRUP: C (motor gerçekten öğrensin)
BAĞIMLILIK: 07 bittikten sonra.

## SORUN ("AI spor yapamaz" paradoksu)
Claude gidip squat yapıp "sol omzum düştü, filtreyi düzelteyim" diyemez.
Ama parametre TARAYABİLİR — golden/etiketli set üstünde ölçüp maksimize ederek.
Bu, motorun gerçekten işe yaradığını KANITLAYAN katman.

## HEDEF
- bench.cpp: golden + açık set + sentetik bozulmuş klipleri motordan geçirir.
- SENTETİK genişletme (AI'nın spor yapmasına gerek yok): golden iskeletlere programatik bozma
  (gürültü, bir eklemi kaydır=sol omuz 15° düşür, tempo değiştir, occlusion=nokta düşür) → yüzlerce ETİKETLİ vaka.
- Çıktı: doğruluk TABLOSU → rep-doğruluk %, form-tespit precision/recall, gecikme ms. Hareket başına.
- PARAMETRE TARAMASI: kRepAcceptPct, One Euro beta/mincutoff, form-ihlal açı eşikleri → tabloyu maksimize et.
- Tablo REPOYA girer → sonraki her motor değişikliği regresyonu görünür kılar.

## LOOP (tıkır tıkır büyüten çember)
1. golden/set klip → 2. sentetik varyant üret (etiketli) → 3. bench geçir → tablo →
4. parametre tara, maksimize → 5. eşik+kural MoveSpec'e → (06'ya besleme) → 6. tablo repoda, regresyon görünür.

## SINIRLAR (yasak)
- 104+ birim test (fonksiyon doğruluğu) AYRI kalır, dokunulmaz. Bench = uçtan-uca AYRI katman.
- İddia yok: "motor iyi" demek yerine TABLO göster (squat rep %96, false-pos 2, sol-omuz recall %88).
- Sentetik bozma gerçekçi olmalı (uydurma değil, gerçek hata modları).

## DONE ÖLÇÜTÜ
- [ ] bench.cpp sentetik + golden + açık set üstünde tablo üretiyor.
- [ ] Parametre taraması bir metriği ölçülebilir iyileştirdi (önce/sonra tablo kanıt).
- [ ] Tablo repoda, regresyon için sabit.
- [ ] Damla tabloyu gördü, "artık kanıtlı" onayı.

## KAPANIŞTA
- STATUS: DONE. GRUP C BİTTİ → motor ölçülebilir güvenilir.
- 8 loop tamam → gymgyme premium his + güvenilir motor + kanıtlı doğruluk.
- Büyük özet raporu reports/ altına.

## LOOP GÜNLÜĞÜ
- (henüz başlamadı)
