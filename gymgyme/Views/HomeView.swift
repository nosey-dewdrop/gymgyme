import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var exercises: [Exercise]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(MuscleGroup.allCases) { group in
                        MuscleGroupCard(
                            muscleGroup: group,
                            lastWorked: lastWorkoutDate(for: group)
                        )
                    }
                }
                .padding()
            }
            .background(DoodleTheme.background)
            .navigationTitle("gymgyme")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func lastWorkoutDate(for group: MuscleGroup) -> Date? {
        exercises
            .filter { $0.muscleGroup == group }
            .flatMap { $0.sets }
            .compactMap { $0.timestamp }
            .max()
    }
}

struct MuscleGroupCard: View {
    let muscleGroup: MuscleGroup
    let lastWorked: Date?

    private var daysSince: Int? {
        guard let lastWorked else { return nil }
        return Calendar.current.dateComponents([.day], from: lastWorked, to: Date()).day
    }

    private var statusColor: Color {
        guard let days = daysSince else { return DoodleTheme.inkLight }
        switch days {
        case 0...3: return DoodleTheme.green
        case 4...6: return DoodleTheme.yellow
        default: return DoodleTheme.red
        }
    }

    private var statusText: String {
        guard let days = daysSince else { return "no data yet" }
        switch days {
        case 0: return "today"
        case 1: return "yesterday"
        default: return "\(days) days ago"
        }
    }

    var body: some View {
        HStack {
            Image(systemName: muscleGroup.icon)
                .font(.title2)
                .foregroundStyle(statusColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(muscleGroup.displayName)
                    .font(DoodleTheme.handwritten(17))
                    .foregroundStyle(DoodleTheme.ink)

                Text(statusText)
                    .font(DoodleTheme.caption())
                    .foregroundStyle(DoodleTheme.inkLight)
            }

            Spacer()

            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
        }
        .doodleCard()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Exercise.self, ExerciseSet.self], inMemory: true)
}
