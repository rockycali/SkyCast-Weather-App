import SwiftUI

struct SettingsView: View {
    private enum UI {
        static let pageSpacing: CGFloat = 18
        static let sectionSpacing: CGFloat = 16
        static let headerSpacing: CGFloat = 8
        static let contentHorizontalPadding: CGFloat = 20
        static let contentTopPadding: CGFloat = 22
        static let contentBottomPadding: CGFloat = 32
        static let safeAreaTopPadding: CGFloat = 6
        static let sectionTitleLeadingInset: CGFloat = 2
        static let cardCornerRadius: CGFloat = 22
        static let rowHorizontalPadding: CGFloat = 18
        static let rowVerticalPadding: CGFloat = 15
        static let subtitleOpacity: CGFloat = 0.82
        static let sectionTitleOpacity: CGFloat = 0.90
        static let valueOpacity: CGFloat = 0.65
        static let valueNightOpacity: CGFloat = 0.72
        static let dividerOpacity: CGFloat = 0.10
    }

    @ObservedObject var viewModel: WeatherViewModel
    @AppStorage("temperatureUnit") private var temperatureUnit = "C"

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.6), value: viewModel.weather?.current.weatherCode ?? -1)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: UI.pageSpacing) {
                        VStack(alignment: .leading, spacing: UI.headerSpacing) {
                            Text("Settings")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.white.opacity(viewModel.isNight ? 0.96 : 1.0))

                            Text("Customize app preferences and information.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(viewModel.isNight ? 0.86 : UI.subtitleOpacity))
                        }

                        settingsCard(
                            title: "App",
                            rows: [
                                SettingRowData(title: "App Name", value: "ClimaFlow", systemImage: "app.fill"),
                                SettingRowData(title: "Version", value: "1.0", systemImage: "info.circle.fill")
                            ]
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Preferences")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white.opacity(viewModel.isNight ? 0.82 : UI.sectionTitleOpacity))
                                .padding(.leading, UI.sectionTitleLeadingInset)

                            VStack(spacing: 0) {
                                HStack(spacing: 14) {
                                    Image(systemName: "thermometer")
                                        .foregroundStyle(.white.opacity(viewModel.isNight ? 0.85 : 1.0))
                                        .font(.title3)
                                        .frame(width: 30)

                                    Text("Temperature Units")
                                        .foregroundStyle(.white.opacity(viewModel.isNight ? 0.92 : 1.0))
                                        .font(.headline)

                                    Spacer()

                                    Picker("Temperature Units", selection: $temperatureUnit) {
                                        Text("°C").tag("C")
                                        Text("°F").tag("F")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 120)
                                    .tint(.white)
                                }
                                .padding(.horizontal, UI.rowHorizontalPadding)
                                .padding(.vertical, UI.rowVerticalPadding)

                                Divider()
                                    .overlay(.white.opacity(UI.dividerOpacity))
                                    .padding(.leading, 56)

                                settingsRow(
                                    title: "Language",
                                    value: "Coming Soon",
                                    systemImage: "globe"
                                )
                                .opacity(0.85)
                            }
                            .padding(.vertical, 6)
                            .glassCard(cornerRadius: UI.cardCornerRadius)
                        }

                        settingsCard(
                            title: "About",
                            rows: [
                                SettingRowData(title: "Built With", value: "SwiftUI + MVVM", systemImage: "hammer.fill"),
                                SettingRowData(title: "Weather API", value: "Open-Meteo", systemImage: "cloud.sun.fill")
                            ]
                        )
                    }
                    .padding(.horizontal, UI.contentHorizontalPadding)
                    .padding(.top, UI.contentTopPadding)
                    .padding(.bottom, UI.contentBottomPadding)
                }
                .safeAreaPadding(.top, UI.safeAreaTopPadding)
            }
            .navigationTitle("")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private var backgroundGradient: LinearGradient {
        guard let weather = viewModel.weather else {
            return LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
        }

        if viewModel.isNight {
            switch weather.current.weatherCode {
            case 0:
                return LinearGradient(
                    colors: [Color(red: 0.02, green: 0.05, blue: 0.14), Color(red: 0.08, green: 0.13, blue: 0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case 1...3:
                return LinearGradient(
                    colors: [Color(red: 0.05, green: 0.09, blue: 0.18), Color(red: 0.11, green: 0.16, blue: 0.30)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case 45, 48:
                return LinearGradient(
                    colors: [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.18, green: 0.18, blue: 0.22)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case 51...67:
                return LinearGradient(
                    colors: [Color(red: 0.05, green: 0.08, blue: 0.16), Color(red: 0.11, green: 0.16, blue: 0.26)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case 71...77:
                return LinearGradient(
                    colors: [Color(red: 0.08, green: 0.12, blue: 0.22), Color(red: 0.18, green: 0.20, blue: 0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case 95...99:
                return LinearGradient(
                    colors: [Color.black, Color(red: 0.20, green: 0.10, blue: 0.30)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            default:
                return LinearGradient(
                    colors: [Color(red: 0.02, green: 0.06, blue: 0.14), Color(red: 0.08, green: 0.13, blue: 0.25)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }

        switch weather.current.weatherCode {
        case 0:
            return LinearGradient(colors: [.blue, .yellow], startPoint: .top, endPoint: .bottom)
        case 1...3:
            return LinearGradient(colors: [.gray, .blue], startPoint: .top, endPoint: .bottom)
        case 45, 48:
            return LinearGradient(colors: [.gray.opacity(0.8), .black], startPoint: .top, endPoint: .bottom)
        case 51...67:
            return LinearGradient(colors: [.blue, .gray], startPoint: .top, endPoint: .bottom)
        case 71...77:
            return LinearGradient(colors: [.white, .blue], startPoint: .top, endPoint: .bottom)
        case 95...99:
            return LinearGradient(colors: [.black, .purple], startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
        }
    }

    @ViewBuilder
    private func settingsCard(title: LocalizedStringKey, rows: [SettingRowData]) -> some View {
        VStack(alignment: .leading, spacing: UI.sectionSpacing) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(viewModel.isNight ? 0.82 : UI.sectionTitleOpacity))
                .padding(.leading, UI.sectionTitleLeadingInset)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    settingsRow(title: row.title, value: row.value, systemImage: row.systemImage)

                    if index < rows.count - 1 {
                        Divider()
                            .overlay(.white.opacity(UI.dividerOpacity))
                            .padding(.leading, 56)
                    }
                }
            }
            .padding(.vertical, 6)
            .glassCard(cornerRadius: UI.cardCornerRadius)
        }
    }

    @ViewBuilder
    private func settingsRow(title: LocalizedStringKey, value: LocalizedStringKey, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .foregroundStyle(.white.opacity(viewModel.isNight ? 0.85 : 1.0))
                .font(.title3)
                .frame(width: 30)

            Text(title)
                .foregroundStyle(.white.opacity(viewModel.isNight ? 0.92 : 1.0))
                .font(.headline)

            Spacer()

            Text(value)
                .foregroundStyle(.white.opacity(viewModel.isNight ? UI.valueNightOpacity : UI.valueOpacity))
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, UI.rowHorizontalPadding)
        .padding(.vertical, UI.rowVerticalPadding)
    }
}

private struct SettingRowData {
    let title: LocalizedStringKey
    let value: LocalizedStringKey
    let systemImage: String
}

private struct SettingsGlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                ZStack {
                    shape
                        .fill(.ultraThinMaterial)

                    shape
                        .fill(colorScheme == .dark ? Color.black.opacity(0.34) : Color.white.opacity(0.10))
                }
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.24 : 0.07), radius: 14, x: 0, y: 8)
            .overlay {
                shape
                    .stroke(.white.opacity(colorScheme == .dark ? 0.10 : 0.28), lineWidth: 1)
            }
    }
}

private extension View {
    func glassCard(cornerRadius: CGFloat = 22) -> some View {
        modifier(SettingsGlassCardModifier(cornerRadius: cornerRadius))
    }
}

#Preview {
    SettingsView(viewModel: WeatherViewModel())
}
