import SwiftUI
import SwiftData
import UIKit

@main
struct gymgymeApp: App {
    init() {
        // Force all windows to use the dark background
        UIView.appearance(whenContainedInInstancesOf: [UIWindow.self]).backgroundColor = UIColor(DoodleTheme.bg)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(DoodleTheme.bg.ignoresSafeArea())
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
