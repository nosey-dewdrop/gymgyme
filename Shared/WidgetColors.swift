import SwiftUI

enum WidgetColors {
    static let bg = Color(widgetHex: "1E1E2E")
    static let fg = Color(widgetHex: "CDD6F4")
    static let dim = Color(widgetHex: "585B70")
    static let green = Color(widgetHex: "A6E3A1")
    static let orange = Color(widgetHex: "FAB387")
    static let pink = Color(widgetHex: "F5C2E7")
    static let blue = Color(widgetHex: "89B4FA")
    static let purple = Color(widgetHex: "CBA6F7")
    static let yellow = Color(widgetHex: "F9E2AF")
    static let teal = Color(widgetHex: "94E2D5")

    static let mono: Font = .system(size: 11, weight: .regular, design: .monospaced)
    static let monoSmall: Font = .system(size: 9, weight: .regular, design: .monospaced)
    static let monoBold: Font = .system(size: 11, weight: .bold, design: .monospaced)
    static let monoTitle: Font = .system(size: 14, weight: .bold, design: .monospaced)
}

extension Color {
    init(widgetHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
