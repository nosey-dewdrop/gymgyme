import SwiftUI

enum DoodleTheme {
    // MARK: - Colors
    static let background = Color(hex: "FFFEF5")
    static let cardBackground = Color(hex: "FFF9E6")
    static let ink = Color(hex: "2C2C2C")
    static let inkLight = Color(hex: "8C8C8C")
    static let accent = Color(hex: "FF6B35")
    static let green = Color(hex: "4CAF50")
    static let yellow = Color(hex: "FFC107")
    static let red = Color(hex: "F44336")

    // MARK: - Fonts
    static func handwritten(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func title() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    static func body() -> Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }

    static func caption() -> Font {
        .system(size: 13, weight: .regular, design: .rounded)
    }
}

// MARK: - Color hex init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

// MARK: - Doodle card modifier
struct DoodleCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(DoodleTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DoodleTheme.ink.opacity(0.15), lineWidth: 1.5)
            )
    }
}

extension View {
    func doodleCard() -> some View {
        modifier(DoodleCard())
    }
}
