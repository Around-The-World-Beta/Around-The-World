import Testing
import VaporTesting
import Fluent
@testable import App

@Suite("Around the World API", .serialized)
struct AppTests {
    @Test("health returns clean JSON")
    func health() async throws {
        try await withATWApp { app in
            try await app.testing().test(.GET, "health") { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode(HealthResponse.self)
                #expect(body.status == "ok")
                #expect(body.service == "around-the-world-api")
            }
        }
    }

    @Test("full games are hidden from browse and reappear after cancellation")
    func rosterDerivedVisibility() async throws {
        try await withATWApp { app in
            let host = User(email: "host-\(UUID())@test.dev", displayName: "Host")
            try await host.save(on: app.db)
            let hostID = try #require(host.id)

            let guest = User(email: "guest-\(UUID())@test.dev", displayName: "Guest")
            try await guest.save(on: app.db)
            let guestID = try #require(guest.id)

            let game = Game(
                hostID: hostID,
                title: "Capacity Two",
                venue: "Dolores Park",
                neighborhood: "Mission",
                skill: "Beginner",
                format: "5v5",
                capacity: 2,
                priceCents: 0,
                notes: "",
                startsAt: Date().addingTimeInterval(3600),
                latitude: 37.7597,
                longitude: -122.4269
            )
            try await game.save(on: app.db)
            let gameID = try #require(game.id)

            try await Participant(gameID: gameID, userID: hostID, status: .joined).save(on: app.db)
            try await Participant(gameID: gameID, userID: guestID, status: .joined).save(on: app.db)

            try await app.testing().test(.GET, "api/v1/games?includeFull=false&region=bay-area") { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode([GameResponse].self)
                #expect(!body.contains(where: { $0.id == gameID }))
            }

            try await app.testing().test(.GET, "api/v1/games/mine?userId=\(guestID.uuidString)") { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode([GameResponse].self)
                #expect(body.contains(where: { $0.id == gameID }))
            }

            let guestRow = try await Participant.query(on: app.db)
                .filter(\.$game.$id == gameID)
                .filter(\.$user.$id == guestID)
                .first()
            let participantID = try #require(guestRow?.id)
            try await app.testing().test(
                .PATCH,
                "api/v1/participants/\(participantID.uuidString)",
                beforeRequest: { req async throws in
                    try req.content.encode(UpdateParticipantRequest(status: "cancelled"))
                }
            ) { res async throws in
                #expect(res.status == .ok)
            }

            try await app.testing().test(.GET, "api/v1/games?includeFull=false&region=bay-area") { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode([GameResponse].self)
                #expect(body.contains(where: { $0.id == gameID && $0.joinedCount == 1 }))
            }
        }
    }
}
