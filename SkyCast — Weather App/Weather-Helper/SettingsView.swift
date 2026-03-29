import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @AppStorage("temperatureUnit") private var temperatureUnit = "C"

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.6), value: viewModel.weather?.current.weatherCode ?? -1)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Settings")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.white)

                            Text("Customize app preferences and information.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.78))
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
                                .foregroundStyle(.white.opacity(0.92))
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                HStack(spacing: 14) {
                                    Image(systemName: "thermometer")
                                        .foregroundStyle(.white)
                                        .font(.title3)
                                        .frame(width: 30)

                                    Text("Temperature Units")
                                        .foregroundStyle(.white)
                                        .font(.headline)

                                    Spacer()

                                    Picker("Temperature Units", selection: $temperatureUnit) {
                                        Text("°C").tag("C")
                                        Text("°F").tag("F")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 120)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)

                                Divider()
                                    .overlay(.white.opacity(0.10))
                                    .padding(.leading, 56)

                                settingsRow(
                                    title: "Language",
                                    value: "Coming Soon",
                                    systemImage: "globe"
                                )
                            }
                            .padding(.vertical, 6)
                            .glassCard(cornerRadius: 24)
                        }

                        settingsCard(
                            title: "About",
                            rows: [
                                SettingRowData(title: "Built With", value: "SwiftUI + MVVM", systemImage: "hammer.fill"),
                                SettingRowData(title: "Weather API", value: "Open-Meteo", systemImage: "cloud.sun.fill")
                            ]
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
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
                    colors: [Color(red: 0.03, green: 0.05, blue: 0.15), Color(red: 0.10, green: 0.16, blue: 0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case 1...3:
                return LinearGradient(
                    colors: [Color(red: 0.06, green: 0.08, blue: 0.18), Color(red: 0.14, green: 0.18, blue: 0.30)],
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
                    colors: [Color(red: 0.04, green: 0.06, blue: 0.14), Color(red: 0.10, green: 0.14, blue: 0.24)],
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
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    settingsRow(title: row.title, value: row.value, systemImage: row.systemImage)

                    if index < rows.count - 1 {
                        Divider()
                            .overlay(.white.opacity(0.10))
                            .padding(.leading, 56)
                    }
                }
            }
            .padding(.vertical, 6)
            .glassCard(cornerRadius: 24)
        }
    }

    @ViewBuilder
    private func settingsRow(title: LocalizedStringKey, value: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .foregroundStyle(.white)
                .font(.title3)
                .frame(width: 30)

            Text(title)
                .foregroundStyle(.white)
                .font(.headline)

            Spacer()

            Text(value)
                .foregroundStyle(.white.opacity(0.72))
                .font(.headline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

private struct SettingRowData {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String
}

private struct SettingsGlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.16 : 0.07), radius: 12, x: 0, y: 6)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(colorScheme == .dark ? 0.16 : 0.24), lineWidth: 1)
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
