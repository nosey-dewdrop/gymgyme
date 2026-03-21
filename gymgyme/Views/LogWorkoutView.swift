import SwiftUI
import SwiftData

struct LogWorkoutView: View {
    let exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var sets: [SetEntry] = [SetEntry()]
    @State private var showPRBanner = false

    private var previousRecord: ExerciseSet? {
        exercise.sets.sorted { $0.timestamp > $1.timestamp }.first
    }

    private var personalBest: Double {
        exercise.sets.map(\.weight).max() ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(DoodleTheme.pink)

                    TagChip(tag: exercise.tag)
                        .padding(.bottom, 4)

                    if let prev = previousRecord {
                        let days = Calendar.current.dateComponents([.day], from: prev.timestamp, to: Date()).day ?? 0
                        let timeText = days == 0 ? "today" : days == 1 ? "yesterday" : "\(days)d ago"
                        HStack(spacing: 0) {
                            Text("last: ")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                            Text("\(prev.reps) reps × \(String(format: "%.0f", prev.weight)) kg")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.fg)
                            Text(" · \(timeText)")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                        }
                        .padding(.bottom, 4)
                    }

                    Text("─ sets")
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.blue)
                        .padding(.top, 4)

                    ForEach(sets.indices, id: \.self) { index in
                        HStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.color(for: index))
                                .frame(width: 20)

                            TextField("reps", text: $sets[index].reps)
                                .keyboardType(.numberPad)
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.fg)
                                .padding(8)
                                .background(DoodleTheme.surface)
                                .cornerRadius(4)

                            Text("×")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.dim)

                            TextField("kg", text: $sets[index].weight)
                                .keyboardType(.decimalPad)
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.fg)
                                .padding(8)
                                .background(DoodleTheme.surface)
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 2)
                    }

                    Button {
                        sets.append(SetEntry())
                    } label: {
                        HStack(spacing: 0) {
                            Text("+ ")
                                .foregroundStyle(DoodleTheme.blue)
                            Text("add set")
                                .foregroundStyle(DoodleTheme.dim)
                        }
                        .font(DoodleTheme.mono)
                    }
                    .padding(.top, 4)

                    if showPRBanner {
                        HStack(spacing: 0) {
                            Text("★ ")
                                .foregroundStyle(DoodleTheme.yellow)
                            Text("NEW PERSONAL RECORD!")
                                .foregroundStyle(DoodleTheme.yellow)
                        }
                        .font(DoodleTheme.monoBold)
                        .padding(.top, 8)
                        .transition(.opacity)
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
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.dim)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") { saveWorkout() }
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.green)
                        .disabled(sets.allSatisfy { $0.reps.isEmpty && $0.weight.isEmpty })
                }
            }
        }
    }

    private func saveWorkout() {
        let session = WorkoutSession()
        modelContext.insert(session)
        var hitPR = false
        for (i, entry) in sets.enumerated() {
            guard let reps = Int(entry.reps), let weight = Double(entry.weight) else { continue }
            let set = ExerciseSet(reps: reps, weight: weight, setNumber: i + 1, exercise: exercise, session: session)
            if weight > personalBest { set.isPersonalRecord = true; hitPR = true }
            modelContext.insert(set)
        }
        if hitPR {
            withAnimation { showPRBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
        } else { dismiss() }
    }
}

struct SetEntry {
    var reps: String = ""
    var weight: String = ""
}
