import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String
    var tag: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet] = []

    init(name: String, tag: String) {
        self.name = name
        self.tag = tag.lowercased().trimmingCharacters(in: .whitespaces)
        self.createdAt = Date()
    }
}
