import SwiftUI
import MapKit

/// Map pane inside Matches (not its own tab). Pins are filtered games for the selected day.
struct SessionsMapView: View {
    let games: [GameResponse]
    let origin: CLLocationCoordinate2D
    @ObservedObject var location: LocationPermissionService
    @State private var position: MapCameraPosition = .region(Self.bayAreaRegion)
    @State private var selected: GameResponse?

    private static let bayAreaRegion = MKCoordinateRegion(
        center: MatchesViewModel.bayAreaOrigin,
        span: MKCoordinateSpan(latitudeDelta: 0.55, longitudeDelta: 0.55)
    )

    var body: some View {
        VStack(spacing: 12) {
            mapCard
            if let game = selected {
                NavigationLink {
                    GameDetailView(gameID: game.id)
                } label: {
                    selectedRow(game)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .onAppear {
            BootLogger.step("map.appear — requesting location (deferred from launch)")
            location.requestWhenInUseIfNeeded()
            if selected == nil {
                selected = games.first
            }
        }
        .onChange(of: games) { _, newGames in
            if let selected, newGames.contains(where: { $0.id == selected.id }) { return }
            self.selected = newGames.first
        }
        .onChange(of: location.lastLocation?.latitude) { _, _ in
            if let coord = location.lastLocation {
                position = .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
                    )
                )
            }
        }
    }

    private var mapCard: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                ForEach(games) { game in
                    Annotation(game.title, coordinate: game.coordinate) {
                        Button {
                            selected = game
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 10, weight: .bold))
                                Text(game.distanceChip(from: origin))
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(selected?.id == game.id ? AppTheme.primaryForeground : AppTheme.foreground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                selected?.id == game.id ? AppTheme.gold : AppTheme.background.opacity(0.92),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().stroke(AppTheme.border, lineWidth: selected?.id == game.id ? 0 : 1)
                            )
                            .shadow(
                                color: selected?.id == game.id ? AppTheme.gold.opacity(0.45) : .clear,
                                radius: 8
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                if let user = location.lastLocation {
                    Annotation(L10n.mapYou, coordinate: user) {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(AppTheme.foreground)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(AppTheme.background, lineWidth: 2))
                            Text(L10n.mapYou)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(AppTheme.muted)
                                .textCase(.uppercase)
                                .tracking(1)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))

            if location.lastLocation == nil {
                locationPrompt
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 360)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var locationPrompt: some View {
        VStack(spacing: 8) {
            Button {
                location.requestWhenInUseIfNeeded()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(locationPromptTitle)
                        .font(.system(size: 14, weight: .bold))
                        .textCase(.uppercase)
                        .tracking(-0.3)
                }
                .foregroundStyle(AppTheme.primaryForeground)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(AppTheme.gold, in: Capsule())
                .shadow(color: AppTheme.gold.opacity(0.45), radius: 12)
            }
            .buttonStyle(ATWPressScaleStyle())
            Text(L10n.mapLocationHelp)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
                .textCase(.uppercase)
                .tracking(1)
        }
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [AppTheme.background.opacity(0), AppTheme.background.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var locationPromptTitle: String {
        switch location.authorization {
        case .denied, .restricted:
            return L10n.mapLocationDenied
        default:
            return L10n.mapTurnOnLocation
        }
    }

    private func selectedRow(_ game: GameResponse) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(AppTheme.cardTitleFont)
                    .italic()
                    .foregroundStyle(AppTheme.foreground)
                    .textCase(.uppercase)
                    .lineLimit(1)
                Text("\(game.venue) · \(game.shortKickoffLabel)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(L10n.mapViewGame)
                .font(.system(size: 14, weight: .bold))
                .italic()
                .foregroundStyle(AppTheme.primaryForeground)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
        }
        .padding(16)
        .background(
            AppTheme.card,
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

extension GameResponse {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
