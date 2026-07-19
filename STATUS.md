# gymgyme REWORK — STATUS

## FAZ 0 — Kritik hatalar   [kapı geçildi]
| kod | durum | kanıt |
|-----|-------|-------|
| G8  | kapandı | root == index.html canlı diff boş (curl) |
| I5  | kapandı | index.html'de 9 Q&A + 8 kategori + dizin scriptleri canlı (curl grep 9/8) |
| Z3  | kapandı | gizlilik.html + gizlilik-tr.html + terms.html: index.html#my-program -> my-program.html; site geneli index.html# taraması boş |

Kapı sonucu: GEÇTİ.
- root ile /index.html canlı diff boş.
- 9 soruluk Q&A ve 8 kategorili dizin+arama yeni index'te geri geldi (metinler 8323265'ten birebir).
- kırık my-program linki 3 sayfada düzeldi, sitede index.html# kırık link 0.
- NOT: dizinin JS ile 386 hareketi render ettiği tarayıcıda doğrulanmalı (curl statik HTML'i görür, #directory'yi script.js dolduruyor). Scriptler yüklü + div mevcut.

## FAZ 1 — Tek kabuk, tek CSS   [başlamadı]
## FAZ 2 — index   [başlamadı]
## FAZ 3 — coach   [başlamadı]
## FAZ 4 — moves · my-moves · my-program   [başlamadı]
## FAZ 5 — blog · patch-notes · gizlilik · terms · suggest   [başlamadı]
## FAZ 6 — Generic denetimi   [başlamadı]
