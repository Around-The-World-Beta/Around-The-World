import Fluent
import Vapor

struct GamesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let games = routes.grouped("games")
        games.grouped(OptionalAuthMiddleware()).get(use: index)
        games.get("mine", use: refuseLegacyMine)
        games.get(":gameID", use: show)
    }

    /// Browse listings for the Bay Area beta. Public — no token required.
    ///
    /// Visibility is derived from the live roster (`joinedCount < capacity`), not a
    /// stored "hidden" flag — a cancellation that frees a spot reopens the listing
    /// automatically. Query params:
    /// - `includeFull` (default `false`): when false, omit fully booked sessions
    /// - `region` (default `bay-area`): geographic filter; `all` disables it
    @Sendable
    func index(req: Request) async throws -> [GameResponse] {
        let includeFull = (try? req.query.get(Bool.self, at: "includeFull")) ?? false
        let region = (try? req.query.get(String.self, at: "region")) ?? "bay-area"

        let games = try await Game.query(on: req.db)
            .filter(\.$status == GameStatus.scheduled.rawValue)
            .sort(\.$startsAt, .ascending)
            .all()

        var responses = try await Self.mapGames(games, on: req.db)

        if region.lowercased() != "all" {
            responses = responses.filter {
                BayAreaRegion.contains(latitude: $0.latitude, longitude: $0.longitude)
            }
        }

        if !includeFull {
            responses = responses.filter { $0.joinedCount < $0.capacity }
        }

        if let userID = req.authUser?.id {
            let hidden = try await UserBlock.hiddenUserIDs(for: userID, on: req.db)
            if !hidden.isEmpty {
                responses = responses.filter { !hidden.contains($0.hostUserId) }
            }
        }

        return responses
    }

    /// Old clients asked `GET /games/mine?userId=`. That leaked other people's schedules.
    @Sendable
    func refuseLegacyMine(req: Request) async throws -> [GameResponse] {
        if req.query[String.self, at: "userId"] != nil {
            throw Abort(
                .unauthorized,
                reason: "userId is taken from the auth token. Use GET /api/v1/me/games"
            )
        }
        throw Abort(.unauthorized, reason: "Sign in required. Use GET /api/v1/me/games")
    }

    @Sendable
    func show(req: Request) async throws -> GameResponse {
        let game = try await Self.findGame(req)
        let joinedCount = try await Self.joinedCount(for: game, on: req.db)
        return try GameResponse(game: game, joinedCount: joinedCount)
    }

    static func findGame(_ req: Request) async throws -> Game {
        guard let gameID = req.parameters.get("gameID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid game id")
        }
        guard let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        return game
    }

    static func joinedCount(for game: Game, on db: any Database) async throws -> Int {
        guard let gameID = game.id else { return 0 }
        return try await Participant.query(on: db)
            .filter(\.$game.$id == gameID)
            .filter(\.$status == ParticipantStatus.joined.rawValue)
            .count()
    }

    static func mapGames(_ games: [Game], on db: any Database) async throws -> [GameResponse] {
        var responses: [GameResponse] = []
        responses.reserveCapacity(games.count)
        for game in games {
            let joined = try await joinedCount(for: game, on: db)
            responses.append(try GameResponse(game: game, joinedCount: joined))
        }
        return responses
    }

    static func requireHost(_ game: Game, userID: UUID) throws {
        guard game.$host.id == userID else {
            throw Abort(.forbidden, reason: "Only the host can change this game")
        }
    }
}

struct GamesWriteController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let games = routes.grouped("games")
        games.post(use: create)
        games.group(":gameID") { game in
            game.patch(use: update)
            game.delete(use: delete)
        }
    }

    @Sendable
    func create(req: Request) async throws -> Response {
        let hostID = try req.requireAuthUserID()
        let body = try req.content.decode(CreateGameRequest.self)
        try Self.validateGameBody(body)

        let game = Game(
            hostID: hostID,
            title: try APIValidation.requireNonEmpty(body.title, field: "title"),
            venue: try APIValidation.requireNonEmpty(body.venue, field: "venue"),
            neighborhood: try APIValidation.requireNonEmpty(body.neighborhood, field: "neighborhood"),
            skill: try APIValidation.validateSkill(body.skill),
            format: try APIValidation.validateFormat(body.format),
            capacity: body.capacity,
            priceCents: body.priceCents,
            notes: try APIValidation.UserContent.notes(body.notes),
            startsAt: body.startsAt,
            latitude: body.latitude,
            longitude: body.longitude,
            imageUrl: body.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        try await game.save(on: req.db)

        if let gameID = game.id {
            let hostParticipant = Participant(gameID: gameID, userID: hostID, status: .joined)
            try await hostParticipant.save(on: req.db)
        }

        let payload = try GameResponse(game: game, joinedCount: 1)
        let response = Response(status: .created)
        try response.content.encode(payload, as: .json)
        return response
    }

    @Sendable
    func update(req: Request) async throws -> GameResponse {
        let userID = try req.requireAuthUserID()
        let game = try await GamesController.findGame(req)
        try GamesController.requireHost(game, userID: userID)
        let body = try req.content.decode(UpdateGameRequest.self)

        if let title = body.title {
            game.title = try APIValidation.requireNonEmpty(title, field: "title")
        }
        if let venue = body.venue {
            game.venue = try APIValidation.requireNonEmpty(venue, field: "venue")
        }
        if let neighborhood = body.neighborhood {
            game.neighborhood = try APIValidation.requireNonEmpty(neighborhood, field: "neighborhood")
        }
        if let skill = body.skill {
            game.skill = try APIValidation.validateSkill(skill)
        }
        if let format = body.format {
            game.format = try APIValidation.validateFormat(format)
        }
        if let capacity = body.capacity {
            try APIValidation.validateCapacity(capacity)
            let joined = try await GamesController.joinedCount(for: game, on: req.db)
            guard capacity >= joined else {
                throw Abort(.badRequest, reason: "capacity cannot be less than current joined count (\(joined))")
            }
            game.capacity = capacity
        }
        if let priceCents = body.priceCents {
            try APIValidation.validatePriceCents(priceCents)
            game.priceCents = priceCents
        }
        if let notes = body.notes {
            game.notes = try APIValidation.UserContent.notes(notes)
        }
        if let startsAt = body.startsAt {
            game.startsAt = startsAt
        }
        if let latitude = body.latitude, let longitude = body.longitude {
            try APIValidation.validateCoordinates(latitude: latitude, longitude: longitude)
            guard BayAreaRegion.contains(latitude: latitude, longitude: longitude) else {
                throw Abort(.badRequest, reason: "Bay Area beta: session location must be inside the San Francisco Bay Area")
            }
            game.latitude = latitude
            game.longitude = longitude
        } else if body.latitude != nil || body.longitude != nil {
            throw Abort(.badRequest, reason: "latitude and longitude must be provided together")
        }
        if let status = body.status {
            game.status = try APIValidation.validateGameStatus(status)
        }
        if let imageUrl = body.imageUrl {
            let trimmed = imageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            game.imageUrl = trimmed.isEmpty ? nil : trimmed
        }

        try await game.update(on: req.db)
        let joined = try await GamesController.joinedCount(for: game, on: req.db)
        return try GameResponse(game: game, joinedCount: joined)
    }

    @Sendable
    func delete(req: Request) async throws -> APIMessage {
        let userID = try req.requireAuthUserID()
        let game = try await GamesController.findGame(req)
        try GamesController.requireHost(game, userID: userID)
        try await game.delete(on: req.db)
        return APIMessage(message: "Game deleted")
    }

    private static func validateGameBody(_ body: CreateGameRequest) throws {
        try APIValidation.validateCapacity(body.capacity)
        try APIValidation.validatePriceCents(body.priceCents)
        try APIValidation.validateCoordinates(latitude: body.latitude, longitude: body.longitude)
        guard BayAreaRegion.contains(latitude: body.latitude, longitude: body.longitude) else {
            throw Abort(.badRequest, reason: "Bay Area beta: session location must be inside the San Francisco Bay Area")
        }
    }
}
