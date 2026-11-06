import Foundation

/// Matches Vapor `UserResponse`.
public struct UserResponse: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let email: String
    public let displayName: String
    public let supabaseUserId: UUID?
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: UUID,
        email: String,
        displayName: String,
        supabaseUserId: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.supabaseUserId = supabaseUserId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Matches Vapor `MeResponse`.
public struct MeResponse: Codable, Sendable, Equatable {
    public let user: UserResponse
    public let profile: ProfileResponse
}

/// Matches Vapor `UpdateMeRequest`.
public struct UpdateMeRequest: Codable, Sendable, Equatable {
    public let displayName: String?

    public init(displayName: String? = nil) {
        self.displayName = displayName
    }
}

/// Matches Vapor `PublicPlayerResponse`. No email.
public struct PublicPlayerResponse: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let displayName: String
    public let city: String?
    public let bio: String?
    public let favoritePosition: String?
    public let skillLevel: String?
    public let avatarUrl: String?
    public let age: Int?
}
