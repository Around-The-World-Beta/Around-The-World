import Fluent

struct CreateProfiles: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("profiles")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("city", .string)
            .field("bio", .string)
            .field("favorite_position", .string)
            .field("skill_level", .string)
            .field("avatar_url", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("profiles").delete()
    }
}
