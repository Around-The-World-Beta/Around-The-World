import Fluent
import Vapor

struct UsersController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("api", "v1", "users")
        users.get(use: index)
        users.post(use: create)
        users.group(":userID") { user in
            user.get(use: show)
            user.patch(use: update)
            user.delete(use: delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [UserResponse] {
        let users = try await User.query(on: req.db).sort(\.$createdAt, .descending).all()
        return try users.map { try UserResponse(user: $0) }
    }

    @Sendable
    func create(req: Request) async throws -> Response {
        let body = try req.content.decode(CreateUserRequest.self)
        let email = try APIValidation.validateEmail(body.email)
        let displayName = try APIValidation.validateDisplayName(body.displayName)
        let skill = try APIValidation.validateOptionalSkill(body.skillLevel)
        let position = try APIValidation.validateOptionalPosition(body.favoritePosition)

        if try await User.query(on: req.db).filter(\.$email == email).first() != nil {
            throw Abort(.conflict, reason: "A user with this email already exists")
        }

        let user = User(
            email: email,
            displayName: displayName,
            supabaseUserId: body.supabaseUserId
        )
        try await user.save(on: req.db)

        guard let userID = user.id else {
            throw Abort(.internalServerError, reason: "Failed to create user")
        }

        let profile = Profile(
            userID: userID,
            city: body.city?.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: body.bio?.trimmingCharacters(in: .whitespacesAndNewlines),
            favoritePosition: position,
            skillLevel: skill
        )
        try await profile.save(on: req.db)

        let payload = try UserResponse(user: user)
        let response = Response(status: .created)
        try response.content.encode(payload, as: .json)
        return response
    }

    @Sendable
    func show(req: Request) async throws -> UserResponse {
        let user = try await findUser(req)
        return try UserResponse(user: user)
    }

    @Sendable
    func update(req: Request) async throws -> UserResponse {
        let user = try await findUser(req)
        let body = try req.content.decode(UpdateUserRequest.self)

        if let email = body.email {
            let normalized = try APIValidation.validateEmail(email)
            if normalized != user.email,
               try await User.query(on: req.db).filter(\.$email == normalized).first() != nil
            {
                throw Abort(.conflict, reason: "A user with this email already exists")
            }
            user.email = normalized
        }
        if let displayName = body.displayName {
            user.displayName = try APIValidation.validateDisplayName(displayName)
        }
        if let supabaseUserId = body.supabaseUserId {
            user.supabaseUserId = supabaseUserId
        }

        try await user.update(on: req.db)
        return try UserResponse(user: user)
    }

    @Sendable
    func delete(req: Request) async throws -> APIMessage {
        let user = try await findUser(req)
        try await user.delete(on: req.db)
        return APIMessage(message: "User deleted")
    }

    private func findUser(_ req: Request) async throws -> User {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user id")
        }
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        return user
    }
}
