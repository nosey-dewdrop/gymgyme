# benchmark-01 / dal A — teşhis enstrümanı + iskelet kalitesi

STATUS: DONE (kod yerelde, commit yok — 16 Tem dal A agent). Yapılan: 720p ideal (coach.js ~617), activePoseModel (~403, ~462), diag(r) rec=1 paneli (~1118-1163, render başında çağrı ~1165), sw v65. esbuild ESM temiz.
ANA LOOP: benchmark-01-algilama.md

## SORUN
Damla: "beni roblox gibi görüyor, hassasiyeti düşük." Kamera 640x480 açılıyor; model zinciri full→lite SESSİZCE düşebiliyor; motor saymadığında nedeni ekranda yok.

## İŞ
1. getUserMedia ideal 1280x720 (js/coach.js ~613)
2. aktif poz modeli görünür (hangi attempt tuttu: full+seg / full / lite)
3. ?rec=1 teşhis paneli: her karede insan diliyle NEDEN (iskelet yok / kadraj / güven düşük / hareket uyuşmazlığı / iniş sığ) + model + gerçek çözünürlük
4. sw.js cache bump

## DONE
- esbuild/syntax kanıtı, davranış değişikliği sadece rec modunda görünür ek panel + çözünürlük.
