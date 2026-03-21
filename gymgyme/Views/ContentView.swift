import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)

                PlansView()
                    .tag(1)

                DiscoverView()
                    .tag(2)
            }
            .tabViewStyle(.automatic)

            // Custom tab bar
            HStack(spacing: 0) {
                TabButton(icon: "dumbbell.fill", label: "Home", isSelected: selectedTab == 0, color: DoodleTheme.accent) {
                    selectedTab = 0
                }
                TabButton(icon: "list.clipboard.fill", label: "Plans", isSelected: selectedTab == 1, color: DoodleTheme.orange) {
                    selectedTab = 1
                }
                TabButton(icon: "magnifyingglass", label: "Discover", isSelected: selectedTab == 2, color: DoodleTheme.blue) {
                    selectedTab = 2
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .background(
                DoodleTheme.cardBackground
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [DoodleTheme.accent.opacity(0.05), DoodleTheme.blue.opacity(0.05)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 20, y: -5)
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? color : DoodleTheme.inkDim)
                    .shadow(color: isSelected ? color.opacity(0.5) : .clear, radius: 8)

                Text(label)
                    .font(DoodleTheme.mono(10))
                    .foregroundStyle(isSelected ? color : DoodleTheme.inkDim)
            }
            .frame(maxWidth: .infinity)
        }
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
