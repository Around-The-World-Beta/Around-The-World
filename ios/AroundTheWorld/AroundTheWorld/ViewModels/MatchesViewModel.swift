import Foundation
import Combine

/// Fetches live Bay Area browse listings (open spots only) from the Vapor API.
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

        BootLogger.step("matches.load.start")
        state = .loading
        do {
            let fetched = try await api.listGames(includeFull: false, region: "bay-area")
            games = fetched
            lastRefreshed = Date()
            state = fetched.isEmpty ? .empty : .loaded
            BootLogger.done("matches.load (\(fetched.count) open)")
        } catch {
            games = []
            state = .failed(error.localizedDescription)
            BootLogger.fail("matches.load", error)
        }
    }
}
