# benchmark-01-algilama — kamera hareketi GERÇEKTEN görsün (L4)

STATUS: IN PROGRESS — dal A + dal B DONE (16 Tem, opus agentlar), KALAN: Damla kaydı
GÜNLÜK 16 Tem: dal A teslim — kamera 720p (roblox hassasiyeti şüpheli #1: 640x480 idi), aktif model artık görünür (full→lite sessiz düşüş yakalanır), ?rec=1 teşhis paneli her karede NEDEN söylüyor (iskelet yok / kadraj / güven / hareket uyuşmazlığı / sığ iniş). dal B teslim — .ggclip replay yolu uçtan uca kanıtlı: bench.sh makeclip sentetik squat üretir, bench.sh clip metrik tablosu basar (8/8 rep), 191 test yeşil.
DAMLA'DAN İSTENEN (2 dakika): telefonda coach.html'i ?rec=1 ile aç, 5-6 squat + 5-6 arm raise yap (iki ayrı seans), inen .ggclip dosyalarını at. Ekranın sol altındaki koyu teşhis panelinde ne yazdığına bir bak — o satır muhtemelen teşhisin kendisi. Kayıt gelince: bench.sh clip ile kopuk halka bulunur, düzeltilir, replay testi olarak repoya girer.
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
