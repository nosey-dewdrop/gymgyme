import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Query private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var tagInput = ""

    private var existingTags: [String] {
        Array(Set(exercises.map(\.tag))).sorted()
    }

    private var suggestions: [String] {
        TagSuggester.suggestions(for: tagInput, existingTags: existingTags)
    }

    private var resolvedTag: String {
        TagSuggester.suggest(for: tagInput)
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
                    }

                    if !name.isEmpty && !nameSuggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(nameSuggestions, id: \.self) { s in
                                    Button {
                                        name = s
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
                        Text("tag:  ")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.dim)
                        TextField("bacak", text: $tagInput)
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

                    if !suggestions.isEmpty && !tagInput.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(suggestions.prefix(5), id: \.self) { s in
                                Button { tagInput = s } label: {
                                    Text("#\(s)")
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.color(for: s))
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .font(DoodleTheme.mono).foregroundStyle(DoodleTheme.dim)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !isDuplicate(trimmed) else { return }
                        modelContext.insert(Exercise(name: trimmed, tag: resolvedTag))
                        dismiss()
                    }
                    .font(DoodleTheme.monoBold)
                    .foregroundStyle(isDuplicate(name.trimmingCharacters(in: .whitespaces)) ? DoodleTheme.dim : DoodleTheme.green)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var nameSuggestions: [String] {
        let input = name.lowercased().trimmingCharacters(in: .whitespaces)
        guard input.count >= 2 else { return [] }
        let existing = exercises.map(\.name)
        return existing.filter { $0.lowercased().contains(input) }.prefix(5).map { $0 }
    }

    private func isDuplicate(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        return exercises.contains { $0.name.lowercased() == name.lowercased() }
    }
}

#Preview {
    AddExerciseView().modelContainer(for: Exercise.self, inMemory: true)
}
