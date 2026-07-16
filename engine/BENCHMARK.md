# gymgyme motor dogruluk bandi (bench suite)

Tek komut: `bash engine/bench.sh suite` (kapi: `--check`). Deterministik
cikti — mmfit klipleri ayni npy+csv'den, sentetik sabit seed. Motor rep =
One Euro filtreli sayim. Rep-dogrulugu = min(motor,etiket)/etiket.

| klip | hareket | etiket rep | motor rep | half | reject/dropout | rep-dogruluk % |
|------|---------|-----------:|----------:|-----:|---------------:|---------------:|
| synth_squat | squat | 8 | 8 | 0 | 0 | 100.0 |
| squats_0 | squat | 10 | 9 | 0 | 0 | 90.0 |
| squats_1 | squat | 10 | 9 | 0 | 0 | 90.0 |
| squats_2 | squat | 10 | 9 | 0 | 0 | 90.0 |
| pushups_0 | pushup | 11 | 0 | 8 | 0 | 0.0 |
| pushups_1 | pushup | 10 | 1 | 5 | 0 | 10.0 |
| pushups_2 | pushup | 10 | 0 | 4 | 0 | 0.0 |
| lunges_0 | lunge | 10 | 6 | 0 | 0 | 60.0 |
| lunges_1 | lunge | 10 | 6 | 0 | 0 | 60.0 |
| lunges_2 | lunge | 10 | 6 | 0 | 0 | 60.0 |
| situps_0 | situp | 10 | 0 | 0 | 0 | 0.0 |
| situps_1 | situp | 10 | 0 | 0 | 0 | 0.0 |
| situps_2 | situp | 10 | 0 | 0 | 0 | 0.0 |
| dumbbell_shoulder_press_0 | press | 10 | 0 | 0 | 0 | 0.0 |
| dumbbell_shoulder_press_1 | press | 10 | 0 | 0 | 0 | 0.0 |
| dumbbell_shoulder_press_2 | press | 9 | 0 | 0 | 0 | 0.0 |
| lateral_shoulder_raises_0 | armraise | 10 | 0 | 0 | 0 | 0.0 |
| lateral_shoulder_raises_1 | armraise | 10 | 0 | 0 | 0 | 0.0 |
| lateral_shoulder_raises_2 | armraise | 10 | 0 | 0 | 0 | 0.0 |
| jumping_jacks_0 | jumpingjack | 11 | 0 | 0 | 0 | 0.0 |
| jumping_jacks_1 | jumpingjack | 11 | 0 | 0 | 0 | 0.0 |
| jumping_jacks_2 | jumpingjack | 10 | 0 | 0 | 0 | 0.0 |

**Ozet:** toplam 54 / 220 rep dogru sayildi -> genel rep-dogruluk **%24.5**

> Not (uydurma degil): press / situp / armraise / jumpingjack su an 0 sayiliyor.
> Kok retarget/ROM sikismasi (benchmark-04 teshisi), motor esigi degil. Bunlar
> tabana KOYULMADI (kapi gurultusu olmasin); squat/lunge/pushup/sentetik tabanli.
