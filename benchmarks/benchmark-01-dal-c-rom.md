# benchmark-01 / dal C — ROM sıkışması: gerçek veride motor görmüyor

STATUS: IN PROGRESS (opus agent'ta)
ANA LOOP: benchmark-01-algilama.md
KAYNAK: loop 04 mmfit ucu (16 Tem) — gerçek veri motoru İLK KEZ yeniden üretilebilir şekilde düşürdü.

## SORUN
MM-Fit gerçek squat: etiket 10 rep, motor 0. Sentetik squat: 8/8. Teşhis: monoküler lifting gürültüsü + projeksiyon ROM'u sıkıştırıyor (diz açısı 92°-120° bandında kalıyor, ~160° "top" eşiği hiç tutmuyor) → top→bottom→top döngüsü başlamıyor → SESSİZ SIFIR. Pushup hep half, lunge yarı sayıyor — aynı kök. Damla'nın "kamera hareket algılamıyor / beni roblox gibi görüyor" şikayetiyle büyük ihtimalle aynı aile: gerçek dünya iskeleti sentetik kadar temiz değil, eşikler mutlak açıya çakılı.

## HEDEF
Motor mutlak açı eşiğine değil, KİŞİNİN O SEANSTA GÖSTERDİĞİ harekete göre faz görsün. MM-Fit squat ≥8/10 sayarken sentetik 8/8 KALIR, 204 test yeşil KALIR.

## DONE
- bench tablosunda mmfit squat/pushup/lunge motor sayıları etikete yaklaşır (squat ≥8/10)
- sentetik regresyon bozulmaz, 204+ test yeşil
- değişiklik açıklanabilir: motor neyi neden kabul ettiğini söyleyebilir
