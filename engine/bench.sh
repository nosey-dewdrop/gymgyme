#!/usr/bin/env bash
# olcum bandi — derle ve kos. kullanim:
#   ./bench.sh              -> sentetik karsilastirma (ham/ema/one euro)
#   ./bench.sh clip x.ggclip -> gercek klip metrikleri
set -euo pipefail
cd "$(dirname "$0")"
clang++ -std=c++17 -O2 -Wall bench.cpp coach_engine.cpp -o /tmp/coach_bench
if [ $# -eq 0 ]; then /tmp/coach_bench synth; else /tmp/coach_bench "$@"; fi
