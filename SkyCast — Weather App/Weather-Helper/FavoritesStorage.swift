import Foundation

final class FavoritesStorage {
    private let favoritesKey = "favorite_cities"

    func loadFavorites() -> [FavoriteCity] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([FavoriteCity].self, from: data)
        } catch {
            print("❌ Failed to load favorites: \(error)")
            return []
        }
    }

    func saveFavorites(_ favorites: [FavoriteCity]) {
        do {
            let data = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(data, forKey: favoritesKey)
        } catch {
            print("❌ Failed to save favorites: \(error)")
        }
    }
}
