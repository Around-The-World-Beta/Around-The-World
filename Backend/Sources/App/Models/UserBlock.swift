import Fluent
import Vapor

/// One player hiding another. Bidirectional for listings: neither sees the other's games.
final class UserBlock: Model, Content, @unchecked Sendable {
    static let schema = "user_blocks"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "blocker_user_id")
    var blocker: User

    @Parent(key: "blocked_user_id")
    var blocked: User

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        blockerID: UUID,
        blockedID: UUID
    ) {
        self.id = id
        self.$blocker.id = blockerID
        self.$blocked.id = blockedID
    }

    /// Users this person should not see, and who should not see them, in browse.
    static func hiddenUserIDs(for userID: UUID, on db: any Database) async throws -> Set<UUID> {
        let outgoing = try await UserBlock.query(on: db).filter(\.$blocker.$id == userID).all()
        let incoming = try await UserBlock.query(on: db).filter(\.$blocked.$id == userID).all()
        var ids = Set<UUID>()
        ids.formUnion(outgoing.map(\.$blocked.id))
        ids.formUnion(incoming.map(\.$blocker.id))
        return ids
    }
}
