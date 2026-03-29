import Foundation

struct GeocodingResponse: Decodable {
    let results: [LocationResult]?
}

struct LocationResult: Decodable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let admin1: String?

    var displayName: String {
        let region = admin1?.isEmpty == false ? admin1! + ", " : ""
        return "\(name), \(region)\(country)"
    }
}

struct ForecastResponse: Codable {
    let timezone: String
    let current: CurrentWeatherDTO
    let hourly: HourlyWeatherDTO
    let daily: DailyWeatherDTO
}

struct CurrentWeatherDTO: Codable {
    let temperature2m: Double
    let weatherCode: Int
    let apparentTemperature: Double
    let relativeHumidity2m: Int
    let windSpeed10m: Double
    let precipitationProbability: Int

    enum CodingKeys: String, CodingKey {
        case weatherCode = "weather_code"
        case apparentTemperature = "apparent_temperature"
        case relativeHumidity2m = "relative_humidity_2m"
        case temperature2m = "temperature_2m"
        case windSpeed10m = "wind_speed_10m"
        case precipitationProbability = "precipitation_probability"
    }
}

struct HourlyWeatherDTO: Codable {
    let time: [String]
    let temperature2m: [Double]
    let weatherCode: [Int]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
    }
}

struct DailyWeatherDTO: Codable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let sunrise: [String]
    let sunset: [String]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case sunrise
        case sunset
    }
}

struct WeatherData: Codable {
    let locationName: String
    let current: CurrentWeather
    let hourly: [HourlyForecastItem]
    let daily: [DailyForecastItem]

    var todayHighText: String {
        let unit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "C"
        return daily.first?.maxText ?? (unit == "F" ? "--°F" : "--°C")
    }

    var todayLowText: String {
        let unit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "C"
        return daily.first?.minText ?? (unit == "F" ? "--°F" : "--°C")
    }
}

struct CurrentWeather: Codable {
    let temperature: Double
    let weatherCode: Int
    let apparentTemperature: Double
    let humidity: Int
    let windSpeed: Double
    let precipitationProbability: Int

    var temperatureText: String { Self.formatTemperature(temperature) }
    var apparentTemperatureText: String { Self.formatTemperature(apparentTemperature) }
    var humidityText: String { "\(humidity)%" }
    var windSpeedText: String { Self.formatWindSpeed(windSpeed) }
    var precipitationChanceText: String { "\(precipitationProbability)%" }
    var summary: String { WeatherCodeMapper.description(for: weatherCode) }
    var symbolName: String { WeatherCodeMapper.symbolName(for: weatherCode) }
    var nightSymbolName: String { WeatherCodeMapper.nightSymbolName(for: weatherCode) }
    
    static func formatTemperature(_ value: Double) -> String {
        let unit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "C"

        if unit == "F" {
            let fahrenheit = (value * 9 / 5) + 32
            return "\(Int(fahrenheit.rounded()))°F"
        }

        return "\(Int(value.rounded()))°C"
    }

    static func formatWindSpeed(_ value: Double) -> String {
        let unit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "C"

        if unit == "F" {
            let mph = value * 0.621371
            return "\(Int(mph.rounded())) mph"
        }

        return "\(Int(value.rounded())) km/h"
    }
}

struct HourlyForecastItem: Identifiable, Codable {
    let id: UUID
    let date: Date
    let temperature: Double
    let weatherCode: Int
    let isNight: Bool

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var temperatureText: String {
        CurrentWeather.formatTemperature(temperature)
    }

    var symbolName: String {
        isNight
            ? WeatherCodeMapper.nightSymbolName(for: weatherCode)
            : WeatherCodeMapper.symbolName(for: weatherCode)
    }
}

struct DailyForecastItem: Identifiable, Codable {
    let id: UUID
    let date: Date
    let minTemperature: Double
    let maxTemperature: Double
    let weatherCode: Int
    let sunrise: Date
    let sunset: Date

    var dayLabel: String {
        if Calendar.current.isDateInToday(date) {
            return String(localized: "Today")
        }

        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }

    var minText: String {
        CurrentWeather.formatTemperature(minTemperature)
    }

    var maxText: String {
        CurrentWeather.formatTemperature(maxTemperature)
    }

    var symbolName: String {
        WeatherCodeMapper.symbolName(for: weatherCode)
    }
}

enum WeatherCodeMapper {
    static func symbolName(for code: Int) -> String {
        switch code {
        case 0:
            return "sun.max.fill"
        case 1, 2:
            return "cloud.sun.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55, 56, 57:
            return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86:
            return "cloud.snow.fill"
        case 95, 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }

    static func nightSymbolName(for code: Int) -> String {
        switch code {
        case 0:
            return "moon.stars.fill"
        case 1, 2:
            return "cloud.moon.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55, 56, 57:
            return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86:
            return "cloud.snow.fill"
        case 95, 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.moon.fill"
        }
    }

    static func description(for code: Int) -> String {
        switch code {
        case 0: return String(localized: "Clear Sky")
        case 1: return String(localized: "Mostly Clear")
        case 2: return String(localized: "Partly Cloudy")
        case 3: return String(localized: "Overcast")
        case 45, 48: return String(localized: "Fog")
        case 51, 53, 55: return String(localized: "Drizzle")
        case 56, 57: return String(localized: "Freezing Drizzle")
        case 61: return String(localized: "Light Rain")
        case 63: return String(localized: "Rain")
        case 65: return String(localized: "Heavy Rain")
        case 66, 67: return String(localized: "Freezing Rain")
        case 71: return String(localized: "Light Snow")
        case 73: return String(localized: "Snow")
        case 75: return String(localized: "Heavy Snow")
        case 77: return String(localized: "Snow Grains")
        case 80: return String(localized: "Rain Showers")
        case 81: return String(localized: "Strong Rain Showers")
        case 82: return String(localized: "Violent Rain Showers")
        case 85: return String(localized: "Snow Showers")
        case 86: return String(localized: "Heavy Snow Showers")
        case 95: return String(localized: "Thunderstorm")
        case 96, 99: return String(localized: "Thunderstorm with Hail")
        default: return String(localized: "Unknown")
        }
    }
}
