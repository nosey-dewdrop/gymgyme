import SwiftUI
import SwiftData

// MARK: - USDA API Models

struct USDASearchResponse: Codable {
    let foods: [USDAFood]?
}

struct USDAFood: Codable, Identifiable {
    let fdcId: Int
    let description: String
    let foodNutrients: [USDANutrient]?

    var id: Int { fdcId }

    var calories: Double {
        foodNutrients?.first { $0.nutrientName == "Energy" }?.value ?? 0
    }
    var protein: Double {
        foodNutrients?.first { $0.nutrientName == "Protein" }?.value ?? 0
    }
    var carbs: Double {
        foodNutrients?.first { $0.nutrientName?.contains("Carbohydrate") == true }?.value ?? 0
    }
    var fat: Double {
        foodNutrients?.first { $0.nutrientName?.contains("Total lipid") == true }?.value ?? 0
    }
}

struct USDANutrient: Codable {
    let nutrientName: String?
    let value: Double?
}

// MARK: - Daily Meal Section

struct DailyMealSection: View {
    @Query(sort: \Meal.timestamp, order: .reverse) private var allMeals: [Meal]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddMeal = false
    @State private var searchText = ""
    @State private var searchResults: [USDAFood] = []
    @State private var isSearching = false
    @State private var selectedFood: USDAFood?
    @State private var errorMessage: String?
    @State private var showSettings = false
    @State private var servingGrams: String = "100"

    private var todaysMeals: [Meal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allMeals.filter { calendar.startOfDay(for: $0.timestamp) == today }
    }

    private var todaysCalories: Int {
        todaysMeals.reduce(0) { $0 + $1.calories }
    }

    private var todaysProtein: Double {
        todaysMeals.reduce(0.0) { $0 + $1.protein }
    }

    private var todaysCarbs: Double {
        todaysMeals.reduce(0.0) { $0 + $1.carbs }
    }

    private var todaysFat: Double {
        todaysMeals.reduce(0.0) { $0 + $1.fat }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("meals")
                    .font(.custom("Menlo-Bold", size: 28))
                    .foregroundStyle(DoodleTheme.orange)
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(DoodleTheme.dim)
                }
                Button { showAddMeal = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(DoodleTheme.orange)
                        .padding(.leading, 12)
                }
                .accessibilityLabel("add meal")
            }
            .padding(.bottom, 8)

            // daily summary
            if !todaysMeals.isEmpty {
                HStack(spacing: 16) {
                    macroBox("cal", value: "\(todaysCalories)", color: DoodleTheme.orange)
                    macroBox("protein", value: String(format: "%.0fg", todaysProtein), color: DoodleTheme.blue)
                    macroBox("carbs", value: String(format: "%.0fg", todaysCarbs), color: DoodleTheme.green)
                    macroBox("fat", value: String(format: "%.0fg", todaysFat), color: DoodleTheme.yellow)
                }
                .padding(.bottom, 4)
            }

            // meal list
            ForEach(todaysMeals, id: \.id) { meal in
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
                        modelContext.delete(meal)
                    } label: {
                        Label("delete", systemImage: "trash")
                    }
                }
            }

            if todaysMeals.isEmpty {
                HStack(spacing: 0) {
                    Text("  ")
                    Text("no meals logged today")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.dim)
                }
            }

        }
        .sheet(isPresented: $showAddMeal) { addMealSheet }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    // MARK: - Add Meal Sheet

    private var addMealSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("add meal")
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundStyle(DoodleTheme.orange)
                    .padding(.top, 8)

                // search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(DoodleTheme.dim)
                    TextField("search food...", text: $searchText)
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.fg)
                        .autocorrectionDisabled()
                        .onSubmit { searchFood() }
                }
                .padding(10)
                .background(DoodleTheme.surface)
                .cornerRadius(6)

                if isSearching {
                    Text("searching...")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.dim)
                }

                if let err = errorMessage {
                    Text(err)
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.red)
                }

                // serving size
                if !searchResults.isEmpty {
                    HStack(spacing: 0) {
                        Text("serving: ")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                        TextField("100", text: $servingGrams)
                            .keyboardType(.numberPad)
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.fg)
                            .frame(width: 50)
                            .padding(4)
                            .background(DoodleTheme.surface)
                            .cornerRadius(4)
                        Text("g")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                            .padding(.leading, 2)
                        Spacer()
                        Text("values per 100g")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(DoodleTheme.dim)
                    }
                    .padding(.vertical, 4)
                }

                // results
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(searchResults) { food in
                            let scale = servingScale
                            Button {
                                addFood(food)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.description.lowercased())
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.fg)
                                        .lineLimit(1)
                                    HStack(spacing: 8) {
                                        Text("\(Int(food.calories * scale)) cal")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.orange)
                                        Text("p:\(String(format: "%.0f", food.protein * scale))g")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.blue)
                                        Text("c:\(String(format: "%.0f", food.carbs * scale))g")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.green)
                                        Text("f:\(String(format: "%.0f", food.fat * scale))g")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.yellow)
                                    }
                                    if scale != 1.0 {
                                        Text("for \(servingGrams)g serving")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(DoodleTheme.dim)
                                    }
                                    Text("").frame(height: 4)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close") { showAddMeal = false }
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.dim)
                }
            }
        }
    }

    // MARK: - USDA API

    private func searchFood() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        searchResults = []

        let urlString = Config.usdaSearchURL(query: searchText)

        guard let url = URL(string: urlString) else { isSearching = false; return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(USDASearchResponse.self, from: data)
                await MainActor.run {
                    searchResults = response.foods ?? []
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    errorMessage = "search failed, check connection"
                }
            }
        }
    }

    private var servingScale: Double {
        guard let grams = Double(servingGrams), grams > 0 else { return 1.0 }
        return grams / 100.0
    }

    private func addFood(_ food: USDAFood) {
        let scale = servingScale
        let meal = Meal(
            name: food.description.lowercased(),
            calories: Int((food.calories * scale).rounded())
        )
        meal.protein = food.protein * scale
        meal.carbs = food.carbs * scale
        meal.fat = food.fat * scale
        modelContext.insert(meal)
        showAddMeal = false
        searchText = ""
        searchResults = []
        servingGrams = "100"
    }

    // MARK: - Helpers

    private func macroBox(_ label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(DoodleTheme.dim)
            Text(value)
                .font(DoodleTheme.monoBold)
                .foregroundStyle(color)
        }
    }

}
