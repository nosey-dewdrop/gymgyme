import SwiftUI
import SwiftData

struct EditWorkoutView: View {
    let sets: [ExerciseSet]
    let date: Date
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var weightUnit: String {
        (profiles.first?.useLbs ?? false) ? "lbs" : "kg"
    }

    @State private var editedSets: [EditableSet] = []
    @State private var setToDelete: Int?

    private static let haptic: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .medium); g.prepare(); return g
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    struct EditableSet: Identifiable {
        let id: UUID
        let original: ExerciseSet
        var reps: String
        var weight: String
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("edit workout")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(DoodleTheme.orange)

                    Text(Self.dateFormatter.string(from: date))
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.dim)
                        .padding(.bottom, 8)

                    ForEach(editedSets.indices, id: \.self) { i in
                        HStack(spacing: 8) {
                            Text("\(i + 1)")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.color(for: i))
                                .frame(width: 24)

                            TextField("reps", text: $editedSets[i].reps)
                                .keyboardType(.numberPad)
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.fg)
                                .padding(8)
                                .background(DoodleTheme.surface)
                                .cornerRadius(4)

                            Text("×")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.dim)

                            TextField(weightUnit, text: $editedSets[i].weight)
                                .keyboardType(.decimalPad)
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.fg)
                                .padding(8)
                                .background(DoodleTheme.surface)
                                .cornerRadius(4)

                            Button {
                                setToDelete = i
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundStyle(DoodleTheme.red)
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
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.dim)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") { saveEdits() }
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.green)
                }
            }
            .onAppear { loadSets() }
            .alert("delete set?", isPresented: Binding(
                get: { setToDelete != nil },
                set: { if !$0 { setToDelete = nil } }
            )) {
                Button("cancel", role: .cancel) { setToDelete = nil }
                Button("delete", role: .destructive) {
                    if let index = setToDelete {
                        deleteSet(at: index)
                    }
                    setToDelete = nil
                }
            } message: {
                Text("this set will be permanently deleted")
            }
        }
    }

    private func loadSets() {
        editedSets = sets.sorted { $0.setNumber < $1.setNumber }.map {
            EditableSet(id: UUID(), original: $0, reps: "\($0.reps)", weight: String(format: "%.0f", $0.weight))
        }
    }

    private func saveEdits() {
        for edited in editedSets {
            if let reps = Int(edited.reps), reps > 0,
               let weight = Double(edited.weight), weight >= 0 {
                edited.original.reps = reps
                edited.original.weight = weight
            }
        }
        Self.haptic.impactOccurred()
        WidgetSync.sync(context: modelContext)
        dismiss()
    }

    private func deleteSet(at index: Int) {
        let set = editedSets[index].original
        modelContext.delete(set)
        editedSets.remove(at: index)
    }
}
