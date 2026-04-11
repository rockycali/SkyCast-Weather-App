import Foundation

protocol WeatherServiceProtocol {
    func searchLocations(query: String) async throws -> [LocationResult]
    func fetchWeather(latitude: Double, longitude: Double, locationName: String) async throws -> WeatherData
}

final class WeatherService: WeatherServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 8
            configuration.timeoutIntervalForResource = 12
            self.session = URLSession(configuration: configuration)
        }

        self.decoder = JSONDecoder()
    }

    func searchLocations(query: String) async throws -> [LocationResult] {
        guard var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search") else {
            throw WeatherError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "8"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validate(response: response)

        let result = try decoder.decode(GeocodingResponse.self, from: data)
        return result.results ?? []
    }

    func fetchWeather(latitude: Double, longitude: Double, locationName: String) async throws -> WeatherData {
        try await fetchWeather(
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
            retryCount: 1
        )
    }

    private func fetchWeather(
        latitude: Double,
        longitude: Double,
        locationName: String,
        retryCount: Int
    ) async throws -> WeatherData {
        do {
            return try await performWeatherFetch(
                latitude: latitude,
                longitude: longitude,
                locationName: locationName
            )
        } catch {
            let mappedError = WeatherError.from(error)

            if retryCount > 0 {
                switch mappedError {
                case .timeout, .connectionLost:
                    try await Task.sleep(nanoseconds: 700_000_000)
                    return try await fetchWeather(
                        latitude: latitude,
                        longitude: longitude,
                        locationName: locationName,
                        retryCount: retryCount - 1
                    )
                default:
                    break
                }
            }

            throw mappedError
        }
    }

    private func performWeatherFetch(latitude: Double, longitude: Double, locationName: String) async throws -> WeatherData {
        guard var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast") else {
            throw WeatherError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,precipitation_probability,surface_pressure,uv_index,weather_code"),
            URLQueryItem(name: "hourly", value: "temperature_2m,apparent_temperature,weather_code"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"),
            URLQueryItem(name: "forecast_days", value: "5"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh")
        ]

        guard let url = components.url else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validate(response: response)

        let forecast = try decoder.decode(ForecastResponse.self, from: data)

        // Fetch Air Quality (AQI)
        let airQuality = try await fetchAirQuality(latitude: latitude, longitude: longitude)

        return mapForecast(forecast, locationName: locationName, airQuality: airQuality)
    }

    private func mapForecast(_ forecast: ForecastResponse, locationName: String, airQuality: Int?) -> WeatherData {
        let cityTimeZone = TimeZone(identifier: forecast.timezone) ?? .current

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = cityTimeZone

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        timeFormatter.timeZone = cityTimeZone

        let currentDTO = forecast.current

        let current = CurrentWeather(
            temperature: currentDTO.temperature2m,
            weatherCode: currentDTO.weatherCode,
            apparentTemperature: currentDTO.apparentTemperature,
            humidity: currentDTO.relativeHumidity2m,
            windSpeed: currentDTO.windSpeed10m,
            precipitationProbability: currentDTO.precipitationProbability,
            windDirection: currentDTO.windDirection10m,
            pressure: currentDTO.surfacePressure,
            uvIndex: currentDTO.uvIndex,
            airQuality: airQuality
        )

        let daily = zip(
            zip(forecast.daily.time, forecast.daily.temperature2mMin),
            zip(
                zip(forecast.daily.temperature2mMax, forecast.daily.weatherCode),
                zip(forecast.daily.sunrise, forecast.daily.sunset)
            )
        )
        .compactMap { entry -> DailyForecastItem? in
            let ((timeString, minTemp), ((maxTemp, code), (sunriseString, sunsetString))) = entry

            guard
                let date = dateFormatter.date(from: timeString),
                let sunrise = timeFormatter.date(from: sunriseString),
                let sunset = timeFormatter.date(from: sunsetString)
            else {
                return nil
            }

            return DailyForecastItem(
                id: UUID(),
                date: date,
                minTemperature: minTemp,
                maxTemperature: maxTemp,
                weatherCode: code,
                sunrise: sunrise,
                sunset: sunset
            )
        }

        var calendar = Calendar.current
        calendar.timeZone = cityTimeZone

        let now = Date()
        let currentHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now

        let allHourly = zip(zip(forecast.hourly.time, forecast.hourly.temperature2m), forecast.hourly.weatherCode)
            .compactMap { pair -> HourlyForecastItem? in
                let ((timeString, temperature), code) = pair
                guard let date = timeFormatter.date(from: timeString) else { return nil }

                let matchingDay = daily.first {
                    calendar.isDate($0.date, inSameDayAs: date)
                }

                let isNight = if let matchingDay {
                    date < matchingDay.sunrise || date >= matchingDay.sunset
                } else {
                    false
                }

                return HourlyForecastItem(
                    id: UUID(), 
                    date: date,
                    temperature: temperature,
                    weatherCode: code,
                    isNight: isNight
                )
            }

        let hourly = allHourly
            .drop { $0.date < currentHour }
            .prefix(12)
            .map { $0 }


        return WeatherData(locationName: locationName, current: current, hourly: hourly, daily: daily)
    }

    private func fetchAirQuality(latitude: Double, longitude: Double) async throws -> Int? {
        guard var components = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "us_aqi")
        ]

        guard let url = components.url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            try validate(response: response)
            let result = try decoder.decode(AirQualityResponse.self, from: data)
            return result.current.usAqi
        } catch {
            return nil
        }
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw WeatherError.serverError(httpResponse.statusCode)
        }
    }
}

private struct AirQualityResponse: Decodable {
    let current: AirQualityCurrent
}

private struct AirQualityCurrent: Decodable {
    let usAqi: Int

    enum CodingKeys: String, CodingKey {
        case usAqi = "us_aqi"
    }
}

enum WeatherError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case noResults
    case locationUnavailable
    case timeout
    case networkUnavailable
    case connectionLost
    case decodingFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The weather request could not be created."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .serverError(let code):
            return "The weather service returned error code \(code)."
        case .noResults:
            return "No matching city was found. Try another search."
        case .locationUnavailable:
            return "Your current location is not available yet."
        case .timeout:
            return "The weather service took too long to respond."
        case .networkUnavailable:
            return "You appear to be offline."
        case .connectionLost:
            return "The network connection was lost."
        case .decodingFailed:
            return "Weather data could not be read."
        case .unknown:
            return "Something went wrong while loading weather data."
        }
    }

    static func from(_ error: Error) -> WeatherError {
        if let weatherError = error as? WeatherError {
            return weatherError
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .notConnectedToInternet:
                return .networkUnavailable
            case .networkConnectionLost:
                return .connectionLost
            default:
                return .unknown
            }
        }

        if error is DecodingError {
            return .decodingFailed
        }

        return .unknown
    }
}
