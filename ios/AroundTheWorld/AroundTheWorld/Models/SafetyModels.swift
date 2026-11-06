import Foundation

enum ReportTargetType: String, Codable, Sendable {
    case user
    case game
}

enum ReportReason: String, CaseIterable, Identifiable, Sendable {
    case spam
    case harassment
    case inappropriate
    case fake
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .spam: return L10n.reportReasonSpam
        case .harassment: return L10n.reportReasonHarassment
        case .inappropriate: return L10n.reportReasonInappropriate
        case .fake: return L10n.reportReasonFake
        case .other: return L10n.reportReasonOther
        }
    }
}

public struct ReportResponse: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let reporterUserId: UUID
    public let targetType: String
    public let targetId: UUID
    public let reason: String
    public let details: String?
    public let createdAt: Date?
}

public struct CreateReportRequest: Codable, Sendable, Equatable {
    public let targetType: String
    public let targetId: UUID
    public let reason: String
    public let details: String?

    public init(targetType: ReportTargetType, targetId: UUID, reason: ReportReason, details: String? = nil) {
        self.targetType = targetType.rawValue
        self.targetId = targetId
        self.reason = reason.rawValue
        self.details = details
    }
}

public struct BlockResponse: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let blockerUserId: UUID
    public let blockedUserId: UUID
    public let createdAt: Date?
}

public struct CreateBlockRequest: Codable, Sendable, Equatable {
    public let blockedUserId: UUID

    public init(blockedUserId: UUID) {
        self.blockedUserId = blockedUserId
    }
}
