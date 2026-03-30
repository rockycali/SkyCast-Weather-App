import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("temperatureUnit") private var temperatureUnit = "C"
    @ObservedObject var viewModel: WeatherViewModel
    @State private var searchText = ""
    @State private var showErrorAlert = false
    @State private var animateBackgroundGradient = false

    enum UI {
        static let pageSpacing: CGFloat = 20
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
        static let hourlySectionSideInset: CGFloat = 0
        static let hourlySectionHorizontalBreakout: CGFloat = -8
        static let inputCornerRadius: CGFloat = 16
        static let secondaryCardCornerRadius: CGFloat = 20
        static let cardCornerRadius: CGFloat = 22
        static let heroCardCornerRadius: CGFloat = 28
        static let subtleTextOpacity: CGFloat = 0.78
        static let secondaryTextOpacityDark: CGFloat = 0.9
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
        static let backgroundSecondaryLayerOpacity: CGFloat = 0.22
        static let backgroundSecondaryAnimationDuration: Double = 32
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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: UI.pageSpacing) {
                        if viewModel.isOffline {
                            Text("Offline mode - showing last data")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        headerSection
                        searchSection
                        currentWeatherSection
                        metricsSection
                        sunCycleSection
                        hourlySection
                        dailySection
                    }
                    .padding(.horizontal, UI.contentHorizontalPadding)
                    .padding(.vertical, UI.contentVerticalPadding)
                    .animation(.easeInOut(duration: 0.4), value: viewModel.weather?.current.weatherCode ?? -1)
                    .id(temperatureUnit)
                }
                .refreshable {
                    print("🔄 Pull-to-refresh triggered")
                    await viewModel.refreshCurrentSource()
                }
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
                    Color(red: 0.03, green: 0.06, blue: 0.16),
                    Color(red: 0.09, green: 0.15, blue: 0.30)
                ]
            case 1...3:
                return [
                    Color(red: 0.10, green: 0.14, blue: 0.26),
                    Color(red: 0.18, green: 0.22, blue: 0.38)
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
                    Color(red: 0.04, green: 0.07, blue: 0.16),
                    Color(red: 0.10, green: 0.14, blue: 0.24)
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
                    Color(red: 0.30, green: 0.40, blue: 0.70).opacity(0.40),
                    Color.clear
                ]
            case 51...67, 71...77, 95...99:
                return [
                    Color(red: 0.18, green: 0.26, blue: 0.48).opacity(0.34),
                    Color.clear
                ]
            default:
                return [
                    Color(red: 0.24, green: 0.30, blue: 0.50).opacity(0.32),
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

    private var searchSection: some View {
        VStack(spacing: UI.gridSpacing) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(colorScheme == .dark ? 0.75 : 0.8))

                TextField(
                    "",
                    text: $searchText,
                    prompt: Text("Search city").foregroundStyle(.white.opacity(0.6))
                )
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .foregroundStyle(.white)
                    .tint(.white)
                    .onSubmit {
                        Task {
                            await searchCity()
                        }
                    }

                Button {
                    Task {
                        await searchCity()
                    }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
            }
            .padding(.horizontal, UI.fieldHorizontalPadding)
            .frame(height: UI.buttonHeight)
            .background(.white.opacity(UI.textFieldBackgroundOpacity))
            .overlay {
                RoundedRectangle(cornerRadius: UI.inputCornerRadius, style: .continuous)
                    .stroke(.white.opacity(UI.fieldBorderOpacityDark), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: UI.inputCornerRadius, style: .continuous))

            VStack(spacing: 0) {
                Button {
                    viewModel.requestLocation()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "location.fill")
                            .frame(width: 18)
                            .foregroundStyle(.white.opacity(0.85))

                        Text("Use My Location")
                            .foregroundStyle(.white)
                    }
                    .font(.headline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: UI.buttonHeight)
                    .padding(.horizontal, UI.fieldHorizontalPadding)
                }

                if viewModel.weather != nil {
                    Divider()
                        .overlay(.white.opacity(0.06))
                        .padding(.horizontal, UI.fieldHorizontalPadding)

                    Button {
                        viewModel.addCurrentCityToFavorites()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: viewModel.isFavoriteCurrentCity() ? "star.fill" : "star")
                                .frame(width: 18)
                                .foregroundStyle(.white.opacity(0.85))

                            Text(viewModel.isFavoriteCurrentCity() ? "Saved to Favorites" : "Save to Favorites")
                                .foregroundStyle(.white)
                        }
                        .font(.headline.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: UI.buttonHeight)
                        .padding(.horizontal, UI.fieldHorizontalPadding)
                    }
                    .disabled(viewModel.isFavoriteCurrentCity())
                    .opacity(viewModel.isFavoriteCurrentCity() ? 0.7 : 1)
                }
            }
            .background(.white.opacity(UI.secondaryButtonBackgroundOpacity))
            .overlay {
                RoundedRectangle(cornerRadius: UI.inputCornerRadius, style: .continuous)
                    .stroke(.white.opacity(UI.buttonBorderOpacity), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: UI.inputCornerRadius, style: .continuous))
        }
    }


    private var currentWeatherSection: some View {
        Group {
            if let weather = viewModel.weather {
                VStack(spacing: UI.gridSpacing) {
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
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .glassCard(cornerRadius: UI.heroCardCornerRadius)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else if viewModel.isLoading {
                loadingCard
            }
        }
    }

    private var metricsSection: some View {
        Group {
            if let weather = viewModel.weather {
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
                        sunset: today.sunset
                    )
                }
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
                                HourlyForecastCard(hour: hour)
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
                VStack(alignment: .leading, spacing: UI.sectionSpacing) {
                    sectionTitle("5-Day Forecast")

                    VStack(spacing: UI.rowSpacing) {
                        ForEach(viewModel.dailyForecast) { day in
                            DailyForecastRow(day: day)
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
                .foregroundStyle(.white)

            Spacer()
        }
    }

    private func searchCity() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await viewModel.searchCity(named: trimmed)
        if viewModel.errorMessage == nil {
            searchText = ""
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
                    .foregroundStyle(.white.opacity(0.96))
                    .frame(width: 18, alignment: .leading)

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.96))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 40, alignment: .topLeading)

            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(14)
        .glassCard(cornerRadius: HomeView.UI.cardCornerRadius)
    }
}

private struct HourlyForecastCard: View {
    let hour: HourlyForecastItem

    var body: some View {
        VStack(spacing: 10) {
            Text(hour.timeLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.96))

            Image(systemName: hour.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.title2)
                .shadow(color: .white.opacity(0.14), radius: 8, x: 0, y: 0)

            Text(hour.temperatureText)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(width: HomeView.UI.hourlyCardWidth)
        .padding(.vertical, 16)
        .glassCard(cornerRadius: HomeView.UI.cardCornerRadius)
    }
}

private struct DailyForecastRow: View {
    let day: DailyForecastItem

    var body: some View {
        HStack {
            Text(day.dayLabel)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: day.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.title3)
                .frame(width: 32)

            Spacer(minLength: 10)

            Text(day.minText)
                .foregroundStyle(.white.opacity(0.75))
                .frame(width: 42, alignment: .trailing)

            Text(day.maxText)
                .foregroundStyle(.white)
                .frame(width: 42, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: HomeView.UI.secondaryCardCornerRadius)
    }
}

#Preview {
    HomeView(viewModel: WeatherViewModel())
}

private struct SunCycleCard: View {
    let sunrise: Date
    let sunset: Date

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
                    .overlay(.white.opacity(0.32))
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
            }
        }
        .padding(18)
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
}

private struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.16 : 0.07), radius: 12, x: 0, y: 6)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(colorScheme == .dark ? 0.16 : 0.24), lineWidth: 1)
            }
    }
}

private extension View {
    func glassCard(cornerRadius: CGFloat = 22) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

