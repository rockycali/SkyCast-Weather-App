import Foundation

struct FavoriteCity: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double

    init(
        name: String,
        country: String,
        latitude: Double,
        longitude: Double
    ) {
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.id = "\(name.lowercased())-\(country.lowercased())-\(latitude)-\(longitude)"
    }
}
