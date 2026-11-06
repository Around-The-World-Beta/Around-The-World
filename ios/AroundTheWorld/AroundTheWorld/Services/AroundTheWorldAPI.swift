import Foundation

/// High-level async API surface that maps 1:1 onto Vapor `/api/v1` routes.
/// Uses `NetworkManager` under the hood so screens stay free of URL plumbing.
///
/// Authenticated calls need `setAccessToken` with the Supabase access token.
/// See `docs/auth-contract.md`.
public struct AroundTheWorldAPI: Sendable {
    private let network: NetworkManager

    public init(network: NetworkManager = .shared) {
        self.network = network
    }

    public func setAccessToken(_ token: String?) async {
        await network.setBearerToken(token)
    }

    // MARK: Health

    public func health() async throws -> HealthResponse {
        try await network.get("health")
    }

    // MARK: Account (`/me`)

    public func me() async throws -> MeResponse {
        try await network.get("api/v1/me")
    }

    public func updateMe(_ request: UpdateMeRequest) async throws -> MeResponse {
        try await network.patch("api/v1/me", body: request)
    }

    public func deleteAccount() async throws -> APIMessage {
        try await network.delete("api/v1/me")
    }

    public func myProfile() async throws -> ProfileResponse {
        try await network.get("api/v1/me/profile")
    }

    public func updateMyProfile(_ request: UpdateProfileRequest) async throws -> ProfileResponse {
        try await network.patch("api/v1/me/profile", body: request)
    }

    public func getPlayer(id: UUID) async throws -> PublicPlayerResponse {
        try await network.get("api/v1/players/\(id.uuidString)")
    }

    // MARK: Games

    /// Browse open Bay Area sessions (`joinedCount < capacity` by default). Public.
    public func listGames(includeFull: Bool = false, region: String = "bay-area") async throws -> [GameResponse] {
        try await network.get(
            "api/v1/games",
            queryItems: [
                URLQueryItem(name: "includeFull", value: includeFull ? "true" : "false"),
                URLQueryItem(name: "region", value: region),
            ]
        )
    }

    /// Sessions the signed-in user hosts or has joined/waitlisted — includes full games.
    public func listMyGames() async throws -> [GameResponse] {
        try await network.get("api/v1/me/games")
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

    public func listMyFriendships() async throws -> [FriendshipResponse] {
        try await network.get("api/v1/me/friendships")
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
