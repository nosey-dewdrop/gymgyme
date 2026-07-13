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

Roadmap (0-18): DONE 0-10, 11 deep link (?move=), 12 move-rule data, 13 sets/rest, 14 session summary, 15 into my-program (session logged + calendar day), 16 tone/a11y, 17 mobile/perf. LEFT: 18 launch only, held for Damla's explicit "yayınla".
The whole engineering band is done: the engine holds a full workout (sets, timed rest, completion + summary), is accessible and mobile/battery aware, opens on a specific move by url, and writes each session into the shared gymgyme calendar. 76 native tests. Stage 18 (link into nav, drop noindex, first-use consent line) is outward-facing and semi-irreversible, so it waits until Damla opens the coach in dev and says publish.

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
