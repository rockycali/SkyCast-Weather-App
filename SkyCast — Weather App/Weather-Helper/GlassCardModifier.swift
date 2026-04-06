import SwiftUI

// MARK: - Glass Card Modifier
struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat
    let extraDarkTint: Double

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                ZStack {
                    shape
                        .fill(.ultraThinMaterial)

                    shape
                        .fill(colorScheme == .dark ? Color.black.opacity(0.28) : Color.white.opacity(0.10))

                    shape
                        .fill(Color.black.opacity(extraDarkTint))
                }
            }
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.07), radius: 14, x: 0, y: 8)
            .overlay {
                shape
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.28), lineWidth: 1)
            }
    }
}

// MARK: - View Extension
extension View {
    func glassCard(cornerRadius: CGFloat = 22, extraDarkTint: Double = 0) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, extraDarkTint: extraDarkTint))
    }
}
