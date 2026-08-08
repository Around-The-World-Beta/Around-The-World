import SwiftUI

/// Main Matches dashboard — live API browse (open spots only, Bay Area).
struct MatchesDashboardView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @EnvironmentObject private var languageStore: LanguageStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                LoadableContent(
                    state: viewModel.state,
                    loadingMessage: L10n.loadingMatches,
                    emptyTitle: L10n.emptyMatchesTitle,
                    emptyMessage: L10n.emptyMatchesMessage,
                    emptySystemImage: "sportscourt",
                    onRetry: { Task { await viewModel.load(force: true) } }
                ) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            header

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
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .refreshable {
                        await viewModel.load(force: true)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandHeader(compact: true)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(AppTheme.gold)
                    }
                    .accessibilityLabel(L10n.tabSettings)
                }
            }
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .atwScreenBackground()
        .id(languageStore.language)
        .task {
            BootLogger.step("matches.dashboard.task")
            if viewModel.state == .idle {
                await viewModel.load()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            BrandHeader()
            Text(L10n.heroHeadline)
                .font(AppTheme.displayFont)
                .foregroundStyle(AppTheme.foreground)
                .textCase(.uppercase)
            Text(L10n.heroSubtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.top, 8)
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
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.foreground)
                    .textCase(.uppercase)
                Spacer()
                Text(L10n.availableCount(count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
            }

            if games.isEmpty {
                Text(emptyLabel)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(
                        AppTheme.card,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                            .foregroundStyle(AppTheme.border)
                    )
            } else {
                ForEach(games) { game in
                    NavigationLink {
                        GameDetailView(gameID: game.id)
                    } label: {
                        GameCardView(game: game)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
