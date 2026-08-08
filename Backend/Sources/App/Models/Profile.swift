import Fluent
import Vapor

enum FavoritePosition: String, Codable, CaseIterable, Sendable {
    case goalkeeper = "Goalkeeper"
    case defender = "Defender"
    case midfielder = "Midfielder"
    case forward = "Forward"
}

enum SkillLevel: String, Codable, CaseIterable, Sendable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case baller = "Baller"
    case openToAll = "Open to All"
    /// Legacy seed / pre-beta value — accepted by validation, normalized to Beginner.
    case casual = "Casual"
}

/// Extended player profile (1:1 with `users`). Aligns with existing Supabase `profiles` fields.
final class Profile: Model, Content, @unchecked Sendable {
    static let schema = "profiles"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @OptionalField(key: "city")
    var city: String?

    @OptionalField(key: "bio")
    var bio: String?

    @OptionalField(key: "favorite_position")
    var favoritePosition: String?

    @OptionalField(key: "skill_level")
    var skillLevel: String?

    @OptionalField(key: "avatar_url")
    var avatarUrl: String?

    @OptionalField(key: "age")
    var age: Int?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        city: String? = nil,
        bio: String? = nil,
        favoritePosition: String? = nil,
        skillLevel: String? = nil,
        avatarUrl: String? = nil,
        age: Int? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.city = city
        self.bio = bio
        self.favoritePosition = favoritePosition
        self.skillLevel = skillLevel
        self.avatarUrl = avatarUrl
        self.age = age
    }
}
