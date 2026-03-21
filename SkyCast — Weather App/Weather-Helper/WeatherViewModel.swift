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

    private let weatherService: WeatherServiceProtocol
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedDefault = false

    init(
        weatherService: WeatherServiceProtocol = WeatherService(),
        locationManager: LocationManager = LocationManager()
    ) {
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

    private func isCancellationError(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }

        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == URLError.cancelled.rawValue
    }

    func loadInitialWeatherIfNeeded() async {
        guard !hasLoadedDefault else { return }
        hasLoadedDefault = true

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            currentSource = .myLocation

            if let location = locationManager.lastLocation {
                let name = locationManager.cityName.isEmpty ? "My Location" : locationManager.cityName
                await loadWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    name: name
                )
            } else {
                requestLocation()
            }

        case .notDetermined:
            currentSource = .myLocation
            requestLocation()

        case .denied, .restricted:
            currentSource = .default
            await loadWeather(latitude: 47.3769, longitude: 8.5417, name: "Zurich, Switzerland")

        @unknown default:
            currentSource = .default
            await loadWeather(latitude: 47.3769, longitude: 8.5417, name: "Zurich, Switzerland")
        }
    }

    func loadDefaultWeatherIfNeeded() async {
        guard !hasLoadedDefault else { return }
        hasLoadedDefault = true
        currentSource = .default
        await loadWeather(latitude: 47.3769, longitude: 8.5417, name: "Zurich, Switzerland")
    }

    func refreshCurrentSource() async {
        switch currentSource {
        case .myLocation:
            if let location = locationManager.lastLocation {
                let name = locationManager.cityName.isEmpty ? "My Location" : locationManager.cityName
                await loadWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    name: name
                )
            } else {
                requestLocation()
            }

        case .city(let name):
            await searchCity(named: name)

        case .default:
            await loadDefaultWeatherIfNeeded()
        }
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
        } catch {
            if isCancellationError(error) {
                print("⚠️ search cancelled")
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func requestLocation() {
        print("🌦 requestLocation() called from WeatherViewModel")
        currentSource = .myLocation

        if let location = locationManager.lastLocation {
            let name = locationManager.cityName.isEmpty ? "My Location" : locationManager.cityName
            Task {
                await loadWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    name: name
                )
            }
        } else {
            locationManager.requestLocation()
        }
    }

    func loadWeather(latitude: Double, longitude: Double, name: String) async {
        print("🌦 loadWeather called:", latitude, longitude, name)
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let requestDisplayName: String
            if case .myLocation = currentSource, !locationManager.cityName.isEmpty {
                requestDisplayName = locationManager.cityName
            } else {
                requestDisplayName = name
            }

            let result = try await weatherService.fetchWeather(
                latitude: latitude,
                longitude: longitude,
                locationName: requestDisplayName
            )

            let finalDisplayName: String
            if case .myLocation = currentSource, !locationManager.cityName.isEmpty {
                finalDisplayName = locationManager.cityName
            } else {
                finalDisplayName = requestDisplayName
            }

            weather = result
            displayName = finalDisplayName
        } catch {
            if isCancellationError(error) {
                print("⚠️ load cancelled")
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    private func observeLocation() {
        locationManager.$lastLocation
            .compactMap { $0 }
            .removeDuplicates(by: { lhs, rhs in
                abs(lhs.coordinate.latitude - rhs.coordinate.latitude) < 0.00005 &&
                abs(lhs.coordinate.longitude - rhs.coordinate.longitude) < 0.00005
            })
            .sink { [weak self] location in
                guard let self else { return }

                let shouldUseLocationUpdate: Bool
                switch self.currentSource {
                case .myLocation:
                    shouldUseLocationUpdate = true
                case .default:
                    shouldUseLocationUpdate = self.locationManager.authorizationStatus == .authorizedWhenInUse || self.locationManager.authorizationStatus == .authorizedAlways
                    if shouldUseLocationUpdate {
                        self.currentSource = .myLocation
                    }
                case .city:
                    shouldUseLocationUpdate = false
                }

                guard shouldUseLocationUpdate else {
                    print("🌦 ignored location update while viewing non-location source")
                    return
                }

                print("🌦 observeLocation received:", location.coordinate.latitude, location.coordinate.longitude)
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
