import SwiftUI

enum DoodleTheme {
    // MARK: - Dark Terminal Base
    static let background = Color(hex: "1A1B2E")
    static let cardBackground = Color(hex: "232540")
    static let cardBackgroundLight = Color(hex: "2A2D4A")
    static let ink = Color(hex: "E8E8F0")
    static let inkLight = Color(hex: "8888AA")
    static let inkDim = Color(hex: "555577")

    // MARK: - Colorful Accents (gender neutral)
    static let accent = Color(hex: "FF6B9D")      // pink
    static let orange = Color(hex: "FFA34D")       // orange
    static let blue = Color(hex: "6BC5F0")         // baby blue
    static let green = Color(hex: "7DD87D")        // green
    static let purple = Color(hex: "B48EF0")       // lavender
    static let yellow = Color(hex: "FFD95C")       // warm yellow
    static let red = Color(hex: "FF6B6B")          // soft red

    // MARK: - Rotating Title Colors
    static let titleColors: [Color] = [accent, orange, blue, green, purple, yellow]

    static func titleColor(for index: Int) -> Color {
        titleColors[abs(index) % titleColors.count]
    }

    static func tagColor(for tag: String) -> Color {
        let hash = abs(tag.hashValue)
        return titleColors[hash % titleColors.count]
    }

    // MARK: - Fonts
    static func handwritten(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func title() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    static func body() -> Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }

    static func caption() -> Font {
        .system(size: 13, weight: .medium, design: .rounded)
    }

    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
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

// MARK: - Glow Card Modifier
struct DoodleCard: ViewModifier {
    var glowColor: Color = DoodleTheme.accent.opacity(0.15)

    func body(content: Content) -> some View {
        content
            .padding()
            .background(DoodleTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DoodleTheme.inkDim.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: glowColor, radius: 8, x: 0, y: 4)
    }
}

struct GlowCard: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .padding()
            .background(DoodleTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func doodleCard() -> some View {
        modifier(DoodleCard())
    }

    func glowCard(color: Color) -> some View {
        modifier(GlowCard(color: color))
    }
}

// MARK: - Colored Section Header
struct ColoredHeader: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color = DoodleTheme.accent) {
        self.text = text
        self.color = color
    }

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3, height: 16)
            Text(text)
                .font(DoodleTheme.handwritten(13))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let tag: String
    var isSelected: Bool = false

    var color: Color { DoodleTheme.tagColor(for: tag) }

    var body: some View {
        Text("#\(tag)")
            .font(DoodleTheme.mono(12))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isSelected ? color.opacity(0.25) : color.opacity(0.1))
            .foregroundStyle(color)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color.opacity(0.5) : .clear, lineWidth: 1)
            )
    }
}
