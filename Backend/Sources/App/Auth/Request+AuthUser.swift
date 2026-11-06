import Vapor

private struct AuthUserKey: StorageKey {
    typealias Value = User
}

extension Request {
    var authUser: User? {
        get { storage[AuthUserKey.self] }
        set { storage[AuthUserKey.self] = newValue }
    }

    func requireAuthUser() throws -> User {
        guard let user = authUser else {
            throw Abort(.unauthorized, reason: "Sign in required")
        }
        return user
    }

    func requireAuthUserID() throws -> UUID {
        try requireAuthUser().requireID()
    }
}
