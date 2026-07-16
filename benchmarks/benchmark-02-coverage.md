# LOOP 06 — KAPSAMA (tüm ev hareketlerini koçla, 14 değil)

STATUS: TODO
GRUP: C (motor gerçekten öğrensin)
BAĞIMLILIK: GRUP B bittikten sonra.

## SORUN (kanıt: data/moves-db.js + js/coach.js MOVES)
MOVE_DB'de 386 hareket listeleniyor ama motorun gerçek form kuralı olan ~5 (MOVES objesi).
Kullanıcı 386 görüyor, 5'i koçlanıyor = BAIT-AND-SWITCH.
Damla: "buraya bütün ev hareketlerini kaydedeceğiz, hepsini öğrenmesi lazım. 14 değil."

## HEDEF
- Koçlanabilir HER hareketin MoveSpec form kuralı olsun:
  - REP-based: squat/pushup/lunge/crunch/raise/twist/climber türevleri (izlenen eklem, açı bandı, tempo, form ihlal kuralları).
  - HOLD-based: plank/side plank/wall sit/hollow hold türevleri (süre + form kapısı).
- STRETCH/YOGA (child's pose, cobra, cat stretch, tüm "stretch"ler): rep yok → dürüstçe "reference" etiketi. Koçlanıyormuş gibi GÖSTERİLMEZ.
- moves listesinde her hareket net etiket taşır: "counts reps" / "coached hold" / "reference".

## YÖNTEM (kör eklememek için)
- Hareketleri gruplara böl (squat-ailesi, pushup-ailesi, lunge-ailesi, crunch-ailesi, raise-ailesi, bridge-ailesi, plank-ailesi...).
- Her aile için 1 base MoveSpec + varyant parametreleri (dip açısı, izlenen eklem farkı).
- Aile bazlı ilerle, her aile kapanınca test.

## SINIRLAR (yasak)
- Uydurma kural YOK — hareketin gerçek biomekaniği neyse o (kaynaklı, anatomik).
- 104+ test bozulmaz; her aile için yeni test.
- Kapsamı bir oturumda bitirmeye çalışma — aile aile, her aile mini-milestone.

## DONE ÖLÇÜTÜ
- [ ] Tüm rep+hold aileleri MoveSpec kurallı, motor sayıp puanlıyor.
- [ ] Stretch'ler "reference" (yanlış vaat yok).
- [ ] moves listesi her harekette doğru etiket gösteriyor.
- [ ] Her aile için testler yeşil.

## KAPANIŞTA
- STATUS: DONE, README kutusu. Kapanış ritüeli: README.md (devlog her zaman; büyük rework ise +rapor+linkedin).
- Yeni sekme → benchmark-07-dataset.md.

## LOOP GÜNLÜĞÜ
- (henüz başlamadı)
