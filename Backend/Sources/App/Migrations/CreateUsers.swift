import Fluent

struct CreateUsers: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("display_name", .string, .required)
            .field("supabase_user_id", .uuid)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "email")
            .unique(on: "supabase_user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
    }
}
