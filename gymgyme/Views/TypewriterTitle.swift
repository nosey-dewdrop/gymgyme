import SwiftUI

struct TypewriterTitle: View {
    @State private var appeared = false

    private var letters: [(Character, Color)] {
        let colors = DoodleTheme.titleColors
        return Array(zip("gymgyme", colors)).map { ($0.0, $0.1) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(letters.enumerated()), id: \.offset) { i, pair in
                Text(String(pair.0))
                    .font(.custom("Menlo-Bold", size: 28))
                    .foregroundStyle(pair.1)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 6)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.7)
                            .delay(Double(i) * 0.05),
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
