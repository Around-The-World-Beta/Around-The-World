import Fluent
import Vapor

/// How an Around The World account relates to a Supabase Auth login.
///
/// This service owns every application table (`users`, `profiles`, `games`,
/// `participants`, `friendships`). Supabase owns `auth.users` and nothing else.
/// The two are joined by `users.supabase_user_id`.
///
/// That column is only ever written from the `sub` claim of a verified Supabase JWT.
/// It is never accepted from a request body: a client that could choose its own
/// `supabase_user_id` could attach itself to any other person's login.
enum IdentityLink {
    /// Rejects a client-supplied Supabase user id.
    static func rejectClientSupplied(_ supabaseUserId: UUID?) throws {
        guard supabaseUserId == nil else {
            throw Abort(
                .forbidden,
                reason: "supabaseUserId is derived from the verified auth token and cannot be set by a client"
            )
        }
    }

    /// Finds or creates the app user for a verified token.
    static func user(from payload: SupabaseJWTPayload, on db: any Database) async throws -> User {
        let sub = try payload.supabaseUserID()
        if let existing = try await User.query(on: db).filter(\.$supabaseUserId == sub).first() {
            return existing
        }

        let email = payload.normalizedEmail ?? "u-\(sub.uuidString.lowercased())@account.aroundtheworld.app"
        if try await User.query(on: db).filter(\.$email == email).first() != nil {
            throw Abort(
                .conflict,
                reason: "An account with this email already exists and is not linked to this login"
            )
        }

        let user = User(
            email: email,
            displayName: payload.preferredDisplayName,
            supabaseUserId: sub
        )
        do {
            try await user.save(on: db)
        } catch {
            if let raced = try await User.query(on: db).filter(\.$supabaseUserId == sub).first() {
                return raced
            }
            throw error
        }

        let userID = try user.requireID()
        if try await Profile.query(on: db).filter(\.$user.$id == userID).first() == nil {
            try await Profile(userID: userID).save(on: db)
        }
        return user
    }
}
