import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            FavoritesView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}
