import SwiftUI
import SwiftData

struct LogWorkoutView: View {
    let exercise: Exercise

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var sets: [SetEntry] = [SetEntry()]
    @State private var showPRBanner = false

    private var previousRecord: ExerciseSet? {
        exercise.sets
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }

    private var personalBest: Double {
        exercise.sets.map(\.weight).max() ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let prev = previousRecord {
                        PreviousRecordCard(exerciseSet: prev)
                    }

                    ForEach(sets.indices, id: \.self) { index in
                        SetEntryCard(
                            setNumber: index + 1,
                            entry: $sets[index]
                        )
                    }

                    Button {
                        sets.append(SetEntry())
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Set")
                        }
                        .font(DoodleTheme.body())
                        .foregroundStyle(DoodleTheme.accent)
                    }
                    .padding(.top, 8)

                    if showPRBanner {
                        PRBanner()
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding()
            }
            .background(DoodleTheme.background)
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .disabled(sets.allSatisfy { $0.reps.isEmpty && $0.weight.isEmpty })
                }
            }
        }
    }

    private func saveWorkout() {
        let session = WorkoutSession()
        modelContext.insert(session)

        var hitPR = false

        for (index, entry) in sets.enumerated() {
            guard let reps = Int(entry.reps), let weight = Double(entry.weight) else { continue }

            let set = ExerciseSet(
                reps: reps,
                weight: weight,
                setNumber: index + 1,
                exercise: exercise,
                session: session
            )

            if weight > personalBest {
                set.isPersonalRecord = true
                hitPR = true
            }

            modelContext.insert(set)
        }

        if hitPR {
            withAnimation(.spring(duration: 0.5)) {
                showPRBanner = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } else {
            dismiss()
        }
    }
}

struct SetEntry {
    var reps: String = ""
    var weight: String = ""
}

struct SetEntryCard: View {
    let setNumber: Int
    @Binding var entry: SetEntry

    var body: some View {
        HStack(spacing: 12) {
            Text("Set \(setNumber)")
                .font(DoodleTheme.handwritten(15))
                .foregroundStyle(DoodleTheme.inkLight)
                .frame(width: 50)

            VStack(spacing: 2) {
                TextField("0", text: $entry.reps)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(DoodleTheme.handwritten(20))
                Text("reps")
                    .font(DoodleTheme.caption())
                    .foregroundStyle(DoodleTheme.inkLight)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                TextField("0", text: $entry.weight)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(DoodleTheme.handwritten(20))
                Text("kg")
                    .font(DoodleTheme.caption())
                    .foregroundStyle(DoodleTheme.inkLight)
            }
            .frame(maxWidth: .infinity)
        }
        .doodleCard()
    }
}

struct PreviousRecordCard: View {
    let exerciseSet: ExerciseSet

    private var timeAgo: String {
        let days = Calendar.current.dateComponents([.day], from: exerciseSet.timestamp, to: Date()).day ?? 0
        switch days {
        case 0: return "today"
        case 1: return "yesterday"
        default: return "\(days) days ago"
        }
    }

    var body: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(DoodleTheme.inkLight)

            Text("Last: \(exerciseSet.reps) reps × \(String(format: "%.0f", exerciseSet.weight)) kg")
                .font(DoodleTheme.body())
                .foregroundStyle(DoodleTheme.ink)

            Spacer()

            Text(timeAgo)
                .font(DoodleTheme.caption())
                .foregroundStyle(DoodleTheme.inkLight)
        }
        .doodleCard()
    }
}

struct PRBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .foregroundStyle(.yellow)
            Text("New Personal Record!")
                .font(DoodleTheme.handwritten(18))
                .foregroundStyle(DoodleTheme.ink)
            Image(systemName: "trophy.fill")
                .foregroundStyle(.yellow)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(DoodleTheme.yellow.opacity(0.2))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(DoodleTheme.yellow, lineWidth: 2)
        )
    }
}
