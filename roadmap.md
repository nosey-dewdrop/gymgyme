# Roadmap

## Phase 1: Foundation
- [x] Xcode project (SwiftUI + SwiftData, iOS 17+)
- [x] Data models (Exercise, ExerciseSet, WorkoutSession, WorkoutPlan, UserProfile, Meal, DayProgram)
- [x] Swipe navigation (horizontal pages + vertical paging)
- [x] Terminal theme (Catppuccin + Menlo font)

## Phase 2: Core Logging
- [x] Exercise adding (manual, name + muscle group with auto-suggest)
- [x] Workout logging (set/rep/kg, previous record shown, rest timer)
- [x] PR detection with haptic feedback
- [x] Log history expand with edit capability
- [x] Delete confirmation dialog

## Phase 3: Tracking
- [x] Atrophy color coding (green/yellow/red based on days since last workout)
- [x] Progress charts per exercise (weight line chart + volume bar chart)
- [x] Calendar with workout day markers and program assignment
- [x] Active programs display on home

## Phase 4: Programs
- [x] Program creation with gap detection (missing muscle group warning)
- [x] Program activate/deactivate
- [x] Premium programs coming soon section

## Phase 5: Nutrition
- [x] Meal logging with USDA food database search
- [x] Calorie/protein/carbs/fat tracking
- [x] Serving size adjustment
- [x] Daily summary on meals page

## Phase 6: Discovery
- [x] wger API exercise search
- [x] Exercise detail with muscles, equipment, images
- [x] TR/EN description toggle
- [x] Add to library from search results (lowercase, english tags)

## Phase 7: Widget & Notifications
- [x] Home screen widget (streak bar + active program)
- [x] App Group data sharing
- [x] Inactivity push notification (5 days)

## Phase 8: Polish & Security
- [x] Onboarding flow (4 screens with profile setup)
- [x] Cloudflare Worker proxy for USDA API key
- [x] Data export (CSV)
- [x] Privacy policy
- [x] Rest timer between sets
- [x] Haptic feedback
- [x] Input validation, edge case fixes
- [x] Accessibility labels
- [x] Reset all data option
- [x] Kg/lbs toggle

## Phase 9: UX Overhaul
- [x] Fix tab order (Home first, Calendar second, Programs third)
- [x] Replace tag terminology with muscle group in UI
- [x] Improve empty states with actionable messages
- [x] Remove admin premium hack
- [x] Unify plan/program terminology
- [x] Exercise type system (weight, bodyweight, duration, cardio)
- [x] Built-in cardio and bodyweight exercises
- [x] Secondary muscles from wger API
- [ ] 3D body map (rotatable muscle group selector)
- [ ] Atrophy visualization on body map

## Phase 10: Pocket PT (Premium)
- [ ] StoreKit 2 integration (69 TL one-time / 249 TL monthly)
- [ ] Paywall screen
- [ ] PT intake form (experience, days/week, goal, session duration, equipment)
- [ ] Auto split selection algorithm (full body / upper-lower / PPL based on intake)
- [ ] AI program generation from user's exercise library
- [ ] Progressive overload toggle per program
- [ ] Weekly weight/rep progression suggestions
- [ ] Deload week reminders (every 4-6 weeks)
- [ ] Neglected muscle group alerts
- [ ] Expert program templates (PPL, Upper/Lower, Full Body 3x, 5x5)

## Phase 11: Launch
- [ ] App Store screenshots
- [ ] App Store description and metadata
- [ ] App Store submission
