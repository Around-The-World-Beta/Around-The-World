import Fluent
import Vapor

enum ParticipantStatus: String, Codable, CaseIterable, Sendable {
    case joined
    case waitlist
    case cancelled
}

/// Join / waitlist / leave record for a game.
final class Participant: Model, Content, @unchecked Sendable {
    static let schema = "participants"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "game_id")
    var game: Game

    @Parent(key: "user_id")
    var user: User

    @Field(key: "status")
    var status: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        gameID: UUID,
        userID: UUID,
        status: ParticipantStatus = .joined
    ) {
        self.id = id
        self.$game.id = gameID
        self.$user.id = userID
        self.status = status.rawValue
    }
}
