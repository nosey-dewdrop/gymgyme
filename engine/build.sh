#!/usr/bin/env bash
# gymgyme coach motor — C++ → WebAssembly derleme.
#
# Saf çekirdek (coach_engine.cpp) + web adaptörü (bindings.cpp) birlikte derlenir.
# Çıktı: motor.js (küçük yükleyici) + motor.wasm (asıl ikili motor). İkisi repoya
# commit'lenir; site "build adımı yok" statik kalır, sadece motoru derleriz.
#
# Gereksinim: emscripten (brew install emscripten).
set -euo pipefail
cd "$(dirname "$0")"

emcc bindings.cpp coach_engine.cpp \
  -O3 -std=c++17 --bind \
  -sMODULARIZE=1 -sEXPORT_ES6=1 -sEXPORT_NAME=createMotor \
  -sENVIRONMENT=web -sALLOW_MEMORY_GROWTH=1 \
  -sFILESYSTEM=0 \
  -o motor.js

echo "ok: $(ls -la motor.js motor.wasm | awk '{print $9, $5}' | tr '\n' ' ')"
