import Vapor

/// Environment-backed auth, CORS, and rate-limit settings.
///
/// Exact names to paste into Railway (and into a local secrets file — never into chat):
/// - `SUPABASE_JWT_SECRET` — Project Settings → API → JWT Secret. Required in production.
/// - `SUPABASE_URL` — Project Settings → API → Project URL (`https://<ref>.supabase.co`).
///   When set, tokens must be issued by `{SUPABASE_URL}/auth/v1`. Required on hosted deploys.
/// - `DATABASE_URL` — Postgres connection string (already required to talk to hosted Postgres).
/// - `CORS_ALLOWED_ORIGINS` — comma-separated browser origins. Empty means no website may call
///   the API. Native iOS does not use CORS.
/// - `RATE_LIMIT_PER_MINUTE` — max requests per client IP per 60 seconds (default 120).
///
/// Full paste-into-Railway steps: `docs/railway-setup.md`.
enum AuthConfiguration {
    static let developmentJWTSecret = "local-dev-jwt-secret-not-for-production"
    static let testingJWTSecret = "test-jwt-secret-for-unit-tests-only"
    static let expectedAudience = "authenticated"
    static let expectedRole = "authenticated"

    /// Anything that is not local `development` or `testing` (including `production`
    /// and a Railway `staging` environment) must have real secrets and Postgres.
    static func requiresHostedSecrets(for environment: Environment) -> Bool {
        switch environment.name {
        case "development", "testing":
            return false
        default:
            return true
        }
    }

    /// Fail fast on hosted boots so a container never comes up with SQLite or the
    /// local JWT secret. Does not change development/testing behaviour.
    static func requireBootConfiguration(for environment: Environment) throws {
        guard requiresHostedSecrets(for: environment) else { return }

        guard Environment.get("SUPABASE_JWT_SECRET")?.isEmpty == false else {
            throw MissingAuthConfiguration(
                "SUPABASE_JWT_SECRET is not set. The server will not start without it in production."
            )
        }
        guard supabaseURL != nil else {
            throw MissingAuthConfiguration(
                "SUPABASE_URL is not set. Hosted environments must check the token issuer."
            )
        }
        guard Environment.get("DATABASE_URL")?.isEmpty == false else {
            throw MissingAuthConfiguration(
                "DATABASE_URL is not set. Hosted environments must use Supabase Postgres — SQLite is local-only."
            )
        }
    }

    static func jwtSecret(for environment: Environment) throws -> String {
        if let secret = Environment.get("SUPABASE_JWT_SECRET"), !secret.isEmpty {
            return secret
        }
        switch environment.name {
        case "testing":
            return testingJWTSecret
        case "development":
            return developmentJWTSecret
        default:
            throw MissingAuthConfiguration(
                "SUPABASE_JWT_SECRET is not set. The server will not start without it in production."
            )
        }
    }

    /// `https://<project-ref>.supabase.co` with no trailing slash, or `nil` to skip issuer checks.
    static var supabaseURL: String? {
        guard let raw = Environment.get("SUPABASE_URL")?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty
        else {
            return nil
        }
        return raw.hasSuffix("/") ? String(raw.dropLast()) : raw
    }

    static var expectedIssuer: String? {
        supabaseURL.map { "\($0)/auth/v1" }
    }

    static func allowedCORSOrigins(for environment: Environment) -> [String] {
        if let raw = Environment.get("CORS_ALLOWED_ORIGINS") {
            return raw.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0 != "*" }
        }
        if environment == .development || environment == .testing {
            return [
                "http://127.0.0.1:5173",
                "http://localhost:5173",
                "http://127.0.0.1:8081",
                "http://localhost:8081",
            ]
        }
        return []
    }

    static var rateLimitDisabled: Bool {
        let raw = (Environment.get("RATE_LIMIT_DISABLED") ?? "").lowercased()
        return raw == "1" || raw == "true" || raw == "yes"
    }

    static var rateLimitPerMinute: Int {
        Environment.get("RATE_LIMIT_PER_MINUTE").flatMap(Int.init) ?? 120
    }
}

struct MissingAuthConfiguration: Error, CustomStringConvertible {
    let message: String
    init(_ message: String) { self.message = message }
    var description: String { message }
}
