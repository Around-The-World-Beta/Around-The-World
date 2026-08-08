import Foundation

/// Matches Vapor `GameResponse`.
public struct GameResponse: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let hostUserId: UUID
    public let title: String
    public let venue: String
    public let neighborhood: String
    public let skill: String
    public let format: String
    public let capacity: Int
    public let joinedCount: Int
    public let priceCents: Int
    public let notes: String
    public let startsAt: Date
    public let latitude: Double
    public let longitude: Double
    public let status: String
    public let imageUrl: String?
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: UUID,
        hostUserId: UUID,
        title: String,
        venue: String,
        neighborhood: String,
        skill: String,
        format: String,
        capacity: Int,
        joinedCount: Int,
        priceCents: Int,
        notes: String,
        startsAt: Date,
        latitude: Double,
        longitude: Double,
        status: String,
        imageUrl: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.hostUserId = hostUserId
        self.title = title
        self.venue = venue
        self.neighborhood = neighborhood
        self.skill = skill
        self.format = format
        self.capacity = capacity
        self.joinedCount = joinedCount
        self.priceCents = priceCents
        self.notes = notes
        self.startsAt = startsAt
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Matches Vapor `CreateGameRequest`.
public struct CreateGameRequest: Codable, Sendable, Equatable {
    public let hostUserId: UUID
    public let title: String
    public let venue: String
    public let neighborhood: String
    public let skill: String
    public let format: String
    public let capacity: Int
    public let priceCents: Int
    public let notes: String
    public let startsAt: Date
    public let latitude: Double
    public let longitude: Double
    public let imageUrl: String?

    public init(
        hostUserId: UUID,
        title: String,
        venue: String,
        neighborhood: String,
        skill: String,
        format: String,
        capacity: Int,
        priceCents: Int,
        notes: String,
        startsAt: Date,
        latitude: Double,
        longitude: Double,
        imageUrl: String? = nil
    ) {
        self.hostUserId = hostUserId
        self.title = title
        self.venue = venue
        self.neighborhood = neighborhood
        self.skill = skill
        self.format = format
        self.capacity = capacity
        self.priceCents = priceCents
        self.notes = notes
        self.startsAt = startsAt
        self.latitude = latitude
        self.longitude = longitude
        self.imageUrl = imageUrl
    }
}

/// Matches Vapor `UpdateGameRequest`.
public struct UpdateGameRequest: Codable, Sendable, Equatable {
    public let title: String?
    public let venue: String?
    public let neighborhood: String?
    public let skill: String?
    public let format: String?
    public let capacity: Int?
    public let priceCents: Int?
    public let notes: String?
    public let startsAt: Date?
    public let latitude: Double?
    public let longitude: Double?
    public let status: String?
    public let imageUrl: String?

    public init(
        title: String? = nil,
        venue: String? = nil,
        neighborhood: String? = nil,
        skill: String? = nil,
        format: String? = nil,
        capacity: Int? = nil,
        priceCents: Int? = nil,
        notes: String? = nil,
        startsAt: Date? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        status: String? = nil,
        imageUrl: String? = nil
    ) {
        self.title = title
        self.venue = venue
        self.neighborhood = neighborhood
        self.skill = skill
        self.format = format
        self.capacity = capacity
        self.priceCents = priceCents
        self.notes = notes
        self.startsAt = startsAt
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.imageUrl = imageUrl
    }
}
