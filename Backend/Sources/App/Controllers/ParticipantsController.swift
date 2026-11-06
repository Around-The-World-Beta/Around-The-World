import Fluent
import Vapor

struct ParticipantsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let participants = routes.grouped("participants")
        participants.post(use: create)
        participants.get("game", ":gameID", use: listByGame)
        participants.group(":participantID") { participant in
            participant.get(use: show)
            participant.patch(use: update)
            participant.delete(use: delete)
        }
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
        let userID = try req.requireAuthUserID()
        let body = try req.content.decode(CreateParticipantRequest.self)

        guard let game = try await Game.find(body.gameId, on: req.db) else {
            throw Abort(.badRequest, reason: "gameId does not reference an existing game")
        }
        guard game.status == GameStatus.scheduled.rawValue else {
            throw Abort(.badRequest, reason: "Cannot join a game that is not scheduled")
        }

        if try await Participant.query(on: req.db)
            .filter(\.$game.$id == body.gameId)
            .filter(\.$user.$id == userID)
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

        let participant = Participant(
            gameID: body.gameId,
            userID: userID,
            status: ParticipantStatus(rawValue: status) ?? .joined
        )
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
        try await requireOwnerOrHost(participant, on: req)
        return try ParticipantResponse(participant: participant)
    }

    @Sendable
    func update(req: Request) async throws -> ParticipantResponse {
        let participant = try await findParticipant(req)
        try requireSelf(participant, on: req)
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
        try requireSelf(participant, on: req)
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

    private func requireSelf(_ participant: Participant, on req: Request) throws {
        let userID = try req.requireAuthUserID()
        guard participant.$user.id == userID else {
            throw Abort(.forbidden, reason: "You can only change your own signup")
        }
    }

    private func requireOwnerOrHost(_ participant: Participant, on req: Request) async throws {
        let userID = try req.requireAuthUserID()
        if participant.$user.id == userID { return }
        guard let game = try await Game.find(participant.$game.id, on: req.db),
              game.$host.id == userID
        else {
            throw Abort(.forbidden, reason: "You cannot view this signup")
        }
    }
}
