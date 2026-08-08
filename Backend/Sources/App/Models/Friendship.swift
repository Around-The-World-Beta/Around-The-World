import Fluent
import Vapor

enum FriendshipStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case accepted
    case blocked
}

/// Directed social edge between two users (follow / friend / block).
final class Friendship: Model, Content, @unchecked Sendable {
    static let schema = "friendships"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "friend_user_id")
    var friend: User

    @Field(key: "status")
    var status: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        friendUserID: UUID,
        status: FriendshipStatus = .pending
    ) {
        self.id = id
        self.$user.id = userID
        self.$friend.id = friendUserID
        self.status = status.rawValue
    }
}
