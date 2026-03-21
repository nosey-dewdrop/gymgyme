import SwiftUI
import SwiftData

struct DiscoverView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var exercises: [ExerciseDBItem] = []
    @State private var isLoading = false
    @State private var selectedDetail: ExerciseDBItem?
    @State private var addedMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MuscleGroup.allCases) { group in
                            Button {
                                if selectedMuscleGroup == group {
                                    selectedMuscleGroup = nil
                                } else {
                                    selectedMuscleGroup = group
                                    searchByMuscle(group)
                                }
                            } label: {
                                Text("#\(group.rawValue)")
                                    .font(DoodleTheme.caption())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedMuscleGroup == group ? DoodleTheme.accent : DoodleTheme.cardBackground)
                                    .foregroundStyle(selectedMuscleGroup == group ? .white : DoodleTheme.ink)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(DoodleTheme.ink.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                if let msg = addedMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DoodleTheme.green)
                        Text(msg)
                            .font(DoodleTheme.caption())
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
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(DoodleTheme.inkLight)
                        Text("Search exercises by muscle group")
                            .font(DoodleTheme.body())
                            .foregroundStyle(DoodleTheme.inkLight)
                        Text("Tap a #tag above to browse")
                            .font(DoodleTheme.caption())
                            .foregroundStyle(DoodleTheme.inkLight)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(exercises) { item in
                                DiscoverExerciseRow(item: item) {
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
            .searchable(text: $searchText, prompt: "Search exercises...")
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

    private func searchByMuscle(_ group: MuscleGroup) {
        isLoading = true
        exercises = []

        let muscleMap: [MuscleGroup: String] = [
            .chest: "chest",
            .back: "back",
            .shoulders: "shoulders",
            .biceps: "biceps",
            .triceps: "triceps",
            .legs: "quadriceps",
            .core: "abdominals",
            .glutes: "glutes"
        ]

        let muscle = muscleMap[group] ?? group.rawValue
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
        // API key should be stored securely - placeholder for now
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
        let muscleGroupMap: [String: MuscleGroup] = [
            "chest": .chest, "pectorals": .chest,
            "back": .back, "lats": .back, "upper back": .back, "spine": .back,
            "shoulders": .shoulders, "delts": .shoulders,
            "biceps": .biceps,
            "triceps": .triceps,
            "quadriceps": .legs, "hamstrings": .legs, "calves": .legs, "adductors": .legs, "abductors": .legs,
            "abdominals": .core, "abs": .core, "serratus anterior": .core,
            "glutes": .glutes, "cardiovascular system": .core
        ]

        let group = muscleGroupMap[item.target.lowercased()] ?? .core
        let exercise = Exercise(name: item.name.capitalized, muscleGroup: group)
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
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: item.gifUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DoodleTheme.ink.opacity(0.05))
                        .overlay(
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundStyle(DoodleTheme.inkLight)
                        )
                }
                .frame(width: 56, height: 56)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name.capitalized)
                        .font(DoodleTheme.handwritten(15))
                        .foregroundStyle(DoodleTheme.ink)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text("#\(item.target)")
                        Text("·")
                        Text(item.equipment)
                    }
                    .font(DoodleTheme.caption())
                    .foregroundStyle(DoodleTheme.inkLight)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DoodleTheme.inkLight)
            }
            .doodleCard()
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
                            .fill(DoodleTheme.ink.opacity(0.05))
                            .frame(height: 200)
                            .overlay(ProgressView())
                    }
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "Target", value: item.target.capitalized)
                        InfoRow(label: "Body Part", value: item.bodyPart.capitalized)
                        InfoRow(label: "Equipment", value: item.equipment.capitalized)

                        if !item.secondaryMuscles.isEmpty {
                            InfoRow(label: "Secondary", value: item.secondaryMuscles.map(\.capitalized).joined(separator: ", "))
                        }
                    }
                    .doodleCard()

                    if !item.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How to do it")
                                .font(DoodleTheme.handwritten(17))
                                .foregroundStyle(DoodleTheme.ink)

                            ForEach(Array(item.instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(DoodleTheme.caption())
                                        .foregroundStyle(DoodleTheme.accent)
                                        .frame(width: 20)
                                    Text(instruction)
                                        .font(DoodleTheme.body())
                                        .foregroundStyle(DoodleTheme.ink)
                                }
                            }
                        }
                        .doodleCard()
                    }

                    Button {
                        onAdd()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to My Exercises")
                        }
                        .font(DoodleTheme.handwritten(17))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DoodleTheme.accent)
                        .cornerRadius(14)
                    }
                }
                .padding()
            }
            .background(DoodleTheme.background)
            .navigationTitle(item.name.capitalized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(DoodleTheme.caption())
                .foregroundStyle(DoodleTheme.inkLight)
                .frame(width: 80, alignment: .leading)
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
