#!/usr/bin/env bash
# coach motorunun saf çekirdek testleri — tarayıcı/wasm gerekmez, sadece clang++.
set -euo pipefail
cd "$(dirname "$0")"
clang++ -std=c++17 -O2 -Wall test.cpp coach_engine.cpp -o /tmp/coach_test
/tmp/coach_test
