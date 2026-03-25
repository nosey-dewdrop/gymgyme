import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Query private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var tagInput = ""
    @State private var selectedType: ExerciseType = .weightReps
    @State private var showDiscover = false
    @State private var computedNameSuggestions: [String] = []
    @State private var computedTagSuggestions: [String] = []
    @State private var cachedExistingTags: [String] = []
    @State private var cachedLowercasedNames: Set<String> = []

    private static let haptic: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .medium); g.prepare(); return g
    }()

    private var resolvedTag: String {
        TagSuggester.suggest(for: tagInput)
    }

    private func isDuplicate(_ n: String) -> Bool {
        guard !n.isEmpty else { return false }
        return cachedLowercasedNames.contains(n.lowercased())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("add exercise")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(DoodleTheme.green)
                        .padding(.bottom, 4)

                    HStack(spacing: 0) {
                        Text("name: ")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.dim)
                        TextField("leg press", text: $name)
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.fg)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: name) { _, new in
                                if new.count > 50 { name = String(new.prefix(50)) }
                            }
                    }

                    if !name.isEmpty && !computedNameSuggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(computedNameSuggestions, id: \.self) { s in
                                    Button {
                                        name = s
                                        if let autoTag = ExerciseNameSuggester.autoTag(for: s) {
                                            tagInput = autoTag
                                        }
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

                    HStack(spacing: 0) {
                        Text("muscle group: ")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.dim)
                        TextField("legs", text: $tagInput)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(DoodleTheme.fg)
                    }

                    if !tagInput.isEmpty && resolvedTag != tagInput.lowercased().trimmingCharacters(in: .whitespaces) {
                        HStack(spacing: 0) {
                            Text("      → ")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                            Text("#\(resolvedTag)")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.color(for: resolvedTag))
                        }
                    }

                    if isDuplicate(name.trimmingCharacters(in: .whitespaces)) {
                        HStack(spacing: 0) {
                            Text("! ")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.red)
                            Text("exercise already exists")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.red)
                        }
                    }

                    if !computedTagSuggestions.isEmpty && !tagInput.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(computedTagSuggestions.prefix(5), id: \.self) { s in
                                Button { tagInput = s } label: {
                                    Text("#\(s)")
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.color(for: s))
                                }
                            }
                        }
                    }

                    Text("").frame(height: 8)

                    Text("type")
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.blue)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ExerciseType.allCases, id: \.self) { type in
                                Button { selectedType = type } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 12))
                                        Text(type.label)
                                            .font(DoodleTheme.monoSmall)
                                    }
                                    .foregroundStyle(selectedType == type ? DoodleTheme.bg : DoodleTheme.fg)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(selectedType == type ? DoodleTheme.blue : DoodleTheme.surface)
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }

                    Text("").frame(height: 16)

                    Button { showDiscover = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                            Text("browse exercises")
                        }
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.blue)
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
            .onAppear {
                cachedExistingTags = Array(Set(exercises.map(\.tag))).sorted()
                cachedLowercasedNames = Set(exercises.map { $0.name.lowercased() })
            }
            .task(id: name) {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                computedNameSuggestions = ExerciseNameSuggester.suggestions(for: name, existingExercises: exercises.map(\.name))
            }
            .task(id: tagInput) {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                computedTagSuggestions = TagSuggester.suggestions(for: tagInput, existingTags: cachedExistingTags)
            }
            .sheet(isPresented: $showDiscover) { DiscoverView() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .font(DoodleTheme.mono).foregroundStyle(DoodleTheme.dim)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !isDuplicate(trimmed) else { return }
                        Self.haptic.impactOccurred()
                        modelContext.insert(Exercise(name: trimmed, tag: resolvedTag, type: selectedType))
                        dismiss()
                    }
                    .font(DoodleTheme.monoBold)
                    .foregroundStyle(isDuplicate(name.trimmingCharacters(in: .whitespaces)) ? DoodleTheme.dim : DoodleTheme.green)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

}

#Preview {
    AddExerciseView().modelContainer(for: Exercise.self, inMemory: true)
}
