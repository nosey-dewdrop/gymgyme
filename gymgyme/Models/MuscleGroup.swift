import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case legs
    case core
    case glutes

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .chest: "figure.arms.open"
        case .back: "figure.walk"
        case .shoulders: "figure.boxing"
        case .biceps: "figure.strengthtraining.traditional"
        case .triceps: "figure.strengthtraining.functional"
        case .legs: "figure.run"
        case .core: "figure.core.training"
        case .glutes: "figure.step.training"
        }
    }
}
