import Foundation
import SwiftData

@Model
final class Meal {
    var name: String
    var calories: Int
    var timestamp: Date
    var notes: String

    init(name: String, calories: Int = 0, notes: String = "") {
        self.name = name
        self.calories = calories
        self.notes = notes
        self.timestamp = Date()
    }
}
