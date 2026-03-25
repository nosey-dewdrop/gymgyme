import Foundation

struct ExerciseNameSuggester {
    static let knownExercises: [String: String] = [
        // Legs
        "squat": "legs",
        "back squat": "legs",
        "front squat": "legs",
        "goblet squat": "legs",
        "bulgarian split squat": "legs",
        "hack squat": "legs",
        "smith machine squat": "legs",
        "leg press": "legs",
        "leg extension": "legs",
        "leg curl": "legs",
        "lying leg curl": "legs",
        "seated leg curl": "legs",
        "romanian deadlift": "legs",
        "stiff leg deadlift": "legs",
        "sumo deadlift": "legs",
        "lunge": "legs",
        "walking lunge": "legs",
        "reverse lunge": "legs",
        "step up": "legs",
        "calf raise": "legs",
        "seated calf raise": "legs",
        "standing calf raise": "legs",
        "hip abduction": "glutes",
        "hip adduction": "legs",
        "hip thrust": "glutes",
        "barbell hip thrust": "glutes",
        "glute bridge": "glutes",
        "glute kickback": "glutes",
        "cable kickback": "glutes",
        "donkey kick": "glutes",
        "fire hydrant": "glutes",
        "good morning": "legs",
        "sissy squat": "legs",
        "pistol squat": "legs",
        "box squat": "legs",
        "pendulum squat": "legs",
        "belt squat": "legs",
        "leg press calf raise": "legs",

        // Chest
        "bench press": "chest",
        "flat bench press": "chest",
        "incline bench press": "chest",
        "decline bench press": "chest",
        "dumbbell bench press": "chest",
        "incline dumbbell press": "chest",
        "decline dumbbell press": "chest",
        "chest fly": "chest",
        "dumbbell fly": "chest",
        "incline dumbbell fly": "chest",
        "cable fly": "chest",
        "cable crossover": "chest",
        "pec deck": "chest",
        "machine chest press": "chest",
        "push up": "chest",
        "dip": "chest",
        "chest dip": "chest",
        "landmine press": "chest",
        "svend press": "chest",
        "floor press": "chest",
        "close grip bench press": "chest",
        "smith machine bench press": "chest",

        // Back
        "deadlift": "back",
        "conventional deadlift": "back",
        "pull up": "back",
        "chin up": "back",
        "lat pulldown": "back",
        "wide grip lat pulldown": "back",
        "close grip lat pulldown": "back",
        "barbell row": "back",
        "bent over row": "back",
        "dumbbell row": "back",
        "one arm dumbbell row": "back",
        "cable row": "back",
        "seated cable row": "back",
        "t bar row": "back",
        "pendlay row": "back",
        "meadows row": "back",
        "chest supported row": "back",
        "machine row": "back",
        "face pull": "back",
        "straight arm pulldown": "back",
        "pullover": "back",
        "dumbbell pullover": "back",
        "hyperextension": "back",
        "back extension": "back",
        "rack pull": "back",
        "inverted row": "back",
        "shrug": "back",
        "barbell shrug": "back",
        "dumbbell shrug": "back",

        // Shoulders
        "overhead press": "shoulders",
        "military press": "shoulders",
        "shoulder press": "shoulders",
        "dumbbell shoulder press": "shoulders",
        "seated dumbbell press": "shoulders",
        "arnold press": "shoulders",
        "lateral raise": "shoulders",
        "dumbbell lateral raise": "shoulders",
        "cable lateral raise": "shoulders",
        "front raise": "shoulders",
        "dumbbell front raise": "shoulders",
        "rear delt fly": "shoulders",
        "reverse fly": "shoulders",
        "reverse pec deck": "shoulders",
        "upright row": "shoulders",
        "barbell upright row": "shoulders",
        "shoulder face pull": "shoulders",
        "machine shoulder press": "shoulders",
        "smith machine shoulder press": "shoulders",
        "pike push up": "shoulders",
        "handstand push up": "shoulders",
        "lu raise": "shoulders",
        "bus driver": "shoulders",
        "plate front raise": "shoulders",

        // Biceps
        "bicep curl": "biceps",
        "barbell curl": "biceps",
        "dumbbell curl": "biceps",
        "hammer curl": "biceps",
        "incline dumbbell curl": "biceps",
        "preacher curl": "biceps",
        "concentration curl": "biceps",
        "cable curl": "biceps",
        "ez bar curl": "biceps",
        "spider curl": "biceps",
        "reverse curl": "biceps",
        "drag curl": "biceps",
        "bayesian curl": "biceps",
        "machine curl": "biceps",
        "cable hammer curl": "biceps",
        "cross body curl": "biceps",
        "zottman curl": "biceps",
        "21s curl": "biceps",

        // Triceps
        "tricep pushdown": "triceps",
        "cable pushdown": "triceps",
        "rope pushdown": "triceps",
        "tricep extension": "triceps",
        "overhead tricep extension": "triceps",
        "dumbbell tricep extension": "triceps",
        "cable overhead extension": "triceps",
        "skull crusher": "triceps",
        "lying tricep extension": "triceps",
        "tricep dip": "triceps",
        "bench dip": "triceps",
        "diamond push up": "triceps",
        "tricep kickback": "triceps",
        "dumbbell kickback": "triceps",
        "close grip push up": "triceps",
        "jm press": "triceps",

        // Abs
        "crunch": "abs",
        "sit up": "abs",
        "leg raise": "abs",
        "hanging leg raise": "abs",
        "lying leg raise": "abs",
        "plank": "abs",
        "side plank": "abs",
        "russian twist": "abs",
        "cable crunch": "abs",
        "ab wheel rollout": "abs",
        "mountain climber": "abs",
        "bicycle crunch": "abs",
        "toe touch": "abs",
        "v up": "abs",
        "dead bug": "abs",
        "wood chop": "abs",
        "cable wood chop": "abs",
        "pallof press": "abs",
        "dragon flag": "abs",
        "decline crunch": "abs",
        "knee raise": "abs",
        "flutter kick": "abs",
        "hollow hold": "abs",
    ]

    static func suggestions(for input: String, existingExercises: [String]) -> [String] {
        let cleaned = input.lowercased().trimmingCharacters(in: .whitespaces)
        guard cleaned.count >= 2 else { return [] }

        let existingSet = Set(existingExercises.map { $0.lowercased() })

        var prefixMatches: [String] = []
        var containsMatches: [String] = []

        // single pass over keys
        for name in knownExercises.keys {
            guard !existingSet.contains(name) else { continue }
            if name.hasPrefix(cleaned) {
                prefixMatches.append(name)
            } else if name.contains(cleaned) {
                containsMatches.append(name)
            }
        }

        return Array((prefixMatches.sorted() + containsMatches.sorted()).prefix(5))
    }

    static func autoTag(for exerciseName: String) -> String? {
        let cleaned = exerciseName.lowercased().trimmingCharacters(in: .whitespaces)
        return knownExercises[cleaned]
    }
}
