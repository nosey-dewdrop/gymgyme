import SwiftUI

struct TypewriterTitle: View {
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: Double = 10
    @State private var sparkleOpacity: Double = 0
    @State private var sparkleScale: Double = 0.3

    var body: some View {
        HStack(spacing: 4) {
            Image("pixel_title")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(height: 36)
                .opacity(titleOpacity)
                .offset(y: titleOffset)

            Image("pixel_sparkle")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .opacity(sparkleOpacity)
                .scaleEffect(sparkleScale)
        }
        .onAppear { animate() }
    }

    private func animate() {
        titleOpacity = 0
        titleOffset = 10
        sparkleOpacity = 0
        sparkleScale = 0.3

        // title slides in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            titleOpacity = 1
            titleOffset = 0
        }

        // sparkle pops after title
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                sparkleOpacity = 1
                sparkleScale = 1.4
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.2)) {
                sparkleScale = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.6)) {
                sparkleOpacity = 0
            }
        }
    }
}

#Preview {
    TypewriterTitle()
        .padding()
        .background(DoodleTheme.bg)
}
