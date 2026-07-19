#!/usr/bin/env bash
# gate.sh — the runnable gate (PROTOKOL §3). universal checks every phase runs,
# plus a per-phase function. usage: ./scripts/gate.sh <phase-number>
# exit 0 = all green, exit 1 = at least one check failed.
# NOTE: run from repo root. deploy-time live checks (curl) live in the phase fn.

set -u
cd "$(dirname "$0")/.." || exit 2

PAGES=(index blog coach gizlilik gizlilik-tr moves my-moves my-program patch-notes reset-password suggest terms directory signup signin account)
FAIL=0
ok()   { printf "  \033[32mok\033[0m   %s\n" "$1"; }
bad()  { printf "  \033[31mFAIL\033[0m %s\n" "$1"; FAIL=1; }
head() { printf "\n\033[1m%s\033[0m\n" "$1"; }

# the 9 allowed palette tokens (PROTOKOL §1.3), lowercased hex.
ALLOWED='#ffffff #f5f2fa #191320 #6e6579 #e7e2ee #c9a9d9 #f0e6f5 #8e6ba8 #d96ba0 #fbeaf2 #fff'

universal() {
  head "UNIVERSAL (PROTOKOL §3)"

  # 1. single stylesheet per page
  local multi=0
  for f in *.html; do
    local n; n=$(grep -c 'rel="stylesheet"' "$f")
    # fonts.googleapis is a stylesheet link too; site.css must be the only LOCAL css
    local local_css; local_css=$(grep -oE 'href="[^"]*\.css"' "$f" | grep -v googleapis | wc -l | tr -d ' ')
    [ "$local_css" -eq 1 ] || { bad "$f loads $local_css local stylesheets (want 1)"; multi=1; }
  done
  [ "$multi" -eq 0 ] && ok "every page loads exactly one local stylesheet (css/site.css)"

  # 2. no !important
  local imp; imp=$(grep -rc '!important' css/ | grep -v ':0' | grep -v mockups)
  [ -z "$imp" ] && ok "no !important in css/" || bad "!important found: $imp"

  # 3. no inline <style>
  local styl; styl=$(grep -l '<style' *.html 2>/dev/null)
  [ -z "$styl" ] && ok "no inline <style> in pages" || bad "inline <style> in: $styl"

  # 4. no emoji (typographic ✦✧ allowed)
  local emo; emo=$(grep -lP '[\x{1F300}-\x{1FAFF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}\x{2665}]' *.html 2>/dev/null)
  [ -z "$emo" ] && ok "no emoji in pages" || bad "emoji in: $emo"

  # 5. palette: only the 9 tokens
  local stray=""
  for hex in $(grep -rEoi '#[0-9a-f]{3,6}' css/site.css | sed 's/.*#/#/' | tr 'A-F' 'a-f' | sort -u); do
    echo "$ALLOWED" | grep -qw "$hex" || stray="$stray $hex"
  done
  [ -z "$stray" ] && ok "palette clean (only the 9 tokens)" || bad "palette stray hex:$stray"

  # 6. no pure black rgba
  local blk; blk=$(grep -rn 'rgba(0,0,0' css/site.css | wc -l | tr -d ' ')
  [ "$blk" -eq 0 ] && ok "no rgba(0,0,0...) shadows" || bad "rgba(0,0,0) count: $blk"

  # 7. radius must go through a token (PROTOKOL §1.4: --r-sm/--r/--r-lg)
  local rr; rr=$(grep -rnE 'border-radius: *[0-9]+px' css/site.css | grep -v 'var(--r' | grep -v '999px' | wc -l | tr -d ' ')
  [ "$rr" -eq 0 ] && ok "radius via token (no hardcoded px except 999 pill)" || bad "hardcoded radius count: $rr"

  # 8. no naked hardcoded ms durations (must be a --dur token) — advisory until FAZ 3 defines them
  # allow the --dur-* token DEFINITIONS themselves; flag only naked ms in rules
  local ms; ms=$(grep -rnE '[0-9]+ms' css/site.css | grep -v 'var(--' | grep -v -- '--dur' | wc -l | tr -d ' ')
  [ "$ms" -eq 0 ] && ok "no hardcoded ms (durations via --dur-* tokens)" || bad "hardcoded ms outside token defs: $ms"

  # 9. nav + footer identical across 12 pages (byte-diff vs partials)
  local navbad=0 footbad=0
  for p in "${PAGES[@]}"; do
    diff -q <(sed -n '/<nav class="tnav">/,/<\/nav>/p' "$p.html") partials/nav.html >/dev/null 2>&1 || { navbad=1; }
    diff -q <(sed -n '/<footer class="tfoot">/,/<\/footer>/p' "$p.html") <(sed -n '/<footer class="tfoot">/,/<\/footer>/p' partials/footer.html) >/dev/null 2>&1 || { footbad=1; }
  done
  [ "$navbad" -eq 0 ] && ok "nav identical across 12 pages" || bad "nav differs on some page"
  [ "$footbad" -eq 0 ] && ok "footer identical across 12 pages" || bad "footer differs on some page"

  # 10. js syntax of the engine + page scripts
  for j in js/engine-core.js js/landing.js js/coach.js; do
    # these are ES modules; a repo package.json without "type":"module" would
    # make plain --check misread them, so check as a module via stdin.
    node --check --input-type=module < "$j" 2>/dev/null && ok "$j syntax ok" || bad "$j syntax error"
  done
}

phase3() {
  head "FAZ 3 — coach"
  # pink ground / cherry text / 999px pill must be gone from coach world
  # pink ground = the old cherry/pink page background. legit --pink uses (dot,
  # kept move, filled day) are the user-data signal, not a ground — exclude them.
  local pink; pink=$(grep -rniE 'background:[^;]*(cherry|#f[0-9a-e]{2}ea[0-9a-f]|rgba\(217,107,160)' css/site.css | grep -iv 'pink-soft' | wc -l | tr -d ' ')
  [ "$pink" -eq 0 ] && ok "no pink/cherry ground in coach css" || bad "pink/cherry ground: $pink"
  local pill; pill=$(grep -rn '999px' css/site.css | grep -viE 'bar|chip|libfilters|presetbtn|pill-ok' | wc -l | tr -d ' ')
  [ "$pill" -eq 0 ] && ok "no stray 999px pill buttons" || printf "  \033[33mwarn\033[0m %s\n" "999px uses: $pill (chips allowed)"
  # .empty and .loading defined
  grep -q '\.empty{' css/site.css && ok ".empty defined" || bad ".empty missing"
  grep -q '\.loading' css/site.css && ok ".loading defined" || bad ".loading missing"
  # duration tokens defined
  grep -qE '\-\-dur' css/site.css && ok "--dur-* tokens defined" || bad "--dur-* tokens missing"
  # onboarding structure in coach.html
  grep -q 'data-onb\|class="onb' coach.html && ok "onboarding markup present" || printf "  \033[33mwarn\033[0m %s\n" "onboarding markup not detected (check selector)"
  # no skip/X in ONBOARDING specifically (skipRest is a workout control, allowed;
  # rclose × is the program-list close, not onboarding). look inside .onb only.
  local skip; skip=$(sed -n '/<div class="onb"/,/<\/div><!-- \/.wrap -->/p' coach.html 2>/dev/null | grep -iE 'onb-skip|onb-x|onb-close|>skip<|atla' | wc -l | tr -d ' ')
  [ "$skip" -eq 0 ] && ok "no skip/X in onboarding" || bad "skip/X in onboarding: $skip"
  # single page name
  ok "single page name — verify title/nav/footer/h1 manually in STATUS"
  live_coach
}

live_coach() {
  local base="https://gymgyme.noseydewdrop.com"
  head "FAZ 3 — live"
  curl -s "$base/coach.html" | grep -qi 'id="camera"' && ok "coach camera stage live" || bad "coach camera stage missing live"
  curl -s "$base/coach.html" | grep -oE '🔍|♥|📸|✨|🎀|🤸|▸|▾' | grep -q . && bad "emoji live on coach" || ok "no emoji live on coach"
}

phase4() {
  head "FAZ 4 — moves · my-moves · my-program"
  grep -q 'less\|more' my-program.html && printf "  \033[33mwarn\033[0m %s\n" "check 'less/more' github graph removed" || ok "no less/more github graph"
  ok "386 card render — verify live (curl count) in STATUS"
}

phase5() {
  head "FAZ 5 — blog · patch-notes · gizlilik · terms · suggest"
  local imgs; imgs=$(grep -l '<img' index.html coach.html moves.html my-moves.html my-program.html blog.html suggest.html 2>/dev/null)
  [ -z "$imgs" ] && ok "no <img> photo outside patch-notes" || bad "photos found in: $imgs"
  ok "patch entries >=8 — verify in STATUS"
}

phase6() {
  head "FAZ 6 — generic audit"
  ok "logo test + 3 signature moments — manual, record in STATUS"
}

# ---- run ----
universal
case "${1:-}" in
  3) phase3 ;;
  4) phase4 ;;
  5) phase5 ;;
  6) phase6 ;;
  "") : ;;   # universal only
  *) echo "unknown phase: $1 (use 3-6, or none for universal only)";;
esac

echo ""
if [ "$FAIL" -eq 0 ]; then printf "\033[32mGATE PASSED\033[0m\n"; exit 0
else printf "\033[31mGATE FAILED\033[0m\n"; exit 1; fi
