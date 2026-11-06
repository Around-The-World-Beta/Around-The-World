import Fluent
import Foundation
import Testing
import VaporTesting
@testable import App

extension AppTests {
    @Test("production refuses to boot without SUPABASE_JWT_SECRET")
    func productionRequiresJWTSecret() async throws {
        try await withRestoredHostedEnv {
            unsetenv("SUPABASE_JWT_SECRET")
            setenv("SUPABASE_URL", "https://example.supabase.co", 1)
            setenv("DATABASE_URL", "postgresql://atw:atw@127.0.0.1:5432/around_the_world", 1)

            let app = try await Application.make(.production)
            do {
                try await configure(app)
                Issue.record("production boot should have failed without SUPABASE_JWT_SECRET")
            } catch let error as MissingAuthConfiguration {
                #expect(error.message.contains("SUPABASE_JWT_SECRET"))
            }
            try await app.asyncShutdown()
        }
    }

    @Test("production refuses to boot without SUPABASE_URL")
    func productionRequiresSupabaseURL() async throws {
        try await withRestoredHostedEnv {
            setenv("SUPABASE_JWT_SECRET", "hosted-test-secret-not-used", 1)
            unsetenv("SUPABASE_URL")
            setenv("DATABASE_URL", "postgresql://atw:atw@127.0.0.1:5432/around_the_world", 1)

            let app = try await Application.make(.production)
            do {
                try await configure(app)
                Issue.record("production boot should have failed without SUPABASE_URL")
            } catch let error as MissingAuthConfiguration {
                #expect(error.message.contains("SUPABASE_URL"))
            }
            try await app.asyncShutdown()
        }
    }

    @Test("production refuses to boot without DATABASE_URL")
    func productionRequiresDatabaseURL() async throws {
        try await withRestoredHostedEnv {
            setenv("SUPABASE_JWT_SECRET", "hosted-test-secret-not-used", 1)
            setenv("SUPABASE_URL", "https://example.supabase.co", 1)
            unsetenv("DATABASE_URL")

            let app = try await Application.make(.production)
            do {
                try await configure(app)
                Issue.record("production boot should have failed without DATABASE_URL")
            } catch let error as MissingAuthConfiguration {
                #expect(error.message.contains("DATABASE_URL"))
            }
            try await app.asyncShutdown()
        }
    }

    @Test("staging also requires hosted secrets")
    func stagingRequiresHostedSecrets() async throws {
        try await withRestoredHostedEnv {
            unsetenv("SUPABASE_JWT_SECRET")
            unsetenv("SUPABASE_URL")
            unsetenv("DATABASE_URL")

            let app = try await Application.make(.custom(name: "staging"))
            do {
                try await configure(app)
                Issue.record("staging boot should have failed without secrets")
            } catch is MissingAuthConfiguration {
                // expected
            }
            try await app.asyncShutdown()
        }
    }

    @Test("SEED_DEMO is ignored when VAPOR_ENV is production")
    func productionNeverSeeds() async throws {
        try await withATWApp { app in
            setenv("SEED_DEMO", "1", 1)
            setenv("VAPOR_ENV", "production", 1)
            defer {
                unsetenv("SEED_DEMO")
                unsetenv("VAPOR_ENV")
            }
            try await SeedDemoData().prepare(on: app.db)
            let count = try await Game.query(on: app.db).count()
            #expect(count == 0)
        }
    }
}

private func withRestoredHostedEnv(_ body: () async throws -> Void) async throws {
    let jwt = getenv("SUPABASE_JWT_SECRET").map { String(cString: $0) }
    let url = getenv("SUPABASE_URL").map { String(cString: $0) }
    let database = getenv("DATABASE_URL").map { String(cString: $0) }
    defer {
        if let jwt { setenv("SUPABASE_JWT_SECRET", jwt, 1) } else { unsetenv("SUPABASE_JWT_SECRET") }
        if let url { setenv("SUPABASE_URL", url, 1) } else { unsetenv("SUPABASE_URL") }
        if let database { setenv("DATABASE_URL", database, 1) } else { unsetenv("DATABASE_URL") }
    }
    try await body()
}
