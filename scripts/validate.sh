#!/usr/bin/env bash
# validate.sh — the motor validation suite (FAZ 7). two speeds:
#   ./scripts/validate.sh quick   native unit tests + node regression (every commit)
#   ./scripts/validate.sh full    quick + the whole labelled corpus (nightly)
# exit non-zero on any regression. invariant #11: the motor is not deployed
# unless this passes.
set -uo pipefail
cd "$(dirname "$0")/.."
MODE="${1:-quick}"
FAIL=0

echo "== native unit tests (engine/test.sh) =="
if [ -f engine/test.sh ]; then
  bash engine/test.sh 2>&1 | tail -3 || FAIL=1
else
  echo "  (engine/test.sh missing — skipped)"
fi

echo ""
echo "== node regression (tests/regression) =="
if [ ! -f engine/motor.node.mjs ]; then
  echo "  building node motor target first..."
  bash engine/build-node.sh >/dev/null 2>&1 || { echo "  build-node failed"; FAIL=1; }
fi
node tests/regression/run.mjs || FAIL=1

if [ "$MODE" = "full" ]; then
  echo ""
  echo "== full corpus =="
  # run.mjs already walks the whole corpus; 'full' is a label for nightly CI.
  echo "  (corpus walked by run.mjs above)"
fi

echo ""
if [ "$FAIL" -eq 0 ]; then echo "VALIDATE PASSED ($MODE)"; exit 0
else echo "VALIDATE FAILED ($MODE)"; exit 1; fi
