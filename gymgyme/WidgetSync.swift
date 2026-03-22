import Foundation
import SwiftData
import WidgetKit

enum WidgetSync {
    static func sync(context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()

        // fetch all exercise sets for streak
        let descriptor = FetchDescriptor<ExerciseSet>()
        let allSets = (try? context.fetch(descriptor)) ?? []
        let uniqueDays = Set(allSets.map { calendar.startOfDay(for: $0.timestamp) })

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
