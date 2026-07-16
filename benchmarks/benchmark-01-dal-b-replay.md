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
