import Fluent
import Vapor

/// Report and block. Both require a verified token. Identity is never taken from the body.
struct SafetyController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.post("reports", use: createReport)
        routes.get("reports", use: listMyReports)
        routes.post("blocks", use: createBlock)
        routes.get("blocks", use: listMyBlocks)
        routes.delete("blocks", ":userID", use: unblock)
    }

    @Sendable
    func createReport(req: Request) async throws -> Response {
        let reporter = try req.requireAuthUser()
        let reporterID = try reporter.requireID()
        let body = try req.content.decode(CreateReportRequest.self)

        guard let targetType = ReportTargetType(rawValue: body.targetType.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw Abort(.badRequest, reason: "targetType must be user or game")
        }
        guard let reason = ReportReason(rawValue: body.reason.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw Abort(
                .badRequest,
                reason: "reason must be one of: \(ReportReason.allCases.map(\.rawValue).joined(separator: ", "))"
            )
        }
        let details = try APIValidation.UserContent.reportDetails(body.details)

        switch targetType {
        case .user:
            guard body.targetId != reporterID else {
                throw Abort(.badRequest, reason: "You cannot report yourself")
            }
            guard try await User.find(body.targetId, on: req.db) != nil else {
                throw Abort(.notFound, reason: "User not found")
            }
        case .game:
            guard try await Game.find(body.targetId, on: req.db) != nil else {
                throw Abort(.notFound, reason: "Game not found")
            }
        }

        if try await UserReport.query(on: req.db)
            .filter(\.$reporter.$id == reporterID)
            .filter(\.$targetType == targetType.rawValue)
            .filter(\.$targetId == body.targetId)
            .first() != nil
        {
            throw Abort(.conflict, reason: "You already reported this")
        }

        let report = UserReport(
            reporterID: reporterID,
            targetType: targetType,
            targetId: body.targetId,
            reason: reason,
            details: details
        )
        try await report.save(on: req.db)

        let payload = try ReportResponse(report: report)
        let response = Response(status: .created)
        try response.content.encode(payload, as: .json)
        return response
    }

    @Sendable
    func listMyReports(req: Request) async throws -> [ReportResponse] {
        let reporterID = try req.requireAuthUserID()
        let reports = try await UserReport.query(on: req.db)
            .filter(\.$reporter.$id == reporterID)
            .sort(\.$createdAt, .descending)
            .all()
        return try reports.map { try ReportResponse(report: $0) }
    }

    @Sendable
    func createBlock(req: Request) async throws -> Response {
        let blocker = try req.requireAuthUser()
        let blockerID = try blocker.requireID()
        let body = try req.content.decode(CreateBlockRequest.self)

        guard body.blockedUserId != blockerID else {
            throw Abort(.badRequest, reason: "You cannot block yourself")
        }
        guard try await User.find(body.blockedUserId, on: req.db) != nil else {
            throw Abort(.notFound, reason: "User not found")
        }

        if let existing = try await UserBlock.query(on: req.db)
            .filter(\.$blocker.$id == blockerID)
            .filter(\.$blocked.$id == body.blockedUserId)
            .first()
        {
            let payload = try BlockResponse(block: existing)
            let response = Response(status: .ok)
            try response.content.encode(payload, as: .json)
            return response
        }

        let block = UserBlock(blockerID: blockerID, blockedID: body.blockedUserId)
        try await block.save(on: req.db)

        let payload = try BlockResponse(block: block)
        let response = Response(status: .created)
        try response.content.encode(payload, as: .json)
        return response
    }

    @Sendable
    func listMyBlocks(req: Request) async throws -> [BlockResponse] {
        let blockerID = try req.requireAuthUserID()
        let blocks = try await UserBlock.query(on: req.db)
            .filter(\.$blocker.$id == blockerID)
            .sort(\.$createdAt, .descending)
            .all()
        return try blocks.map { try BlockResponse(block: $0) }
    }

    @Sendable
    func unblock(req: Request) async throws -> APIMessage {
        let blockerID = try req.requireAuthUserID()
        guard let blockedID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user id")
        }
        guard let block = try await UserBlock.query(on: req.db)
            .filter(\.$blocker.$id == blockerID)
            .filter(\.$blocked.$id == blockedID)
            .first()
        else {
            throw Abort(.notFound, reason: "Block not found")
        }
        try await block.delete(on: req.db)
        return APIMessage(message: "Unblocked")
    }
}
