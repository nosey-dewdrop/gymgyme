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
            .background(DoodleTheme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .font(DoodleTheme.mono).foregroundStyle(DoodleTheme.dim)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        modelContext.insert(Exercise(name: name.trimmingCharacters(in: .whitespaces), tag: resolvedTag))
                        dismiss()
                    }
                    .font(DoodleTheme.monoBold).foregroundStyle(DoodleTheme.green)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddExerciseView().modelContainer(for: Exercise.self, inMemory: true)
}
