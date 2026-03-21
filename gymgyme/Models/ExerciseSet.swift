import Foundation
import SwiftData

@Model
final class ExerciseSet {
    var reps: Int
    var weight: Double
    var setNumber: Int
    var isPersonalRecord: Bool
    var timestamp: Date

    var exercise: Exercise?
    var session: WorkoutSession?

    init(reps: Int, weight: Double, setNumber: Int, exercise: Exercise? = nil, session: WorkoutSession? = nil) {
        self.reps = reps
        self.weight = weight
        self.setNumber = setNumber
        self.isPersonalRecord = false
        self.timestamp = Date()
        self.exercise = exercise
        self.session = session
    }
}
