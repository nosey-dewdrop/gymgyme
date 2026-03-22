import Foundation
import SwiftData

enum PlanGoal: String, Codable, CaseIterable {
    case fullBody = "Full Body"
    case upper = "Upper Body"
    case lower = "Lower Body"
}

enum PlanDuration: String, Codable, CaseIterable {
    case oneWeek = "1 Week"
    case twoWeeks = "2 Weeks"
    case oneMonth = "1 Month"
}

@Model
final class WorkoutPlan {
    var name: String
    var goal: PlanGoal
    var duration: PlanDuration
    var createdAt: Date
    var exerciseNames: [String]
    var isActive: Bool

    init(name: String, goal: PlanGoal, duration: PlanDuration, exerciseNames: [String] = []) {
        self.name = name
        self.goal = goal
        self.duration = duration
        self.createdAt = Date()
        self.exerciseNames = exerciseNames
        self.isActive = false
    }
}
