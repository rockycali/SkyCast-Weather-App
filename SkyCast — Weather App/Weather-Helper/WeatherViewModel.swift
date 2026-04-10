import Combine
import CoreLocation
import Foundation
import SwiftUI

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherData?
    @Published var isLoading = false
    @Published var isRefreshing = false
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
    private var activeWeatherRequestKey: String?
    private var weatherLoadTask: Task<Void, Never>?
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
        let isNight: Bool
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

    private func isNight(for weather: WeatherData) -> Bool {
        guard let today = weather.daily.first else { return false }
        let now = Date()
        return now < today.sunrise || now > today.sunset
    }

    private func applyCachedWeather(
        _ cached: WeatherData,
        latitude: Double,
        longitude: Double,
        markOffline: Bool = false
    ) {
        currentLatitude = latitude
        currentLongitude = longitude
        weather = cached
        displayName = cached.locationName
        errorMessage = nil
        isOffline = markOffline
    }

    private func weatherRequestKey(latitude: Double, longitude: Double) -> String {
        let roundedLatitude = (latitude * 10_000).rounded() / 10_000
        let roundedLongitude = (longitude * 10_000).rounded() / 10_000

        let sourceKey: String
        switch currentSource {
        case .myLocation:
            sourceKey = "myLocation"
        case .city:
            sourceKey = "city"
        case .default:
            sourceKey = "default"
        }

        return "\(sourceKey)-\(roundedLatitude)-\(roundedLongitude)"
    }

    private func shouldSkipWeatherRequest(for requestKey: String) -> Bool {
        guard let activeWeatherRequestKey else { return false }
        return activeWeatherRequestKey == requestKey
    }

    private func isShowingWeather(near latitude: Double, longitude: Double, threshold: Double = 0.001) -> Bool {
        guard let currentLatitude, let currentLongitude else { return false }
        return abs(currentLatitude - latitude) < threshold && abs(currentLongitude - longitude) < threshold
    }

    private func startWeatherLoad(latitude: Double, longitude: Double, name: String) {
        weatherLoadTask?.cancel()
        weatherLoadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.loadWeather(
                latitude: latitude,
                longitude: longitude,
                name: name
            )
        }
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
                startWeatherLoad(
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
            startWeatherLoad(latitude: 47.3769, longitude: 8.5417, name: "Zurich, Switzerland")

        @unknown default:
            currentSource = .default
            startWeatherLoad(latitude: 47.3769, longitude: 8.5417, name: "Zurich, Switzerland")
        }
    }

    func loadDefaultWeatherIfNeeded() async {
        guard !hasLoadedDefault else { return }
        hasLoadedDefault = true
        currentSource = .default
        startWeatherLoad(latitude: 47.3769, longitude: 8.5417, name: "Zurich, Switzerland")
    }

    func refreshCurrentSource() async {
        switch currentSource {
        case .myLocation:
            if let location = locationManager.lastLocation {
                let name = locationManager.cityName.isEmpty ? "My Location" : locationManager.cityName
                startWeatherLoad(
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
            startWeatherLoad(
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
            startWeatherLoad(
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

        startWeatherLoad(
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
            let isNearDuplicateLocation: Bool
            if let previousLocation = lastObservedLocation {
                isNearDuplicateLocation = previousLocation.distance(from: location) < 50
            } else {
                isNearDuplicateLocation = false
            }

            if isNearDuplicateLocation,
               isShowingWeather(near: location.coordinate.latitude, longitude: location.coordinate.longitude) {
                print("🌦 skipping requestLocation weather reload for near-duplicate location already on screen")
                displayName = name
                return
            }

            lastObservedLocation = location
            startWeatherLoad(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                name: name
            )
        } else {
            locationManager.requestLocation()
        }
    }

    func loadWeather(latitude: Double, longitude: Double, name: String) async {
        print("🌦 loadWeather called:", latitude, longitude, name)
        if Task.isCancelled {
            print("⚠️ skipping cancelled weather load before start")
            return
        }
        let requestKey = weatherRequestKey(latitude: latitude, longitude: longitude)
        if shouldSkipWeatherRequest(for: requestKey) {
            print("🌦 skipping duplicate weather request:", requestKey)
            return
        }
        
        activeWeatherRequestKey = requestKey
        errorMessage = nil

        let cachedWeather = cache.load(latitude: latitude, longitude: longitude)
        let hasVisibleWeather = weather != nil

        if let cachedWeather {
            applyCachedWeather(
                cachedWeather,
                latitude: latitude,
                longitude: longitude,
                markOffline: false
            )
        }

        if cachedWeather != nil || hasVisibleWeather {
            isRefreshing = true
        } else {
            isLoading = true
        }

        defer {
            isLoading = false
            isRefreshing = false
            if activeWeatherRequestKey == requestKey {
                activeWeatherRequestKey = nil
            }
        }

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
            if Task.isCancelled {
                print("⚠️ weather load cancelled before applying result")
                return
            }

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
            errorMessage = nil

        } catch {
            if isCancellationError(error) {
                print("⚠️ load cancelled")
                return
            }
            if Task.isCancelled {
                print("⚠️ load cancelled by task state")
                return
            }

            print("API failed, trying cache...")

            if let cachedWeather {
                applyCachedWeather(
                    cachedWeather,
                    latitude: latitude,
                    longitude: longitude,
                    markOffline: true
                )
            } else if weather != nil, isLikelyNetworkFailure(error) {
                isOffline = true
                errorMessage = nil
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

    func addFavorite(_ favorite: FavoriteCity) {
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

        startWeatherLoad(
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
                    weatherCode: weather.current.weatherCode,
                    isNight: isNight(for: weather)
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
                       previousLocation.distance(from: location) < 50,
                       self.isShowingWeather(near: location.coordinate.latitude, longitude: location.coordinate.longitude) {
                        print("🌦 ignored near-duplicate location update already matching visible weather")
                        return
                    }

                    self.lastObservedLocation = location

                    print("🌦 observeLocation received:", location.coordinate.latitude, location.coordinate.longitude)
                    self.startWeatherLoad(
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
                    if self.isRefreshing || self.isLoading { return }
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
