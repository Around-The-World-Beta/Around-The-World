import SwiftUI

/// User's signed-up sessions — includes fully booked games (browse hides those).
struct MyGamesView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = MyGamesViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: L10n.tabMyGames, subtitle: L10n.myGamesSubtitle)

                if session.isRestoring {
                    LoadingStateView(message: L10n.loadingMatches)
                } else if !session.isSignedIn {
                    SignedOutGateView(
                        title: L10n.emptyMyGamesTitle,
                        message: L10n.authMyGamesSignedOut,
                        systemImage: "calendar"
                    )
                } else {
                    LoadableContent(
                        state: viewModel.state,
                        loadingMessage: L10n.loadingMatches,
                        emptyTitle: L10n.emptyMyGamesTitle,
                        emptyMessage: L10n.emptyMyGamesMessage,
                        emptySystemImage: "calendar",
                        onRetry: { Task { await viewModel.load(force: true) } }
                    ) {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(viewModel.games) { game in
                                    NavigationLink {
                                        GameDetailView(gameID: game.id)
                                    } label: {
                                        GameCardView(game: game)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .refreshable { await viewModel.load(force: true) }
                    }
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .atwScreenBackground()
        .task { await viewModel.load() }
        .onChange(of: session.isSignedIn) { _, _ in
            Task { await viewModel.load(force: true) }
        }
    }
}

@MainActor
final class MyGamesViewModel: ObservableObject {
    @Published private(set) var state: LoadState = .idle
    @Published private(set) var games: [GameResponse] = []

    private let api = AroundTheWorldAPI()

    func load(force: Bool = false) async {
        if case .loading = state, !force { return }
        guard SessionStore.shared.isSignedIn else {
            games = []
            state = .empty
            return
        }

        state = .loading
        do {
            let fetched = try await api.listMyGames()
            games = fetched
            state = fetched.isEmpty ? .empty : .loaded
        } catch {
            games = []
            state = .failed(error.localizedDescription)
        }
    }
}
