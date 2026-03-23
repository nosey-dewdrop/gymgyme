import SwiftUI
import SwiftData
import UIKit

@main
struct gymgymeApp: App {
    @Environment(\.scenePhase) private var scenePhase

    let sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for:
                Exercise.self,
                WorkoutSession.self,
                ExerciseSet.self,
                WorkoutPlan.self,
                UserProfile.self,
                Meal.self,
                DayProgram.self
            )
        } catch {
            fatalError("failed to create model container: \(error)")
        }
    }()

    init() {
        // set window background once at launch to prevent white flash
        DispatchQueue.main.async {
            for scene in UIApplication.shared.connectedScenes {
                guard let ws = scene as? UIWindowScene else { continue }
                for window in ws.windows {
                    window.backgroundColor = UIColor(DoodleTheme.bg)
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(DoodleTheme.bg.ignoresSafeArea(.all))
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // fix black screen: reset window bg when coming back
                for scene in UIApplication.shared.connectedScenes {
                    guard let ws = scene as? UIWindowScene else { continue }
                    for window in ws.windows {
                        window.backgroundColor = UIColor(DoodleTheme.bg)
                    }
                }
                WidgetSync.sync(context: sharedModelContainer.mainContext)
            }
        }
    }
}
