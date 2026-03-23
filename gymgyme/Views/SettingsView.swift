import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false

    private var profile: UserProfile {
        profiles.first ?? createProfile()
    }

    private func resetAllData() {
        try? modelContext.delete(model: Exercise.self)
        try? modelContext.delete(model: ExerciseSet.self)
        try? modelContext.delete(model: WorkoutSession.self)
        try? modelContext.delete(model: WorkoutPlan.self)
        try? modelContext.delete(model: Meal.self)
        try? modelContext.delete(model: DayProgram.self)
        try? modelContext.delete(model: UserProfile.self)
        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        UserDefaults.standard.set(false, forKey: "dataMigrated")
        dismiss()
    }

    private func createProfile() -> UserProfile {
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
                            set: { profile.heightCm = min(300, max(0, $0)) }
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
                            set: { profile.weightKg = min(500, max(0, $0)) }
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

                    Text("").frame(height: 8)
                    Text("units")
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.blue)
                        .padding(.bottom, 4)

                    HStack {
                        Text("weight unit")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.dim)
                        Spacer()
                        Button {
                            profile.useLbs.toggle()
                        } label: {
                            Text(profile.useLbs ? "lbs" : "kg")
                                .font(DoodleTheme.monoBold)
                                .foregroundStyle(DoodleTheme.green)
                        }
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

                        Text("1 kg fat = size of a bottle. 1 kg muscle = size of a fist.")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                            .padding(.top, 2)
                    }

                    Text("").frame(height: 24)
                    Text("danger zone")
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.red)
                        .padding(.bottom, 4)

                    Button {
                        showResetAlert = true
                    } label: {
                        Text("reset all data")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.red)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(DoodleTheme.surface)
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .alert("reset all data?", isPresented: $showResetAlert) {
                Button("cancel", role: .cancel) {}
                Button("reset", role: .destructive) { resetAllData() }
            } message: {
                Text("this will delete all exercises, workouts, meals, and programs. this cannot be undone.")
            }
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
