# LOOP 04 — %60 KABUL KAPISI (rep sadece yeterince iyiyse sayılsın)

STATUS: DONE (wasm rebuild: OK, motor.wasm rebuilt, 3 yeni alan binary'de doğrulandı). Damla kamerada "çöp rep sayılmıyor" onayı KALDI (canlı teyit onun).
GRUP: B (sonuç güvenilir mi)
BAĞIMLILIK: GRUP A bittikten sonra.

## SORUN (kanıt: coach_engine.cpp:1221)
Şu an rep, SADECE açı penceresi kapanınca (topTh→bottomTh→topTh) sayılıyor —
skordan BAĞIMSIZ. Skoru %20 de olsa sayılıyor, %95 de olsa. "accuracy ≥ %60 olunca say"
diye bir kapı MOTORDA YOK. Robot gibi %100 aramamalı ama çöp rep'i de saymamalı.

## KRİTİK AYRIM (karıştırma)
- FİLTRE toleransı (nefes/titreme/sarsıntı) = ZATEN var (One Euro + Kalman). Bu ayrı katman.
- KABUL eşiği (%60 "yeterince iyi rep") = YENİ eklenecek. Bu ayrı katman.
- Mimari: Filtre → Rep pencere → **%60 KAPISI (yeni)** → 0-100 skor.

## HEDEF
- `kRepAcceptPct` MoveSpec'e (hareket başına ayarlanabilir; plank≠squat).
- Rep tamamlandığında lastScore_ zaten hesaplı → `if (lastScore_ >= kRepAcceptPct) reps_++`.
  Altındaysa: yarım-rep / "biraz daha derine" uyarısı, SAYMA.
- Default eşik 60; her hareket kendi eşiğini MoveSpec'ten alır.

## SINIRLAR (yasak)
- 104+ yerel test BOZULMAZ. Yeni testler eklenir (eşik altı sayılmaz, üstü sayılır).
- One Euro/Kalman kalbine dokunma.

## DONE ÖLÇÜTÜ
- [ ] kRepAcceptPct MoveSpec'te, motor rep'i eşiğe göre sayıyor.
- [ ] Yeni birim testler yeşil, eski 104+ hâlâ yeşil (test.sh çıktısı kanıt).
- [ ] Damla kamerada: çöp rep sayılmıyor, düzgün rep sayılıyor.

## KAPANIŞTA
- STATUS: DONE, README kutusu. Kapanış ritüeli: README.md (devlog her zaman; büyük rework ise +rapor+linkedin).
- Yeni sekme → benchmark-05-scorebadge.md.

## LOOP GÜNLÜĞÜ
### 16 Tem — kapı motora girdi (native + wasm yeşil)
NE YAPILDI:
- `MoveSpec.acceptPct` eklendi (default 60, hareket başına override; plank≠squat). FİLTRE ≠ EŞİK ayrımı korundu: One Euro sinyali temizler, acceptPct KABUL kararıdır.
- coach_engine.cpp: rep penceresi kapanınca AKIŞ TERSİNE ÇEVRİLDİ. Eskiden `reps_++` koşulsuzdu, skor SONRA hesaplanıyordu. Artık: önce skorla → `if (score < acceptPct)` ise SAYMA, `rejectedReps_++`, `rejectTick`, `lastRejectReason="form N < 60"`, koç "that one didn't count - form N, need 60+". Set ilerlemesi/ortalama/simetri sadece SAYILAN rep'e işler — reddedilen hiçbirine girmez.
- KARAR: halfReps'e DOKUNULMADI. halfReps = dibe inmeyen iniş (ayrı kavram); yeni kapı = dibe inen ama formu kötü rep. İkisi ayrı sayaç, JS'te ayrı satır ("not counted: X too shallow, Y form too low").
- KARAR: hold hareketlerine dokunulmadı (holdQuality süre-tabanlı; kapı sadece rep-based).
- Reading + bindings.cpp: `rejectedReps`, `rejectTick`, `lastRejectReason` alanları eklendi ve embind ile JS'e köprülendi (3 alan motor.wasm binary'sinde `strings` ile doğrulandı).
- js/coach.js: rejectTick'te halfBuzz + koç cümlesi; halfNote satırı iki nedeni ayırıyor; `?rec=1` diag paneline form-kapısı reddi sticky mesajı eklendi (diagPrevReject).
- sw.js CACHE v65 → v66 (engine değişti).

MEVCUT TEST ÇAKIŞMASI (çözüldü, test SİLİNMEDİ):
- "a rushed rep is told to slow down" testi kapıya takıldı (aceleci rep skoru <60 → reddediliyordu, repTick hiç ateşlemiyordu). O blok YORUM motorunu sınıyor, kapıyı değil → o engine'e `acceptPct=0` verildi, niyet korundu.

KANIT (sayılar):
- Native: `bash engine/test.sh` → all tests passed. coach suite 153 → 166 ok (+13 yeni kapı testi, 0 kayıp). Toplam tüm suitler: 166 + kalman 14 + ik 12 + classifier 12 = **204 ok** (baseline 191).
- Yeni 3+ test: (a) eşik altı → sayılmaz + rejectedReps=1 + rejectTick + reason "< 101" + koç "didn't count" + avg=-1'de kalır, (b) eşik üstü temiz rep sayılır (score≥60), (c) hareket başına override: aynı aceleci rep acceptPct=0'da sayılır, rushScore+1'de reddedilir, rushScore-1'de sayılır.
- wasm: `bash engine/build.sh` → `ok: motor.js 45588 motor.wasm 85315`. motor.wasm git'te M, yeni 3 alan binary'de mevcut.
- `npx esbuild js/coach.js --outfile=/dev/null` → temiz (exit 0).

RİSK / AÇIK:
- Damla kamerada canlı teyit vermedi (çöp rep gerçekten sayılmıyor mu). Motor+testler kanıtlı; canlı görsel onay onun.
- Vercel deploy limiti (CLAUDE.md) → canlıya push Damla'nın kararı; commit ATILMADI (talimat: sen doğrulayıp commit'le).
