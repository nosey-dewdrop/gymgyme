# healthy living — community directory

A public-good website: a community-fed directory of home training resources — healthy-living articles, home workouts, pilates, ballet, yoga, gym, calisthenics, bodyweight. Anyone suggests a link or a move; Damla approves; the best-recommended rise up. Born from the home-workout iOS pivot (2026-07-10): the mission is ACCESS ("adult ballet barely exists even in Ankara"), not revenue.

## Direction change (Damla, 2026-07-13): backend is now IN
Damla: "local olmaz, database gidelim." The coach now has real accounts + a database (shared damlahelloworld Supabase, project ref xjtmqncfhuidctxgthhv). This SUPERSEDES the SUPABASESIZ / no-backend non-negotiable below for the coach. The camera/video still never leaves the device (KVKK); only the workout NUMBERS (reps, scores, dates, move) sync to the account. Accounts open the door to a money model on top (not yet decided/built). The directory link-list itself is still static for now; migrating its my-program/calendar to accounts is the next step.
- Auth = email + password, shared across the damlahelloworld ecosystem. Tables gg_ prefixed. RLS: each user only their own rows. Anon key is public (client-side, RLS-protected). Run supabase/migration.sql in the shared project's SQL editor.
- Privacy/consent shipped same session: gizlilik.html + consent line on the auth bar + honest copy (no more "nothing is saved").

## Earlier non-negotiables (Damla, 2026-07-10) — kept for the directory, superseded for the coach
- **No monetization by design.** No paywall, no ads, no tracking. (Superseded intent: accounts now enable a future money model; nothing built yet.)
- **Low maintenance by design, and SUPABASESIZ (Damla, 2026-07-10 morning).** The directory site is static files; suggestions arrive as pre-filled mails merged into seed.js. (SUPERSEDED for the coach, which now uses Supabase.)
- Design: strong pink background, plain Arial, dense list, links in pink tones (darker = more recommended), NO borders anywhere ("içim daralmasın"), contributors as a flowing paragraph with per-name colors under "contributors (thank you!)". Deliberately raw — "bi güzellik beklentimiz yok".

## Status
2026-07-10 (late night, many live iterations with Damla): SITE NAME = **gymgyme**. Left sidebar (fixed, in the left whitespace): brand + tagline + "suggest something!" + my program + live article/workout counters. First visit = onboarding page (name + activities, localStorage); greet "hi, name!" afterwards. 89 seed rows bundled AND in migration.sql, all how-tos English, exercises tagged with equipment + muscle buckets. Category pages: equipment & muscle filters (site font convention, active = bigger). my program: reorder, remove, did it!/last-done, month calendar planner (drag & drop AND two-tap "plan → tap a day" for touch), day plans, mark-day-done, earlier/later months, print = formatted A4 sheet with how-tos. +recommend: heart button per entry, Supabase RPC (increment-only, security definer), one per browser via localStorage; only appears on live DB rows (id present). WAITING ON DAMLA (the only real blocker): (1) run supabase/migration.sql (now includes hl_recommend function), (2) Vercel, (3) domain → canonical/og/sitemap.

## Status update (supabasesiz + polish)
2026-07-10 morning: Supabase fully removed (config.js, migration, RPC, remote fetch, recommend hearts). Suggest form now composes a mailto to Damla with all fields. Mobile polish pass: responsive layout under 700px (sidebar flows, inline counters, fluid calendar, bigger touch targets). TO GO LIVE: connect repo to Vercel + domain. Nothing else.

## COACH engine (build-in-public, started 2026-07-12)
The "slop -> engine" upgrade: an on-device camera coach that watches home workouts, reads joints and (soon) counts reps + checks form. Turns the directory from a link list into a real product. On-device (MediaPipe pose + our own motor, both wasm in the browser) so it does NOT break "no backend" and stays KVKK-clean: the camera image never leaves the device.

- **Engine is C++ -> WebAssembly**, not js. Pure framework-free core `engine/coach_engine.hpp/.cpp` (moves defined as data via `MoveSpec`) + thin `engine/bindings.cpp` (emscripten). Build `engine/build.sh` -> `engine/motor.js` + `engine/motor.wasm` (committed). Native tests `engine/test.sh` (no browser). Glue only in `js/coach.js`; page split html/css/js on purpose.
- Page: `coach.html` (unlinked, robots noindex until proven). 19-stage roadmap + narrative devlog in `BUILD-LOG.md` (Damla voices it for reels; each step is its own commit).
- Security: mediapipe + model vendored under `vendor/` (no runtime cdn), tight CSP + Permissions-Policy (`vercel.json` + meta). Perf: landmarks pass by pointer through the wasm heap.

Roadmap (0-18): ALL DONE, including 18 launch (2026-07-13, Damla: "yayınla yayınla sen durma").

## Status update (2026-07-13 evening — LIVE at gymgyme.damlahelloworld.com)
Big day, all pushed and deployed (Vercel auto-deploys on push, domain is bound):
- WORDING: user-facing "coach" -> "personal trainer" (urls unchanged).
- PWA: manifest + icons (PIL, pink+arial "gg") + sw.js (precache, vendor/engine cache-first; BUMP CACHE version in sw.js whenever vendor/ or engine/ change — currently v3).
- SHIP-CHECK ran (report: reports/2026-07-13-gymgyme-ship-check.md). 4 blockers fixed same day: honest sync (summary waits for insert result; failed rows queue in hl_sync_queue, flush on online/sign-in), password reset (forgot link + reset-password.html), "your workouts" history section (DB last 30 signed in, device otherwise), first-use consent gate before camera (gg_consent_v1).
- LEGAL BAND: gizlilik-tr.html (KVKK in Turkish), terms.html, honest gizlilik copy, sitewide CSP + frame-ancestors (vercel.json), in-app full account deletion (delete_me RPC in migration.sql, double-confirm button).
- TRADEMARK: "gymgyme" clean in US (justia/trademarkia) AND TURKPATENT ("sonuç bulunamadı", Damla verified). Note: @gymgymie is a 63k fitness creator (handle confusion risk, not legal).
- ENGINE BAND (Damla feedback after first real use): body calibration (opt-in, learns limb ratios ~2s then locks on and rejects mismatched reads), spike gate (single-frame teleports swallowed), per-move framing cues (push-up works without legs in frame). emaAlpha 0.5, match tolerance 0.30.
- UI BAND (Damla's explicit order): white soft cards on pink, huge "🎀 personal trainer ✨" title, "meet the engine" onboarding card, MANDATORY "step 1 - your session" before the camera area appears, real buttons.
- MOVES: 6 -> 14 (sumo squat, side lunge, kneeling push-up, glute kickback, bird dog, calf raise, jumping jack, arm raise) — all pure MoveSpec data. 92 native tests green.
- Damla's account works in prod (signup + auth bar verified live); camera worked after permission.

OPEN / NEXT:
- Damla to verify on phone: PWA install (Safari share -> add to home screen), offline open, camera in standalone; and add live reset-password.html url to Supabase Auth redirect allowlist; check "Confirm email" setting.
- Damla judgement pending on new UI + calibration feel ("hassas değil" was the complaint; tuned, needs her camera test).
- Engine next: "hold" capability for plank/wall sit type moves, then library grows toward "all moves" (data-only). Detail mode idea (per-frame readings panel) approved concept, not built.
- Product decisions open: money model (none by new direction), physio B2B pivot (Damla thinking), progression insights on history.
- Ship-check leftovers: signup autocomplete nuance, sw CACHE bump discipline (manual).

## Launch (first users - Damla owns content/outreach)
Suggested channels when live: r/xxfitness + r/bodyweightfitness (helpful-tool framing, not promo), Turkish fitness Instagram/TikTok ("Ankara'da yetişkin balesi yok diye yaptık" story), ekşi sözlük (evde spor başlıkları), Bilkent groups. The pitch is the mission: free forever, no ads, no accounts, everyone adds. The "contributors (thank you!)" wall is the growth loop: people come back to see their name.

## Architecture
- Static site, vanilla JS, Supabase REST directly from the browser (shared damlahelloworld project, table `hl_entries`).
- RLS: anon SELECT only `approved=true`; anon INSERT forced `approved=false, recommend_count=1`. Seed rows inserted as owner with `approved=true`.
- Moderation: Supabase dashboard. Duplicate URL suggestions → merge by bumping `recommend_count` (manual for now).
- Privacy: stores only what is published (title, url, description, display name). Form says the name will be published. No emails, no cookies, no analytics.

## Ideas
- One-click "+recommend" on existing entries (needs abuse protection — rate limit or edge function; decide later).
- Category pages / hash filters if the list gets huge.
- "submitted, awaiting review" counter for transparency.
