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

/// Posted after create / edit / cancel so Matches and My Games refresh.
enum GamesDidChange {
    static let notification = Notification.Name("atw.games.didChange")
    static let gameKey = "game"
    static let revealInBrowseKey = "revealInBrowse"

    static func post(game: GameResponse? = nil, revealInBrowse: Bool = false) {
        var info: [AnyHashable: Any] = [revealInBrowseKey: revealInBrowse]
        if let game {
            info[gameKey] = game
        }
        NotificationCenter.default.post(name: notification, object: nil, userInfo: info)
    }
}

/// Matches Vapor `CreateGameRequest`. Host is the token — do not send `hostUserId`.
public struct CreateGameRequest: Codable, Sendable, Equatable {
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
        self.title = title
        self.venue = venue
        self.neighborhood = neighborhood
        self.skill = skill
        self.format = format
        self.capacity = capacity
        self.priceCents = priceCents
        self.notes = UserContentLimits.clamped(notes, maxLength: UserContentLimits.notesMax)
        self.startsAt = startsAt
        self.latitude = latitude
        self.longitude = longitude
        self.imageUrl = imageUrl
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(venue, forKey: .venue)
        try container.encode(neighborhood, forKey: .neighborhood)
        try container.encode(skill, forKey: .skill)
        try container.encode(format, forKey: .format)
        try container.encode(capacity, forKey: .capacity)
        try container.encode(priceCents, forKey: .priceCents)
        try container.encode(notes, forKey: .notes)
        try container.encode(startsAt, forKey: .startsAt)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
    }

    private enum CodingKeys: String, CodingKey {
        case title, venue, neighborhood, skill, format, capacity, priceCents, notes, startsAt, latitude, longitude, imageUrl
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
        self.notes = notes.map { UserContentLimits.clamped($0, maxLength: UserContentLimits.notesMax) }
        self.startsAt = startsAt
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.imageUrl = imageUrl
    }
}

/// Posted after create / edit / cancel so Matches and My Games refresh.
enum GamesDidChange {
    static let notification = Notification.Name("atw.games.didChange")
    static let gameKey = "game"
    static let revealInBrowseKey = "revealInBrowse"

    static func post(game: GameResponse? = nil, revealInBrowse: Bool = false) {
        var info: [AnyHashable: Any] = [revealInBrowseKey: revealInBrowse]
        if let game {
            info[gameKey] = game
        }
        NotificationCenter.default.post(name: notification, object: nil, userInfo: info)
    }
}
