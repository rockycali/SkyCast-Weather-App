import SwiftUI

// MARK: - Glass Card Modifier
struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat
    let extraDarkTint: Double
    let prefersExtraContrast: Bool
    let isBrightDaylightWeather: Bool
    let shadowOpacityMultiplier: Double

    func body(content: Content) -> some View {
        let shouldBoostReadability = prefersExtraContrast || isBrightDaylightWeather
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                ZStack {
                    shape
                        .fill(.ultraThinMaterial)

                    shape
                        .fill(
                            colorScheme == .dark
                            ? Color.black.opacity(shouldBoostReadability ? 0.35 : 0.28)
                            : Color.white.opacity(shouldBoostReadability ? 0.18 : 0.10)
                        )

                    shape
                        .fill(
                            Color.black.opacity(
                                shouldBoostReadability
                                ? max(extraDarkTint, 0.18)
                                : extraDarkTint
                            )
                        )
                }
            }
            .shadow(
                color: Color.black.opacity(
                    (
                        shouldBoostReadability
                        ? (colorScheme == .dark ? 0.30 : 0.12)
                        : (colorScheme == .dark ? 0.24 : 0.07)
                    ) * shadowOpacityMultiplier
                ),
                radius: shouldBoostReadability ? 18 : 14,
                x: 0,
                y: 8
            )
            .overlay {
                shape
                    .stroke(
                        Color.white.opacity(
                            shouldBoostReadability
                            ? (colorScheme == .dark ? 0.18 : 0.34)
                            : (colorScheme == .dark ? 0.14 : 0.28)
                        ),
                        lineWidth: 1
                    )
            }
    }
}

// MARK: - View Extension
extension View {
    func glassCard(
        cornerRadius: CGFloat = 22,
        extraDarkTint: Double = 0,
        prefersExtraContrast: Bool = false,
        isBrightDaylightWeather: Bool = false,
        shadowOpacityMultiplier: Double = 1
    ) -> some View {
        modifier(
            GlassCardModifier(
                cornerRadius: cornerRadius,
                extraDarkTint: extraDarkTint,
                prefersExtraContrast: prefersExtraContrast,
                isBrightDaylightWeather: isBrightDaylightWeather,
                shadowOpacityMultiplier: shadowOpacityMultiplier
            )
        )
    }
}
