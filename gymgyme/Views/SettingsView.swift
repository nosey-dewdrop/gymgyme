import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    @Query private var exercises: [Exercise]
    @Query private var exerciseSets: [ExerciseSet]
    @Query private var sessions: [WorkoutSession]
    @Query private var meals: [Meal]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false
    @State private var showPrivacyPolicy = false
    @State private var csvFileURL: URL?
    @State private var showShareSheet = false

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

    private func generateCSV() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        var csv = "date,exercise_name,tag,set_number,reps,weight\n"

        for set in exerciseSets.sorted(by: { $0.timestamp > $1.timestamp }) {
            let date = dateFormatter.string(from: set.timestamp)
            let name = set.exercise?.name ?? "unknown"
            let tag = set.exercise?.tag ?? ""
            let escapedName = name.contains(",") ? "\"\(name)\"" : name
            let escapedTag = tag.contains(",") ? "\"\(tag)\"" : tag
            csv += "\(date),\(escapedName),\(escapedTag),\(set.setNumber),\(set.reps),\(set.weight)\n"
        }

        if !meals.isEmpty {
            csv += "\ndate,meal_name,calories,protein,carbs,fat,notes\n"
            for meal in meals.sorted(by: { $0.timestamp > $1.timestamp }) {
                let date = dateFormatter.string(from: meal.timestamp)
                let name = meal.name.contains(",") ? "\"\(meal.name)\"" : meal.name
                let notes = meal.notes.contains(",") ? "\"\(meal.notes)\"" : meal.notes
                csv += "\(date),\(name),\(meal.calories),\(meal.protein),\(meal.carbs),\(meal.fat),\(notes)\n"
            }
        }

        return csv
    }

    private func exportCSV() {
        let csv = generateCSV()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("gymgyme_export.csv")
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)
        csvFileURL = tempURL
        showShareSheet = true
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

                    Text("").frame(height: 16)
                    Text("data & privacy")
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.blue)
                        .padding(.bottom, 4)

                    Button {
                        exportCSV()
                    } label: {
                        HStack {
                            Text("export data (csv)")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.green)
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(DoodleTheme.green)
                        }
                        .padding(10)
                        .background(DoodleTheme.surface)
                        .cornerRadius(6)
                    }

                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        HStack {
                            Text("privacy policy")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.fg)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(DoodleTheme.dim)
                        }
                        .padding(10)
                        .background(DoodleTheme.surface)
                        .cornerRadius(6)
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
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = csvFileURL {
                    ShareSheet(activityItems: [url])
                }
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView().modelContainer(for: UserProfile.self, inMemory: true)
}
