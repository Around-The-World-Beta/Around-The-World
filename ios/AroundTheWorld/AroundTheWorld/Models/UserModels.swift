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

/// Matches Vapor `CreateUserRequest`.
public struct CreateUserRequest: Codable, Sendable, Equatable {
    public let email: String
    public let displayName: String
    public let supabaseUserId: UUID?
    public let city: String?
    public let bio: String?
    public let favoritePosition: String?
    public let skillLevel: String?

    public init(
        email: String,
        displayName: String,
        supabaseUserId: UUID? = nil,
        city: String? = nil,
        bio: String? = nil,
        favoritePosition: String? = nil,
        skillLevel: String? = nil
    ) {
        self.email = email
        self.displayName = displayName
        self.supabaseUserId = supabaseUserId
        self.city = city
        self.bio = bio
        self.favoritePosition = favoritePosition
        self.skillLevel = skillLevel
    }
}

/// Matches Vapor `UpdateUserRequest`.
public struct UpdateUserRequest: Codable, Sendable, Equatable {
    public let email: String?
    public let displayName: String?
    public let supabaseUserId: UUID?

    public init(
        email: String? = nil,
        displayName: String? = nil,
        supabaseUserId: UUID? = nil
    ) {
        self.email = email
        self.displayName = displayName
        self.supabaseUserId = supabaseUserId
    }
}
