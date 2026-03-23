import Foundation
import SwiftData

@Model
final class Meal {
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var timestamp: Date
    var notes: String

    init(name: String, calories: Int = 0, notes: String = "") {
        self.name = name
        self.calories = calories
        self.protein = 0
        self.carbs = 0
        self.fat = 0
        self.notes = notes
        self.timestamp = Date()
    }
}
