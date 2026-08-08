import Fluent
import Vapor

/// Optional local demo seed. **Off by default** so empty Supabase/Postgres
/// databases stay empty for Bay Area beta testing.
///
/// Enable with `SEED_DEMO=1` when you need sample Bay Area listings on a fresh DB.
struct SeedDemoData: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let enabled = (Environment.get("SEED_DEMO") ?? "").lowercased()
        guard enabled == "1" || enabled == "true" || enabled == "yes" else {
            return
        }

        let existing = try await Game.query(on: database).count()
        if existing > 0 {
            return
        }

        let host = User(
            email: "coach@aroundtheworld.dev",
            displayName: "Coach T"
        )
        try await host.save(on: database)
        guard let hostID = host.id else { return }

        let profile = Profile(
            userID: hostID,
            city: "San Francisco, CA",
            bio: "Bay Area pickup organizer",
            favoritePosition: "Midfielder",
            skillLevel: "Baller",
            age: 29
        )
        try await profile.save(on: database)

        let player = User(
            email: "marco@aroundtheworld.dev",
            displayName: "Marco Diaz"
        )
        try await player.save(on: database)

        // Bay Area venues only (Mission, Oakland, Palo Alto).
        let games: [Game] = [
            Game(
                hostID: hostID,
                title: "Mission Evening Scrimmage",
                venue: "Franklin Square Park",
                neighborhood: "Mission",
                skill: "Baller",
                format: "7v7",
                capacity: 14,
                priceCents: 0,
                notes: "Bring dark + light. Turf shoes recommended.",
                startsAt: Date().addingTimeInterval(60 * 60 * 20),
                latitude: 37.7644,
                longitude: -122.4102
            ),
            Game(
                hostID: hostID,
                title: "Lake Merritt Morning Kickabout",
                venue: "Lake Merritt Fields",
                neighborhood: "Oakland",
                skill: "Beginner",
                format: "6v6",
                capacity: 12,
                priceCents: 0,
                notes: "All ages welcome. Free casual game.",
                startsAt: Date().addingTimeInterval(60 * 60 * 48),
                latitude: 37.8015,
                longitude: -122.2583
            ),
            Game(
                hostID: hostID,
                title: "Palo Alto Lunch 5v5",
                venue: "Mitchell Park Field",
                neighborhood: "Palo Alto",
                skill: "Intermediate",
                format: "5v5",
                capacity: 10,
                priceCents: 500,
                notes: "Quick lunch session. First come first served.",
                startsAt: Date().addingTimeInterval(60 * 60 * 6),
                latitude: 37.4020,
                longitude: -122.1130
            ),
        ]

        for game in games {
            try await game.save(on: database)
            if let gameID = game.id {
                try await Participant(gameID: gameID, userID: hostID, status: .joined).save(on: database)
                if let playerID = player.id {
                    try await Participant(gameID: gameID, userID: playerID, status: .joined).save(on: database)
                }
            }
        }
    }

    func revert(on database: any Database) async throws {
        // Keep data on revert; wipe the DB file/volume if you need a clean slate.
    }
}
