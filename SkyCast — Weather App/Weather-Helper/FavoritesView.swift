import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.6), value: viewModel.weather?.current.weatherCode ?? -1)

                Group {
                    if viewModel.favorites.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "star.slash")
                                .font(.system(size: 44))
                                .foregroundStyle(.white.opacity(0.85))

                            Text("No Favorites Yet")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)

                            Text("Saved cities will appear here.")
                                .foregroundStyle(.white.opacity(0.78))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 18) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Your Favorite Cities")
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(.white)

                                    Text("Tap a city to open it on Home.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.78))
                                }

                                ForEach(viewModel.favorites) { favorite in
                                    HStack(spacing: 12) {
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            Task {
                                                await viewModel.loadFavorite(favorite)
                                                selectedTab = 0
                                            }
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: "star.fill")
                                                    .foregroundStyle(.yellow)
                                                    .font(.headline)
                                                    .frame(width: 38, height: 38)
                                                    .background(.white.opacity(0.10))
                                                    .clipShape(Circle())

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(favorite.name)
                                                        .font(.headline)
                                                        .foregroundStyle(.white)

                                                    if !favorite.country.isEmpty {
                                                        Text(favorite.country)
                                                            .font(.subheadline)
                                                            .foregroundStyle(.white.opacity(0.78))
                                                    }
                                                }

                                                Spacer()

                                                Image(systemName: "chevron.right")
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(.white.opacity(0.55))
                                            }
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            viewModel.removeFavorite(favorite)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.headline)
                                                .foregroundStyle(.white.opacity(0.9))
                                                .frame(width: 36, height: 36)
                                                .background(.white.opacity(0.12))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .glassCard(cornerRadius: 22)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 28)
                        }
                    }
                }
            }
            .navigationTitle("")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private var backgroundGradient: LinearGradient {
        guard let weather = viewModel.weather else {
            return LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .top,
                endPoint: .bottom
            )
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
}

#Preview {
    FavoritesView(viewModel: WeatherViewModel(), selectedTab: .constant(1))
}

private struct GlassCardModifier: ViewModifier {
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
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
