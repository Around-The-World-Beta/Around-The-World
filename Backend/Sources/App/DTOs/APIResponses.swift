import Vapor

struct APIMessage: Content {
    let message: String
}

struct UserResponse: Content {
    let id: UUID
    let email: String
    let displayName: String
    let supabaseUserId: UUID?
    let createdAt: Date?
    let updatedAt: Date?

    init(user: User) throws {
        guard let id = user.id else {
            throw Abort(.internalServerError, reason: "User missing id")
        }
        self.id = id
        self.email = user.email
        self.displayName = user.displayName
        self.supabaseUserId = user.supabaseUserId
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
    }
}

struct MeResponse: Content {
    let user: UserResponse
    let profile: ProfileResponse
}

struct UpdateMeRequest: Content {
    let displayName: String?
    /// Still decoded so a stale client sending it gets an explicit error.
    let supabaseUserId: UUID?
}

struct PublicPlayerResponse: Content {
    let id: UUID
    let displayName: String
    let city: String?
    let bio: String?
    let favoritePosition: String?
    let skillLevel: String?
    let avatarUrl: String?
    let age: Int?

    init(user: User, profile: Profile?) throws {
        guard let id = user.id else {
            throw Abort(.internalServerError, reason: "User missing id")
        }
        self.id = id
        self.displayName = user.displayName
        self.city = profile?.city
        self.bio = profile?.bio
        self.favoritePosition = profile?.favoritePosition
        self.skillLevel = profile?.skillLevel
        self.avatarUrl = profile?.avatarUrl
        self.age = profile?.age
    }
}

struct ProfileResponse: Content {
    let id: UUID
    let userId: UUID
    let city: String?
    let bio: String?
    let favoritePosition: String?
    let skillLevel: String?
    let avatarUrl: String?
    let age: Int?
    let createdAt: Date?
    let updatedAt: Date?

    init(profile: Profile) throws {
        guard let id = profile.id else {
            throw Abort(.internalServerError, reason: "Profile missing id")
        }
        self.id = id
        self.userId = profile.$user.id
        self.city = profile.city
        self.bio = profile.bio
        self.favoritePosition = profile.favoritePosition
        self.skillLevel = profile.skillLevel
        self.avatarUrl = profile.avatarUrl
        self.age = profile.age
        self.createdAt = profile.createdAt
        self.updatedAt = profile.updatedAt
    }
}

struct UpdateProfileRequest: Content {
    let city: String?
    let bio: String?
    let favoritePosition: String?
    let skillLevel: String?
    let avatarUrl: String?
    let age: Int?
}

struct GameResponse: Content {
    let id: UUID
    let hostUserId: UUID
    let title: String
    let venue: String
    let neighborhood: String
    let skill: String
    let format: String
    let capacity: Int
    let joinedCount: Int
    let priceCents: Int
    let notes: String
    let startsAt: Date
    let latitude: Double
    let longitude: Double
    let status: String
    let imageUrl: String?
    let createdAt: Date?
    let updatedAt: Date?

    init(game: Game, joinedCount: Int) throws {
        guard let id = game.id else {
            throw Abort(.internalServerError, reason: "Game missing id")
        }
        self.id = id
        self.hostUserId = game.$host.id
        self.title = game.title
        self.venue = game.venue
        self.neighborhood = game.neighborhood
        self.skill = game.skill
        self.format = game.format
        self.capacity = game.capacity
        self.joinedCount = joinedCount
        self.priceCents = game.priceCents
        self.notes = game.notes
        self.startsAt = game.startsAt
        self.latitude = game.latitude
        self.longitude = game.longitude
        self.status = game.status
        self.imageUrl = game.imageUrl
        self.createdAt = game.createdAt
        self.updatedAt = game.updatedAt
    }
}

struct CreateGameRequest: Content {
    let title: String
    let venue: String
    let neighborhood: String
    let skill: String
    let format: String
    let capacity: Int
    let priceCents: Int
    let notes: String
    let startsAt: Date
    let latitude: Double
    let longitude: Double
    let imageUrl: String?
}

struct UpdateGameRequest: Content {
    let title: String?
    let venue: String?
    let neighborhood: String?
    let skill: String?
    let format: String?
    let capacity: Int?
    let priceCents: Int?
    let notes: String?
    let startsAt: Date?
    let latitude: Double?
    let longitude: Double?
    let status: String?
    let imageUrl: String?
}

struct ParticipantResponse: Content {
    let id: UUID
    let gameId: UUID
    let userId: UUID
    let status: String
    let createdAt: Date?
    let updatedAt: Date?

    init(participant: Participant) throws {
        guard let id = participant.id else {
            throw Abort(.internalServerError, reason: "Participant missing id")
        }
        self.id = id
        self.gameId = participant.$game.id
        self.userId = participant.$user.id
        self.status = participant.status
        self.createdAt = participant.createdAt
        self.updatedAt = participant.updatedAt
    }
}

struct CreateParticipantRequest: Content {
    let gameId: UUID
    let status: String?
}

struct UpdateParticipantRequest: Content {
    let status: String
}

struct FriendshipResponse: Content {
    let id: UUID
    let userId: UUID
    let friendUserId: UUID
    let status: String
    let createdAt: Date?
    let updatedAt: Date?

    init(friendship: Friendship) throws {
        guard let id = friendship.id else {
            throw Abort(.internalServerError, reason: "Friendship missing id")
        }
        self.id = id
        self.userId = friendship.$user.id
        self.friendUserId = friendship.$friend.id
        self.status = friendship.status
        self.createdAt = friendship.createdAt
        self.updatedAt = friendship.updatedAt
    }
}

struct CreateFriendshipRequest: Content {
    let friendUserId: UUID
    let status: String?
}

struct UpdateFriendshipRequest: Content {
    let status: String
}

enum ReportTargetType: String, Codable, CaseIterable, Sendable {
    case user
    case game
}

enum ReportReason: String, Codable, CaseIterable, Sendable {
    case spam
    case harassment
    case inappropriate
    case fake
    case other
}

struct ReportResponse: Content {
    let id: UUID
    let reporterUserId: UUID
    let targetType: String
    let targetId: UUID
    let reason: String
    let details: String?
    let createdAt: Date?

    init(report: UserReport) throws {
        guard let id = report.id else {
            throw Abort(.internalServerError, reason: "Report missing id")
        }
        self.id = id
        self.reporterUserId = report.$reporter.id
        self.targetType = report.targetType
        self.targetId = report.targetId
        self.reason = report.reason
        self.details = report.details
        self.createdAt = report.createdAt
    }
}

struct CreateReportRequest: Content {
    let targetType: String
    let targetId: UUID
    let reason: String
    let details: String?
}

struct BlockResponse: Content {
    let id: UUID
    let blockerUserId: UUID
    let blockedUserId: UUID
    let createdAt: Date?

    init(block: UserBlock) throws {
        guard let id = block.id else {
            throw Abort(.internalServerError, reason: "Block missing id")
        }
        self.id = id
        self.blockerUserId = block.$blocker.id
        self.blockedUserId = block.$blocked.id
        self.createdAt = block.createdAt
    }
}

struct CreateBlockRequest: Content {
    let blockedUserId: UUID
}
