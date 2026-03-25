import SwiftUI

struct TypewriterTitle: View {
    @State private var appeared = false

    private static let letters: [(offset: Int, char: String, color: Color)] = {
        let colors = DoodleTheme.titleColors
        return "gymgyme".enumerated().map { (offset: $0.offset, char: String($0.element), color: colors[$0.offset % colors.count]) }
    }()

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Self.letters, id: \.offset) { item in
                Text(item.char)
                    .font(.custom("Menlo-Bold", size: 28))
                    .foregroundStyle(item.color)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 6)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.7)
                            .delay(Double(item.offset) * 0.05),
                        value: appeared
                    )
            }
        }
        .onAppear { appeared = true }
    }
}

#Preview {
    TypewriterTitle()
        .padding()
        .background(DoodleTheme.bg)
}
