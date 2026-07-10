# healthy living — community directory

A public-good website: a community-fed directory of home training resources — healthy-living articles, home workouts, pilates, ballet, yoga, gym, calisthenics, bodyweight. Anyone suggests a link or a move; Damla approves; the best-recommended rise up. Born from the home-workout iOS pivot (2026-07-10): the mission is ACCESS ("adult ballet barely exists even in Ankara"), not revenue.

## Non-negotiables (Damla, 2026-07-10)
- **No monetization by design.** No paywall, no ads, no tracking. The global "every product is born with a paywall" rule is explicitly suspended here — this one is hayır işi.
- **Low maintenance by design.** Community adds content; the only ongoing job is flipping `approved` in the Supabase dashboard. No admin UI, no accounts.
- Design: strong pink background, plain Arial, dense list, links in pink tones (darker = more recommended), NO borders anywhere ("içim daralmasın"), contributors as a flowing paragraph with per-name colors under "contributors (thank you!)". Deliberately raw — "bi güzellik beklentimiz yok".

## Status
2026-07-10: site built (index.html + styles.css + script.js + config.js, no build step), migration + 61 seed rows ready (16 articles from gunun-notu sources + 45 exercises, contributor "damla"). WAITING ON DAMLA: (1) paste supabase/migration.sql into the shared Supabase SQL editor, (2) create GitHub repo connection to Vercel, (3) buy domain + update canonical/og:url + sitemap.

## Architecture
- Static site, vanilla JS, Supabase REST directly from the browser (shared damlahelloworld project, table `hl_entries`).
- RLS: anon SELECT only `approved=true`; anon INSERT forced `approved=false, recommend_count=1`. Seed rows inserted as owner with `approved=true`.
- Moderation: Supabase dashboard. Duplicate URL suggestions → merge by bumping `recommend_count` (manual for now).
- Privacy: stores only what is published (title, url, description, display name). Form says the name will be published. No emails, no cookies, no analytics.

## Ideas
- One-click "+recommend" on existing entries (needs abuse protection — rate limit or edge function; decide later).
- Category pages / hash filters if the list gets huge.
- "submitted, awaiting review" counter for transparency.
