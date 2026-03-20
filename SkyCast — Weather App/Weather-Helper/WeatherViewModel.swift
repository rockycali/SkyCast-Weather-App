import Combine
import CoreLocation
import Foundation

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var displayName = "Weather"
    @Published var currentSource: WeatherSource = .default

    init(weatherService: WeatherServiceProtocol = WeatherService(), locationManager: LocationManager = LocationManager()) {
        self.weatherService = weatherService
        self.locationManager = locationManager
        observeLocation()
    }

    enum WeatherSource {
        case myLocation
        case city(String)
        case `default`
    }

    var hourlyForecast: [HourlyForecastItem] {
        weather?.hourly ?? []
    }

    var dailyForecast: [DailyForecastItem] {
        weather?.daily ?? []
    }

    var isNight: Bool {
        guard let today = dailyForecast.first else { return false }
        let now = Date()
        return now < today.sunrise || now > today.sunset
    }

    func loadDefaultWeatherIfNeeded() async {
        guard !hasLoadedDefault else { return }
        hasLoadedDefault = true
        currentSource = .default
        await loadWeather(latitude: 47.3769, longitude: 8.5417, name: "Zurich, Switzerland")
    }

    func searchCity(named query: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let results = try await weatherService.searchLocations(query: query)
            guard let first = results.first else {
                throw WeatherError.noResults
            }
            currentSource = .city(first.displayName)
            await loadWeather(latitude: first.latitude, longitude: first.longitude, name: first.displayName)
        } catch is CancellationError {
            print("⚠️ search cancelled")
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestLocation() {
        print("🌦 requestLocation() called from WeatherViewModel")
        currentSource = .myLocation
        locationManager.requestLocation()
    }

    func loadWeather(latitude: Double, longitude: Double, name: String) async {
        print("🌦 loadWeather called:", latitude, longitude, name)
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await weatherService.fetchWeather(latitude: latitude, longitude: longitude, locationName: name)
            weather = result
            displayName = name
        } catch is CancellationError {
            print("⚠️ load cancelled")
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private let weatherService: WeatherServiceProtocol
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedDefault = false

    private func observeLocation() {
        locationManager.$lastLocation
            .compactMap { $0 }
            .removeDuplicates(by: { lhs, rhs in
                abs(lhs.coordinate.latitude - rhs.coordinate.latitude) < 0.000001 &&
                abs(lhs.coordinate.longitude - rhs.coordinate.longitude) < 0.000001
            })
            .sink { [weak self] location in
                guard let self else { return }
                print("🌦 observeLocation received:", location.coordinate.latitude, location.coordinate.longitude)
                self.currentSource = .myLocation
                Task {
                    await self.loadWeather(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        name: "My Location"
                    )
                }
            }
            .store(in: &cancellables)

        locationManager.$cityName
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { [weak self] cityName in
                guard let self else { return }
                guard case .myLocation = self.currentSource else { return }
                print("🌦 cityName updated:", cityName)
                self.displayName = cityName
            }
            .store(in: &cancellables)

        locationManager.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] message in
                print("🌦 location error from manager:", message)
                self?.errorMessage = message
            }
            .store(in: &cancellables)
    }
}
