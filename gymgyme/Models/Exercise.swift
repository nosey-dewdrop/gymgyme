import Foundation
import SwiftData

enum ExerciseType: String, Codable, CaseIterable {
    case weightReps = "weight"
    case bodyweight = "bodyweight"
    case duration = "duration"
    case cardio = "cardio"

    var label: String {
        switch self {
        case .weightReps: return "weight & reps"
        case .bodyweight: return "bodyweight"
        case .duration: return "duration"
        case .cardio: return "cardio"
        }
    }

    var icon: String {
        switch self {
        case .weightReps: return "dumbbell"
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .duration: return "timer"
        case .cardio: return "heart.circle"
        }
    }
}

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case gym = "gym"
    case dumbbell = "dumbbell"
    case band = "band"
    case pullupBar = "pullup_bar"
    case kettlebell = "kettlebell"
    case none = "none"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gym: return "gym machines"
        case .dumbbell: return "dumbbells"
        case .band: return "resistance band"
        case .pullupBar: return "pull-up bar"
        case .kettlebell: return "kettlebell"
        case .none: return "no equipment"
        }
    }

    var icon: String {
        switch self {
        case .gym: return "building.2"
        case .dumbbell: return "dumbbell"
        case .band: return "figure.flexibility"
        case .pullupBar: return "figure.climbing"
        case .kettlebell: return "figure.strengthtraining.functional"
        case .none: return "figure.walk"
        }
    }
}

@Model
final class Exercise {
    var name: String
    var tag: String
    var createdAt: Date
    var exerciseTypeRaw: String
    var secondaryMuscles: [String]
    var equipmentRaw: [String]

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet] = []

    var exerciseType: ExerciseType {
        get { ExerciseType(rawValue: exerciseTypeRaw) ?? .weightReps }
        set { exerciseTypeRaw = newValue.rawValue }
    }

    var equipment: [Equipment] {
        get { equipmentRaw.compactMap { Equipment(rawValue: $0) } }
        set { equipmentRaw = newValue.map(\.rawValue) }
    }

    init(name: String, tag: String, type: ExerciseType = .weightReps,
         secondaryMuscles: [String] = [], equipment: [Equipment] = []) {
        self.name = name
        self.tag = tag.lowercased().trimmingCharacters(in: .whitespaces)
        self.createdAt = Date()
        self.exerciseTypeRaw = type.rawValue
        self.secondaryMuscles = secondaryMuscles
        self.equipmentRaw = equipment.map(\.rawValue)
    }
}

// MARK: - Built-in Exercise Database

struct BuiltInExercise {
    let name: String
    let tag: String
    let secondaryMuscles: [String]
    let type: ExerciseType
    let equipment: [Equipment]
}

enum ExerciseDB {

    // MARK: - Chest

    static let chest: [BuiltInExercise] = [
        // gym
        BuiltInExercise(name: "bench press", tag: "chest", secondaryMuscles: ["front delts", "triceps"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "incline bench press", tag: "chest", secondaryMuscles: ["front delts", "triceps"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "decline bench press", tag: "chest", secondaryMuscles: ["triceps"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "cable fly", tag: "chest", secondaryMuscles: ["front delts"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "pec deck", tag: "chest", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "chest press machine", tag: "chest", secondaryMuscles: ["triceps"], type: .weightReps, equipment: [.gym]),
        // dumbbell
        BuiltInExercise(name: "dumbbell bench press", tag: "chest", secondaryMuscles: ["front delts", "triceps"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell incline press", tag: "chest", secondaryMuscles: ["front delts", "triceps"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell fly", tag: "chest", secondaryMuscles: ["front delts"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell floor press", tag: "chest", secondaryMuscles: ["triceps"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell pullover", tag: "chest", secondaryMuscles: ["lats", "triceps"], type: .weightReps, equipment: [.dumbbell]),
        // band
        BuiltInExercise(name: "band chest press", tag: "chest", secondaryMuscles: ["triceps"], type: .weightReps, equipment: [.band]),
        BuiltInExercise(name: "band chest fly", tag: "chest", secondaryMuscles: [], type: .weightReps, equipment: [.band]),
        // bodyweight
        BuiltInExercise(name: "push-ups", tag: "chest", secondaryMuscles: ["front delts", "triceps"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "wide push-ups", tag: "chest", secondaryMuscles: ["front delts"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "decline push-ups", tag: "chest", secondaryMuscles: ["front delts", "triceps"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "diamond push-ups", tag: "chest", secondaryMuscles: ["triceps"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "pike push-ups", tag: "chest", secondaryMuscles: ["shoulders"], type: .bodyweight, equipment: [.none]),
    ]

    // MARK: - Back

    static let back: [BuiltInExercise] = [
        // gym
        BuiltInExercise(name: "lat pulldown", tag: "back", secondaryMuscles: ["biceps", "rear delts"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "seated row", tag: "back", secondaryMuscles: ["biceps", "rear delts"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "barbell row", tag: "back", secondaryMuscles: ["biceps", "rear delts"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "t-bar row", tag: "back", secondaryMuscles: ["biceps"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "cable row", tag: "back", secondaryMuscles: ["biceps"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "face pull", tag: "back", secondaryMuscles: ["rear delts", "traps"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "deadlift", tag: "back", secondaryMuscles: ["glutes", "hamstrings", "traps"], type: .weightReps, equipment: [.gym]),
        // dumbbell
        BuiltInExercise(name: "dumbbell row", tag: "back", secondaryMuscles: ["biceps"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell reverse fly", tag: "back", secondaryMuscles: ["rear delts"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell shrug", tag: "back", secondaryMuscles: ["traps"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "renegade row", tag: "back", secondaryMuscles: ["abs", "biceps"], type: .weightReps, equipment: [.dumbbell]),
        // band
        BuiltInExercise(name: "band pull-apart", tag: "back", secondaryMuscles: ["rear delts"], type: .weightReps, equipment: [.band]),
        BuiltInExercise(name: "band row", tag: "back", secondaryMuscles: ["biceps"], type: .weightReps, equipment: [.band]),
        BuiltInExercise(name: "band lat pulldown", tag: "back", secondaryMuscles: ["biceps"], type: .weightReps, equipment: [.band]),
        // bodyweight / pullup bar
        BuiltInExercise(name: "pull-ups", tag: "back", secondaryMuscles: ["biceps"], type: .bodyweight, equipment: [.pullupBar]),
        BuiltInExercise(name: "chin-ups", tag: "back", secondaryMuscles: ["biceps"], type: .bodyweight, equipment: [.pullupBar]),
        BuiltInExercise(name: "inverted row", tag: "back", secondaryMuscles: ["biceps", "rear delts"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "superman", tag: "back", secondaryMuscles: ["glutes"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "dead hang", tag: "back", secondaryMuscles: ["forearms"], type: .duration, equipment: [.pullupBar]),
    ]

    // MARK: - Shoulders

    static let shoulders: [BuiltInExercise] = [
        // gym
        BuiltInExercise(name: "overhead press", tag: "shoulders", secondaryMuscles: ["triceps", "traps"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "lateral raise machine", tag: "shoulders", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "shoulder press machine", tag: "shoulders", secondaryMuscles: ["triceps"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "cable lateral raise", tag: "shoulders", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "reverse pec deck", tag: "shoulders", secondaryMuscles: ["rear delts"], type: .weightReps, equipment: [.gym]),
        // dumbbell
        BuiltInExercise(name: "dumbbell shoulder press", tag: "shoulders", secondaryMuscles: ["triceps"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell lateral raise", tag: "shoulders", secondaryMuscles: [], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell front raise", tag: "shoulders", secondaryMuscles: ["front delts"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "arnold press", tag: "shoulders", secondaryMuscles: ["front delts", "triceps"], type: .weightReps, equipment: [.dumbbell]),
        // band
        BuiltInExercise(name: "band shoulder press", tag: "shoulders", secondaryMuscles: ["triceps"], type: .weightReps, equipment: [.band]),
        BuiltInExercise(name: "band lateral raise", tag: "shoulders", secondaryMuscles: [], type: .weightReps, equipment: [.band]),
        BuiltInExercise(name: "band front raise", tag: "shoulders", secondaryMuscles: [], type: .weightReps, equipment: [.band]),
        // bodyweight
        BuiltInExercise(name: "pike push-ups", tag: "shoulders", secondaryMuscles: ["triceps", "chest"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "handstand hold", tag: "shoulders", secondaryMuscles: ["traps", "abs"], type: .duration, equipment: [.none]),
    ]

    // MARK: - Biceps

    static let biceps: [BuiltInExercise] = [
        // gym
        BuiltInExercise(name: "barbell curl", tag: "biceps", secondaryMuscles: ["forearms"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "preacher curl", tag: "biceps", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "cable curl", tag: "biceps", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        // dumbbell
        BuiltInExercise(name: "dumbbell bicep curl", tag: "biceps", secondaryMuscles: ["forearms"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "hammer curl", tag: "biceps", secondaryMuscles: ["forearms"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "concentration curl", tag: "biceps", secondaryMuscles: [], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "incline dumbbell curl", tag: "biceps", secondaryMuscles: [], type: .weightReps, equipment: [.dumbbell]),
        // band
        BuiltInExercise(name: "band bicep curl", tag: "biceps", secondaryMuscles: [], type: .weightReps, equipment: [.band]),
        // bodyweight
        BuiltInExercise(name: "chin-ups", tag: "biceps", secondaryMuscles: ["back"], type: .bodyweight, equipment: [.pullupBar]),
    ]

    // MARK: - Triceps

    static let triceps: [BuiltInExercise] = [
        // gym
        BuiltInExercise(name: "tricep pushdown", tag: "triceps", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "overhead cable extension", tag: "triceps", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "skull crushers", tag: "triceps", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "close grip bench press", tag: "triceps", secondaryMuscles: ["chest"], type: .weightReps, equipment: [.gym]),
        // dumbbell
        BuiltInExercise(name: "dumbbell tricep extension", tag: "triceps", secondaryMuscles: [], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell kickback", tag: "triceps", secondaryMuscles: [], type: .weightReps, equipment: [.dumbbell]),
        // band
        BuiltInExercise(name: "band tricep pushdown", tag: "triceps", secondaryMuscles: [], type: .weightReps, equipment: [.band]),
        BuiltInExercise(name: "band overhead extension", tag: "triceps", secondaryMuscles: [], type: .weightReps, equipment: [.band]),
        // bodyweight
        BuiltInExercise(name: "diamond push-ups", tag: "triceps", secondaryMuscles: ["chest"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "bench dips", tag: "triceps", secondaryMuscles: ["chest", "shoulders"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "dips", tag: "triceps", secondaryMuscles: ["chest", "shoulders"], type: .bodyweight, equipment: [.pullupBar]),
    ]

    // MARK: - Legs (Quads focused)

    static let legs: [BuiltInExercise] = [
        // gym
        BuiltInExercise(name: "barbell squat", tag: "legs", secondaryMuscles: ["glutes", "hamstrings", "abs"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "leg press", tag: "legs", secondaryMuscles: ["glutes"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "leg extension", tag: "legs", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "hack squat", tag: "legs", secondaryMuscles: ["glutes"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "smith machine squat", tag: "legs", secondaryMuscles: ["glutes"], type: .weightReps, equipment: [.gym]),
        // dumbbell
        BuiltInExercise(name: "goblet squat", tag: "legs", secondaryMuscles: ["glutes", "abs"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell lunges", tag: "legs", secondaryMuscles: ["glutes"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell step-ups", tag: "legs", secondaryMuscles: ["glutes"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell split squat", tag: "legs", secondaryMuscles: ["glutes"], type: .weightReps, equipment: [.dumbbell]),
        // kettlebell
        BuiltInExercise(name: "kettlebell squat", tag: "legs", secondaryMuscles: ["glutes", "abs"], type: .weightReps, equipment: [.kettlebell]),
        BuiltInExercise(name: "kettlebell swing", tag: "legs", secondaryMuscles: ["glutes", "hamstrings", "back"], type: .weightReps, equipment: [.kettlebell]),
        // band
        BuiltInExercise(name: "band squat", tag: "legs", secondaryMuscles: ["glutes"], type: .weightReps, equipment: [.band]),
        // bodyweight
        BuiltInExercise(name: "bodyweight squat", tag: "legs", secondaryMuscles: ["glutes"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "lunges", tag: "legs", secondaryMuscles: ["glutes"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "jump squats", tag: "legs", secondaryMuscles: ["glutes", "calves"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "bulgarian split squat", tag: "legs", secondaryMuscles: ["glutes"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "wall sit", tag: "legs", secondaryMuscles: [], type: .duration, equipment: [.none]),
    ]

    // MARK: - Hamstrings

    static let hamstrings: [BuiltInExercise] = [
        // gym
        BuiltInExercise(name: "leg curl", tag: "hamstrings", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "romanian deadlift", tag: "hamstrings", secondaryMuscles: ["glutes", "back"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "stiff leg deadlift", tag: "hamstrings", secondaryMuscles: ["glutes", "back"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "seated leg curl", tag: "hamstrings", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        // dumbbell
        BuiltInExercise(name: "dumbbell romanian deadlift", tag: "hamstrings", secondaryMuscles: ["glutes", "back"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell single leg deadlift", tag: "hamstrings", secondaryMuscles: ["glutes"], type: .weightReps, equipment: [.dumbbell]),
        // band
        BuiltInExercise(name: "band leg curl", tag: "hamstrings", secondaryMuscles: [], type: .weightReps, equipment: [.band]),
        BuiltInExercise(name: "band good morning", tag: "hamstrings", secondaryMuscles: ["glutes", "back"], type: .weightReps, equipment: [.band]),
        // bodyweight
        BuiltInExercise(name: "nordic hamstring curl", tag: "hamstrings", secondaryMuscles: [], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "single leg glute bridge", tag: "hamstrings", secondaryMuscles: ["glutes"], type: .bodyweight, equipment: [.none]),
    ]

    // MARK: - Glutes

    static let glutes: [BuiltInExercise] = [
        // gym
        BuiltInExercise(name: "barbell hip thrust", tag: "glutes", secondaryMuscles: ["hamstrings"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "cable kickback", tag: "glutes", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "hip abduction machine", tag: "glutes", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        // dumbbell
        BuiltInExercise(name: "dumbbell hip thrust", tag: "glutes", secondaryMuscles: ["hamstrings"], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "dumbbell sumo squat", tag: "glutes", secondaryMuscles: ["legs"], type: .weightReps, equipment: [.dumbbell]),
        // band
        BuiltInExercise(name: "band hip thrust", tag: "glutes", secondaryMuscles: ["hamstrings"], type: .weightReps, equipment: [.band]),
        BuiltInExercise(name: "band clamshell", tag: "glutes", secondaryMuscles: [], type: .weightReps, equipment: [.band]),
        BuiltInExercise(name: "band kickback", tag: "glutes", secondaryMuscles: [], type: .weightReps, equipment: [.band]),
        BuiltInExercise(name: "band lateral walk", tag: "glutes", secondaryMuscles: [], type: .weightReps, equipment: [.band]),
        // bodyweight
        BuiltInExercise(name: "glute bridge", tag: "glutes", secondaryMuscles: ["hamstrings"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "hip thrust", tag: "glutes", secondaryMuscles: ["hamstrings"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "donkey kicks", tag: "glutes", secondaryMuscles: [], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "fire hydrants", tag: "glutes", secondaryMuscles: [], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "single leg glute bridge", tag: "glutes", secondaryMuscles: ["hamstrings"], type: .bodyweight, equipment: [.none]),
    ]

    // MARK: - Abs

    static let abs: [BuiltInExercise] = [
        // gym
        BuiltInExercise(name: "cable crunch", tag: "abs", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "hanging leg raise", tag: "abs", secondaryMuscles: ["hip flexors"], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "ab machine", tag: "abs", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        // bodyweight
        BuiltInExercise(name: "crunches", tag: "abs", secondaryMuscles: [], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "sit-ups", tag: "abs", secondaryMuscles: ["hip flexors"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "leg raises", tag: "abs", secondaryMuscles: ["hip flexors"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "bicycle crunches", tag: "abs", secondaryMuscles: ["obliques"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "mountain climbers", tag: "abs", secondaryMuscles: ["shoulders", "hip flexors"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "russian twist", tag: "abs", secondaryMuscles: ["obliques"], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "dead bug", tag: "abs", secondaryMuscles: [], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "plank", tag: "abs", secondaryMuscles: ["shoulders"], type: .duration, equipment: [.none]),
        BuiltInExercise(name: "side plank", tag: "abs", secondaryMuscles: ["obliques"], type: .duration, equipment: [.none]),
    ]

    // MARK: - Calves

    static let calves: [BuiltInExercise] = [
        BuiltInExercise(name: "standing calf raise", tag: "calves", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "seated calf raise", tag: "calves", secondaryMuscles: [], type: .weightReps, equipment: [.gym]),
        BuiltInExercise(name: "dumbbell calf raise", tag: "calves", secondaryMuscles: [], type: .weightReps, equipment: [.dumbbell]),
        BuiltInExercise(name: "bodyweight calf raise", tag: "calves", secondaryMuscles: [], type: .bodyweight, equipment: [.none]),
        BuiltInExercise(name: "single leg calf raise", tag: "calves", secondaryMuscles: [], type: .bodyweight, equipment: [.none]),
    ]

    // MARK: - Cardio

    static let cardio: [BuiltInExercise] = [
        BuiltInExercise(name: "walking", tag: "cardio", secondaryMuscles: [], type: .cardio, equipment: [.none]),
        BuiltInExercise(name: "running", tag: "cardio", secondaryMuscles: [], type: .cardio, equipment: [.none]),
        BuiltInExercise(name: "cycling", tag: "cardio", secondaryMuscles: [], type: .cardio, equipment: [.none]),
        BuiltInExercise(name: "swimming", tag: "cardio", secondaryMuscles: [], type: .cardio, equipment: [.none]),
        BuiltInExercise(name: "jump rope", tag: "cardio", secondaryMuscles: ["calves", "shoulders"], type: .cardio, equipment: [.none]),
        BuiltInExercise(name: "rowing machine", tag: "cardio", secondaryMuscles: ["back", "biceps"], type: .cardio, equipment: [.gym]),
        BuiltInExercise(name: "stair climber", tag: "cardio", secondaryMuscles: ["legs", "glutes"], type: .cardio, equipment: [.gym]),
        BuiltInExercise(name: "elliptical", tag: "cardio", secondaryMuscles: [], type: .cardio, equipment: [.gym]),
        BuiltInExercise(name: "hiking", tag: "cardio", secondaryMuscles: ["legs", "glutes"], type: .cardio, equipment: [.none]),
        BuiltInExercise(name: "burpees", tag: "cardio", secondaryMuscles: ["chest", "legs", "abs"], type: .bodyweight, equipment: [.none]),
    ]

    // MARK: - Flexibility / Recovery

    static let flexibility: [BuiltInExercise] = [
        BuiltInExercise(name: "yoga", tag: "flexibility", secondaryMuscles: [], type: .duration, equipment: [.none]),
        BuiltInExercise(name: "stretching", tag: "flexibility", secondaryMuscles: [], type: .duration, equipment: [.none]),
        BuiltInExercise(name: "foam rolling", tag: "recovery", secondaryMuscles: [], type: .duration, equipment: [.none]),
    ]

    // MARK: - All exercises

    static var all: [BuiltInExercise] {
        chest + back + shoulders + biceps + triceps + legs + hamstrings + glutes + abs + calves + cardio + flexibility
    }

    /// Filter exercises by available equipment
    static func exercises(for equipmentSet: Set<Equipment>) -> [BuiltInExercise] {
        all.filter { exercise in
            exercise.equipment.contains { equipmentSet.contains($0) }
        }
    }

    /// Filter exercises by muscle group and available equipment
    static func exercises(tag: String, equipment equipmentSet: Set<Equipment>) -> [BuiltInExercise] {
        all.filter { exercise in
            exercise.tag == tag && exercise.equipment.contains { equipmentSet.contains($0) }
        }
    }
}
