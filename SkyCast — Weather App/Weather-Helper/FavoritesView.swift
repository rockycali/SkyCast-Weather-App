
import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: WeatherViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favorites.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)

                        Text("No Favorites Yet")
                            .font(.title3.weight(.semibold))

                        Text("Saved cities will appear here.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.favorites) { favorite in
                            Button {
                                Task {
                                    await viewModel.loadFavorite(favorite)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(favorite.name)
                                        .font(.headline)

                                    if !favorite.country.isEmpty {
                                        Text(favorite.country)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: viewModel.removeFavorite)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Favorites")
        }
    }
}
#Preview {
    FavoritesView(viewModel: WeatherViewModel())
}
