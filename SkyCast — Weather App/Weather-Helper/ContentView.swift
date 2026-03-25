import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = WeatherViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.6), value: viewModel.weather?.current.weatherCode ?? -1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        searchSection
                        currentWeatherSection
                        metricsSection
                        sunCycleSection
                        hourlySection
                        dailySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .animation(.easeInOut(duration: 0.4), value: viewModel.weather?.current.weatherCode ?? -1)
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
            .alert("ClimaFlow", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        guard let weather = viewModel.weather else {
            return LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        if viewModel.isNight {
            switch weather.current.weatherCode {
            case 0:
                return LinearGradient(
                    colors: [Color(red: 0.03, green: 0.05, blue: 0.15), Color(red: 0.10, green: 0.16, blue: 0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case 1...3:
                return LinearGradient(
                    colors: [Color(red: 0.06, green: 0.08, blue: 0.18), Color(red: 0.14, green: 0.18, blue: 0.30)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case 45, 48:
                return LinearGradient(
                    colors: [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.18, green: 0.18, blue: 0.22)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case 51...67:
                return LinearGradient(
                    colors: [Color(red: 0.05, green: 0.08, blue: 0.16), Color(red: 0.11, green: 0.16, blue: 0.26)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case 71...77:
                return LinearGradient(
                    colors: [Color(red: 0.08, green: 0.12, blue: 0.22), Color(red: 0.18, green: 0.20, blue: 0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case 95...99:
                return LinearGradient(
                    colors: [Color.black, Color(red: 0.20, green: 0.10, blue: 0.30)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            default:
                return LinearGradient(
                    colors: [Color(red: 0.04, green: 0.06, blue: 0.14), Color(red: 0.10, green: 0.14, blue: 0.24)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }

        switch weather.current.weatherCode {
        case 0:
            return LinearGradient(colors: [.blue, .yellow], startPoint: .top, endPoint: .bottom)
        case 1...3:
            return LinearGradient(colors: [.gray, .blue], startPoint: .top, endPoint: .bottom)
        case 45, 48:
            return LinearGradient(colors: [.gray.opacity(0.8), .black], startPoint: .top, endPoint: .bottom)
        case 51...67:
            return LinearGradient(colors: [.blue, .gray], startPoint: .top, endPoint: .bottom)
        case 71...77:
            return LinearGradient(colors: [.white, .blue], startPoint: .top, endPoint: .bottom)
        case 95...99:
            return LinearGradient(colors: [.black, .purple], startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Current Weather")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))

            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text(viewModel.displayName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            if let current = viewModel.weather?.current {
                Text(current.summary)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(colorScheme == .dark ? 0.9 : 0.96))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(colorScheme == .dark ? 0.75 : 0.8))

                    TextField("Search city", text: $searchText)
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
                }
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(.white.opacity(0.16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.22), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    Task {
                        await searchCity()
                    }
                } label: {
                    WeatherButton(
                        title: "Go",
                        textColor: colorScheme == .dark ? .white : .black,
                        backgroundColor: colorScheme == .dark ? Color.white.opacity(0.16) : .white
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(colorScheme == .dark ? 0.22 : 0.12), lineWidth: 1)
                    }
                    .frame(width: 84, height: 50)
                }
                .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
            }

            Button {
                viewModel.requestLocation()
            } label: {
                Label("Use My Location", systemImage: "location.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.white.opacity(0.14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var currentWeatherSection: some View {
        Group {
            if let weather = viewModel.weather {
                VStack(spacing: 12) {
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
                        .opacity(colorScheme == .dark ? 0.9 : 0.96)
                    Text("H: \(weather.todayHighText)   L: \(weather.todayLowText)")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .glassCard(cornerRadius: 28)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else if viewModel.isLoading {
                loadingCard
            }
        }
    }

    private var metricsSection: some View {
        Group {
            if let weather = viewModel.weather {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                VStack(alignment: .leading, spacing: 14) {
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
                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("Hourly Forecast")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.hourlyForecast) { hour in
                                HourlyForecastCard(hour: hour)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
        }
    }

    private var dailySection: some View {
        Group {
            if !viewModel.dailyForecast.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("5-Day Forecast")

                    VStack(spacing: 10) {
                        ForEach(viewModel.dailyForecast) { day in
                            DailyForecastRow(day: day)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)

            Text("Loading weather...")
                .foregroundStyle(.white)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .glassCard(cornerRadius: 28)
    }

    private func sectionTitle(_ title: String) -> some View {
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

private struct WeatherBackgroundView: View {
    let weatherCode: Int?
    let colorScheme: ColorScheme

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var gradientColors: [Color] {
        switch weatherCode {
        case 0:
            return colorScheme == .dark
                ? [Color(red: 0.05, green: 0.16, blue: 0.32), Color(red: 0.18, green: 0.39, blue: 0.62)]
                : [Color.blue, Color.cyan]
        case 1, 2, 3:
            return colorScheme == .dark
                ? [Color(red: 0.09, green: 0.13, blue: 0.24), Color(red: 0.23, green: 0.31, blue: 0.48)]
                : [Color.indigo, Color.blue]
        case 51, 53, 55, 61, 63, 65, 80, 81, 82:
            return colorScheme == .dark
                ? [Color(red: 0.14, green: 0.16, blue: 0.20), Color(red: 0.19, green: 0.28, blue: 0.39)]
                : [Color.gray, Color.blue.opacity(0.75)]
        case 71, 73, 75, 77, 85, 86:
            return colorScheme == .dark
                ? [Color(red: 0.12, green: 0.18, blue: 0.28), Color(red: 0.18, green: 0.20, blue: 0.36)]
                : [Color.cyan.opacity(0.8), Color.indigo]
        case 95, 96, 99:
            return colorScheme == .dark
                ? [Color.black, Color(red: 0.20, green: 0.10, blue: 0.30)]
                : [Color.black, Color.purple]
        default:
            return colorScheme == .dark
                ? [Color(red: 0.08, green: 0.12, blue: 0.22), Color(red: 0.18, green: 0.24, blue: 0.40)]
                : [Color.blue, Color.indigo]
        }
    }
}

private struct WeatherMetricCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.96))

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard(cornerRadius: 22)
    }
}

private struct HourlyForecastCard: View {
    @Environment(\.colorScheme) private var colorScheme
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
        .frame(width: 84)
        .padding(.vertical, 16)
        .glassCard(cornerRadius: 22)
    }
}

private struct DailyForecastRow: View {
    @Environment(\.colorScheme) private var colorScheme
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
        .glassCard(cornerRadius: 20)
    }
}

#Preview {
    ContentView()
}

private struct SunCycleCard: View {
    @Environment(\.colorScheme) private var colorScheme
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
        .glassCard(cornerRadius: 22)
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
