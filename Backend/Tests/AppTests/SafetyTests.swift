import Foundation
import Testing
import VaporTesting
import Fluent
@testable import App

extension AppTests {
    @Test("report and block require a sign-in token")
    func reportAndBlockRequireAuth() async throws {
        try await withATWApp { app in
            try await app.testing().test(
                .POST,
                "api/v1/reports",
                beforeRequest: { req async throws in
                    try req.content.encode(
                        CreateReportRequest(
                            targetType: "user",
                            targetId: UUID(),
                            reason: "spam",
                            details: nil
                        )
                    )
                }
            ) { res async throws in
                #expect(res.status == .unauthorized)
            }

            try await app.testing().test(
                .POST,
                "api/v1/blocks",
                beforeRequest: { req async throws in
                    try req.content.encode(CreateBlockRequest(blockedUserId: UUID()))
                }
            ) { res async throws in
                #expect(res.status == .unauthorized)
            }
        }
    }

    @Test("signed-in player can report a game and block its host")
    func reportGameAndBlockHost() async throws {
        try await withATWApp { app in
            let (hostToken, _) = try await mintSupabaseToken(
                on: app,
                email: "host-\(UUID())@test.dev",
                name: "Host"
            )
            let (reporterToken, _) = try await mintSupabaseToken(
                on: app,
                email: "reporter-\(UUID())@test.dev",
                name: "Reporter"
            )

            var hostID: UUID?
            try await app.testing().test(.GET, "api/v1/me", headers: bearerHeaders(hostToken)) { res async throws in
                #expect(res.status == .ok)
                hostID = try res.content.decode(MeResponse.self).user.id
            }
            let blockedHostID = try #require(hostID)

            var gameID: UUID?
            try await app.testing().test(
                .POST,
                "api/v1/games",
                headers: bearerHeaders(hostToken),
                beforeRequest: { req async throws in
                    try req.content.encode(sampleCreateGame(title: "Ugly Notes"))
                }
            ) { res async throws in
                #expect(res.status == .created)
                gameID = try res.content.decode(GameResponse.self).id
            }
            let reportedGameID = try #require(gameID)

            try await app.testing().test(
                .POST,
                "api/v1/reports",
                headers: bearerHeaders(reporterToken),
                beforeRequest: { req async throws in
                    try req.content.encode(
                        CreateReportRequest(
                            targetType: "game",
                            targetId: reportedGameID,
                            reason: "inappropriate",
                            details: "Offensive notes."
                        )
                    )
                }
            ) { res async throws in
                #expect(res.status == .created)
                let body = try res.content.decode(ReportResponse.self)
                #expect(body.targetId == reportedGameID)
                #expect(body.reason == "inappropriate")
            }

            try await app.testing().test(
                .POST,
                "api/v1/blocks",
                headers: bearerHeaders(reporterToken),
                beforeRequest: { req async throws in
                    try req.content.encode(CreateBlockRequest(blockedUserId: blockedHostID))
                }
            ) { res async throws in
                #expect(res.status == .created)
                let body = try res.content.decode(BlockResponse.self)
                #expect(body.blockedUserId == blockedHostID)
            }

            try await app.testing().test(
                .GET,
                "api/v1/games?includeFull=true&region=bay-area",
                headers: bearerHeaders(reporterToken)
            ) { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode([GameResponse].self)
                #expect(!body.contains(where: { $0.id == reportedGameID }))
            }

            try await app.testing().test(.GET, "api/v1/games?includeFull=true&region=bay-area") { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode([GameResponse].self)
                #expect(body.contains(where: { $0.id == reportedGameID }))
            }
        }
    }

    @Test("bio and game notes reject over-long and script content")
    func contentLimits() async throws {
        try await withATWApp { app in
            let (token, _) = try await mintSupabaseToken(
                on: app,
                email: "limits-\(UUID())@test.dev",
                name: "Limits"
            )

            try await app.testing().test(
                .PATCH,
                "api/v1/me/profile",
                headers: bearerHeaders(token),
                beforeRequest: { req async throws in
                    try req.content.encode(
                        UpdateProfileRequest(
                            city: "Oakland, CA",
                            bio: String(repeating: "a", count: 201),
                            favoritePosition: nil,
                            skillLevel: nil,
                            avatarUrl: nil,
                            age: nil
                        )
                    )
                }
            ) { res async throws in
                #expect(res.status == .badRequest)
            }

            try await app.testing().test(
                .POST,
                "api/v1/games",
                headers: bearerHeaders(token),
                beforeRequest: { req async throws in
                    try req.content.encode(sampleCreateGame(title: "Too Long").withNotes(String(repeating: "n", count: 501)))
                }
            ) { res async throws in
                #expect(res.status == .badRequest)
            }

            try await app.testing().test(
                .POST,
                "api/v1/games",
                headers: bearerHeaders(token),
                beforeRequest: { req async throws in
                    try req.content.encode(sampleCreateGame(title: "Scripted").withNotes("Come play <script>alert(1)</script>"))
                }
            ) { res async throws in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test("DELETE /api/v1/me removes the signed-in account and cascaded rows")
    func deleteAccountRemovesRelatedRows() async throws {
        try await withATWApp { app in
            let email = "gone-\(UUID())@test.dev"
            let (token, sub) = try await mintSupabaseToken(on: app, email: email, name: "Gone")

            var userID: UUID?
            try await app.testing().test(.GET, "api/v1/me", headers: bearerHeaders(token)) { res async throws in
                #expect(res.status == .ok)
                let me = try res.content.decode(MeResponse.self)
                #expect(me.user.supabaseUserId == sub)
                #expect(me.user.email == email.lowercased())
                userID = me.user.id
            }
            let deletedUserID = try #require(userID)

            try await app.testing().test(
                .POST,
                "api/v1/games",
                headers: bearerHeaders(token),
                beforeRequest: { req async throws in
                    try req.content.encode(sampleCreateGame(title: "My Pickup"))
                }
            ) { res async throws in
                #expect(res.status == .created)
            }

            try await app.testing().test(.DELETE, "api/v1/me", headers: bearerHeaders(token)) { res async throws in
                #expect(res.status == .ok)
                let body = try res.content.decode(APIMessage.self)
                #expect(body.message == "Account deleted")
            }

            #expect(try await User.find(deletedUserID, on: app.db) == nil)
            #expect(try await Game.query(on: app.db).filter(\.$host.$id == deletedUserID).all().isEmpty)
            #expect(try await UserReport.query(on: app.db).filter(\.$reporter.$id == deletedUserID).all().isEmpty)
            #expect(try await UserBlock.query(on: app.db).filter(\.$blocker.$id == deletedUserID).all().isEmpty)
        }
    }

    @Test("profile bio over 200 characters is rejected on PATCH /me/profile")
    func meProfileBioLimit() async throws {
        try await withATWApp { app in
            let (token, _) = try await mintSupabaseToken(
                on: app,
                email: "bio-me-\(UUID())@test.dev",
                name: "Bio Person"
            )

            try await app.testing().test(
                .PATCH,
                "api/v1/me/profile",
                headers: bearerHeaders(token),
                beforeRequest: { req async throws in
                    try req.content.encode(
                        UpdateProfileRequest(
                            city: "Oakland, CA",
                            bio: String(repeating: "b", count: 201),
                            favoritePosition: nil,
                            skillLevel: nil,
                            avatarUrl: nil,
                            age: nil
                        )
                    )
                }
            ) { res async throws in
                #expect(res.status == .badRequest)
            }

            try await app.testing().test(
                .PATCH,
                "api/v1/me/profile",
                headers: bearerHeaders(token),
                beforeRequest: { req async throws in
                    try req.content.encode(
                        UpdateProfileRequest(
                            city: "Oakland, CA",
                            bio: "Bay Area pickup. Midfielder.",
                            favoritePosition: "Midfielder",
                            skillLevel: "Casual",
                            avatarUrl: nil,
                            age: 29
                        )
                    )
                }
            ) { res async throws in
                #expect(res.status == .ok)
                let profile = try res.content.decode(ProfileResponse.self)
                #expect(profile.bio == "Bay Area pickup. Midfielder.")
                #expect(profile.city == "Oakland, CA")
            }
        }
    }
}

private extension CreateGameRequest {
    func withNotes(_ notes: String) -> CreateGameRequest {
        CreateGameRequest(
            title: title,
            venue: venue,
            neighborhood: neighborhood,
            skill: skill,
            format: format,
            capacity: capacity,
            priceCents: priceCents,
            notes: notes,
            startsAt: startsAt,
            latitude: latitude,
            longitude: longitude,
            imageUrl: imageUrl
        )
    }
}
