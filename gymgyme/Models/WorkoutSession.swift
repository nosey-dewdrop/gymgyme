import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var date: Date
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.session)
    var sets: [ExerciseSet] = []

    init(date: Date = Date(), notes: String = "") {
        self.date = date
        self.notes = notes
    }
}
