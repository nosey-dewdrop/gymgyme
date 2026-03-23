import SwiftUI
import SwiftData
import Combine

struct LogWorkoutView: View {
    let exercise: Exercise
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var sets: [SetEntry] = [SetEntry()]
    @State private var showPRBanner = false
    @State private var restSeconds: Int = 0
    @State private var restDuration: Int = 90
    @State private var timerActive = false
    @State private var timerCancellable: AnyCancellable?

    private var previousRecord: ExerciseSet? {
        exercise.sets.sorted { $0.timestamp > $1.timestamp }.first
    }

    private var useLbs: Bool {
        profiles.first?.useLbs ?? false
    }

    private var weightUnit: String {
        useLbs ? "lbs" : "kg"
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
                            Text("\(prev.reps) reps × \(String(format: "%.0f", prev.weight)) \(weightUnit)")
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

                            TextField(weightUnit, text: $sets[index].weight)
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

                    // rest timer
                    if timerActive {
                        VStack(spacing: 4) {
                            Text("rest")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                            Text("\(restSeconds)s")
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                                .foregroundStyle(DoodleTheme.green)
                            Text("tap to skip")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                        .onTapGesture { stopTimer() }
                        .transition(.opacity)
                    }

                    // rest duration picker
                    HStack(spacing: 0) {
                        Text("rest timer: ")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                        Text("\(restDuration)s")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.green)
                        Spacer()
                        Stepper("", value: $restDuration, in: 15...300, step: 15)
                            .labelsHidden()
                            .tint(DoodleTheme.green)
                    }
                    .padding(.top, 8)
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
                    Button("save") { saveWorkout() }
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.green)
                        .disabled(sets.allSatisfy { $0.reps.isEmpty && $0.weight.isEmpty })
                }
            }
        }
    }

    private func saveWorkout() {
        // validate and collect valid sets first
        var validSets: [(reps: Int, weight: Double, index: Int)] = []
        for (i, entry) in sets.enumerated() {
            guard let reps = Int(entry.reps), reps > 0,
                  let weight = Double(entry.weight), weight > 0 else { continue }
            validSets.append((reps: reps, weight: weight, index: i))
        }
        guard !validSets.isEmpty else { dismiss(); return }

        let session = WorkoutSession()
        modelContext.insert(session)
        var hitPR = false
        for valid in validSets {
            let set = ExerciseSet(reps: valid.reps, weight: valid.weight, setNumber: valid.index + 1, exercise: exercise, session: session)
            if valid.weight > personalBest && valid.weight > 0 { set.isPersonalRecord = true; hitPR = true }
            modelContext.insert(set)
        }
        WidgetSync.sync(context: modelContext)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if hitPR {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { showPRBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                startTimer()
            }
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        restSeconds = restDuration
        withAnimation { timerActive = true }
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if restSeconds > 0 {
                    restSeconds -= 1
                } else {
                    stopTimer()
                }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        withAnimation { timerActive = false }
        dismiss()
    }
}

struct SetEntry {
    var reps: String = ""
    var weight: String = ""
}
