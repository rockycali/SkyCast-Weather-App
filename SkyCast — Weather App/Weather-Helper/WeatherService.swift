import Foundation

protocol WeatherServiceProtocol {
    func searchLocations(query: String) async throws -> [LocationResult]
    func fetchWeather(latitude: Double, longitude: Double, locationName: String) async throws -> WeatherData
}

final class WeatherService: WeatherServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
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
        guard var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast") else {
            throw WeatherError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,precipitation_probability,weather_code"),
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
        return mapForecast(forecast, locationName: locationName)
    }

    private func mapForecast(_ forecast: ForecastResponse, locationName: String) -> WeatherData {
        let isoFormatter = ISO8601DateFormatter()

        let current = CurrentWeather(
            temperature: forecast.current.temperature2m,
            weatherCode: forecast.current.weatherCode,
            apparentTemperature: forecast.current.apparentTemperature,
            humidity: forecast.current.relativeHumidity2m,
            windSpeed: forecast.current.windSpeed10m,
            precipitationProbability: forecast.current.precipitationProbability
        )

        let hourly = zip(zip(forecast.hourly.time, forecast.hourly.temperature2m), forecast.hourly.weatherCode)
            .compactMap { pair -> HourlyForecastItem? in
                let ((timeString, temperature), code) = pair
                guard let date = isoFormatter.date(from: timeString) else { return nil }
                return HourlyForecastItem(date: date, temperature: temperature, weatherCode: code)
            }
            .prefix(12)
            .map { $0 }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = .current

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        timeFormatter.timeZone = .current

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
                let sunrise = timeFormatter.date(from: sunriseString) ?? isoFormatter.date(from: sunriseString),
                let sunset = timeFormatter.date(from: sunsetString) ?? isoFormatter.date(from: sunsetString)
            else {
                return nil
            }

            return DailyForecastItem(
                date: date,
                minTemperature: minTemp,
                maxTemperature: maxTemp,
                weatherCode: code,
                sunrise: sunrise,
                sunset: sunset
            )
        }

        return WeatherData(locationName: locationName, current: current, hourly: hourly, daily: daily)
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

enum WeatherError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case noResults
    case locationUnavailable

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
        }
    }
}
