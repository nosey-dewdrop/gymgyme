import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(DoodleTheme.bg)
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(DoodleTheme.dim)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(DoodleTheme.dim)]
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(DoodleTheme.green)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(DoodleTheme.green)]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView()
        } else {
            TabView(selection: $currentPage) {
                HomeView()
                    .tag(0)
                    .tabItem {
                        Image(systemName: "dumbbell")
                        Text("exercises")
                    }
                CalendarView()
                    .tag(1)
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("calendar")
                    }
                PlansView()
                    .tag(2)
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("programs")
                    }
            }
            .tint(DoodleTheme.green)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Exercise.self, WorkoutSession.self, ExerciseSet.self,
            WorkoutPlan.self, UserProfile.self, Meal.self,
            DayProgram.self
        ], inMemory: true)
}
