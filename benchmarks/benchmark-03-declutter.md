# LOOP 03 — DECLUTTER (CS-ödevi hissini kaldır)

STATUS: TODO
GRUP: A (görünür değer)
BAĞIMLILIK: 02 bittikten sonra.

## SORUN
Debug metreler (depth/confidence/framing + açı + fps) müşteriye laboratuvar/CS-ödevi hissi veriyor.
Fiş (.receipt) desktop'ta videoyu örtüyor — üründe hata gibi görünüyor.

## HEDEF
- Debug paneli müşteriden gizle: sadece `?rec=1` (geliştirme) modunda görünsün.
  - coach.html debug meters bloğu + #angles + #fps.
  - coach.js render'ı `if (recOn)` arkasına.
- Fiş: body.running iken sağa dock, videoyu örtmesin (z-index/konum).
- Müşteri katı = temiz: kamera + overlay + rep sayısı + tek koç cümlesi. Başka hiçbir sayı yok.

## SINIRLAR (yasak)
- `?rec=1` lab katı SİLİNMEZ (Damla ölçüm için kullanıyor) — sadece müşteriden gizli.
- Whimsy (fiş) silinmez, taşınır.

## DONE ÖLÇÜTÜ
- [ ] Normal ziyaretçi hiçbir debug sayısı görmüyor (açı/fps/confidence gizli).
- [ ] `?rec=1` ile hepsi hâlâ geliyor.
- [ ] Fiş videoyu örtmüyor (desktop + mobil).
- [ ] Damla "artık ürün gibi, ödev gibi değil" onayı.

## KAPANIŞTA
- STATUS: DONE, README kutusu. Kapanış ritüeli: README.md (devlog her zaman; büyük rework ise +rapor+linkedin).
- GRUP A BİTTİ → görünür müşteri değeri teslim edildi.
- Yeni sekme → benchmark-04-gate.md.

## LOOP GÜNLÜĞÜ
- (henüz başlamadı)
