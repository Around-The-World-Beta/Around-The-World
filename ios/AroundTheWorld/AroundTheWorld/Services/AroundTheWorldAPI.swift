import Foundation

/// High-level async API surface that maps 1:1 onto Vapor `/api/v1` routes.
/// Uses `NetworkManager` under the hood so screens stay free of URL plumbing.
public struct AroundTheWorldAPI: Sendable {
    private let network: NetworkManager

    public init(network: NetworkManager = .shared) {
        self.network = network
    }

    // MARK: Health

    public func health() async throws -> HealthResponse {
        try await network.get("health")
    }

    // MARK: Users

    public func listUsers() async throws -> [UserResponse] {
        try await network.get("api/v1/users")
    }

    public func getUser(id: UUID) async throws -> UserResponse {
        try await network.get("api/v1/users/\(id.uuidString)")
    }

    public func createUser(_ request: CreateUserRequest) async throws -> UserResponse {
        try await network.post("api/v1/users", body: request)
    }

    public func updateUser(id: UUID, _ request: UpdateUserRequest) async throws -> UserResponse {
        try await network.patch("api/v1/users/\(id.uuidString)", body: request)
    }

    public func deleteUser(id: UUID) async throws -> APIMessage {
        try await network.delete("api/v1/users/\(id.uuidString)")
    }

    // MARK: Profiles

    public func listProfiles() async throws -> [ProfileResponse] {
        try await network.get("api/v1/profiles")
    }

    public func getProfile(id: UUID) async throws -> ProfileResponse {
        try await network.get("api/v1/profiles/\(id.uuidString)")
    }

    public func getProfile(userId: UUID) async throws -> ProfileResponse {
        try await network.get("api/v1/profiles/user/\(userId.uuidString)")
    }

    public func updateProfile(id: UUID, _ request: UpdateProfileRequest) async throws -> ProfileResponse {
        try await network.patch("api/v1/profiles/\(id.uuidString)", body: request)
    }

    public func deleteProfile(id: UUID) async throws -> APIMessage {
        try await network.delete("api/v1/profiles/\(id.uuidString)")
    }

    // MARK: Games

    /// Browse open Bay Area sessions (`joinedCount < capacity` by default).
    public func listGames(includeFull: Bool = false, region: String = "bay-area") async throws -> [GameResponse] {
        try await network.get(
            "api/v1/games",
            queryItems: [
                URLQueryItem(name: "includeFull", value: includeFull ? "true" : "false"),
                URLQueryItem(name: "region", value: region),
            ]
        )
    }

    /// Sessions the user already joined/waitlisted — includes full games.
    public func listMyGames(userId: UUID) async throws -> [GameResponse] {
        try await network.get(
            "api/v1/games/mine",
            queryItems: [URLQueryItem(name: "userId", value: userId.uuidString)]
        )
    }

    public func getGame(id: UUID) async throws -> GameResponse {
        try await network.get("api/v1/games/\(id.uuidString)")
    }

    public func createGame(_ request: CreateGameRequest) async throws -> GameResponse {
        try await network.post("api/v1/games", body: request)
    }

    public func updateGame(id: UUID, _ request: UpdateGameRequest) async throws -> GameResponse {
        try await network.patch("api/v1/games/\(id.uuidString)", body: request)
    }

    public func deleteGame(id: UUID) async throws -> APIMessage {
        try await network.delete("api/v1/games/\(id.uuidString)")
    }

    // MARK: Participants

    public func listParticipants() async throws -> [ParticipantResponse] {
        try await network.get("api/v1/participants")
    }

    public func listParticipants(gameId: UUID) async throws -> [ParticipantResponse] {
        try await network.get("api/v1/participants/game/\(gameId.uuidString)")
    }

    public func getParticipant(id: UUID) async throws -> ParticipantResponse {
        try await network.get("api/v1/participants/\(id.uuidString)")
    }

    public func createParticipant(_ request: CreateParticipantRequest) async throws -> ParticipantResponse {
        try await network.post("api/v1/participants", body: request)
    }

    public func updateParticipant(id: UUID, _ request: UpdateParticipantRequest) async throws -> ParticipantResponse {
        try await network.patch("api/v1/participants/\(id.uuidString)", body: request)
    }

    public func deleteParticipant(id: UUID) async throws -> APIMessage {
        try await network.delete("api/v1/participants/\(id.uuidString)")
    }

    // MARK: Friendships

    public func listFriendships() async throws -> [FriendshipResponse] {
        try await network.get("api/v1/friendships")
    }

    public func listFriendships(userId: UUID) async throws -> [FriendshipResponse] {
        try await network.get("api/v1/friendships/user/\(userId.uuidString)")
    }

    public func getFriendship(id: UUID) async throws -> FriendshipResponse {
        try await network.get("api/v1/friendships/\(id.uuidString)")
    }

    public func createFriendship(_ request: CreateFriendshipRequest) async throws -> FriendshipResponse {
        try await network.post("api/v1/friendships", body: request)
    }

    public func updateFriendship(id: UUID, _ request: UpdateFriendshipRequest) async throws -> FriendshipResponse {
        try await network.patch("api/v1/friendships/\(id.uuidString)", body: request)
    }

    public func deleteFriendship(id: UUID) async throws -> APIMessage {
        try await network.delete("api/v1/friendships/\(id.uuidString)")
    }
}
