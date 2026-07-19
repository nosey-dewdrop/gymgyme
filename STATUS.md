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

## FAZ 1 — Tek kabuk, tek CSS   [kapı: Damla ekran görüntüsü onayı bekliyor — 19 Tem]
| kod | durum | kanıt (canlı, çıplak URL) |
|-----|-------|------|
| tek stylesheet | kapandı | 13 URL (root + 12 sayfa) hepsi yalnız css/site.css; eski css'ler canlıda 404; site.css 200 text/css |
| G1 G2 | kapandı | tek css/site.css = tek tasarım dünyası; nav 12/12 + footer 12/12 partial'a BİREBİR (diff ok) |
| G3 emoji | KISMİ | 🔍♥📸✨🎀🤸▸▾ tümü söküldü; TEK istisna moves.html'de görünür cümle içindeki ♥ ("tap the ♥...") — copy'ye dokunma kuralı emoji yasağıyla çakışıyor, Damla kararı bekliyor |
| G4 buton | kapandı | tek buton dili site.css (.btn lila / .ghost hairline); pembe hap + siyah dikdörtgen kalktı |
| G5 | kapandı | site.css reset + tipografi (Bricolage/Inter/JetBrains Mono google fonts) — tarayıcı varsayılanı yok |
| G9 | kapandı | favicon 🎀 → icons/icon-192.png tüm sayfalar; fontlar her head'de |
| B1 B4 | kapandı | blog.html artık site.css + kanonik nav (my moves dahil) |
| Z1 Z2 | kapandı | gizlilik/gizlilik-tr/terms sidebar kabuğundan çıktı, ortak kabuk (nav+main.prose+footer) |
| S1 | site.css'te | suggest form alanları .field/input site.css sistemine bağlı (görsel FAZ 5'te teyit) |
| !important | 0 | grep -rc "!important" css/ = 0 |
| inline style | 0 | grep -l "<style" *.html boş |
| #topSearch | 12/12 | her sayfada canlı |
| rename | tamam | .stage→.panel, .receipt→.summary, #camstage→#camera (coach.html + js/coach.js $("camera")); coach.js node --check OK |

Notlar / açık:
- partials/nav.html + footer.html = tek kaynak. Site'de build step yok → içerik her sayfaya BİREBİR yapıştırıldı (kapı "10 sayfada aynı" böyle sağlandı).
- INLINE STYLE SİLİNDİ → index (hero .worth/.how/.priv/.loop), patch-notes (polaroid/timeline) ve moves/my-program sayfa-özel görselleri şu an STİLSİZ. FAZ 2/4/5 onları site.css sistemiyle yeniden kuracak. Bu FAZ 1'in doğası (tek CSS'e in), FAZ 2 index'i baştan tasarlıyor zaten.
- sw.js CACHE v69→v70, CORE'dan silinen css'ler çıkarıldı + css/site.css eklendi (install kırılmasın).
- Ekran görüntüsü: Damla kendi dev'inde bakar (headless screenshot kuralı gereği ben üretmiyorum).


## FAZ 2 — index   [başlamadı]
## FAZ 3 — coach   [başlamadı]
## FAZ 4 — moves · my-moves · my-program   [başlamadı]
## FAZ 5 — blog · patch-notes · gizlilik · terms · suggest   [başlamadı]
## FAZ 6 — Generic denetimi   [başlamadı]
