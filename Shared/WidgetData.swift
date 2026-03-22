import Foundation

struct WidgetStreakData: Codable {
    let workoutDays: [String] // ISO date strings
    let updatedAt: Date
}

struct WidgetProgramData: Codable {
    let programName: String
    let exerciseNames: [String]
    let goal: String
}

struct WidgetSharedData: Codable {
    let streak: WidgetStreakData
    let activeProgram: WidgetProgramData?
}

enum WidgetDataStore {
    static let suiteName = "group.com.damla.gymgyme"
    static let key = "widgetData"

    static func save(_ data: WidgetSharedData) {
        guard let suite = UserDefaults(suiteName: suiteName),
              let encoded = try? JSONEncoder().encode(data) else { return }
        suite.set(encoded, forKey: key)
    }

    static func load() -> WidgetSharedData? {
        guard let suite = UserDefaults(suiteName: suiteName),
              let data = suite.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSharedData.self, from: data)
    }
}
