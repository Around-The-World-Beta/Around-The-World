import Combine
import CoreLocation
import Foundation

/// Form + publish/update for Host. Identity comes from the session token — never a user id in the body.
@MainActor
final class HostSessionViewModel: ObservableObject {
    static let formats = ["5v5", "6v6", "7v7", "8v8", "11v11"]
    static let minPlayers = 4
    static let maxPlayers = 30

    let existingID: UUID?
    let existingJoinedCount: Int

    @Published var title = ""
    @Published var venueName = ""
    @Published var neighborhood = ""
    @Published var pin = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    @Published var startsAt = HostSessionViewModel.defaultStartsAt()
    @Published var format = "7v7"
    @Published var skill = MatchDifficulty.intermediate
    @Published var capacity = 14
    @Published var notes = ""
    @Published var isPublishing = false
    @Published var errorMessage: String?
    @Published var postedGame: GameResponse?

    private let api: AroundTheWorldAPI
    private let session: SessionStore

    var isEditing: Bool { existingID != nil }

    var minCapacity: Int {
        max(Self.minPlayers, existingJoinedCount)
    }

    var isInBayArea: Bool {
        BayAreaMapBounds.contains(pin)
    }

    init(
        existing: GameResponse? = nil,
        api: AroundTheWorldAPI = AroundTheWorldAPI(),
        session: SessionStore = .shared
    ) {
        self.api = api
        self.session = session
        self.existingID = existing?.id
        self.existingJoinedCount = existing?.joinedCount ?? 0

        guard let existing else { return }
        title = existing.title
        venueName = existing.venue
        neighborhood = existing.neighborhood
        pin = CLLocationCoordinate2D(latitude: existing.latitude, longitude: existing.longitude)
        startsAt = existing.startsAt
        format = Self.formats.contains(existing.format) ? existing.format : "7v7"
        skill = MatchDifficulty.canonical(existing.skill)
        capacity = max(existing.capacity, existing.joinedCount)
        notes = UserContentLimits.clamped(existing.notes, maxLength: UserContentLimits.notesMax)
    }

    func applyVenue(name: String, neighborhood: String, coordinate: CLLocationCoordinate2D) {
        venueName = name
        self.neighborhood = neighborhood
        pin = coordinate
    }

    func dropPin(_ coordinate: CLLocationCoordinate2D) {
        pin = coordinate
    }

    func bumpCapacity(_ delta: Int) {
        capacity = min(Self.maxPlayers, max(minCapacity, capacity + delta))
    }

    func submit() async {
        errorMessage = nil

        guard session.isSignedIn else {
            errorMessage = L10n.hostNeedSignIn
            session.requestSignIn()
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedVenue = venueName.trimmingCharacters(in: .whitespacesAndNewlines)
        var area = neighborhood.trimmingCharacters(in: .whitespacesAndNewlines)
        if area.isEmpty {
            area = "Bay Area"
        }
        let trimmedNotes = UserContentLimits.clamped(
            notes.trimmingCharacters(in: .whitespacesAndNewlines),
            maxLength: UserContentLimits.notesMax
        )

        guard !trimmedTitle.isEmpty else {
            errorMessage = L10n.hostNeedTitle
            return
        }
        guard !trimmedVenue.isEmpty else {
            errorMessage = L10n.hostNeedVenue
            return
        }
        guard isInBayArea else {
            errorMessage = L10n.hostBayAreaOnly
            return
        }

        isPublishing = true
        defer { isPublishing = false }

        do {
            let game: GameResponse
            if let existingID {
                game = try await api.updateGame(
                    id: existingID,
                    UpdateGameRequest(
                        title: trimmedTitle,
                        venue: trimmedVenue,
                        neighborhood: area,
                        skill: skill.rawValue,
                        format: format,
                        capacity: capacity,
                        notes: trimmedNotes,
                        startsAt: startsAt,
                        latitude: pin.latitude,
                        longitude: pin.longitude
                    )
                )
                GamesDidChange.post(game: game, revealInBrowse: false)
            } else {
                game = try await api.createGame(
                    CreateGameRequest(
                        title: trimmedTitle,
                        venue: trimmedVenue,
                        neighborhood: area,
                        skill: skill.rawValue,
                        format: format,
                        capacity: capacity,
                        priceCents: 0,
                        notes: trimmedNotes,
                        startsAt: startsAt,
                        latitude: pin.latitude,
                        longitude: pin.longitude
                    )
                )
                GamesDidChange.post(game: game, revealInBrowse: true)
            }
            postedGame = game
        } catch let error as APIError {
            if case .httpStatus(401, _) = error {
                session.requestSignIn()
            }
            errorMessage = error.userFacingMessage
            BootLogger.fail("host.submit", error)
        } catch {
            errorMessage = error.localizedDescription
            BootLogger.fail("host.submit", error)
        }
    }

    static func defaultStartsAt() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}
