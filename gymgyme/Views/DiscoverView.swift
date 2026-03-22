import SwiftUI
import SwiftData

struct DiscoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var myExercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedTag: String?
    @State private var exercises: [ExerciseDBItem] = []
    @State private var isLoading = false
    @State private var selectedDetail: ExerciseDBItem?
    @State private var addedMessage: String?

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
                                    if selectedTag == tag { selectedTag = nil }
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
                            Button { selectedDetail = item } label: {
                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 0) {
                                        Text("● ")
                                            .font(DoodleTheme.mono)
                                            .foregroundStyle(DoodleTheme.color(for: index))
                                        Text(item.name.capitalized)
                                            .font(DoodleTheme.monoBold)
                                            .foregroundStyle(DoodleTheme.fg)
                                            .lineLimit(1)
                                    }
                                    HStack(spacing: 0) {
                                        Text("  #\(item.target)")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.color(for: item.target))
                                        Text(" · \(item.equipment)")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.dim)
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
            .sheet(item: $selectedDetail) { item in
                ExerciseDetailView(item: item) { addToMyExercises(item) }
            }
        }
    }

    private func searchByMuscle(_ tag: String) {
        isLoading = true; exercises = []
        let map: [String: String] = [
            "bacak": "quadriceps", "gogus": "chest", "sirt": "back",
            "omuz": "shoulders", "biceps": "biceps", "triceps": "triceps",
            "karin": "abdominals", "kalca": "glutes",
        ]
        let muscle = map[tag] ?? tag
        fetchExercises(urlString: "https://exercisedb.p.rapidapi.com/exercises/target/\(muscle)?limit=20&offset=0")
    }

    private func searchByName() {
        guard !searchText.isEmpty else { return }
        isLoading = true; exercises = []
        let encoded = searchText.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? searchText
        fetchExercises(urlString: "https://exercisedb.p.rapidapi.com/exercises/name/\(encoded)?limit=20&offset=0")
    }

    private func fetchExercises(urlString: String) {
        guard let url = URL(string: urlString) else { isLoading = false; return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("exercisedb.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.setValue("DEMO_KEY", forHTTPHeaderField: "x-rapidapi-key")
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let decoded = try JSONDecoder().decode([ExerciseDBItem].self, from: data)
                await MainActor.run { exercises = decoded; isLoading = false }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }

    private func addToMyExercises(_ item: ExerciseDBItem) {
        let tagMap: [String: String] = [
            "chest": "gogus", "pectorals": "gogus", "back": "sirt", "lats": "sirt",
            "upper back": "sirt", "shoulders": "omuz", "delts": "omuz",
            "biceps": "biceps", "triceps": "triceps",
            "quadriceps": "bacak", "hamstrings": "bacak", "calves": "bacak",
            "abdominals": "karin", "glutes": "kalca",
        ]
        let tag = tagMap[item.target.lowercased()] ?? selectedTag ?? item.target.lowercased()
        modelContext.insert(Exercise(name: item.name.capitalized, tag: tag))
        withAnimation { addedMessage = "\(item.name.capitalized) added!" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { addedMessage = nil } }
    }
}

struct ExerciseDBItem: Codable, Identifiable {
    let id: String; let name: String; let target: String; let bodyPart: String
    let equipment: String; let gifUrl: String; let secondaryMuscles: [String]; let instructions: [String]
}

struct ExerciseDetailView: View {
    let item: ExerciseDBItem
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        AsyncImage(url: URL(string: item.gifUrl)) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Text("loading...")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.dim)
                            .frame(height: 200)
                    }
                    .cornerRadius(8)

                    Text("").frame(height: 4)

                    infoLine("target", item.target.capitalized, DoodleTheme.pink)
                    infoLine("body", item.bodyPart.capitalized, DoodleTheme.orange)
                    infoLine("equip", item.equipment.capitalized, DoodleTheme.blue)

                    if !item.secondaryMuscles.isEmpty {
                        infoLine("also", item.secondaryMuscles.map(\.capitalized).joined(separator: ", "), DoodleTheme.green)
                    }

                    if !item.instructions.isEmpty {
                        Text("").frame(height: 8)
                        Text("how to do it")
                            .font(DoodleTheme.monoBold)
                            .foregroundStyle(DoodleTheme.green)
                        Text("").frame(height: 4)
                        ForEach(Array(item.instructions.enumerated()), id: \.offset) { i, step in
                            HStack(alignment: .top, spacing: 0) {
                                Text("\(i + 1). ")
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.color(for: i))
                                Text(step)
                                    .font(DoodleTheme.monoSmall)
                                    .foregroundStyle(DoodleTheme.fg)
                            }
                            .padding(.bottom, 2)
                        }
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
            .navigationTitle(item.name.capitalized)
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

struct InfoRow: View {
    let label: String; let value: String; var color: Color = DoodleTheme.fg
    var body: some View {
        HStack(spacing: 0) {
            Text("\(label): ").font(DoodleTheme.monoSmall).foregroundStyle(DoodleTheme.dim)
            Text(value).font(DoodleTheme.monoSmall).foregroundStyle(color)
        }
    }
}

#Preview {
    DiscoverView().modelContainer(for: Exercise.self, inMemory: true)
}
