import Combine
import CoreLocation
import Foundation
import SwiftUI

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var displayName = "Weather"
    @Published var currentSource: WeatherSource = .default
    @Published var favorites: [FavoriteCity] = []
    @Published var isOffline = false
    @Published var citySearchResults: [LocationResult] = []
    @Published var favoriteWeatherSnapshots: [String: FavoriteWeatherSnapshot] = [:]

    private let weatherService: WeatherServiceProtocol
    private let locationManager: LocationManager
    private let favoritesStorage: FavoritesStorage
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedDefault = false
    private var lastObservedLocation: CLLocation?
    private var currentLatitude: Double?
    private var currentLongitude: Double?
    private let cache = WeatherCacheManager()
  

    init(
        weatherService: WeatherServiceProtocol = WeatherService(),
        locationManager: LocationManager = LocationManager(),
        favoritesStorage: FavoritesStorage = FavoritesStorage()
    ) {
        self.weatherService = weatherService
        self.locationManager = locationManager
        self.favoritesStorage = favoritesStorage
        self.favorites = favoritesStorage.loadFavorites()
        observeLocation()
        Task { @MainActor in
            await refreshFavoriteWeatherSnapshots()
            await refreshCurrentSource()
        }
    }

    enum WeatherSource {
        case myLocation
        case city(String)
        case `default`
    }
    
    struct FavoriteWeatherSnapshot {
        let temperature: Int
        let weatherCode: Int
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

    /// True when the failure is due to no connectivity (vs validation, no results, etc.).
    private func isLikelyNetworkFailure(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .timedOut,
                 .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff:
                return true
            default:
                break
            }
        }
        if let clError = error as? CLError, clError.code == .network {
            return true
        }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            switch ns.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorCannotFindHost,
                 NSURLErrorTimedOut, NSURLErrorDNSLookupFailed, NSURLErrorDataNotAllowed:
                return true
            default:
                break
            }
        }
        return false
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
            await loadWeather(
                latitude: 47.3769,
                longitude: 8.5417,
                name: "Zurich, Switzerland"
            )
        }
    }

    func searchCity(named query: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let results = try await weatherService.searchLocations(query: query)
            citySearchResults = results
            guard let first = results.first else {
                throw WeatherError.noResults
            }
            currentSource = .city(first.displayName)
            await loadWeather(
                latitude: first.latitude,
                longitude: first.longitude,
                name: first.displayName
            )
        } catch {
            if isCancellationError(error) {
                print("⚠️ search cancelled")
                return
            }
            // Keep showing cached weather without a blocking alert when search can't reach the network.
            if weather != nil, isLikelyNetworkFailure(error) {
                isOffline = true
                return
            }
            citySearchResults = []
            errorMessage = error.localizedDescription
        }
    }

    func searchCities(for query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            citySearchResults = []
            errorMessage = nil
            return
        }

        do {
            let results = try await weatherService.searchLocations(query: trimmed)
            citySearchResults = results
            errorMessage = nil
        } catch {
            if isCancellationError(error) {
                return
            }
            citySearchResults = []
        }
    }

    func loadLocationResult(_ result: LocationResult) async {
        errorMessage = nil
        currentSource = .city(result.displayName)
        citySearchResults = []

        await loadWeather(
            latitude: result.latitude,
            longitude: result.longitude,
            name: result.displayName
        )
    }

    func requestLocation() {
        print("🌦 requestLocation() called from WeatherViewModel")
        currentSource = .myLocation

        if let location = locationManager.lastLocation {
            let name = locationManager.cityName.isEmpty ? "My Location" : locationManager.cityName
            lastObservedLocation = location
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

            currentLatitude = latitude
            currentLongitude = longitude
            weather = result
            displayName = finalDisplayName

            cache.save(result, latitude: latitude, longitude: longitude)
            isOffline = false

        } catch {
            if isCancellationError(error) {
                print("⚠️ load cancelled")
                return
            }

            print("API failed, trying cache...")

            if let cached = cache.load(latitude: latitude, longitude: longitude) {
                currentLatitude = latitude
                currentLongitude = longitude
                weather = cached
                displayName = cached.locationName
                errorMessage = nil
                isOffline = true
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    func addCurrentCityToFavorites() {
        guard let latitude = currentLatitude,
              let longitude = currentLongitude else {
            return
        }

        let locationName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !locationName.isEmpty else { return }

        let parts = locationName
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let cityName = parts.first ?? locationName
        let countryName = parts.count > 1 ? (parts.last ?? "") : ""

        let favorite = FavoriteCity(
            name: cityName,
            country: countryName,
            latitude: latitude,
            longitude: longitude
        )

        guard !favorites.contains(where: { $0.id == favorite.id }) else {
            return
        }

        favorites.append(favorite)
        favoritesStorage.saveFavorites(favorites)

        Task { @MainActor in
            await refreshFavoriteWeatherSnapshots()
        }
    }

    func removeFavorite(at offsets: IndexSet) {
        let idsToRemove = offsets.map { favorites[$0].id }
        favorites.remove(atOffsets: offsets)
        idsToRemove.forEach { favoriteWeatherSnapshots.removeValue(forKey: $0) }
        favoritesStorage.saveFavorites(favorites)
    }

    func removeFavorite(_ favorite: FavoriteCity) {
        favorites.removeAll { $0.id == favorite.id }
        favoriteWeatherSnapshots.removeValue(forKey: favorite.id)
        favoritesStorage.saveFavorites(favorites)
    }

    func loadFavorite(_ favorite: FavoriteCity) async {
        currentSource = .city(favorite.name)

        let fullName: String
        if favorite.country.isEmpty {
            fullName = favorite.name
        } else {
            fullName = "\(favorite.name), \(favorite.country)"
        }

        await loadWeather(
            latitude: favorite.latitude,
            longitude: favorite.longitude,
            name: fullName
        )
    }

    func refreshFavoriteWeatherSnapshots() async {
        guard !favorites.isEmpty else {
            favoriteWeatherSnapshots = [:]
            return
        }

        var snapshots: [String: FavoriteWeatherSnapshot] = [:]

        for favorite in favorites {
            do {
                let locationName = favorite.country.isEmpty
                    ? favorite.name
                    : "\(favorite.name), \(favorite.country)"

                let weather = try await weatherService.fetchWeather(
                    latitude: favorite.latitude,
                    longitude: favorite.longitude,
                    locationName: locationName
                )

                snapshots[favorite.id] = FavoriteWeatherSnapshot(
                    temperature: Int(weather.current.temperature.rounded()),
                    weatherCode: weather.current.weatherCode
                )
            } catch {
                continue
            }
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            favoriteWeatherSnapshots = snapshots
        }
    }

    func isFavoriteCurrentCity() -> Bool {
        guard let latitude = currentLatitude,
              let longitude = currentLongitude else {
            return false
        }

        return favorites.contains {
            $0.latitude == latitude && $0.longitude == longitude
        }
    }

    private func observeLocation() {
        locationManager.$lastLocation
            .compactMap { $0 }
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates(by: { lhs, rhs in
                lhs.distance(from: rhs) < 50
            })
            .sink { [weak self] location in
                Task { @MainActor [weak self] in
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

                    if let previousLocation = self.lastObservedLocation,
                       previousLocation.distance(from: location) < 50 {
                        print("🌦 ignored near-duplicate location update")
                        return
                    }

                    self.lastObservedLocation = location

                    print("🌦 observeLocation received:", location.coordinate.latitude, location.coordinate.longitude)
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
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    guard case .myLocation = self.currentSource else { return }
                    print("🌦 cityName updated:", cityName)
                    self.displayName = cityName
                }
            }
            .store(in: &cancellables)

        locationManager.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] message in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    print("🌦 location error from manager:", message)
                    if self.isOffline, self.weather != nil {
                        return
                    }
                    self.errorMessage = message
                }
            }
            .store(in: &cancellables)
    }
}
