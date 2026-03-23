import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 1

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView()
        } else {
            TabView(selection: $currentPage) {
                CalendarView()
                    .tag(0)
                HomeView()
                    .tag(1)
                PlansView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .background(DoodleTheme.bg.ignoresSafeArea())
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
