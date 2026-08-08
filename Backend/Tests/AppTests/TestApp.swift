import Foundation
import VaporTesting
@testable import App

/// Builds a fully configured Around the World app (not VaporTesting's bare `withApp`).
func withATWApp(_ test: (Application) async throws -> Void) async throws {
    setenv("DATABASE_DRIVER", "sqlite", 1)
    setenv("SQLITE_PATH", "/tmp/atw-test-\(UUID().uuidString).sqlite", 1)
    unsetenv("DATABASE_URL")

    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        try await test(app)
        try await app.asyncShutdown()
    } catch {
        try? await app.asyncShutdown()
        throw error
    }
}
