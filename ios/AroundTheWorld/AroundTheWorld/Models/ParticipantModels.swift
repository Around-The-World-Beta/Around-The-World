import Foundation

/// Matches Vapor `ParticipantResponse`.
public struct ParticipantResponse: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let gameId: UUID
    public let userId: UUID
    public let status: String
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: UUID,
        gameId: UUID,
        userId: UUID,
        status: String,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.gameId = gameId
        self.userId = userId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Matches Vapor `CreateParticipantRequest`. Player is the token — do not send `userId`.
public struct CreateParticipantRequest: Codable, Sendable, Equatable {
    public let gameId: UUID
    public let status: String?

    public init(gameId: UUID, status: String? = nil) {
        self.gameId = gameId
        self.status = status
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gameId, forKey: .gameId)
        try container.encodeIfPresent(status, forKey: .status)
    }

    private enum CodingKeys: String, CodingKey {
        case gameId, status
    }
}

/// Matches Vapor `UpdateParticipantRequest`.
public struct UpdateParticipantRequest: Codable, Sendable, Equatable {
    public let status: String

    public init(status: String) {
        self.status = status
    }
}
