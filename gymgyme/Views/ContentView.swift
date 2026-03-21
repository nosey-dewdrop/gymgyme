import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("home", systemImage: "terminal") }
            PlansView()
                .tabItem { Label("plans", systemImage: "list.bullet") }
            DiscoverView()
                .tabItem { Label("discover", systemImage: "magnifyingglass") }
        }
        .tint(DoodleTheme.green)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Exercise.self, WorkoutSession.self, ExerciseSet.self,
            WorkoutPlan.self, UserProfile.self
        ], inMemory: true)
}
