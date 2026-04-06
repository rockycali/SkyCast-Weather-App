import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("temperatureUnit") private var temperatureUnit = "C"
    @ObservedObject var viewModel: WeatherViewModel
    @State private var showErrorAlert = false
    @State private var animateBackgroundGradient = false
    @State private var isHeroCardExpanded = false
    private let heroCardScrollID = "heroWeatherCard"

    enum UI {
        static let pageSpacing: CGFloat = 16
        static let sectionSpacing: CGFloat = 14
        static let gridSpacing: CGFloat = 10
        static let rowSpacing: CGFloat = 10
        static let contentHorizontalPadding: CGFloat = 20
        static let contentVerticalPadding: CGFloat = 16
        static let fieldHorizontalPadding: CGFloat = 14
        static let buttonHeight: CGFloat = 50
        static let hourlyCardWidth: CGFloat = 84
        static let hourlyCardHeight: CGFloat = 0
        static let hourlyCardSpacing: CGFloat = 12
        static let hourlySectionSideInset: CGFloat = 6
        static let hourlySectionHorizontalBreakout: CGFloat = -8
        static let inputCornerRadius: CGFloat = 16
        static let secondaryCardCornerRadius: CGFloat = 20
        static let cardCornerRadius: CGFloat = 22
        static let heroCardCornerRadius: CGFloat = 28
        static let subtleTextOpacity: CGFloat = 0.82
        static let secondaryTextOpacityDark: CGFloat = 0.94
        static let secondaryTextOpacityLight: CGFloat = 0.96
        static let textFieldBackgroundOpacity: CGFloat = 0.16
        static let secondaryButtonBackgroundOpacity: CGFloat = 0.14
        static let fieldBorderOpacityDark: CGFloat = 0.22
        static let fieldBorderOpacityLight: CGFloat = 0.12
        static let buttonBorderOpacity: CGFloat = 0.2
        static let backgroundAnimationDuration: Double = 24
        static let backgroundStartPointX: CGFloat = 0.14
        static let backgroundEndPointX: CGFloat = 0.86
        static let backgroundAnimatedOffset: CGFloat = 0.10
        static let backgroundSecondaryLayerOpacity: CGFloat = 0.18
        static let backgroundSecondaryAnimationDuration: Double = 32
        static let heroCardInnerPadding: CGFloat = 18
        static let heroCardDetailSpacing: CGFloat = 12
        static let heroDetailGridSpacing: CGFloat = 14
        static let heroDetailRowSpacing: CGFloat = 2
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ZStack {
                    backgroundGradient
                        .ignoresSafeArea()

                    backgroundAccentGradient
                        .opacity(UI.backgroundSecondaryLayerOpacity)
                        .blur(radius: 60)
                        .ignoresSafeArea()
                }
                .animation(.easeInOut(duration: 0.6), value: viewModel.weather?.current.weatherCode ?? -1)
                .onAppear {
                    guard !animateBackgroundGradient else { return }
                    withAnimation(
                        .easeInOut(duration: UI.backgroundAnimationDuration)
                        .repeatForever(autoreverses: true)
                    ) {
                        animateBackgroundGradient = true
                    }
                }

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: UI.pageSpacing) {
                            if viewModel.isOffline {
                                Text("Offline mode - showing last data")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                            headerSection
                            currentWeatherSection
                            metricsSection
                            sunCycleSection
                            hourlySection
                            dailySection
                        }
                        .padding(.horizontal, UI.contentHorizontalPadding)
                        .padding(.top, UI.contentVerticalPadding)
                        .padding(.bottom, 236)
                        .animation(.easeInOut(duration: 0.4), value: viewModel.weather?.current.weatherCode ?? -1)
                        .id(temperatureUnit)
                    }
                    .refreshable {
                        print("🔄 Pull-to-refresh triggered")
                        await viewModel.refreshCurrentSource()
                    }
                    .onChange(of: isHeroCardExpanded) { _, isExpanded in
                        guard isExpanded else { return }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo(heroCardScrollID, anchor: .top)
                            }
                        }
                    }
                }

                VStack {
                    Spacer()

                    LinearGradient(
                        colors: [
                            Color.clear,
                            backgroundGradientColors.last?.opacity(0.35) ?? Color.clear,
                            backgroundGradientColors.last?.opacity(0.55) ?? Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 72)
                    .allowsHitTesting(false)
                }
                .ignoresSafeArea(edges: .bottom)

            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadInitialWeatherIfNeeded()
            }
            .alert("ClimaFlow", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? String(localized: "Unknown error"))
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                // Avoid alert over cached offline data (location/search may still report network errors).
                let hasCachedOfflineWeather = viewModel.isOffline && viewModel.weather != nil
                showErrorAlert = newValue != nil && !hasCachedOfflineWeather
            }
            .onChange(of: viewModel.isOffline) { _, _ in
                if viewModel.isOffline, viewModel.weather != nil, viewModel.errorMessage != nil {
                    showErrorAlert = false
                }
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: backgroundGradientColors,
            startPoint: UnitPoint(
                x: animateBackgroundGradient
                    ? UI.backgroundStartPointX + UI.backgroundAnimatedOffset
                    : UI.backgroundStartPointX,
                y: animateBackgroundGradient ? 0.10 : 0
            ),
            endPoint: UnitPoint(
                x: animateBackgroundGradient
                    ? UI.backgroundEndPointX - UI.backgroundAnimatedOffset
                    : UI.backgroundEndPointX,
                y: animateBackgroundGradient ? 0.90 : 1
            )
        )
    }

    private var backgroundAccentGradient: LinearGradient {
        LinearGradient(
            colors: backgroundAccentColors,
            startPoint: UnitPoint(
                x: animateBackgroundGradient ? 0.88 : 0.18,
                y: animateBackgroundGradient ? 0.18 : 0.82
            ),
            endPoint: UnitPoint(
                x: animateBackgroundGradient ? 0.12 : 0.82,
                y: animateBackgroundGradient ? 0.82 : 0.18
            )
        )
    }

    private var backgroundGradientColors: [Color] {
        guard let weather = viewModel.weather else {
            return [
                Color(red: 0.18, green: 0.30, blue: 0.70),
                Color(red: 0.32, green: 0.20, blue: 0.58)
            ]
        }

        if viewModel.isNight {
            switch weather.current.weatherCode {
            case 0:
                return [
                    Color(red: 0.02, green: 0.05, blue: 0.14),
                    Color(red: 0.08, green: 0.13, blue: 0.28)
                ]
            case 1...3:
                return [
                    Color(red: 0.05, green: 0.09, blue: 0.18),
                    Color(red: 0.11, green: 0.16, blue: 0.30)
                ]
            case 45, 48:
                return [
                    Color(red: 0.10, green: 0.12, blue: 0.18),
                    Color(red: 0.18, green: 0.20, blue: 0.26)
                ]
            case 51...67:
                return [
                    Color(red: 0.04, green: 0.08, blue: 0.18),
                    Color(red: 0.09, green: 0.14, blue: 0.24)
                ]
            case 71...77:
                return [
                    Color(red: 0.07, green: 0.11, blue: 0.20),
                    Color(red: 0.15, green: 0.18, blue: 0.28)
                ]
            case 95...99:
                return [
                    Color(red: 0.03, green: 0.03, blue: 0.08),
                    Color(red: 0.12, green: 0.08, blue: 0.20)
                ]
            default:
                return [
                    Color(red: 0.03, green: 0.07, blue: 0.15),
                    Color(red: 0.09, green: 0.14, blue: 0.26)
                ]
            }
        }

        switch weather.current.weatherCode {
        case 0:
            return [
                Color(red: 0.22, green: 0.52, blue: 0.96),
                Color(red: 0.96, green: 0.78, blue: 0.36)
            ]
        case 1...3:
            return [
                Color(red: 0.52, green: 0.64, blue: 0.82),
                Color(red: 0.26, green: 0.40, blue: 0.68)
            ]
        case 45, 48:
            return [
                Color(red: 0.70, green: 0.75, blue: 0.82),
                Color(red: 0.48, green: 0.54, blue: 0.62)
            ]
        case 51...67:
            return [
                Color(red: 0.20, green: 0.42, blue: 0.76),
                Color(red: 0.32, green: 0.38, blue: 0.50)
            ]
        case 71...77:
            return [
                Color(red: 0.68, green: 0.80, blue: 0.96),
                Color(red: 0.36, green: 0.52, blue: 0.82)
            ]
        case 95...99:
            return [
                Color(red: 0.12, green: 0.10, blue: 0.18),
                Color(red: 0.26, green: 0.14, blue: 0.36)
            ]
        default:
            return [
                Color(red: 0.22, green: 0.42, blue: 0.82),
                Color(red: 0.30, green: 0.22, blue: 0.58)
            ]
        }
    }

    private var backgroundAccentColors: [Color] {
        guard let weather = viewModel.weather else {
            return [Color.white.opacity(0.45), Color.clear]
        }

        if viewModel.isNight {
            switch weather.current.weatherCode {
            case 0:
                return [
                    Color(red: 0.28, green: 0.40, blue: 0.78).opacity(0.46),
                    Color.clear
                ]
            case 51...67, 71...77, 95...99:
                return [
                    Color(red: 0.18, green: 0.26, blue: 0.48).opacity(0.34),
                    Color.clear
                ]
            default:
                return [
                    Color(red: 0.22, green: 0.32, blue: 0.58).opacity(0.36),
                    Color.clear
                ]
            }
        }

        switch weather.current.weatherCode {
        case 0:
            return [
                Color(red: 1.00, green: 0.96, blue: 0.72).opacity(0.55),
                Color.clear
            ]
        case 1...3:
            return [
                Color.white.opacity(0.30),
                Color.clear
            ]
        case 51...67:
            return [
                Color(red: 0.70, green: 0.82, blue: 0.98).opacity(0.26),
                Color.clear
            ]
        case 71...77:
            return [
                Color.white.opacity(0.34),
                Color.clear
            ]
        case 95...99:
            return [
                Color(red: 0.56, green: 0.42, blue: 0.80).opacity(0.22),
                Color.clear
            ]
        default:
            return [
                Color.white.opacity(0.22),
                Color.clear
            ]
        }
    }

    private var isBrightDaylightWeather: Bool {
        guard let weather = viewModel.weather else { return false }
        return !viewModel.isNight && weather.current.weatherCode == 0
    }

    private var brightCardReadabilityOpacity: Double {
        isBrightDaylightWeather ? 0.12 : 0
    }

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Current Weather")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(UI.subtleTextOpacity))

            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(UI.secondaryTextOpacityDark))

                Text(viewModel.displayName.split(separator: ",").first.map(String.init) ?? viewModel.displayName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            if let current = viewModel.weather?.current {
                Text(current.summary)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(colorScheme == .dark ? UI.secondaryTextOpacityDark : UI.secondaryTextOpacityLight))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var currentWeatherSection: some View {
        Group {
            if let weather = viewModel.weather {
                VStack(spacing: UI.heroCardDetailSpacing) {
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
                            .rotationEffect(.degrees(isHeroCardExpanded ? 180 : 0))
                            .scaleEffect(isHeroCardExpanded ? 1.06 : 1)
                    }

                    Image(systemName: viewModel.isNight ? weather.current.nightSymbolName : weather.current.symbolName)
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
                        .opacity(colorScheme == .dark ? UI.secondaryTextOpacityDark : UI.secondaryTextOpacityLight)

                    Text("H: \(weather.todayHighText)   L: \(weather.todayLowText)")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.92))

                    if isHeroCardExpanded {
                        VStack(spacing: UI.heroCardDetailSpacing) {
                            Divider()
                                .overlay(.white.opacity(0.14))
                                .padding(.top, 4)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: UI.heroDetailGridSpacing) {
                                HeroDetailItem(title: "Feels Like", value: weather.current.apparentTemperatureText, systemImage: "thermometer.medium", prefersExtraContrast: isBrightDaylightWeather)

                                HeroDetailItem(title: "Wind", value: weather.current.windSpeedText, systemImage: "wind", prefersExtraContrast: isBrightDaylightWeather)

                                HeroDetailItem(title: "Humidity", value: weather.current.humidityText, systemImage: "drop.fill", prefersExtraContrast: isBrightDaylightWeather)

                                HeroDetailItem(title: "Rain Chance", value: weather.current.rainDescriptionText, systemImage: "cloud.rain.fill", prefersExtraContrast: isBrightDaylightWeather)

                                HeroDetailItem(title: "Wind Dir", value: weather.current.windDirectionText, systemImage: "location.north.line", prefersExtraContrast: isBrightDaylightWeather)

                                HeroDetailItem(title: "Pressure", value: weather.current.pressureText, systemImage: "gauge", prefersExtraContrast: isBrightDaylightWeather)

                                HeroDetailItem(title: "UV Index", value: weather.current.uvIndexText, systemImage: "sun.max.fill", prefersExtraContrast: isBrightDaylightWeather)

                                HeroDetailItem(title: "Air Quality", value: weather.current.airQualityText, systemImage: "aqi.medium", prefersExtraContrast: isBrightDaylightWeather)
                            }
                            .padding(.top, 10)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                }
                .frame(maxWidth: .infinity)
                .padding(.top, isHeroCardExpanded ? 8 : 0)
                .padding(.vertical, UI.heroCardInnerPadding)
                .padding(.horizontal, UI.heroCardInnerPadding)
                .background {
                    RoundedRectangle(cornerRadius: UI.heroCardCornerRadius, style: .continuous)
                        .fill(.black.opacity(brightCardReadabilityOpacity))
                }
                .glassCard(cornerRadius: UI.heroCardCornerRadius)
                .scaleEffect(isHeroCardExpanded ? 1.01 : 1.0)
                .contentShape(Rectangle())
                .id(heroCardScrollID)
                .onTapGesture {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        isHeroCardExpanded.toggle()
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else if viewModel.isLoading {
                loadingCard
            }
        }
    }

    private var metricsSection: some View {
        Group {
            if let weather = viewModel.weather, !isHeroCardExpanded {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: UI.gridSpacing) {
                    WeatherMetricCard(title: "Feels Like", value: weather.current.apparentTemperatureText, systemImage: "thermometer.medium")
                    WeatherMetricCard(title: "Wind", value: weather.current.windSpeedText, systemImage: "wind")
                    WeatherMetricCard(title: "Humidity", value: weather.current.humidityText, systemImage: "drop.fill")
                    WeatherMetricCard(title: "Rain", value: weather.current.precipitationChanceText, systemImage: "cloud.rain.fill")
                }
            }
        }
    }

    private var sunCycleSection: some View {
        Group {
            if let today = viewModel.dailyForecast.first {
                VStack(alignment: .leading, spacing: UI.sectionSpacing) {
                    sectionTitle("Sunrise & Sunset")

                    SunCycleCard(
                        sunrise: today.sunrise,
                        sunset: today.sunset,
                        prefersExtraContrast: isBrightDaylightWeather
                    )
                }
                .padding(.top, 12)
            }
        }
    }

    private var hourlySection: some View {
        Group {
            if !viewModel.hourlyForecast.isEmpty {
                VStack(alignment: .leading, spacing: UI.sectionSpacing) {
                    sectionTitle("Hourly Forecast")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: UI.hourlyCardSpacing) {
                            ForEach(viewModel.hourlyForecast) { hour in
                                HourlyForecastCard(hour: hour, prefersExtraContrast: isBrightDaylightWeather)
                            }
                        }
                        .padding(.leading, UI.hourlySectionSideInset)
                        .padding(.trailing, UI.hourlySectionSideInset)
                    }
                    .padding(.horizontal, UI.hourlySectionHorizontalBreakout)
                }
            }
        }
    }

    private var dailySection: some View {
        Group {
            if !viewModel.dailyForecast.isEmpty {
                let dailyTemperatureValues = viewModel.dailyForecast.flatMap { day in
                    [day.numericMinTemperature, day.numericMaxTemperature].compactMap { $0 }
                }
                let overallMinTemperature = dailyTemperatureValues.min() ?? 0
                let overallMaxTemperature = dailyTemperatureValues.max() ?? 0

                VStack(alignment: .leading, spacing: UI.sectionSpacing) {
                    sectionTitle("5-Day Forecast")

                    VStack(spacing: UI.rowSpacing) {
                        ForEach(viewModel.dailyForecast) { day in
                            DailyForecastRow(
                                day: day,
                                overallMinTemperature: overallMinTemperature,
                                overallMaxTemperature: overallMaxTemperature,
                                prefersExtraContrast: isBrightDaylightWeather
                            )
                        }
                    }
                }
                .padding(.bottom, UI.pageSpacing)
            }
        }
    }

    private var loadingCard: some View {
        VStack(spacing: UI.gridSpacing) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)

            Text("Loading weather...")
                .foregroundStyle(.white)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .glassCard(cornerRadius: UI.heroCardCornerRadius)
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        HStack {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(colorScheme == .dark ? 0.88 : 1.0))

            Spacer()
        }
    }

}
private struct HeroDetailItem: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String
    let prefersExtraContrast: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 18, alignment: .leading)

            VStack(alignment: .leading, spacing: HomeView.UI.heroDetailRowSpacing) {
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(prefersExtraContrast ? 0.10 : 0.06))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(prefersExtraContrast ? 0.12 : 0.08), lineWidth: 1)
        }
    }
}

private struct WeatherMetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(1.0))
                    .frame(width: 18, alignment: .leading)

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(1.0))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 40, alignment: .topLeading)

            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: HomeView.UI.cardCornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.06))
        }
        .glassCard(cornerRadius: HomeView.UI.cardCornerRadius)
    }
}

private struct HourlyForecastCard: View {
    let hour: HourlyForecastItem
    let prefersExtraContrast: Bool

    private var iconSize: CGFloat {
        if hour.symbolName.contains("sun.max") || hour.symbolName.contains("cloud.sun") {
            return 29
        }
        return 28
    }

    private var iconVerticalOffset: CGFloat {
        if hour.symbolName.contains("sun.max") {
            return -0.5
        }
        return 0
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(hour.timeLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.96))

            Image(systemName: hour.symbolName)
                .symbolRenderingMode(.multicolor)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .offset(y: iconVerticalOffset)
                .shadow(color: .white.opacity(0.14), radius: 8, x: 0, y: 0)

            Text(hour.temperatureText)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(width: HomeView.UI.hourlyCardWidth)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: HomeView.UI.cardCornerRadius, style: .continuous)
                .fill(Color.black.opacity(prefersExtraContrast ? 0.06 : 0))
        }
        .glassCard(cornerRadius: HomeView.UI.cardCornerRadius)
    }
}

private struct DailyForecastRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let day: DailyForecastItem
    let overallMinTemperature: Double
    let overallMaxTemperature: Double
    let prefersExtraContrast: Bool

    private var isToday: Bool {
        day.dayLabel == String(localized: "Today")
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(day.dayLabel)
                .font(.headline.weight(isToday ? .semibold : .medium))
                .foregroundStyle(.white)
                .frame(width: 68, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Image(systemName: day.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.title3)
                .frame(width: 28)

            if let minTemperature = day.numericMinTemperature,
               let maxTemperature = day.numericMaxTemperature {
                Text(day.minText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.74))
                    .frame(width: 44, alignment: .trailing)

                TemperatureRangeBar(
                    minTemperature: minTemperature,
                    maxTemperature: maxTemperature,
                    overallMinTemperature: overallMinTemperature,
                    overallMaxTemperature: overallMaxTemperature
                )
                .frame(maxWidth: .infinity)
                .padding(.leading, 2)

                Text(day.maxText)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, alignment: .trailing)
            } else {
                Spacer(minLength: 8)

                Text(day.minText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.74))
                    .frame(width: 44, alignment: .trailing)

                Text(day.maxText)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: HomeView.UI.secondaryCardCornerRadius, style: .continuous)
                .fill(
                    isToday
                    ? Color.white.opacity(colorScheme == .dark ? 0.12 : 0.16)
                    : Color.black.opacity(prefersExtraContrast ? 0.06 : 0)
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: HomeView.UI.secondaryCardCornerRadius, style: .continuous)
                .stroke(.white.opacity(isToday ? 0.28 : (prefersExtraContrast ? 0.10 : 0)), lineWidth: 1)
        }
        .glassCard(cornerRadius: HomeView.UI.secondaryCardCornerRadius)
    }
}

private struct TemperatureRangeBar: View {
    let minTemperature: Double
    let maxTemperature: Double
    let overallMinTemperature: Double
    let overallMaxTemperature: Double

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let totalRange = max(overallMaxTemperature - overallMinTemperature, 1)
            let startRatio = (minTemperature - overallMinTemperature) / totalRange
            let endRatio = (maxTemperature - overallMinTemperature) / totalRange
            let clampedStart = min(max(startRatio, 0), 1)
            let clampedEnd = min(max(endRatio, 0), 1)
            let fillStart = trackWidth * clampedStart
            let fillWidth = max(trackWidth * (clampedEnd - clampedStart), 24)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(height: 4)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth, height: 4)
                    .offset(x: fillStart)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}
private extension CurrentWeather {
    var airQualityText: String {
        guard let aqi = airQuality else { return "--" }

        switch aqi {
        case 0...50: return "\(aqi) • Good"
        case 51...100: return "\(aqi) • Moderate"
        case 101...150: return "\(aqi) • Unhealthy (Sensitive)"
        case 151...200: return "\(aqi) • Unhealthy"
        case 201...300: return "\(aqi) • Very Unhealthy"
        default: return "\(aqi) • Hazardous"
        }
    }

    var rainDescriptionText: String {
        let numericValue = precipitationChanceText
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let value = Int(numericValue) else {
            return precipitationChanceText
        }

        switch value {
        case 0:
            return "0% • No rain"
        case 1...30:
            return "\(value)% • Slight chance"
        case 31...60:
            return "\(value)% • Possible rain"
        default:
            return "\(value)% • Likely rain"
        }
    }
}
// Helper for extracting numeric temperature values from DailyForecastItem
private extension DailyForecastItem {
    var numericMinTemperature: Double? {
        Self.numericTemperature(from: minText)
    }

    var numericMaxTemperature: Double? {
        Self.numericTemperature(from: maxText)
    }

    private static func numericTemperature(from value: String) -> Double? {
        let cleanedValue = value
            .replacingOccurrences(of: "°", with: "")
            .replacingOccurrences(of: "C", with: "")
            .replacingOccurrences(of: "F", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(cleanedValue)
    }
}


#Preview {
    HomeView(viewModel: WeatherViewModel())
}

private struct SunCycleCard: View {
    let sunrise: Date
    let sunset: Date
    let prefersExtraContrast: Bool

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Sunrise", systemImage: "sunrise.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.96))

                    Text(Self.timeFormatter.string(from: sunrise))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .overlay(.white.opacity(0.18))
                    .frame(maxHeight: 42)

                VStack(alignment: .trailing, spacing: 8) {
                    Label("Sunset", systemImage: "sunset.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.96))

                    Text(Self.timeFormatter.string(from: sunset))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daylight")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.92))

                    Spacer()

                    Text(daylightDurationText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.18))
                            .frame(height: 10)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.yellow.opacity(0.95), Color.orange.opacity(0.95)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(18, geometry.size.width * daylightProgress), height: 10)
                    }
                }
                .frame(height: 10)

                // ADDED: Time until next event text
                Text(timeUntilNextEventText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: HomeView.UI.cardCornerRadius, style: .continuous)
                .fill(Color.black.opacity(prefersExtraContrast ? 0.06 : 0))
        }
        .glassCard(cornerRadius: HomeView.UI.cardCornerRadius)
    }

    private var daylightProgress: CGFloat {
        let total = sunset.timeIntervalSince(sunrise)
        guard total > 0 else { return 0 }

        let current = Date().timeIntervalSince(sunrise)
        let progress = current / total
        return min(max(progress, 0), 1)
    }

    private var daylightDurationText: String {
        let totalMinutes = max(Int(sunset.timeIntervalSince(sunrise) / 60), 0)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    // ADDED: Time until next event computed property
    private var timeUntilNextEventText: String {
        let now = Date()

        if now < sunrise {
            return "Sunrise in \(timeString(from: sunrise.timeIntervalSince(now)))"
        } else if now < sunset {
            return "Sunset in \(timeString(from: sunset.timeIntervalSince(now)))"
        } else {
            // After sunset → next sunrise (next day)
            let nextSunrise = Calendar.current.date(byAdding: .day, value: 1, to: sunrise) ?? sunrise
            return "Sunrise in \(timeString(from: nextSunrise.timeIntervalSince(now)))"
        }
    }

    // ADDED: Helper function for time formatting
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
}

private struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                ZStack {
                    shape
                        .fill(.ultraThinMaterial)

                    shape
                        .fill(colorScheme == .dark ? Color.black.opacity(0.28) : Color.white.opacity(0.10))
                }
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.24 : 0.07), radius: 14, x: 0, y: 8)
            .overlay {
                shape
                    .stroke(.white.opacity(colorScheme == .dark ? 0.14 : 0.28), lineWidth: 1)
            }
    }
}

private extension View {
    func glassCard(cornerRadius: CGFloat = 22) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

