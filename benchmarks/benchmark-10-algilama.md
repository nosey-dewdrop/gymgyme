# benchmark-10-algilama — kamera hareketi GERÇEKTEN görsün (L4)

STATUS: TODO
KATMAN: L4 (motor)
KAYNAK: Damla, 16 Tem: "kamera hareketleri görmüyo, hareket algılamıyo". 15 Tem sabahı da aynı şikayet vardı (kol kalktı, saymadı). Bu ürünün BİR NUMARALI kusuru — bu kapanmadan hiçbir cila loop'u öne geçemez.

## SORUN
Damla kamerada hareket yapıyor, motor görmüyor / rep saymıyor. Bu tek bir bug değil, bir zincir; kopuk halka bilinmiyor:
1. landmark üretimi (mediapipe kare başına iskelet veriyor mu, fps kaç)
2. iskelet → motor köprüsü (js/coach.js wasm'a doğru formatta besliyor mu)
3. faz tespiti (motor up/down fazlarını görüyor mu, eşikler gerçek insan için doğru mu)
4. hareket eşleşmesi (yapılan hareket seçili MoveSpec ile eşleşiyor mu, yanlış hareket seçiliyken sessizce sıfır mı)
5. sayaç/skor çıkışı (motor saydı ama UI göstermiyor olabilir)

## HEDEF
Damla'nın kamerada yaptığı hareket, mevcut kurallı hareketlerin HEPSİNDE güvenilir sayılır. "Bazen sayıyor" yok.

## ADIMLAR
1. TEŞHİS ÖNCE: zincirin her halkasına gözlemlenebilir çıktı ekle (?rec=1 arkası): kare başına landmark sayısı/fps, motorun gördüğü faz, aktif eşik değerleri, reddedilen rep'in RED NEDENİ. Motor "saymadım" derken NEDEN saymadığını söylemeli (loop kanunu: açıklanabilirlik).
2. Damla'dan 1-2 kısa kayıt (?rec=1 ile) → kopuk halka kayıtla teşhis edilir, tahminle değil.
3. Kopuk halkayı düzelt (eşik mi, faz mı, köprü mü — kanıta göre).
4. Her kurallı hareket için "başlangıç pozu + görüş alanı" kontrolü: müşteri kadraja yanlış girdiyse motor sessiz kalmak yerine söyler ("step back", "turn sideways" gibi tek satır yönlendirme).
5. Regresyon: düzeltme testlere girer (native test + kayıttan-replay), 104+ test yeşil kalır.

## DONE ÖLÇÜTLERİ
- Damla kamerada kurallı hareketleri yapar, her biri sayar — onun sözlü onayı TEK geçerli kabul.
- Reddedilen her rep'in nedeni ?rec=1 panelinde görünür (sessiz sıfır YOK).
- Kayıttan-replay testi repoda: Damla'nın kaydı motor formatına, beklenen rep sayısı assert edilir.
- Push'lu + canlıda doğrulanmış.
