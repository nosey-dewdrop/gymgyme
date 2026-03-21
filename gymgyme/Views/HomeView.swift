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
            ZStack {
                // Background with subtle gradient
                DoodleTheme.background.ignoresSafeArea()
                LinearGradient(
                    colors: [
                        DoodleTheme.accent.opacity(0.03),
                        DoodleTheme.background,
                        DoodleTheme.blue.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        if let days = daysSinceAnyWorkout, days >= 1 {
                            InactivityBanner(days: days)
                        } else if daysSinceAnyWorkout == nil && !exercises.isEmpty {
                            InactivityBanner(days: nil)
                        }

                        StreakCard(exercises: exercises)

                        if exercises.isEmpty {
                            EmptyHomeView()
                        } else {
                            ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                                ExerciseCard(exercise: exercise, colorIndex: index)
                                    .onTapGesture {
                                        selectedExercise = exercise
                                    }
                            }
                        }

                        // Bottom spacer for tab bar
                        Spacer().frame(height: 80)
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(DoodleTheme.inkLight)
                            .shadow(color: DoodleTheme.purple.opacity(0.3), radius: 4)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("gymgyme")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DoodleTheme.accent, DoodleTheme.orange, DoodleTheme.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddExercise = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(DoodleTheme.accent)
                            .shadow(color: DoodleTheme.accent.opacity(0.5), radius: 6)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Empty Home

struct EmptyHomeView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(DoodleTheme.accent.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulse ? 1.1 : 1.0)

                Circle()
                    .fill(DoodleTheme.accent.opacity(0.05))
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulse ? 1.15 : 1.0)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DoodleTheme.accent, DoodleTheme.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: DoodleTheme.accent.opacity(0.4), radius: 10)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }

            VStack(spacing: 8) {
                Text("no exercises yet")
                    .font(DoodleTheme.handwritten(20))
                    .foregroundStyle(DoodleTheme.ink)

                Text("tap ")
                    .font(DoodleTheme.mono(13))
                    .foregroundStyle(DoodleTheme.inkDim)
                +
                Text("+ ")
                    .font(DoodleTheme.mono(13))
                    .foregroundStyle(DoodleTheme.accent)
                +
                Text("to add your first exercise")
                    .font(DoodleTheme.mono(13))
                    .foregroundStyle(DoodleTheme.inkDim)
            }

            // Decorative dots
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(DoodleTheme.titleColor(for: i))
                        .frame(width: 6, height: 6)
                        .opacity(0.5)
                }
            }
        }
        .padding(.top, 60)
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
                .shadow(color: color.opacity(0.5), radius: 4)

            if let days {
                Text("\(days)")
                    .font(DoodleTheme.handwritten(16))
                    .foregroundStyle(color)
                +
                Text(" day\(days == 1 ? "" : "s") since last workout")
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
                .stroke(color.opacity(0.25), lineWidth: 1)
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
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(DoodleTheme.orange)
                            .shadow(color: DoodleTheme.orange.opacity(0.5), radius: 4)
                        Text("21 DAY CHALLENGE")
                            .font(DoodleTheme.mono(12))
                            .foregroundStyle(DoodleTheme.purple)
                    }
                    Spacer()
                    Text("\(currentStreak)")
                        .font(DoodleTheme.handwritten(18))
                        .foregroundStyle(DoodleTheme.green)
                    +
                    Text(" streak")
                        .font(DoodleTheme.mono(11))
                        .foregroundStyle(DoodleTheme.green.opacity(0.7))
                }

                HStack(spacing: 3) {
                    ForEach(0..<21, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(last21Days[index]
                                  ? DoodleTheme.green
                                  : DoodleTheme.inkDim.opacity(0.3))
                            .frame(height: 16)
                            .shadow(color: last21Days[index] ? DoodleTheme.green.opacity(0.5) : .clear, radius: 4)
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
            // Color bar
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4, height: 40)
                .shadow(color: accentColor.opacity(0.5), radius: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(DoodleTheme.handwritten(16))
                        .foregroundStyle(DoodleTheme.ink)
                    if hasPR {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                            .foregroundStyle(DoodleTheme.yellow)
                            .shadow(color: DoodleTheme.yellow.opacity(0.5), radius: 3)
                    }
                }

                HStack(spacing: 8) {
                    if let lastSet, let timeAgo = timeAgoText {
                        Text(timeAgo)
                            .font(DoodleTheme.mono(12))
                            .foregroundStyle(accentColor.opacity(0.8))
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
