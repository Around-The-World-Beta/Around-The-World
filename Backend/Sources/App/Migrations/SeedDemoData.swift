import Fluent
import Vapor

/// Inserts a demo host + a couple of games when the database is empty so the
/// iOS simulator has something to render on first launch.
struct SeedDemoData: AsyncMigration {
    func prepare(on database: any Database) async throws {
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
            city: "Brooklyn, NY",
            bio: "Pickup soccer organizer",
            favoritePosition: "Midfielder",
            skillLevel: "Baller"
        )
        try await profile.save(on: database)

        let player = User(
            email: "marco@aroundtheworld.dev",
            displayName: "Marco Diaz"
        )
        try await player.save(on: database)

        let games: [Game] = [
            Game(
                hostID: hostID,
                title: "Saturday Scrimmage & Drills",
                venue: "Red Hook Rec Fields",
                neighborhood: "Red Hook",
                skill: "Baller",
                format: "8v8",
                capacity: 16,
                priceCents: 1000,
                notes: "First 30 min touch drills, then full scrimmage. Serious players only please.",
                startsAt: Date().addingTimeInterval(60 * 60 * 20),
                latitude: 40.6734,
                longitude: -74.0083
            ),
            Game(
                hostID: hostID,
                title: "Late Night 7v7 Sprints",
                venue: "McCarren Park Turf",
                neighborhood: "Williamsburg",
                skill: "Intermediate",
                format: "7v7",
                capacity: 14,
                priceCents: 800,
                notes: "Bring dark + light shirts. Turf shoes recommended.",
                startsAt: Date().addingTimeInterval(60 * 60 * 6),
                latitude: 40.7215,
                longitude: -73.9518
            ),
            Game(
                hostID: hostID,
                title: "Lunch Break Kickabout",
                venue: "Bushwick Inlet Park",
                neighborhood: "Greenpoint",
                skill: "Casual",
                format: "6v6",
                capacity: 12,
                priceCents: 0,
                notes: "Free casual game. Show up, play, head back to work.",
                startsAt: Date().addingTimeInterval(60 * 60 * 48),
                latitude: 40.7226,
                longitude: -73.9614
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
        // Keep demo data on revert; wipe the DB file/volume if you need a clean slate.
    }
}
