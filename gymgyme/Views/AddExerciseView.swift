import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedMuscleGroup: MuscleGroup = .chest

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise name", text: $name)
                        .font(DoodleTheme.body())
                } header: {
                    Text("Name")
                }
                .listRowBackground(DoodleTheme.cardBackground)

                Section {
                    ForEach(MuscleGroup.allCases) { group in
                        Button {
                            selectedMuscleGroup = group
                        } label: {
                            HStack {
                                Image(systemName: group.icon)
                                    .frame(width: 30)
                                Text(group.displayName)
                                    .font(DoodleTheme.body())
                                Spacer()
                                if selectedMuscleGroup == group {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(DoodleTheme.accent)
                                }
                            }
                            .foregroundStyle(DoodleTheme.ink)
                        }
                    }
                } header: {
                    Text("Muscle Group")
                }
                .listRowBackground(DoodleTheme.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(DoodleTheme.background)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let exercise = Exercise(name: name.trimmingCharacters(in: .whitespaces), muscleGroup: selectedMuscleGroup)
                        modelContext.insert(exercise)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddExerciseView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
