import Fluent
import SQLKit

/// Denies direct client access to the application tables on Postgres.
///
/// Supabase publishes every table in the `public` schema through its auto-generated
/// REST API, reachable with the anon key that ships inside the iOS app. Without row
/// level security, anyone holding that key could read and write `users`, `games`, and
/// `profiles` directly, bypassing this service entirely.
///
/// Enabling RLS with **no policies** denies all access through that path. This service
/// is unaffected because it connects as the table owner, and owners bypass RLS unless
/// `FORCE ROW LEVEL SECURITY` is set, which it is not.
///
/// No-op on SQLite, which has no RLS and no REST front end.
struct EnableRowLevelSecurity: AsyncMigration {
    static let tables = ["users", "profiles", "games", "participants", "friendships"]

    func prepare(on database: any Database) async throws {
        guard let sql = postgres(database) else { return }
        for table in Self.tables {
            try await sql.raw("ALTER TABLE \(ident: table) ENABLE ROW LEVEL SECURITY").run()
        }
    }

    func revert(on database: any Database) async throws {
        guard let sql = postgres(database) else { return }
        for table in Self.tables {
            try await sql.raw("ALTER TABLE \(ident: table) DISABLE ROW LEVEL SECURITY").run()
        }
    }

    private func postgres(_ database: any Database) -> (any SQLDatabase)? {
        guard let sql = database as? any SQLDatabase, sql.dialect.name == "postgresql" else {
            return nil
        }
        return sql
    }
}
