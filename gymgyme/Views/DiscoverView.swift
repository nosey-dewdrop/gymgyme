import SwiftUI
import SwiftData

// MARK: - wger API Models (kept for online search fallback)

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

// MARK: - Discover Exercise Item

struct DiscoverExercise: Identifiable {
    let id: String
    let name: String
    let tag: String
    let secondaryMuscles: [String]
    let type: ExerciseType
    let equipmentList: [Equipment]
    let isBuiltIn: Bool

    // wger detail fields (only for online results)
    var wgerBaseId: Int?
    var muscles: [String] = []
    var descriptionEN: String = ""
    var descriptionTR: String = ""
    var imageURLs: [String] = []

    init(builtIn: BuiltInExercise) {
        self.id = "builtin_\(builtIn.name)"
        self.name = builtIn.name
        self.tag = builtIn.tag
        self.secondaryMuscles = builtIn.secondaryMuscles
        self.type = builtIn.type
        self.equipmentList = builtIn.equipment
        self.isBuiltIn = true
    }

    init(wgerName: String, category: String, baseId: Int, imageURL: String?) {
        self.id = "wger_\(baseId)"
        self.name = wgerName
        self.tag = category.lowercased()
        self.secondaryMuscles = []
        self.type = .weightReps
        self.equipmentList = [.gym]
        self.isBuiltIn = false
        self.wgerBaseId = baseId
    }
}

// MARK: - Discover View

struct DiscoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var myExercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedMuscle: String?
    @State private var selectedEquipment: Equipment?
    @State private var selectedType: ExerciseType?
    @State private var addedMessage: String?
    @State private var displayCount = 30
    @State private var selectedDetail: DiscoverExercise?
    @State private var isLoadingDetail = false
    @State private var cachedFiltered: [DiscoverExercise] = []
    @State private var cachedMyExerciseNames: Set<String> = []

    private let muscleGroups = ["chest", "back", "shoulders", "biceps", "triceps", "legs", "hamstrings", "glutes", "abs", "calves", "cardio"]

    // pre-built once, not per render
    private static let allDiscoverExercises: [DiscoverExercise] = ExerciseDB.all.map { DiscoverExercise(builtIn: $0) }

    // MARK: - Filtered exercises

    private func refilter() {
        var results = Self.allDiscoverExercises

        if let muscle = selectedMuscle {
            results = results.filter { $0.tag == muscle }
        }

        if let equip = selectedEquipment {
            results = results.filter { $0.equipmentList.contains(equip) }
        }

        if let type = selectedType {
            results = results.filter { $0.type == type }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter {
                $0.name.contains(query) || $0.tag.contains(query) ||
                $0.secondaryMuscles.contains { $0.contains(query) }
            }
        }

        cachedFiltered = results
    }

    private var visibleExercises: [DiscoverExercise] {
        Array(cachedFiltered.prefix(displayCount))
    }

    private var activeFilterCount: Int {
        (selectedMuscle != nil ? 1 : 0) + (selectedEquipment != nil ? 1 : 0) + (selectedType != nil ? 1 : 0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // header
                    Text("discover")
                        .font(.custom("Menlo-Bold", size: 28))
                        .foregroundStyle(DoodleTheme.blue)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                    // search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(DoodleTheme.dim)
                        TextField("search exercises...", text: $searchText)
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.fg)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(DoodleTheme.dim)
                            }
                        }
                    }
                    .padding(10)
                    .background(DoodleTheme.surface)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    // filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            // muscle group filter
                            filterMenu(title: selectedMuscle ?? "muscle group", isActive: selectedMuscle != nil, icon: "figure.strengthtraining.traditional") {
                                Button("all muscle groups") { selectedMuscle = nil; resetPagination() }
                                ForEach(muscleGroups, id: \.self) { group in
                                    Button(group) { selectedMuscle = group; resetPagination() }
                                }
                            }

                            // equipment filter
                            filterMenu(title: selectedEquipment?.label ?? "equipment", isActive: selectedEquipment != nil, icon: "wrench.and.screwdriver") {
                                Button("all equipment") { selectedEquipment = nil; resetPagination() }
                                ForEach(Equipment.allCases) { equip in
                                    Button {
                                        selectedEquipment = equip; resetPagination()
                                    } label: {
                                        Label(equip.label, systemImage: equip.icon)
                                    }
                                }
                            }

                            // type filter
                            filterMenu(title: selectedType?.label ?? "type", isActive: selectedType != nil, icon: "tag") {
                                Button("all types") { selectedType = nil; resetPagination() }
                                ForEach(ExerciseType.allCases, id: \.self) { type in
                                    Button {
                                        selectedType = type; resetPagination()
                                    } label: {
                                        Label(type.label, systemImage: type.icon)
                                    }
                                }
                            }

                            // clear all
                            if activeFilterCount > 0 {
                                Button {
                                    selectedMuscle = nil
                                    selectedEquipment = nil
                                    selectedType = nil
                                    resetPagination()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10))
                                        Text("clear")
                                            .font(DoodleTheme.monoSmall)
                                    }
                                    .foregroundStyle(DoodleTheme.red)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(DoodleTheme.red.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 8)

                    // active filters summary
                    if activeFilterCount > 0 {
                        HStack(spacing: 4) {
                            Text("\(cachedFiltered.count) exercises")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    } else {
                        Text("\(ExerciseDB.all.count) exercises")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }

                    // added message
                    if let msg = addedMessage {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(DoodleTheme.green)
                            Text(msg)
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.fg)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }

                    // exercise list
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(visibleExercises) { exercise in
                            exerciseRow(exercise)
                        }

                        // load more trigger
                        if displayCount < cachedFiltered.count {
                            ProgressView()
                                .tint(DoodleTheme.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .onAppear { displayCount += 30 }
                        }
                    }

                    if cachedFiltered.isEmpty {
                        VStack(spacing: 4) {
                            Text("no exercises match these filters")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.dim)
                            Text("try changing or removing a filter")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.top, 8)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .overlay {
                if isLoadingDetail {
                    VStack {
                        ProgressView()
                            .tint(DoodleTheme.blue)
                        Text("loading details...")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DoodleTheme.bg.opacity(0.8))
                }
            }
            .onAppear {
                cachedMyExerciseNames = Set(myExercises.map { $0.name.lowercased() })
                refilter()
            }
            .task(id: searchText) {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                refilter()
            }
            .onChange(of: selectedMuscle) { _, _ in refilter() }
            .onChange(of: selectedEquipment) { _, _ in refilter() }
            .onChange(of: selectedType) { _, _ in refilter() }
            .sheet(item: $selectedDetail) { item in
                BuiltInDetailView(item: item) { addToMyExercises(item) }
            }
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: DiscoverExercise) -> some View {
        VStack(spacing: 0) {
            Button { selectedDetail = exercise } label: {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(exercise.name)
                            .font(DoodleTheme.monoBold)
                            .foregroundStyle(DoodleTheme.fg)
                            .lineLimit(1)
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(exercise.equipmentList, id: \.rawValue) { equip in
                                Image(systemName: equip.icon)
                                    .font(.system(size: 10))
                                    .foregroundStyle(DoodleTheme.dim)
                            }
                        }
                    }

                    HStack(spacing: 6) {
                        TagChip(tag: exercise.tag)
                        if !exercise.secondaryMuscles.isEmpty {
                            Text("+ \(exercise.secondaryMuscles.joined(separator: ", "))")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(DoodleTheme.dim)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider()
                .background(DoodleTheme.surface)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Filter Menu

    private func filterMenu<Content: View>(title: String, isActive: Bool, icon: String, @ViewBuilder content: () -> Content) -> some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(DoodleTheme.monoSmall)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .foregroundStyle(isActive ? DoodleTheme.bg : DoodleTheme.fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isActive ? DoodleTheme.blue : DoodleTheme.surface)
            .cornerRadius(6)
        }
    }

    // MARK: - Add to My Exercises

    private func addToMyExercises(_ item: DiscoverExercise) {
        let alreadyExists = cachedMyExerciseNames.contains(item.name.lowercased())
        guard !alreadyExists else {
            withAnimation { addedMessage = "\(item.name) already in your exercises" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { addedMessage = nil } }
            return
        }
        modelContext.insert(Exercise(
            name: item.name, tag: item.tag, type: item.type,
            secondaryMuscles: item.secondaryMuscles, equipment: item.equipmentList
        ))
        cachedMyExerciseNames.insert(item.name.lowercased())
        withAnimation { addedMessage = "\(item.name) added!" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { addedMessage = nil } }
    }

    private func resetPagination() {
        displayCount = 30
    }
}

// MARK: - Built-in Exercise Detail View

struct BuiltInDetailView: View {
    let item: DiscoverExercise
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // name
                    Text(item.name)
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundStyle(DoodleTheme.fg)

                    // tags
                    HStack(spacing: 8) {
                        TagChip(tag: item.tag)
                        Image(systemName: item.type.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(DoodleTheme.dim)
                        Text(item.type.label)
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                    }

                    // equipment
                    if !item.equipmentList.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("equipment")
                                .font(DoodleTheme.monoBold)
                                .foregroundStyle(DoodleTheme.blue)
                            HStack(spacing: 8) {
                                ForEach(item.equipmentList, id: \.rawValue) { equip in
                                    HStack(spacing: 4) {
                                        Image(systemName: equip.icon)
                                            .font(.system(size: 14))
                                        Text(equip.label)
                                            .font(DoodleTheme.monoSmall)
                                    }
                                    .foregroundStyle(DoodleTheme.fg)
                                }
                            }
                        }
                    }

                    // muscles
                    if !item.secondaryMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("also works")
                                .font(DoodleTheme.monoBold)
                                .foregroundStyle(DoodleTheme.orange)
                            Text(item.secondaryMuscles.joined(separator: ", "))
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.fg)
                        }
                    }

                    Text("").frame(height: 12)

                    // add button
                    Button {
                        onAdd(); dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("add to my exercises")
                        }
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(DoodleTheme.green)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
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
}

// MARK: - Keep ExerciseDetailView for wger results (unused now but kept for future online search)

struct ExerciseDetailView: View {
    let item: DiscoverExercise
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showTurkish = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundStyle(DoodleTheme.fg)

                    if !item.descriptionEN.isEmpty {
                        Text(showTurkish && !item.descriptionTR.isEmpty ? item.descriptionTR : item.descriptionEN)
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.fg)
                    }

                    Button {
                        onAdd(); dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("add to my exercises")
                        }
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(DoodleTheme.green)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close") { dismiss() }
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.dim)
                }
            }
        }
    }
}

#Preview {
    DiscoverView().modelContainer(for: Exercise.self, inMemory: true)
}
