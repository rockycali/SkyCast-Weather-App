import SwiftUI

struct ContentView: View {

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        // 🌫 Glass blur
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)

        // 🎨 Transparent background
        appearance.backgroundColor = UIColor.clear

        // 🎯 Icon colors
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
}
