import Foundation
import SwiftData

@Model
final class UserProfile {
    var heightCm: Double
    var weightKg: Double
    var useLbs: Bool

    var bmi: Double {
        guard heightCm > 0 else { return 0 }
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }

    init(heightCm: Double = 0, weightKg: Double = 0) {
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.useLbs = false
    }
}
