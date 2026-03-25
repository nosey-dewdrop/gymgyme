import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @State private var heightInput = ""
    @State private var weightInput = ""

    private let infoPages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("dumbbell", "track your workouts", "log sets, reps, and weight.\npersonal records detected automatically.", DoodleTheme.green),
        ("flame", "spot what you're skipping", "see which muscle groups you're neglecting.\nstay balanced, avoid atrophy.", DoodleTheme.pink),
        ("chart.line.uptrend.xyaxis", "watch your progress", "charts show your improvement over time.\nnever forget where you left off.", DoodleTheme.teal),
    ]

    private var totalPages: Int { infoPages.count + 1 }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if currentPage < infoPages.count {
                // info pages
                Image(systemName: infoPages[currentPage].icon)
                    .font(.system(size: 60))
                    .foregroundStyle(infoPages[currentPage].color)
                    .padding(.bottom, 24)

                Text(infoPages[currentPage].title)
                    .font(.custom("Menlo-Bold", size: 24))
                    .foregroundStyle(infoPages[currentPage].color)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)

                Text(infoPages[currentPage].subtitle)
                    .font(DoodleTheme.mono)
                    .foregroundStyle(DoodleTheme.dim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                // profile setup page
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(DoodleTheme.orange)
                    .padding(.bottom, 24)

                Text("about you")
                    .font(.custom("Menlo-Bold", size: 24))
                    .foregroundStyle(DoodleTheme.orange)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)

                Text("optional — helps calculate BMI")
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
                    .padding(.bottom, 20)

                VStack(spacing: 12) {
                    HStack {
                        Text("height (cm)")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.dim)
                        Spacer()
                        TextField("170", text: $heightInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.fg)
                            .frame(width: 80)
                    }
                    .padding(10)
                    .background(DoodleTheme.surface)
                    .cornerRadius(6)

                    HStack {
                        Text("weight (kg)")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.dim)
                        Spacer()
                        TextField("65", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.fg)
                            .frame(width: 80)
                    }
                    .padding(10)
                    .background(DoodleTheme.surface)
                    .cornerRadius(6)
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            // dots
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { i in
                    let color: Color = i < infoPages.count ? infoPages[min(i, infoPages.count - 1)].color : DoodleTheme.orange
                    Circle()
                        .fill(i == currentPage ? color : DoodleTheme.dim.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 24)

            // button
            Button {
                if currentPage < totalPages - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    finishOnboarding()
                }
            } label: {
                let isLast = currentPage == totalPages - 1
                let color: Color = currentPage < infoPages.count ? infoPages[currentPage].color : DoodleTheme.orange
                Text(isLast ? "let's go" : "next")
                    .font(DoodleTheme.monoBold)
                    .foregroundStyle(DoodleTheme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(color)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)

            // skip
            if currentPage < totalPages - 1 {
                Button {
                    finishOnboarding()
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

    private func finishOnboarding() {
        // save profile if user entered data
        let height = Double(heightInput) ?? 0
        let weight = Double(weightInput) ?? 0
        if height > 0 || weight > 0 {
            let profile = profiles.first ?? {
                let p = UserProfile()
                modelContext.insert(p)
                return p
            }()
            if height > 0 { profile.heightCm = height }
            if weight > 0 { profile.weightKg = weight }
        }
        hasSeenOnboarding = true
    }
}
