import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Query private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var tagInput = ""
    @State private var showSuggestions = false

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
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        ColoredHeader("NAME", color: DoodleTheme.blue)
                        TextField("exercise name", text: $name)
                            .font(DoodleTheme.body())
                            .foregroundStyle(DoodleTheme.ink)
                            .padding()
                            .background(DoodleTheme.cardBackgroundLight)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DoodleTheme.blue.opacity(0.3), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ColoredHeader("TAG", color: DoodleTheme.green)
                        TextField("#bacak, #omuz, #gogus...", text: $tagInput)
                            .font(DoodleTheme.mono(15))
                            .foregroundStyle(DoodleTheme.ink)
                            .padding()
                            .background(DoodleTheme.cardBackgroundLight)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DoodleTheme.green.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: tagInput) { _, _ in
                                showSuggestions = !tagInput.isEmpty
                            }

                        if !tagInput.isEmpty && resolvedTag != tagInput.lowercased().trimmingCharacters(in: .whitespaces) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                TagChip(tag: resolvedTag)
                            }
                            .foregroundStyle(DoodleTheme.inkLight)
                            .transition(.opacity)
                        }

                        if showSuggestions && !suggestions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(suggestions, id: \.self) { suggestion in
                                        Button {
                                            tagInput = suggestion
                                            showSuggestions = false
                                        } label: {
                                            TagChip(tag: suggestion)
                                        }
                                    }
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                }
                .padding()

                Spacer()
            }
            .background(DoodleTheme.background)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DoodleTheme.inkLight)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let exercise = Exercise(
                            name: name.trimmingCharacters(in: .whitespaces),
                            tag: resolvedTag
                        )
                        modelContext.insert(exercise)
                        dismiss()
                    }
                    .foregroundStyle(DoodleTheme.green)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddExerciseView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
