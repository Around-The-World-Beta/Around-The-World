import JWT
import Vapor

/// Verifies a Supabase access token and attaches the matching app user.
///
/// Identity is taken only from the verified `sub` claim. Request bodies and
/// path parameters are never used to decide who is calling.
struct RequireAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let payload = try await verifiedPayload(on: request)
        try verifyIssuer(payload, on: request)
        request.authUser = try await IdentityLink.user(from: payload, on: request.db)
        return try await next.respond(to: request)
    }

    private func verifiedPayload(on request: Request) async throws -> SupabaseJWTPayload {
        guard let bearer = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "Sign in required")
        }
        do {
            return try await request.application.jwt.keys.verify(bearer.token, as: SupabaseJWTPayload.self)
        } catch let abort as any AbortError {
            throw abort
        } catch {
            throw Abort(.unauthorized, reason: "Invalid or expired token")
        }
    }

    private func verifyIssuer(_ payload: SupabaseJWTPayload, on request: Request) throws {
        guard let expected = AuthConfiguration.expectedIssuer else { return }
        let actual = payload.issuer.value
        guard actual == expected else {
            request.logger.warning("Rejected token with unexpected issuer")
            throw Abort(.unauthorized, reason: "Invalid or expired token")
        }
    }
}
