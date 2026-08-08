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

/// Matches Vapor `CreateFriendshipRequest`.
public struct CreateFriendshipRequest: Codable, Sendable, Equatable {
    public let userId: UUID
    public let friendUserId: UUID
    public let status: String?

    public init(userId: UUID, friendUserId: UUID, status: String? = nil) {
        self.userId = userId
        self.friendUserId = friendUserId
        self.status = status
    }
}

/// Matches Vapor `UpdateFriendshipRequest`.
public struct UpdateFriendshipRequest: Codable, Sendable, Equatable {
    public let status: String

    public init(status: String) {
        self.status = status
    }
}
