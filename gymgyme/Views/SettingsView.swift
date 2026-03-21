import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var profile: UserProfile {
        if let existing = profiles.first { return existing }
        let new = UserProfile()
        modelContext.insert(new)
        return new
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("settings")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(DoodleTheme.purple)
                        .padding(.bottom, 8)

                    Text("profile")
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.blue)
                        .padding(.bottom, 4)

                    HStack {
                        Text("height (cm)")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.dim)
                        Spacer()
                        TextField("170", value: Binding(
                            get: { profile.heightCm },
                            set: { profile.heightCm = $0 }
                        ), format: .number)
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
                        TextField("65", value: Binding(
                            get: { profile.weightKg },
                            set: { profile.weightKg = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.fg)
                        .frame(width: 80)
                    }
                    .padding(10)
                    .background(DoodleTheme.surface)
                    .cornerRadius(6)

                    if profile.heightCm > 0 && profile.weightKg > 0 {
                        Text("").frame(height: 8)
                        HStack(spacing: 0) {
                            Text("bmi: ")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.dim)
                            Text(String(format: "%.1f", profile.bmi))
                                .font(DoodleTheme.monoBold)
                                .foregroundStyle(DoodleTheme.orange)
                        }

                        Text("1 kg yag sise, 1 kg kas yumruk.")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("done") { dismiss() }
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.dim)
                }
            }
        }
    }
}

#Preview {
    SettingsView().modelContainer(for: UserProfile.self, inMemory: true)
}
