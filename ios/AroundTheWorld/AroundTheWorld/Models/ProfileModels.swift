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
    public let age: Int?
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
        age: Int? = nil,
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
        self.age = age
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
    public let age: Int?

    public init(
        city: String? = nil,
        bio: String? = nil,
        favoritePosition: String? = nil,
        skillLevel: String? = nil,
        avatarUrl: String? = nil,
        age: Int? = nil
    ) {
        self.city = city
        self.bio = bio
        self.favoritePosition = favoritePosition
        self.skillLevel = skillLevel
        self.avatarUrl = avatarUrl
        self.age = age
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(favoritePosition, forKey: .favoritePosition)
        try container.encodeIfPresent(skillLevel, forKey: .skillLevel)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try container.encodeIfPresent(age, forKey: .age)
    }

    private enum CodingKeys: String, CodingKey {
        case city, bio, favoritePosition, skillLevel, avatarUrl, age
    }
}

/// Positions the server accepts on `PATCH /api/v1/me/profile`.
enum PlayerPosition: String, CaseIterable, Identifiable, Sendable {
    case goalkeeper = "Goalkeeper"
    case defender = "Defender"
    case midfielder = "Midfielder"
    case forward = "Forward"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .goalkeeper: return L10n.profilePositionGK
        case .defender: return L10n.profilePositionDef
        case .midfielder: return L10n.profilePositionMid
        case .forward: return L10n.profilePositionFwd
        }
    }
}
