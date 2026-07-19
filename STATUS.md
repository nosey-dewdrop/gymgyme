# gymgyme REWORK — STATUS

## FAZ 0 — Kritik hatalar   [kapı geçildi]
| kod | durum | kanıt |
|-----|-------|-------|
| G8  | kapandı | `diff root index.html` = AYNI; root'ta NOW SHOWING/starring you/ADMIT ONE = 0 |
| I5  | kapandı | index.html canlı: is it chatgpt = 1, calisthenics = 1 (9 Q&A + 8 kategori dizin) |
| Z3  | kapandı | gizlilik.html + gizlilik-tr.html + terms.html linki my-program.html'e; site geneli index.html# = 0 |

Kapı sonucu: GEÇTİ (ikinci deneme).
- İLK denemede kapı DÜŞTÜ: root eski sinema sayfasını serve ediyordu. Sebep DOSYA DEĞİL, Vercel edge CACHE'iydi (repoda sinema HTML yok; x-vercel-cache HIT eski deploy'u tutuyordu).
- Düzeltme: FAZ 0 push'u yeni deploy'u yaydı + vercel.json'a html için `cache-control: max-age=0, must-revalidate, s-maxage=0` eklendi -> root bir daha stale dönmez.
- landing-mock.html silindi (takipsiz, yayına çıkmıyordu).
- Düzeltme: dizin = topluluk link dizini (articles/workouts, hep boş); 386 hareket moves.html kütüphanesinde, AYRI şey.

## FAZ 1 — Tek kabuk, tek CSS   [başlamadı]
## FAZ 2 — index   [başlamadı]
## FAZ 3 — coach   [başlamadı]
## FAZ 4 — moves · my-moves · my-program   [başlamadı]
## FAZ 5 — blog · patch-notes · gizlilik · terms · suggest   [başlamadı]
## FAZ 6 — Generic denetimi   [başlamadı]
