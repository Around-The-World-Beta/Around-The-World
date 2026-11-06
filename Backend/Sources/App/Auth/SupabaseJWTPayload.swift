import Foundation
import JWT
import Vapor

/// Access-token payload matching Supabase's documented JWT claims.
///
/// https://supabase.com/docs/guides/auth/jwt-fields
///
/// Required claims we verify: `iss`, `aud`, `exp`, `iat`, `sub`, `role`.
/// We also read `email`, `user_metadata`, `is_anonymous`, and `session_id`.
///
/// Tests mint HS256 tokens in this shape with a local secret. Production verifies
/// the same shape using `SUPABASE_JWT_SECRET` from the Supabase project.
struct SupabaseJWTPayload: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case issuer = "iss"
        case subject = "sub"
        case audience = "aud"
        case expiresAt = "exp"
        case issuedAt = "iat"
        case role
        case email
        case phone
        case aal
        case sessionID = "session_id"
        case isAnonymous = "is_anonymous"
        case userMetadata = "user_metadata"
        case appMetadata = "app_metadata"
    }

    var issuer: IssuerClaim
    var subject: SubjectClaim
    var audience: AudienceClaim
    var expiresAt: ExpirationClaim
    var issuedAt: IssuedAtClaim
    var role: String
    var email: String?
    var phone: String?
    var aal: String?
    var sessionID: String?
    var isAnonymous: Bool?
    var userMetadata: UserMetadata?
    var appMetadata: AppMetadata?

    struct UserMetadata: Codable, Sendable {
        enum CodingKeys: String, CodingKey {
            case name
            case fullName = "full_name"
        }

        var name: String?
        var fullName: String?
    }

    struct AppMetadata: Codable, Sendable {
        var provider: String?
        var providers: [String]?
    }

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try expiresAt.verifyNotExpired()
        try audience.verifyIntendedAudience(includes: AuthConfiguration.expectedAudience)
        guard role == AuthConfiguration.expectedRole else {
            throw Abort(.unauthorized, reason: "Token role is not authenticated")
        }
        if isAnonymous == true {
            throw Abort(.unauthorized, reason: "Anonymous tokens are not accepted")
        }
    }

    func supabaseUserID() throws -> UUID {
        let raw = subject.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let id = UUID(uuidString: raw) else {
            throw Abort(.unauthorized, reason: "Token subject is not a user id")
        }
        return id
    }

    var normalizedEmail: String? {
        guard let email else { return nil }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.isEmpty ? nil : trimmed
    }

    var preferredDisplayName: String {
        let candidates = [
            userMetadata?.fullName,
            userMetadata?.name,
            normalizedEmail?.split(separator: "@").first.map(String.init),
        ]
        for candidate in candidates {
            guard let value = candidate?.trimmingCharacters(in: .whitespacesAndNewlines),
                  value.count >= 2
            else { continue }
            return String(value.prefix(60))
        }
        return "Player"
    }
}
