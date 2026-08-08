import Testing
import VaporTesting
import Fluent
@testable import App

@Suite("API health", .serialized)
struct AppTests {
    @Test("health returns clean JSON")
    func health() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "health") { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode(HealthResponse.self)
                #expect(body.status == "ok")
                #expect(body.service == "around-the-world-api")
            }
        }
    }
}

private func withApp(_ test: (Application) async throws -> Void) async throws {
    let app = try await Application.make(.testing)
    do {
        // Use the same local Postgres as development for integration-style tests.
        // CI / agents should provide DATABASE_* env vars (see Backend/.env.example).
        try await configure(app)
        try await app.autoMigrate()
        try await test(app)
        try await app.asyncShutdown()
    } catch {
        try? await app.asyncShutdown()
        throw error
    }
}
