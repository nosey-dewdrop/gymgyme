import SwiftUI
import SwiftData

struct CreatePlanView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var planName = ""
    @State private var selectedGoal: PlanGoal = .fullBody
    @State private var selectedDuration: PlanDuration = .oneWeek
    @State private var selectedExercises: Set<PersistentIdentifier> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text("new plan")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(DoodleTheme.orange)
                        .padding(.bottom, 8)

                    Text("name")
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.blue)

                    TextField("plan name", text: $planName)
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.fg)
                        .padding(10)
                        .background(DoodleTheme.surface)
                        .cornerRadius(6)

                    Text("").frame(height: 4)

                    Text("goal")
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.pink)

                    Picker("", selection: $selectedGoal) {
                        ForEach(PlanGoal.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 4)

                    Text("duration")
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.purple)

                    Picker("", selection: $selectedDuration) {
                        ForEach(PlanDuration.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 8)

                    Text("exercises")
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.green)

                    if exercises.isEmpty {
                        Text("  add exercises from home tab first")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                    } else {
                        ForEach(exercises) { exercise in
                            Button { toggleExercise(exercise) } label: {
                                HStack(spacing: 0) {
                                    Text(selectedExercises.contains(exercise.persistentModelID) ? "■ " : "□ ")
                                        .font(DoodleTheme.mono)
                                        .foregroundStyle(selectedExercises.contains(exercise.persistentModelID) ? DoodleTheme.green : DoodleTheme.dim)
                                    Text(exercise.name)
                                        .font(DoodleTheme.mono)
                                        .foregroundStyle(DoodleTheme.fg)
                                    Spacer()
                                    TagChip(tag: exercise.tag)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(DoodleTheme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.dim)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("create") { savePlan() }
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.green)
                        .disabled(planName.trimmingCharacters(in: .whitespaces).isEmpty || selectedExercises.isEmpty)
                }
            }
        }
    }

    private func toggleExercise(_ e: Exercise) {
        if selectedExercises.contains(e.persistentModelID) {
            selectedExercises.remove(e.persistentModelID)
        } else {
            selectedExercises.insert(e.persistentModelID)
        }
    }

    private func savePlan() {
        let names = exercises.filter { selectedExercises.contains($0.persistentModelID) }.map(\.name)
        modelContext.insert(WorkoutPlan(
            name: planName.trimmingCharacters(in: .whitespaces),
            goal: selectedGoal, duration: selectedDuration, exerciseNames: names
        ))
        dismiss()
    }
}

#Preview {
    CreatePlanView().modelContainer(for: [Exercise.self, WorkoutPlan.self], inMemory: true)
}
