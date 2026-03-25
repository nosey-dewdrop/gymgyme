import SwiftUI

// MARK: - PT Intake Data

struct PTIntakeData {
    var goal: PTGoal?
    var daysPerWeek: Int = 3
    var sessionMinutes: Int = 60
    var experience: PTExperience?
    var location: PTLocation?
    var homeEquipment: Set<Equipment> = []
    var splitPreference: PTSplitPreference?
    var focusArea: PTFocusArea?
    var age: String = ""
    var gender: PTGender?
    var injury: String = ""
}

enum PTGoal: String, CaseIterable {
    case muscle = "muscle"
    case strength = "strength"
    case weightLoss = "weight_loss"
    case general = "general"

    var label: String {
        switch self {
        case .muscle: return "build muscle"
        case .strength: return "get stronger"
        case .weightLoss: return "lose weight"
        case .general: return "general fitness"
        }
    }

    var icon: String {
        switch self {
        case .muscle: return "figure.strengthtraining.traditional"
        case .strength: return "dumbbell.fill"
        case .weightLoss: return "flame"
        case .general: return "heart.circle"
        }
    }

    var description: String {
        switch self {
        case .muscle: return "more reps, moderate weight, high volume"
        case .strength: return "heavy weight, fewer reps, long rest"
        case .weightLoss: return "full body sessions, shorter rest, cardio mix"
        case .general: return "balanced training, stay active and healthy"
        }
    }
}

enum PTExperience: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    var label: String {
        switch self {
        case .beginner: return "just starting out"
        case .intermediate: return "1-2 years"
        case .advanced: return "3+ years"
        }
    }

    var description: String {
        switch self {
        case .beginner: return "new to the gym or coming back after a long break"
        case .intermediate: return "comfortable with most exercises, looking to level up"
        case .advanced: return "experienced lifter, knows their way around"
        }
    }
}

enum PTLocation: String, CaseIterable {
    case gym = "gym"
    case home = "home"
    case both = "both"

    var label: String {
        switch self {
        case .gym: return "gym"
        case .home: return "home"
        case .both: return "both"
        }
    }

    var icon: String {
        switch self {
        case .gym: return "building.2"
        case .home: return "house"
        case .both: return "arrow.left.arrow.right"
        }
    }
}

enum PTSplitPreference: String, CaseIterable {
    case fullBody = "full_body"
    case upperLower = "upper_lower"
    case auto = "auto"

    var label: String {
        switch self {
        case .fullBody: return "full body each session"
        case .upperLower: return "upper body / lower body"
        case .auto: return "you decide for me"
        }
    }

    var description: String {
        switch self {
        case .fullBody: return "great for 2-3 days per week"
        case .upperLower: return "good for 4+ days per week"
        case .auto: return "we'll pick the best plan for your schedule"
        }
    }
}

enum PTFocusArea: String, CaseIterable {
    case upper = "upper"
    case lower = "lower"
    case balanced = "balanced"
    case doesntMatter = "any"

    var label: String {
        switch self {
        case .upper: return "upper body"
        case .lower: return "lower body"
        case .balanced: return "balanced"
        case .doesntMatter: return "doesn't matter"
        }
    }
}

enum PTGender: String, CaseIterable {
    case female = "female"
    case male = "male"
    case preferNot = "prefer_not"

    var label: String {
        switch self {
        case .female: return "female"
        case .male: return "male"
        case .preferNot: return "prefer not to say"
        }
    }
}

// MARK: - PT Intake View

struct PTIntakeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var data = PTIntakeData()
    @State private var isGenerating = false

    var onComplete: (PTIntakeData) -> Void

    private let totalSteps = 10

    private var canProceed: Bool {
        switch step {
        case 0: return data.goal != nil
        case 1: return true // slider always has a value
        case 2: return true // slider always has a value
        case 3: return data.experience != nil
        case 4: return data.location != nil
        case 5: return data.location != .home || !data.homeEquipment.isEmpty
        case 6: return data.splitPreference != nil
        case 7: return data.focusArea != nil
        case 8: return true // age is optional
        case 9: return true // gender is optional
        default: return true
        }
    }

    private var showStep5: Bool {
        data.location == .home || data.location == .both
    }

    private var currentVisualStep: Int {
        if !showStep5 && step >= 5 {
            return step - 1
        }
        return step
    }

    private var totalVisualSteps: Int {
        showStep5 ? totalSteps : totalSteps - 1
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                stepContent
                navigationButtons
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar { cancelToolbarItem }
        }
    }

    private var progressBar: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DoodleTheme.surface)
                        .frame(height: 4)
                    Rectangle()
                        .fill(DoodleTheme.green)
                        .frame(width: geo.size.width * CGFloat(currentVisualStep + 1) / CGFloat(totalVisualSteps), height: 4)
                        .animation(.easeInOut(duration: 0.3), value: step)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Text("\(currentVisualStep + 1) / \(totalVisualSteps)")
                .font(DoodleTheme.monoSmall)
                .foregroundStyle(DoodleTheme.dim)
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        Spacer()
        currentStepView
            .padding(.horizontal, 24)
        Spacer()
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case 0: goalStep
        case 1: daysStep
        case 2: durationStep
        case 3: experienceStep
        case 4: locationStep
        case 5:
            if showStep5 { equipmentStep } else { splitStep }
        case 6:
            if showStep5 { splitStep } else { focusStep }
        case 7:
            if showStep5 { focusStep } else { ageStep }
        case 8:
            if showStep5 { ageStep } else { genderStep }
        case 9:
            if showStep5 { genderStep } else { injuryStep }
        default: injuryStep
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { step -= 1 }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("back")
                    }
                    .font(DoodleTheme.mono)
                    .foregroundStyle(DoodleTheme.dim)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                }
            }

            Spacer()

            let isLast = (showStep5 && step == totalSteps - 1) || (!showStep5 && step == totalSteps - 2)

            Button {
                if isLast {
                    onComplete(data)
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if step == 4 && !showStep5 {
                            step = 6
                        } else {
                            step += 1
                        }
                    }
                }
            } label: {
                Text(isLast ? "create my program" : "next")
                    .font(DoodleTheme.monoBold)
                    .foregroundStyle(canProceed ? DoodleTheme.bg : DoodleTheme.dim)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .background(canProceed ? DoodleTheme.green : DoodleTheme.surface)
                    .cornerRadius(10)
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var cancelToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("cancel") { dismiss() }
                .font(DoodleTheme.mono)
                .foregroundStyle(DoodleTheme.dim)
        }
    }

    // MARK: - Step 0: Goal

    private var goalStep: some View {
        VStack(spacing: 16) {
            questionTitle("what's your goal?")

            ForEach(PTGoal.allCases, id: \.rawValue) { goal in
                optionCard(
                    title: goal.label,
                    subtitle: goal.description,
                    icon: goal.icon,
                    isSelected: data.goal == goal
                ) {
                    data.goal = goal
                }
            }
        }
    }

    // MARK: - Step 1: Days per week

    private var daysStep: some View {
        VStack(spacing: 16) {
            questionTitle("how many days per week\ncan you work out?")

            Text("\(data.daysPerWeek)")
                .font(.system(size: 48, weight: .black, design: .monospaced))
                .foregroundStyle(DoodleTheme.green)

            Text(daysDescription)
                .font(DoodleTheme.monoSmall)
                .foregroundStyle(DoodleTheme.dim)
                .multilineTextAlignment(.center)

            Slider(value: Binding(
                get: { Double(data.daysPerWeek) },
                set: { data.daysPerWeek = Int($0) }
            ), in: 2...6, step: 1)
            .tint(DoodleTheme.green)
        }
    }

    private var daysDescription: String {
        switch data.daysPerWeek {
        case 2: return "full body sessions recommended"
        case 3: return "full body or upper/lower split"
        case 4: return "upper/lower split works great"
        case 5: return "push/pull/legs or upper/lower"
        case 6: return "push/pull/legs twice a week"
        default: return ""
        }
    }

    // MARK: - Step 2: Duration

    private var durationStep: some View {
        VStack(spacing: 16) {
            questionTitle("how long is\nyour typical session?")

            let options = [30, 45, 60, 90]
            ForEach(options, id: \.self) { mins in
                optionCard(
                    title: "\(mins) minutes",
                    subtitle: durationDescription(mins),
                    icon: "clock",
                    isSelected: data.sessionMinutes == mins
                ) {
                    data.sessionMinutes = mins
                }
            }
        }
    }

    private func durationDescription(_ mins: Int) -> String {
        switch mins {
        case 30: return "quick and focused"
        case 45: return "enough for a solid workout"
        case 60: return "the sweet spot for most people"
        case 90: return "plenty of time for everything"
        default: return ""
        }
    }

    // MARK: - Step 3: Experience

    private var experienceStep: some View {
        VStack(spacing: 16) {
            questionTitle("how long have you\nbeen working out?")

            ForEach(PTExperience.allCases, id: \.rawValue) { exp in
                optionCard(
                    title: exp.label,
                    subtitle: exp.description,
                    icon: "person.fill",
                    isSelected: data.experience == exp
                ) {
                    data.experience = exp
                }
            }
        }
    }

    // MARK: - Step 4: Location

    private var locationStep: some View {
        VStack(spacing: 16) {
            questionTitle("where do you\nwork out?")

            ForEach(PTLocation.allCases, id: \.rawValue) { loc in
                optionCard(
                    title: loc.label,
                    subtitle: "",
                    icon: loc.icon,
                    isSelected: data.location == loc
                ) {
                    data.location = loc
                    if loc == .gym {
                        data.homeEquipment = [.gym]
                    }
                }
            }
        }
    }

    // MARK: - Step 5: Equipment (only if home/both)

    private var equipmentStep: some View {
        VStack(spacing: 16) {
            questionTitle("what equipment\ndo you have at home?")

            Text("select all that apply")
                .font(DoodleTheme.monoSmall)
                .foregroundStyle(DoodleTheme.dim)

            let homeEquipment: [Equipment] = [.dumbbell, .band, .pullupBar, .kettlebell, .none]
            ForEach(homeEquipment) { equip in
                let isSelected = data.homeEquipment.contains(equip)
                optionCard(
                    title: equip.label,
                    subtitle: "",
                    icon: equip.icon,
                    isSelected: isSelected
                ) {
                    if equip == .none {
                        data.homeEquipment = [.none]
                    } else {
                        data.homeEquipment.remove(.none)
                        if isSelected {
                            data.homeEquipment.remove(equip)
                        } else {
                            data.homeEquipment.insert(equip)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step 6: Split

    private var splitStep: some View {
        VStack(spacing: 16) {
            questionTitle("how should we\nplan your workouts?")

            ForEach(PTSplitPreference.allCases, id: \.rawValue) { split in
                optionCard(
                    title: split.label,
                    subtitle: split.description,
                    icon: "calendar",
                    isSelected: data.splitPreference == split
                ) {
                    data.splitPreference = split
                }
            }
        }
    }

    // MARK: - Step 7: Focus area

    private var focusStep: some View {
        VStack(spacing: 16) {
            questionTitle("any area you want\nto focus on?")

            ForEach(PTFocusArea.allCases, id: \.rawValue) { area in
                optionCard(
                    title: area.label,
                    subtitle: "",
                    icon: "target",
                    isSelected: data.focusArea == area
                ) {
                    data.focusArea = area
                }
            }
        }
    }

    // MARK: - Step 8: Age

    private var ageStep: some View {
        VStack(spacing: 16) {
            questionTitle("how old are you?")

            Text("optional — helps adjust intensity")
                .font(DoodleTheme.monoSmall)
                .foregroundStyle(DoodleTheme.dim)

            TextField("age", text: $data.age)
                .keyboardType(.numberPad)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(DoodleTheme.fg)
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    step += 1
                }
            } label: {
                Text("skip")
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
            }
        }
    }

    // MARK: - Step 9: Gender

    private var genderStep: some View {
        VStack(spacing: 16) {
            questionTitle("your gender?")

            Text("optional — helps balance the program")
                .font(DoodleTheme.monoSmall)
                .foregroundStyle(DoodleTheme.dim)

            ForEach(PTGender.allCases, id: \.rawValue) { g in
                optionCard(
                    title: g.label,
                    subtitle: "",
                    icon: "person",
                    isSelected: data.gender == g
                ) {
                    data.gender = g
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    // this is the last step or second to last
                    step += 1
                }
            } label: {
                Text("skip")
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
            }
        }
    }

    // MARK: - Step 10: Injury

    private var injuryStep: some View {
        VStack(spacing: 16) {
            questionTitle("anything we should\nknow about?")

            Text("injuries, limitations, pain — optional")
                .font(DoodleTheme.monoSmall)
                .foregroundStyle(DoodleTheme.dim)

            TextField("bad knee, shoulder pain...", text: $data.injury, axis: .vertical)
                .font(DoodleTheme.mono)
                .foregroundStyle(DoodleTheme.fg)
                .padding(12)
                .background(DoodleTheme.surface)
                .cornerRadius(8)
                .lineLimit(3...6)

            Button {
                data.injury = ""
                onComplete(data)
            } label: {
                Text("nope, all good")
                    .font(DoodleTheme.mono)
                    .foregroundStyle(DoodleTheme.green)
            }
        }
    }

    // MARK: - Shared Components

    private func questionTitle(_ text: String) -> some View {
        Text(text)
            .font(.custom("Menlo-Bold", size: 22))
            .foregroundStyle(DoodleTheme.fg)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private func optionCard(title: String, subtitle: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? DoodleTheme.bg : DoodleTheme.fg)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(isSelected ? DoodleTheme.bg : DoodleTheme.fg)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(isSelected ? DoodleTheme.bg.opacity(0.7) : DoodleTheme.dim)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DoodleTheme.bg)
                }
            }
            .padding(14)
            .background(isSelected ? DoodleTheme.green : DoodleTheme.surface)
            .cornerRadius(10)
        }
    }
}
