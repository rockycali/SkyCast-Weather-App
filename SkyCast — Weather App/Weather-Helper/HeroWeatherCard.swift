import SwiftUI

struct HeroWeatherCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let weather: WeatherData
    let isNight: Bool
    let isExpanded: Bool
    let prefersExtraContrast: Bool
    let onTap: () -> Void

    private var usesStrongSunnyContrast: Bool {
        prefersExtraContrast && !isNight
    }

    private var usesSoftContrast: Bool {
        prefersExtraContrast && isNight
    }

    private var cardBaseTintOpacity: Double {
        if usesStrongSunnyContrast { return 0.10 }
        if usesSoftContrast { return 0.03 }
        return 0
    }

    private var cardGradientTopOpacity: Double {
        if usesStrongSunnyContrast { return 0.16 }
        if usesSoftContrast { return 0.05 }
        return 0
    }

    private var cardGradientMidOpacity: Double {
        if usesStrongSunnyContrast { return 0.07 }
        if usesSoftContrast { return 0.02 }
        return 0
    }

    private var glassExtraDarkTint: Double {
        if usesStrongSunnyContrast { return 0.08 }
        if usesSoftContrast { return 0.03 }
        return isNight ? 0.04 : 0
    }

    private var cardStrokeOpacity: Double {
        if usesStrongSunnyContrast { return 0.18 }
        if usesSoftContrast { return 0.12 }
        return 0.10
    }

    private var cardShadowOpacity: Double {
        if usesStrongSunnyContrast { return 0.14 }
        if usesSoftContrast { return 0.08 }
        return 0.06
    }

    private var cardShadowRadius: CGFloat {
        if usesStrongSunnyContrast { return 16 }
        if usesSoftContrast { return 12 }
        return 10
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: HomeView.UI.heroCardDetailSpacing) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Now")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(usesStrongSunnyContrast ? 0.88 : (usesSoftContrast ? 0.80 : 0.72)))
                            .shadow(color: .black.opacity(usesStrongSunnyContrast ? 0.22 : (usesSoftContrast ? 0.14 : 0.10)), radius: usesStrongSunnyContrast ? 2 : 1, x: 0, y: 1)
                    }

                    Spacer()

                    Image(systemName: "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(usesStrongSunnyContrast ? 1.0 : (usesSoftContrast ? 0.96 : 0.92)))
                        .shadow(color: .black.opacity(usesStrongSunnyContrast ? 0.20 : (usesSoftContrast ? 0.12 : 0.08)), radius: usesStrongSunnyContrast ? 2 : 1, x: 0, y: 1)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .scaleEffect(isExpanded ? 1.06 : 1)
                }

                Image(systemName: isNight ? weather.current.nightSymbolName : weather.current.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 124, height: 124)
                    .shadow(color: .white.opacity(0.18), radius: 18, x: 0, y: 0)
                    .shadow(color: .black.opacity(usesStrongSunnyContrast ? 0.18 : (usesSoftContrast ? 0.10 : 0.08)), radius: usesStrongSunnyContrast ? 8 : (usesSoftContrast ? 5 : 4), x: 0, y: 4)

                Text(weather.current.temperatureText)
                    .font(.system(size: 68, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(usesStrongSunnyContrast ? 0.30 : (usesSoftContrast ? 0.18 : 0.14)), radius: usesStrongSunnyContrast ? 4 : (usesSoftContrast ? 3 : 2), x: 0, y: 2)

                Text(weather.current.summary)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .opacity(usesStrongSunnyContrast ? 0.96 : (usesSoftContrast ? 0.90 : (colorScheme == .dark ? HomeView.UI.secondaryTextOpacityDark : HomeView.UI.secondaryTextOpacityLight)))
                    .shadow(color: .black.opacity(usesStrongSunnyContrast ? 0.22 : (usesSoftContrast ? 0.14 : 0.10)), radius: usesStrongSunnyContrast ? 3 : (usesSoftContrast ? 2 : 1), x: 0, y: 1)

                Text("H: \(weather.todayHighText)   L: \(weather.todayLowText)")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.white.opacity(usesStrongSunnyContrast ? 0.98 : (usesSoftContrast ? 0.94 : 0.92)))
                    .shadow(color: .black.opacity(usesStrongSunnyContrast ? 0.18 : (usesSoftContrast ? 0.10 : 0.08)), radius: usesStrongSunnyContrast ? 2 : 1, x: 0, y: 1)

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
                    .fill(Color.black.opacity(cardBaseTintOpacity))
            }
            .overlay {
                RoundedRectangle(cornerRadius: HomeView.UI.heroCardCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(cardGradientTopOpacity),
                                Color.black.opacity(cardGradientMidOpacity),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .glassCard(cornerRadius: HomeView.UI.heroCardCornerRadius, extraDarkTint: glassExtraDarkTint)
            .overlay {
                RoundedRectangle(cornerRadius: HomeView.UI.heroCardCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(cardStrokeOpacity), lineWidth: 1)
            }
            .shadow(color: .black.opacity(cardShadowOpacity), radius: cardShadowRadius, x: 0, y: 8)
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

    @Environment(\.colorScheme) private var colorScheme

    private var tileFillOpacity: Double {
        if colorScheme == .dark {
            return prefersExtraContrast ? 0.14 : 0.09
        }
        return prefersExtraContrast ? 0.12 : 0.07
    }

    private var tileStrokeOpacity: Double {
        if colorScheme == .dark {
            return prefersExtraContrast ? 0.20 : 0.12
        }
        return prefersExtraContrast ? 0.18 : 0.10
    }

    private var tileShadowOpacity: Double {
        if colorScheme == .dark {
            return prefersExtraContrast ? 0.06 : 0.02
        }
        return prefersExtraContrast ? 0.08 : 0.00
    }

    private var tileShadowRadius: CGFloat {
        if colorScheme == .dark {
            return prefersExtraContrast ? 4 : 2
        }
        return prefersExtraContrast ? 6 : 0
    }

    private var labelOpacity: Double {
        prefersExtraContrast ? 0.98 : 0.78
    }

    private var labelShadowOpacity: Double {
        prefersExtraContrast ? 0.18 : 0.08
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HomeView.UI.heroDetailRowSpacing) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(labelOpacity))
                .shadow(color: .black.opacity(labelShadowOpacity), radius: prefersExtraContrast ? 2 : 1, x: 0, y: 1)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(labelShadowOpacity), radius: prefersExtraContrast ? 2 : 1, x: 0, y: 1)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(tileFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(tileStrokeOpacity), lineWidth: 1)
                )
                .shadow(color: .black.opacity(tileShadowOpacity), radius: tileShadowRadius, x: 0, y: 3)
        }
    }
}
