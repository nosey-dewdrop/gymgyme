#!/usr/bin/env bash
# gymgyme coach motor — C++ → WebAssembly derleme.
# Gereksinim: emscripten (brew install emscripten). Çıktı: motor.js + motor.wasm.
# Bu iki dosya repoya commit'lenir; site "build yok" statik kalır, sadece motoru derleriz.
set -euo pipefail
cd "$(dirname "$0")"

emcc motor.cpp -O3 -std=c++17 --bind \
  -sMODULARIZE=1 -sEXPORT_ES6=1 -sEXPORT_NAME=createMotor \
  -sENVIRONMENT=web -sALLOW_MEMORY_GROWTH=1 \
  -o motor.js

echo "ok: motor.js + motor.wasm built"
