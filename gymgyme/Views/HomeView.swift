import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var exercises: [Exercise]
    @Query(filter: #Predicate<WorkoutPlan> { $0.isActive }) private var activePlans: [WorkoutPlan]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddExercise = false
    @State private var showSettings = false
    @State private var showDiscoverSheet = false
    @State private var expandedExerciseId: PersistentIdentifier?
    @State private var cachedExpandedGroups: [DayGroup] = []
    @State private var logExercise: Exercise?
    @State private var chartExercise: Exercise?
    @State private var exerciseToDelete: Exercise?
    @State private var editSets: [ExerciseSet]?
    @State private var editDate: Date?
    @State private var cachedSortedExercises: [Exercise] = []
    @State private var cachedLastWorkout: Date?
    @State private var cachedMaxDates: [PersistentIdentifier: Date] = [:]
    @State private var cachedHasPR: Set<PersistentIdentifier> = []

    private var daysSinceAnyWorkout: Int? {
        guard let last = cachedLastWorkout else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day
    }

    private func recomputeCache() {
        // precompute max date per exercise into dictionary: O(n*s) total, one pass
        var maxDates: [PersistentIdentifier: Date] = [:]
        var latestDate: Date?
        for exercise in exercises {
            if let setDate = exercise.sets.max(by: { $0.timestamp < $1.timestamp })?.timestamp {
                maxDates[exercise.persistentModelID] = setDate
                if let latest = latestDate {
                    if setDate > latest { latestDate = setDate }
                } else {
                    latestDate = setDate
                }
            }
        }
        cachedLastWorkout = latestDate
        cachedMaxDates = maxDates

        // cache PR status
        var prSet = Set<PersistentIdentifier>()
        for exercise in exercises {
            if exercise.sets.contains(where: { $0.isPersonalRecord }) {
                prSet.insert(exercise.persistentModelID)
            }
        }
        cachedHasPR = prSet

        // sort by dictionary lookup: O(n log n) comparisons at O(1) each
        cachedSortedExercises = exercises.sorted { a, b in
            let aDate = maxDates[a.persistentModelID]
            let bDate = maxDates[b.persistentModelID]
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
                    HStack {
                        HStack(spacing: 0) {
                            ForEach(Self.titleChars, id: \.offset) { i, char in
                                Text(char)
                                    .font(.custom("Menlo-Bold", size: 28))
                                    .foregroundStyle(DoodleTheme.color(for: i))
                            }
                        }
                        Spacer()
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(DoodleTheme.dim)
                        }
                        .accessibilityLabel("settings")
                        Button { showAddExercise = true } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(DoodleTheme.green)
                                .padding(.leading, 12)
                        }
                        .accessibilityLabel("add exercise")
                    }
                    .padding(.bottom, 8)

                    if let days = daysSinceAnyWorkout, days >= 1 {
                        termLine(bullet: "!", color: days >= 5 ? DoodleTheme.red : DoodleTheme.yellow,
                                 text: "\(days) day\(days == 1 ? "" : "s") since last workout")
                    }

                    activeProgramsSection

                    if exercises.isEmpty {
                        Text("").frame(height: 20)
                        termLine(bullet: "~", color: DoodleTheme.dim, text: "start by adding an exercise")
                        Text("  track your sets, reps, and progress")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                        Text("").frame(height: 8)

                        Button { showAddExercise = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("add your first exercise")
                            }
                            .font(DoodleTheme.monoBold)
                            .foregroundStyle(DoodleTheme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(DoodleTheme.green)
                            .cornerRadius(8)
                        }

                        Text("").frame(height: 8)

                        Button { showDiscoverSheet = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                Text("browse exercises")
                            }
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(DoodleTheme.surface)
                            .cornerRadius(8)
                        }
                    } else {
                        Text("").frame(height: 8)
                        termLine(bullet: "─", color: DoodleTheme.dim, text: "exercises (\(exercises.count))")
                        Text("").frame(height: 4)

                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(cachedSortedExercises.enumerated()), id: \.element.id) { index, exercise in
                                exerciseRow(exercise, index: index)
                            }
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .navigationBarHidden(true)
            .sheet(isPresented: $showDiscoverSheet) { DiscoverView() }
            .sheet(isPresented: $showAddExercise) { AddExerciseView() }
            .sheet(item: $logExercise) { exercise in LogWorkoutView(exercise: exercise) }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $chartExercise) { exercise in ProgressChartView(exercise: exercise) }
            .sheet(isPresented: Binding(
                get: { editSets != nil && editDate != nil },
                set: { if !$0 { editSets = nil; editDate = nil } }
            )) {
                if let sets = editSets, let date = editDate {
                    EditWorkoutView(sets: sets, date: date)
                }
            }
            .alert("delete exercise?", isPresented: Binding(
                get: { exerciseToDelete != nil },
                set: { if !$0 { exerciseToDelete = nil } }
            )) {
                Button("cancel", role: .cancel) { exerciseToDelete = nil }
                Button("delete", role: .destructive) {
                    if let e = exerciseToDelete { deleteExercise(e) }
                    exerciseToDelete = nil
                }
            } message: {
                Text("all workout logs for this exercise will be deleted")
            }
            .onAppear {
                recomputeCache()
                NotificationManager.shared.requestPermission()
                NotificationManager.shared.scheduleInactivityReminder(lastWorkoutDate: cachedLastWorkout)
            }
            .onChange(of: exercises.count) { _, _ in recomputeCache() }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                recomputeCache()
            }
        }
    }

    private func exerciseRow(_ exercise: Exercise, index: Int) -> some View {
        let color = DoodleTheme.color(for: index)
        let lastSet: ExerciseSet? = {
            guard let maxDate = cachedMaxDates[exercise.persistentModelID] else { return nil }
            return exercise.sets.first { $0.timestamp == maxDate }
        }()
        let hasPR = cachedHasPR.contains(exercise.persistentModelID)
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
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(DoodleTheme.dim)
                }

                HStack(spacing: 0) {
                    Text("  ")
                    if let lastSet {
                        let days = Calendar.current.dateComponents([.day], from: lastSet.timestamp, to: Date()).day ?? 0
                        let timeText = days == 0 ? "today" : days == 1 ? "yesterday" : "\(days)d ago"
                        let atrophyColor = atrophyColor(days: days)
                        let detail: String = {
                            switch exercise.exerciseType {
                            case .weightReps:
                                return "\(lastSet.reps)×\(String(format: "%.0f", lastSet.weight))"
                            case .bodyweight:
                                return "\(lastSet.reps) reps"
                            case .duration:
                                return lastSet.formattedDuration
                            case .cardio:
                                return "\(lastSet.formattedDuration) · \(lastSet.formattedDistance)"
                            }
                        }()
                        Text("\(detail) · \(timeText)")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(atrophyColor)
                    } else {
                        Text("not logged yet")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                    }
                    Text(" ")
                    TagChip(tag: exercise.tag)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Self.hapticLight.impactOccurred()
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedExerciseId = nil
                        cachedExpandedGroups = []
                    } else {
                        expandedExerciseId = exercise.persistentModelID
                        let sortedSets = exercise.sets.sorted { $0.timestamp > $1.timestamp }
                        cachedExpandedGroups = groupSetsByDay(sortedSets)
                    }
                }
            }

            // expanded log history
            if isExpanded {
                let grouped = cachedExpandedGroups

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(grouped, id: \.date) { group in
                        Button {
                            editSets = group.sets
                            editDate = group.date
                        } label: {
                            HStack(spacing: 0) {
                                Text("  ")
                                let dateStr = formatDate(group.date)
                                let setsStr: String = {
                                    guard let type = group.sets.first?.exercise?.exerciseType else {
                                        return group.sets.map { "\($0.reps)×\(String(format: "%.0f", $0.weight))" }.joined(separator: ", ")
                                    }
                                    switch type {
                                    case .weightReps:
                                        return group.sets.map { "\($0.reps)×\(String(format: "%.0f", $0.weight))" }.joined(separator: ", ")
                                    case .bodyweight:
                                        return group.sets.map { "\($0.reps) reps" }.joined(separator: ", ")
                                    case .duration:
                                        return group.sets.map { $0.formattedDuration }.joined(separator: ", ")
                                    case .cardio:
                                        return group.sets.map { "\($0.formattedDuration) · \($0.formattedDistance)" }.joined(separator: ", ")
                                    }
                                }()
                                Text(dateStr)
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.dim)
                                Text(" / ")
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.dim)
                                Text(setsStr)
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.fg)
                                Spacer()
                                Image(systemName: "pencil")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DoodleTheme.dim)
                            }
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
                            Text("chart")
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
        .contextMenu {
            Button(role: .destructive) {
                exerciseToDelete = exercise
            } label: {
                Label("delete", systemImage: "trash")
            }
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
        return groups.keys.sorted(by: >).prefix(10).map { DayGroup(date: $0, sets: groups[$0] ?? []) }
    }

    private static let titleChars: [(offset: Int, element: String)] = "exercises".enumerated().map { ($0.offset, String($0.element)) }

    private static let hapticLight: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        return g
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()

    private func formatDate(_ date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    @ViewBuilder
    private var activeProgramsSection: some View {
        if !activePlans.isEmpty {
            Text("").frame(height: 4)
            termLine(bullet: "─", color: DoodleTheme.dim, text: "active programs")
            Text("").frame(height: 2)

            ForEach(activePlans) { plan in
                HStack(spacing: 0) {
                    Text("  ● ")
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.green)
                    Text(plan.name)
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.fg)
                    Text(" · \(plan.exerciseNames.count) exercises")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.dim)
                }
            }
        }
    }

    private func atrophyColor(days: Int) -> Color {
        if days <= 3 { return DoodleTheme.green }
        if days <= 7 { return DoodleTheme.yellow }
        if days <= 30 { return DoodleTheme.red }
        return DoodleTheme.dim
    }

    private func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
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
