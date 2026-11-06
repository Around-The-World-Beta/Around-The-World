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
                #expect(body.database == "ok")
            }
        }
    }

    @Test("full games are hidden from browse and reappear after cancellation")
    func rosterDerivedVisibility() async throws {
        try await withATWApp { app in
            let (hostToken, _) = try await mintSupabaseToken(
                on: app,
                email: "host-\(UUID())@test.dev",
                name: "Host"
            )
            let (guestToken, _) = try await mintSupabaseToken(
                on: app,
                email: "guest-\(UUID())@test.dev",
                name: "Guest"
            )

            try await app.testing().test(.GET, "api/v1/me", headers: bearerHeaders(hostToken)) { res async throws in
                #expect(res.status == .ok)
            }

            var gameID: UUID?
            try await app.testing().test(
                .POST,
                "api/v1/games",
                headers: bearerHeaders(hostToken),
                beforeRequest: { req async throws in
                    try req.content.encode(sampleCreateGame(title: "Capacity Two", capacity: 2))
                }
            ) { res async throws in
                #expect(res.status == .created)
                gameID = try res.content.decode(GameResponse.self).id
            }
            let id = try #require(gameID)

            var participantID: UUID?
            try await app.testing().test(
                .POST,
                "api/v1/participants",
                headers: bearerHeaders(guestToken),
                beforeRequest: { req async throws in
                    try req.content.encode(CreateParticipantRequest(gameId: id, status: "joined"))
                }
            ) { res async throws in
                #expect(res.status == .created)
                participantID = try res.content.decode(ParticipantResponse.self).id
            }
            let signupID = try #require(participantID)

            try await app.testing().test(.GET, "api/v1/games?includeFull=false&region=bay-area") { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode([GameResponse].self)
                #expect(!body.contains(where: { $0.id == id }))
            }

            try await app.testing().test(.GET, "api/v1/me/games", headers: bearerHeaders(guestToken)) { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode([GameResponse].self)
                #expect(body.contains(where: { $0.id == id }))
            }

            try await app.testing().test(
                .PATCH,
                "api/v1/participants/\(signupID.uuidString)",
                headers: bearerHeaders(guestToken),
                beforeRequest: { req async throws in
                    try req.content.encode(UpdateParticipantRequest(status: "cancelled"))
                }
            ) { res async throws in
                #expect(res.status == .ok)
            }

            try await app.testing().test(.GET, "api/v1/games?includeFull=false&region=bay-area") { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode([GameResponse].self)
                #expect(body.contains(where: { $0.id == id && $0.joinedCount == 1 }))
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
            let (token, _) = try await mintSupabaseToken(
                on: app,
                email: "legacy-\(UUID())@test.dev",
                name: "Legacy Tier"
            )
            try await app.testing().test(
                .PATCH,
                "api/v1/me/profile",
                headers: bearerHeaders(token),
                beforeRequest: { req async throws in
                    try req.content.encode(
                        UpdateProfileRequest(
                            city: nil,
                            bio: nil,
                            favoritePosition: nil,
                            skillLevel: "Beginner",
                            avatarUrl: nil,
                            age: nil
                        )
                    )
                }
            ) { res async throws in
                #expect(res.status == .ok)
                let profile = try res.content.decode(ProfileResponse.self)
                #expect(profile.skillLevel == SkillLevel.casual.rawValue)
            }
        }
    }

    @Test("unknown skill tier is rejected")
    func unknownSkillTierRejected() async throws {
        try await withATWApp { app in
            let (token, _) = try await mintSupabaseToken(
                on: app,
                email: "bad-tier-\(UUID())@test.dev",
                name: "Bad Tier"
            )
            try await app.testing().test(
                .PATCH,
                "api/v1/me/profile",
                headers: bearerHeaders(token),
                beforeRequest: { req async throws in
                    try req.content.encode(
                        UpdateProfileRequest(
                            city: nil,
                            bio: nil,
                            favoritePosition: nil,
                            skillLevel: "Could've Been Pro",
                            avatarUrl: nil,
                            age: nil
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
    @Test("client-supplied supabaseUserId is refused; token sub is stored instead")
    func clientSuppliedSupabaseIDRefused() async throws {
        try await withATWApp { app in
            let sub = UUID()
            let (token, _) = try await mintSupabaseToken(
                on: app,
                sub: sub,
                email: "linked-\(UUID())@test.dev",
                name: "Linked"
            )

            try await app.testing().test(
                .PATCH,
                "api/v1/me",
                headers: bearerHeaders(token),
                beforeRequest: { req async throws in
                    try req.content.encode(
                        UpdateMeRequest(displayName: "Still Me", supabaseUserId: UUID())
                    )
                }
            ) { res async throws in
                #expect(res.status == .forbidden)
            }

            try await app.testing().test(.GET, "api/v1/me", headers: bearerHeaders(token)) { res async throws in
                #expect(res.status == .ok)
                let me = try res.content.decode(MeResponse.self)
                #expect(me.user.supabaseUserId == sub)
            }
        }
    }
}
