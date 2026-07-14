# gymgyme

tamamen tarayıcında çalışan bir personal trainer. bilgisayarlı görü, senin cihazında, hiçbir kare hiçbir yere yüklenmiyor.

canlı: https://gymgyme.damlahelloworld.com

## neden yaptım

evde spor yapmaya çalışan herkesin sorunu aynı: doğru mu yapıyorum bilmiyorsun, sayan yok, düzelten yok. spor salonundaki hoca cebinde olsun istedim ama kamera görüntüsünü buluta gönderen bir şey değil — mahremiyeti fizik zorlasın, ben söz vererek değil. o yüzden kamera görüntüsü cihazdan hiç çıkmıyor, çıkamıyor.

## kalbi: kendi yazdığım c++ motoru

asıl iş `engine/` klasöründeki, elle yazılıp webassembly'ye derlenmiş c++ motorunda dönüyor. her karede mediapipe'ın pose landmarker'ı gpu'da 33 vücut noktasını okuyor; benim motorum o gürültülü noktaları alıp asıl koçluğu yapıyor:

- **eklem-açısı uzayında one euro filtresi** — parametreleri hisle değil, bir ölçüm bench'iyle seçtim
- **kemik-kilidi iskelet**: kalibrasyon senin kemik uzunluklarını metrik dünya koordinatında öğreniyor, sonra her karede iskeleti yeniden oturtuyor — kemik uzunluğu varyansı ham ~%5'ten %0.00'a düşüyor, eklemler kayamıyor
- **kişi kilidi**: kadraja başkası girerse motor onu koçlamayı reddediyor (kalibre edilmiş vücut oranları + zamansal tutarlılık vetosu)
- **hareket-öncülü kapılama**: fiziksel olarak mümkün açısal hız her hareketin kendi spec'inden türetiliyor — squat yaparken squat fiziği
- **histerezisli tekrar sayımı**, yarım-tekrar tespiti, 0-100 puanlama (derinlik/tempo/kontrol) ve her tekrardan sonra tek satır koç yorumu
- görsel katman olarak yüz mesh'i + el iskeleti + segmentasyon silueti; derinlik-kodlu çizim

120+ native birim testi (`engine/test.sh`), sentetik doğru-referanslı bir ölçüm bench'i (`engine/bench.sh`: jitter, rmse, gecikme, kemik varyansı, iki-kişi senaryoları) ve offline değerlendirme için landmark akışını yakalayan gizli bir `?rec=1` kaydedici var.

## motorun etrafındaki dünya

bir sinema-marquee dünyası: 188 hareketlik kütüphane, beğenilen hareketler, tek dokunuşla programlar, contribution graph gibi boyanan bir devamlılık takvimi ve toplulukça derlenen evde-spor link dizini.

**ücretsiz, reklam yok, takip yok. antrenman sayıların (asla video) sadece giriş yaparsan senkronlanıyor.**

## stack

c++17 → webassembly (emscripten) motor + statik html/css/js (build adımı yok) + mediapipe tasks (vendored, cihaz üstünde) + supabase (hesap + antrenman sayıları, rls korumalı). vercel'de barınıyor.

## katkı

sitedeki öneri formunu kullan — zaten olayın tamamı bu. gönderdiğin isim sayfada girdiyle birlikte yayınlanıyor; istersen takma ad kullan.

## kurulum notları

- `supabase/migration.sql` — tablo, rls politikaları ve seed satırları; supabase sql editörüne bir kere yapıştır.
- `config.js` — supabase url + anon key (bilerek public, her şeyi rls koruyor).
- domain bağlandıktan sonra: `index.html`'deki canonical/og:url'yi güncelle, gerçek domain'le robots.txt + sitemap.xml ekle.
