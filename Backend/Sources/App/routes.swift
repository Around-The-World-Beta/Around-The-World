import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ async -> HealthResponse in
        HealthResponse(status: "ok", service: "around-the-world-api")
    }

    try app.register(collection: UsersController())
    try app.register(collection: ProfilesController())
    try app.register(collection: GamesController())
    try app.register(collection: ParticipantsController())
    try app.register(collection: FriendshipsController())
}

struct HealthResponse: Content {
    let status: String
    let service: String
}
