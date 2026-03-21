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

    private var selectedTags: Set<String> {
        Set(exercises.filter { selectedExercises.contains($0.persistentModelID) }.map(\.tag))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        ColoredHeader("NAME", color: DoodleTheme.blue)
                        TextField("plan name", text: $planName)
                            .font(DoodleTheme.body())
                            .foregroundStyle(DoodleTheme.ink)
                            .padding()
                            .background(DoodleTheme.cardBackgroundLight)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DoodleTheme.blue.opacity(0.3), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ColoredHeader("SETTINGS", color: DoodleTheme.orange)

                        VStack(spacing: 0) {
                            Picker("Goal", selection: $selectedGoal) {
                                ForEach(PlanGoal.allCases, id: \.self) { goal in
                                    Text(goal.rawValue).tag(goal)
                                }
                            }
                            .tint(DoodleTheme.orange)

                            Divider().background(DoodleTheme.inkDim)

                            Picker("Duration", selection: $selectedDuration) {
                                ForEach(PlanDuration.allCases, id: \.self) { duration in
                                    Text(duration.rawValue).tag(duration)
                                }
                            }
                            .tint(DoodleTheme.orange)
                        }
                        .padding()
                        .background(DoodleTheme.cardBackgroundLight)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DoodleTheme.orange.opacity(0.3), lineWidth: 1)
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ColoredHeader("EXERCISES", color: DoodleTheme.green)

                        if exercises.isEmpty {
                            Text("add exercises from the Home tab first")
                                .font(DoodleTheme.mono(13))
                                .foregroundStyle(DoodleTheme.inkDim)
                                .padding()
                        } else {
                            VStack(spacing: 2) {
                                ForEach(exercises) { exercise in
                                    Button {
                                        toggleExercise(exercise)
                                    } label: {
                                        HStack {
                                            Text(exercise.name)
                                                .font(DoodleTheme.body())
                                                .foregroundStyle(DoodleTheme.ink)
                                            Spacer()
                                            TagChip(tag: exercise.tag)
                                            Image(systemName: selectedExercises.contains(exercise.persistentModelID) ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(selectedExercises.contains(exercise.persistentModelID) ? DoodleTheme.green : DoodleTheme.inkDim)
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal)
                                    }

                                    if exercise.id != exercises.last?.id {
                                        Divider().background(DoodleTheme.inkDim.opacity(0.3))
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .background(DoodleTheme.cardBackgroundLight)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DoodleTheme.green.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding()
            }
            .background(DoodleTheme.background)
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DoodleTheme.inkLight)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        savePlan()
                    }
                    .foregroundStyle(DoodleTheme.green)
                    .disabled(planName.trimmingCharacters(in: .whitespaces).isEmpty || selectedExercises.isEmpty)
                }
            }
        }
    }

    private func toggleExercise(_ exercise: Exercise) {
        if selectedExercises.contains(exercise.persistentModelID) {
            selectedExercises.remove(exercise.persistentModelID)
        } else {
            selectedExercises.insert(exercise.persistentModelID)
        }
    }

    private func savePlan() {
        let names = exercises
            .filter { selectedExercises.contains($0.persistentModelID) }
            .map(\.name)

        let plan = WorkoutPlan(
            name: planName.trimmingCharacters(in: .whitespaces),
            goal: selectedGoal,
            duration: selectedDuration,
            exerciseNames: names
        )
        modelContext.insert(plan)
        dismiss()
    }
}

#Preview {
    CreatePlanView()
        .modelContainer(for: [Exercise.self, WorkoutPlan.self], inMemory: true)
}
