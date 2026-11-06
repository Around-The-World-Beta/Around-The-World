import Fluent
import Vapor

/// A signed-in player reporting user-written text (a bio or a game's notes) or a player.
final class UserReport: Model, Content, @unchecked Sendable {
    static let schema = "user_reports"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "reporter_user_id")
    var reporter: User

    @Field(key: "target_type")
    var targetType: String

    @Field(key: "target_id")
    var targetId: UUID

    @Field(key: "reason")
    var reason: String

    @OptionalField(key: "details")
    var details: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        reporterID: UUID,
        targetType: ReportTargetType,
        targetId: UUID,
        reason: ReportReason,
        details: String? = nil
    ) {
        self.id = id
        self.$reporter.id = reporterID
        self.targetType = targetType.rawValue
        self.targetId = targetId
        self.reason = reason.rawValue
        self.details = details
    }
}
