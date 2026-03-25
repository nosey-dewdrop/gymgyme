import Foundation
import SwiftData

@Model
final class ExerciseSet {
    var reps: Int
    var weight: Double
    var setNumber: Int
    var isPersonalRecord: Bool
    var timestamp: Date
    var durationSeconds: Int
    var distanceKm: Double

    var exercise: Exercise?
    var session: WorkoutSession?

    init(reps: Int = 0, weight: Double = 0, setNumber: Int = 1,
         durationSeconds: Int = 0, distanceKm: Double = 0,
         exercise: Exercise? = nil, session: WorkoutSession? = nil) {
        self.reps = reps
        self.weight = weight
        self.setNumber = setNumber
        self.isPersonalRecord = false
        self.timestamp = Date()
        self.durationSeconds = durationSeconds
        self.distanceKm = distanceKm
        self.exercise = exercise
        self.session = session
    }

    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        if minutes > 0 && seconds > 0 {
            return "\(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }

    var formattedDistance: String {
        if distanceKm >= 1 {
            return String(format: "%.1f km", distanceKm)
        } else {
            return String(format: "%.0f m", distanceKm * 1000)
        }
    }
}
