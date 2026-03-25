import SwiftUI
import SwiftData
import Combine

struct LogWorkoutView: View {
    let exercise: Exercise
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // weight/bodyweight sets
    @State private var sets: [SetEntry] = [SetEntry()]
    @State private var showPRBanner = false

    // duration/cardio
    @State private var durationMinutes = ""
    @State private var durationSeconds = ""
    @State private var distanceKm = ""

    // rest timer
    @State private var restSeconds: Int = 0
    @State private var restDuration: Int = 90
    @State private var timerActive = false
    @State private var timerCancellable: AnyCancellable?

    // cached on appear — avoid scanning all sets during render
    @State private var cachedPreviousRecord: ExerciseSet?
    @State private var cachedPersonalBest: Double = 0
    @State private var cachedPersonalBestDuration: Int = 0
    @State private var cachedBestReps: Int = 0
    @State private var cachedPrevDaysAgo: Int = 0
    @State private var cachedPrevTimeText: String = ""

    private static let hapticMedium: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        return g
    }()

    private static let hapticSuccess: UINotificationFeedbackGenerator = {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        return g
    }()

    private var useLbs: Bool {
        profiles.first?.useLbs ?? false
    }

    private var weightUnit: String {
        useLbs ? "lbs" : "kg"
    }

    private func cacheExerciseStats() {
        var maxDate: Date?
        var maxDateSet: ExerciseSet?
        var bestWeight: Double = 0
        var bestDuration: Int = 0
        var bestReps: Int = 0
        for s in exercise.sets {
            if let max = maxDate {
                if s.timestamp > max { maxDate = s.timestamp; maxDateSet = s }
            } else {
                maxDate = s.timestamp; maxDateSet = s
            }
            if s.weight > bestWeight { bestWeight = s.weight }
            if s.durationSeconds > bestDuration { bestDuration = s.durationSeconds }
            if s.reps > bestReps { bestReps = s.reps }
        }
        cachedPreviousRecord = maxDateSet
        cachedPersonalBest = bestWeight
        cachedPersonalBestDuration = bestDuration
        cachedBestReps = bestReps
        if let ts = maxDate {
            let days = Calendar.current.dateComponents([.day], from: ts, to: Date()).day ?? 0
            cachedPrevDaysAgo = days
            cachedPrevTimeText = days == 0 ? "today" : days == 1 ? "yesterday" : "\(days)d ago"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(DoodleTheme.pink)

                    HStack(spacing: 6) {
                        TagChip(tag: exercise.tag)
                        Image(systemName: exercise.exerciseType.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(DoodleTheme.dim)
                        Text(exercise.exerciseType.label)
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                    }
                    .padding(.bottom, 4)

                    previousRecordSection

                    switch exercise.exerciseType {
                    case .weightReps:
                        weightRepsInput
                    case .bodyweight:
                        bodyweightInput
                    case .duration:
                        durationInput
                    case .cardio:
                        cardioInput
                    }

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

                    // rest timer (only for set-based exercises)
                    if exercise.exerciseType == .weightReps || exercise.exerciseType == .bodyweight {
                        restTimerSection
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
                    Button("save") { saveWorkout() }
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.green)
                        .disabled(!canSave)
                }
            }
            .onAppear { cacheExerciseStats() }
            .onDisappear { timerCancellable?.cancel() }
        }
    }

    // MARK: - Previous Record

    @ViewBuilder
    private var previousRecordSection: some View {
        if let prev = cachedPreviousRecord {
            let timeText = cachedPrevTimeText

            HStack(spacing: 0) {
                Text("last: ")
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)

                switch exercise.exerciseType {
                case .weightReps:
                    Text("\(prev.reps) reps × \(String(format: "%.0f", prev.weight)) \(weightUnit)")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.fg)
                case .bodyweight:
                    Text("\(prev.reps) reps")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.fg)
                case .duration:
                    Text(prev.formattedDuration)
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.fg)
                case .cardio:
                    Text("\(prev.formattedDuration) · \(prev.formattedDistance)")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.fg)
                }

                Text(" · \(timeText)")
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
            }
            .padding(.bottom, 4)
        }
    }

    // MARK: - Weight + Reps Input

    private var weightRepsInput: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("your sets")
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

                    if sets.count > 1 {
                        Button { sets.remove(at: index) } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(DoodleTheme.red)
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            addSetButton
        }
    }

    // MARK: - Bodyweight Input

    private var bodyweightInput: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("your sets")
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

                    Text("reps")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.dim)

                    Spacer()

                    if sets.count > 1 {
                        Button { sets.remove(at: index) } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(DoodleTheme.red)
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            addSetButton
        }
    }

    // MARK: - Duration Input

    private var durationInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("duration")
                .font(DoodleTheme.monoBold)
                .foregroundStyle(DoodleTheme.blue)
                .padding(.top, 4)

            HStack(spacing: 8) {
                TextField("min", text: $durationMinutes)
                    .keyboardType(.numberPad)
                    .font(DoodleTheme.mono)
                    .foregroundStyle(DoodleTheme.fg)
                    .padding(8)
                    .background(DoodleTheme.surface)
                    .cornerRadius(4)

                Text("min")
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)

                TextField("sec", text: $durationSeconds)
                    .keyboardType(.numberPad)
                    .font(DoodleTheme.mono)
                    .foregroundStyle(DoodleTheme.fg)
                    .padding(8)
                    .background(DoodleTheme.surface)
                    .cornerRadius(4)

                Text("sec")
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
            }
        }
    }

    // MARK: - Cardio Input

    private var cardioInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("duration")
                .font(DoodleTheme.monoBold)
                .foregroundStyle(DoodleTheme.blue)
                .padding(.top, 4)

            HStack(spacing: 8) {
                TextField("min", text: $durationMinutes)
                    .keyboardType(.numberPad)
                    .font(DoodleTheme.mono)
                    .foregroundStyle(DoodleTheme.fg)
                    .padding(8)
                    .background(DoodleTheme.surface)
                    .cornerRadius(4)

                Text("min")
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)

                TextField("sec", text: $durationSeconds)
                    .keyboardType(.numberPad)
                    .font(DoodleTheme.mono)
                    .foregroundStyle(DoodleTheme.fg)
                    .padding(8)
                    .background(DoodleTheme.surface)
                    .cornerRadius(4)

                Text("sec")
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
            }

            Text("distance")
                .font(DoodleTheme.monoBold)
                .foregroundStyle(DoodleTheme.green)

            HStack(spacing: 8) {
                TextField("0.0", text: $distanceKm)
                    .keyboardType(.decimalPad)
                    .font(DoodleTheme.mono)
                    .foregroundStyle(DoodleTheme.fg)
                    .padding(8)
                    .background(DoodleTheme.surface)
                    .cornerRadius(4)

                Text("km")
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
            }
        }
    }

    // MARK: - Shared Components

    private var addSetButton: some View {
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
    }

    private var restTimerSection: some View {
        VStack(spacing: 0) {
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
    }

    // MARK: - Validation

    private var canSave: Bool {
        switch exercise.exerciseType {
        case .weightReps:
            return !sets.allSatisfy { $0.reps.isEmpty && $0.weight.isEmpty }
        case .bodyweight:
            return !sets.allSatisfy { $0.reps.isEmpty }
        case .duration:
            return !durationMinutes.isEmpty || !durationSeconds.isEmpty
        case .cardio:
            return !durationMinutes.isEmpty || !durationSeconds.isEmpty
        }
    }

    // MARK: - Save

    private func saveWorkout() {
        let session = WorkoutSession()
        modelContext.insert(session)

        switch exercise.exerciseType {
        case .weightReps:
            saveWeightReps(session: session)
        case .bodyweight:
            saveBodyweight(session: session)
        case .duration:
            saveDuration(session: session)
        case .cardio:
            saveCardio(session: session)
        }

        WidgetSync.sync(context: modelContext)
        Self.hapticMedium.impactOccurred()
    }

    private func saveWeightReps(session: WorkoutSession) {
        var validSets: [(reps: Int, weight: Double, index: Int)] = []
        for (i, entry) in sets.enumerated() {
            guard let reps = Int(entry.reps), reps > 0,
                  let weight = Double(entry.weight), weight > 0 else { continue }
            validSets.append((reps: reps, weight: weight, index: i))
        }
        guard !validSets.isEmpty else { dismiss(); return }

        var hitPR = false
        for valid in validSets {
            let set = ExerciseSet(reps: valid.reps, weight: valid.weight, setNumber: valid.index + 1, exercise: exercise, session: session)
            if valid.weight > cachedPersonalBest && valid.weight > 0 { set.isPersonalRecord = true; hitPR = true }
            modelContext.insert(set)
        }

        if hitPR {
            Self.hapticSuccess.notificationOccurred(.success)
            withAnimation { showPRBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { startTimer() }
        } else {
            startTimer()
        }
    }

    private func saveBodyweight(session: WorkoutSession) {
        var validSets: [(reps: Int, index: Int)] = []
        for (i, entry) in sets.enumerated() {
            guard let reps = Int(entry.reps), reps > 0 else { continue }
            validSets.append((reps: reps, index: i))
        }
        guard !validSets.isEmpty else { dismiss(); return }

        let bestReps = cachedBestReps
        var hitPR = false
        for valid in validSets {
            let set = ExerciseSet(reps: valid.reps, setNumber: valid.index + 1, exercise: exercise, session: session)
            if valid.reps > bestReps && valid.reps > 0 { set.isPersonalRecord = true; hitPR = true }
            modelContext.insert(set)
        }

        if hitPR {
            Self.hapticSuccess.notificationOccurred(.success)
            withAnimation { showPRBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { startTimer() }
        } else {
            startTimer()
        }
    }

    private func saveDuration(session: WorkoutSession) {
        let mins = Int(durationMinutes) ?? 0
        let secs = Int(durationSeconds) ?? 0
        let totalSeconds = mins * 60 + secs
        guard totalSeconds > 0 else { dismiss(); return }

        let set = ExerciseSet(durationSeconds: totalSeconds, exercise: exercise, session: session)
        if totalSeconds > cachedPersonalBestDuration && cachedPersonalBestDuration > 0 {
            set.isPersonalRecord = true
            Self.hapticSuccess.notificationOccurred(.success)
            withAnimation { showPRBanner = true }
        }
        modelContext.insert(set)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() }
    }

    private func saveCardio(session: WorkoutSession) {
        let mins = Int(durationMinutes) ?? 0
        let secs = Int(durationSeconds) ?? 0
        let totalSeconds = mins * 60 + secs
        let distance = Double(distanceKm) ?? 0
        guard totalSeconds > 0 else { dismiss(); return }

        let set = ExerciseSet(durationSeconds: totalSeconds, distanceKm: distance, exercise: exercise, session: session)
        modelContext.insert(set)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() }
    }

    // MARK: - Timer

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
