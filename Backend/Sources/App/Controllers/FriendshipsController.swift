import Fluent
import Vapor

struct FriendshipsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let friendships = routes.grouped("friendships")
        friendships.post(use: create)
        friendships.group(":friendshipID") { friendship in
            friendship.get(use: show)
            friendship.patch(use: update)
            friendship.delete(use: delete)
        }
    }

    @Sendable
    func create(req: Request) async throws -> Response {
        let userID = try req.requireAuthUserID()
        let body = try req.content.decode(CreateFriendshipRequest.self)

        guard userID != body.friendUserId else {
            throw Abort(.badRequest, reason: "You cannot follow yourself")
        }
        guard try await User.find(body.friendUserId, on: req.db) != nil else {
            throw Abort(.badRequest, reason: "friendUserId does not reference an existing user")
        }

        if try await Friendship.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$friend.$id == body.friendUserId)
            .first() != nil
        {
            throw Abort(.conflict, reason: "Friendship already exists")
        }

        let status = try APIValidation.validateFriendshipStatus(body.status ?? FriendshipStatus.pending.rawValue)
        let friendship = Friendship(
            userID: userID,
            friendUserID: body.friendUserId,
            status: FriendshipStatus(rawValue: status) ?? .pending
        )
        friendship.status = status
        try await friendship.save(on: req.db)

        let payload = try FriendshipResponse(friendship: friendship)
        let response = Response(status: .created)
        try response.content.encode(payload, as: .json)
        return response
    }

    @Sendable
    func show(req: Request) async throws -> FriendshipResponse {
        let friendship = try await findFriendship(req)
        try requireParty(friendship, on: req)
        return try FriendshipResponse(friendship: friendship)
    }

    @Sendable
    func update(req: Request) async throws -> FriendshipResponse {
        let friendship = try await findFriendship(req)
        try requireParty(friendship, on: req)
        let body = try req.content.decode(UpdateFriendshipRequest.self)
        friendship.status = try APIValidation.validateFriendshipStatus(body.status)
        try await friendship.update(on: req.db)
        return try FriendshipResponse(friendship: friendship)
    }

    @Sendable
    func delete(req: Request) async throws -> APIMessage {
        let friendship = try await findFriendship(req)
        try requireParty(friendship, on: req)
        try await friendship.delete(on: req.db)
        return APIMessage(message: "Friendship deleted")
    }

    private func findFriendship(_ req: Request) async throws -> Friendship {
        guard let friendshipID = req.parameters.get("friendshipID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid friendship id")
        }
        guard let friendship = try await Friendship.find(friendshipID, on: req.db) else {
            throw Abort(.notFound, reason: "Friendship not found")
        }
        return friendship
    }

    private func requireParty(_ friendship: Friendship, on req: Request) throws {
        let userID = try req.requireAuthUserID()
        guard friendship.$user.id == userID || friendship.$friend.id == userID else {
            throw Abort(.forbidden, reason: "You can only change your own friend list")
        }
    }
}
