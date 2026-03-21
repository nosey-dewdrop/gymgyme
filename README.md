# GymGyme 🌱🎀
### *a gym tracker that actually understands atrophy, progress, and the pain of skipping arm day*
A workout tracker + program builder that watches what you *actually* do, warns you about what you're neglecting, and builds programs from your real exercise library. Men only exercise upper body and women (me) only train legs and glutes. I looked at the mirror last week and my legs are atrophicated and glutes not so impressive at all. My upper body is a full disaster. Looks like pretzel...

---

## The Problem (Why This Exists)

1. **The Leg Day Loop**: I train legs every single session and lose track of *how long* I've been doing only legs. Meanwhile my arms are literally atrophying. No app tells me "hey, you haven't touched your shoulders in 3 months." And I forget them. 

2. **Motivation Drain**: I don't always want to go to the gym. Seeing stagnation (or worse, regression) without context makes it worse. Seeing *progress* makes it better.

3. **Memory is Garbage**: What was my leg press PR? How many reps? At what weight? Gone. Lost to the void. Every session starts from zero because I don't remember where I left off. For insance, 2 years ago I had 80 kgs of leg press. Now, I can't do 60. I can't believe this is true. Hallucinator...

4. **Atrophy is Real and Brutal**: 5 days off can undo 5 months of work. The app needs to understand this. If I haven't trained a muscle group in X days, it should scream at me. Atrophy tracking is not optional - it's the core feature.

---

## App Structure & Navigation

### Navigation: Bottom tab bar (2 tabs) + top-right settings gear

| Tab | Screen | Description |
|-----|--------|-------------|
| **My Exercises** (Home) | Exercise list + atrophy status + active challenges | First thing the user sees. The nerve center. |
| **Programs** | Program builder + saved programs | Swipe right from home. Create, edit, manage workout programs. |

**Settings** lives as a gear icon in the top-right corner of the nav bar — NOT as a tab. Keeps the bottom bar clean.

A third flow — **Exercise Search/Discovery** — is accessed from a search bar within the exercises or programs screens, not as its own tab.

---

## Screen Details

### Screen 1: My Exercises (Home)

This is the first thing the user sees when opening the app. It answers: "What have I been doing, what am I neglecting, and where did I leave off?"

#### Top Section — Status Banner
```
You haven't worked out in: 3 days
```
Simple. Guilt-inducing. Effective.

#### Active Challenges
Ongoing goals displayed as visual streaks:
```
21-Day Gym Challenge:  ██░██░███░░... (14/21)
```
- Each block = 1 day. Filled = went to gym. Empty = missed.
- Users can see their streak at a glance.
- Challenges are user-created (e.g., "30 days no skip", "train upper body 3x/week for a month").

#### Exercise List
Each exercise card shows:
```
Leg Press / last: 3 days ago / 65 kg          #legs
Shoulder Pulldown / last: 3 months ago / 15 kg (7.5×2)  #shoulders
Bicep Curl / never logged / —                 #arms
```

**Sorting logic (critical UX decision):**
1. Exercises with 0 sessions logged → pinned to the bottom (you added them but never did them)
2. Remaining exercises sorted by most recently performed -> least recently performed (top = did yesterday, bottom = did 3 months ago)

This means the stuff you're neglecting naturally sinks toward the bottom — right above the "never done" pile. Atrophy becomes visible through sort order alone.

**Each exercise card is tappable** → opens exercise detail view with:
- Full progress history (weight × reps over time)
- PR records
- Frequency chart (how often you train this)
- Log new session button

**Tags** (#legs, #shoulders, #chest) are the muscle group labels. Tappable to filter.

#### Floating Action Button: + Add Exercise
- Name it
- Assign muscle group (from predefined list or custom)
- Set equipment type (machine w/ levels, free weight kg/lbs, bodyweight, cable)

---

### Screen 2: Programs (swipe right)

#### Program List
Shows saved programs with quick stats:
```
Full Body Fridays — 8 exercises — ~55 min
Upper Body Blitz — 6 exercises — ~40 min
```

#### Create New Program Flow:
1. **Name it** — free text
2. **Select target regions** — Full Body / Upper / Lower / Push-Pull-Legs / Custom selection of muscle groups
3. **How many workouts?** — exercises per session
4. **Duration** — how long will you follow this? 1 week / 2 weeks / 1 month / ongoing
5. **Auto-populate from your exercise library:**
   - App pulls exercises matching the selected regions from YOUR logged exercises
   - If you selected "Upper Body" but have zero upper body exercises → **"Can't build this program — you have no upper body exercises logged! Add some first or search the exercise database."**
   - User can reorder, swap, remove, add exercises
6. **Set targets per exercise** — target sets × reps, target weight
7. **Gap detection (post-creation):**
   - "⚠️ This program has no shoulder or tricep work. Want to add exercises for these groups?"
8. **Session duration estimate:**
   - Calculated from: (total sets × avg set duration) + (total sets × avg rest time) + warm-up buffer
   - "Estimated session time: ~45 min (12 sets, avg 2 min rest)"
   - User can adjust their default rest time in settings

#### Active Program View:
- Today's session highlighted
- Tap exercise → log your set (weight + reps)
- Progress bars showing completion

---

### Exercise Search & Discovery (accessed from search bar)

A search interface for finding new exercises to add to your library.

**Search by muscle group tag:**
- Type `#chest` or `chest` → shows all chest exercises from the database
- Type `#legs` → leg exercises
- Free text search also works: "dumbbell", "cable", "bodyweight"

**Each search result shows:**
- Exercise name
- Target muscle group + secondary muscles
- Equipment needed
- Difficulty level
- How to perform it (description / form guide)
- What it's good for

**Action:** "Add to My Exercises" button on each result → adds it to your exercise library, ready to log and include in programs.

**Data source:** Exercise API (ExerciseDB, wger, or similar) + AI-assisted descriptions for form guidance and exercise recommendations. If the user searches something vague like "I want bigger arms", AI can suggest a curated list.

---

### Settings (gear icon, top-right)

- **Profile:** name, height, weight, age
- **Units:** kg/lbs, cm/ft
- **Body Metrics:**
  - BMI display with disclaimer: *"BMI is just a formula. It doesn't distinguish muscle from fat. 1 kg of fat is the size of a bottle. 1 kg of muscle is the size of a fist. What matters is your muscle-to-fat ratio, not a number."*
  - Weight tracking over time
- **Rest time default** (used for session duration estimates)
- **Notification preferences** (atrophy warnings, challenge reminders)
- **Theme** (future: doodle, pixel art, minimal)

---

## Core Features Deep Dive

### 1. Exercise Library (User-Driven + API Search)

**User adds exercises they know and do.** Each exercise has:
- Name (e.g., "Leg Press")
- Target muscle group / body region (e.g., "Legs — Quads")
- Equipment type (machine level vs. free weight lbs/kg)
- Last session date (auto-updated)
- Last recorded weight/level + reps (auto-updated)

**Progress tracking per exercise:**
- `leg press / 3 days ago / 65 kg / 4×12`
- `shoulder pulldown / 3 months ago / 15 kg (7.5×2) / 3×10`
- Visual timeline: weight over time, rep PRs, frequency graph

### 2. Atrophy Tracker (THE Core Feature)

For each muscle group, track days since last trained. Color-coded urgency:
- 🟢 Trained within 3 days
- 🟡 5–7 days — caution
- 🔴 7+ days — atrophy warning
- ⚫ 30+ days — "this muscle group is dying"

Atrophy is surfaced in multiple ways:
- Exercise list sort order (neglected stuff sinks)
- Muscle group tags change color based on status
- Settings/dashboard can show a full body atrophy map
- Push notification potential: "You haven't trained shoulders in 14 days"

### 3. Program Builder

See Screen 2 above for the full flow. Key principles:
- **Only builds from exercises you've actually logged.** No ghost exercises.
- **Gap detection is mandatory.** Always tells you what's missing.
- **Duration estimates** so you know if your session fits your schedule.

### 4. Body Metrics (Honest Edition)

- Input: height, weight, age
- BMI calculated **with prominent disclaimer** about muscle vs. fat
- Weight tracking over time (optional, not pushed)
- Future: body fat %, body measurements

### 5. Nutrition Tracker (V2 — Simple, Not MyFitnessPal)

- Log meals (what you ate, roughly when)
- App learns eating patterns over time (average meal times from log entries)
- Weekly report: rough calorie estimate, deficit/surplus indicator, meal timing patterns, weekend vs. weekday comparison
- Water intake reminder (subtle, doesn't break simplicity)
- **Not a food scale app** — keep it usable

### 6. Meal Plan Builder (V2)

- Create weekly meal plans
- Show what you're eating mapped to days
- Weekend rest day / cheat day awareness
- Calorie goal visualization

---

## UI / Aesthetic Direction

### Primary Vision: **Doodle / Apple Notes / Hand-drawn**
- Feels like someone drew the app in a notebook
- Sketch-style borders, hand-drawn icons, paper texture backgrounds
- Warm, analog, non-intimidating — not a bodybuilder app

### Asset Strategy (Critical for Architecture):
**Every visual element must be swappable as an asset:**
- Logo → asset
- Icons → assets  
- Buttons → can be asset-based
- Background textures → assets
- Muscle group illustrations → assets

This is non-negotiable because:
- Pixel art theme is a future possibility (budget permitting)
- Procreate-illustrated assets could replace defaults later
- The codebase must treat ALL visuals as theme-able, replaceable resources
- Code with this in mind from day one — no hardcoded SVGs buried in views

### Design Principles:
- Simple > Cluttered (always)
- Information density through smart defaults, not more screens
- The home screen exercise list IS the atrophy dashboard — no separate screen needed
- Progress charts should feel motivating, not clinical
- The doodle aesthetic should make the gym feel less intimidating

---

## Social Features (V3+)

- **GymRat / Gym Buddies:** see nearby gym-goers (opt-in), workout together, share programs
- **Strava-like activity feed** (maybe — TBD if this fits the vibe)
- **Accountability partners**
- **Shared programs** — send your program to a friend

---

## Technical Considerations

### Exercise Data:
- Exercise API options: [ExerciseDB](https://exercisedb.io/), [wger API](https://wger.de/api/v2/), or custom + AI-assisted
- Muscle group taxonomy: chest, back, shoulders, biceps, triceps, quads, hamstrings, glutes, calves, abs, forearms
- API provides: exercise name, target muscle, secondary muscles, equipment, instructions, GIFs/images

### Data Model:
```
Exercise {
  id, name, muscleGroup, secondaryMuscles?, equipment, isUserAdded, apiId?,
  lastLogDate?, lastWeight?, lastReps?, lastSets?
}

WorkoutLog {
  id, date, exerciseId, sets, reps, weight, unit (kg/lbs/level), notes?
}

MuscleGroup {
  id, name, lastTrainedDate, atrophyStatus (green/yellow/red/black)
}

Program {
  id, name, goal (fullBody/upper/lower/ppl/custom),
  duration (1w/2w/1m/ongoing), estimatedSessionMinutes?,
  sessions: [ProgramSession]
}

ProgramSession {
  dayOfWeek, exercises: [{ exerciseId, targetSets, targetReps, targetWeight? }]
}

Challenge {
  id, name, durationDays, startDate, streakData: [Bool]
}

Meal {
  id, date, time, description, estimatedCalories?
}

UserProfile {
  height, weight, age, unitPreference (metric/imperial), defaultRestSeconds
}
```

### Platform:
- iOS — SwiftUI + SwiftData
- Offline-first with optional Supabase sync for social features (V3)
- SpriteKit NOT needed (no game-like animations)

### Session Duration Estimation:
- Formula: `(totalSets × avgSetDuration) + (totalSets × defaultRestSeconds) + warmupBuffer`
- User calibrates their own rest time in settings
- Shown when viewing any program session

---

## MVP Scope

### V1 — Core Gym Tracker:
1. Add/manage exercises with muscle groups
2. Log workouts (weight, reps, sets per exercise)  
3. Home screen with sorted exercise list + atrophy coloring
4. Progress view per exercise (last session, PR, timeline)
5. Program builder from user's exercise library with gap detection
6. Exercise search/discovery (API or local database)
7. Basic profile + BMI with disclaimer
8. Challenge streaks (visual streak tracker)

### V2 — Nutrition & Polish:
- Nutrition tracking + meal log
- Meal plan builder
- Weekly calorie reports
- Water reminders
- Session duration estimates
- Atrophy push notifications

### V3 — Social & Theming:
- Gym buddies / nearby gym-goers
- Shared programs
- AI-powered exercise recommendations
- Theming system (doodle, pixel art, minimal)

---

## Open Questions

- Which exercise API is most vibecoder-friendly? (wger is open-source and free, ExerciseDB has better data but paid tiers)
- Should meal logging use AI to estimate calories from text descriptions?
- Atrophy decay curve — linear or exponential? (Real muscle atrophy is roughly exponential after ~2 weeks of inactivity)
- How granular should muscle group tracking be? ("legs" vs. "quads / hamstrings / glutes / calves")
- Challenge system — preset challenges or fully custom?
- Naming: GainzGarden is a placeholder — open to something that fits the doodle/notebook aesthetic

---

*Built with the conductor-over-orchestra philosophy. Damla defines what needs to exist. AI builds it.*
