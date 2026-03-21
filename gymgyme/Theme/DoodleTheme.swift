import SwiftUI

enum DoodleTheme {
    static let bg = Color(hex: "1E1E2E")
    static let fg = Color(hex: "CDD6F4")
    static let dim = Color(hex: "585B70")
    static let surface = Color(hex: "252536")

    static let pink = Color(hex: "F5C2E7")
    static let orange = Color(hex: "FAB387")
    static let blue = Color(hex: "89B4FA")
    static let green = Color(hex: "A6E3A1")
    static let purple = Color(hex: "CBA6F7")
    static let yellow = Color(hex: "F9E2AF")
    static let red = Color(hex: "F38BA8")
    static let teal = Color(hex: "94E2D5")

    static let titleColors: [Color] = [pink, orange, blue, green, purple, yellow, teal]

    static func color(for index: Int) -> Color {
        titleColors[abs(index) % titleColors.count]
    }

    static func color(for text: String) -> Color {
        titleColors[abs(text.hashValue) % titleColors.count]
    }

    static let mono: Font = .system(size: 14, weight: .regular, design: .monospaced)
    static let monoSmall: Font = .system(size: 12, weight: .regular, design: .monospaced)
    static let monoBold: Font = .system(size: 14, weight: .bold, design: .monospaced)
    static let monoTitle: Font = .system(size: 18, weight: .bold, design: .monospaced)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

// keep these for backward compat but simplified
struct DoodleCard: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

struct GlowCard: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func doodleCard() -> some View { modifier(DoodleCard()) }
    func glowCard(color: Color) -> some View { modifier(GlowCard(color: color)) }
}

struct TagChip: View {
    let tag: String
    var isSelected: Bool = false

    var body: some View {
        Text("#\(tag)")
            .font(DoodleTheme.monoSmall)
            .foregroundStyle(isSelected ? DoodleTheme.bg : DoodleTheme.color(for: tag))
            .padding(.horizontal, isSelected ? 6 : 0)
            .padding(.vertical, isSelected ? 2 : 0)
            .background(isSelected ? DoodleTheme.color(for: tag) : .clear)
            .cornerRadius(4)
    }
}

struct ColoredHeader: View {
    let text: String
    let color: Color
    init(_ text: String, color: Color = DoodleTheme.pink) {
        self.text = text
        self.color = color
    }
    var body: some View {
        Text(text)
            .font(DoodleTheme.monoBold)
            .foregroundStyle(color)
    }
}
