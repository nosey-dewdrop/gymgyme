import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var profile: UserProfile {
        if let existing = profiles.first {
            return existing
        }
        let new = UserProfile()
        modelContext.insert(new)
        return new
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        ColoredHeader("PROFILE", color: DoodleTheme.blue)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Height (cm)")
                                    .font(DoodleTheme.body())
                                    .foregroundStyle(DoodleTheme.ink)
                                Spacer()
                                TextField("170", value: Binding(
                                    get: { profile.heightCm },
                                    set: { profile.heightCm = $0 }
                                ), format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(DoodleTheme.mono(16))
                                .foregroundStyle(DoodleTheme.blue)
                                .frame(width: 80)
                            }

                            Divider().background(DoodleTheme.inkDim.opacity(0.3))

                            HStack {
                                Text("Weight (kg)")
                                    .font(DoodleTheme.body())
                                    .foregroundStyle(DoodleTheme.ink)
                                Spacer()
                                TextField("65", value: Binding(
                                    get: { profile.weightKg },
                                    set: { profile.weightKg = $0 }
                                ), format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(DoodleTheme.mono(16))
                                .foregroundStyle(DoodleTheme.blue)
                                .frame(width: 80)
                            }
                        }
                        .padding()
                        .background(DoodleTheme.cardBackgroundLight)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DoodleTheme.blue.opacity(0.3), lineWidth: 1)
                        )
                    }

                    if profile.heightCm > 0 && profile.weightKg > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            ColoredHeader("BMI", color: DoodleTheme.orange)

                            VStack(spacing: 10) {
                                HStack {
                                    Text("Your BMI")
                                        .font(DoodleTheme.body())
                                        .foregroundStyle(DoodleTheme.ink)
                                    Spacer()
                                    Text(String(format: "%.1f", profile.bmi))
                                        .font(DoodleTheme.handwritten(24))
                                        .foregroundStyle(DoodleTheme.orange)
                                }

                                Text("1 kg yag sise, 1 kg kas yumruk. Onemli olan kas orani.")
                                    .font(DoodleTheme.mono(11))
                                    .foregroundStyle(DoodleTheme.inkDim)
                            }
                            .padding()
                            .background(DoodleTheme.cardBackgroundLight)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DoodleTheme.orange.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: DoodleTheme.orange.opacity(0.15), radius: 8, x: 0, y: 3)
                        }
                    }
                }
                .padding()
            }
            .background(DoodleTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DoodleTheme.inkLight)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
