import Fluent

struct CreateFriendships: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("friendships")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("friend_user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("status", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "user_id", "friend_user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("friendships").delete()
    }
}
