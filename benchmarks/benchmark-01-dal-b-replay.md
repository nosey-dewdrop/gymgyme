# benchmark-01 / dal B — replay yolu uçtan uca kanıt

STATUS: IN PROGRESS (agent'ta)
ANA LOOP: benchmark-01-algilama.md

## SORUN
Teşhis Damla'nın .ggclip kaydına muhtaç; kayıt geldiğinde tek komutla motora geri beslenebildiği HİÇ kanıtlanmadı. Kayıt gelmeden yol test edilmeli.

## İŞ
1. .ggclip formatını koddan çıkar (js/coach.js recFrame) ve belgele
2. sentetik bir squat .ggclip üret (motorun kendi sentetik test verisinden türet)
3. engine/bench.sh clip <dosya> uçtan uca ÇALIŞTIR, metrik tablosunu göster; kırıksa minimum düzelt
4. engine/test.sh yeşil kalır (104+)

## DONE
- Tek komut + gerçek çıktı tablosu kanıtı; Damla'nın klibi geldiği gün sıfır hazırlık gerekmez.

## SONUÇ (16 Tem, agent — commit'lenmedi, Damla onayı bekliyor)
- Format uyumlu: kaydedici (js/coach.js recFrame) `ggclip 1 <move>` + satır başına `t 33x(x y z v) [33x(x y z v) | -]`, bench.cpp runClip aynısını okuyor. Düzeltme gerekmedi. Not: kaydedici ekran x'ini aspect ile çarpıyor — motor JS tarafında da aynı ölçekle besleniyor, tutarlı.
- Sentetik klip: bench.cpp'ye `makeclip` modu eklendi (motorun kendi makeSynth'i, normal kamera gürültüsü, 8 gerçek tekrar) → `bash engine/bench.sh makeclip /tmp/synth-squat.ggclip` (960 kare, 32 sn).
- Uçtan uca: `bash engine/bench.sh clip /tmp/synth-squat.ggclip` →
  ema      hf-jitter 2.222 deg/kare  reps 8  half 0  dropouts 0
  one euro hf-jitter 1.967 deg/kare  reps 8  half 0  dropouts 0
  kemik varyansı (ham dünya): uyluk 2.65% baldır 2.97% üst kol 4.32%
- "-" (dünya verisi yok) dalı da test edildi: reps 8, dropouts 0, kemik varyansı -1 (beklenen).
- engine/test.sh: 191 ok, 0 fail.
- Damla'nın klibi gelince: dosyayı indir, `bash engine/bench.sh clip <dosya>.ggclip` — başka hazırlık yok.
