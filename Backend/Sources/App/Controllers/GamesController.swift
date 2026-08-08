import Fluent
import Vapor

struct GamesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let games = routes.grouped("api", "v1", "games")
        games.get(use: index)
        games.post(use: create)
        games.get("mine", use: mine)
        games.group(":gameID") { game in
            game.get(use: show)
            game.patch(use: update)
            game.delete(use: delete)
        }
    }

    /// Browse listings for the Bay Area beta.
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

        var responses = try await mapGames(games, on: req.db)

        if region.lowercased() != "all" {
            responses = responses.filter {
                BayAreaRegion.contains(latitude: $0.latitude, longitude: $0.longitude)
            }
        }

        // spots_filled < spots_total  ≡  joinedCount < capacity
        if !includeFull {
            responses = responses.filter { $0.joinedCount < $0.capacity }
        }

        return responses
    }

    /// Sessions the user already signed up for (joined or waitlisted), including full ones.
    @Sendable
    func mine(req: Request) async throws -> [GameResponse] {
        guard let userID = try? req.query.get(UUID.self, at: "userId") else {
            throw Abort(.badRequest, reason: "userId query parameter is required")
        }

        let participations = try await Participant.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$status != ParticipantStatus.cancelled.rawValue)
            .all()
        let gameIDs = Set(participations.map(\.$game.id))
        guard !gameIDs.isEmpty else { return [] }

        let games = try await Game.query(on: req.db)
            .filter(\.$id ~~ Array(gameIDs))
            .sort(\.$startsAt, .ascending)
            .all()
        return try await mapGames(games, on: req.db)
    }

    @Sendable
    func create(req: Request) async throws -> Response {
        let body = try req.content.decode(CreateGameRequest.self)
        try await validateGameBody(body, on: req.db)

        let game = Game(
            hostID: body.hostUserId,
            title: try APIValidation.requireNonEmpty(body.title, field: "title"),
            venue: try APIValidation.requireNonEmpty(body.venue, field: "venue"),
            neighborhood: try APIValidation.requireNonEmpty(body.neighborhood, field: "neighborhood"),
            skill: try APIValidation.validateSkill(body.skill),
            format: try APIValidation.validateFormat(body.format),
            capacity: body.capacity,
            priceCents: body.priceCents,
            notes: body.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            startsAt: body.startsAt,
            latitude: body.latitude,
            longitude: body.longitude,
            imageUrl: body.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        try await game.save(on: req.db)

        // Host is automatically joined.
        if let gameID = game.id {
            let hostParticipant = Participant(gameID: gameID, userID: body.hostUserId, status: .joined)
            try await hostParticipant.save(on: req.db)
        }

        let payload = try GameResponse(game: game, joinedCount: 1)
        let response = Response(status: .created)
        try response.content.encode(payload, as: .json)
        return response
    }

    @Sendable
    func show(req: Request) async throws -> GameResponse {
        let game = try await findGame(req)
        let joinedCount = try await joinedCount(for: game, on: req.db)
        return try GameResponse(game: game, joinedCount: joinedCount)
    }

    @Sendable
    func update(req: Request) async throws -> GameResponse {
        let game = try await findGame(req)
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
            let joined = try await joinedCount(for: game, on: req.db)
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
            game.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let startsAt = body.startsAt {
            game.startsAt = startsAt
        }
        if let latitude = body.latitude, let longitude = body.longitude {
            try APIValidation.validateCoordinates(latitude: latitude, longitude: longitude)
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
        let joined = try await joinedCount(for: game, on: req.db)
        return try GameResponse(game: game, joinedCount: joined)
    }

    @Sendable
    func delete(req: Request) async throws -> APIMessage {
        let game = try await findGame(req)
        try await game.delete(on: req.db)
        return APIMessage(message: "Game deleted")
    }

    private func findGame(_ req: Request) async throws -> Game {
        guard let gameID = req.parameters.get("gameID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid game id")
        }
        guard let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        return game
    }

    private func validateGameBody(_ body: CreateGameRequest, on db: any Database) async throws {
        guard try await User.find(body.hostUserId, on: db) != nil else {
            throw Abort(.badRequest, reason: "hostUserId does not reference an existing user")
        }
        try APIValidation.validateCapacity(body.capacity)
        try APIValidation.validatePriceCents(body.priceCents)
        try APIValidation.validateCoordinates(latitude: body.latitude, longitude: body.longitude)
        guard BayAreaRegion.contains(latitude: body.latitude, longitude: body.longitude) else {
            throw Abort(.badRequest, reason: "Bay Area beta: session location must be inside the San Francisco Bay Area")
        }
    }

    private func joinedCount(for game: Game, on db: any Database) async throws -> Int {
        guard let gameID = game.id else { return 0 }
        return try await Participant.query(on: db)
            .filter(\.$game.$id == gameID)
            .filter(\.$status == ParticipantStatus.joined.rawValue)
            .count()
    }

    private func mapGames(_ games: [Game], on db: any Database) async throws -> [GameResponse] {
        var responses: [GameResponse] = []
        responses.reserveCapacity(games.count)
        for game in games {
            let joined = try await joinedCount(for: game, on: db)
            responses.append(try GameResponse(game: game, joinedCount: joined))
        }
        return responses
    }
}
