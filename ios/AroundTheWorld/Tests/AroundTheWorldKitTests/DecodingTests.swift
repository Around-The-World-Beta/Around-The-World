import Foundation
import Testing
@testable import AroundTheWorldKit

@Suite("Vapor JSON schema decoding")
struct DecodingTests {
    @Test("decodes UserResponse identical to Vapor output")
    func decodeUser() throws {
        let json = """
        {
          "id": "1FC0F1AF-3DE5-4C1B-9848-C4CB8C939EAC",
          "email": "coach@example.com",
          "displayName": "Coach T",
          "createdAt": "2026-08-08T19:32:40Z",
          "updatedAt": "2026-08-08T19:32:40Z"
        }
        """.data(using: .utf8)!

        let user = try JSONCoding.decoder.decode(UserResponse.self, from: json)
        #expect(user.email == "coach@example.com")
        #expect(user.displayName == "Coach T")
        #expect(user.supabaseUserId == nil)
        #expect(user.id.uuidString == "1FC0F1AF-3DE5-4C1B-9848-C4CB8C939EAC")
    }

    @Test("decodes GameResponse with joinedCount")
    func decodeGame() throws {
        let json = """
        {
          "id": "E16C8120-A841-4F92-A6D4-E5B1B50CAA4F",
          "hostUserId": "1FC0F1AF-3DE5-4C1B-9848-C4CB8C939EAC",
          "title": "Saturday Scrimmage & Drills",
          "venue": "Red Hook Rec Fields",
          "neighborhood": "Red Hook",
          "skill": "Baller",
          "format": "8v8",
          "capacity": 16,
          "joinedCount": 2,
          "priceCents": 1000,
          "notes": "First 30 min touch drills, then full scrimmage.",
          "startsAt": "2026-08-09T13:00:00Z",
          "latitude": 40.6734,
          "longitude": -74.0083,
          "status": "scheduled",
          "createdAt": "2026-08-08T19:32:41Z",
          "updatedAt": "2026-08-08T19:32:41Z"
        }
        """.data(using: .utf8)!

        let game = try JSONCoding.decoder.decode(GameResponse.self, from: json)
        #expect(game.title == "Saturday Scrimmage & Drills")
        #expect(game.joinedCount == 2)
        #expect(game.priceCents == 1000)
        #expect(game.status == "scheduled")
    }

    @Test("decodes API error body")
    func decodeError() throws {
        let json = """
        { "error": { "status": 404, "message": "User not found" } }
        """.data(using: .utf8)!

        let body = try JSONCoding.decoder.decode(APIErrorBody.self, from: json)
        #expect(body.error.status == 404)
        #expect(body.error.message == "User not found")
    }

    @Test("encodes CreateUserRequest with camelCase keys")
    func encodeCreateUser() throws {
        let request = CreateUserRequest(
            email: "marco@example.com",
            displayName: "Marco Diaz",
            city: "Williamsburg",
            skillLevel: "Intermediate"
        )
        let data = try JSONCoding.encoder.encode(request)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(object?["displayName"] as? String == "Marco Diaz")
        #expect(object?["skillLevel"] as? String == "Intermediate")
        #expect(object?["email"] as? String == "marco@example.com")
    }
}
