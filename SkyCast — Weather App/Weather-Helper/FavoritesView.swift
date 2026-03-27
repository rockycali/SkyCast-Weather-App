import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

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
                            VStack(spacing: 14) {
                                ForEach(viewModel.favorites) { favorite in
                                    HStack(spacing: 12) {
                                        Button {
                                            Task {
                                                await viewModel.loadFavorite(favorite)
                                                selectedTab = 0
                                            }
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: "star.fill")
                                                    .foregroundStyle(.yellow)
                                                    .font(.title3)

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
                                    .padding(.vertical, 14)
                                    .glassCard(cornerRadius: 20)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.08, green: 0.12, blue: 0.22), Color(red: 0.18, green: 0.24, blue: 0.40)]
                : [Color.blue, Color.indigo],
            startPoint: .top,
            endPoint: .bottom
        )
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
