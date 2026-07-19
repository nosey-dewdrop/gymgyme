# gymgyme REWORK — STATUS

## FAZ 0 — Kritik hatalar   [kapı geçildi — 19 Tem]
| kod | durum | kanıt |
|-----|-------|-------|
| cache | kapandı | freshness testi: işaretli deploy → root'ta 1, işaret kaldırıldı deploy → root'ta 0; edge her deploy'da anında tazeleniyor (HIT görünse de stale dönmüyor). Ölçüt "MISS/BYPASS" → "içerik taze" güncellendi (Damla). |
| G8  | kapandı | `diff root index.html` = AYNI; root NOW SHOWING = 0, is it chatgpt = 1 |
| I5  | kapandı | 9 Q&A native `<details>/<summary>`, dizinden sonra + contributors'tan önce, metin cf49e20'den BİREBİR; canlı: details = 9, the strictest privacy policy = 1, calisthenics = 1, healthy-living-articles = 1 |
| Z3  | kapandı | gizlilik/terms link kırığı önceki oturumda düzeldi; site geneli sinema kalıntısı canlıda yok |

Kapı sonucu: GEÇTİ.
- Cache: gerçek sebep vercel.json'daki `/(.*\\.html)?` regex'iydi — opsiyonel `.html?` çıplak root `/`'u kapsamıyordu, sadece tarayıcı cache'i kapanıyor, CDN açık kalıyordu. Düzeltme: `source: "/"` + `source: "/(.*\\.html)"` ayrı iki kural, ikisine de `s-maxage=0`. Statik varlıklar (css/js/img/wasm) kasıtlı cache'li bırakıldı.
- I5 uyarı: `ed6394a` commit mesajı "restore 9-question qa" diyor ama içeriği boş — commit mesajına değil içeriğe bakıldı. Gerçek kaynak cf49e20 (sinema orijinali). Beklenen "does my video / will it work / who made" ifadeleri hiç var olmamış (Damla teyit etti).
- Dizin = topluluk link dizini (articles/workouts sayacı, hep 0); 386 hareket moves.html'de, AYRI şey.
- AÇIK (FAZ 1'e devir): topbar arama kutusu (`#topSearch`) HTML'den düşmüş, topbar.js onu arıyor. FAZ 0 kapısında değil; topbar FAZ 1'de kanonikleşecek, orada geri gelir.

## FAZ 1 — Tek kabuk, tek CSS   [başlamadı]
## FAZ 2 — index   [başlamadı]
## FAZ 3 — coach   [başlamadı]
## FAZ 4 — moves · my-moves · my-program   [başlamadı]
## FAZ 5 — blog · patch-notes · gizlilik · terms · suggest   [başlamadı]
## FAZ 6 — Generic denetimi   [başlamadı]
