import SwiftUI
import MapKit

/// Native MapKit browse of open Bay Area sessions (roster-derived visibility).
struct SessionsMapView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @StateObject private var location = LocationPermissionService()
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.55, longitudeDelta: 0.55)
        )
    )
    @State private var selected: GameResponse?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                switch viewModel.state {
                case .idle, .loading:
                    LoadingStateView(message: L10n.loadingMatches)
                case .failed(let message):
                    ErrorStateView(message: message) {
                        Task { await viewModel.load(force: true) }
                    }
                case .empty:
                    EmptyStateView(
                        title: L10n.emptyMapTitle,
                        message: L10n.emptyMapMessage,
                        systemImage: "map"
                    )
                case .loaded:
                    mapContent
                }
            }
            .navigationTitle(L10n.mapTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .atwScreenBackground()
        .task {
            BootLogger.step("map.appear — requesting location (deferred from launch)")
            location.requestWhenInUseIfNeeded()
            await viewModel.load()
        }
        .onChange(of: location.lastLocation?.latitude) { _, _ in
            if let coord = location.lastLocation {
                position = .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
                    )
                )
            }
        }
        .sheet(item: $selected) { game in
            NavigationStack {
                GameDetailView(gameID: game.id)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var mapContent: some View {
        Map(position: $position) {
            ForEach(viewModel.games) { game in
                Annotation(game.title, coordinate: game.coordinate) {
                    Button {
                        selected = game
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "sportscourt.fill")
                                .font(.title2)
                                .foregroundStyle(AppTheme.gold)
                            Text(game.spotsLeft > 0 ? "\(game.spotsLeft)" : "!")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppTheme.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.gold, in: Capsule())
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            if let user = location.lastLocation {
                Annotation("You", coordinate: user) {
                    Image(systemName: "location.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .ignoresSafeArea(edges: .bottom)
    }
}

extension GameResponse {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
