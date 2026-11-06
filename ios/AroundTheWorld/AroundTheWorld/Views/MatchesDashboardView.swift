import SwiftUI
import CoreLocation

/// Matches tab — 7-day strip, List/Map toggle, filters + sort, Free/Paid lists.
struct MatchesDashboardView: View {
    @ObservedObject var viewModel: MatchesViewModel
    @ObservedObject var location: LocationPermissionService
    @Binding var showFilters: Bool
    @EnvironmentObject private var languageStore: LanguageStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: L10n.tabMatches, subtitle: L10n.matchesSubtitle)
                    .background(AppTheme.background.opacity(0.90))

                viewToggle
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                dateStrip
                filtersSortBar
                mainBody
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .atwScreenBackground()
        .id(languageStore.language)
        .task {
            BootLogger.step("matches.dashboard.task")
            if viewModel.state == .idle {
                await viewModel.load()
            }
        }
        .onChange(of: location.lastLocation?.latitude) { _, _ in
            if let coord = location.lastLocation {
                viewModel.origin = coord
            }
        }
        .onChange(of: viewModel.viewMode) { _, mode in
            if mode == .map {
                location.requestWhenInUseIfNeeded()
            }
        }
    }

    private var viewToggle: some View {
        HStack(spacing: 0) {
            toggleButton(.list, title: L10n.viewList, systemImage: "list.bullet")
            toggleButton(.map, title: L10n.viewMap, systemImage: "map")
        }
        .padding(4)
        .background(AppTheme.secondaryFill, in: Capsule())
        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
    }

    private func toggleButton(_ mode: MatchViewMode, title: String, systemImage: String) -> some View {
        let active = viewModel.viewMode == mode
        return Button {
            viewModel.viewMode = mode
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(-0.2)
            }
            .foregroundStyle(active ? AppTheme.primaryForeground : AppTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(active ? AppTheme.gold : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var dateStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.week.enumerated()), id: \.element.id) { index, day in
                    let active = index == viewModel.selectedDayIndex
                    Button {
                        viewModel.selectedDayIndex = index
                    } label: {
                        VStack(spacing: 2) {
                            Text(day.weekday.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.2)
                            Text("\(day.dayNumber)")
                                .font(.system(size: 18, weight: .bold))
                            Text(day.isToday ? L10n.dateToday.uppercased() : day.month.uppercased())
                                .font(.system(size: 9, weight: .semibold))
                                .opacity(active ? 0.90 : 1)
                                .foregroundStyle(active ? AppTheme.primaryForeground : AppTheme.muted)
                        }
                        .foregroundStyle(active ? AppTheme.primaryForeground : AppTheme.foreground)
                        .frame(minWidth: 56)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(
                            active ? AppTheme.gold : AppTheme.card,
                            in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                .stroke(active ? AppTheme.gold : AppTheme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(AppTheme.background)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.border).frame(height: 1)
        }
        .overlay(alignment: .top) {
            Rectangle().fill(AppTheme.border).frame(height: 1)
        }
    }

    private var filtersSortBar: some View {
        HStack {
            Button {
                showFilters = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                    Text(L10n.filtersTitle)
                        .font(.system(size: 12, weight: .semibold))
                    if viewModel.activeFilterCount > 0 {
                        Text("\(viewModel.activeFilterCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.primaryForeground)
                            .frame(width: 20, height: 20)
                            .background(AppTheme.gold, in: Circle())
                    }
                }
                .foregroundStyle(AppTheme.foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.card, in: Capsule())
                .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Menu {
                ForEach(MatchSortKey.allCases) { key in
                    Button(key.label) {
                        viewModel.sort = key
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14, weight: .semibold))
                    Text(L10n.sortLabel)
                        .font(.system(size: 12, weight: .semibold))
                    Text(viewModel.sort.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.gold)
                }
                .foregroundStyle(AppTheme.foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.card, in: Capsule())
                .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.border).frame(height: 1)
        }
    }

    @ViewBuilder
    private var mainBody: some View {
        switch viewModel.state {
        case .idle:
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loading:
            LoadingStateView(message: L10n.loadingMatches)
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await viewModel.load(force: true) }
            }
        case .empty:
            EmptyStateView(
                title: L10n.emptyMatchesTitle,
                message: L10n.emptyMatchesMessage,
                systemImage: "trophy"
            )
        case .loaded:
            if viewModel.viewMode == .list {
                listBody
            } else {
                SessionsMapView(
                    games: viewModel.filteredGames,
                    origin: viewModel.origin,
                    location: location
                )
            }
        }
    }

    private var listBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                gameSection(
                    title: L10n.freeSessions,
                    count: viewModel.freeGames.count,
                    games: viewModel.freeGames,
                    emptyLabel: L10n.noFreeSessions
                )
                gameSection(
                    title: L10n.paidSessions,
                    count: viewModel.paidGames.count,
                    games: viewModel.paidGames,
                    emptyLabel: L10n.noPaidSessions
                )
            }
            .padding(.top, 16)
            .padding(.bottom, 80)
        }
        .refreshable {
            await viewModel.load(force: true)
        }
    }

    private func gameSection(
        title: String,
        count: Int,
        games: [GameResponse],
        emptyLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.foreground)
                    .textCase(.uppercase)
                    .tracking(-0.3)
                Spacer()
                Text(L10n.availableCount(count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.horizontal, 20)

            if games.isEmpty {
                Text(emptyLabel)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(
                        AppTheme.card,
                        in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                            .foregroundStyle(AppTheme.border)
                    )
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 16) {
                    ForEach(games) { game in
                        NavigationLink {
                            GameDetailView(gameID: game.id)
                        } label: {
                            GameCardView(game: game, origin: viewModel.origin)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
