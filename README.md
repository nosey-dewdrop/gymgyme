# healthy living

A community-curated directory of home training resources: healthy-living articles, home workouts, pilates, ballet, yoga, gym, calisthenics, bodyweight.

Studios are expensive or simply don't exist where you live. Moving at home shouldn't require anything but a wall, a chair and a good link. Anyone can suggest a link or a move; suggestions appear after human review; the most-recommended rise up.

**Free, no ads, no tracking, no accounts, forever.**

## Stack
Static HTML/CSS/JS (no build step) + Supabase (one table, RLS-guarded anonymous suggestions). Hosted on Vercel.

## Contributing
Use the suggestion form on the site — that's the whole point. Your display name is published on the page with the entry; use a nickname if you prefer.

## Setup notes
- `supabase/migration.sql` — table, RLS policies and seed rows; paste into the Supabase SQL editor once.
- `config.js` — Supabase URL + anon key (public by design, RLS protects everything).
- After the domain is attached: update canonical/og:url in `index.html` and add robots.txt + sitemap.xml with the real domain.
