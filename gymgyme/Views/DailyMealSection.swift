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

// MARK: - Add Meal Sheet (reusable, used by CalendarView)

struct AddMealSheet: View {
    let date: Date
    let onAdd: (Meal) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [USDAFood] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var servingGrams: String = "100"
    @State private var foodSuggestions: [String] = []

    var body: some View {
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
                        .textInputAutocapitalization(.never)
                        .onSubmit { searchFood() }
                }
                .padding(10)
                .background(DoodleTheme.surface)
                .cornerRadius(6)

                if !searchText.isEmpty && searchResults.isEmpty && !isSearching {
                    if !foodSuggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(foodSuggestions, id: \.self) { s in
                                    Button {
                                        searchText = s
                                        searchFood()
                                    } label: {
                                        Text(s)
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.fg)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(DoodleTheme.surface)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                    }
                }

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
                    let scale = servingScale
                    let showServing = scale != 1.0
                    let servingLabel = "\(servingGrams)g serving"
                    LazyVStack(alignment: .leading, spacing: 4) {
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
                                        Text("\(Int(food.calories * scale)) cal")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.orange)
                                        Text("p:\(Int(food.protein * scale))g")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.blue)
                                        Text("c:\(Int(food.carbs * scale))g")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.green)
                                        Text("f:\(Int(food.fat * scale))g")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.yellow)
                                    }
                                    if showServing {
                                        Text("for \(servingLabel)")
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
            .task(id: searchText) {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                foodSuggestions = FoodNameSuggester.suggestions(for: searchText)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close") { dismiss() }
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
        errorMessage = nil

        let urlString = Config.usdaSearchURL(query: searchText)

        guard let url = URL(string: urlString) else { isSearching = false; return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(USDASearchResponse.self, from: data)
                await MainActor.run {
                    errorMessage = nil
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
        // set the meal timestamp to the selected date (noon) so it shows on the right day
        let calendar = Calendar.current
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        meal.timestamp = noon
        onAdd(meal)
    }
}
