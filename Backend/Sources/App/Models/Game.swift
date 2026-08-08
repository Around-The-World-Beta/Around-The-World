import Fluent
import Vapor

enum GameStatus: String, Codable, CaseIterable, Sendable {
    case scheduled
    case cancelled
    case completed
}

/// Pickup game / match listing — core product entity for discovery, host, and join flows.
final class Game: Model, Content, @unchecked Sendable {
    static let schema = "games"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "host_user_id")
    var host: User

    @Field(key: "title")
    var title: String

    @Field(key: "venue")
    var venue: String

    @Field(key: "neighborhood")
    var neighborhood: String

    @Field(key: "skill")
    var skill: String

    @Field(key: "format")
    var format: String

    @Field(key: "capacity")
    var capacity: Int

    @Field(key: "price_cents")
    var priceCents: Int

    @Field(key: "notes")
    var notes: String

    @Field(key: "starts_at")
    var startsAt: Date

    @Field(key: "latitude")
    var latitude: Double

    @Field(key: "longitude")
    var longitude: Double

    @Field(key: "status")
    var status: String

    @OptionalField(key: "image_url")
    var imageUrl: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$game)
    var participants: [Participant]

    init() {}

    init(
        id: UUID? = nil,
        hostID: UUID,
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
        status: GameStatus = .scheduled,
        imageUrl: String? = nil
    ) {
        self.id = id
        self.$host.id = hostID
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
        self.status = status.rawValue
        self.imageUrl = imageUrl
    }
}
