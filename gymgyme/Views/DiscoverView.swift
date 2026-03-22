import SwiftUI
import SwiftData

// MARK: - wger API Models

struct WgerSearchResponse: Codable {
    let suggestions: [WgerSuggestion]
}

struct WgerSuggestion: Codable {
    let value: String
    let data: WgerSuggestionData
}

struct WgerSuggestionData: Codable, Identifiable {
    let id: Int
    let base_id: Int
    let name: String
    let category: String
    let image: String?
    let image_thumbnail: String?
}

struct WgerExerciseInfo: Codable {
    let id: Int
    let category: WgerCategory
    let muscles: [WgerMuscle]
    let muscles_secondary: [WgerMuscle]
    let equipment: [WgerEquipment]
    let images: [WgerImage]
    let translations: [WgerTranslation]
}

struct WgerCategory: Codable { let id: Int; let name: String }
struct WgerMuscle: Codable { let id: Int; let name: String; let name_en: String }
struct WgerEquipment: Codable { let id: Int; let name: String }
struct WgerImage: Codable { let id: Int; let image: String; let is_main: Bool }
struct WgerTranslation: Codable { let id: Int; let name: String; let description: String; let language: Int }

// MARK: - Unified Exercise Item (used in list + detail)

struct DiscoverExercise: Identifiable {
    let id: Int
    let baseId: Int
    let name: String
    let category: String
    let imageURL: String?

    // detail fields (loaded on tap)
    var muscles: [String] = []
    var secondaryMuscles: [String] = []
    var equipment: [String] = []
    var description: String = ""
    var imageURLs: [String] = []
}

// MARK: - Discover View

struct DiscoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var myExercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedTag: String?
    @State private var exercises: [DiscoverExercise] = []
    @State private var isLoading = false
    @State private var selectedExercise: DiscoverExercise?
    @State private var addedMessage: String?
    @State private var errorMessage: String?

    private var existingTags: [String] {
        Array(Set(myExercises.map(\.tag))).sorted()
    }

    private let commonTags = ["bacak", "biceps", "gogus", "kalca", "karin", "omuz", "sirt", "triceps"]

    private var displayTags: [String] {
        Array(Set(commonTags + existingTags)).sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    Text("discover")
                        .font(.custom("Menlo-Bold", size: 28))
                        .foregroundStyle(DoodleTheme.blue)
                        .padding(.bottom, 8)

                    // tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(displayTags, id: \.self) { tag in
                                Button {
                                    if selectedTag == tag { selectedTag = nil; exercises = [] }
                                    else { selectedTag = tag; searchByMuscle(tag) }
                                } label: {
                                    TagChip(tag: tag, isSelected: selectedTag == tag)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)

                    if let msg = addedMessage {
                        HStack(spacing: 0) {
                            Text("✓ ")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.green)
                            Text(msg)
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.fg)
                        }
                        .padding(.bottom, 4)
                    }

                    if let err = errorMessage {
                        HStack(spacing: 0) {
                            Text("! ")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.red)
                            Text(err)
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                        }
                        .padding(.bottom, 4)
                    }

                    if isLoading {
                        HStack(spacing: 0) {
                            Text("● ")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.blue)
                            Text("loading...")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.dim)
                        }
                    } else if exercises.isEmpty {
                        HStack(spacing: 0) {
                            Text("~ ")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.dim)
                            Text("tap a #tag or search by name")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.dim)
                        }
                    } else {
                        ForEach(Array(exercises.enumerated()), id: \.element.id) { index, item in
                            Button { loadDetail(item) } label: {
                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 0) {
                                        Text("● ")
                                            .font(DoodleTheme.mono)
                                            .foregroundStyle(DoodleTheme.color(for: index))
                                        Text(item.name)
                                            .font(DoodleTheme.monoBold)
                                            .foregroundStyle(DoodleTheme.fg)
                                            .lineLimit(1)
                                    }
                                    HStack(spacing: 0) {
                                        Text("  #\(item.category.lowercased())")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.color(for: item.category))
                                    }
                                    Text("").frame(height: 4)
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
            .searchable(text: $searchText, prompt: "search exercises...")
            .onSubmit(of: .search) { searchByName() }
            .sheet(item: $selectedExercise) { item in
                ExerciseDetailView(item: item) { addToMyExercises(item) }
            }
        }
    }

    // MARK: - Search by muscle tag

    private func searchByMuscle(_ tag: String) {
        let map: [String: String] = [
            "bacak": "legs", "gogus": "chest", "sirt": "back",
            "omuz": "shoulders", "biceps": "biceps", "triceps": "triceps",
            "karin": "abs", "kalca": "glutes",
        ]
        let term = map[tag] ?? tag
        searchWger(term: term)
    }

    // MARK: - Search by name

    private func searchByName() {
        guard !searchText.isEmpty else { return }
        searchWger(term: searchText)
    }

    // MARK: - wger search API

    private func searchWger(term: String) {
        isLoading = true
        exercises = []
        errorMessage = nil
        let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
        let urlString = "https://wger.de/api/v2/exercise/search/?term=\(encoded)&language=en&format=json"

        guard let url = URL(string: urlString) else { isLoading = false; return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(WgerSearchResponse.self, from: data)
                let items = response.suggestions.map { s in
                    DiscoverExercise(
                        id: s.data.id,
                        baseId: s.data.base_id,
                        name: s.data.name,
                        category: s.data.category,
                        imageURL: s.data.image.map { "https://wger.de\($0)" }
                    )
                }
                await MainActor.run {
                    exercises = items
                    isLoading = false
                    if items.isEmpty { errorMessage = "no exercises found for \"\(term)\"" }
                }
            } catch {
                await MainActor.run { isLoading = false; errorMessage = "search failed" }
            }
        }
    }

    // MARK: - Load exercise detail

    private func loadDetail(_ item: DiscoverExercise) {
        let urlString = "https://wger.de/api/v2/exerciseinfo/\(item.baseId)/?format=json"
        guard let url = URL(string: urlString) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let info = try JSONDecoder().decode(WgerExerciseInfo.self, from: data)

                let englishTranslation = info.translations.first { $0.language == 2 }
                let description = englishTranslation?.description
                    .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                let imageURLs = info.images.map { "https://wger.de\($0.image)" }
                let muscles = info.muscles.map { $0.name_en.isEmpty ? $0.name : $0.name_en }
                let secondaryMuscles = info.muscles_secondary.map { $0.name_en.isEmpty ? $0.name : $0.name_en }
                let equipment = info.equipment.map { $0.name }

                var detail = item
                detail.muscles = muscles
                detail.secondaryMuscles = secondaryMuscles
                detail.equipment = equipment
                detail.description = description
                detail.imageURLs = imageURLs

                await MainActor.run { selectedExercise = detail }
            } catch {
                // fallback: show without detail
                await MainActor.run { selectedExercise = item }
            }
        }
    }

    // MARK: - Add to my exercises

    private func addToMyExercises(_ item: DiscoverExercise) {
        let tagMap: [String: String] = [
            "chest": "gogus", "back": "sirt", "shoulders": "omuz",
            "arms": "biceps", "legs": "bacak", "abs": "karin",
            "cardio": "cardio", "stretching": "stretching",
        ]
        let tag = tagMap[item.category.lowercased()] ?? selectedTag ?? item.category.lowercased()
        modelContext.insert(Exercise(name: item.name, tag: tag))
        withAnimation { addedMessage = "\(item.name) added!" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { addedMessage = nil } }
    }
}

// MARK: - Exercise Detail View

struct ExerciseDetailView: View {
    let item: DiscoverExercise
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // image
                    if let firstImage = item.imageURLs.first, let url = URL(string: firstImage) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Text("loading image...")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.dim)
                                .frame(height: 200)
                        }
                        .cornerRadius(8)
                    }

                    Text("").frame(height: 4)

                    infoLine("category", item.category, DoodleTheme.pink)

                    if !item.muscles.isEmpty {
                        infoLine("muscles", item.muscles.joined(separator: ", "), DoodleTheme.orange)
                    }

                    if !item.equipment.isEmpty {
                        infoLine("equip", item.equipment.joined(separator: ", "), DoodleTheme.blue)
                    }

                    if !item.secondaryMuscles.isEmpty {
                        infoLine("also", item.secondaryMuscles.joined(separator: ", "), DoodleTheme.green)
                    }

                    if !item.description.isEmpty {
                        Text("").frame(height: 8)
                        Text("how to do it")
                            .font(DoodleTheme.monoBold)
                            .foregroundStyle(DoodleTheme.green)
                        Text("").frame(height: 4)
                        Text(item.description)
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.fg)
                    }

                    Text("").frame(height: 12)
                    Button {
                        onAdd(); dismiss()
                    } label: {
                        HStack(spacing: 0) {
                            Text("+ ")
                                .foregroundStyle(DoodleTheme.green)
                            Text("add to my exercises")
                                .foregroundStyle(DoodleTheme.fg)
                        }
                        .font(DoodleTheme.monoBold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(DoodleTheme.surface)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close") { dismiss() }
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.dim)
                }
            }
        }
    }

    private func infoLine(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 0) {
            Text("\(label): ")
                .font(DoodleTheme.monoSmall)
                .foregroundStyle(DoodleTheme.dim)
            Text(value)
                .font(DoodleTheme.monoSmall)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    DiscoverView().modelContainer(for: Exercise.self, inMemory: true)
}
