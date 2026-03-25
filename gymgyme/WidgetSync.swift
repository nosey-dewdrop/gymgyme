import Foundation
import SwiftData
import WidgetKit

enum WidgetSync {
    private static let formatter = ISO8601DateFormatter()
    private static let calendar = Calendar.current

    static func sync(context: ModelContext) {
        let today = calendar.startOfDay(for: Date())

        // fetch only last 21 days of exercise sets for streak
        let cutoff = calendar.date(byAdding: .day, value: -21, to: today) ?? today
        let descriptor = FetchDescriptor<ExerciseSet>(
            predicate: #Predicate { $0.timestamp >= cutoff }
        )
        let recentSets = (try? context.fetch(descriptor)) ?? []
        let uniqueDays = Set(recentSets.map { calendar.startOfDay(for: $0.timestamp) })

        var workoutDayStrings: [String] = []
        for offset in 0..<21 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today),
               uniqueDays.contains(date) {
                workoutDayStrings.append(formatter.string(from: date))
            }
        }

        let streakData = WidgetStreakData(
            workoutDays: workoutDayStrings,
            updatedAt: Date()
        )

        // fetch active program
        let planDescriptor = FetchDescriptor<WorkoutPlan>(
            predicate: #Predicate { $0.isActive }
        )
        let activePlan = try? context.fetch(planDescriptor).first

        let programData = activePlan.map {
            WidgetProgramData(
                programName: $0.name,
                exerciseNames: $0.exerciseNames,
                goal: $0.goal.rawValue
            )
        }

        WidgetDataStore.save(WidgetSharedData(
            streak: streakData,
            activeProgram: programData
        ))
        WidgetCenter.shared.reloadAllTimelines()
    }
}
