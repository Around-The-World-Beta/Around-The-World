import Vapor

/// How an Around The World account relates to a Supabase Auth login.
///
/// This service owns every application table (`users`, `profiles`, `games`,
/// `participants`, `friendships`). Supabase owns `auth.users` and nothing else.
/// The two are joined by `users.supabase_user_id`.
///
/// That column is only ever written from the `sub` claim of a verified Supabase JWT.
/// It is never accepted from a request body: a client that could choose its own
/// `supabase_user_id` could attach itself to any other person's login, which is the
/// whole point of having the link in the first place.
///
/// Token verification itself is not implemented yet — it is the next workstream. Until
/// it lands, nothing writes this column, and requests that try to set it are rejected
/// rather than quietly accepted.
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
}
