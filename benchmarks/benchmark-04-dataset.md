# LOOP 07 — VERİ SETİ (motor neyle öğrenecek/doğrulanacak)

STATUS: IN PROGRESS — mmfit ucu DONE (yol kanıtlandı: veri -> ggclip -> motor -> tablo). Kalan: EC3D + REHAB24-6 uçları, diğer segmentler.
GRUP: C (motor gerçekten öğrensin)
BAĞIMLILIK: 06 bittikten sonra.

## SORU (Damla: "internette milyar spor videosu var, öyle mi eğiticez?")
CEVAP (araştırma kanıtlı): internetteki milyar video ETİKETSİZ (kaç rep / hangi form hatası belli değil),
telif+KVKK riskli, gigabaytlarca disk. Doğruluğu ÖLÇEMEZSİN → işe yaramaz.
Tek başına yeten açık set YOK. Ama etiketli + telif-temiz + indirilebilir 3 set var.

## KAYNAKLAR (araştırma raporu: reports/2026-07-15-gymgyme-vizyon-motor-teshis.md + agent bulgusu)
1. **REHAB24-6** (Zenodo, CC-BY-NC, 5.7GB): 2D/3D iskelet + rep segmenti + doğru/yanlış form. squat/lunge.
2. **EC3D** (~300MB): 3D iskelet + form-hatası etiketli. squat/lunge/plank.
3. **MM-Fit** (MIT): iskelet + rep-count, 10 hareket (squat/pushup/situp/jumping jack...).
   → hepsi İSKELET (video değil) veya iskelete dönüştürülür; disk makul, telif temiz.

## HEDEF
- Setleri indir, motorun MediaPipe-33 formatına DÖNÜŞTÜR (iskelet JSON zaman serisi).
- Her klip için ground-truth etiket tut: beklenen rep sayısı + form hataları.
- engine/dataset/ altında düzenli sakla. **Ham veri gitignore** (repo şişmesin, sadece dönüştürülmüş özet + golden).
- KAPSAMA BOŞLUĞU: açık setlerde olmayan hareketler (mountain climber, russian twist, high knees...)
  → Damla golden klip çeker (video değil, iskelet JSON kaydedilir, ~50KB, kimse tanınmaz, KVKK temiz).

## SINIRLAR (yasak)
- Ham video repoya GİRMEZ (disk). Sadece iskelet + etiket.
- Uydurma etiket YOK — her etiket ya set'ten gelir ya Damla golden çekiminden.
- Lisans: CC-BY-NC ticari değil ama gymgyme para hedefi yok → uygun. Kaynak künyesi dosyada.

## DONE ÖLÇÜTÜ
- [ ] En az REHAB24-6 + EC3D indirildi, iskelet JSON'a dönüştü.
- [ ] Ground-truth etiket tablosu var.
- [ ] Kapsama boşluğu listesi (Damla'nın çekeceği hareketler) net.
- [ ] Disk şişmedi (ham veri gitignore).

## KAPANIŞTA
- STATUS: DONE, README kutusu. Kapanış ritüeli: README.md (devlog her zaman; büyük rework ise +rapor+linkedin).
- Yeni sekme → benchmark-08-bench.md.

## LOOP GÜNLÜĞÜ

### 16 Tem — İLK UÇUŞ: MM-Fit ucu (yolu tek sette kanıtla)
Amaç: üç setten SADECE MM-Fit ile uçtan uca yolu (veri -> ggclip -> motor -> tablo)
kanıtlamak. Hepsini indirmedim; önce tek sette retarget doğrulandı.

**LİSANS (kanıtlı):** MM-Fit — kaynak repo `github.com/KDMStromback/mm-fit`
**MIT lisanslı** (repo footer). Site: mmfit.github.io. Ticari + akademik serbest,
atıf yeter → gymgyme için tamamen uygun. Dataset zip'i ORİJİNAL VİDEO İÇERMİYOR
(makale: "Neither mm-fit nor UI-PRMD provides original video") — sadece sensör +
2D/3D iskelet + etiket. KVKK/telif açısından temiz.

**İNDİRİLEN PARÇA (< 1GB kuralı):** Tam zip 1.74GB (S3). Ama zip düz yapıda ve her
workout ayrı dosya. `remotezip` (kısmi/ranged okuma) ile SADECE w00'ın iki dosyası
çekildi — video/sensör indirilmedi:
- `mm-fit/w00/w00_pose_3d.npy`  (sıkışık 24.5MB, açık 27.6MB)
- `mm-fit/w00/w00_labels.csv`   (846 B)
Toplam disk: **27MB** (bütçenin çok altında). engine/data/mmfit/ altında, gitignore'lı.

**POZ FORMATI:** `w00_pose_3d.npy` şekli `(3, 63918, 18)`.
- axis 0..2 = koordinat satırları: **[X yatay, depth/derinlik, vertical/dikey]**.
  Dikey (row 2) YUKARI bakıyor (kafa > ayak bileği) → MediaPipe ekran-y AŞAĞI, bu yüzden FLIP.
- column 0 = kare numarası (30 fps indeksi). columns 1..17 = **17 eklem, Human3.6M /
  Martinez et-al sırası** (2D=OpenPose, 3D=Martinez lifting — makaleden doğrulandı).
- ham dünya (mm cinsinden), gürültülü monoküler lifting → yüksek kemik varyansı (aşağıda).

**ETİKET (ground-truth rep):** `w00_labels.csv` = `start_frame, end_frame, reps, exercise`.
w00 squat 3×10, pushup 11/10/10, lunge 3×10 (+ situp/press/rows/curls/raises/jacks).

**EŞLEME (h36m 17-joint -> MediaPipe-33), `engine/tools/mmfit2ggclip.py`:**
| h36m eklem (col) | ad          | MediaPipe idx |
|------------------|-------------|---------------|
| 10               | head        | 0 (nose, ~)   |
| 11               | l shoulder  | 11 (L_SHO)    |
| 14               | r shoulder  | 12 (R_SHO)    |
| 12               | l elbow     | 13 (L_ELB)    |
| 15               | r elbow     | 14 (R_ELB)    |
| 13               | l wrist     | 15 (L_WRI)    |
| 16               | r wrist     | 16 (R_WRI)    |
| 4                | l hip       | 23 (L_HIP)    |
| 1                | r hip       | 24 (R_HIP)    |
| 5                | l knee      | 25 (L_KNE)    |
| 2                | r knee      | 26 (R_KNE)    |
| 6                | l ankle     | 27 (L_ANK)    |
| 3                | r ankle     | 28 (R_ANK)    |
MM-Fit'te olmayan MediaPipe landmark'ları (yüz, parmak, ayak detayı) **vis=0** → motor atlar.
Projeksiyon: screen_x=X, screen_y=-vertical (flip), z=depth; bütün-klip bbox ile
[0,1]'e normalize (aspect korunur, kare-arası jitter yok). Exercise->MoveSpec:
squats->squat, pushups->pushup, lunges->lunge, situps->situp,
dumbbell_shoulder_press->press, lateral_shoulder_raises->armraise, jumping_jacks->jumpingjack.
(rows/bicep_curls/tricep_extensions: karşılık MoveSpec yok → atlandı.)

**BENCH TABLOSU (etiket rep vs motor rep, `bench.sh clip`):**
| hareket | set | etiket rep | motor rep (ema) | motor rep (euro) | half | reject/dropout | uyluk kemik var. |
|---------|-----|-----------|-----------------|------------------|------|----------------|------------------|
| squat   | 0   | 10        | 0               | 0                | 0    | 0              | 14.96%           |
| squat   | 1   | 10        | 0               | 0                | 0    | 0              | 14.63%           |
| squat   | 2   | 10        | 0               | 0                | 0    | 0              | 14.91%           |
| pushup  | 0   | 11        | 0               | 0                | 11/10| 0              | 4.00% (baldır 14%)|
| pushup  | 1   | 10        | 0               | 0                | 10   | 0              | 4.41%            |
| pushup  | 2   | 10        | 0               | 0                | 9/7  | 0              | 4.56%            |
| lunge   | 0   | 10        | 5               | 5                | 0    | 0              | 13.19%           |
| lunge   | 1   | 10        | 5               | 5                | 0    | 0              | 12.48%           |
| lunge   | 2   | 10        | 5               | 5                | 0    | 0              | 12.17%           |

(kıyas: sentetik squat klibi `makeclip` -> motor 8/8 doğru, uyluk kemik var. %2.65.)

**TEŞHİS (düzeltme LOOP 01/05 işi — burada sadece teşhis):**
- Sorun RETARGET/PROJEKSİYON tarafında, motor eşiğinde DEĞİL. Kanıt: aynı motor
  sentetik klibi 8/8 sayıyor; MM-Fit kemik-uzunluk varyansı %12-15 (sentetikte %2.6)
  → mapped iskelet geometrik olarak oynak.
- Squat R-diz açısı klip boyunca sadece **92°-120°** (ort 102°) arası; hiç ~160°+
  düz-ayakta konumuna çıkmıyor → motor top->bottom->top döngüsü göremiyor → 0 rep.
  Sebep: MM-Fit 3D pozları monoküler 2D->3D lifting (Martinez), gürültülü; ayrıca
  kameraya-dönük squat'ı ortografik 2D'ye düşürünce diz açısı sıkışıyor. Sol/sağ diz
  asimetrisi (sol 36°-123°) de lifting gürültüsünü doğruluyor.
- Lunge: motor 10 yerine 5 sayıyor — tek-bacak dönüşümlü lunge'ta motor sadece bir
  bacağın primary açısını izliyor olabilir (2 tekrar = 1 döngü gibi görünüyor). Yine
  eşik değil, hangi-bacak/perspektif seçimi meselesi.
- Pushup: hep "half" — dip var ama tam kilit (top) açısına ulaşmıyor; aynı top-eşiği
  problemi. → hepsi ortak kök: lifting+ortografik projeksiyon ROM'u (hareket açıklığı)
  sıkıştırıyor, top eşiği tutmuyor.

**KANIT (gerçek komut + çıktı):**
- İndirme: `python3` + `remotezip` ile w00_pose_3d.npy (27.6MB) + labels.csv çekildi.
- Dönüşüm: `python3 engine/tools/mmfit2ggclip.py <npy> <csv> --exercise squats --set 0 -o x.ggclip`
  → 9 klip yazıldı (squat/pushup/lunge × 3 set).
- Bench: `bash engine/bench.sh clip x.ggclip` → yukarıdaki tablo.
- Mapping birim testi (roundtrip + görünürlük + dikey-flip + eklem kapsaması): **4/4 GREEN**.
- Motor testleri bozulmadı: `bash engine/test.sh` → **204 ok**.

**SONRAKİ ADIM:**
1. (LOOP 01/05) ROM sıkışması: MM-Fit klibinde adaptif top-eşiği / perspektif
   düzeltmesi ya da 3D dünya-açısını kullanma (screen yerine world landmark açısı).
2. Kalan MM-Fit segmentleri (situp/press/armraise/jumpingjack) + diğer workout'lar (w01..w20).
3. Diğer iki set: **EC3D** (~300MB, 3D iskelet + form-hatası etiketli) ve **REHAB24-6**
   (Zenodo CC-BY-NC, 5.7GB — sadece iskelet+rep parçası çekilecek). Aynı retarget deseni;
   her set için ayrı `*2ggclip.py` küçük adaptör.

## LOOP GÜNLÜĞÜ (eski placeholder)
- (henüz başlamadı)
