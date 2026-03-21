import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            WorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "dumbbell.fill")
                }

            PlansView()
                .tabItem {
                    Label("Plans", systemImage: "list.clipboard.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(DoodleTheme.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Exercise.self,
            WorkoutSession.self,
            ExerciseSet.self,
            WorkoutPlan.self,
            UserProfile.self
        ], inMemory: true)
}
