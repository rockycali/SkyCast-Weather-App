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

struct ForecastResponse: Decodable {
    let timezone: String
    let current: CurrentWeatherDTO
    let hourly: HourlyWeatherDTO
    let daily: DailyWeatherDTO
}

struct CurrentWeatherDTO: Decodable {
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

struct HourlyWeatherDTO: Decodable {
    let time: [String]
    let temperature2m: [Double]
    let weatherCode: [Int]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
    }
}

struct DailyWeatherDTO: Decodable {
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

struct WeatherData {
    let locationName: String
    let current: CurrentWeather
    let hourly: [HourlyForecastItem]
    let daily: [DailyForecastItem]

    var todayHighText: String {
        daily.first?.maxText ?? "--°"
    }

    var todayLowText: String {
        daily.first?.minText ?? "--°"
    }
}

struct CurrentWeather {
    let temperature: Double
    let weatherCode: Int
    let apparentTemperature: Double
    let humidity: Int
    let windSpeed: Double
    let precipitationProbability: Int

    var temperatureText: String { Self.formatTemperature(temperature) }
    var apparentTemperatureText: String { Self.formatTemperature(apparentTemperature) }
    var humidityText: String { "\(humidity)%" }
    var windSpeedText: String { "\(Int(windSpeed.rounded())) km/h" }
    var precipitationChanceText: String { "\(precipitationProbability)%" }
    var summary: String { WeatherCodeMapper.description(for: weatherCode) }
    var symbolName: String { WeatherCodeMapper.symbolName(for: weatherCode) }
    var nightSymbolName: String { WeatherCodeMapper.nightSymbolName(for: weatherCode) }
    
    static func formatTemperature(_ value: Double) -> String {
        "\(Int(value.rounded()))°"
    }
}

struct HourlyForecastItem: Identifiable {
    let id = UUID()
    let date: Date
    let temperature: Double
    let weatherCode: Int
    let isNight: Bool

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
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

struct DailyForecastItem: Identifiable {
    let id = UUID()
    let date: Date
    let minTemperature: Double
    let maxTemperature: Double
    let weatherCode: Int
    let sunrise: Date
    let sunset: Date

    var dayLabel: String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
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
        case 0: return "Clear Sky"
        case 1: return "Mostly Clear"
        case 2: return "Partly Cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing Drizzle"
        case 61: return "Light Rain"
        case 63: return "Rain"
        case 65: return "Heavy Rain"
        case 66, 67: return "Freezing Rain"
        case 71: return "Light Snow"
        case 73: return "Snow"
        case 75: return "Heavy Snow"
        case 77: return "Snow Grains"
        case 80: return "Rain Showers"
        case 81: return "Strong Rain Showers"
        case 82: return "Violent Rain Showers"
        case 85: return "Snow Showers"
        case 86: return "Heavy Snow Showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm with Hail"
        default: return "Unknown"
        }
    }
}
