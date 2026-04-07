import SwiftUI

struct SunCycleCard: View {
    let sunrise: Date
    let sunset: Date
    let isNight: Bool

    private var currentProgress: Double {
        let now = Date()
        let total = sunset.timeIntervalSince(sunrise)
        guard total > 0 else { return isNight ? 0 : 1 }
        return min(max(now.timeIntervalSince(sunrise) / total, 0), 1)
    }

    private var timeUntilNextEventText: String {
        let now = Date()

        if now < sunrise {
            return String(localized: "Sunrise in %@", defaultValue: "Sunrise in %@")
                .replacingOccurrences(of: "%@", with: timeString(from: sunrise.timeIntervalSince(now)))
        } else if now < sunset {
            return String(localized: "Sunset in %@", defaultValue: "Sunset in %@")
                .replacingOccurrences(of: "%@", with: timeString(from: sunset.timeIntervalSince(now)))
        } else {
            let nextSunrise = Calendar.current.date(byAdding: .day, value: 1, to: sunrise) ?? sunrise
            return String(localized: "Sunrise in %@", defaultValue: "Sunrise in %@")
                .replacingOccurrences(of: "%@", with: timeString(from: nextSunrise.timeIntervalSince(now)))
        }
    }

    private func timeString(from interval: TimeInterval) -> String {
        let totalMinutes = max(Int(interval / 60), 0)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(String(localized: "Sunrise & Sunset"), systemImage: "sun.horizon.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Sunrise"))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                        Text(sunrise.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(localized: "Sunset"))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                        Text(sunset.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.14))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.yellow.opacity(0.95), Color.orange.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geometry.size.width * currentProgress, 12))
                    }
                }
                .frame(height: 10)

                Text(timeUntilNextEventText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: HomeView.UI.secondaryCardCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: HomeView.UI.secondaryCardCornerRadius, style: .continuous)
                        .fill(isNight ? Color.white.opacity(0.035) : Color.white.opacity(0.045))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: HomeView.UI.secondaryCardCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(isNight ? 0.10 : 0.12), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(isNight ? 0.16 : 0.10), radius: 14, x: 0, y: 8)
    }
}
