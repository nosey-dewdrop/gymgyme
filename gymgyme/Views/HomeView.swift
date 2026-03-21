import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddExercise = false
    @State private var selectedExercise: Exercise?
    @State private var showSettings = false

    private var lastAnyWorkout: Date? {
        exercises
            .flatMap { $0.sets }
            .compactMap { $0.timestamp }
            .max()
    }

    private var daysSinceAnyWorkout: Int? {
        guard let last = lastAnyWorkout else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day
    }

    private var sortedExercises: [Exercise] {
        exercises.sorted { a, b in
            let aDate = a.sets.compactMap(\.timestamp).max()
            let bDate = b.sets.compactMap(\.timestamp).max()

            switch (aDate, bDate) {
            case (nil, nil): return a.name < b.name
            case (nil, _): return false
            case (_, nil): return true
            case let (aD?, bD?): return aD > bD
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let days = daysSinceAnyWorkout, days >= 1 {
                        InactivityBanner(days: days)
                    } else if daysSinceAnyWorkout == nil && !exercises.isEmpty {
                        InactivityBanner(days: nil)
                    }

                    StreakCard(exercises: exercises)

                    if exercises.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 48))
                                .foregroundStyle(DoodleTheme.inkLight)
                            Text("No exercises yet")
                                .font(DoodleTheme.handwritten(18))
                                .foregroundStyle(DoodleTheme.ink)
                            Text("Tap + to add your first exercise")
                                .font(DoodleTheme.caption())
                                .foregroundStyle(DoodleTheme.inkLight)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(sortedExercises) { exercise in
                            ExerciseCard(exercise: exercise)
                                .onTapGesture {
                                    selectedExercise = exercise
                                }
                        }
                    }
                }
                .padding()
            }
            .background(DoodleTheme.background)
            .navigationTitle("gymgyme")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(DoodleTheme.ink)
                    }
                }
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                NotificationManager.shared.requestPermission()
                NotificationManager.shared.scheduleInactivityReminder(lastWorkoutDate: lastAnyWorkout)
            }
        }
    }
}

// MARK: - Inactivity Banner

struct InactivityBanner: View {
    let days: Int?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: days != nil && days! >= 5 ? "exclamationmark.triangle.fill" : "clock")
                .foregroundStyle(days != nil && days! >= 5 ? DoodleTheme.red : DoodleTheme.yellow)

            if let days {
                Text("\(days) day\(days == 1 ? "" : "s") since last workout")
                    .font(DoodleTheme.handwritten(15))
                    .foregroundStyle(DoodleTheme.ink)
            } else {
                Text("No workouts logged yet")
                    .font(DoodleTheme.handwritten(15))
                    .foregroundStyle(DoodleTheme.ink)
            }
            Spacer()
        }
        .padding()
        .background((days ?? 0) >= 5 ? DoodleTheme.red.opacity(0.1) : DoodleTheme.yellow.opacity(0.1))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke((days ?? 0) >= 5 ? DoodleTheme.red.opacity(0.3) : DoodleTheme.yellow.opacity(0.3), lineWidth: 1.5)
        )
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let exercises: [Exercise]

    private var last21Days: [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let allTimestamps = exercises.flatMap { $0.sets }.map { calendar.startOfDay(for: $0.timestamp) }
        let uniqueDays = Set(allTimestamps)

        return (0..<21).reversed().map { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return false }
            return uniqueDays.contains(date)
        }
    }

    private var currentStreak: Int {
        var streak = 0
        for worked in last21Days.reversed() {
            if worked { streak += 1 } else { break }
        }
        return streak
    }

    var body: some View {
        if !exercises.isEmpty && exercises.contains(where: { !$0.sets.isEmpty }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("21 Day Challenge")
                        .font(DoodleTheme.handwritten(16))
                        .foregroundStyle(DoodleTheme.ink)
                    Spacer()
                    Text("\(currentStreak) streak")
                        .font(DoodleTheme.caption())
                        .foregroundStyle(DoodleTheme.accent)
                }

                HStack(spacing: 3) {
                    ForEach(0..<21, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(last21Days[index] ? DoodleTheme.green : DoodleTheme.ink.opacity(0.1))
                            .frame(height: 14)
                    }
                }
            }
            .doodleCard()
        }
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    let exercise: Exercise

    private var lastSet: ExerciseSet? {
        exercise.sets
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }

    private var hasPR: Bool {
        exercise.sets.contains { $0.isPersonalRecord }
    }

    private var timeAgoText: String? {
        guard let lastSet else { return nil }
        let days = Calendar.current.dateComponents([.day], from: lastSet.timestamp, to: Date()).day ?? 0
        switch days {
        case 0: return "today"
        case 1: return "yesterday"
        default:
            if days >= 30 {
                let months = days / 30
                return "\(months) month\(months == 1 ? "" : "s") ago"
            }
            return "\(days) days ago"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.muscleGroup.icon)
                .font(.title3)
                .foregroundStyle(DoodleTheme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
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

                if let lastSet, let timeAgo = timeAgoText {
                    Text("\(timeAgo) / \(String(format: "%.0f", lastSet.weight)) kg")
                        .font(DoodleTheme.caption())
                        .foregroundStyle(DoodleTheme.inkLight)
                } else {
                    Text("no logs yet")
                        .font(DoodleTheme.caption())
                        .foregroundStyle(DoodleTheme.inkLight)
                }
            }

            Spacer()

            Text("#\(exercise.muscleGroup.rawValue)")
                .font(DoodleTheme.caption())
                .foregroundStyle(DoodleTheme.accent.opacity(0.7))
        }
        .doodleCard()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Exercise.self, ExerciseSet.self, WorkoutSession.self, UserProfile.self], inMemory: true)
}
