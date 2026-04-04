import SwiftUI

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor.white.withAlphaComponent(0.06)
            } else {
                return UIColor.white.withAlphaComponent(0.12)
            }
        }
        appearance.shadowColor = .clear

        let normalIconColor = UIColor.white.withAlphaComponent(0.56)
        let selectedIconColor = UIColor.white.withAlphaComponent(0.92)

        appearance.stackedLayoutAppearance.normal.iconColor = normalIconColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalIconColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)

        appearance.stackedLayoutAppearance.selected.iconColor = selectedIconColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedIconColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)

        appearance.inlineLayoutAppearance.normal.iconColor = normalIconColor
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalIconColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        appearance.inlineLayoutAppearance.selected.iconColor = selectedIconColor
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedIconColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        appearance.compactInlineLayoutAppearance.normal.iconColor = normalIconColor
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalIconColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        appearance.compactInlineLayoutAppearance.selected.iconColor = selectedIconColor
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedIconColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().itemPositioning = .centered
    }
    @StateObject private var viewModel = WeatherViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            CitiesView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Cities", systemImage: "star")
                }
                .tag(1)

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
    }
}
