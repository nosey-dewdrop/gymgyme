# OTONOM KOŞUM + DEVAMLILIK (Claude'un işletim kılavuzu — Damla okumaz)

> ANAYASA "ne" der; bu dosya "nasıl koşulur" der. Amaç: Damla'ya router/denetim yükü
> BİNMEDEN zincirin kendi kendine dönmesi. Damla'ya ancak (a) kapı kartı, (b) gerçek
> darboğazda tek fikir/tasarım sorusu ile dönülür.

## KOŞUM DÖNGÜSÜ (her tur)
1. **OKU**: DEVAM.md (SIRA + NEREDEYİZ + PARK) + proje CLAUDE.md + ANAYASA. Kopuk başlama.
2. **SEÇ**: SIRA'daki sıradaki açık iş. Kapı kartı bekliyorsa BEKLEME — paralel başka işe geç.
3. **YAP**: işi bitir, KANIT üret (derleme/test/render/curl/ölçüm). Kanıtsız "oldu" yasak.
4. **DENETLE**: ilgili lint/test/ölçüt kendi akar. Geçtiyse ray yeşil.
5. **YAZ**: NEREDEYİZ'i güncelle (ne bitti+kanıt / ne açık / sıradaki tek adım). Commit+push.
6. **TEKRAR**: SIRA bitene ya da tek kalan iş kapı beklemesine kadar dön.

## TAKILINCA — TEŞHİS ET, YENİ ZİNCİR KUR (Damla'ya dönme)
Bir iş ilerlemiyorsa sıra şu, HER kademede kendin çöz:
1. **MİKRO-LOOP** (derinlik ≤2): sorunu izole et, tek düzeltme, tekrar dene.
   Rapora "MİKRO-LOOP: sorun/çözüm/dönüş" bloğu.
2. **TEŞHİS**: derinlik 2'de hâlâ takılıysa DUR, kök nedeni ölçümle bul (log/diff/render).
   "Ne bozuk, neden bozuk" — girdi mi çıktı mı mimari mi. Sonucu yaz.
3. **YENİ ZİNCİR**: teşhis mevcut planın yanlış olduğunu gösteriyorsa, eski zinciri
   KIRMIZI-MÜHÜR'le kapat, teşhisten yeni bir DEVAM/SIRA türet, ona geç. Bu SENİN işin.
4. **DAMLA'YA ANCAK**: teşhis bir FİKİR ya da TASARIM/estetik kararı gerektiriyorsa
   (mühendislik değil) — o zaman TEK net soru. Yoksa dönme.

## KAPI (geri-alınamaz işler — ANAYASA §1)
`node .operator/gate.mjs open <ID> <tip> "<baslik>"` → pending. Zincir devam eder.
Damla `decide <ID> approve|reject "<gerekçe>"` der. Pin/deploy/post ANCAK approve sonrası.
Ret gerekçesi → karar/zevk sözlüğüne işlenir, sonraki tur oradan başlar.

## DEVAMLILIK (oturumlar kopmasın)
- NEREDEYİZ her tur sonu güncel → sonraki oturum oradan başlar.
- Yarım iş bırakma; bırakıyorsan NEREDEYİZ'e "YARIM: <ne>, <dönüş noktası>" yaz.
- PARK listesi kalıcı hafıza; ertelenen hiçbir şey unutulmaz.
- Uzun/otonom koşumda: iş bitene kadar koş, süre tahmini yapma, istenmeden özet/kapanış yapma.

## SINIR (Damla'nın kalıcı kuralları — çiğnenmez)
- Uyku/dinlenme/gün-kapatma önerme. Yapılan işi zırt pırt özetleme.
- Konuşmayı üretimin yerine koyma: emin olunca OTUR YAP RENDER ET GÖSTER.
- Şikayet/venting iş emri değildir; belirsizse tek cümleyle restate + "evet" bekle.
