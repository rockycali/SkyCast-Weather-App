//
//  WeatherCacheManager.swift
//  ClimaFlow
//
//  Created by Nafish on 27/03/26.
//

import Foundation

class WeatherCacheManager {
    private let keyPrefix = "cached_weather_data"

    /// Stable key per geographic point (~11 m precision) so cached weather matches the requested location.
    private func storageKey(latitude: Double, longitude: Double) -> String {
        let lat = (latitude * 10_000).rounded() / 10_000
        let lon = (longitude * 10_000).rounded() / 10_000
        return "\(keyPrefix)_\(lat)_\(lon)"
    }

    func save(_ weather: WeatherData, latitude: Double, longitude: Double) {
        do {
            let data = try JSONEncoder().encode(weather)
            UserDefaults.standard.set(data, forKey: storageKey(latitude: latitude, longitude: longitude))
        } catch {
            print("Cache save failed:", error)
        }
    }

    func load(latitude: Double, longitude: Double) -> WeatherData? {
        guard let data = UserDefaults.standard.data(forKey: storageKey(latitude: latitude, longitude: longitude)) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(WeatherData.self, from: data)
        } catch {
            print("Cache load failed:", error)
            return nil
        }
    }
}
