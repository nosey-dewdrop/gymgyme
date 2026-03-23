import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 1

    private let pageNames = ["calendar", "exercises", "programs", "search"]
    private let pageColors: [Color] = [DoodleTheme.teal, DoodleTheme.green, DoodleTheme.orange, DoodleTheme.blue]

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView()
        } else {
            ZStack(alignment: .bottom) {
                TabView(selection: $currentPage) {
                    CalendarView()
                        .tag(0)
                    HomeView()
                        .tag(1)
                    PlansView()
                        .tag(2)
                    DiscoverView()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea(.container, edges: .bottom)
                .background(DoodleTheme.bg.ignoresSafeArea())

                // page indicator
                HStack(spacing: 14) {
                    ForEach(0..<pageNames.count, id: \.self) { i in
                        Button {
                            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                                currentPage = i
                            }
                        } label: {
                            Text(pageNames[i])
                                .font(.system(size: currentPage == i ? 13 : 11, weight: currentPage == i ? .bold : .regular, design: .monospaced))
                                .foregroundStyle(currentPage == i ? pageColors[i] : DoodleTheme.dim)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(DoodleTheme.bg.opacity(0.95))
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Exercise.self, WorkoutSession.self, ExerciseSet.self,
            WorkoutPlan.self, UserProfile.self
        ], inMemory: true)
}
