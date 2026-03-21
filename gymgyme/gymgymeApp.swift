import SwiftUI
import SwiftData

@main
struct gymgymeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Exercise.self,
            WorkoutSession.self,
            ExerciseSet.self,
            WorkoutPlan.self,
            UserProfile.self
        ])
    }
}
