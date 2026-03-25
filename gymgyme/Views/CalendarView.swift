import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var allSets: [ExerciseSet]
    @Query private var plans: [WorkoutPlan]
    @Query private var dayPrograms: [DayProgram]
    @Query private var profiles: [UserProfile]
    @Query(sort: \Meal.timestamp, order: .reverse) private var allMeals: [Meal]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date? = nil
    @State private var displayedMonth: Date = Date()
    @State private var showPlanPicker = false
    @State private var showSettings = false
    @State private var showAddMeal = false
    @State private var mealToDelete: Meal?
    @State private var cachedWorkoutDays: Set<Date> = []
    @State private var cachedProgramDays: [Date: DayProgram] = [:]
    @State private var cachedCalendarCells: [CalendarCell] = []
    @State private var cachedSetsByDay: [Date: [ExerciseSet]] = [:]
    @State private var cachedMealsByDay: [Date: [Meal]] = [:]
    @State private var cachedTodayStart: Date = Calendar.current.startOfDay(for: Date())

    private struct CalendarCell: Identifiable {
        let id: Int // index
        let date: Date?
        let dayNumber: Int
        let isToday: Bool
        let hasWorkout: Bool
        let hasProgram: Bool
        let isPast: Bool
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private static let dayDetailFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    private var weightUnit: String {
        (profiles.first?.useLbs ?? false) ? "lbs" : "kg"
    }

    private static let calendar = Calendar.current
    private var calendar: Calendar { Self.calendar }
    private static let gridColumns = Array(repeating: GridItem(.flexible()), count: 7)

    private func rebuildCache() {
        cachedWorkoutDays = Set(allSets.map { calendar.startOfDay(for: $0.timestamp) })
        var map: [Date: DayProgram] = [:]
        for dp in dayPrograms {
            map[calendar.startOfDay(for: dp.date)] = dp
        }
        cachedProgramDays = map
        rebuildDaysInMonth()
        rebuildDayDetails()
    }

    private func rebuildDaysInMonth() {
        let todayStart = calendar.startOfDay(for: Date())
        cachedTodayStart = todayStart
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { cachedCalendarCells = []; return }
        let weekdayOffset = (calendar.component(.weekday, from: firstDay) + 5) % 7
        var cells: [CalendarCell] = []
        cells.reserveCapacity(weekdayOffset + range.count)
        for i in 0..<weekdayOffset {
            cells.append(CalendarCell(id: i, date: nil, dayNumber: 0, isToday: false, hasWorkout: false, hasProgram: false, isPast: false))
        }
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                let start = calendar.startOfDay(for: date)
                cells.append(CalendarCell(
                    id: weekdayOffset + day - 1,
                    date: date,
                    dayNumber: day,
                    isToday: start == todayStart,
                    hasWorkout: cachedWorkoutDays.contains(start),
                    hasProgram: cachedProgramDays[start] != nil,
                    isPast: start < todayStart
                ))
            }
        }
        cachedCalendarCells = cells
    }

    private func rebuildDayDetails() {
        // pre-group sets by day
        var setsByDay: [Date: [ExerciseSet]] = [:]
        for set in allSets {
            let day = calendar.startOfDay(for: set.timestamp)
            setsByDay[day, default: []].append(set)
        }
        // sort each day's sets
        for (day, sets) in setsByDay {
            setsByDay[day] = sets.sorted { $0.timestamp < $1.timestamp }
        }
        cachedSetsByDay = setsByDay

        // pre-group meals by day
        var mealsByDay: [Date: [Meal]] = [:]
        for meal in allMeals {
            let day = calendar.startOfDay(for: meal.timestamp)
            mealsByDay[day, default: []].append(meal)
        }
        cachedMealsByDay = mealsByDay
    }

    private var monthTitle: String {
        Self.monthFormatter.string(from: displayedMonth)
    }

    private func setsForDate(_ date: Date) -> [ExerciseSet] {
        cachedSetsByDay[calendar.startOfDay(for: date)] ?? []
    }

    private func programForDate(_ date: Date) -> DayProgram? {
        cachedProgramDays[calendar.startOfDay(for: date)]
    }

    private func mealsForDate(_ date: Date) -> [Meal] {
        cachedMealsByDay[calendar.startOfDay(for: date)] ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("calendar")
                            .font(.custom("Menlo-Bold", size: 28))
                            .foregroundStyle(DoodleTheme.teal)
                        Spacer()
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(DoodleTheme.dim)
                        }
                    }
                    .padding(.bottom, 8)

                    // month nav
                    HStack {
                        Button {
                            displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                        } label: {
                            Text("◀")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.dim)
                        }

                        Spacer()

                        Text(monthTitle)
                            .font(DoodleTheme.monoBold)
                            .foregroundStyle(DoodleTheme.fg)

                        Spacer()

                        Button {
                            displayedMonth = Date()
                            selectedDate = Date()
                        } label: {
                            Text("today")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.green)
                        }
                        .padding(.trailing, 8)

                        Button {
                            displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                        } label: {
                            Text("▶")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.dim)
                        }
                    }
                    .padding(.bottom, 4)

                    // weekday headers
                    let weekdays = ["mo", "tu", "we", "th", "fr", "sa", "su"]
                    LazyVGrid(columns: Self.gridColumns, spacing: 4) {
                        ForEach(weekdays, id: \.self) { day in
                            Text(day)
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // calendar grid
                    let selectedStart = selectedDate.map { calendar.startOfDay(for: $0) }
                    LazyVGrid(columns: Self.gridColumns, spacing: 4) {
                        ForEach(cachedCalendarCells) { cell in
                            if let date = cell.date {
                                let isSelected = selectedStart.map { $0 == calendar.startOfDay(for: date) } ?? false
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        if isSelected { selectedDate = nil }
                                        else { selectedDate = date }
                                    }
                                } label: {
                                    VStack(spacing: 2) {
                                        Text("\(cell.dayNumber)")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(
                                                isSelected ? DoodleTheme.bg :
                                                cell.isToday ? DoodleTheme.green :
                                                DoodleTheme.fg
                                            )
                                        Circle()
                                            .fill(dotColor(cell: cell, isSelected: isSelected))
                                            .frame(width: 5, height: 5)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? DoodleTheme.green : .clear)
                                    .cornerRadius(6)
                                }
                            } else {
                                Text("")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                        }
                    }

                    // selected day detail
                    if let date = selectedDate {
                        let sets = setsForDate(date)
                        let dayProg = programForDate(date)
                        Text("").frame(height: 8)
                        termLine(bullet: "─", color: DoodleTheme.dim, text: Self.dayDetailFormatter.string(from: date))

                        // assigned program
                        if let dp = dayProg {
                            Text("").frame(height: 4)
                            HStack(spacing: 0) {
                                Text("  ● ")
                                    .font(DoodleTheme.mono)
                                    .foregroundStyle(DoodleTheme.orange)
                                Text(dp.planName)
                                    .font(DoodleTheme.monoBold)
                                    .foregroundStyle(DoodleTheme.fg)
                            }
                            ForEach(dp.exerciseNames, id: \.self) { name in
                                HStack(spacing: 0) {
                                    Text("    ")
                                    Text(name)
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.dim)
                                }
                            }
                        }

                        // logged workouts
                        if !sets.isEmpty {
                            Text("").frame(height: 4)
                            let grouped = Dictionary(grouping: sets) { $0.exercise?.name ?? "unknown" }
                            let sortedNames = grouped.keys.sorted()
                            let unit = weightUnit
                            ForEach(sortedNames, id: \.self) { name in
                                let exerciseSets = grouped[name] ?? []
                                let tag = exerciseSets.first?.exercise?.tag ?? ""
                                let detail = Self.formatSetDetail(exerciseSets)
                                HStack(spacing: 0) {
                                    Text("  ● ")
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.color(for: name))
                                    Text(name)
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.fg)
                                    Text(" ")
                                    TagChip(tag: tag)
                                }
                                HStack(spacing: 0) {
                                    Text("    ")
                                    Text(detail)
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.dim)
                                    Text(" \(unit)")
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.dim)
                                }
                            }
                        }

                        // meals for this day
                        let dayMeals = mealsForDate(date)
                        if !dayMeals.isEmpty {
                            Text("").frame(height: 8)
                            termLine(bullet: "─", color: DoodleTheme.dim, text: "meals")
                            Text("").frame(height: 2)
                            let totalCal = dayMeals.reduce(0) { $0 + $1.calories }
                            let totalProtein = dayMeals.reduce(0.0) { $0 + $1.protein }
                            HStack(spacing: 0) {
                                Text("  ")
                                Text("\(totalCal) cal")
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.orange)
                                Text(" · ")
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.dim)
                                Text("\(String(format: "%.0f", totalProtein))g protein")
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.blue)
                            }
                            ForEach(dayMeals, id: \.id) { meal in
                                HStack(spacing: 0) {
                                    Text("  ")
                                    Text(meal.name)
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.fg)
                                    Spacer()
                                    Text("\(meal.calories) cal")
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.dim)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        mealToDelete = meal
                                    } label: {
                                        Label("delete", systemImage: "trash")
                                    }
                                }
                            }
                        }

                        if sets.isEmpty && dayProg == nil && dayMeals.isEmpty {
                            let isFuture = date > calendar.startOfDay(for: Date())
                            HStack(spacing: 0) {
                                Text("  ")
                                Text(isFuture ? "upcoming" : "rest day")
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.dim)
                            }
                        }

                        // action buttons
                        Text("").frame(height: 4)
                        Button {
                            showPlanPicker = true
                        } label: {
                            HStack(spacing: 0) {
                                Text("  ")
                                Text(dayProg == nil ? "+ assign a program" : "~ change program")
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.orange)
                            }
                        }

                        if dayProg != nil {
                            Button {
                                if let dp = dayProg {
                                    modelContext.delete(dp)
                                }
                            } label: {
                                HStack(spacing: 0) {
                                    Text("  ")
                                    Text("- remove program")
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.red)
                                }
                            }
                        }

                        Button {
                            showAddMeal = true
                        } label: {
                            HStack(spacing: 0) {
                                Text("  ")
                                Text("+ add meal")
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.orange)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .navigationBarHidden(true)
            .onAppear { rebuildCache() }
            .onChange(of: allSets.count) { _, _ in rebuildCache() }
            .onChange(of: allMeals.count) { _, _ in rebuildDayDetails() }
            .onChange(of: dayPrograms.count) { _, _ in rebuildCache() }
            .onChange(of: displayedMonth) { _, _ in rebuildDaysInMonth() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showPlanPicker) {
                planPickerSheet
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealSheet(date: selectedDate ?? Date()) { meal in
                    modelContext.insert(meal)
                    showAddMeal = false
                }
            }
            .alert("delete meal?", isPresented: Binding(
                get: { mealToDelete != nil },
                set: { if !$0 { mealToDelete = nil } }
            )) {
                Button("cancel", role: .cancel) { mealToDelete = nil }
                Button("delete", role: .destructive) {
                    if let m = mealToDelete { modelContext.delete(m) }
                    mealToDelete = nil
                }
            } message: {
                Text("this meal will be deleted")
            }
        }
    }

    // MARK: - Plan Picker Sheet

    private var planPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ColoredHeader("assign a program", color: DoodleTheme.orange)
                        .padding(.top, 20)

                    if plans.isEmpty {
                        Text("no programs yet")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.dim)
                            .padding(.top, 20)
                    } else {
                        ForEach(plans) { plan in
                            Button {
                                assignProgram(plan)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 0) {
                                        Text("● ")
                                            .font(DoodleTheme.mono)
                                            .foregroundStyle(DoodleTheme.orange)
                                        Text(plan.name)
                                            .font(DoodleTheme.monoBold)
                                            .foregroundStyle(DoodleTheme.fg)
                                    }
                                    Text("  \(plan.exerciseNames.count) exercises")
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.dim)
                                    Text("").frame(height: 4)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { showPlanPicker = false }
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.dim)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func assignProgram(_ plan: WorkoutPlan) {
        guard let date = selectedDate else { return }
        let dayStart = calendar.startOfDay(for: date)
        // remove existing assignment for this day
        if let existing = programForDate(dayStart) {
            modelContext.delete(existing)
        }
        modelContext.insert(DayProgram(date: dayStart, plan: plan))
        showPlanPicker = false
    }

    private func dotColor(cell: CalendarCell, isSelected: Bool) -> Color {
        if cell.hasProgram && cell.hasWorkout { return DoodleTheme.green }
        if cell.hasProgram && !cell.hasWorkout && cell.isPast { return DoodleTheme.red }
        if cell.hasWorkout { return DoodleTheme.green }
        return .clear
    }

    private static func formatSetDetail(_ sets: [ExerciseSet]) -> String {
        sets.map { "\($0.reps)×\(Int($0.weight))" }.joined(separator: ", ")
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
    CalendarView()
        .modelContainer(for: [ExerciseSet.self, Exercise.self, WorkoutSession.self, DayProgram.self, WorkoutPlan.self], inMemory: true)
}
