import SwiftUI

struct ContentView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DoodleTheme.bg)

        let normal = UITabBarItemAppearance()
        normal.normal.iconColor = UIColor(DoodleTheme.dim)
        normal.normal.titleTextAttributes = [.foregroundColor: UIColor(DoodleTheme.dim)]
        normal.selected.iconColor = UIColor(DoodleTheme.green)
        normal.selected.titleTextAttributes = [.foregroundColor: UIColor(DoodleTheme.green)]

        appearance.stackedLayoutAppearance = normal
        appearance.inlineLayoutAppearance = normal
        appearance.compactInlineLayoutAppearance = normal

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("exercises", systemImage: "terminal") }
            CalendarView()
                .tabItem { Label("calendar", systemImage: "calendar") }
            PlansView()
                .tabItem { Label("programs", systemImage: "list.bullet") }
            MealLogView()
                .tabItem { Label("meals", systemImage: "fork.knife") }
            DiscoverView()
                .tabItem { Label("discover", systemImage: "magnifyingglass") }
        }
        .tint(DoodleTheme.green)
        .background(DoodleTheme.bg.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Exercise.self, WorkoutSession.self, ExerciseSet.self,
            WorkoutPlan.self, UserProfile.self, Meal.self
        ], inMemory: true)
}
