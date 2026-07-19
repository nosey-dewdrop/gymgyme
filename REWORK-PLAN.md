# gymgyme visual rework — task list (19 Jul 2026)

Goal: one calm white-lila editorial world across ALL pages. Each page keeps its
OWN copy (Damla's voice) — cut, never rewrite. Kill the cinema/marquee theater.
Motif: the dot (point cloud figure, dot cluster marks, dot leaders, button hover dots).

## Bugs Damla pointed at (index)
- [ ] B1  "the whole loop" collapses to the left rail, right half empty — fix alignment, use the width
- [ ] B2  "Open the camera. Do one rep." floats alone centered — anchor it, fill space
- [ ] B3  white text on lila buttons everywhere (some still dark/gray)
- [ ] B4  things that could sit side by side are stacked (how-cols, loop steps) — lay them out across
- [ ] B5  too much vertical air between blocks — tighten rhythm
- [ ] B6  Q&A reads as a generic lila card — make it not a card
- [ ] B7  voice inconsistent: index carries new copy, inner pages still marquee voice

## The real bug (mine)
- [ ] B8  SITE IS SPLIT: only index.html moved to the new world. moves/my-moves/
         my-program/coach/suggest/blog/patch-notes still load styles.css + marquee.css
         = pink/cinema theme. cherry var flipped to lila but .marquee/.sub-sign/
         shadows/awning/SEASON PASS structures remain.

## Plan (in order, no stopping to ask)

### Phase 1 — index polish (the page Damla is looking at)
1. [ ] fix .btn text to white on lila, consistent hover
2. [ ] lay how-grid as real columns across the width, not a stacked pair
3. [ ] loop: heading + steps share the row, steps fill the right
4. [ ] close block anchored (not lone-centered), tighten
5. [ ] cut vertical padding globally on this page, remove dead air
6. [ ] Q&A: kill the card look — hairline rows, italic pull-quote, no box/bg

### Phase 2 — shared world
7. [ ] move the index white-lila language into a single shared stylesheet the
       inner pages can use, OR strip marquee.css theater from inner pages and
       point them at the cleaned theme.css
8. [ ] kill .marquee / .sub-sign cinema headers on moves/my-program/etc,
       replace with the calm page header pattern, keep each page's own copy
9. [ ] remove decorative shadows, awning bulbs, potikare strip where they read cinema
10.[ ] the dot motif appears on every page (nav marker, section marks)

### Phase 3 — page transitions + mechanics
11.[ ] add smooth page transitions (view-transition / fade) so it feels like one app
12.[ ] every mechanic reachable and consistent: moves library, my-moves, program
       calendar (week/month/year), coach, suggest, blog, patch-notes
13.[ ] each page: alignment pass, no dead space, side-by-side where it fits

### Phase 4 — generic test (answer each before ship)
14.[ ] logo off: mistakable for another fitness/SaaS site? fix where yes
15.[ ] any leaked cliches (centered hero+3 cards, gray body, shadowed rounded
       boxes, chevron FAQ, gradient, stock icon)? remove
16.[ ] >=3 moments only this site has? if weak, deepen the dot motif
17.[ ] which 3 things to delete to improve? delete, then ship

## Guardrails
- CSP: external scripts must be files (script-src 'self'); inline canvas = js file.
- Preserve all JS-driven IDs: #directory #nav #cat-title #topSearch #searchDrop
  #movesBtn #greet #contributors #stat-articles #stat-workouts + inner page ids
  (#allMoves #keptList #weekView #monthView #yearView #cam ...). Do not rename.
- Keep script include order. Verify each phase live (Vercel deploy) before next.
- Voice: cut whole sentences, never reword. New microcopy imitates existing voice.
