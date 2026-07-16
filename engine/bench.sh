#!/usr/bin/env bash
# olcum bandi — derle ve kos. kullanim:
#   ./bench.sh              -> sentetik karsilastirma (ham/ema/one euro)
#   ./bench.sh clip x.ggclip -> gercek klip metrikleri
#   ./bench.sh suite         -> tum sentetik+mmfit klip dogruluk tablosu -> BENCHMARK.md
#   ./bench.sh suite --check -> ayni tablo + regresyon kapisi (taban altina duserse exit 1)
set -euo pipefail
cd "$(dirname "$0")"
if [ "${1:-}" = "suite" ]; then exec bash tools/bench-suite.sh "${2:-}"; fi
clang++ -std=c++17 -O2 -Wall bench.cpp coach_engine.cpp -o /tmp/coach_bench
if [ $# -eq 0 ]; then /tmp/coach_bench synth; else /tmp/coach_bench "$@"; fi
