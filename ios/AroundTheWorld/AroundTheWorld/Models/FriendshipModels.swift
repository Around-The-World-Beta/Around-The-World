import Foundation

/// Matches Vapor `FriendshipResponse`.
public struct FriendshipResponse: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let friendUserId: UUID
    public let status: String
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: UUID,
        userId: UUID,
        friendUserId: UUID,
        status: String,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.friendUserId = friendUserId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Matches Vapor `CreateFriendshipRequest`. Follower is the token — do not send `userId`.
public struct CreateFriendshipRequest: Codable, Sendable, Equatable {
    public let friendUserId: UUID
    public let status: String?

    public init(friendUserId: UUID, status: String? = nil) {
        self.friendUserId = friendUserId
        self.status = status
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(friendUserId, forKey: .friendUserId)
        try container.encodeIfPresent(status, forKey: .status)
    }

    private enum CodingKeys: String, CodingKey {
        case friendUserId, status
    }
}

/// Matches Vapor `UpdateFriendshipRequest`.
public struct UpdateFriendshipRequest: Codable, Sendable, Equatable {
    public let status: String

    public init(status: String) {
        self.status = status
    }
}
