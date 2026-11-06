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
                skill: SkillLevel.casual.rawValue,
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

    @Test("canonical skill tiers match the product design")
    func canonicalSkillTiers() async throws {
        #expect(SkillLevel.allCases.map(\.rawValue) == ["Casual", "Intermediate", "Baller", "Open to All"])
        #expect(!APIValidation.allowedSkills.contains("Beginner"))
    }

    @Test("legacy skill tier is rewritten on write, not stored")
    func legacySkillTierNormalized() async throws {
        try await withATWApp { app in
            try await app.testing().test(
                .POST,
                "api/v1/users",
                beforeRequest: { req async throws in
                    try req.content.encode(
                        CreateUserRequest(
                            email: "legacy-\(UUID())@test.dev",
                            displayName: "Legacy Tier",
                            supabaseUserId: nil,
                            city: nil,
                            bio: nil,
                            favoritePosition: nil,
                            skillLevel: "Beginner"
                        )
                    )
                }
            ) { res async throws in
                #expect(res.status == .created)
                let user = try res.content.decode(UserResponse.self)
                let profile = try await Profile.query(on: app.db)
                    .filter(\.$user.$id == user.id)
                    .first()
                #expect(profile?.skillLevel == SkillLevel.casual.rawValue)
            }
        }
    }

    @Test("unknown skill tier is rejected")
    func unknownSkillTierRejected() async throws {
        try await withATWApp { app in
            try await app.testing().test(
                .POST,
                "api/v1/users",
                beforeRequest: { req async throws in
                    try req.content.encode(
                        CreateUserRequest(
                            email: "bad-tier-\(UUID())@test.dev",
                            displayName: "Bad Tier",
                            supabaseUserId: nil,
                            city: nil,
                            bio: nil,
                            favoritePosition: nil,
                            skillLevel: "Could've Been Pro"
                        )
                    )
                }
            ) { res async throws in
                #expect(res.status == .badRequest)
            }
        }
    }

    /// A client that can choose its own `supabase_user_id` can attach itself to anyone
    /// else's login, so the column is only ever written from a verified token.
    @Test("client-supplied supabaseUserId is refused")
    func clientSuppliedSupabaseIDRefused() async throws {
        try await withATWApp { app in
            try await app.testing().test(
                .POST,
                "api/v1/users",
                beforeRequest: { req async throws in
                    try req.content.encode(
                        CreateUserRequest(
                            email: "spoof-\(UUID())@test.dev",
                            displayName: "Spoofer",
                            supabaseUserId: UUID(),
                            city: nil,
                            bio: nil,
                            favoritePosition: nil,
                            skillLevel: nil
                        )
                    )
                }
            ) { res async throws in
                #expect(res.status == .forbidden)
            }

            let stored = try await User.query(on: app.db).all()
            #expect(stored.allSatisfy { $0.supabaseUserId == nil })
        }
    }
}
