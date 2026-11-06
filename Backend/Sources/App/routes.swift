import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ async -> HealthResponse in
        HealthResponse(status: "ok", service: "around-the-world-api")
    }

    let v1 = app.grouped("api", "v1")

    v1.get("meta", "bay-area") { _ async -> BayAreaMetaResponse in
        .default
    }

    // Public browse. Identity is not involved, so no token is required.
    try v1.register(collection: GamesController())

    // Stale dump endpoints: refuse instead of listing everyone.
    v1.get("users") { _ async throws -> [UserResponse] in
        throw Abort(.unauthorized, reason: "User lists are private")
    }
    v1.post("users") { _ async throws -> UserResponse in
        throw Abort(.unauthorized, reason: "Accounts are created from a verified login token via GET /api/v1/me")
    }
    v1.get("profiles") { _ async throws -> [ProfileResponse] in
        throw Abort(.unauthorized, reason: "Profile lists are private. Use GET /api/v1/me/profile")
    }
    v1.get("participants") { _ async throws -> [ParticipantResponse] in
        throw Abort(.unauthorized, reason: "Participant lists are private")
    }
    v1.get("friendships") { _ async throws -> [FriendshipResponse] in
        throw Abort(.unauthorized, reason: "Friend lists are private. Use GET /api/v1/me/friendships")
    }
    v1.get("friendships", "user", ":userID") { _ async throws -> [FriendshipResponse] in
        throw Abort(.unauthorized, reason: "Friend lists are private. Use GET /api/v1/me/friendships")
    }
    v1.get("profiles", "user", ":userID") { _ async throws -> ProfileResponse in
        throw Abort(.unauthorized, reason: "Use GET /api/v1/me/profile for your profile, or GET /api/v1/players/:id")
    }
    v1.get("users", ":userID") { _ async throws -> UserResponse in
        throw Abort(.unauthorized, reason: "Email addresses are not public. Use GET /api/v1/players/:id")
    }
    v1.patch("users", ":userID") { _ async throws -> UserResponse in
        throw Abort(.unauthorized, reason: "Use PATCH /api/v1/me")
    }
    v1.delete("users", ":userID") { _ async throws -> APIMessage in
        throw Abort(.unauthorized, reason: "Use DELETE /api/v1/me to delete your own account")
    }
    v1.get("profiles", ":profileID") { _ async throws -> ProfileResponse in
        throw Abort(.unauthorized, reason: "Use GET /api/v1/me/profile")
    }
    v1.patch("profiles", ":profileID") { _ async throws -> ProfileResponse in
        throw Abort(.unauthorized, reason: "Use PATCH /api/v1/me/profile")
    }
    v1.delete("profiles", ":profileID") { _ async throws -> APIMessage in
        throw Abort(.unauthorized, reason: "Use DELETE /api/v1/me")
    }

    let authed = v1.grouped(RequireAuthMiddleware())
    try authed.register(collection: MeController())
    try authed.register(collection: UsersController())
    try authed.register(collection: GamesWriteController())
    try authed.register(collection: ParticipantsController())
    try authed.register(collection: FriendshipsController())
}

struct HealthResponse: Content {
    let status: String
    let service: String
}
