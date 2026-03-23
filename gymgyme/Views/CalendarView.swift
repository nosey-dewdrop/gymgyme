import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var allSets: [ExerciseSet]
    @Query private var plans: [WorkoutPlan]
    @Query private var dayPrograms: [DayProgram]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date? = nil
    @State private var displayedMonth: Date = Date()
    @State private var showPlanPicker = false

    private var calendar: Calendar { Calendar.current }

    private var workoutDays: Set<Date> {
        Set(allSets.map { calendar.startOfDay(for: $0.timestamp) })
    }

    private var programDays: [Date: DayProgram] {
        var map: [Date: DayProgram] = [:]
        for dp in dayPrograms {
            map[calendar.startOfDay(for: dp.date)] = dp
        }
        return map
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }
        let weekdayOffset = (calendar.component(.weekday, from: firstDay) + 5) % 7

        var days: [Date?] = Array(repeating: nil, count: weekdayOffset)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    private func setsForDate(_ date: Date) -> [ExerciseSet] {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        return allSets.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private func programForDate(_ date: Date) -> DayProgram? {
        programDays[calendar.startOfDay(for: date)]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("calendar")
                        .font(.custom("Menlo-Bold", size: 28))
                        .foregroundStyle(DoodleTheme.teal)
                        .padding(.bottom, 4)

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
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                        ForEach(weekdays, id: \.self) { day in
                            Text(day)
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                        ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                            if let date {
                                let isToday = calendar.isDateInToday(date)
                                let hasWorkout = workoutDays.contains(calendar.startOfDay(for: date))
                                let hasProgram = programForDate(date) != nil
                                let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false

                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        if isSelected { selectedDate = nil }
                                        else { selectedDate = date }
                                    }
                                } label: {
                                    VStack(spacing: 2) {
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(
                                                isSelected ? DoodleTheme.bg :
                                                isToday ? DoodleTheme.green :
                                                DoodleTheme.fg
                                            )

                                        HStack(spacing: 2) {
                                            if hasWorkout {
                                                Circle()
                                                    .fill(DoodleTheme.green)
                                                    .frame(width: 5, height: 5)
                                            }
                                            if hasProgram {
                                                Circle()
                                                    .fill(DoodleTheme.orange)
                                                    .frame(width: 5, height: 5)
                                            }
                                            if !hasWorkout && !hasProgram {
                                                Circle()
                                                    .fill(.clear)
                                                    .frame(width: 5, height: 5)
                                            }
                                        }
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
                        let formatter = { () -> DateFormatter in
                            let f = DateFormatter()
                            f.dateFormat = "d MMMM yyyy"
                            return f
                        }()

                        Text("").frame(height: 8)
                        termLine(bullet: "─", color: DoodleTheme.dim, text: formatter.string(from: date))

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
                            ForEach(grouped.keys.sorted(), id: \.self) { name in
                                let exerciseSets = grouped[name]!
                                let tag = exerciseSets.first?.exercise?.tag ?? ""
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
                                    let detail = exerciseSets.map { "\($0.reps)×\(String(format: "%.0f", $0.weight))" }.joined(separator: ", ")
                                    Text(detail)
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.dim)
                                    Text(" kg")
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.dim)
                                }
                            }
                        }

                        if sets.isEmpty && dayProg == nil {
                            HStack(spacing: 0) {
                                Text("  ")
                                Text("rest day")
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.dim)
                            }
                        }

                        // assign program button
                        Text("").frame(height: 4)
                        Button {
                            showPlanPicker = true
                        } label: {
                            HStack(spacing: 0) {
                                Text("  ")
                                Text(dayProg == nil ? "+ assign program" : "~ change program")
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
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPlanPicker) {
                planPickerSheet
            }
        }
    }

    // MARK: - Plan Picker Sheet

    private var planPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ColoredHeader("assign program", color: DoodleTheme.orange)
                        .padding(.top, 8)

                    if plans.isEmpty {
                        Text("no programs yet")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.dim)
                            .padding(.top, 8)
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
