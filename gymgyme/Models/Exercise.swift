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

@Model
final class Exercise {
    var name: String
    var tag: String
    var createdAt: Date
    var exerciseTypeRaw: String
    var secondaryMuscles: [String]

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet] = []

    var exerciseType: ExerciseType {
        get { ExerciseType(rawValue: exerciseTypeRaw) ?? .weightReps }
        set { exerciseTypeRaw = newValue.rawValue }
    }

    init(name: String, tag: String, type: ExerciseType = .weightReps, secondaryMuscles: [String] = []) {
        self.name = name
        self.tag = tag.lowercased().trimmingCharacters(in: .whitespaces)
        self.createdAt = Date()
        self.exerciseTypeRaw = type.rawValue
        self.secondaryMuscles = secondaryMuscles
    }
}

// MARK: - Built-in exercises that wger doesn't cover

struct BuiltInExercise {
    let name: String
    let tag: String
    let type: ExerciseType
}

enum BuiltInExercises {
    static let cardio: [BuiltInExercise] = [
        BuiltInExercise(name: "walking", tag: "cardio", type: .cardio),
        BuiltInExercise(name: "running", tag: "cardio", type: .cardio),
        BuiltInExercise(name: "cycling", tag: "cardio", type: .cardio),
        BuiltInExercise(name: "swimming", tag: "cardio", type: .cardio),
        BuiltInExercise(name: "jump rope", tag: "cardio", type: .cardio),
        BuiltInExercise(name: "rowing machine", tag: "cardio", type: .cardio),
        BuiltInExercise(name: "stair climber", tag: "cardio", type: .cardio),
        BuiltInExercise(name: "elliptical", tag: "cardio", type: .cardio),
        BuiltInExercise(name: "hiking", tag: "cardio", type: .cardio),
        BuiltInExercise(name: "dancing", tag: "cardio", type: .cardio),
    ]

    static let durationBased: [BuiltInExercise] = [
        BuiltInExercise(name: "plank", tag: "abs", type: .duration),
        BuiltInExercise(name: "side plank", tag: "abs", type: .duration),
        BuiltInExercise(name: "wall sit", tag: "legs", type: .duration),
        BuiltInExercise(name: "dead hang", tag: "back", type: .duration),
        BuiltInExercise(name: "yoga", tag: "flexibility", type: .duration),
        BuiltInExercise(name: "stretching", tag: "flexibility", type: .duration),
        BuiltInExercise(name: "foam rolling", tag: "recovery", type: .duration),
    ]

    static let bodyweight: [BuiltInExercise] = [
        BuiltInExercise(name: "push-ups", tag: "chest", type: .bodyweight),
        BuiltInExercise(name: "pull-ups", tag: "back", type: .bodyweight),
        BuiltInExercise(name: "chin-ups", tag: "biceps", type: .bodyweight),
        BuiltInExercise(name: "dips", tag: "triceps", type: .bodyweight),
        BuiltInExercise(name: "squats", tag: "legs", type: .bodyweight),
        BuiltInExercise(name: "lunges", tag: "legs", type: .bodyweight),
        BuiltInExercise(name: "burpees", tag: "cardio", type: .bodyweight),
        BuiltInExercise(name: "mountain climbers", tag: "abs", type: .bodyweight),
        BuiltInExercise(name: "sit-ups", tag: "abs", type: .bodyweight),
        BuiltInExercise(name: "crunches", tag: "abs", type: .bodyweight),
        BuiltInExercise(name: "leg raises", tag: "abs", type: .bodyweight),
        BuiltInExercise(name: "glute bridge", tag: "glutes", type: .bodyweight),
        BuiltInExercise(name: "hip thrust", tag: "glutes", type: .bodyweight),
        BuiltInExercise(name: "calf raises", tag: "calves", type: .bodyweight),
    ]

    static var all: [BuiltInExercise] {
        cardio + durationBased + bodyweight
    }
}
