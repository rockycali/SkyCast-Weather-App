import Foundation

extension CurrentWeather {

    var airQualityText: String {
        guard let aqi = airQuality else { return "--" }

        let label: String
        switch aqi {
        case 0...50:
            label = String(localized: "Good")
        case 51...100:
            label = String(localized: "Moderate")
        case 101...150:
            label = String(localized: "Unhealthy (Sensitive)")
        case 151...200:
            label = String(localized: "Unhealthy")
        case 201...300:
            label = String(localized: "Very Unhealthy")
        default:
            label = String(localized: "Hazardous")
        }

        return "\(aqi) • \(label)"
    }

    var rainDescriptionText: String {
        let numericValue = precipitationChanceText
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let value = Int(numericValue) else {
            return precipitationChanceText
        }

        let label: String
        switch value {
        case 0:
            label = String(localized: "No rain")
        case 1...30:
            label = String(localized: "Slight chance")
        case 31...60:
            label = String(localized: "Possible rain")
        default:
            label = String(localized: "Likely rain")
        }

        return "\(value)% • \(label)"
    }
}
