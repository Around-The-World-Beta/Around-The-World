import Foundation
import Combine
import AroundTheWorldKit

/// Fetches the live matches dashboard from the Vapor API via `NetworkManager`.
@MainActor
final class MatchesViewModel: ObservableObject {
    @Published private(set) var state: LoadState = .idle
    @Published private(set) var games: [GameResponse] = []
    @Published private(set) var lastRefreshed: Date?

    private let api: AroundTheWorldAPI

    init(api: AroundTheWorldAPI = AroundTheWorldAPI()) {
        self.api = api
    }

    var freeGames: [GameResponse] {
        games.filter { $0.priceCents == 0 }
    }

    var paidGames: [GameResponse] {
        games.filter { $0.priceCents > 0 }
    }

    func load(force: Bool = false) async {
        if case .loading = state, !force { return }

        state = .loading
        do {
            let fetched = try await api.listGames()
            games = fetched
            lastRefreshed = Date()
            state = fetched.isEmpty ? .empty : .loaded
        } catch {
            games = []
            state = .failed(error.localizedDescription)
        }
    }
}
