import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import AroundTheWorldKit

@Suite("Live Vapor API", .serialized)
struct LiveAPITests {
    @Test("health + listGames against local Vapor when available")
    func liveHealthAndGames() async throws {
        let network = NetworkManager(configuration: .localDevelopment)
        let api = AroundTheWorldAPI(network: network)

        do {
            let health = try await api.health()
            #expect(health.status == "ok")
            #expect(health.service == "around-the-world-api")

            let games = try await api.listGames()
            // Presence is enough — seed data may vary between runs.
            _ = games
        } catch let error as APIError {
            if case .transport = error {
                // Vapor not running in this environment — skip rather than fail CI.
                return
            }
            throw error
        }
    }
}
