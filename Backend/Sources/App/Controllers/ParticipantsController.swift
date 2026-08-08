import Fluent
import Vapor

struct ParticipantsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let participants = routes.grouped("api", "v1", "participants")
        participants.get(use: index)
        participants.post(use: create)
        participants.group(":participantID") { participant in
            participant.get(use: show)
            participant.patch(use: update)
            participant.delete(use: delete)
        }
        participants.get("game", ":gameID", use: listByGame)
    }

    @Sendable
    func index(req: Request) async throws -> [ParticipantResponse] {
        let participants = try await Participant.query(on: req.db).sort(\.$createdAt, .descending).all()
        return try participants.map { try ParticipantResponse(participant: $0) }
    }

    @Sendable
    func listByGame(req: Request) async throws -> [ParticipantResponse] {
        guard let gameID = req.parameters.get("gameID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid game id")
        }
        let participants = try await Participant.query(on: req.db)
            .filter(\.$game.$id == gameID)
            .sort(\.$createdAt, .ascending)
            .all()
        return try participants.map { try ParticipantResponse(participant: $0) }
    }

    @Sendable
    func create(req: Request) async throws -> Response {
        let body = try req.content.decode(CreateParticipantRequest.self)

        guard let game = try await Game.find(body.gameId, on: req.db) else {
            throw Abort(.badRequest, reason: "gameId does not reference an existing game")
        }
        guard try await User.find(body.userId, on: req.db) != nil else {
            throw Abort(.badRequest, reason: "userId does not reference an existing user")
        }
        guard game.status == GameStatus.scheduled.rawValue else {
            throw Abort(.badRequest, reason: "Cannot join a game that is not scheduled")
        }

        if try await Participant.query(on: req.db)
            .filter(\.$game.$id == body.gameId)
            .filter(\.$user.$id == body.userId)
            .first() != nil
        {
            throw Abort(.conflict, reason: "User is already a participant of this game")
        }

        let requestedStatus = try APIValidation.validateParticipantStatus(body.status ?? ParticipantStatus.joined.rawValue)
        var status = requestedStatus

        if status == ParticipantStatus.joined.rawValue {
            let joined = try await Participant.query(on: req.db)
                .filter(\.$game.$id == body.gameId)
                .filter(\.$status == ParticipantStatus.joined.rawValue)
                .count()
            if joined >= game.capacity {
                status = ParticipantStatus.waitlist.rawValue
            }
        }

        let participant = Participant(gameID: body.gameId, userID: body.userId, status: ParticipantStatus(rawValue: status) ?? .joined)
        participant.status = status
        try await participant.save(on: req.db)

        let payload = try ParticipantResponse(participant: participant)
        let response = Response(status: .created)
        try response.content.encode(payload, as: .json)
        return response
    }

    @Sendable
    func show(req: Request) async throws -> ParticipantResponse {
        let participant = try await findParticipant(req)
        return try ParticipantResponse(participant: participant)
    }

    @Sendable
    func update(req: Request) async throws -> ParticipantResponse {
        let participant = try await findParticipant(req)
        let body = try req.content.decode(UpdateParticipantRequest.self)
        let status = try APIValidation.validateParticipantStatus(body.status)

        if status == ParticipantStatus.joined.rawValue {
            guard let game = try await Game.find(participant.$game.id, on: req.db) else {
                throw Abort(.notFound, reason: "Game not found")
            }
            let joined = try await Participant.query(on: req.db)
                .filter(\.$game.$id == participant.$game.id)
                .filter(\.$status == ParticipantStatus.joined.rawValue)
                .count()
            let alreadyJoined = participant.status == ParticipantStatus.joined.rawValue
            if !alreadyJoined, joined >= game.capacity {
                throw Abort(.conflict, reason: "Game is at capacity")
            }
        }

        participant.status = status
        try await participant.update(on: req.db)
        return try ParticipantResponse(participant: participant)
    }

    @Sendable
    func delete(req: Request) async throws -> APIMessage {
        let participant = try await findParticipant(req)
        try await participant.delete(on: req.db)
        return APIMessage(message: "Participant removed")
    }

    private func findParticipant(_ req: Request) async throws -> Participant {
        guard let participantID = req.parameters.get("participantID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid participant id")
        }
        guard let participant = try await Participant.find(participantID, on: req.db) else {
            throw Abort(.notFound, reason: "Participant not found")
        }
        return participant
    }
}
