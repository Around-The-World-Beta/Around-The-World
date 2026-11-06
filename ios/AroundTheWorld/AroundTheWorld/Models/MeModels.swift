import Foundation

/// `GET /api/v1/me` — current app user plus profile. Creates both on first login.
public struct MeResponse: Codable, Sendable, Equatable {
    public let user: UserResponse
    public let profile: ProfileResponse

    public init(user: UserResponse, profile: ProfileResponse) {
        self.user = user
        self.profile = profile
    }
}

/// `PATCH /api/v1/me` — display name only. Do not send a user id.
public struct UpdateMeRequest: Codable, Sendable, Equatable {
    public let displayName: String?

    public init(displayName: String?) {
        self.displayName = displayName
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(displayName, forKey: .displayName)
    }

    private enum CodingKeys: String, CodingKey {
        case displayName
    }
}
