import Fluent
import Vapor

/// Signed-in account surface. Every handler uses `req.authUser` from the verified token.
struct MeController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let me = routes.grouped("me")
        me.get(use: show)
        me.patch(use: update)
        me.delete(use: delete)
        me.get("profile", use: showProfile)
        me.patch("profile", use: updateProfile)
        me.get("games", use: games)
        me.get("friendships", use: friendships)
    }

    @Sendable
    func show(req: Request) async throws -> MeResponse {
        try await meResponse(for: req.requireAuthUser(), on: req.db)
    }

    @Sendable
    func update(req: Request) async throws -> MeResponse {
        let user = try req.requireAuthUser()
        let body = try req.content.decode(UpdateMeRequest.self)
        try IdentityLink.rejectClientSupplied(body.supabaseUserId)
        if let displayName = body.displayName {
            user.displayName = try APIValidation.validateDisplayName(displayName)
            try await user.update(on: req.db)
        }
        return try await meResponse(for: user, on: req.db)
    }

    @Sendable
    func delete(req: Request) async throws -> APIMessage {
        let user = try req.requireAuthUser()
        try await user.delete(on: req.db)
        return APIMessage(message: "Account deleted")
    }

    @Sendable
    func showProfile(req: Request) async throws -> ProfileResponse {
        try ProfileResponse(profile: try await requireProfile(for: req.requireAuthUser(), on: req.db))
    }

    @Sendable
    func updateProfile(req: Request) async throws -> ProfileResponse {
        let user = try req.requireAuthUser()
        let profile = try await requireProfile(for: user, on: req.db)
        let body = try req.content.decode(UpdateProfileRequest.self)

        if let city = body.city {
            let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count <= 100 else {
                throw Abort(.badRequest, reason: "city must be at most 100 characters")
            }
            profile.city = trimmed.isEmpty ? nil : trimmed
        }
        if let bio = body.bio {
            let trimmed = bio.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count <= 200 else {
                throw Abort(.badRequest, reason: "bio must be at most 200 characters")
            }
            profile.bio = trimmed.isEmpty ? nil : trimmed
        }
        if body.favoritePosition != nil {
            profile.favoritePosition = try APIValidation.validateOptionalPosition(body.favoritePosition)
        }
        if body.skillLevel != nil {
            profile.skillLevel = try APIValidation.validateOptionalSkill(body.skillLevel)
        }
        if let avatarUrl = body.avatarUrl {
            let trimmed = avatarUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count <= 2048 else {
                throw Abort(.badRequest, reason: "avatarUrl must be at most 2048 characters")
            }
            profile.avatarUrl = trimmed.isEmpty ? nil : trimmed
        }
        if body.age != nil {
            profile.age = try APIValidation.validateOptionalAge(body.age)
        }

        try await profile.update(on: req.db)
        return try ProfileResponse(profile: profile)
    }

    @Sendable
    func games(req: Request) async throws -> [GameResponse] {
        let userID = try req.requireAuthUserID()
        let participations = try await Participant.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$status != ParticipantStatus.cancelled.rawValue)
            .all()
        let participatedIDs = Set(participations.map(\.$game.id))
        let hosted = try await Game.query(on: req.db).filter(\.$host.$id == userID).all()
        let hostedIDs = Set(hosted.compactMap(\.id))
        let gameIDs = participatedIDs.union(hostedIDs)
        guard !gameIDs.isEmpty else { return [] }

        let games = try await Game.query(on: req.db)
            .filter(\.$id ~~ Array(gameIDs))
            .sort(\.$startsAt, .ascending)
            .all()
        return try await GamesController.mapGames(games, on: req.db)
    }

    @Sendable
    func friendships(req: Request) async throws -> [FriendshipResponse] {
        let userID = try req.requireAuthUserID()
        let friendships = try await Friendship.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$user.$id == userID)
                group.filter(\.$friend.$id == userID)
            }
            .sort(\.$createdAt, .descending)
            .all()
        return try friendships.map { try FriendshipResponse(friendship: $0) }
    }

    private func requireProfile(for user: User, on db: any Database) async throws -> Profile {
        let userID = try user.requireID()
        if let profile = try await Profile.query(on: db).filter(\.$user.$id == userID).first() {
            return profile
        }
        let created = Profile(userID: userID)
        try await created.save(on: db)
        return created
    }

    private func meResponse(for user: User, on db: any Database) async throws -> MeResponse {
        let profile = try await requireProfile(for: user, on: db)
        return try MeResponse(user: UserResponse(user: user), profile: ProfileResponse(profile: profile))
    }
}
