#!/usr/bin/env bash
# gymgyme coach motor — NODE build, for the regression suite only.
#
# SAME source as build.sh (coach_engine.cpp + bindings.cpp), SAME behaviour —
# only the emscripten ENVIRONMENT changes so the module loads under node. this
# NEVER touches the production motor.js / motor.wasm the live site serves; it
# emits a separate motor.node.mjs + motor.node.wasm used only by tests/.
# invariant #9 (don't touch the live motor) is preserved: the engine logic is
# identical, this is a second target of the same code.
#
# requirement: emscripten (brew install emscripten).
set -euo pipefail
cd "$(dirname "$0")"

emcc bindings.cpp coach_engine.cpp \
  -O3 -std=c++17 --bind \
  -sMODULARIZE=1 -sEXPORT_ES6=1 -sEXPORT_NAME=createMotor \
  -sENVIRONMENT=node -sALLOW_MEMORY_GROWTH=1 \
  -sFILESYSTEM=0 \
  -sEXPORTED_FUNCTIONS=_malloc,_free \
  -sEXPORTED_RUNTIME_METHODS=HEAPF32 \
  -o motor.node.mjs

echo "ok: $(ls -la motor.node.mjs motor.node.wasm | awk '{print $9, $5}' | tr '\n' ' ')"
echo "note: node-only target for tests/regression. production motor.js/wasm untouched."
