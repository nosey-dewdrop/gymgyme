import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "dumbbell.fill")
                }

            PlansView()
                .tabItem {
                    Label("Plans", systemImage: "list.clipboard.fill")
                }

            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
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
