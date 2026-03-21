import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String
    var muscleGroup: MuscleGroup
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet] = []

    init(name: String, muscleGroup: MuscleGroup) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.createdAt = Date()
    }
}
