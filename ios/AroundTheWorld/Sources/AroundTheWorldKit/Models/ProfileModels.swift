import Foundation

/// Matches Vapor `ProfileResponse`.
public struct ProfileResponse: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let city: String?
    public let bio: String?
    public let favoritePosition: String?
    public let skillLevel: String?
    public let avatarUrl: String?
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: UUID,
        userId: UUID,
        city: String? = nil,
        bio: String? = nil,
        favoritePosition: String? = nil,
        skillLevel: String? = nil,
        avatarUrl: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.city = city
        self.bio = bio
        self.favoritePosition = favoritePosition
        self.skillLevel = skillLevel
        self.avatarUrl = avatarUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Matches Vapor `UpdateProfileRequest`.
public struct UpdateProfileRequest: Codable, Sendable, Equatable {
    public let city: String?
    public let bio: String?
    public let favoritePosition: String?
    public let skillLevel: String?
    public let avatarUrl: String?

    public init(
        city: String? = nil,
        bio: String? = nil,
        favoritePosition: String? = nil,
        skillLevel: String? = nil,
        avatarUrl: String? = nil
    ) {
        self.city = city
        self.bio = bio
        self.favoritePosition = favoritePosition
        self.skillLevel = skillLevel
        self.avatarUrl = avatarUrl
    }
}
