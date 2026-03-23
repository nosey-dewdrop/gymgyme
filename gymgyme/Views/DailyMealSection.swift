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
            Text("meals")
                .font(.custom("Menlo-Bold", size: 28))
                .foregroundStyle(DoodleTheme.orange)
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

            // add meal button
            Button { showAddMeal = true } label: {
                HStack(spacing: 0) {
                    Text("  ")
                    Text("+ add meal")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.orange)
                }
            }
            .padding(.top, 4)
        }
        .sheet(isPresented: $showAddMeal) {
            addMealSheet
        }
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

                // results
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(searchResults) { food in
                            Button {
                                addFood(food)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.description.lowercased())
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.fg)
                                        .lineLimit(1)
                                    HStack(spacing: 8) {
                                        Text("\(Int(food.calories)) cal")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.orange)
                                        Text("p:\(String(format: "%.0f", food.protein))g")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.blue)
                                        Text("c:\(String(format: "%.0f", food.carbs))g")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.green)
                                        Text("f:\(String(format: "%.0f", food.fat))g")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.yellow)
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

        let query = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchText
        let urlString = "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(query)&pageSize=15&api_key=\(Config.usdaAPIKey)"

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

    private func addFood(_ food: USDAFood) {
        let meal = Meal(
            name: food.description.lowercased(),
            calories: Int(food.calories)
        )
        meal.protein = food.protein
        meal.carbs = food.carbs
        meal.fat = food.fat
        modelContext.insert(meal)
        showAddMeal = false
        searchText = ""
        searchResults = []
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
