import Fluent

struct CreateGames: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("games")
            .id()
            .field("host_user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("title", .string, .required)
            .field("venue", .string, .required)
            .field("neighborhood", .string, .required)
            .field("skill", .string, .required)
            .field("format", .string, .required)
            .field("capacity", .int, .required)
            .field("price_cents", .int, .required)
            .field("notes", .string, .required)
            .field("starts_at", .datetime, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("status", .string, .required)
            .field("image_url", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("games").delete()
    }
}
