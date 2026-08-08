import Fluent

struct CreateParticipants: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("participants")
            .id()
            .field("game_id", .uuid, .required, .references("games", "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("status", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "game_id", "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("participants").delete()
    }
}
