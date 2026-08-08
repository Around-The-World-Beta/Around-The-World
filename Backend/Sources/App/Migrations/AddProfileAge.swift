import Fluent

/// Adds optional `age` for player profiles (Bay Area beta profile fields).
struct AddProfileAge: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("profiles")
            .field("age", .int)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("profiles")
            .deleteField("age")
            .update()
    }
}
