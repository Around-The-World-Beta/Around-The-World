import Fluent
import Vapor

struct ProfilesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let profiles = routes.grouped("api", "v1", "profiles")
        profiles.get(use: index)
        profiles.group(":profileID") { profile in
            profile.get(use: show)
            profile.patch(use: update)
            profile.delete(use: delete)
        }
        profiles.get("user", ":userID", use: showByUser)
    }

    @Sendable
    func index(req: Request) async throws -> [ProfileResponse] {
        let profiles = try await Profile.query(on: req.db).sort(\.$createdAt, .descending).all()
        return try profiles.map { try ProfileResponse(profile: $0) }
    }

    @Sendable
    func show(req: Request) async throws -> ProfileResponse {
        let profile = try await findProfile(req)
        return try ProfileResponse(profile: profile)
    }

    @Sendable
    func showByUser(req: Request) async throws -> ProfileResponse {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user id")
        }
        guard let profile = try await Profile.query(on: req.db).filter(\.$user.$id == userID).first() else {
            throw Abort(.notFound, reason: "Profile not found")
        }
        return try ProfileResponse(profile: profile)
    }

    @Sendable
    func update(req: Request) async throws -> ProfileResponse {
        let profile = try await findProfile(req)
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

        try await profile.update(on: req.db)
        return try ProfileResponse(profile: profile)
    }

    @Sendable
    func delete(req: Request) async throws -> APIMessage {
        let profile = try await findProfile(req)
        try await profile.delete(on: req.db)
        return APIMessage(message: "Profile deleted")
    }

    private func findProfile(_ req: Request) async throws -> Profile {
        guard let profileID = req.parameters.get("profileID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid profile id")
        }
        guard let profile = try await Profile.find(profileID, on: req.db) else {
            throw Abort(.notFound, reason: "Profile not found")
        }
        return profile
    }
}
