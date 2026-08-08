import Fluent
import Vapor

/// Application user identity. `supabaseUserId` links to Supabase Auth (`auth.users.id`) when configured.
final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "display_name")
    var displayName: String

    /// Optional FK-style link to Supabase Auth user UUID.
    @OptionalField(key: "supabase_user_id")
    var supabaseUserId: UUID?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @OptionalChild(for: \.$user)
    var profile: Profile?

    @Children(for: \.$host)
    var hostedGames: [Game]

    init() {}

    init(
        id: UUID? = nil,
        email: String,
        displayName: String,
        supabaseUserId: UUID? = nil
    ) {
        self.id = id
        self.email = email.lowercased()
        self.displayName = displayName
        self.supabaseUserId = supabaseUserId
    }
}
