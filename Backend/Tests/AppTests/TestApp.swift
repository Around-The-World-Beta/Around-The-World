import Foundation
import JWT
import VaporTesting
@testable import App

/// Builds a fully configured Around the World app (not VaporTesting's bare `withApp`).
///
/// Environment variables are process-global. Keep every test that calls this in one
/// `.serialized` suite so two apps never migrate the same SQLite file.
func withATWApp(
    rateLimitPerMinute: Int? = nil,
    _ test: (Application) async throws -> Void
) async throws {
    let sqlitePath = "/tmp/atw-test-\(UUID().uuidString).sqlite"
    setenv("DATABASE_DRIVER", "sqlite", 1)
    setenv("SQLITE_PATH", sqlitePath, 1)
    unsetenv("DATABASE_URL")
    setenv("SUPABASE_JWT_SECRET", AuthConfiguration.testingJWTSecret, 1)
    setenv("SUPABASE_URL", "https://test.supabase.co", 1)
    setenv("CORS_ALLOWED_ORIGINS", "http://127.0.0.1:5173,http://localhost:5173", 1)
    if let rateLimitPerMinute {
        unsetenv("RATE_LIMIT_DISABLED")
        setenv("RATE_LIMIT_PER_MINUTE", "\(rateLimitPerMinute)", 1)
    } else {
        setenv("RATE_LIMIT_DISABLED", "1", 1)
        unsetenv("RATE_LIMIT_PER_MINUTE")
    }

    let app = try await Application.make(.testing)
    setenv("SQLITE_PATH", sqlitePath, 1)
    do {
        try await configure(app)
        try await test(app)
        try await app.asyncShutdown()
    } catch {
        try? await app.asyncShutdown()
        throw error
    }
}

func mintSupabaseToken(
    on app: Application,
    sub: UUID = UUID(),
    email: String? = nil,
    name: String? = nil,
    role: String = "authenticated",
    audience: String = "authenticated",
    issuer: String = "https://test.supabase.co/auth/v1",
    expiresIn: TimeInterval = 3600,
    isAnonymous: Bool = false
) async throws -> (token: String, sub: UUID) {
    let now = Date()
    var metadata: SupabaseJWTPayload.UserMetadata?
    if let name {
        metadata = .init(name: name, fullName: name)
    }
    let payload = SupabaseJWTPayload(
        issuer: IssuerClaim(value: issuer),
        subject: SubjectClaim(value: sub.uuidString.lowercased()),
        audience: AudienceClaim(value: audience),
        expiresAt: ExpirationClaim(value: now.addingTimeInterval(expiresIn)),
        issuedAt: IssuedAtClaim(value: now),
        role: role,
        email: email,
        phone: "",
        aal: "aal1",
        sessionID: UUID().uuidString.lowercased(),
        isAnonymous: isAnonymous,
        userMetadata: metadata,
        appMetadata: .init(provider: "apple", providers: ["apple"])
    )
    let token = try await app.jwt.keys.sign(payload)
    return (token, sub)
}

func bearerHeaders(_ token: String) -> HTTPHeaders {
    ["Authorization": "Bearer \(token)"]
}

func sampleCreateGame(title: String = "Mission Pickup", capacity: Int = 10) -> CreateGameRequest {
    CreateGameRequest(
        title: title,
        venue: "Franklin Square Park",
        neighborhood: "San Francisco, San Francisco",
        skill: SkillLevel.casual.rawValue,
        format: "5v5",
        capacity: capacity,
        priceCents: 0,
        notes: "Bring both colors.",
        startsAt: Date().addingTimeInterval(3600),
        latitude: 37.7644,
        longitude: -122.4102,
        imageUrl: nil
    )
}
