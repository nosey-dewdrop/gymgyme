# healthy living — community directory

A public-good website: a community-fed directory of home training resources — healthy-living articles, home workouts, pilates, ballet, yoga, gym, calisthenics, bodyweight. Anyone suggests a link or a move; Damla approves; the best-recommended rise up. Born from the home-workout iOS pivot (2026-07-10): the mission is ACCESS ("adult ballet barely exists even in Ankara"), not revenue.

## Non-negotiables (Damla, 2026-07-10)
- **No monetization by design.** No paywall, no ads, no tracking. The global "every product is born with a paywall" rule is explicitly suspended here — this one is hayır işi.
- **Low maintenance by design.** Community adds content; the only ongoing job is flipping `approved` in the Supabase dashboard. No admin UI, no accounts.
- Design: strong pink background, plain Arial, dense list, links in pink tones (darker = more recommended), NO borders anywhere ("içim daralmasın"), contributors as a flowing paragraph with per-name colors under "contributors (thank you!)". Deliberately raw — "bi güzellik beklentimiz yok".

## Status
2026-07-10 (late night, many live iterations with Damla): SITE NAME = **gymgyme** (lowercase brand, top left; the name lives on as the website). Big clickable "suggest something" sits top right on every page ("görsünler kaçmasın"); nav has categories + my program only. Onboarding greet: asks name + interest once (localStorage), greets "hi, name!", interest becomes default category; "not you?" resets. Search was built then REMOVED by Damla's call. Seed now 89 rows bundled in seed.js AND in migration.sql (16 articles, 20 pilates, 15 home-workouts, 10 gym, 8 ballet, 8 yoga, 6 calisthenics, 6 bodyweight — ballet/yoga/calisthenics/bodyweight sourced 10 Tem night, all with source URLs; household strength remapped to gym). Moves show HOW-TO on hover (title tooltip; original 45 have Turkish cues for now, 28 new ones English). Move identity = title+url (several NHS moves share one URL). Layout: h1/tag left-aligned, contributors + footer centered and pinned to bottom, no em dashes anywhere, no borders. WAITING ON DAMLA: (1) run supabase/migration.sql, (2) Vercel, (3) domain (then canonical/og/sitemap update).

## Architecture
- Static site, vanilla JS, Supabase REST directly from the browser (shared damlahelloworld project, table `hl_entries`).
- RLS: anon SELECT only `approved=true`; anon INSERT forced `approved=false, recommend_count=1`. Seed rows inserted as owner with `approved=true`.
- Moderation: Supabase dashboard. Duplicate URL suggestions → merge by bumping `recommend_count` (manual for now).
- Privacy: stores only what is published (title, url, description, display name). Form says the name will be published. No emails, no cookies, no analytics.

## Ideas
- One-click "+recommend" on existing entries (needs abuse protection — rate limit or edge function; decide later).
- Category pages / hash filters if the list gets huge.
- "submitted, awaiting review" counter for transparency.
