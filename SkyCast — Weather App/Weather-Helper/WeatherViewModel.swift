import Combine
import CoreLocation
import Foundation

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var displayName = "Weather"

    private let weatherService: WeatherServiceProtocol
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedDefault = false

    init(weatherService: WeatherServiceProtocol = WeatherService(), locationManager: LocationManager = LocationManager()) {
        self.weatherService = weatherService
        self.locationManager = locationManager
        observeLocation()
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
        await loadWeather(latitude: 47.3769, longitude: 8.5417, name: "Zurich, Switzerland")
    }

    func searchCity(named query: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let results = try await weatherService.searchLocations(query: query)
            guard let first = results.first else {
                throw WeatherError.noResults
            }

            await loadWeather(latitude: first.latitude, longitude: first.longitude, name: first.displayName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestLocation() {
        print("🌦 requestLocation() called from WeatherViewModel")
        locationManager.requestLocation()
    }

    func loadWeather(latitude: Double, longitude: Double, name: String) async {
        print("🌦 loadWeather called:", latitude, longitude, name)
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await weatherService.fetchWeather(latitude: latitude, longitude: longitude, locationName: name)
            weather = result
            displayName = name
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func observeLocation() {
        locationManager.$lastLocation
            .combineLatest(locationManager.$cityName)
            .compactMap { (location: CLLocation?, cityName: String) -> (CLLocation, String)? in
                guard let location else { return nil }
                return (location, cityName)
            }
            .sink { [weak self] value in
                guard let self else { return }
                let (location, cityName) = value
                print("🌦 observeLocation received:", location.coordinate.latitude, location.coordinate.longitude)
                let resolvedName = cityName.isEmpty ? "My Location" : cityName
                Task {
                    await self.loadWeather(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        name: resolvedName
                    )
                }
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
