import SwiftUI
import SwiftData

struct MealLogView: View {
    @Query(sort: \Meal.timestamp, order: .reverse) private var meals: [Meal]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddMeal = false
    @State private var newName = ""
    @State private var newCalories = ""
    @State private var newNotes = ""

    private var todaysMeals: [Meal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return meals.filter { calendar.startOfDay(for: $0.timestamp) == today }
    }

    private var todaysCalories: Int {
        todaysMeals.reduce(0) { $0 + $1.calories }
    }

    private var weeklyCalories: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return meals.filter { $0.timestamp >= weekAgo }.reduce(0) { $0 + $1.calories }
    }

    private var weeklyAvg: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekMeals = meals.filter { $0.timestamp >= weekAgo }
        let days = Set(weekMeals.map { calendar.startOfDay(for: $0.timestamp) }).count
        guard days > 0 else { return 0 }
        return weekMeals.reduce(0) { $0 + $1.calories } / days
    }

    private var groupedByDay: [(date: Date, meals: [Meal])] {
        let calendar = Calendar.current
        var groups: [Date: [Meal]] = [:]
        for meal in meals {
            let day = calendar.startOfDay(for: meal.timestamp)
            groups[day, default: []].append(meal)
        }
        return groups.keys.sorted(by: >).prefix(14).map { (date: $0, meals: groups[$0]!) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 0) {
                        Text("● ")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.orange)
                        Text("meals")
                            .font(.custom("Menlo-Bold", size: 28))
                            .foregroundStyle(DoodleTheme.orange)
                    }
                    .padding(.bottom, 8)

                    // today summary
                    if !todaysMeals.isEmpty {
                        termLine(bullet: "─", color: DoodleTheme.dim, text: "today")
                        Text("").frame(height: 2)
                        HStack(spacing: 16) {
                            statBox("meals", value: "\(todaysMeals.count)", color: DoodleTheme.orange)
                            statBox("calories", value: "\(todaysCalories)", color: DoodleTheme.yellow)
                        }
                        Text("").frame(height: 4)
                    }

                    // weekly summary
                    if weeklyCalories > 0 {
                        termLine(bullet: "─", color: DoodleTheme.dim, text: "this week")
                        Text("").frame(height: 2)
                        HStack(spacing: 16) {
                            statBox("total", value: "\(weeklyCalories)", color: DoodleTheme.blue)
                            statBox("daily avg", value: "\(weeklyAvg)", color: DoodleTheme.teal)
                        }
                        Text("").frame(height: 8)
                    }

                    // meal history
                    if meals.isEmpty {
                        Text("").frame(height: 20)
                        termLine(bullet: "~", color: DoodleTheme.dim, text: "no meals logged yet")
                        termLine(bullet: " ", color: DoodleTheme.dim, text: "tap + to log your first meal")
                    } else {
                        termLine(bullet: "─", color: DoodleTheme.dim, text: "history")
                        Text("").frame(height: 4)

                        ForEach(groupedByDay, id: \.date) { group in
                            daySection(group.date, meals: group.meals)
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
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddMeal = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(DoodleTheme.orange)
                    }
                }
            }
            .sheet(isPresented: $showAddMeal) {
                addMealSheet
            }
        }
    }

    // MARK: - Day Section

    private func daySection(_ date: Date, meals: [Meal]) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let dayStr = formatter.string(from: date)
        let dayCal = meals.reduce(0) { $0 + $1.calories }

        return VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 0) {
                Text("  ")
                Text(dayStr)
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
                if dayCal > 0 {
                    Text(" / \(dayCal) kcal")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.yellow)
                }
            }

            ForEach(meals, id: \.id) { meal in
                HStack(spacing: 0) {
                    Text("    ")
                    Text(meal.name)
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.fg)
                    if meal.calories > 0 {
                        Text(" \(meal.calories)")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        modelContext.delete(meal)
                    } label: {
                        Label("delete", systemImage: "trash")
                    }
                }
            }

            Text("").frame(height: 4)
        }
    }

    // MARK: - Add Meal Sheet

    private var addMealSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                ColoredHeader("log meal", color: DoodleTheme.orange)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("what did you eat?")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.dim)
                    TextField("", text: $newName)
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.fg)
                        .padding(8)
                        .background(DoodleTheme.surface)
                        .cornerRadius(6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("calories (optional)")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.dim)
                    TextField("", text: $newCalories)
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.fg)
                        .keyboardType(.numberPad)
                        .padding(8)
                        .background(DoodleTheme.surface)
                        .cornerRadius(6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("notes (optional)")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.dim)
                    TextField("", text: $newNotes)
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.fg)
                        .padding(8)
                        .background(DoodleTheme.surface)
                        .cornerRadius(6)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        resetForm()
                        showAddMeal = false
                    }
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        saveMeal()
                    }
                    .font(DoodleTheme.monoBold)
                    .foregroundStyle(newName.isEmpty ? DoodleTheme.dim : DoodleTheme.orange)
                    .disabled(newName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    private func saveMeal() {
        let meal = Meal(
            name: newName.trimmingCharacters(in: .whitespaces),
            calories: Int(newCalories) ?? 0,
            notes: newNotes.trimmingCharacters(in: .whitespaces)
        )
        modelContext.insert(meal)
        resetForm()
        showAddMeal = false
    }

    private func resetForm() {
        newName = ""
        newCalories = ""
        newNotes = ""
    }

    private func statBox(_ label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(DoodleTheme.monoSmall)
                .foregroundStyle(DoodleTheme.dim)
            Text(value)
                .font(DoodleTheme.monoBold)
                .foregroundStyle(color)
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
