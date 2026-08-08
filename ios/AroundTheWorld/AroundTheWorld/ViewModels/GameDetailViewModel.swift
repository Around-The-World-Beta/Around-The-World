import Foundation
import Combine

/// Loads a single game + its participants from the live API.
@MainActor
final class GameDetailViewModel: ObservableObject {
    @Published private(set) var state: LoadState = .idle
    @Published private(set) var game: GameResponse?
    @Published private(set) var participants: [ParticipantResponse] = []
    @Published var actionMessage: String?
    @Published private(set) var isActing = false

    let gameID: UUID
    private let api: AroundTheWorldAPI

    /// Optional signed-in user for Claim Spot (Phase 2 auth will populate this).
    var currentUserID: UUID?

    init(gameID: UUID, api: AroundTheWorldAPI = AroundTheWorldAPI(), currentUserID: UUID? = nil) {
        self.gameID = gameID
        self.api = api
        self.currentUserID = currentUserID
    }

    func load() async {
        state = .loading
        actionMessage = nil
        do {
            async let gameTask = api.getGame(id: gameID)
            async let participantsTask = api.listParticipants(gameId: gameID)
            let (fetchedGame, fetchedParticipants) = try await (gameTask, participantsTask)
            game = fetchedGame
            participants = fetchedParticipants.filter { $0.status == "joined" || $0.status == "waitlist" }
            state = .loaded
        } catch let error as APIError {
            game = nil
            participants = []
            if case .httpStatus(404, _) = error {
                state = .empty
            } else {
                state = .failed(error.localizedDescription)
            }
        } catch {
            game = nil
            participants = []
            state = .failed(error.localizedDescription)
        }
    }

    func claimSpot() async {
        guard let game else { return }
        guard let userID = currentUserID else {
            actionMessage = L10n.signInToClaim
            return
        }

        isActing = true
        defer { isActing = false }

        do {
            _ = try await api.createParticipant(
                CreateParticipantRequest(gameId: game.id, userId: userID)
            )
            actionMessage = game.isFull ? "Added to waitlist." : "You're in — see you on the pitch."
            await load()
        } catch {
            actionMessage = error.localizedDescription
        }
    }
}
