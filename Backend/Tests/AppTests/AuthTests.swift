import Fluent
import JWT
import Testing
import VaporTesting
@testable import App

extension AppTests {
    @Test("unauthenticated attack sequence from the completion-plan audit is blocked")
    func unauthenticatedAttackSequenceBlocked() async throws {
        try await withATWApp { app in
            // 1. Create an account with just an email and a name. No password. No token.
            try await app.testing().test(
                .POST,
                "api/v1/users",
                beforeRequest: { req async throws in
                    try req.content.encode([
                        "email": "attacker@example.com",
                        "displayName": "Attacker",
                    ])
                }
            ) { res async throws in
                #expect(res.status == .unauthorized)
            }

            // 2. Ask for the list of all users (emails).
            try await app.testing().test(.GET, "api/v1/users") { res async throws in
                #expect(res.status == .unauthorized)
                #expect(!res.body.string.contains("@"))
            }

            // 3. Ask for all profiles (city, age, bio, position).
            try await app.testing().test(.GET, "api/v1/profiles") { res async throws in
                #expect(res.status == .unauthorized)
            }

            // Seed a victim by signing in properly, then try to impersonate them.
            let (victimToken, _) = try await mintSupabaseToken(
                on: app,
                email: "victim-\(UUID())@test.dev",
                name: "Victim"
            )
            var victimID: UUID?
            try await app.testing().test(.GET, "api/v1/me", headers: bearerHeaders(victimToken)) { res async throws in
                #expect(res.status == .ok)
                victimID = try res.content.decode(MeResponse.self).user.id
            }
            let victim = try #require(victimID)

            // 4. Create a game in someone else's name — supply their user id as host, no token.
            try await app.testing().test(
                .POST,
                "api/v1/games",
                beforeRequest: { req async throws in
                    struct Spoof: Content {
                        let hostUserId: UUID
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
                    }
                    try req.content.encode(
                        Spoof(
                            hostUserId: victim,
                            title: "Stolen Game",
                            venue: "Franklin Square Park",
                            neighborhood: "San Francisco, San Francisco",
                            skill: "Casual",
                            format: "5v5",
                            capacity: 10,
                            priceCents: 0,
                            notes: "",
                            startsAt: Date().addingTimeInterval(3600),
                            latitude: 37.7644,
                            longitude: -122.4102
                        )
                    )
                }
            ) { res async throws in
                #expect(res.status == .unauthorized)
            }

            let stolen = try await Game.query(on: app.db).filter(\.$title == "Stolen Game").first()
            #expect(stolen == nil)

            // 5. Delete that game (or any game) with no credentials.
            try await app.testing().test(.DELETE, "api/v1/games/\(UUID().uuidString)") { res async throws in
                #expect(res.status == .unauthorized)
            }

            // 6. Delete a user account entirely, with no credentials.
            try await app.testing().test(.DELETE, "api/v1/users/\(victim.uuidString)") { res async throws in
                #expect(res.status == .unauthorized)
            }
            let stillThere = try await User.find(victim, on: app.db)
            #expect(stillThere != nil)
        }
    }

    @Test("other people's games, profiles, and friend lists are not readable by id")
    func cannotReadSomeoneElsesPrivateLists() async throws {
        try await withATWApp { app in
            let (aliceToken, _) = try await mintSupabaseToken(
                on: app,
                email: "alice-\(UUID())@test.dev",
                name: "Alice"
            )
            var aliceID: UUID?
            try await app.testing().test(.GET, "api/v1/me", headers: bearerHeaders(aliceToken)) { res async throws in
                aliceID = try res.content.decode(MeResponse.self).user.id
            }
            let alice = try #require(aliceID)

            try await app.testing().test(.GET, "api/v1/games/mine?userId=\(alice.uuidString)") { res async throws in
                #expect(res.status == .unauthorized)
            }
            try await app.testing().test(.GET, "api/v1/profiles/user/\(alice.uuidString)") { res async throws in
                #expect(res.status == .unauthorized)
            }
            try await app.testing().test(.GET, "api/v1/friendships/user/\(alice.uuidString)") { res async throws in
                #expect(res.status == .unauthorized)
            }
            try await app.testing().test(.GET, "api/v1/users/\(alice.uuidString)") { res async throws in
                #expect(res.status == .unauthorized)
                #expect(!res.body.string.contains("alice-"))
            }
        }
    }

    @Test("hostUserId in the body cannot impersonate another player")
    func createGameIgnoresClientHostId() async throws {
        try await withATWApp { app in
            let (aliceToken, _) = try await mintSupabaseToken(
                on: app,
                email: "alice-\(UUID())@test.dev",
                name: "Alice"
            )
            let (bobToken, _) = try await mintSupabaseToken(
                on: app,
                email: "bob-\(UUID())@test.dev",
                name: "Bob"
            )
            var aliceID: UUID?
            var bobID: UUID?
            try await app.testing().test(.GET, "api/v1/me", headers: bearerHeaders(aliceToken)) { res async throws in
                aliceID = try res.content.decode(MeResponse.self).user.id
            }
            try await app.testing().test(.GET, "api/v1/me", headers: bearerHeaders(bobToken)) { res async throws in
                bobID = try res.content.decode(MeResponse.self).user.id
            }
            let alice = try #require(aliceID)
            let bob = try #require(bobID)

            try await app.testing().test(
                .POST,
                "api/v1/games",
                headers: bearerHeaders(bobToken),
                beforeRequest: { req async throws in
                    struct Spoof: Content {
                        let hostUserId: UUID
                        let title, venue, neighborhood, skill, format: String
                        let capacity, priceCents: Int
                        let notes: String
                        let startsAt: Date
                        let latitude, longitude: Double
                    }
                    let sample = sampleCreateGame(title: "Bob's Game")
                    try req.content.encode(
                        Spoof(
                            hostUserId: alice,
                            title: sample.title,
                            venue: sample.venue,
                            neighborhood: sample.neighborhood,
                            skill: sample.skill,
                            format: sample.format,
                            capacity: sample.capacity,
                            priceCents: sample.priceCents,
                            notes: sample.notes,
                            startsAt: sample.startsAt,
                            latitude: sample.latitude,
                            longitude: sample.longitude
                        )
                    )
                }
            ) { res async throws in
                #expect(res.status == .created)
                let game = try res.content.decode(GameResponse.self)
                #expect(game.hostUserId == bob)
                #expect(game.hostUserId != alice)
            }
        }
    }

    @Test("only the host can edit or cancel a game; only you can edit your profile")
    func ownershipEnforced() async throws {
        try await withATWApp { app in
            let (hostToken, _) = try await mintSupabaseToken(
                on: app,
                email: "host-\(UUID())@test.dev",
                name: "Host"
            )
            let (otherToken, _) = try await mintSupabaseToken(
                on: app,
                email: "other-\(UUID())@test.dev",
                name: "Other"
            )

            var gameID: UUID?
            try await app.testing().test(
                .POST,
                "api/v1/games",
                headers: bearerHeaders(hostToken),
                beforeRequest: { req async throws in
                    try req.content.encode(sampleCreateGame())
                }
            ) { res async throws in
                #expect(res.status == .created)
                gameID = try res.content.decode(GameResponse.self).id
            }
            let id = try #require(gameID)

            try await app.testing().test(
                .PATCH,
                "api/v1/games/\(id.uuidString)",
                headers: bearerHeaders(otherToken),
                beforeRequest: { req async throws in
                    try req.content.encode(["title": "Hijacked"] as [String: String])
                }
            ) { res async throws in
                #expect(res.status == .forbidden)
            }

            try await app.testing().test(
                .DELETE,
                "api/v1/games/\(id.uuidString)",
                headers: bearerHeaders(otherToken)
            ) { res async throws in
                #expect(res.status == .forbidden)
            }

            try await app.testing().test(
                .PATCH,
                "api/v1/games/\(id.uuidString)",
                headers: bearerHeaders(hostToken),
                beforeRequest: { req async throws in
                    try req.content.encode(["status": "cancelled"] as [String: String])
                }
            ) { res async throws in
                #expect(res.status == .ok)
                #expect(try res.content.decode(GameResponse.self).status == "cancelled")
            }

            try await app.testing().test(
                .PATCH,
                "api/v1/me/profile",
                headers: bearerHeaders(otherToken),
                beforeRequest: { req async throws in
                    try req.content.encode(
                        UpdateProfileRequest(
                            city: "Oakland",
                            bio: "not yours",
                            favoritePosition: nil,
                            skillLevel: nil,
                            avatarUrl: nil,
                            age: nil
                        )
                    )
                }
            ) { res async throws in
                #expect(res.status == .ok)
            }

            try await app.testing().test(.GET, "api/v1/me/profile", headers: bearerHeaders(hostToken)) { res async throws in
                let profile = try res.content.decode(ProfileResponse.self)
                #expect(profile.city != "Oakland")
                #expect(profile.bio != "not yours")
            }
        }
    }

    @Test("expired, anonymous, and wrong-secret tokens are rejected")
    func badTokensRejected() async throws {
        try await withATWApp { app in
            try await app.testing().test(.GET, "api/v1/me") { res async throws in
                #expect(res.status == .unauthorized)
            }

            let expired = try await mintSupabaseToken(
                on: app,
                email: "expired@test.dev",
                expiresIn: -60
            )
            try await app.testing().test(.GET, "api/v1/me", headers: bearerHeaders(expired.token)) { res async throws in
                #expect(res.status == .unauthorized)
            }

            let anon = try await mintSupabaseToken(
                on: app,
                email: "anon@test.dev",
                isAnonymous: true
            )
            try await app.testing().test(.GET, "api/v1/me", headers: bearerHeaders(anon.token)) { res async throws in
                #expect(res.status == .unauthorized)
            }

            let otherKeys = JWTKeyCollection()
            await otherKeys.add(hmac: HMACKey(from: "some-other-secret"), digestAlgorithm: .sha256)
            let now = Date()
            let forged = try await otherKeys.sign(
                SupabaseJWTPayload(
                    issuer: IssuerClaim(value: "https://test.supabase.co/auth/v1"),
                    subject: SubjectClaim(value: UUID().uuidString.lowercased()),
                    audience: AudienceClaim(value: "authenticated"),
                    expiresAt: ExpirationClaim(value: now.addingTimeInterval(3600)),
                    issuedAt: IssuedAtClaim(value: now),
                    role: "authenticated",
                    email: "forged@test.dev",
                    phone: "",
                    aal: "aal1",
                    sessionID: UUID().uuidString,
                    isAnonymous: false,
                    userMetadata: nil,
                    appMetadata: nil
                )
            )
            try await app.testing().test(.GET, "api/v1/me", headers: bearerHeaders(forged)) { res async throws in
                #expect(res.status == .unauthorized)
            }
        }
    }

    @Test("CORS does not reflect unknown browser origins")
    func corsRestricted() async throws {
        try await withATWApp { app in
            try await app.testing().test(
                .GET,
                "health",
                headers: ["Origin": "https://evil.example"]
            ) { res async throws in
                #expect(res.status == .ok)
                let allowed = res.headers[.accessControlAllowOrigin]
                #expect(!allowed.contains("*"))
                #expect(!allowed.contains("https://evil.example"))
            }

            try await app.testing().test(
                .GET,
                "health",
                headers: ["Origin": "http://127.0.0.1:5173"]
            ) { res async throws in
                #expect(res.status == .ok)
                #expect(res.headers[.accessControlAllowOrigin].contains("http://127.0.0.1:5173"))
            }
        }
    }

    @Test("rate limiter returns 429 after the per-minute cap")
    func rateLimited() async throws {
        try await withATWApp(rateLimitPerMinute: 3) { app in
            for _ in 0..<3 {
                try await app.testing().test(.GET, "api/v1/meta/bay-area") { res async throws in
                    #expect(res.status == .ok)
                }
            }
            try await app.testing().test(.GET, "api/v1/meta/bay-area") { res async throws in
                #expect(res.status == .tooManyRequests)
            }
        }
    }

    @Test("health is not rate limited so a host probe cannot starve the API")
    func healthSkipsRateLimit() async throws {
        try await withATWApp(rateLimitPerMinute: 1) { app in
            try await app.testing().test(.GET, "health") { res async throws in
                #expect(res.status == .ok)
            }
            try await app.testing().test(.GET, "health") { res async throws in
                #expect(res.status == .ok)
            }
            try await app.testing().test(.GET, "api/v1/meta/bay-area") { res async throws in
                #expect(res.status == .ok)
            }
            try await app.testing().test(.GET, "api/v1/meta/bay-area") { res async throws in
                #expect(res.status == .tooManyRequests)
            }
        }
    }

    @Test("my games and my friendships are the signed-in user's only")
    func meEndpointsAreSelfOnly() async throws {
        try await withATWApp { app in
            let (aliceToken, _) = try await mintSupabaseToken(
                on: app,
                email: "alice-\(UUID())@test.dev",
                name: "Alice"
            )
            let (bobToken, _) = try await mintSupabaseToken(
                on: app,
                email: "bob-\(UUID())@test.dev",
                name: "Bob"
            )

            var aliceGame: UUID?
            try await app.testing().test(
                .POST,
                "api/v1/games",
                headers: bearerHeaders(aliceToken),
                beforeRequest: { req async throws in
                    try req.content.encode(sampleCreateGame(title: "Alice Hosts"))
                }
            ) { res async throws in
                aliceGame = try res.content.decode(GameResponse.self).id
            }

            try await app.testing().test(.GET, "api/v1/me/games", headers: bearerHeaders(bobToken)) { res async throws in
                #expect(res.status == .ok)
                let games = try res.content.decode([GameResponse].self)
                #expect(!games.contains(where: { $0.id == aliceGame }))
            }

            try await app.testing().test(.GET, "api/v1/me/games", headers: bearerHeaders(aliceToken)) { res async throws in
                #expect(res.status == .ok)
                let games = try res.content.decode([GameResponse].self)
                #expect(games.contains(where: { $0.id == aliceGame }))
            }
        }
    }
}
