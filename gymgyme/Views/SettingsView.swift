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
            List {
                Section {
                    HStack {
                        Text("Height (cm)")
                            .font(DoodleTheme.body())
                        Spacer()
                        TextField("170", value: Binding(
                            get: { profile.heightCm },
                            set: { profile.heightCm = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    }

                    HStack {
                        Text("Weight (kg)")
                            .font(DoodleTheme.body())
                        Spacer()
                        TextField("65", value: Binding(
                            get: { profile.weightKg },
                            set: { profile.weightKg = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    }

                    if profile.heightCm > 0 && profile.weightKg > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("BMI")
                                    .font(DoodleTheme.handwritten(17))
                                Spacer()
                                Text(String(format: "%.1f", profile.bmi))
                                    .font(DoodleTheme.handwritten(20))
                                    .foregroundStyle(DoodleTheme.accent)
                            }

                            Text("1 kg yag sise, 1 kg kas yumruk. Onemli olan kas orani.")
                                .font(DoodleTheme.caption())
                                .foregroundStyle(DoodleTheme.inkLight)
                        }
                    }
                } header: {
                    Text("Profile")
                }
                .listRowBackground(DoodleTheme.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(DoodleTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
