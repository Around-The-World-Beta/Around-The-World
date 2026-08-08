import SwiftUI

/// Main Matches dashboard — inspired by `src/routes/index.tsx`.
struct MatchesDashboardView: View {
    @StateObject private var viewModel = MatchesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                LoadableContent(
                    state: viewModel.state,
                    loadingMessage: "Loading matches…",
                    emptyTitle: "No matches yet",
                    emptyMessage: "The pitch is quiet. Host a game or pull to refresh when the database has listings.",
                    emptySystemImage: "sportscourt",
                    onRetry: { Task { await viewModel.load(force: true) } }
                ) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            header

                            gameSection(
                                title: "Free Sessions",
                                count: viewModel.freeGames.count,
                                games: viewModel.freeGames,
                                emptyLabel: "No free sessions match"
                            )

                            gameSection(
                                title: "Paid Sessions",
                                count: viewModel.paidGames.count,
                                games: viewModel.paidGames,
                                emptyLabel: "No paid sessions match"
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
                    VStack(spacing: 2) {
                        Text("Matches")
                            .font(.headline.weight(.black))
                            .foregroundStyle(AppTheme.foreground)
                            .textCase(.uppercase)
                        Text("Choose pickup games to attend")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .atwScreenBackground()
        .task {
            if viewModel.state == .idle {
                await viewModel.load()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Find a game")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.foreground)
                .textCase(.uppercase)
            Text("Live listings from the Around The World API.")
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
                Text("\(count) available")
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
