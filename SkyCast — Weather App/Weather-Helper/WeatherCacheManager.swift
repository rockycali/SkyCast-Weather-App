//
//  WeatherCacheManager.swift
//  ClimaFlow
//
//  Created by Nafish on 27/03/26.
//

import Foundation

class WeatherCacheManager {
    private let key = "cached_weather_data"

    func save(_ weather: WeatherData) {
        do {
            let data = try JSONEncoder().encode(weather)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Cache save failed:", error)
        }
    }

    func load() -> WeatherData? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
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
