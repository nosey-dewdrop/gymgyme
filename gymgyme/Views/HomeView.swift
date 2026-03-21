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
                VStack(spacing: 14) {
                    if let days = daysSinceAnyWorkout, days >= 1 {
                        InactivityBanner(days: days)
                    } else if daysSinceAnyWorkout == nil && !exercises.isEmpty {
                        InactivityBanner(days: nil)
                    }

                    StreakCard(exercises: exercises)

                    if exercises.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 44))
                                .foregroundStyle(DoodleTheme.inkDim)
                            Text("no exercises yet")
                                .font(DoodleTheme.handwritten(18))
                                .foregroundStyle(DoodleTheme.inkLight)
                            Text("tap + to add your first exercise")
                                .font(DoodleTheme.caption())
                                .foregroundStyle(DoodleTheme.inkDim)
                        }
                        .padding(.top, 80)
                    } else {
                        ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseCard(exercise: exercise, colorIndex: index)
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
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(DoodleTheme.inkLight)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(DoodleTheme.accent)
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

    private var isUrgent: Bool { (days ?? 0) >= 5 }
    private var color: Color { isUrgent ? DoodleTheme.red : DoodleTheme.yellow }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isUrgent ? "exclamationmark.triangle.fill" : "clock")
                .foregroundStyle(color)

            if let days {
                Text("\(days) day\(days == 1 ? "" : "s") since last workout")
                    .font(DoodleTheme.mono(13))
                    .foregroundStyle(DoodleTheme.ink)
            } else {
                Text("no workouts logged yet")
                    .font(DoodleTheme.mono(13))
                    .foregroundStyle(DoodleTheme.ink)
            }
            Spacer()
        }
        .padding()
        .background(color.opacity(0.08))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 3)
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
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ColoredHeader("21 DAY CHALLENGE", color: DoodleTheme.purple)
                    Spacer()
                    Text("\(currentStreak) streak")
                        .font(DoodleTheme.mono(12))
                        .foregroundStyle(DoodleTheme.green)
                }

                HStack(spacing: 3) {
                    ForEach(0..<21, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(last21Days[index] ? DoodleTheme.green : DoodleTheme.inkDim.opacity(0.4))
                            .frame(height: 14)
                            .shadow(color: last21Days[index] ? DoodleTheme.green.opacity(0.4) : .clear, radius: 4)
                    }
                }
            }
            .glowCard(color: DoodleTheme.purple)
        }
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    let exercise: Exercise
    let colorIndex: Int

    private var accentColor: Color {
        DoodleTheme.titleColor(for: colorIndex)
    }

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
                return "\(months) mo ago"
            }
            return "\(days)d ago"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accentColor)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(DoodleTheme.handwritten(16))
                        .foregroundStyle(DoodleTheme.ink)
                    if hasPR {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                            .foregroundStyle(DoodleTheme.yellow)
                    }
                }

                HStack(spacing: 8) {
                    if let lastSet, let timeAgo = timeAgoText {
                        Text(timeAgo)
                            .font(DoodleTheme.mono(12))
                            .foregroundStyle(DoodleTheme.inkLight)
                        Text("/")
                            .foregroundStyle(DoodleTheme.inkDim)
                        Text("\(String(format: "%.0f", lastSet.weight)) kg")
                            .font(DoodleTheme.mono(12))
                            .foregroundStyle(DoodleTheme.ink)
                    } else {
                        Text("no logs yet")
                            .font(DoodleTheme.mono(12))
                            .foregroundStyle(DoodleTheme.inkDim)
                    }
                }
            }

            Spacer()

            TagChip(tag: exercise.tag)
        }
        .glowCard(color: accentColor)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Exercise.self, ExerciseSet.self, WorkoutSession.self, UserProfile.self], inMemory: true)
}
