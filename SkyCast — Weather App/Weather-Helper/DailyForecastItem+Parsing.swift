import Foundation

// MARK: - Temperature Parsing
extension DailyForecastItem {
    var numericMinTemperature: Double? {
        Self.numericTemperature(from: minText)
    }

    var numericMaxTemperature: Double? {
        Self.numericTemperature(from: maxText)
    }

    private static func numericTemperature(from value: String) -> Double? {
        let cleanedValue = value
            .replacingOccurrences(of: "°", with: "")
            .replacingOccurrences(of: "C", with: "")
            .replacingOccurrences(of: "F", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(cleanedValue)
    }
}
