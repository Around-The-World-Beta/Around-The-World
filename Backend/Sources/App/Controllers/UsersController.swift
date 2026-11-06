import Fluent
import Vapor

/// Public player cards. Email addresses are never returned here.
/// Listing every user, creating users from a body, and editing/deleting by id are gone.
struct UsersController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.get("players", ":userID", use: publicProfile)
    }

    @Sendable
    func publicProfile(req: Request) async throws -> PublicPlayerResponse {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user id")
        }
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        let profile = try await Profile.query(on: req.db).filter(\.$user.$id == userID).first()
        return try PublicPlayerResponse(user: user, profile: profile)
    }
}
