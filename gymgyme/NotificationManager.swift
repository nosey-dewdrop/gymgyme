import UserNotifications
import SwiftData

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func scheduleInactivityReminder(lastWorkoutDate: Date?) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["inactivity"])

        let content = UNMutableNotificationContent()
        content.title = "gymgyme"
        content.body = "5 gun oldu! Spora gitmek istemez misin?"
        content.sound = .default

        let triggerDate: Date
        if let last = lastWorkoutDate {
            triggerDate = Calendar.current.date(byAdding: .day, value: 5, to: last) ?? Date()
        } else {
            triggerDate = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        }

        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "inactivity", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
