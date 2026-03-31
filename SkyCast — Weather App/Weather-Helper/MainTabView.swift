import SwiftUI

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        appearance.backgroundColor = UIColor.clear
        appearance.shadowColor = .clear

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    @StateObject private var viewModel = WeatherViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            CitiesView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Cities", systemImage: "star.fill")
                }
                .tag(1)

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}
