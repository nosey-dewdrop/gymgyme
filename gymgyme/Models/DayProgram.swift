import Foundation
import SwiftData

@Model
final class DayProgram {
    var date: Date
    var planName: String
    var exerciseNames: [String]

    init(date: Date, plan: WorkoutPlan) {
        self.date = Calendar.current.startOfDay(for: date)
        self.planName = plan.name
        self.exerciseNames = plan.exerciseNames
    }
}
