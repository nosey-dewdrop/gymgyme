import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

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
                    ForEach(exercises) { exercise in
                        ExerciseRow(exercise: exercise)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DoodleTheme.background)
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack {
            Image(systemName: exercise.muscleGroup.icon)
                .foregroundStyle(DoodleTheme.accent)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(DoodleTheme.handwritten(16))
                    .foregroundStyle(DoodleTheme.ink)

                Text(exercise.muscleGroup.displayName)
                    .font(DoodleTheme.caption())
                    .foregroundStyle(DoodleTheme.inkLight)
            }
        }
        .listRowBackground(DoodleTheme.cardBackground)
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: [Exercise.self, ExerciseSet.self], inMemory: true)
}
