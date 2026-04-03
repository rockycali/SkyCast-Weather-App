import SwiftUI

struct CitiesView: View {
    private enum UI {
        static let pageSpacing: CGFloat = 16
        static let sectionSpacing: CGFloat = 16
        static let headerSpacing: CGFloat = 8
        static let contentHorizontalPadding: CGFloat = 20
        static let contentTopPadding: CGFloat = 22
        static let contentBottomPadding: CGFloat = 32
        static let safeAreaTopPadding: CGFloat = 6
        static let cardCornerRadius: CGFloat = 22
        static let rowHorizontalPadding: CGFloat = 18
        static let rowVerticalPadding: CGFloat = 15
        static let subtitleOpacity: CGFloat = 0.78
        static let secondaryIconOpacity: CGFloat = 0.55
    }
    private enum L10n {
        static let noCitiesYet: LocalizedStringKey = "No Cities Yet"
        static let savedCitiesWillAppearHere: LocalizedStringKey = "Saved cities will appear here."
        static let yourCities: LocalizedStringKey = "Your Cities"
        static let tapCityToOpenHome: LocalizedStringKey = "Tap a city to open it on Home."
        static let currentLocation: LocalizedStringKey = "Current Location"
        static let savedCities: LocalizedStringKey = "Saved Cities"
        static let searchCities: LocalizedStringKey = "Search cities"
        static let searchResults: LocalizedStringKey = "Search Results"
        static let noMatchingCities: LocalizedStringKey = "No matching cities"
        static let tryDifferentSearch: LocalizedStringKey = "Try a different city or country name."
    }

    @ObservedObject var viewModel: WeatherViewModel
    @Binding var selectedTab: Int
    @AppStorage("temperatureUnit") private var temperatureUnit = "C"
    @State private var searchText = ""
    @State private var liveSearchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: UI.pageSpacing) {
                        VStack(alignment: .leading, spacing: UI.headerSpacing) {
                            Text(L10n.yourCities)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)

                            Text(L10n.tapCityToOpenHome)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(UI.subtitleOpacity))
                        }

                        searchBar

                        if isSearching {
                            searchResultsSection
                        } else {
                            currentLocationRow
                                .padding(.bottom, 6)

                            if !viewModel.favorites.isEmpty {
                                Text(L10n.savedCities)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(UI.subtitleOpacity))
                                    .padding(.top, 2)
                                    .padding(.leading, 2)
                            }

                            if viewModel.favorites.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "star.slash")
                                        .font(.system(size: 44))
                                        .foregroundStyle(.white.opacity(0.88))

                                    Text(L10n.noCitiesYet)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.white)

                                    Text(L10n.savedCitiesWillAppearHere)
                                        .foregroundStyle(.white.opacity(UI.subtitleOpacity))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                                .glassCard(cornerRadius: UI.cardCornerRadius)
                            } else {
                                ForEach(filteredFavorites.indices, id: \.self) { index in
                                    let favorite = filteredFavorites[index]
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
                                                            .foregroundStyle(.white.opacity(UI.subtitleOpacity))
                                                    }
                                                }

                                                Spacer()

                                                if let snapshot = viewModel.favoriteWeatherSnapshots[favorite.id] {
                                                    HStack(spacing: 10) {
                                                        Image(systemName: weatherSymbolName(for: snapshot.weatherCode, isNight: snapshot.isNight))
                                                            .font(.system(size: 17, weight: .medium))
                                                            .foregroundStyle(.white.opacity(0.88))
                                                            .frame(width: 18)

                                                        Text("\(snapshot.temperature)°")
                                                            .font(.subheadline.weight(.semibold))
                                                            .foregroundStyle(.white.opacity(0.84))
                                                            .frame(minWidth: 34, alignment: .leading)
                                                    }
                                                }

                                                Image(systemName: "chevron.right")
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(.white.opacity(UI.secondaryIconOpacity))
                                            }
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, UI.rowHorizontalPadding)
                                    .padding(.vertical, UI.rowVerticalPadding)
                                    .glassCard(cornerRadius: UI.cardCornerRadius)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            viewModel.removeFavorite(favorite)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, UI.contentHorizontalPadding)
                    .padding(.top, UI.contentTopPadding)
                    .padding(.bottom, UI.contentBottomPadding)
                    .id(temperatureUnit)
                }
                .safeAreaPadding(.top, UI.safeAreaTopPadding)
                .task {
                    await viewModel.refreshFavoriteWeatherSnapshots()
                }
            }
            .navigationTitle("")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private var filteredFavorites: [FavoriteCity] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return viewModel.favorites
        }

        return viewModel.favorites.filter { favorite in
            favorite.name.localizedCaseInsensitiveContains(query) ||
            favorite.country.localizedCaseInsensitiveContains(query)
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var visibleSearchResults: [LocationResult] {
        Array(viewModel.citySearchResults.prefix(6))
    }

    private var isSearchLoading: Bool {
        isSearching && liveSearchTask != nil && viewModel.citySearchResults.isEmpty
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.78))

            TextField(
                "",
                text: $searchText,
                prompt: Text(L10n.searchCities).foregroundStyle(.white.opacity(0.6))
            )
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .foregroundStyle(.white)
            .tint(.white)
            .onSubmit {
                Task {
                    await searchCity()
                }
            }
            .onChange(of: searchText) { _, newValue in
                liveSearchTask?.cancel()

                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 2 else {
                    Task { @MainActor in
                        viewModel.citySearchResults = []
                    }
                    return
                }

                liveSearchTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }
                    await viewModel.searchCities(for: trimmed)
                }
            }

            // Insert clear button if searchText is not empty
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    liveSearchTask?.cancel()
                    viewModel.citySearchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Button {
                Task {
                    await searchCity()
                }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(.white.opacity(0.14))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func searchCity() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        await viewModel.searchCity(named: trimmed)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        if viewModel.errorMessage == nil {
            searchText = ""
            liveSearchTask?.cancel()
            selectedTab = 0
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.searchResults)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.96))
                .padding(.leading, 2)

            // Insert loading state at the top of results section
            if isSearchLoading {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Searching...")
                        .foregroundStyle(.white.opacity(0.8))
                        .font(.subheadline)
                }
                .padding()
            }

            // Show empty state only if not searching and results are empty
            if !isSearchLoading && viewModel.citySearchResults.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(UI.subtitleOpacity))

                    Text(L10n.noMatchingCities)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(L10n.tryDifferentSearch)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.74))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .glassCard(cornerRadius: UI.cardCornerRadius)
            } else if !viewModel.citySearchResults.isEmpty {
                VStack(spacing: 10) {
                    ForEach(visibleSearchResults, id: \.id) { result in
                        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let isStrongTopMatch = result.name.lowercased().hasPrefix(trimmedQuery.lowercased())
                        let isTopResult = result.id == visibleSearchResults.first?.id && isStrongTopMatch
                        HStack(spacing: 12) {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                Task {
                                    await viewModel.loadLocationResult(result)
                                    searchText = ""
                                    liveSearchTask?.cancel()
                                    selectedTab = 0
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass.circle.fill")
                                        .foregroundStyle(.white.opacity(0.9))
                                        .font(.headline)
                                        .frame(width: 38, height: 38)
                                        .background(.white.opacity(0.10))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text(result.name)
                                                .font(.headline)
                                                .foregroundStyle(.white)

                                            if isTopResult {
                                                Text("Top Result")
                                                    .font(.caption2.bold())
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(.ultraThinMaterial)
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(.white.opacity(0.2), lineWidth: 0.5)
                                                    )
                                                    .clipShape(Capsule())
                                            }
                                        }

                                        Text(result.displayName)
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.72))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }

                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            let favorite = FavoriteCity(
                                name: result.name,
                                country: result.country,
                                latitude: result.latitude,
                                longitude: result.longitude
                            )
                            let isSaved = viewModel.favorites.contains(where: { $0.id == favorite.id })

                            Button {
                                guard !isSaved else { return }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.addFavorite(favorite)
                            } label: {
                                Image(systemName: isSaved ? "star.fill" : "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(isSaved ? .yellow : .white.opacity(0.92))
                                    .frame(width: 36, height: 36)
                                    .background(.white.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(isSaved)
                            .opacity(isSaved ? 0.9 : 1)
                        }
                        .padding(.horizontal, UI.rowHorizontalPadding)
                        .padding(.vertical, UI.rowVerticalPadding)
                        .glassCard(cornerRadius: UI.cardCornerRadius)
                    }
                }
            }
        }
    }

    private func weatherSymbolName(for weatherCode: Int, isNight: Bool) -> String {
        switch weatherCode {
        case 0:
            return isNight ? "moon.stars.fill" : "sun.max.fill"
        case 1, 2:
            return isNight ? "cloud.moon.fill" : "cloud.sun.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51...67:
            return "cloud.rain.fill"
        case 71...77:
            return "cloud.snow.fill"
        case 95...99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
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

    private var currentLocationRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.requestLocation()
            selectedTab = 0
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .foregroundStyle(.white)
                    .font(.headline)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.16))
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.22), lineWidth: 1)
                    }
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.currentLocation)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Open weather for your location")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(UI.subtitleOpacity))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(UI.secondaryIconOpacity))
            }
            .padding(.horizontal, UI.rowHorizontalPadding)
            .padding(.vertical, UI.rowVerticalPadding)
            .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: UI.cardCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: UI.cardCornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.20), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CitiesView(viewModel: WeatherViewModel(), selectedTab: .constant(1))
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

