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

    private let commonTags = ["bacak", "gogus", "sirt", "omuz", "biceps", "triceps", "karin", "kalca"]

    private var displayTags: [String] {
        let all = Set(commonTags + existingTags)
        return Array(all).sorted()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(displayTags, id: \.self) { tag in
                            Button {
                                if selectedTag == tag {
                                    selectedTag = nil
                                } else {
                                    selectedTag = tag
                                    searchByMuscle(tag)
                                }
                            } label: {
                                TagChip(tag: tag, isSelected: selectedTag == tag)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                if let msg = addedMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DoodleTheme.green)
                        Text(msg)
                            .font(DoodleTheme.mono(12))
                            .foregroundStyle(DoodleTheme.ink)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .transition(.opacity)
                }

                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(DoodleTheme.accent)
                    Spacer()
                } else if exercises.isEmpty {
                    Spacer()
                    VStack(spacing: 14) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(DoodleTheme.inkDim)
                        Text("search exercises")
                            .font(DoodleTheme.handwritten(17))
                            .foregroundStyle(DoodleTheme.inkLight)
                        Text("tap a #tag above or search by name")
                            .font(DoodleTheme.mono(12))
                            .foregroundStyle(DoodleTheme.inkDim)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, item in
                                DiscoverExerciseRow(item: item, colorIndex: index) {
                                    selectedDetail = item
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(DoodleTheme.background)
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "search exercises...")
            .onSubmit(of: .search) {
                searchByName()
            }
            .sheet(item: $selectedDetail) { item in
                ExerciseDetailView(item: item) {
                    addToMyExercises(item)
                }
            }
        }
    }

    private func searchByMuscle(_ tag: String) {
        isLoading = true
        exercises = []

        let muscleMap: [String: String] = [
            "bacak": "quadriceps", "gogus": "chest", "sirt": "back",
            "omuz": "shoulders", "biceps": "biceps", "triceps": "triceps",
            "karin": "abdominals", "kalca": "glutes",
        ]

        let muscle = muscleMap[tag] ?? tag
        let urlString = "https://exercisedb.p.rapidapi.com/exercises/target/\(muscle)?limit=20&offset=0"
        fetchExercises(urlString: urlString)
    }

    private func searchByName() {
        guard !searchText.isEmpty else { return }
        isLoading = true
        exercises = []

        let encoded = searchText.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? searchText
        let urlString = "https://exercisedb.p.rapidapi.com/exercises/name/\(encoded)?limit=20&offset=0"
        fetchExercises(urlString: urlString)
    }

    private func fetchExercises(urlString: String) {
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("exercisedb.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.setValue("DEMO_KEY", forHTTPHeaderField: "x-rapidapi-key")

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let decoded = try JSONDecoder().decode([ExerciseDBItem].self, from: data)
                await MainActor.run {
                    exercises = decoded
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func addToMyExercises(_ item: ExerciseDBItem) {
        let tagMap: [String: String] = [
            "chest": "gogus", "pectorals": "gogus",
            "back": "sirt", "lats": "sirt", "upper back": "sirt", "spine": "sirt",
            "shoulders": "omuz", "delts": "omuz",
            "biceps": "biceps", "triceps": "triceps",
            "quadriceps": "bacak", "hamstrings": "bacak", "calves": "bacak", "adductors": "bacak", "abductors": "bacak",
            "abdominals": "karin", "abs": "karin", "serratus anterior": "karin",
            "glutes": "kalca", "cardiovascular system": "karin"
        ]

        let tag = tagMap[item.target.lowercased()] ?? selectedTag ?? item.target.lowercased()
        let exercise = Exercise(name: item.name.capitalized, tag: tag)
        modelContext.insert(exercise)

        withAnimation {
            addedMessage = "\(item.name.capitalized) added!"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { addedMessage = nil }
        }
    }
}

// MARK: - ExerciseDB Model

struct ExerciseDBItem: Codable, Identifiable {
    let id: String
    let name: String
    let target: String
    let bodyPart: String
    let equipment: String
    let gifUrl: String
    let secondaryMuscles: [String]
    let instructions: [String]
}

// MARK: - Discover Row

struct DiscoverExerciseRow: View {
    let item: ExerciseDBItem
    let colorIndex: Int
    let onTap: () -> Void

    private var color: Color {
        DoodleTheme.titleColor(for: colorIndex)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: item.gifUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DoodleTheme.cardBackgroundLight)
                        .overlay(
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundStyle(DoodleTheme.inkDim)
                        )
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name.capitalized)
                        .font(DoodleTheme.handwritten(14))
                        .foregroundStyle(DoodleTheme.ink)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text("#\(item.target)")
                            .foregroundStyle(color)
                        Text("·")
                            .foregroundStyle(DoodleTheme.inkDim)
                        Text(item.equipment)
                            .foregroundStyle(DoodleTheme.inkLight)
                    }
                    .font(DoodleTheme.mono(11))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(DoodleTheme.inkDim)
            }
            .glowCard(color: color)
        }
    }
}

// MARK: - Exercise Detail

struct ExerciseDetailView: View {
    let item: ExerciseDBItem
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AsyncImage(url: URL(string: item.gifUrl)) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DoodleTheme.cardBackgroundLight)
                            .frame(height: 200)
                            .overlay(ProgressView().tint(DoodleTheme.accent))
                    }
                    .cornerRadius(12)
                    .shadow(color: DoodleTheme.accent.opacity(0.2), radius: 12)

                    VStack(alignment: .leading, spacing: 10) {
                        ColoredHeader("INFO", color: DoodleTheme.blue)
                        InfoRow(label: "Target", value: item.target.capitalized, color: DoodleTheme.accent)
                        InfoRow(label: "Body Part", value: item.bodyPart.capitalized, color: DoodleTheme.orange)
                        InfoRow(label: "Equipment", value: item.equipment.capitalized, color: DoodleTheme.blue)

                        if !item.secondaryMuscles.isEmpty {
                            InfoRow(label: "Secondary", value: item.secondaryMuscles.map(\.capitalized).joined(separator: ", "), color: DoodleTheme.green)
                        }
                    }
                    .glowCard(color: DoodleTheme.blue)

                    if !item.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            ColoredHeader("HOW TO DO IT", color: DoodleTheme.green)

                            ForEach(Array(item.instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(DoodleTheme.mono(12))
                                        .foregroundStyle(DoodleTheme.titleColor(for: index))
                                        .frame(width: 20)
                                    Text(instruction)
                                        .font(DoodleTheme.body())
                                        .foregroundStyle(DoodleTheme.ink)
                                }
                            }
                        }
                        .glowCard(color: DoodleTheme.green)
                    }

                    Button {
                        onAdd()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to My Exercises")
                        }
                        .font(DoodleTheme.handwritten(16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DoodleTheme.accent)
                        .cornerRadius(14)
                        .shadow(color: DoodleTheme.accent.opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                }
                .padding()
            }
            .background(DoodleTheme.background)
            .navigationTitle(item.name.capitalized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(DoodleTheme.inkLight)
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var color: Color = DoodleTheme.inkLight

    var body: some View {
        HStack {
            Text(label)
                .font(DoodleTheme.mono(11))
                .foregroundStyle(DoodleTheme.inkDim)
                .frame(width: 75, alignment: .leading)
            Text(value)
                .font(DoodleTheme.body())
                .foregroundStyle(DoodleTheme.ink)
        }
    }
}

#Preview {
    DiscoverView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
