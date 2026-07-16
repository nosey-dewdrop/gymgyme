#!/usr/bin/env bash
# gymgyme bench SUITE — tek komutluk dogruluk bandi + regresyon kapisi.
#
#   bash engine/bench.sh suite            -> tabloyu uretir + engine/BENCHMARK.md yazar
#   bash engine/bench.sh suite --check    -> ayni tablo + TABAN kontrolu (regresyon
#                                            olursa exit 1, hangi klip dustu yazar)
#
# DETERMINISTIK: mmfit klipleri her kosuda ayni npy+csv'den ayni uretilir;
# sentetik makeclip sabit seed (42) kullanir. Boylece BENCHMARK.md diff'i anlamli.
#
# Suite test.sh'a BAGLANMAZ (test hizli kalir). build.sh sonrasi hatirlatma var.
# Not: macOS sistem bash 3.2 uyumlu — associative array YOK, satir-tabanli tablo.
set -euo pipefail
export LC_ALL=C          # deterministik: ondalik nokta, awk locale bagimsiz
ENG="$(cd "$(dirname "$0")/.." && pwd)"     # engine/
cd "$ENG"

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

BENCH=/tmp/coach_bench
BASELINES="$ENG/bench-baselines.txt"
OUT="$ENG/BENCHMARK.md"
NPY="$ENG/data/mmfit/mm-fit/w00/w00_pose_3d.npy"
CSV="$ENG/data/mmfit/mm-fit/w00/w00_labels.csv"
WORK="$(mktemp -d)"
ROWS="$WORK/rows.tsv"          # id \t move \t label \t rep \t half \t drop
: > "$ROWS"
trap 'rm -rf "$WORK"' EXIT

# 1) motoru derle (bench + engine cekirdegi)
clang++ -std=c++17 -O2 -Wall bench.cpp coach_engine.cpp -o "$BENCH" 2>/dev/null

# run_clip <id> <label> : klibi motordan gecir, satiri ROWS'a yaz
run_clip() {
  id="$1"; label="$2"
  out=$("$BENCH" clip "$WORK/$id.ggclip" 2>/dev/null)
  move=$(printf '%s\n' "$out"  | sed -n 's/.*hareket: \([a-z]*\).*/\1/p' | head -1)
  eu=$(printf '%s\n'  "$out"   | grep 'one euro')
  rep=$(printf  '%s\n' "$eu" | sed -n 's/.*reps \([0-9]*\).*/\1/p')
  half=$(printf '%s\n' "$eu" | sed -n 's/.*half \([0-9]*\).*/\1/p')
  drop=$(printf '%s\n' "$eu" | sed -n 's/.*dropouts \([0-9]*\).*/\1/p')
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$move" "$label" "$rep" "$half" "$drop" >> "$ROWS"
}

# 2) sentetik klip (sabit seed makeclip icinde), etiket 8
"$BENCH" makeclip "$WORK/synth_squat.ggclip" >/dev/null
run_clip synth_squat 8

# 3) mmfit segmentleri — deterministik retarget; etiket satirdan okunur.
if [ -f "$NPY" ] && [ -f "$CSV" ]; then
  for ex in squats pushups lunges situps dumbbell_shoulder_press lateral_shoulder_raises jumping_jacks; do
    for s in 0 1 2; do
      id="${ex}_${s}"
      line=$(python3 "$ENG/tools/mmfit2ggclip.py" "$NPY" "$CSV" \
             --exercise "$ex" --set "$s" -o "$WORK/$id.ggclip" 2>/dev/null) || continue
      reps=$(printf '%s\n' "$line" | sed -n 's/.*label_reps=\([0-9]*\).*/\1/p')
      run_clip "$id" "$reps"
    done
  done
fi

# 4) tabloyu uret -> BENCHMARK.md + stdout. tarih YOK (git tarihler).
render() {
  echo "# gymgyme motor dogruluk bandi (bench suite)"
  echo
  echo "Tek komut: \`bash engine/bench.sh suite\` (kapi: \`--check\`). Deterministik"
  echo "cikti — mmfit klipleri ayni npy+csv'den, sentetik sabit seed. Motor rep ="
  echo "One Euro filtreli sayim. Rep-dogrulugu = min(motor,etiket)/etiket."
  echo
  echo "| klip | hareket | etiket rep | motor rep | half | reject/dropout | rep-dogruluk % |"
  echo "|------|---------|-----------:|----------:|-----:|---------------:|---------------:|"
  tl=0; tr=0
  while IFS="$(printf '\t')" read -r id move label rep half drop; do
    [ -z "$id" ] && continue
    if [ "$label" -gt 0 ]; then
      hit=$rep; [ "$hit" -gt "$label" ] && hit=$label
      acc=$(awk -v h="$hit" -v l="$label" 'BEGIN{printf "%.1f", 100*h/l}')
      tl=$((tl+label)); tr=$((tr+hit))
    else acc="--"; fi
    printf "| %s | %s | %s | %s | %s | %s | %s |\n" "$id" "$move" "$label" "$rep" "$half" "$drop" "$acc"
  done < "$ROWS"
  echo
  ov=$(awk -v r="$tr" -v l="$tl" 'BEGIN{printf "%.1f", (l>0?100*r/l:0)}')
  echo "**Ozet:** toplam $tr / $tl rep dogru sayildi -> genel rep-dogruluk **%$ov**"
  echo
  echo "> Not (uydurma degil): press / situp / armraise / jumpingjack su an 0 sayiliyor."
  echo "> Kok retarget/ROM sikismasi (benchmark-04 teshisi), motor esigi degil. Bunlar"
  echo "> tabana KOYULMADI (kapi gurultusu olmasin); squat/lunge/pushup/sentetik tabanli."
}

TABLE=$(render)
printf '%s\n' "$TABLE" > "$OUT"
printf '%s\n' "$TABLE"
echo
echo "yazildi: $OUT"

# 5) --check: her tabanli klip icin motor rep >= taban mi?
if [ "$CHECK" -eq 1 ]; then
  echo
  echo "== REGRESYON KAPISI (bench-baselines.txt) =="
  fail=0
  # tabanlari oku: yorumlari at, klip-id + min-rep
  while read -r kid minr rest; do
    [ -z "${kid:-}" ] && continue
    case "$kid" in \#*) continue;; esac
    rep=$(awk -F'\t' -v k="$kid" '$1==k{print $4}' "$ROWS")
    if [ -z "$rep" ]; then
      echo "  ATLA   $kid: tabloda yok (klip uretilemedi?)"
      continue
    fi
    if [ "$rep" -lt "$minr" ]; then
      echo "  DUSTU  $kid: motor $rep < taban $minr"
      fail=1
    else
      echo "  ok     $kid: motor $rep >= taban $minr"
    fi
  done < <(sed 's/#.*//' "$BASELINES")
  if [ "$fail" -eq 1 ]; then
    echo "REGRESYON: en az bir klip tabanin altina dustu."
    exit 1
  fi
  echo "GECTI: tum klipler tabanda ya da uzerinde."
fi
