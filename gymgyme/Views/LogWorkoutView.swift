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
                VStack(spacing: 14) {
                    if let prev = previousRecord {
                        PreviousRecordCard(exerciseSet: prev)
                    }

                    ForEach(sets.indices, id: \.self) { index in
                        SetEntryCard(
                            setNumber: index + 1,
                            entry: $sets[index],
                            color: DoodleTheme.titleColor(for: index)
                        )
                    }

                    Button {
                        sets.append(SetEntry())
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Set")
                        }
                        .font(DoodleTheme.mono(14))
                        .foregroundStyle(DoodleTheme.blue)
                    }
                    .padding(.top, 4)

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
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DoodleTheme.inkLight)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkout()
                    }
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
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text("SET \(setNumber)")
                .font(DoodleTheme.mono(11))
                .foregroundStyle(color)
                .frame(width: 44)

            VStack(spacing: 2) {
                TextField("0", text: $entry.reps)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(DoodleTheme.handwritten(22))
                    .foregroundStyle(DoodleTheme.ink)
                Text("reps")
                    .font(DoodleTheme.mono(10))
                    .foregroundStyle(DoodleTheme.inkDim)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                TextField("0", text: $entry.weight)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(DoodleTheme.handwritten(22))
                    .foregroundStyle(DoodleTheme.ink)
                Text("kg")
                    .font(DoodleTheme.mono(10))
                    .foregroundStyle(DoodleTheme.inkDim)
            }
            .frame(maxWidth: .infinity)
        }
        .glowCard(color: color)
    }
}

struct PreviousRecordCard: View {
    let exerciseSet: ExerciseSet

    private var timeAgo: String {
        let days = Calendar.current.dateComponents([.day], from: exerciseSet.timestamp, to: Date()).day ?? 0
        switch days {
        case 0: return "today"
        case 1: return "yesterday"
        default: return "\(days)d ago"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(DoodleTheme.inkDim)

            Text("last: \(exerciseSet.reps) reps x \(String(format: "%.0f", exerciseSet.weight)) kg")
                .font(DoodleTheme.mono(13))
                .foregroundStyle(DoodleTheme.ink)

            Spacer()

            Text(timeAgo)
                .font(DoodleTheme.mono(11))
                .foregroundStyle(DoodleTheme.inkLight)
        }
        .glowCard(color: DoodleTheme.blue)
    }
}

struct PRBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .foregroundStyle(DoodleTheme.yellow)
            Text("NEW PERSONAL RECORD!")
                .font(DoodleTheme.mono(15))
                .foregroundStyle(DoodleTheme.yellow)
            Image(systemName: "trophy.fill")
                .foregroundStyle(DoodleTheme.yellow)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(DoodleTheme.yellow.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(DoodleTheme.yellow.opacity(0.4), lineWidth: 2)
        )
        .shadow(color: DoodleTheme.yellow.opacity(0.3), radius: 12, x: 0, y: 4)
    }
}
