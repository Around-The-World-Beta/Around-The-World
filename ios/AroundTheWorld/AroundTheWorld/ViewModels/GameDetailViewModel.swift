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
    @Published var showReport = false
    @Published var confirmBlock = false

    let gameID: UUID
    private let api: AroundTheWorldAPI
    private let session: SessionStore

    init(
        gameID: UUID,
        api: AroundTheWorldAPI = AroundTheWorldAPI(),
        session: SessionStore = .shared
    ) {
        self.gameID = gameID
        self.api = api
        self.session = session
    }

    func load() async {
        state = .loading
        actionMessage = nil
        do {
            let fetchedGame = try await api.getGame(id: gameID)
            game = fetchedGame
            participants = await loadSquadIfSignedIn()
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

    var isHost: Bool {
        game?.isHostedBy(session.userID) == true
    }

    func claimSpot() async {
        guard let game else { return }
        guard session.isSignedIn else {
            session.requestSignIn()
            return
        }

        isActing = true
        defer { isActing = false }

        do {
            let participant = try await api.createParticipant(CreateParticipantRequest(gameId: game.id))
            actionMessage = participant.status == "waitlist" ? L10n.claimWaitlisted : L10n.claimJoined
            await load()
        } catch let error as APIError {
            actionMessage = error.userFacingMessage
        } catch {
            actionMessage = error.localizedDescription
        }
    }

    func cancelGame() async {
        guard session.isSignedIn else {
            session.requestSignIn()
            return
        }

        isActing = true
        defer { isActing = false }

        do {
            let updated = try await api.updateGame(id: gameID, UpdateGameRequest(status: "cancelled"))
            game = updated
            actionMessage = L10n.hostCancelledDone
            GamesDidChange.post(game: updated, revealInBrowse: false)
        } catch let error as APIError {
            if case .httpStatus(401, _) = error {
                session.requestSignIn()
            }
            actionMessage = error.userFacingMessage
        } catch {
            actionMessage = error.localizedDescription
        }
    }

    func requestReport() {
        guard session.isSignedIn else {
            session.requestSignIn()
            return
        }
        showReport = true
    }

    func requestBlock() {
        guard session.isSignedIn else {
            session.requestSignIn()
            return
        }
        guard !isHost else { return }
        confirmBlock = true
    }

    func blockHost() async {
        guard let hostID = game?.hostUserId else { return }
        guard session.isSignedIn else {
            session.requestSignIn()
            return
        }
        isActing = true
        defer { isActing = false }
        do {
            _ = try await api.createBlock(CreateBlockRequest(blockedUserId: hostID))
            actionMessage = L10n.blockDone
        } catch {
            actionMessage = error.localizedDescription
        }
    }

    /// Squad listing requires a token after W1. Signed-out browse still shows the public card.
    private func loadSquadIfSignedIn() async -> [ParticipantResponse] {
        guard session.isSignedIn else { return [] }
        do {
            let fetched = try await api.listParticipants(gameId: gameID)
            return fetched.filter { $0.status == "joined" || $0.status == "waitlist" }
        } catch {
            BootLogger.fail("game.participants", error)
            return []
        }
    }
}
