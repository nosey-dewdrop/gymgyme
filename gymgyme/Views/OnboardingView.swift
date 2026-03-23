import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("plus.circle", "add your exercises", "build your personal exercise library.\nadd from the database or create your own.", DoodleTheme.green),
        ("pencil.and.list.clipboard", "log your workouts", "track sets, reps, and weight.\npersonal records detected automatically.", DoodleTheme.pink),
        ("chart.line.uptrend.xyaxis", "watch your progress", "see how you improve over time.\nnever forget where you left off.", DoodleTheme.teal),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // icon
            Image(systemName: pages[currentPage].icon)
                .font(.system(size: 60))
                .foregroundStyle(pages[currentPage].color)
                .padding(.bottom, 24)

            // title
            Text(pages[currentPage].title)
                .font(.custom("Menlo-Bold", size: 24))
                .foregroundStyle(pages[currentPage].color)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            // subtitle
            Text(pages[currentPage].subtitle)
                .font(DoodleTheme.mono)
                .foregroundStyle(DoodleTheme.dim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // dots
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Circle()
                        .fill(i == currentPage ? pages[currentPage].color : DoodleTheme.dim.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 24)

            // button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasSeenOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "next" : "let's go")
                    .font(DoodleTheme.monoBold)
                    .foregroundStyle(DoodleTheme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(pages[currentPage].color)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)

            // skip
            if currentPage < pages.count - 1 {
                Button {
                    hasSeenOnboarding = true
                } label: {
                    Text("skip")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.dim)
                }
                .padding(.bottom, 16)
            } else {
                Text("").frame(height: 32)
            }
        }
        .background(DoodleTheme.bg.ignoresSafeArea(.all))
    }
}
