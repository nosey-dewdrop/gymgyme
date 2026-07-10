# healthy living — community directory

A public-good website: a community-fed directory of home training resources — healthy-living articles, home workouts, pilates, ballet, yoga, gym, calisthenics, bodyweight. Anyone suggests a link or a move; Damla approves; the best-recommended rise up. Born from the home-workout iOS pivot (2026-07-10): the mission is ACCESS ("adult ballet barely exists even in Ankara"), not revenue.

## Non-negotiables (Damla, 2026-07-10)
- **No monetization by design.** No paywall, no ads, no tracking. The global "every product is born with a paywall" rule is explicitly suspended here — this one is hayır işi.
- **Low maintenance by design.** Community adds content; the only ongoing job is flipping `approved` in the Supabase dashboard. No admin UI, no accounts.
- Design: strong pink background, plain Arial, dense list, links in pink tones (darker = more recommended), NO borders anywhere ("içim daralmasın"), contributors as a flowing paragraph with per-name colors under "contributors (thank you!)". Deliberately raw — "bi güzellik beklentimiz yok".

## Status
2026-07-10 (late night, many live iterations with Damla): SITE NAME = **gymgyme**. Left sidebar (fixed, in the left whitespace): brand + tagline + "suggest something!" + my program + live article/workout counters. First visit = onboarding page (name + activities, localStorage); greet "hi, name!" afterwards. 89 seed rows bundled AND in migration.sql, all how-tos English, exercises tagged with equipment + muscle buckets. Category pages: equipment & muscle filters (site font convention, active = bigger). my program: reorder, remove, did it!/last-done, month calendar planner (drag & drop AND two-tap "plan → tap a day" for touch), day plans, mark-day-done, earlier/later months, print = formatted A4 sheet with how-tos. +recommend: heart button per entry, Supabase RPC (increment-only, security definer), one per browser via localStorage; only appears on live DB rows (id present). WAITING ON DAMLA (the only real blocker): (1) run supabase/migration.sql (now includes hl_recommend function), (2) Vercel, (3) domain → canonical/og/sitemap.

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
