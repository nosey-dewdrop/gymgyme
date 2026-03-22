import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddExercise = false
    @State private var showSettings = false
    @State private var expandedExerciseId: PersistentIdentifier?
    @State private var logExercise: Exercise?
    @State private var chartExercise: Exercise?

    private var lastAnyWorkout: Date? {
        exercises.flatMap { $0.sets }.compactMap { $0.timestamp }.max()
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
                VStack(alignment: .leading, spacing: 2) {
                    TypewriterTitle()
                        .padding(.bottom, 8)

                    if let days = daysSinceAnyWorkout, days >= 1 {
                        termLine(bullet: "!", color: days >= 5 ? DoodleTheme.red : DoodleTheme.yellow,
                                 text: "\(days) day\(days == 1 ? "" : "s") since last workout")
                    }

                    streakSection

                    if exercises.isEmpty {
                        Text("").frame(height: 20)
                        termLine(bullet: "~", color: DoodleTheme.dim, text: "no exercises yet")
                        termLine(bullet: " ", color: DoodleTheme.dim, text: "tap + to add your first exercise")
                    } else {
                        Text("").frame(height: 8)
                        termLine(bullet: "─", color: DoodleTheme.dim, text: "exercises (\(exercises.count))")
                        Text("").frame(height: 4)

                        ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                            exerciseRow(exercise, index: index)
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(DoodleTheme.green)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddExercise = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(DoodleTheme.green)
                    }
                }
            }
            .sheet(isPresented: $showAddExercise) { AddExerciseView() }
            .sheet(item: $logExercise) { exercise in LogWorkoutView(exercise: exercise) }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $chartExercise) { exercise in ProgressChartView(exercise: exercise) }
            .onAppear {
                NotificationManager.shared.requestPermission()
                NotificationManager.shared.scheduleInactivityReminder(lastWorkoutDate: lastAnyWorkout)
            }
        }
    }

    private func exerciseRow(_ exercise: Exercise, index: Int) -> some View {
        let color = DoodleTheme.color(for: index)
        let lastSet = exercise.sets.sorted { $0.timestamp > $1.timestamp }.first
        let hasPR = exercise.sets.contains { $0.isPersonalRecord }
        let isExpanded = expandedExerciseId == exercise.persistentModelID

        return VStack(alignment: .leading, spacing: 1) {
            // main row — tap to expand
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 0) {
                    Text("● ")
                        .font(DoodleTheme.mono)
                        .foregroundStyle(color)
                    Text(exercise.name)
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.fg)
                    if hasPR {
                        Text(" ★")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.yellow)
                    }
                }

                HStack(spacing: 0) {
                    Text("  ")
                    if let lastSet {
                        let days = Calendar.current.dateComponents([.day], from: lastSet.timestamp, to: Date()).day ?? 0
                        let timeText = days == 0 ? "today" : days == 1 ? "yesterday" : "\(days)d ago"
                        Text("last: \(timeText)")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                    } else {
                        Text("no logs yet")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                    }
                    Text(" ")
                    TagChip(tag: exercise.tag)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedExerciseId = nil
                    } else {
                        expandedExerciseId = exercise.persistentModelID
                    }
                }
            }

            // expanded log history
            if isExpanded {
                let sortedSets = exercise.sets.sorted { $0.timestamp > $1.timestamp }
                // group sets by session (same day)
                let grouped = groupSetsByDay(sortedSets)

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(grouped, id: \.date) { group in
                        HStack(spacing: 0) {
                            Text("  ")
                            let dateStr = formatDate(group.date)
                            let setsStr = group.sets.map { "\($0.reps)×\(String(format: "%.0f", $0.weight))" }.joined(separator: ", ")
                            Text(dateStr)
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                            Text(" / ")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                            Text(setsStr)
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.fg)
                            Text(" kg")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            logExercise = exercise
                        } label: {
                            HStack(spacing: 0) {
                                Text("  ")
                                Text("+ log workout")
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.green)
                            }
                        }

                        Button {
                            chartExercise = exercise
                        } label: {
                            Text("~ progress")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.teal)
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.top, 2)
                .transition(.opacity)
            }

            Text("").frame(height: 6)
        }
    }

    private struct DayGroup {
        let date: Date
        let sets: [ExerciseSet]
    }

    private func groupSetsByDay(_ sets: [ExerciseSet]) -> [DayGroup] {
        let calendar = Calendar.current
        var groups: [Date: [ExerciseSet]] = [:]
        for set in sets {
            let day = calendar.startOfDay(for: set.timestamp)
            groups[day, default: []].append(set)
        }
        return groups.keys.sorted(by: >).prefix(10).map { DayGroup(date: $0, sets: groups[$0]!) }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    @ViewBuilder
    private var streakSection: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let allTimestamps = exercises.flatMap { $0.sets }.map { calendar.startOfDay(for: $0.timestamp) }
        let uniqueDays = Set(allTimestamps)

        if !uniqueDays.isEmpty {
            let days: [Bool] = (0..<21).reversed().map { offset in
                guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return false }
                return uniqueDays.contains(date)
            }
            let streak = {
                var s = 0
                for d in days.reversed() { if d { s += 1 } else { break } }
                return s
            }()

            Text("").frame(height: 4)

            HStack(spacing: 0) {
                Text("● ")
                    .font(DoodleTheme.mono)
                    .foregroundStyle(DoodleTheme.purple)
                Text("21d challenge: ")
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)

                ForEach(0..<21, id: \.self) { i in
                    Text(days[i] ? "█" : "░")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(days[i] ? DoodleTheme.green : DoodleTheme.dim.opacity(0.4))
                }

                Text(" \(streak)")
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.green)
            }
        }
    }

    private func termLine(bullet: String, color: Color, text: String) -> some View {
        HStack(spacing: 0) {
            Text("\(bullet) ")
                .font(DoodleTheme.mono)
                .foregroundStyle(color)
            Text(text)
                .font(DoodleTheme.mono)
                .foregroundStyle(DoodleTheme.fg)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Exercise.self, ExerciseSet.self, WorkoutSession.self, UserProfile.self], inMemory: true)
}
