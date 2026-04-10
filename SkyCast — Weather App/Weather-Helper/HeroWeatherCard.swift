import SwiftUI

struct HeroWeatherCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let weather: WeatherData
    let isNight: Bool
    let isExpanded: Bool
    let prefersExtraContrast: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: HomeView.UI.heroCardDetailSpacing) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Now")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Spacer()

                    Image(systemName: "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.92))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .scaleEffect(isExpanded ? 1.06 : 1)
                }

                Image(systemName: isNight ? weather.current.nightSymbolName : weather.current.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 124, height: 124)
                    .shadow(color: .white.opacity(0.18), radius: 18, x: 0, y: 0)

                Text(weather.current.temperatureText)
                    .font(.system(size: 68, weight: .semibold))
                    .foregroundStyle(.white)

                Text(weather.current.summary)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .opacity(colorScheme == .dark ? HomeView.UI.secondaryTextOpacityDark : HomeView.UI.secondaryTextOpacityLight)

                Text("H: \(weather.todayHighText)   L: \(weather.todayLowText)")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.92))

                if isExpanded {
                    VStack(spacing: HomeView.UI.heroCardDetailSpacing) {
                        Divider()
                            .overlay(.white.opacity(0.14))
                            .padding(.top, 4)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HomeView.UI.heroDetailGridSpacing) {
                            HeroWeatherDetailItem(title: "Feels Like", value: weather.current.apparentTemperatureText, systemImage: "thermometer.medium", prefersExtraContrast: prefersExtraContrast)

                            HeroWeatherDetailItem(title: "Wind", value: weather.current.windSpeedText, systemImage: "wind", prefersExtraContrast: prefersExtraContrast)

                            HeroWeatherDetailItem(title: "Humidity", value: weather.current.humidityText, systemImage: "drop.fill", prefersExtraContrast: prefersExtraContrast)

                            HeroWeatherDetailItem(title: "Rain Chance", value: weather.current.rainDescriptionText, systemImage: "cloud.rain.fill", prefersExtraContrast: prefersExtraContrast)

                            HeroWeatherDetailItem(title: "Wind Dir", value: weather.current.windDirectionText, systemImage: "location.north.line", prefersExtraContrast: prefersExtraContrast)

                            HeroWeatherDetailItem(title: "Pressure", value: weather.current.pressureText, systemImage: "gauge", prefersExtraContrast: prefersExtraContrast)

                            HeroWeatherDetailItem(title: "UV Index", value: weather.current.uvIndexText, systemImage: "sun.max.fill", prefersExtraContrast: prefersExtraContrast)

                            HeroWeatherDetailItem(title: "Air Quality", value: weather.current.airQualityText, systemImage: "aqi.medium", prefersExtraContrast: prefersExtraContrast)
                        }
                        .padding(.top, 10)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, isExpanded ? 8 : 0)
            .padding(.vertical, HomeView.UI.heroCardInnerPadding)
            .padding(.horizontal, HomeView.UI.heroCardInnerPadding)
            .background {
                RoundedRectangle(cornerRadius: HomeView.UI.heroCardCornerRadius, style: .continuous)
                    .fill(Color.black.opacity(prefersExtraContrast ? 0.06 : 0))
            }
            .glassCard(cornerRadius: HomeView.UI.heroCardCornerRadius, extraDarkTint: isNight ? 0.04 : 0)
            .scaleEffect(isExpanded ? 1.01 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct HeroWeatherDetailItem: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String
    let prefersExtraContrast: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: HomeView.UI.heroDetailRowSpacing) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(prefersExtraContrast ? 0.96 : 0.72))

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(prefersExtraContrast ? 0.10 : 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(prefersExtraContrast ? 0.14 : 0.10), lineWidth: 1)
                )
        }
    }
}
