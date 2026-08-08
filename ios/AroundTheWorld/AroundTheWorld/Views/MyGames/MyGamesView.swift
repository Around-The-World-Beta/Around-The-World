import SwiftUI

/// User's signed-up sessions — includes fully booked games (browse hides those).
struct MyGamesView: View {
    @StateObject private var viewModel = MyGamesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                LoadableContent(
                    state: viewModel.state,
                    loadingMessage: L10n.loadingMatches,
                    emptyTitle: L10n.emptyMyGamesTitle,
                    emptyMessage: L10n.emptyMyGamesMessage,
                    emptySystemImage: "calendar",
                    onRetry: { Task { await viewModel.load(force: true) } }
                ) {
                    List(viewModel.games) { game in
                        NavigationLink {
                            GameDetailView(gameID: game.id, currentUserID: viewModel.currentUserID)
                        } label: {
                            GameCardView(game: game)
                        }
                        .listRowBackground(AppTheme.card)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { await viewModel.load(force: true) }
                }
            }
            .navigationTitle(L10n.tabMyGames)
            .navigationBarTitleDisplayMode(.inline)
        }
        .atwScreenBackground()
        .task { await viewModel.load() }
    }
}

@MainActor
final class MyGamesViewModel: ObservableObject {
    @Published private(set) var state: LoadState = .idle
    @Published private(set) var games: [GameResponse] = []

    /// Set after auth. Without it, My Games shows a clear empty state (no fake rows).
    var currentUserID: UUID?

    private let api = AroundTheWorldAPI()

    func load(force: Bool = false) async {
        if case .loading = state, !force { return }
        guard let userID = currentUserID else {
            games = []
            state = .empty
            return
        }

        state = .loading
        do {
            let fetched = try await api.listMyGames(userId: userID)
            games = fetched
            state = fetched.isEmpty ? .empty : .loaded
        } catch {
            games = []
            state = .failed(error.localizedDescription)
        }
    }
}
