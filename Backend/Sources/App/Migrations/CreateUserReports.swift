import Fluent
import SQLKit

struct CreateUserReports: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("user_reports")
            .id()
            .field("reporter_user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("target_type", .string, .required)
            .field("target_id", .uuid, .required)
            .field("reason", .string, .required)
            .field("details", .string)
            .field("created_at", .datetime)
            .unique(on: "reporter_user_id", "target_type", "target_id")
            .create()

        try await enableRLS(on: database, table: "user_reports")
    }

    func revert(on database: any Database) async throws {
        try await database.schema("user_reports").delete()
    }
}

struct CreateUserBlocks: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("user_blocks")
            .id()
            .field("blocker_user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("blocked_user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "blocker_user_id", "blocked_user_id")
            .create()

        try await enableRLS(on: database, table: "user_blocks")
    }

    func revert(on database: any Database) async throws {
        try await database.schema("user_blocks").delete()
    }
}

private func enableRLS(on database: any Database, table: String) async throws {
    guard let sql = database as? any SQLDatabase, sql.dialect.name == "postgresql" else {
        return
    }
    try await sql.raw("ALTER TABLE \(ident: table) ENABLE ROW LEVEL SECURITY").run()
}
