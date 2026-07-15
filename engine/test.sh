#!/usr/bin/env bash
# coach motorunun saf çekirdek testleri — tarayıcı/wasm gerekmez, sadece clang++.
set -euo pipefail
cd "$(dirname "$0")"
clang++ -std=c++17 -O2 -Wall test.cpp coach_engine.cpp -o /tmp/coach_test
/tmp/coach_test
# saf CV modulleri ayri test edilir (motor cekirdegi, wasm gerekmez)
clang++ -std=c++17 -O2 -Wall test_kalman.cpp -o /tmp/kalman_test
/tmp/kalman_test
clang++ -std=c++17 -O2 -Wall test_ik.cpp -o /tmp/ik_test
/tmp/ik_test
