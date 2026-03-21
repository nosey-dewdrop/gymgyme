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

    private var missingMuscleGroups: [MuscleGroup] {
        let coveredGroups = exercises
            .filter { selectedExercises.contains($0.persistentModelID) }
            .map(\.muscleGroup)
        let coveredSet = Set(coveredGroups)

        let requiredGroups: [MuscleGroup]
        switch selectedGoal {
        case .fullBody:
            requiredGroups = MuscleGroup.allCases
        case .upper:
            requiredGroups = [.chest, .back, .shoulders, .biceps, .triceps]
        case .lower:
            requiredGroups = [.legs, .glutes, .core]
        }

        return requiredGroups.filter { !coveredSet.contains($0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Plan name", text: $planName)
                        .font(DoodleTheme.body())
                } header: {
                    Text("Name")
                }
                .listRowBackground(DoodleTheme.cardBackground)

                Section {
                    Picker("Goal", selection: $selectedGoal) {
                        ForEach(PlanGoal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                    .font(DoodleTheme.body())

                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(PlanDuration.allCases, id: \.self) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }
                    .font(DoodleTheme.body())
                } header: {
                    Text("Settings")
                }
                .listRowBackground(DoodleTheme.cardBackground)

                Section {
                    if exercises.isEmpty {
                        Text("Add exercises in the Workout tab first")
                            .font(DoodleTheme.body())
                            .foregroundStyle(DoodleTheme.inkLight)
                    } else {
                        ForEach(exercises) { exercise in
                            Button {
                                toggleExercise(exercise)
                            } label: {
                                HStack {
                                    Image(systemName: exercise.muscleGroup.icon)
                                        .frame(width: 30)
                                    VStack(alignment: .leading) {
                                        Text(exercise.name)
                                            .font(DoodleTheme.body())
                                        Text(exercise.muscleGroup.displayName)
                                            .font(DoodleTheme.caption())
                                            .foregroundStyle(DoodleTheme.inkLight)
                                    }
                                    Spacer()
                                    if selectedExercises.contains(exercise.persistentModelID) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(DoodleTheme.accent)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(DoodleTheme.inkLight)
                                    }
                                }
                                .foregroundStyle(DoodleTheme.ink)
                            }
                        }
                    }
                } header: {
                    Text("Exercises")
                }
                .listRowBackground(DoodleTheme.cardBackground)

                if !missingMuscleGroups.isEmpty {
                    Section {
                        ForEach(missingMuscleGroups) { group in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(DoodleTheme.yellow)
                                Text("No \(group.displayName.lowercased()) exercise!")
                                    .font(DoodleTheme.body())
                                    .foregroundStyle(DoodleTheme.ink)
                            }
                        }
                    } header: {
                        Text("Missing Muscle Groups")
                    }
                    .listRowBackground(DoodleTheme.yellow.opacity(0.1))
                }
            }
            .scrollContentBackground(.hidden)
            .background(DoodleTheme.background)
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        savePlan()
                    }
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
