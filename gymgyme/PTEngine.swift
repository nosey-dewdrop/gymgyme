import Foundation

// MARK: - PT Engine: Generates real workout programs from intake data

struct PTProgram {
    let name: String
    let splitType: String
    let days: [PTDay]
    let goal: PTGoal
    let restSeconds: Int
    let repRange: String
    let weeklyNotes: String
}

struct PTDay {
    let dayNumber: Int
    let label: String
    let exercises: [PTExerciseSlot]
    let estimatedMinutes: Int
}

struct PTExerciseSlot {
    let exercise: BuiltInExercise
    let sets: Int
    let repRange: String
    let isCompound: Bool
}

enum PTEngine {

    // MARK: - Main entry point

    static func generateProgram(from intake: PTIntakeData) -> PTProgram? {
        guard let goal = intake.goal,
              let experience = intake.experience else { return nil }

        let equipment = resolveEquipment(intake)
        let split = resolveSplit(intake)
        let repRange = repRange(for: goal)
        let restSeconds = restSeconds(for: goal)
        let setsPerMuscle = weeklyVolume(for: experience)
        let sessionMinutes = intake.sessionMinutes
        let focusBias = intake.focusArea ?? .balanced

        let days = buildDays(
            split: split,
            daysPerWeek: intake.daysPerWeek,
            equipment: equipment,
            setsPerMuscle: setsPerMuscle,
            sessionMinutes: sessionMinutes,
            repRange: repRange,
            focusBias: focusBias,
            goal: goal
        )

        let name = generateName(goal: goal, split: split)

        return PTProgram(
            name: name,
            splitType: split.label,
            days: days,
            goal: goal,
            restSeconds: restSeconds,
            repRange: repRange,
            weeklyNotes: weeklyNotes(experience: experience, goal: goal)
        )
    }

    // MARK: - Equipment resolution

    private static func resolveEquipment(_ intake: PTIntakeData) -> Set<Equipment> {
        switch intake.location {
        case .gym:
            return [.gym, .dumbbell, .none]
        case .home:
            var set = intake.homeEquipment
            set.insert(.none)
            return set
        case .both:
            var set = intake.homeEquipment
            set.insert(.gym)
            set.insert(.dumbbell)
            set.insert(.none)
            return set
        case nil:
            return [.gym, .dumbbell, .none]
        }
    }

    // MARK: - Split resolution

    private enum Split {
        case fullBody
        case upperLower
        case ppl

        var label: String {
            switch self {
            case .fullBody: return "full body"
            case .upperLower: return "upper / lower"
            case .ppl: return "push / pull / legs"
            }
        }
    }

    private static func resolveSplit(_ intake: PTIntakeData) -> Split {
        if let pref = intake.splitPreference {
            switch pref {
            case .fullBody: return .fullBody
            case .upperLower: return .upperLower
            case .auto: break
            }
        }

        switch intake.daysPerWeek {
        case 2...3: return .fullBody
        case 4: return .upperLower
        case 5...6: return .ppl
        default: return .fullBody
        }
    }

    // MARK: - Rep ranges by goal

    private static func repRange(for goal: PTGoal) -> String {
        switch goal {
        case .muscle: return "8-12"
        case .strength: return "3-6"
        case .weightLoss: return "12-15"
        case .general: return "8-12"
        }
    }

    // MARK: - Rest seconds by goal

    private static func restSeconds(for goal: PTGoal) -> Int {
        switch goal {
        case .muscle: return 90
        case .strength: return 150
        case .weightLoss: return 45
        case .general: return 90
        }
    }

    // MARK: - Weekly volume (sets per muscle group per week)

    private static func weeklyVolume(for experience: PTExperience) -> Int {
        switch experience {
        case .beginner: return 8
        case .intermediate: return 12
        case .advanced: return 16
        }
    }

    // MARK: - Build days

    private static func buildDays(
        split: Split, daysPerWeek: Int, equipment: Set<Equipment>,
        setsPerMuscle: Int, sessionMinutes: Int, repRange: String,
        focusBias: PTFocusArea, goal: PTGoal
    ) -> [PTDay] {
        let muscleSchedule = muscleSchedule(split: split, daysPerWeek: daysPerWeek, focusBias: focusBias)

        var days: [PTDay] = []

        for (i, dayMuscles) in muscleSchedule.enumerated() {
            let maxExercises = exerciseCount(for: sessionMinutes, goal: goal)
            let setsPerGroup = max(2, setsPerMuscle / frequencyPerMuscle(split: split, daysPerWeek: daysPerWeek))

            var exercises: [PTExerciseSlot] = []
            var exercisesAdded = 0

            for muscle in dayMuscles {
                guard exercisesAdded < maxExercises else { break }

                let available = ExerciseDB.exercises(tag: muscle, equipment: equipment)
                guard !available.isEmpty else { continue }

                // pick 1-2 exercises per muscle group
                let compounds = available.filter { isCompound($0) }
                let isolations = available.filter { !isCompound($0) }

                // always try a compound first
                if let compound = compounds.randomElement() {
                    exercises.append(PTExerciseSlot(
                        exercise: compound, sets: setsPerGroup,
                        repRange: repRange, isCompound: true
                    ))
                    exercisesAdded += 1
                }

                // add isolation if room and muscle needs more volume
                if exercisesAdded < maxExercises, let iso = isolations.randomElement(), iso.name != exercises.last?.exercise.name {
                    exercises.append(PTExerciseSlot(
                        exercise: iso, sets: max(2, setsPerGroup - 1),
                        repRange: repRange, isCompound: false
                    ))
                    exercisesAdded += 1
                }
            }

            let totalSets = exercises.reduce(0) { $0 + $1.sets }
            let estMinutes = totalSets * 3 // ~3 min per set (including rest)

            days.append(PTDay(
                dayNumber: i + 1,
                label: dayLabel(split: split, index: i, muscles: dayMuscles),
                exercises: exercises,
                estimatedMinutes: min(estMinutes, sessionMinutes)
            ))
        }

        return days
    }

    // MARK: - Muscle schedule per split

    private static func muscleSchedule(split: Split, daysPerWeek: Int, focusBias: PTFocusArea) -> [[String]] {
        switch split {
        case .fullBody:
            let base = ["chest", "back", "shoulders", "legs", "abs"]
            return Array(repeating: applyFocus(base, bias: focusBias), count: daysPerWeek)

        case .upperLower:
            let upper = applyFocus(["chest", "back", "shoulders", "biceps", "triceps"], bias: focusBias)
            let lower = applyFocus(["legs", "hamstrings", "glutes", "calves", "abs"], bias: focusBias)
            var schedule: [[String]] = []
            for i in 0..<daysPerWeek {
                schedule.append(i % 2 == 0 ? upper : lower)
            }
            return schedule

        case .ppl:
            let push = ["chest", "shoulders", "triceps"]
            let pull = ["back", "biceps", "abs"]
            let legs = ["legs", "hamstrings", "glutes", "calves"]
            var schedule: [[String]] = []
            let cycle = [push, pull, legs]
            for i in 0..<daysPerWeek {
                schedule.append(applyFocus(cycle[i % 3], bias: focusBias))
            }
            return schedule
        }
    }

    private static func applyFocus(_ muscles: [String], bias: PTFocusArea) -> [String] {
        switch bias {
        case .upper:
            let muscleSet = Set(muscles)
            let upperMuscles = ["chest", "back", "shoulders", "biceps", "triceps"]
            let extra = upperMuscles.filter { !muscleSet.contains($0) }.prefix(1)
            return muscles + Array(extra)
        case .lower:
            let muscleSet = Set(muscles)
            let lowerMuscles = ["legs", "hamstrings", "glutes", "calves"]
            let extra = lowerMuscles.filter { !muscleSet.contains($0) }.prefix(1)
            return muscles + Array(extra)
        case .balanced, .doesntMatter:
            return muscles
        }
    }

    // MARK: - Exercise count based on session duration

    private static func exerciseCount(for minutes: Int, goal: PTGoal) -> Int {
        let base: Int
        switch minutes {
        case ...30: base = 4
        case 31...45: base = 5
        case 46...60: base = 6
        case 61...90: base = 8
        default: base = 6
        }
        // weight loss gets more exercises (shorter rest, more work)
        return goal == .weightLoss ? base + 1 : base
    }

    // MARK: - Frequency per muscle per week

    private static func frequencyPerMuscle(split: Split, daysPerWeek: Int) -> Int {
        switch split {
        case .fullBody: return daysPerWeek
        case .upperLower: return max(1, daysPerWeek / 2)
        case .ppl: return max(1, daysPerWeek / 3)
        }
    }

    // MARK: - Compound detection

    private static func isCompound(_ exercise: BuiltInExercise) -> Bool {
        exercise.secondaryMuscles.count >= 2
    }

    // MARK: - Day labels

    private static func dayLabel(split: Split, index: Int, muscles: [String]) -> String {
        switch split {
        case .fullBody:
            return "day \(index + 1) — full body"
        case .upperLower:
            return index % 2 == 0 ? "day \(index + 1) — upper body" : "day \(index + 1) — lower body"
        case .ppl:
            let labels = ["push", "pull", "legs"]
            return "day \(index + 1) — \(labels[index % 3])"
        }
    }

    // MARK: - Program name

    private static func generateName(goal: PTGoal, split: Split) -> String {
        let goalName: String
        switch goal {
        case .muscle: goalName = "muscle builder"
        case .strength: goalName = "strength program"
        case .weightLoss: goalName = "fat burner"
        case .general: goalName = "balanced fitness"
        }
        return "\(goalName) — \(split.label)"
    }

    // MARK: - Weekly notes

    private static func weeklyNotes(experience: PTExperience, goal: PTGoal) -> String {
        var notes = ""
        switch goal {
        case .muscle: notes += "focus on controlled reps, feel the muscle working. "
        case .strength: notes += "focus on form and gradual weight increase. "
        case .weightLoss: notes += "keep rest times short, maintain intensity. "
        case .general: notes += "stay consistent, enjoy the process. "
        }
        switch experience {
        case .beginner: notes += "start light, master form before adding weight."
        case .intermediate: notes += "aim to increase weight or reps each week."
        case .advanced: notes += "track volume closely, deload every 4-6 weeks."
        }
        return notes
    }
}
