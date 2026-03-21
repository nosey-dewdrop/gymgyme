import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddExercise = false
    @State private var selectedExercise: Exercise?

    var body: some View {
        NavigationStack {
            List {
                if exercises.isEmpty {
                    ContentUnavailableView(
                        "No exercises yet",
                        systemImage: "dumbbell",
                        description: Text("Tap + to add your first exercise")
                    )
                } else {
                    ForEach(MuscleGroup.allCases) { group in
                        let groupExercises = exercises.filter { $0.muscleGroup == group }
                        if !groupExercises.isEmpty {
                            Section {
                                ForEach(groupExercises) { exercise in
                                    ExerciseRow(exercise: exercise)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedExercise = exercise
                                        }
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        modelContext.delete(groupExercises[index])
                                    }
                                }
                            } header: {
                                Text(group.displayName)
                                    .font(DoodleTheme.caption())
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DoodleTheme.background)
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseView()
            }
            .sheet(item: $selectedExercise) { exercise in
                LogWorkoutView(exercise: exercise)
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    private var lastSet: ExerciseSet? {
        exercise.sets
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }

    private var hasPR: Bool {
        exercise.sets.contains { $0.isPersonalRecord }
    }

    var body: some View {
        HStack {
            Image(systemName: exercise.muscleGroup.icon)
                .foregroundStyle(DoodleTheme.accent)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(exercise.name)
                        .font(DoodleTheme.handwritten(16))
                        .foregroundStyle(DoodleTheme.ink)

                    if hasPR {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }

                if let lastSet {
                    let days = Calendar.current.dateComponents([.day], from: lastSet.timestamp, to: Date()).day ?? 0
                    let timeText = days == 0 ? "today" : days == 1 ? "yesterday" : "\(days) days ago"
                    Text("\(timeText) / \(String(format: "%.0f", lastSet.weight)) kg")
                        .font(DoodleTheme.caption())
                        .foregroundStyle(DoodleTheme.inkLight)
                } else {
                    Text("no logs yet")
                        .font(DoodleTheme.caption())
                        .foregroundStyle(DoodleTheme.inkLight)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(DoodleTheme.inkLight)
        }
        .listRowBackground(DoodleTheme.cardBackground)
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: [Exercise.self, ExerciseSet.self, WorkoutSession.self], inMemory: true)
}
